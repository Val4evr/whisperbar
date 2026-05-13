import Foundation

public enum FileAPIKeyStoreError: LocalizedError, Equatable {
    case invalidDirectory
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .invalidDirectory:
            return "Could not create the app support directory."
        case .invalidData:
            return "The saved API key file was not valid text."
        }
    }
}

public final class FileAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private let fileURL: URL
    private let fileManager: FileManager

    public init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        let directory = baseDirectory ?? fileManager
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/WhisperBar", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("openai.key")
    }

    public func readAPIKey() throws -> String? {
        AppLogger.shared.info("Reading API key from app support secret file")
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        guard let value = String(data: data, encoding: .utf8) else {
            throw FileAPIKeyStoreError.invalidData
        }
        return APIKeyValidator.normalized(value)
    }

    public func saveAPIKey(_ value: String) throws {
        AppLogger.shared.info("Saving API key to app support secret file")
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let normalized = APIKeyValidator.normalized(value)
        try Data(normalized.utf8).write(to: fileURL, options: .atomic)
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    public func deleteAPIKey() throws {
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
}
