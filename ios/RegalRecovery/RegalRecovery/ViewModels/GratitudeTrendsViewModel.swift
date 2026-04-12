import Foundation

// MARK: - Supporting Types

enum TrendPeriod: String, CaseIterable, Identifiable {
    case thirtyDay = "30d"
    case ninetyDay = "90d"
    case allTime = "All"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .thirtyDay: return 30
        case .ninetyDay: return 90
        case .allTime: return nil
        }
    }
}

struct GratitudeStreakData {
    let currentStreak: Int
    let longestStreak: Int
    let totalDaysWithEntries: Int
}

struct CategoryBreakdownItem: Identifiable {
    let category: GratitudeCategory
    let count: Int
    let percentage: Double

    var id: String { category.rawValue }
}

struct WeeklyEntryData: Identifiable {
    let weekLabel: String
    let daysWithEntries: Int

    var id: String { weekLabel }
}

// MARK: - View Model

@Observable
class GratitudeTrendsViewModel {

    var selectedPeriod: TrendPeriod = .thirtyDay

    private let calendar = Calendar.current

    // MARK: - Streak

    func streakData(from entries: [RRGratitudeEntry]) -> GratitudeStreakData {
        let uniqueDays = uniqueCalendarDays(from: entries)
        guard !uniqueDays.isEmpty else {
            return GratitudeStreakData(currentStreak: 0, longestStreak: 0, totalDaysWithEntries: 0)
        }

        let sortedDays = uniqueDays.sorted(by: >)
        let currentStreak = computeCurrentStreak(sortedDays: sortedDays)
        let longestStreak = computeLongestStreak(sortedDays: sortedDays)

        return GratitudeStreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysWithEntries: uniqueDays.count
        )
    }

    private func computeCurrentStreak(sortedDays: [Date]) -> Int {
        let today = calendar.startOfDay(for: Date())

        guard let mostRecent = sortedDays.first else { return 0 }

        // Streak must include today or yesterday to be "current"
        let daysSinceLast = calendar.dateComponents([.day], from: mostRecent, to: today).day ?? 0
        guard daysSinceLast <= 1 else { return 0 }

        var streak = 1
        var expectedDate = mostRecent

        for i in 1..<sortedDays.count {
            let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            if calendar.isDate(sortedDays[i], inSameDayAs: previousDay) {
                streak += 1
                expectedDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    private func computeLongestStreak(sortedDays: [Date]) -> Int {
        guard sortedDays.count > 1 else { return sortedDays.count }

        // Work from oldest to newest for longest streak
        let ascending = sortedDays.reversed() as [Date]
        var longest = 1
        var current = 1

        for i in 1..<ascending.count {
            let expectedNext = calendar.date(byAdding: .day, value: 1, to: ascending[i - 1])!
            if calendar.isDate(ascending[i], inSameDayAs: expectedNext) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    private func uniqueCalendarDays(from entries: [RRGratitudeEntry]) -> [Date] {
        var seen = Set<String>()
        var result: [Date] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for entry in entries {
            let key = formatter.string(from: entry.date)
            if seen.insert(key).inserted {
                result.append(calendar.startOfDay(for: entry.date))
            }
        }

        return result
    }

    // MARK: - Category Breakdown

    func categoryBreakdown(from entries: [RRGratitudeEntry], period: TrendPeriod) -> [CategoryBreakdownItem] {
        let filtered = filteredEntries(entries, period: period)
        var counts: [GratitudeCategory: Int] = [:]

        for entry in filtered {
            for item in entry.items {
                if let category = item.category {
                    counts[category, default: 0] += 1
                }
            }
        }

        let total = counts.values.reduce(0, +)
        guard total > 0 else { return [] }

        return counts
            .map { CategoryBreakdownItem(
                category: $0.key,
                count: $0.value,
                percentage: Double($0.value) / Double(total) * 100.0
            )}
            .sorted { $0.count > $1.count }
    }

    // MARK: - Volume

    func averageItemsPerEntry(from entries: [RRGratitudeEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        let totalItems = entries.reduce(0) { $0 + $1.items.count }
        return Double(totalItems) / Double(entries.count)
    }

    func weeklyEntryData(from entries: [RRGratitudeEntry]) -> [WeeklyEntryData] {
        let today = calendar.startOfDay(for: Date())
        var weeks: [WeeklyEntryData] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for weekIndex in (0..<8).reversed() {
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: -weekIndex, to: today)!
            let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd)!

            var uniqueDays = Set<String>()
            for entry in entries {
                let entryDay = calendar.startOfDay(for: entry.date)
                if entryDay >= weekStart && entryDay <= weekEnd {
                    uniqueDays.insert(formatter.string(from: entryDay))
                }
            }

            let label = weekLabel(for: weekEnd, weeksAgo: weekIndex)
            weeks.append(WeeklyEntryData(weekLabel: label, daysWithEntries: uniqueDays.count))
        }

        return weeks
    }

    private func weekLabel(for date: Date, weeksAgo: Int) -> String {
        if weeksAgo == 0 { return "This" }
        if weeksAgo == 1 { return "Last" }
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    // MARK: - Correlations

    func urgeCorrelation(entries: [RRGratitudeEntry], urgeLogs: [RRUrgeLog]) -> String? {
        let gratitudeDaySet = uniqueCalendarDayStrings(from: entries)

        guard !gratitudeDaySet.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        // Find date range covered
        let allDates = entries.map { $0.date } + urgeLogs.map { $0.date }
        guard let earliest = allDates.min(), let latest = allDates.max() else { return nil }

        let totalDays = max(1, (calendar.dateComponents([.day], from: earliest, to: latest).day ?? 0) + 1)
        let gratDayCount = gratitudeDaySet.count
        let nonGratDayCount = totalDays - gratDayCount

        guard gratDayCount >= 14, nonGratDayCount >= 14 else { return nil }

        var urgesOnGratDays = 0
        var urgesOnNonGratDays = 0

        for urge in urgeLogs {
            let key = formatter.string(from: urge.date)
            if gratitudeDaySet.contains(key) {
                urgesOnGratDays += 1
            } else {
                urgesOnNonGratDays += 1
            }
        }

        let rateGrat = Double(urgesOnGratDays) / Double(gratDayCount)
        let rateNonGrat = Double(urgesOnNonGratDays) / Double(nonGratDayCount)

        guard rateNonGrat > 0 else { return nil }

        let reduction = ((rateNonGrat - rateGrat) / rateNonGrat) * 100.0
        guard reduction > 5.0 else { return nil }

        return "Your urge frequency is \(Int(reduction.rounded()))% lower on days with gratitude entries."
    }

    // MARK: - Helpers

    private func filteredEntries(_ entries: [RRGratitudeEntry], period: TrendPeriod) -> [RRGratitudeEntry] {
        guard let days = period.days else { return entries }
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return entries.filter { $0.date >= cutoff }
    }

    private func uniqueCalendarDayStrings(from entries: [RRGratitudeEntry]) -> Set<String> {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return Set(entries.map { formatter.string(from: $0.date) })
    }

    /// Partitions scores from `otherRecords` into two groups: days that also have a gratitude entry, and days that do not.
    private func partitionDays(
        entries: [RRGratitudeEntry],
        otherRecords: [(date: Date, score: Int)]
    ) -> (gratitudeDays: [Int], nonGratitudeDays: [Int]) {
        let gratDaySet = uniqueCalendarDayStrings(from: entries)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var withGratitude: [Int] = []
        var withoutGratitude: [Int] = []

        for record in otherRecords {
            let key = formatter.string(from: record.date)
            if gratDaySet.contains(key) {
                withGratitude.append(record.score)
            } else {
                withoutGratitude.append(record.score)
            }
        }

        return (withGratitude, withoutGratitude)
    }
}
