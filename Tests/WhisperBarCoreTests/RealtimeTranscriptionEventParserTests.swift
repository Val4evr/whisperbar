import Foundation
import Testing
@testable import WhisperBarCore

@Suite("Realtime event parser")
struct RealtimeTranscriptionEventParserTests {
    @Test func parsesDeltaEvent() throws {
        let event = try parse("""
        {
          "type": "conversation.item.input_audio_transcription.delta",
          "item_id": "item_123",
          "content_index": 0,
          "delta": "Hello"
        }
        """)
        #expect(event == .delta(itemID: "item_123", text: "Hello"))
    }

    @Test func parsesCompletionEvent() throws {
        let event = try parse("""
        {
          "type": "conversation.item.input_audio_transcription.completed",
          "item_id": "item_123",
          "content_index": 0,
          "transcript": "Hello world"
        }
        """)
        #expect(event == .completed(itemID: "item_123", transcript: "Hello world"))
    }

    @Test func parsesErrorEvent() throws {
        let event = try parse("""
        {
          "type": "error",
          "error": {
            "message": "Incorrect API key provided"
          }
        }
        """)
        #expect(event == .error(message: "Incorrect API key provided"))
    }

    @Test func ignoresUnknownEvents() throws {
        let event = try parse("""
        { "type": "rate_limits.updated" }
        """)
        #expect(event == .ignored(type: "rate_limits.updated"))
    }

    @Test func acceptsTranscriptionSessionLifecycleEvents() throws {
        #expect(try parse(#"{ "type": "transcription_session.created" }"#) == .sessionCreated)
        #expect(try parse(#"{ "type": "transcription_session.updated" }"#) == .sessionUpdated)
    }

    private func parse(_ json: String) throws -> RealtimeTranscriptionEvent {
        try RealtimeTranscriptionEventParser.parse(Data(json.utf8))
    }
}
