import SwiftUI
import WhisperBarCore

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                usageSection
                apiSection
                permissionsSection
                hotKeySection
                launchSection
                errorSection
                footer
            }
            .padding(18)
        }
        .frame(width: 372, height: 560)
        .background(.regularMaterial)
        .onAppear {
            model.refreshUsageSummary()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
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
        }
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Cost", systemImage: "chart.bar.fill")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Picker("Range", selection: $model.selectedUsagePeriod) {
                    ForEach(UsagePeriod.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .controlSize(.small)
                .frame(width: 168)
            }

            HStack(spacing: 8) {
                metric("Tokens", value: tokenString(model.usageSummary.estimatedAudioTokens))
                metric("Minutes", value: minutesString(model.usageSummary.durationSeconds))
                metric("Cost", value: costString(model.usageSummary.estimatedCostUSD))
            }

            UsageBarChart(buckets: model.usageSummary.buckets)
                .frame(height: 54)

            Text("Estimated from local dictation duration at $0.017/min.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.callout, design: .rounded).weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var apiSection: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            HStack {
                Spacer()
                Button("Save Key") {
                    model.saveAPIKey()
                }
                .disabled(model.apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
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
            if status == "Allowed" {
                Label("Allowed", systemImage: "checkmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.green)
            } else {
                Button("Allow", action: action)
                    .controlSize(.small)
            }
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
            Text(model.hotKeyStatusText)
                .font(.caption2)
                .foregroundStyle(model.hotKeyStatusText == "Active" ? .green : .secondary)
            .background(HotKeyCaptureView(isRecording: $model.isRecordingHotKey) { hotKey in
                model.setHotKey(hotKey)
                model.isRecordingHotKey = false
            })
        }
    }

    private var launchSection: some View {
        HStack {
            Label("Launch at Login", systemImage: "power")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Toggle("", isOn: Binding(
                get: { model.isLaunchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
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
                .help(AppLogger.shared.logFilePath)
            Spacer()
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .controlSize(.small)
        }
    }

    private func tokenString(_ tokens: Int) -> String {
        if tokens >= 1_000 {
            return String(format: "%.1fk", Double(tokens) / 1_000)
        }
        return "\(tokens)"
    }

    private func minutesString(_ seconds: Double) -> String {
        String(format: "%.1f", seconds / 60)
    }

    private func costString(_ cost: Double) -> String {
        if cost < 0.01 {
            return String(format: "$%.4f", cost)
        }
        return String(format: "$%.2f", cost)
    }
}

private struct UsageBarChart: View {
    var buckets: [UsageBucket]

    private var maxSeconds: Double {
        max(1, buckets.map(\.durationSeconds).max() ?? 0)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(bucket.durationSeconds > 0 ? Color.accentColor : Color.secondary.opacity(0.18))
                        .frame(height: max(4, 38 * bucket.durationSeconds / maxSeconds))
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 3) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
                    Text(bucket.label)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 10)
        }
    }
}
