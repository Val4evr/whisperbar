import SwiftUI
import WhisperBarCore

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            Divider()
            apiSection
            permissionsSection
            hotKeySection
            launchSection
            errorSection
            Spacer(minLength: 0)
            footer
        }
        .padding(18)
        .frame(width: 360)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(model.isRecording ? .red : Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("WhisperBar")
                    .font(.headline)
                Text(model.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                model.dictationController?.toggleDictation()
            } label: {
                Image(systemName: model.isRecording ? "stop.fill" : "mic.fill")
            }
            .buttonStyle(.borderedProminent)
            .help(model.isRecording ? "Stop dictation" : "Start dictation")
        }
    }

    private var apiSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("OpenAI API Key", systemImage: "key.fill")
                .font(.subheadline.weight(.semibold))
            HStack {
                Text(model.apiKeySummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Remove", role: .destructive) {
                    model.deleteAPIKey()
                }
                .disabled(!model.hasAPIKey)
            }
            TextField("sk-...", text: $model.apiKeyDraft)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .disableAutocorrection(true)
                .onSubmit {
                    model.saveAPIKey()
                }
            Button("Save Key") {
                model.saveAPIKey()
            }
            .disabled(model.apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Permissions", systemImage: "checkmark.shield.fill")
                .font(.subheadline.weight(.semibold))
            permissionRow(title: "Microphone", status: model.microphoneStatusText) {
                model.requestMicrophonePermission()
            }
            permissionRow(title: "Accessibility", status: model.accessibilityStatusText) {
                model.requestAccessibilityPermission()
            }
        }
    }

    private func permissionRow(title: String, status: String, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.medium))
                Text(status)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Allow", action: action)
                .controlSize(.small)
        }
    }

    private var hotKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Hotkey", systemImage: "keyboard")
                .font(.subheadline.weight(.semibold))
            HStack {
                Text(model.hotKey.displayName)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Spacer()
                Button(model.isRecordingHotKey ? "Press keys..." : "Record") {
                    model.isRecordingHotKey.toggle()
                }
                .controlSize(.small)
                Button {
                    model.setHotKey(.defaultToggle)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .controlSize(.small)
                .help("Reset hotkey")
            }
            .background(HotKeyCaptureView(isRecording: $model.isRecordingHotKey) { hotKey in
                model.setHotKey(hotKey)
                model.isRecordingHotKey = false
            })
        }
    }

    private var launchSection: some View {
        Toggle(isOn: Binding(
            get: { model.isLaunchAtLoginEnabled },
            set: { model.setLaunchAtLogin($0) }
        )) {
            Label("Launch at Login", systemImage: "power")
        }
        .font(.subheadline.weight(.semibold))
    }

    @ViewBuilder
    private var errorSection: some View {
        if let lastError = model.lastError {
            Label(lastError, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .lineLimit(3)
        }
    }

    private var footer: some View {
        HStack {
            Text(AppConstants.transcriptionModel)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .controlSize(.small)
        }
    }
}
