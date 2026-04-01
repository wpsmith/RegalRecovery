import Testing
import SwiftUI
@testable import RegalRecovery

@Suite("EmotionalJournalViewModel Tests")
struct EmotionalJournalViewModelTests {

    // MARK: - Helpers

    private func makeViewModel(with entries: [EmotionalJournalEntry]) -> EmotionalJournalViewModel {
        let vm = EmotionalJournalViewModel()
        vm.entries = entries
        return vm
    }

    private func makeEntry(
        daysAgo: Int = 0,
        hour: Int = 12,
        emotion: String = "Anxious",
        color: Color = .purple,
        intensity: Int = 5,
        activity: String = "Work",
        location: String = "Home"
    ) -> EmotionalJournalEntry {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        let baseDate = calendar.date(from: components)!
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: baseDate)!

        return EmotionalJournalEntry(
            date: date,
            emotion: emotion,
            emotionColor: color,
            intensity: intensity,
            activity: activity,
            location: location
        )
    }

    // MARK: - Insight Tests

    @Test("generateInsights with weekday pattern returns day-of-week insight")
    func testGenerateInsights_WithWeekdayPattern_ReturnsInsight() {
        // Create multiple entries on the same weekday
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let dayName = calendar.weekdaySymbols[todayWeekday - 1]

        let entries = [
            makeEntry(daysAgo: 0, emotion: "Anxious"),
            makeEntry(daysAgo: 0, hour: 14, emotion: "Anxious"),
            makeEntry(daysAgo: 0, hour: 16, emotion: "Anxious"),
            makeEntry(daysAgo: 1, emotion: "Happy"),
        ]

        let vm = makeViewModel(with: entries)
        let insights = vm.generateInsights()

        let hasWeekdayInsight = insights.contains { $0.contains(dayName) }
        #expect(hasWeekdayInsight, "Expected an insight mentioning \(dayName)")
    }

    @Test("generateInsights with high intensity time pattern returns timing insight")
    func testGenerateInsights_WithTimePattern_ReturnsInsight() {
        // Create entries with high intensity at same hour
        let entries = [
            makeEntry(daysAgo: 0, hour: 20, intensity: 9),
            makeEntry(daysAgo: 1, hour: 20, intensity: 8),
            makeEntry(daysAgo: 2, hour: 20, intensity: 7),
            makeEntry(daysAgo: 3, hour: 10, intensity: 3),
        ]

        let vm = makeViewModel(with: entries)
        let insights = vm.generateInsights()

        let hasTimeInsight = insights.contains { $0.contains("intensity") || $0.contains("peaks") }
        #expect(hasTimeInsight, "Expected an insight about timing or intensity patterns")
    }

    @Test("submit with valid entry adds to entries list")
    func testSubmit_ValidEntry_AddsToEntries() async throws {
        let vm = EmotionalJournalViewModel()
        vm.selectedPrimaryEmotion = .fearful
        vm.selectedEmotion = "Anxious"
        vm.intensity = 7
        vm.activity = "Work meeting"
        vm.location = "Office"

        let countBefore = vm.entries.count
        try await vm.submit()

        #expect(vm.entries.count == countBefore + 1)
        #expect(vm.entries.first?.emotion == "Anxious")
        #expect(vm.entries.first?.intensity == 7)
    }

    @Test("submit without emotion throws validation error")
    func testSubmit_NoEmotion_Throws() async {
        let vm = EmotionalJournalViewModel()
        vm.selectedEmotion = ""

        do {
            try await vm.submit()
            #expect(false, "Expected validation error")
        } catch {
            #expect(error is ActivityError)
        }
    }

    @Test("submit resets form fields after success")
    func testSubmit_ResetsFormAfterSuccess() async throws {
        let vm = EmotionalJournalViewModel()
        vm.selectedPrimaryEmotion = .happy
        vm.selectedEmotion = "Joyful"
        vm.intensity = 9
        vm.activity = "Fellowship"

        try await vm.submit()

        #expect(vm.selectedEmotion.isEmpty)
        #expect(vm.selectedPrimaryEmotion == nil)
        #expect(vm.intensity == 5)
        #expect(vm.activity.isEmpty)
    }

    @Test("generateInsights returns empty for fewer than 3 entries")
    func testGenerateInsights_TooFewEntries_ReturnsEmpty() {
        let vm = makeViewModel(with: [makeEntry(), makeEntry(daysAgo: 1)])
        let insights = vm.generateInsights()
        #expect(insights.isEmpty)
    }

    @Test("generateInsights returns at most 3 insights")
    func testGenerateInsights_MaxThreeInsights() {
        let entries = (0..<20).map { i in
            makeEntry(daysAgo: i, hour: 20, emotion: "Anxious", intensity: 8)
        }
        let vm = makeViewModel(with: entries)
        let insights = vm.generateInsights()
        #expect(insights.count <= 3)
    }
}
