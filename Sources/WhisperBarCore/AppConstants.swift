import Foundation

public enum AppConstants {
    public static let appName = "WhisperBar"
    public static let bundleIdentifier = "ai.valprok.WhisperBar"
    public static let keychainService = "ai.valprok.WhisperBar.openai"
    public static let keychainAccount = "OpenAI API Key"
    public static let realtimeTranscriptionURL = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
    public static let transcriptionModel = "gpt-realtime-whisper"
    public static let audioSampleRate = 24_000
}
