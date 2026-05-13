@preconcurrency import AVFoundation
import Foundation

public enum AudioConversionError: LocalizedError {
    case converterCreationFailed
    case conversionFailed
    case missingConvertedBuffer

    public var errorDescription: String? {
        switch self {
        case .converterCreationFailed:
            return "Could not create an audio converter."
        case .conversionFailed:
            return "Could not convert microphone audio."
        case .missingConvertedBuffer:
            return "Converted audio buffer was empty."
        }
    }
}

public final class PCM16Converter: @unchecked Sendable {
    private let outputFormat: AVAudioFormat

    public init(sampleRate: Double = Double(AppConstants.audioSampleRate)) {
        self.outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: true
        )!
    }

    public func convert(_ buffer: AVAudioPCMBuffer) throws -> Data {
        guard let converter = AVAudioConverter(from: buffer.format, to: outputFormat) else {
            throw AudioConversionError.converterCreationFailed
        }

        let ratio = outputFormat.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else {
            throw AudioConversionError.missingConvertedBuffer
        }

        let inputState = ConverterInputState(buffer: buffer)
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputState.didFeedInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputState.didFeedInput = true
            outStatus.pointee = .haveData
            return inputState.buffer
        }

        guard status != .error, error == nil else {
            throw AudioConversionError.conversionFailed
        }
        guard let channelData = outputBuffer.int16ChannelData else {
            throw AudioConversionError.missingConvertedBuffer
        }

        let frameCount = Int(outputBuffer.frameLength)
        return Data(bytes: channelData[0], count: frameCount * MemoryLayout<Int16>.size)
    }
}

private final class ConverterInputState: @unchecked Sendable {
    let buffer: AVAudioPCMBuffer
    var didFeedInput = false

    init(buffer: AVAudioPCMBuffer) {
        self.buffer = buffer
    }
}
