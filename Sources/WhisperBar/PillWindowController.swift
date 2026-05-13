import AppKit
import SwiftUI

@MainActor
final class PillWindowController {
    private let panel: NSPanel
    private let model: AppModel

    init(model: AppModel) {
        self.model = model
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 138),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.contentView = NSHostingView(rootView: DictationPillView(model: model))
        self.panel = panel
    }

    func show() {
        positionPanel()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func positionPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let frame = screen.visibleFrame
        let size = panel.frame.size
        let x = frame.midX - size.width / 2
        let y = frame.maxY - size.height - 22
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

struct DictationPillView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.isRecording ? Color.red.opacity(0.14) : Color.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: model.isRecording ? "mic.fill" : "checkmark")
                    .foregroundStyle(model.isRecording ? .red : Color.accentColor)
                    .font(.system(size: 15, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(model.isRecording ? "Listening" : "Finishing")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Spacer()
                    if model.isRecording {
                        RecordingDots()
                    }
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        Text(model.liveTranscript.isEmpty ? " " : model.liveTranscript)
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.primary)
                            .lineSpacing(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("transcript-end")
                    }
                    .frame(maxHeight: 68)
                    .onChange(of: model.liveTranscript) { _, _ in
                        proxy.scrollTo("transcript-end", anchor: .bottom)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(width: 520, height: 138)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14))
        )
    }
}

struct RecordingDots: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.red.opacity(index == phase ? 0.95 : 0.32))
                    .frame(width: 5, height: 5)
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 280_000_000)
                await MainActor.run {
                    phase = (phase + 1) % 3
                }
            }
        }
    }
}
