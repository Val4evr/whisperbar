import AppKit
import Carbon
import SwiftUI
import WhisperBarCore

struct HotKeyCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCapture: (HotKey) -> Void

    func makeNSView(context: Context) -> CaptureNSView {
        let view = CaptureNSView()
        view.onCapture = onCapture
        return view
    }

    func updateNSView(_ nsView: CaptureNSView, context: Context) {
        nsView.isRecording = isRecording
    }

    final class CaptureNSView: NSView {
        var onCapture: ((HotKey) -> Void)?
        var isRecording = false {
            didSet {
                if isRecording {
                    window?.makeFirstResponder(self)
                }
            }
        }

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            guard isRecording else {
                super.keyDown(with: event)
                return
            }
            let modifiers = event.modifierFlags.carbonModifiers
            guard modifiers != 0 else { return }
            onCapture?(HotKey(keyCode: Int64(event.keyCode), carbonModifiers: modifiers, shiftSide: .any))
        }
    }
}

extension NSEvent.ModifierFlags {
    var carbonModifiers: UInt32 {
        var value: UInt32 = 0
        if contains(.command) { value |= UInt32(cmdKey) }
        if contains(.option) { value |= UInt32(optionKey) }
        if contains(.control) { value |= UInt32(controlKey) }
        if contains(.shift) { value |= UInt32(shiftKey) }
        return value
    }
}
