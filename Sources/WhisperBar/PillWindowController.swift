import AppKit
import SwiftUI

@MainActor
final class PillWindowController {
    private let panel: NSPanel
    private let model: AppModel
    private var lastDragTranslation: CGSize = .zero
    private var hasCustomPosition = false

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
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.panel = panel
        panel.contentView = NSHostingView(rootView: DictationPillView(
            model: model,
            onDragChanged: { [weak self] translation in
                self?.dragChanged(translation)
            },
            onDragEnded: { [weak self] in
                self?.lastDragTranslation = .zero
            }
        ))
    }

    func show() {
        if !hasCustomPosition {
            positionPanel()
        }
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

    private func dragChanged(_ translation: CGSize) {
        hasCustomPosition = true
        let delta = CGSize(
            width: translation.width - lastDragTranslation.width,
            height: translation.height - lastDragTranslation.height
        )
        lastDragTranslation = translation
        let origin = panel.frame.origin
        panel.setFrameOrigin(NSPoint(x: origin.x + delta.width, y: origin.y - delta.height))
    }
}

struct DictationPillView: View {
    @ObservedObject var model: AppModel
    var onDragChanged: (CGSize) -> Void
    var onDragEnded: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                LiveAudioBars(level: model.audioLevel, isActive: model.isRecording)
                    .frame(width: 46, height: 22)

                Text(model.isRecording ? "Listening" : "Finishing")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Text("Ctrl Opt Space")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: Capsule())
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in
                        onDragChanged(value.translation)
                    }
                    .onEnded { _ in
                        onDragEnded()
                    }
            )

            TranscriptTextView(text: model.liveTranscript)
                .frame(height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 560, height: 148)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.16))
        }
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 12)
    }
}

struct LiveAudioBars: View {
    let level: Double
    let isActive: Bool

    private let bars = 7

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(0..<bars, id: \.self) { index in
                let distance = abs(Double(index) - Double(bars - 1) / 2)
                let response = max(0.18, level * (1.14 - distance * 0.13))
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isActive ? Color.accentColor.opacity(0.95) : Color.secondary.opacity(0.32))
                    .frame(width: 4, height: 4 + response * 18)
                    .animation(.interactiveSpring(response: 0.18, dampingFraction: 0.76), value: level)
            }
        }
    }
}

struct TranscriptTextView: NSViewRepresentable {
    var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.drawsBackground = false
        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        textView.font = NSFont.systemFont(ofSize: 16, weight: .regular)
        textView.textColor = .labelColor
        textView.string = text
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.autoresizingMask = [.width]

        scrollView.documentView = textView
        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        let shouldFollowBottom = context.coordinator.isNearBottom(scrollView)
        if textView.string != text {
            textView.string = text.isEmpty ? " " : text
            textView.font = NSFont.systemFont(ofSize: 16, weight: .regular)
            textView.textColor = .labelColor
        }
        if shouldFollowBottom {
            context.coordinator.scrollToBottom(scrollView)
        }
    }

    @MainActor
    final class Coordinator {
        weak var textView: NSTextView?

        func isNearBottom(_ scrollView: NSScrollView) -> Bool {
            guard let documentView = scrollView.documentView else { return true }
            let visible = scrollView.contentView.bounds
            let bottomGap = documentView.bounds.maxY - visible.maxY
            return bottomGap < 20
        }

        func scrollToBottom(_ scrollView: NSScrollView) {
            guard let documentView = scrollView.documentView else { return }
            let visibleHeight = scrollView.contentView.bounds.height
            let maxY = max(0, documentView.bounds.height - visibleHeight)
            scrollView.contentView.scroll(to: NSPoint(x: 0, y: maxY))
            scrollView.reflectScrolledClipView(scrollView.contentView)
        }
    }
}
