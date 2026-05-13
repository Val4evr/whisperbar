import Foundation

public enum APIKeyValidator {
    public static func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func looksValid(_ value: String) -> Bool {
        let key = normalized(value)
        return key.hasPrefix("sk-") && key.count >= 20 && !key.contains(" ")
    }

    public static func redacted(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "Not set" }
        let key = normalized(value)
        guard key.count > 12 else { return "Saved" }
        return "\(key.prefix(7))...\(key.suffix(4))"
    }
}
