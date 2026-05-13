import Foundation

public final class HotKeyStore: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key = "toggleHotKey"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> HotKey {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(HotKey.self, from: data)
        else {
            return .defaultToggle
        }
        if decoded == .legacyHelpMenuToggle {
            save(.defaultToggle)
            return .defaultToggle
        }
        return decoded
    }

    public func save(_ hotKey: HotKey) {
        guard let data = try? JSONEncoder().encode(hotKey) else { return }
        defaults.set(data, forKey: key)
    }
}
