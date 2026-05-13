import AppKit
import Carbon
import WhisperBarCore

@MainActor
final class GlobalHotKeyMonitor {
    private var hotKey: HotKey
    private let onTrigger: @MainActor () -> Void
    private let onStatusChange: @MainActor (String) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var rightShiftDown = false

    init(
        hotKey: HotKey,
        onTrigger: @escaping @MainActor () -> Void,
        onStatusChange: @escaping @MainActor (String) -> Void
    ) {
        self.hotKey = hotKey
        self.onTrigger = onTrigger
        self.onStatusChange = onStatusChange
    }

    func update(hotKey: HotKey) {
        self.hotKey = hotKey
    }

    func start() {
        guard eventTap == nil else { return }
        guard AXIsProcessTrusted() else {
            AppLogger.shared.error("Hotkey monitor unavailable: Accessibility permission is not granted")
            onStatusChange("Needs Accessibility")
            return
        }
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        let ref = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<GlobalHotKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handle(type: type, event: event)
            },
            userInfo: ref
        ) else {
            AppLogger.shared.error("CGEvent tap creation failed")
            onStatusChange("Hotkey inactive")
            return
        }
        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        AppLogger.shared.info("Global hotkey monitor active for \(hotKey.displayName)")
        onStatusChange("Active")
    }

    func stop() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
                AppLogger.shared.info("Re-enabled disabled event tap")
                onStatusChange("Active")
            }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if type == .flagsChanged, keyCode == Int64(kVK_RightShift) {
            rightShiftDown = event.flags.contains(.maskShift)
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let carbon = event.flags.carbonModifiers
        if hotKey.matches(keyCode: keyCode, carbonModifiers: carbon, rightShift: rightShiftDown) {
            AppLogger.shared.info("Global hotkey triggered")
            onTrigger()
            return nil
        }
        return Unmanaged.passUnretained(event)
    }
}

private extension CGEventFlags {
    var carbonModifiers: UInt32 {
        var value: UInt32 = 0
        if contains(.maskCommand) { value |= UInt32(cmdKey) }
        if contains(.maskAlternate) { value |= UInt32(optionKey) }
        if contains(.maskControl) { value |= UInt32(controlKey) }
        if contains(.maskShift) { value |= UInt32(shiftKey) }
        return value
    }
}
