import Foundation
import SwiftUI

@Observable
class EmotionalJournalViewModel {

    // MARK: - State

    var entries: [EmotionalJournalEntry] = []
    var insights: [String] = []
    var isLoading = false
    var error: String?

    // New entry state
    var selectedPrimaryEmotion: PrimaryEmotion?
    var selectedEmotion: String = ""
    var intensity: Int = 5
    var activity: String = ""
    var location: String = "Home, Austin TX"

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // TODO: Replace with repository call
            entries = try await loadFromStorage()
        } catch {
            entries = MockData.emotionalJournalEntries
            self.error = error.localizedDescription
        }

        insights = generateInsights()
    }

    // MARK: - Submit

    func submit() async throws {
        guard !selectedEmotion.isEmpty else {
            throw ActivityError.validationFailed("Please select an emotion.")
        }

        let emotionColor = selectedPrimaryEmotion?.color ?? .purple

        let entry = EmotionalJournalEntry(
            date: Date(),
            emotion: selectedEmotion,
            emotionColor: emotionColor,
            intensity: intensity,
            activity: activity,
            location: location
        )

        // TODO: Replace with repository save
        entries.insert(entry, at: 0)
        insights = generateInsights()
        resetForm()
    }

    // MARK: - Insights

    func generateInsights() -> [String] {
        guard entries.count >= 3 else { return [] }

        var results: [String] = []
        let calendar = Calendar.current

        // Day-of-week pattern: find most common emotion per weekday
        let byWeekday = Dictionary(grouping: entries) { entry in
            calendar.component(.weekday, from: entry.date)
        }
        if let (weekday, dayEntries) = byWeekday.max(by: { $0.value.count < $1.value.count }),
           dayEntries.count >= 2 {
            let emotionCounts = Dictionary(grouping: dayEntries, by: \.emotion)
            if let (topEmotion, _) = emotionCounts.max(by: { $0.value.count < $1.value.count }) {
                let dayName = calendar.weekdaySymbols[weekday - 1]
                results.append("You feel \(topEmotion) most on \(dayName)s")
            }
        }

        // Time-of-day pattern: find when intensity peaks
        let byHour = Dictionary(grouping: entries) {
            calendar.component(.hour, from: $0.date)
        }
        if let (peakHour, hourEntries) = byHour.max(by: {
            let avg0 = Double($0.value.reduce(0) { $0 + $1.intensity }) / Double($0.value.count)
            let avg1 = Double($1.value.reduce(0) { $0 + $1.intensity }) / Double($1.value.count)
            return avg0 < avg1
        }), hourEntries.count >= 2 {
            let avgIntensity = Double(hourEntries.reduce(0) { $0 + $1.intensity }) / Double(hourEntries.count)
            if avgIntensity >= 6 {
                let endHour = peakHour + 2
                let startStr = formatHour(peakHour)
                let endStr = formatHour(endHour)
                results.append("High intensity peaks between \(startStr)-\(endStr)")
            }
        }

        // Emotion frequency
        let emotionCounts = Dictionary(grouping: entries, by: \.emotion)
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        if let top = emotionCounts.first, top.value >= 2 {
            let pct = Int(Double(top.value) / Double(entries.count) * 100)
            results.append("\(top.key) is your most frequent emotion (\(pct)% of entries)")
        }

        // Intensity trend (last 7 vs prior 7)
        let sorted = entries.sorted { $0.date > $1.date }
        if sorted.count >= 6 {
            let recentHalf = sorted.prefix(sorted.count / 2)
            let olderHalf = sorted.suffix(sorted.count / 2)
            let recentAvg = Double(recentHalf.reduce(0) { $0 + $1.intensity }) / Double(recentHalf.count)
            let olderAvg = Double(olderHalf.reduce(0) { $0 + $1.intensity }) / Double(olderHalf.count)
            let diff = recentAvg - olderAvg
            if abs(diff) >= 1.0 {
                let direction = diff > 0 ? "increasing" : "decreasing"
                results.append("Your emotional intensity has been \(direction) recently")
            }
        }

        return Array(results.prefix(3))
    }

    // MARK: - Private

    private func resetForm() {
        selectedPrimaryEmotion = nil
        selectedEmotion = ""
        intensity = 5
        activity = ""
    }

    private func loadFromStorage() async throws -> [EmotionalJournalEntry] {
        // TODO: Replace with actual data fetch
        throw ActivityError.notImplemented
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h < 12 { return "\(h) AM" }
        if h == 12 { return "12 PM" }
        return "\(h - 12) PM"
    }
}
