import Foundation
import Testing
@testable import WhisperBarCore

@Suite("API key metadata")
struct APIKeyMetadataStoreTests {
    @Test func defaultsToNoSavedKey() {
        let defaults = isolatedDefaults()
        let store = APIKeyMetadataStore(defaults: defaults)
        #expect(store.load() == APIKeyMetadata(hasSavedKey: false, redactedKey: "Not set"))
    }

    @Test func persistsRedactedKeyWithoutSecret() {
        let defaults = isolatedDefaults()
        let store = APIKeyMetadataStore(defaults: defaults)
        store.save(redactedKey: "sk-proj...1234")
        #expect(store.load() == APIKeyMetadata(hasSavedKey: true, redactedKey: "sk-proj...1234"))
    }

    @Test func clearsMetadata() {
        let defaults = isolatedDefaults()
        let store = APIKeyMetadataStore(defaults: defaults)
        store.save(redactedKey: "sk-proj...1234")
        store.clear()
        #expect(store.load() == APIKeyMetadata(hasSavedKey: false, redactedKey: "Not set"))
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "WhisperBarCoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
