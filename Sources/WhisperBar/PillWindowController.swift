import AppKit
import SwiftUI

@MainActor
final class PillWindowController {
    private let panel: NSPanel
    private let model: AppModel
    private var hasCustomPosition = false

    init(model: AppModel) {
        self.model = model
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 584, height: 172),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        self.panel = panel
        panel.contentView = TransparentHostingView(rootView: DictationPillView(
            model: model,
            onDragStarted: { [weak self] in
                self?.hasCustomPosition = true
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

}

struct DictationPillView: View {
    @ObservedObject var model: AppModel
    var onDragStarted: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                HStack(spacing: 12) {
                    LiveAudioBars(level: model.audioLevel, isActive: model.isRecording)
                        .frame(width: 48, height: 24)

                    Text(model.isRecording ? "Listening" : "Finishing")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Spacer()
                }

                WindowDragHandle(onDragStarted: onDragStarted)
            }
            .frame(height: 24)

            TranscriptTextView(text: model.liveTranscript)
                .frame(height: 78)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 560, height: 148)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.26), radius: 18, x: 0, y: 12)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.16))
        }
        .padding(12)
    }
}

struct LiveAudioBars: View {
    let level: Double
    let isActive: Bool

    private let bars = 7

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let energy = isActive ? min(1, pow(max(level, 0.035) * 2.4, 0.58)) : 0

            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<bars, id: \.self) { index in
                    let phase = time * 7.5 + Double(index) * 0.82
                    let wave = (sin(phase) + 1) / 2
                    let centerBias = 1 - abs(Double(index) - Double(bars - 1) / 2) * 0.08
                    let height = isActive ? 5 + energy * centerBias * (7 + wave * 14) : 5

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isActive ? Color.accentColor.opacity(0.95) : Color.secondary.opacity(0.32))
                        .frame(width: 4, height: height)
                        .animation(.easeOut(duration: 0.08), value: level)
                }
            }
        }
    }
}

final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }

    required init(rootView: Content) {
        super.init(rootView: rootView)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct WindowDragHandle: NSViewRepresentable {
    var onDragStarted: () -> Void

    func makeNSView(context: Context) -> DragHandleView {
        let view = DragHandleView()
        view.onDragStarted = onDragStarted
        return view
    }

    func updateNSView(_ nsView: DragHandleView, context: Context) {
        nsView.onDragStarted = onDragStarted
    }
}

final class DragHandleView: NSView {
    var onDragStarted: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onDragStarted?()
        window?.performDrag(with: event)
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
