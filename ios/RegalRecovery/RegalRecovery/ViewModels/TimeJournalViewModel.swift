import Foundation
import SwiftUI

@Observable
class TimeJournalViewModel {

    // MARK: - State

    var blocks: [TimeBlock] = []
    var weeklyNeedsSummary: [(need: String, hours: Double)] = []
    var isLoading = false
    var error: String?

    // New block state
    var newStartHour: Int = 8
    var newStartMinute: Int = 0
    var newDuration: Int = 30
    var newActivity: String = ""
    var newNeed: String = ""

    // MARK: - Load

    func loadToday() async {
        isLoading = true
        defer { isLoading = false }

        do {
            blocks = try await loadFromStorage()
        } catch {
            blocks = MockData.timeBlocks
            self.error = error.localizedDescription
        }

        weeklyNeedsSummary = calculateNeedsSummary()
    }

    // MARK: - Add Block

    func addBlock(startHour: Int, startMinute: Int, duration: Int, activity: String, need: String) async throws {
        guard !activity.isEmpty else {
            throw ActivityError.validationFailed("Activity is required.")
        }
        guard !need.isEmpty else {
            throw ActivityError.validationFailed("Need is required.")
        }
        guard duration > 0 else {
            throw ActivityError.validationFailed("Duration must be greater than zero.")
        }

        let color = colorForNeed(need)
        let block = TimeBlock(
            startHour: startHour,
            startMinute: startMinute,
            durationMinutes: duration,
            activity: activity,
            need: need,
            color: color
        )

        // TODO: Replace with repository save
        blocks.append(block)
        blocks.sort { ($0.startHour * 60 + $0.startMinute) < ($1.startHour * 60 + $1.startMinute) }
        weeklyNeedsSummary = calculateNeedsSummary()
        resetForm()
    }

    // MARK: - Needs Summary

    func calculateNeedsSummary() -> [(need: String, hours: Double)] {
        let grouped = Dictionary(grouping: blocks, by: \.need)
        return grouped.map { need, items in
            let totalMinutes = items.reduce(0) { $0 + $1.durationMinutes }
            return (need: need, hours: Double(totalMinutes) / 60.0)
        }
        .sorted { $0.hours > $1.hours }
    }

    // MARK: - Computed

    var totalLoggedMinutes: Int {
        blocks.reduce(0) { $0 + $1.durationMinutes }
    }

    var totalLoggedHours: Double {
        Double(totalLoggedMinutes) / 60.0
    }

    // MARK: - Private

    private func resetForm() {
        newStartHour = 8
        newStartMinute = 0
        newDuration = 30
        newActivity = ""
        newNeed = ""
    }

    private func loadFromStorage() async throws -> [TimeBlock] {
        throw ActivityError.notImplemented
    }

    private func colorForNeed(_ need: String) -> Color {
        switch need {
        case "Peace": return .rrPrimary
        case "Agency": return .blue
        case "Connection": return .pink
        case "Belonging": return .rrPrimary
        case "Comfort": return .orange
        case "Understanding": return .purple
        case "Hope": return .rrPrimary
        case "Love": return .pink
        default: return .gray
        }
    }
}
