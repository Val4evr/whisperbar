import AVFoundation
import Foundation
import WhisperBarCore

@MainActor
final class DictationController: NSObject {
    private let model: AppModel
    private let pillController: PillWindowController
    private let audioCapture = AudioCapture()
    private let pasteboardCoordinator = PasteboardCoordinator()
    private var realtimeClient: RealtimeTranscriptionClient?
    private var finalTranscripts: [String] = []

    init(model: AppModel, pillController: PillWindowController) {
        self.model = model
        self.pillController = pillController
        super.init()
    }

    func toggleDictation() {
        if model.isRecording {
            stopDictation()
        } else {
            startDictation()
        }
    }

    func cancel() {
        audioCapture.stop()
        realtimeClient?.disconnect()
        realtimeClient = nil
        pillController.hide()
        model.isRecording = false
    }

    private func startDictation() {
        guard !model.isRecording else { return }
        guard AXIsProcessTrusted() else {
            model.lastError = "Accessibility permission is required for the global hotkey and paste."
            AppLogger.shared.error(model.lastError ?? "Accessibility permission missing")
            return
        }
        guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
            model.lastError = "Microphone permission is required."
            AppLogger.shared.error(model.lastError ?? "Microphone permission missing")
            model.requestMicrophonePermission()
            return
        }

        do {
            guard let apiKey = try model.readAPIKey(), APIKeyValidator.looksValid(apiKey) else {
                model.lastError = "Add your OpenAI API key first."
                AppLogger.shared.error(model.lastError ?? "Missing API key")
                return
            }

            finalTranscripts = []
            model.liveTranscript = ""
            model.lastError = nil
            model.statusText = "Connecting"
            model.isRecording = true
            pillController.show()

            let client = RealtimeTranscriptionClient(apiKey: apiKey)
            client.delegate = self
            realtimeClient = client
            client.connect()

            try audioCapture.start { [weak self] data in
                self?.realtimeClient?.appendAudio(data)
            }
            model.statusText = "Listening"
        } catch {
            model.lastError = error.localizedDescription
            AppLogger.shared.error("Failed to start dictation: \(error.localizedDescription)")
            cancel()
        }
    }

    private func stopDictation() {
        guard model.isRecording else { return }
        AppLogger.shared.info("Stopping dictation")
        model.isRecording = false
        model.statusText = "Finishing"
        audioCapture.stop()
        realtimeClient?.commit()

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await self?.finishAndPaste()
        }
    }

    private func finishAndPaste() async {
        let text = finalTranscriptText()
        realtimeClient?.disconnect()
        realtimeClient = nil
        pillController.hide()
        model.statusText = "Ready"
        model.liveTranscript = ""
        if !text.isEmpty {
            await pasteboardCoordinator.pasteAndRestore(ClipboardRestorePlan(dictatedText: text))
        }
    }

    private func finalTranscriptText() -> String {
        let completed = finalTranscripts.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if !completed.isEmpty {
            return completed
        }
        return model.liveTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension DictationController: RealtimeTranscriptionClientDelegate {
    nonisolated func realtimeClient(_ client: RealtimeTranscriptionClient, didReceive event: RealtimeTranscriptionEvent) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            switch event {
            case .delta(_, let text):
                self.model.liveTranscript += text
            case .completed(_, let transcript):
                let normalized = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !normalized.isEmpty {
                    self.finalTranscripts.append(normalized)
                    self.model.liveTranscript = self.finalTranscripts.joined(separator: " ")
                }
            case .error(let message):
                self.model.lastError = message
                AppLogger.shared.error("Realtime API error: \(message)")
                self.model.statusText = "Error"
            case .sessionCreated, .sessionUpdated:
                if self.model.isRecording {
                    self.model.statusText = "Listening"
                }
            case .committed, .ignored:
                break
            }
        }
    }

    nonisolated func realtimeClient(_ client: RealtimeTranscriptionClient, didFail error: Error) {
        Task { @MainActor [weak self] in
            self?.model.lastError = error.localizedDescription
            AppLogger.shared.error("Realtime client failed: \(error.localizedDescription)")
            self?.model.statusText = "Error"
        }
    }
}
