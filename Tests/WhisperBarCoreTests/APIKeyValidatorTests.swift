import Testing
@testable import WhisperBarCore

@Suite("API key validation")
struct APIKeyValidatorTests {
    @Test func trimsWhitespace() {
        #expect(APIKeyValidator.normalized("  sk-test-key\n") == "sk-test-key")
    }

    @Test func validatesOpenAIKeyShape() {
        #expect(APIKeyValidator.looksValid("sk-12345678901234567890"))
        #expect(!APIKeyValidator.looksValid("not-a-key"))
        #expect(!APIKeyValidator.looksValid("sk-short"))
        #expect(!APIKeyValidator.looksValid("sk-1234 5678901234567890"))
    }

    @Test func redactsLongKeys() {
        #expect(APIKeyValidator.redacted("sk-12345678901234567890") == "sk-1234...7890")
        #expect(APIKeyValidator.redacted(nil) == "Not set")
    }
}
