import AppKit
import SwiftUI
import WhisperBarCore

@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private let model: AppModel
    private var settingsController: MeasuringHostingController<SettingsView>?

    init(model: AppModel) {
        self.model = model
        super.init()
        configureStatusItem()
        configurePopover()
    }

    func showOnboardingIfNeeded() {
        guard !model.hasAPIKey else { return }
        statusItem.button?.contentTintColor = .systemOrange
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "WhisperBar")
        button.imagePosition = .imageLeading
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func configurePopover() {
        popover.behavior = .transient
        let controller = MeasuringHostingController(rootView: SettingsView(model: model), preferredWidth: SettingsView.contentWidth)
        settingsController = controller
        popover.contentViewController = controller
        updatePopoverSize()
    }

    @objc private func togglePopover(_ sender: Any?) {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            model.refreshLaunchAtLogin()
            model.refreshUsageSummary()
            updatePopoverSize()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func updatePopoverSize() {
        settingsController?.updatePreferredContentSize()
        if let preferredContentSize = settingsController?.preferredContentSize {
            popover.contentSize = preferredContentSize
        }
    }
}

@MainActor
private final class MeasuringHostingController<Content: View>: NSHostingController<Content> {
    private let preferredWidth: CGFloat

    init(rootView: Content, preferredWidth: CGFloat) {
        self.preferredWidth = preferredWidth
        super.init(rootView: rootView)
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        updatePreferredContentSize()
    }

    func updatePreferredContentSize() {
        view.frame.size.width = preferredWidth
        view.layoutSubtreeIfNeeded()
        let fittingSize = view.fittingSize
        let measuredHeight = ceil(fittingSize.height)
        let nextSize = NSSize(width: preferredWidth, height: measuredHeight)

        guard abs(preferredContentSize.width - nextSize.width) > 0.5 ||
            abs(preferredContentSize.height - nextSize.height) > 0.5 else {
            return
        }

        preferredContentSize = nextSize
    }
}
