import Foundation

public enum RealtimeRequestFactory {
    public static func sessionUpdate(language: String? = "en") throws -> Data {
        var transcription: [String: Any] = [
            "model": AppConstants.transcriptionModel
        ]
        if let language, !language.isEmpty {
            transcription["language"] = language
        }

        let input: [String: Any] = [
            "format": [
                "type": "audio/pcm",
                "rate": AppConstants.audioSampleRate
            ],
            "transcription": transcription
        ]

        let payload: [String: Any] = [
            "type": "session.update",
            "session": [
                "type": "transcription",
                "audio": [
                    "input": input
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    public static func appendAudio(_ pcm16: Data) throws -> Data {
        let payload: [String: Any] = [
            "type": "input_audio_buffer.append",
            "audio": pcm16.base64EncodedString()
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }

    public static func commitAudio() throws -> Data {
        try JSONSerialization.data(withJSONObject: ["type": "input_audio_buffer.commit"])
    }
}
