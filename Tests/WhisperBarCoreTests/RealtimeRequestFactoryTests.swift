import Foundation
import Testing
@testable import WhisperBarCore

@Suite("Realtime requests")
struct RealtimeRequestFactoryTests {
    @Test func sessionUpdateUsesWhisperAndPCM24k() throws {
        let data = try RealtimeRequestFactory.sessionUpdate()
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["type"] as? String == "session.update")
        let session = try #require(object["session"] as? [String: Any])
        #expect(session["type"] as? String == "transcription")
        let audio = try #require(session["audio"] as? [String: Any])
        let input = try #require(audio["input"] as? [String: Any])
        let format = try #require(input["format"] as? [String: Any])
        #expect(format["type"] as? String == "audio/pcm")
        #expect(format["rate"] as? Int == 24_000)
        let transcription = try #require(input["transcription"] as? [String: Any])
        #expect(transcription["model"] as? String == "gpt-realtime-whisper")
        #expect(input["turn_detection"] == nil)
    }

    @Test func appendAudioBase64EncodesPCM() throws {
        let data = try RealtimeRequestFactory.appendAudio(Data([1, 2, 3, 4]))
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["type"] as? String == "input_audio_buffer.append")
        #expect(object["audio"] as? String == "AQIDBA==")
    }
}
