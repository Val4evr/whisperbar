import SwiftUI
import WhisperBarCore

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            usageSection
            Divider()
            apiSection
            Divider()
            permissionsSection
            Divider()
            hotKeySection
            Divider()
            launchSection
            errorSection
        }
        .padding(.horizontal, 22)
        .padding(.top, 24)
        .padding(.bottom, 26)
        .frame(width: 372, height: 500)
        .background(.regularMaterial)
        .onAppear {
            model.refreshUsageSummary()
        }
    }

    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Cost", systemImage: "chart.bar.fill", isHealthy: model.hasUsage)
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
            .padding(.bottom, 8)

            UsageBarChart(period: model.selectedUsagePeriod, buckets: model.usageSummary.buckets)
                .frame(height: 70)
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
            sectionTitle("OpenAI API Key", systemImage: "key.fill", isHealthy: model.hasAPIKey)
            HStack {
                apiKeyField

                if model.isAPIKeyFieldReadOnly {
                    Button("Remove", role: .destructive) {
                        model.beginAPIKeyRemoval()
                    }
                    .controlSize(.small)
                } else {
                    Button("Save Key") {
                        model.saveAPIKey()
                    }
                    .controlSize(.small)
                    .disabled(model.apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    private var apiKeyField: some View {
        if model.isAPIKeyFieldReadOnly {
            Text(model.apiKeySummary)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                .padding(.horizontal, 8)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                .help("API key saved")
        } else {
            TextField(apiKeyPlaceholder, text: $model.apiKeyDraft)
                .textFieldStyle(.roundedBorder)
                .textContentType(.password)
                .disableAutocorrection(true)
                .onSubmit {
                    model.saveAPIKey()
                }
        }
    }

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Permissions", systemImage: "checkmark.shield.fill", isHealthy: model.hasRequiredPermissions)
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
                if status != "Allowed" {
                    Text(status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if status == "Allowed" {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.green)
            } else {
                Button("Allow", action: action)
                    .controlSize(.small)
            }
        }
    }

    private var hotKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Hotkey", systemImage: "keyboard", isHealthy: model.hasConfiguredHotKey)
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
        HStack {
            sectionTitle("Launch at Login", systemImage: "power", isHealthy: model.isLaunchAtLoginEnabled)
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

    private var apiKeyPlaceholder: String {
        model.apiKeyInputPlaceholder
    }

    private func sectionTitle(_ title: String, systemImage: String, isHealthy: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isHealthy ? .green : .red)
                .frame(width: 18, height: 18)
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

private struct UsageBarChart: View {
    var period: UsagePeriod
    var buckets: [UsageBucket]
    @State private var hoveredIndex: Int?

    private var maxSeconds: Double {
        max(1, buckets.map(\.durationSeconds).max() ?? 0)
    }

    private var hoveredBucket: UsageBucket? {
        guard let hoveredIndex, buckets.indices.contains(hoveredIndex) else { return nil }
        return buckets[hoveredIndex]
    }

    var body: some View {
        VStack(spacing: 5) {
            Text(hoverText)
                .font(.caption2)
                .foregroundStyle(hoveredBucket == nil ? .clear : .secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(barColor(bucket: bucket, index: index))
                        .frame(height: max(4, 38 * bucket.durationSeconds / maxSeconds))
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onHover { isHovering in
                            hoveredIndex = isHovering ? index : (hoveredIndex == index ? nil : hoveredIndex)
                        }
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

    private var hoverText: String {
        guard let hoveredBucket else {
            return " "
        }
        let tokens = Int((hoveredBucket.durationSeconds * AppConstants.estimatedAudioTokensPerSecond).rounded())
        let cost = hoveredBucket.durationSeconds / 60 * AppConstants.realtimeWhisperUSDPerMinute
        return "\(period.bucketTitle) \(hoveredBucket.detailLabel) · \(tokens) tokens · \(minutesString(hoveredBucket.durationSeconds)) min · \(costString(cost))"
    }

    private func barColor(bucket: UsageBucket, index: Int) -> Color {
        guard bucket.durationSeconds > 0 else {
            return hoveredIndex == index ? Color.secondary.opacity(0.32) : Color.secondary.opacity(0.18)
        }
        return hoveredIndex == index ? Color.accentColor : Color.accentColor.opacity(0.74)
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
