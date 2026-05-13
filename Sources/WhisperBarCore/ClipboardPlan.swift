import Foundation

public struct ClipboardRestorePlan: Equatable, Sendable {
    public var dictatedText: String
    public var restoreDelayNanoseconds: UInt64

    public init(dictatedText: String, restoreDelayNanoseconds: UInt64 = 650_000_000) {
        self.dictatedText = dictatedText
        self.restoreDelayNanoseconds = restoreDelayNanoseconds
    }

    public var shouldPaste: Bool {
        !dictatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
