import Foundation
import Security

public enum KeychainStoreError: LocalizedError, Equatable {
    case unexpectedStatus(OSStatus)
    case invalidData

    public var errorDescription: String? {
        switch self {
        case .unexpectedStatus(let status):
            return "Keychain returned status \(status)."
        case .invalidData:
            return "The saved keychain item was not valid text."
        }
    }
}

public protocol APIKeyStoring: Sendable {
    func readAPIKey() throws -> String?
    func saveAPIKey(_ value: String) throws
    func deleteAPIKey() throws
}

public final class KeychainAPIKeyStore: APIKeyStoring, @unchecked Sendable {
    private let service: String
    private let account: String

    public init(service: String = AppConstants.keychainService, account: String = AppConstants.keychainAccount) {
        self.service = service
        self.account = account
    }

    public func readAPIKey() throws -> String? {
        AppLogger.shared.info("Reading API key from Keychain")
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            AppLogger.shared.info("No API key found in Keychain")
            return nil
        }
        guard status == errSecSuccess else {
            AppLogger.shared.error("Keychain read failed with status \(status)")
            throw KeychainStoreError.unexpectedStatus(status)
        }
        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            AppLogger.shared.error("Keychain read returned invalid data")
            throw KeychainStoreError.invalidData
        }
        return value
    }

    public func saveAPIKey(_ value: String) throws {
        AppLogger.shared.info("Saving API key to Keychain")
        let normalized = APIKeyValidator.normalized(value)
        let data = Data(normalized.utf8)
        var query = baseQuery()

        let update: [String: Any] = [
            kSecValueData as String: data
        ]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return }
        if status != errSecItemNotFound {
            AppLogger.shared.error("Keychain update failed with status \(status)")
            throw KeychainStoreError.unexpectedStatus(status)
        }

        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            AppLogger.shared.error("Keychain add failed with status \(addStatus)")
            throw KeychainStoreError.unexpectedStatus(addStatus)
        }
    }

    public func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound { return }
        throw KeychainStoreError.unexpectedStatus(status)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
