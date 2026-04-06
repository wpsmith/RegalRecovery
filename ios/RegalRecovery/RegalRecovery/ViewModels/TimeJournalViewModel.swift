import Foundation
import SwiftData
import SwiftUI

@Observable
class TimeJournalViewModel {

    // MARK: - State

    var entries: [RRTimeJournalEntry] = []
    var currentDate: Date = Calendar.current.startOfDay(for: Date())
    var mode: TimeJournalMode = .t60
    var isLoading = false
    var error: String?

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let calendar = Calendar.current

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties

    var dayStatus: TimeJournalDayStatus {
        TimeJournalDayStatus.evaluate(entries: entries, mode: mode, now: Date(), forDate: currentDate)
    }

    var filledCount: Int {
        entries.count
    }

    var totalSlots: Int {
        mode.slotsPerDay
    }

    var completionPercent: Double {
        guard totalSlots > 0 else { return 0 }
        return Double(filledCount) / Double(totalSlots)
    }

    var overdueCount: Int {
        let now = Date()
        let dayStart = calendar.startOfDay(for: currentDate)
        let minutesElapsed: Int
        if calendar.isDate(now, inSameDayAs: currentDate) {
            minutesElapsed = Int(now.timeIntervalSince(dayStart)) / 60
        } else if now > dayStart {
            minutesElapsed = 24 * 60
        } else {
            minutesElapsed = 0
        }

        let filledSlots = Set(entries.map(\.slotIndex))
        var count = 0
        for slotIndex in 0..<mode.slotsPerDay {
            let slotEndMinute = (slotIndex + 1) * mode.intervalMinutes
            if minutesElapsed >= slotEndMinute && !filledSlots.contains(slotIndex) {
                count += 1
            }
        }
        return count
    }

    var lastUpdated: Date? {
        entries.map(\.modifiedAt).max()
    }

    var triggerReason: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short

        switch dayStatus {
        case .completed:
            return "All \(totalSlots) slots filled"
        case .overdue:
            let timeString = lastUpdated.map { timeFormatter.string(from: $0) } ?? "N/A"
            return "\(overdueCount) overdue slot\(overdueCount == 1 ? "" : "s") -- Last updated \(timeString)"
        case .inProgress:
            let timeString = lastUpdated.map { timeFormatter.string(from: $0) } ?? "N/A"
            return "\(filledCount) of \(totalSlots) slots filled -- Last updated \(timeString)"
        }
    }

    // MARK: - Slot Helpers

    func entry(for slotIndex: Int) -> RRTimeJournalEntry? {
        entries.first { $0.slotIndex == slotIndex }
    }

    func slotStatus(for slotIndex: Int) -> TimeJournalSlotStatus {
        entry(for: slotIndex)?.slotStatus ?? .empty
    }

    func isSlotElapsed(_ slotIndex: Int) -> Bool {
        let now = Date()
        let dayStart = calendar.startOfDay(for: currentDate)
        let minutesElapsed: Int
        if calendar.isDate(now, inSameDayAs: currentDate) {
            minutesElapsed = Int(now.timeIntervalSince(dayStart)) / 60
        } else if now > dayStart {
            minutesElapsed = 24 * 60
        } else {
            minutesElapsed = 0
        }
        let slotEndMinute = (slotIndex + 1) * mode.intervalMinutes
        return minutesElapsed >= slotEndMinute
    }

    /// Returns the slot index that covers the current time of day.
    var currentSlotIndex: Int {
        let now = Date()
        let components = calendar.dateComponents([.hour, .minute], from: now)
        return mode.slotIndex(hour: components.hour ?? 0, minute: components.minute ?? 0)
    }

    // MARK: - Actions

    func loadDay(date: Date) async {
        isLoading = true
        error = nil
        currentDate = calendar.startOfDay(for: date)
        defer { isLoading = false }

        do {
            let dayStart = currentDate
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                entries = []
                return
            }

            let predicate = #Predicate<RRTimeJournalEntry> { entry in
                entry.date >= dayStart && entry.date < dayEnd
            }
            let descriptor = FetchDescriptor<RRTimeJournalEntry>(
                predicate: predicate,
                sortBy: [SortDescriptor(\.slotIndex)]
            )
            entries = try modelContext.fetch(descriptor)
        } catch {
            self.error = error.localizedDescription
            entries = []
        }
    }

    func saveEntry(_ entry: RRTimeJournalEntry) async {
        do {
            modelContext.insert(entry)
            try modelContext.save()
            await loadDay(date: currentDate)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteEntry(_ entry: RRTimeJournalEntry) async {
        do {
            modelContext.delete(entry)
            try modelContext.save()
            await loadDay(date: currentDate)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func navigateDay(offset: Int) async {
        guard let newDate = calendar.date(byAdding: .day, value: offset, to: currentDate) else { return }
        await loadDay(date: newDate)
    }

    func fillSleepSlots(from startSlot: Int, to endSlot: Int) async {
        let userId = entries.first?.userId ?? UUID()
        for slotIndex in startSlot...endSlot {
            guard entry(for: slotIndex) == nil else { continue }
            let newEntry = RRTimeJournalEntry(
                userId: userId,
                date: currentDate,
                slotIndex: slotIndex,
                mode: mode.rawValue,
                activity: "Sleep",
                isSleep: true,
                isAutoFilled: true,
                autoFillAttribution: "sleep-fill"
            )
            modelContext.insert(newEntry)
        }
        do {
            try modelContext.save()
            await loadDay(date: currentDate)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func changeMode(_ newMode: TimeJournalMode) {
        mode = newMode
    }
}
