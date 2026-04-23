// ViewModels/PCIScoringService.swift

import Foundation
import SwiftData

struct PCIScoringService {

    /// Get the Monday start of the ISO week containing the given date.
    static func weekStart(for date: Date) -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }

    /// Compute weekly score for a given week start (Monday).
    /// Returns sum of daily totalScore values in that Mon-Sun range.
    static func weeklyScore(for weekStart: Date, entries: [RRPCIDailyEntry]) -> Int {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        return entries
            .filter { $0.date >= weekStart && $0.date < weekEnd }
            .reduce(0) { $0 + $1.totalScore }
    }

    /// Compute weekly scores for the last N weeks from a reference date.
    /// Returns chronologically sorted array of (weekStart, score, riskLevel).
    static func weeklyScores(
        weeks: Int,
        from date: Date = Date(),
        entries: [RRPCIDailyEntry]
    ) -> [(weekStart: Date, score: Int, riskLevel: PCIRiskLevel)] {
        var results: [(Date, Int, PCIRiskLevel)] = []
        let calendar = Calendar.current
        let currentWeekStart = weekStart(for: date)

        for i in (0..<weeks).reversed() {
            guard let ws = calendar.date(byAdding: .weekOfYear, value: -i, to: currentWeekStart) else { continue }
            let score = weeklyScore(for: ws, entries: entries)
            results.append((ws, score, PCIRiskLevel.from(weeklyScore: score)))
        }
        return results
    }

    /// Week-over-week delta. Returns nil if no previous week data exists.
    static func weeklyDelta(
        currentWeekStart: Date,
        entries: [RRPCIDailyEntry]
    ) -> Int? {
        let calendar = Calendar.current
        guard let previousWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else { return nil }

        let current = weeklyScore(for: currentWeekStart, entries: entries)
        let previous = weeklyScore(for: previousWeekStart, entries: entries)

        let prevEnd = calendar.date(byAdding: .day, value: 7, to: previousWeekStart)!
        let hasPreviousData = entries.contains { $0.date >= previousWeekStart && $0.date < prevEnd }
        return hasPreviousData ? current - previous : nil
    }

    /// Partial week info (how many days checked in so far this week, running score).
    static func partialWeekInfo(
        weekStart: Date,
        entries: [RRPCIDailyEntry]
    ) -> (daysCompleted: Int, runningScore: Int) {
        let calendar = Calendar.current
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)!
        let weekEntries = entries.filter { $0.date >= weekStart && $0.date < weekEnd }
        return (weekEntries.count, weekEntries.reduce(0) { $0 + $1.totalScore })
    }

    /// Current week's score for a userId using a ModelContext.
    static func currentWeekScore(context: ModelContext, userId: UUID) -> Int {
        let ws = weekStart(for: Date())
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: ws)!
        let descriptor = FetchDescriptor<RRPCIDailyEntry>(
            predicate: #Predicate { $0.userId == userId && $0.date >= ws && $0.date < weekEnd }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        return entries.reduce(0) { $0 + $1.totalScore }
    }
}
