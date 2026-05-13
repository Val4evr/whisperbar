import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appModel: AppModel?
    private var statusController: StatusBarController?
    private var dictationController: DictationController?
    private var hotKeyMonitor: GlobalHotKeyMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let appModel = AppModel()
        let pillController = PillWindowController(model: appModel)
        let dictationController = DictationController(model: appModel, pillController: pillController)
        let statusController = StatusBarController(model: appModel)
        let hotKeyMonitor = GlobalHotKeyMonitor(hotKey: appModel.hotKey) {
            Task { @MainActor in
                dictationController.toggleDictation()
            }
        }

        appModel.dictationController = dictationController
        appModel.hotKeyMonitor = hotKeyMonitor
        statusController.showOnboardingIfNeeded()
        hotKeyMonitor.start()

        self.appModel = appModel
        self.statusController = statusController
        self.dictationController = dictationController
        self.hotKeyMonitor = hotKeyMonitor
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyMonitor?.stop()
        dictationController?.cancel()
    }
}
