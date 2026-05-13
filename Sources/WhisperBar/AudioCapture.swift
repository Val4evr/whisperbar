import AVFoundation
import Foundation
import WhisperBarCore

final class AudioCapture {
    private let engine = AVAudioEngine()
    private let converter = PCM16Converter()
    private var onAudio: ((Data) -> Void)?

    func start(onAudio: @escaping (Data) -> Void) throws {
        AppLogger.shared.info("Starting microphone capture")
        self.onAudio = onAudio
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            do {
                let data = try self.converter.convert(buffer)
                if !data.isEmpty {
                    self.onAudio?(data)
                }
            } catch {
                AppLogger.shared.error("Audio conversion failed: \(error.localizedDescription)")
            }
        }
        engine.prepare()
        try engine.start()
        AppLogger.shared.info("Microphone capture started")
    }

    func stop() {
        AppLogger.shared.info("Stopping microphone capture")
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        onAudio = nil
    }
}
