import AVFoundation
import Foundation
import WhisperBarCore

final class AudioCapture {
    private let engine = AVAudioEngine()
    private let converter = PCM16Converter()
    private var onAudio: ((Data, Double) -> Void)?

    func start(onAudio: @escaping (Data, Double) -> Void) throws {
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
                    self.onAudio?(data, Self.level(from: buffer))
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

    private static func level(from buffer: AVAudioPCMBuffer) -> Double {
        guard let channelData = buffer.floatChannelData else { return 0 }
        let channelCount = Int(buffer.format.channelCount)
        let frameCount = Int(buffer.frameLength)
        guard channelCount > 0, frameCount > 0 else { return 0 }

        var sum: Float = 0
        for channel in 0..<channelCount {
            let samples = channelData[channel]
            for frame in 0..<frameCount {
                let sample = samples[frame]
                sum += sample * sample
            }
        }

        let rms = sqrt(sum / Float(frameCount * channelCount))
        let normalized = min(1, max(0, Double(rms) * 14))
        return normalized
    }
}
