import Foundation
import Testing
@testable import WhisperBarCore

@Suite("Usage ledger")
struct UsageLedgerTests {
    @Test func summarizesDurationTokensAndCost() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let entries = [
            UsageEntry(startedAt: now.addingTimeInterval(-60), durationSeconds: 30),
            UsageEntry(startedAt: now.addingTimeInterval(-90_000), durationSeconds: 45)
        ]

        let summary = UsageSummary(period: .day, entries: entries, now: now, calendar: calendar)

        #expect(summary.durationSeconds == 30)
        #expect(summary.estimatedAudioTokens == 300)
        #expect(summary.estimatedCostUSD == 30 / 60 * AppConstants.realtimeWhisperUSDPerMinute)
        #expect(summary.buckets.count == 24)
    }

    @Test func storeRoundTripsEntries() throws {
        let directory = try temporaryDirectory()
        let store = UsageLedgerStore(baseDirectory: directory)
        let entry = UsageEntry(startedAt: Date(timeIntervalSince1970: 123), durationSeconds: 12)

        try store.record(entry)

        #expect(store.load() == [entry])
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
