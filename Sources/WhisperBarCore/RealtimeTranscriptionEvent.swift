import Foundation

public enum RealtimeTranscriptionEvent: Equatable, Sendable {
    case delta(itemID: String?, text: String)
    case completed(itemID: String?, transcript: String)
    case sessionCreated
    case sessionUpdated
    case committed
    case error(message: String)
    case ignored(type: String?)
}

public enum RealtimeTranscriptionEventParser {
    public static func parse(_ data: Data) throws -> RealtimeTranscriptionEvent {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dict = object as? [String: Any] else {
            return .ignored(type: nil)
        }

        let type = dict["type"] as? String
        switch type {
        case "conversation.item.input_audio_transcription.delta":
            return .delta(itemID: dict["item_id"] as? String, text: dict["delta"] as? String ?? "")
        case "conversation.item.input_audio_transcription.completed":
            return .completed(itemID: dict["item_id"] as? String, transcript: dict["transcript"] as? String ?? "")
        case "session.created":
            return .sessionCreated
        case "transcription_session.created":
            return .sessionCreated
        case "session.updated":
            return .sessionUpdated
        case "transcription_session.updated":
            return .sessionUpdated
        case "input_audio_buffer.committed":
            return .committed
        case "error":
            return .error(message: parseErrorMessage(from: dict))
        default:
            return .ignored(type: type)
        }
    }

    private static func parseErrorMessage(from dict: [String: Any]) -> String {
        if let error = dict["error"] as? [String: Any] {
            if let message = error["message"] as? String {
                return message
            }
            if let code = error["code"] as? String {
                return code
            }
        }
        return dict["message"] as? String ?? "Unknown Realtime API error"
    }
}
