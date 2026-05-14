public protocol APIKeyStoring: Sendable {
    func readAPIKey() throws -> String?
    func saveAPIKey(_ value: String) throws
    func deleteAPIKey() throws
}
