import Foundation
import Testing
@testable import WhisperBarCore

@Suite("File API key store")
struct FileAPIKeyStoreTests {
    @Test func roundTripsKeyAndNormalizesWhitespace() throws {
        let directory = try temporaryDirectory()
        let store = FileAPIKeyStore(baseDirectory: directory)

        #expect(try store.readAPIKey() == nil)
        try store.saveAPIKey("  sk-12345678901234567890\n")
        #expect(try store.readAPIKey() == "sk-12345678901234567890")
    }

    @Test func removesSavedKey() throws {
        let directory = try temporaryDirectory()
        let store = FileAPIKeyStore(baseDirectory: directory)

        try store.saveAPIKey("sk-12345678901234567890")
        try store.deleteAPIKey()
        #expect(try store.readAPIKey() == nil)
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
