import Foundation

public final class AppLogger: @unchecked Sendable {
    public static let shared = AppLogger()

    private let queue = DispatchQueue(label: "ai.valprok.WhisperBar.logger")
    private let fileURL: URL
    private let dateFormatter: ISO8601DateFormatter

    public init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) {
        let directory = baseDirectory ?? fileManager
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/WhisperBar", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("WhisperBar.log")
        self.dateFormatter = ISO8601DateFormatter()
    }

    public var logFilePath: String {
        fileURL.path
    }

    public func info(_ message: String) {
        write(level: "INFO", message: message)
    }

    public func error(_ message: String) {
        write(level: "ERROR", message: message)
    }

    private func write(level: String, message: String) {
        let timestamp = dateFormatter.string(from: Date())
        let line = "\(timestamp) [\(level)] \(message)\n"
        queue.async { [fileURL] in
            guard let data = line.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    defer { try? handle.close() }
                    _ = try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                }
            } else {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }
}
