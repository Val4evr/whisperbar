import AVFoundation
import Foundation
import WhisperBarCore

final class AudioCapture {
    private let engine = AVAudioEngine()
    private let converter = PCM16Converter()
    private var onAudio: ((Data) -> Void)?

    func start(onAudio: @escaping (Data) -> Void) throws {
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
                // Surface conversion failures through the main dictation path on the next stop.
            }
        }
        engine.prepare()
        try engine.start()
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        onAudio = nil
    }
}
