import Foundation

public enum UsagePeriod: String, CaseIterable, Codable, Identifiable, Sendable {
    case day
    case week
    case month

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        }
    }

    var bucketCount: Int {
        switch self {
        case .day: return 24
        case .week: return 7
        case .month: return 30
        }
    }

    func startDate(now: Date, calendar: Calendar) -> Date {
        switch self {
        case .day:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        case .month:
            return calendar.date(byAdding: .day, value: -29, to: calendar.startOfDay(for: now)) ?? now
        }
    }
}

public struct UsageEntry: Codable, Equatable, Sendable {
    public var startedAt: Date
    public var durationSeconds: Double
    public var model: String

    public init(startedAt: Date, durationSeconds: Double, model: String = AppConstants.transcriptionModel) {
        self.startedAt = startedAt
        self.durationSeconds = max(0, durationSeconds)
        self.model = model
    }
}

public struct UsageBucket: Equatable, Sendable {
    public var label: String
    public var durationSeconds: Double

    public init(label: String, durationSeconds: Double) {
        self.label = label
        self.durationSeconds = durationSeconds
    }
}

public struct UsageSummary: Equatable, Sendable {
    public var period: UsagePeriod
    public var durationSeconds: Double
    public var estimatedAudioTokens: Int
    public var estimatedCostUSD: Double
    public var buckets: [UsageBucket]

    public init(period: UsagePeriod, entries: [UsageEntry], now: Date = Date(), calendar: Calendar = .current) {
        self.period = period
        let start = period.startDate(now: now, calendar: calendar)
        let included = entries.filter { $0.startedAt >= start && $0.startedAt <= now }
        self.durationSeconds = included.reduce(0) { $0 + $1.durationSeconds }
        self.estimatedAudioTokens = Int((durationSeconds * AppConstants.estimatedAudioTokensPerSecond).rounded())
        self.estimatedCostUSD = durationSeconds / 60 * AppConstants.realtimeWhisperUSDPerMinute
        self.buckets = Self.makeBuckets(period: period, entries: included, now: now, calendar: calendar)
    }

    public static var emptyDay: UsageSummary {
        UsageSummary(period: .day, entries: [])
    }

    private static func makeBuckets(
        period: UsagePeriod,
        entries: [UsageEntry],
        now: Date,
        calendar: Calendar
    ) -> [UsageBucket] {
        let dayStart = calendar.startOfDay(for: now)
        switch period {
        case .day:
            return (0..<24).map { hour in
                let seconds = entries
                    .filter { calendar.component(.hour, from: $0.startedAt) == hour }
                    .reduce(0) { $0 + $1.durationSeconds }
                return UsageBucket(label: hour % 6 == 0 ? "\(hour)" : "", durationSeconds: seconds)
            }
        case .week:
            return (0..<7).map { offset in
                let date = calendar.date(byAdding: .day, value: offset - 6, to: dayStart) ?? now
                let seconds = entries
                    .filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.durationSeconds }
                let label = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                return UsageBucket(label: String(label.prefix(1)), durationSeconds: seconds)
            }
        case .month:
            return (0..<30).map { offset in
                let date = calendar.date(byAdding: .day, value: offset - 29, to: dayStart) ?? now
                let seconds = entries
                    .filter { calendar.isDate($0.startedAt, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.durationSeconds }
                let day = calendar.component(.day, from: date)
                return UsageBucket(label: offset % 7 == 0 ? "\(day)" : "", durationSeconds: seconds)
            }
        }
    }
}

public final class UsageLedgerStore: @unchecked Sendable {
    private let fileURL: URL
    private let fileManager: FileManager
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(fileManager: FileManager = .default, baseDirectory: URL? = nil) {
        self.fileManager = fileManager
        let directory = baseDirectory ?? fileManager
            .homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/WhisperBar", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("usage.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    public func load() -> [UsageEntry] {
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let entries = try? decoder.decode([UsageEntry].self, from: data) else {
            return []
        }
        return entries
    }

    public func record(_ entry: UsageEntry) throws {
        var entries = load()
        entries.append(entry)
        try save(entries)
    }

    private func save(_ entries: [UsageEntry]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }
}
