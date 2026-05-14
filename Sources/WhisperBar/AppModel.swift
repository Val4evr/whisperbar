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
    @Published var audioLevel: Double = 0
    @Published var lastError: String?
    @Published var apiKeyDraft = ""
    @Published var apiKeySummary = "Not set"
    @Published var isEditingAPIKey = false
    @Published private(set) var hasSavedAPIKey = false
    @Published var hotKeyStatusText = "Checking"
    @Published var hotKey: HotKey
    @Published var isLaunchAtLoginEnabled = false
    @Published var isRecordingHotKey = false
    @Published var selectedUsagePeriod: UsagePeriod = .day {
        didSet { refreshUsageSummary() }
    }
    @Published private(set) var usageSummary = UsageSummary.emptyDay

    private let keychainStore: APIKeyStoring
    private let hotKeyStore: HotKeyStore
    private let apiKeyMetadataStore: APIKeyMetadataStore
    private let usageLedgerStore: UsageLedgerStore

    weak var dictationController: DictationController?
    weak var hotKeyMonitor: GlobalHotKeyMonitor?

    init(
        keychainStore: APIKeyStoring = FileAPIKeyStore(),
        hotKeyStore: HotKeyStore = HotKeyStore(),
        apiKeyMetadataStore: APIKeyMetadataStore = APIKeyMetadataStore(),
        usageLedgerStore: UsageLedgerStore = UsageLedgerStore()
    ) {
        self.keychainStore = keychainStore
        self.hotKeyStore = hotKeyStore
        self.apiKeyMetadataStore = apiKeyMetadataStore
        self.usageLedgerStore = usageLedgerStore
        self.hotKey = hotKeyStore.load()
        loadAPIKeyMetadata()
        refreshUsageSummary()
        refreshLaunchAtLogin()
    }

    var hasAPIKey: Bool {
        hasSavedAPIKey
    }

    var apiKeyInputPlaceholder: String {
        hasSavedAPIKey ? apiKeySummary : "sk-..."
    }

    var isAPIKeyFieldReadOnly: Bool {
        hasSavedAPIKey && !isEditingAPIKey
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

    var hasRequiredPermissions: Bool {
        microphoneStatusText == "Allowed" && accessibilityStatusText == "Allowed"
    }

    func readAPIKey() throws -> String? {
        let apiKey = try keychainStore.readAPIKey()
        if let apiKey, !apiKey.isEmpty {
            updateAPIKeyMetadata(for: apiKey)
        }
        return apiKey
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
            isEditingAPIKey = false
            lastError = nil
            updateAPIKeyMetadata(for: normalized)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteAPIKey() {
        do {
            try keychainStore.deleteAPIKey()
            apiKeyDraft = ""
            isEditingAPIKey = true
            clearAPIKeyMetadata()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func loadAPIKeyMetadata() {
        let metadata = apiKeyMetadataStore.load()
        apiKeySummary = metadata.redactedKey
        hasSavedAPIKey = metadata.hasSavedKey
    }

    private func updateAPIKeyMetadata(for key: String) {
        let redacted = APIKeyValidator.redacted(key)
        apiKeySummary = redacted
        hasSavedAPIKey = true
        apiKeyMetadataStore.save(redactedKey: redacted)
    }

    private func clearAPIKeyMetadata() {
        apiKeySummary = "Not set"
        hasSavedAPIKey = false
        apiKeyMetadataStore.clear()
    }

    func beginAPIKeyRemoval() {
        deleteAPIKey()
    }

    func setHotKey(_ hotKey: HotKey) {
        self.hotKey = hotKey
        hotKeyStore.save(hotKey)
        hotKeyMonitor?.update(hotKey: hotKey)
    }

    func recordUsage(startedAt: Date, durationSeconds: Double) {
        guard durationSeconds > 0 else { return }
        do {
            try usageLedgerStore.record(UsageEntry(startedAt: startedAt, durationSeconds: durationSeconds))
            refreshUsageSummary()
        } catch {
            lastError = error.localizedDescription
            AppLogger.shared.error("Failed to record usage: \(error.localizedDescription)")
        }
    }

    func refreshUsageSummary() {
        usageSummary = UsageSummary(period: selectedUsagePeriod, entries: usageLedgerStore.load())
    }

    func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
            Task { @MainActor in
                self?.objectWillChange.send()
            }
        }
    }

    func requestAccessibilityPermission() {
        AppLogger.shared.info("Requesting Accessibility permission")
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
