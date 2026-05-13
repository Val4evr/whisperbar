import Foundation
import Testing
@testable import WhisperBarCore

@Suite("Keychain store contract")
struct KeychainStoreTests {
    @Test func memoryStoreRoundTripsLikeTheKeychainWrapper() throws {
        let store = MemoryAPIKeyStore()
        #expect(try store.readAPIKey() == nil)
        try store.saveAPIKey("  sk-12345678901234567890\n")
        #expect(try store.readAPIKey() == "sk-12345678901234567890")
        try store.deleteAPIKey()
        #expect(try store.readAPIKey() == nil)
    }
}

private final class MemoryAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private var value: String?

    func readAPIKey() throws -> String? {
        value
    }

    func saveAPIKey(_ value: String) throws {
        self.value = APIKeyValidator.normalized(value)
    }

    func deleteAPIKey() throws {
        value = nil
    }
}
