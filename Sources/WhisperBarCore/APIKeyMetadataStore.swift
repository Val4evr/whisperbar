import Foundation

public struct APIKeyMetadata: Equatable, Sendable {
    public var hasSavedKey: Bool
    public var redactedKey: String

    public init(hasSavedKey: Bool = false, redactedKey: String = "Not set") {
        self.hasSavedKey = hasSavedKey
        self.redactedKey = redactedKey
    }
}

public final class APIKeyMetadataStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let hasSavedKeyKey = "openAIAPIKey.hasSavedKey"
    private let redactedKeyKey = "openAIAPIKey.redacted"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> APIKeyMetadata {
        let hasSavedKey = defaults.bool(forKey: hasSavedKeyKey)
        let redacted = defaults.string(forKey: redactedKeyKey)
        return APIKeyMetadata(
            hasSavedKey: hasSavedKey,
            redactedKey: hasSavedKey ? (redacted ?? "Saved") : "Not set"
        )
    }

    public func save(redactedKey: String) {
        defaults.set(true, forKey: hasSavedKeyKey)
        defaults.set(redactedKey, forKey: redactedKeyKey)
    }

    public func clear() {
        defaults.set(false, forKey: hasSavedKeyKey)
        defaults.removeObject(forKey: redactedKeyKey)
    }
}
