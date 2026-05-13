import Testing
@testable import WhisperBarCore

@Suite("Clipboard restore plan")
struct ClipboardPlanTests {
    @Test func skipsEmptyTranscript() {
        #expect(!ClipboardRestorePlan(dictatedText: "   ").shouldPaste)
        #expect(ClipboardRestorePlan(dictatedText: "Hello").shouldPaste)
    }

    @Test func hasHistoryFriendlyDefaultDelay() {
        #expect(ClipboardRestorePlan(dictatedText: "Hello").restoreDelayNanoseconds == 650_000_000)
    }
}
