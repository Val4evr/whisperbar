import AVFoundation
import Foundation
import ServiceManagement
import SwiftUI
import WhisperBarCore

@MainActor
final class AppModel: ObservableObject {
    @Published var isRecording = false
    @Published var statusText = "Ready"
    @Published var liveTranscript = ""
    @Published var lastError: String?
    @Published var apiKeyDraft = ""
    @Published var apiKeySummary = "Not set"
    @Published var hotKey: HotKey
    @Published var isLaunchAtLoginEnabled = false
    @Published var isRecordingHotKey = false

    private let keychainStore: APIKeyStoring
    private let hotKeyStore: HotKeyStore

    weak var dictationController: DictationController?
    weak var hotKeyMonitor: GlobalHotKeyMonitor?

    init(keychainStore: APIKeyStoring = KeychainAPIKeyStore(), hotKeyStore: HotKeyStore = HotKeyStore()) {
        self.keychainStore = keychainStore
        self.hotKeyStore = hotKeyStore
        self.hotKey = hotKeyStore.load()
        refreshAPIKeySummary()
        refreshLaunchAtLogin()
    }

    var hasAPIKey: Bool {
        (try? keychainStore.readAPIKey())??.isEmpty == false
    }

    var microphoneStatusText: String {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: return "Allowed"
        case .notDetermined: return "Not requested"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        @unknown default: return "Unknown"
        }
    }

    var accessibilityStatusText: String {
        AXIsProcessTrusted() ? "Allowed" : "Needs permission"
    }

    func readAPIKey() throws -> String? {
        try keychainStore.readAPIKey()
    }

    func saveAPIKey() {
        let normalized = APIKeyValidator.normalized(apiKeyDraft)
        guard APIKeyValidator.looksValid(normalized) else {
            lastError = "That does not look like an OpenAI API key."
            return
        }
        do {
            try keychainStore.saveAPIKey(normalized)
            apiKeyDraft = ""
            lastError = nil
            refreshAPIKeySummary()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteAPIKey() {
        do {
            try keychainStore.deleteAPIKey()
            refreshAPIKeySummary()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshAPIKeySummary() {
        apiKeySummary = APIKeyValidator.redacted(try? keychainStore.readAPIKey())
    }

    func setHotKey(_ hotKey: HotKey) {
        self.hotKey = hotKey
        hotKeyStore.save(hotKey)
        hotKeyMonitor?.update(hotKey: hotKey)
    }

    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }

    func requestAccessibilityPermission() {
        AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        objectWillChange.send()
    }

    func refreshLaunchAtLogin() {
        isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refreshLaunchAtLogin()
        } catch {
            isLaunchAtLoginEnabled = SMAppService.mainApp.status == .enabled
            lastError = error.localizedDescription
        }
    }
}
