import SwiftUI

// MARK: - Time Journal Mode

/// Defines the journaling interval: 30-minute or 60-minute slots.
enum TimeJournalMode: String, Codable, CaseIterable {
    case t30
    case t60

    /// Total number of slots in a day.
    var slotsPerDay: Int {
        switch self {
        case .t30: return 48
        case .t60: return 24
        }
    }

    /// Duration of each slot in minutes.
    var intervalMinutes: Int {
        switch self {
        case .t30: return 30
        case .t60: return 60
        }
    }

    /// Human-readable name for display.
    var displayName: String {
        switch self {
        case .t30: return "T30 (30-min)"
        case .t60: return "T60 (60-min)"
        }
    }

    /// Returns the slot index for a given hour and minute.
    func slotIndex(hour: Int, minute: Int) -> Int {
        let totalMinutes = hour * 60 + minute
        return totalMinutes / intervalMinutes
    }

    /// Returns the start time (hour, minute) for a given slot index.
    func slotStartTime(index: Int) -> (hour: Int, minute: Int) {
        let totalMinutes = index * intervalMinutes
        return (hour: totalMinutes / 60, minute: totalMinutes % 60)
    }

    /// Returns a formatted label for the given slot index (e.g. "7:00 AM" or "7:00 - 7:30 AM").
    func slotLabel(index: Int) -> String {
        let start = slotStartTime(index: index)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var startComponents = DateComponents()
        startComponents.hour = start.hour
        startComponents.minute = start.minute
        let calendar = Calendar.current
        guard let startDate = calendar.date(from: startComponents) else { return "" }

        let endMinutes = (index + 1) * intervalMinutes
        var endComponents = DateComponents()
        endComponents.hour = endMinutes / 60
        endComponents.minute = endMinutes % 60
        guard let endDate = calendar.date(from: endComponents) else {
            return formatter.string(from: startDate)
        }

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    /// The last valid slot index (0-based).
    var finalSlotIndex: Int {
        slotsPerDay - 1
    }
}

// MARK: - Time Journal Slot Status

/// Visual status of a single time journal slot.
enum TimeJournalSlotStatus: String, Codable {
    case empty
    case filled
    case retroactive
    case autoFilled
    case flagged

    /// The color associated with this slot status (per iOS design spec §1.2).
    var color: Color {
        switch self {
        case .empty:       return .gray.opacity(0.3)
        case .filled:      return .rrPrimary
        case .retroactive: return .rrSecondary.opacity(0.7)
        case .autoFilled:  return .blue.opacity(0.5)
        case .flagged:     return .orange
        }
    }

    /// Whether the slot should render with a dashed border (per iOS design spec §1.2).
    var useDashedBorder: Bool {
        self == .retroactive
    }

    /// Accessibility label for VoiceOver.
    var accessibilityLabel: String {
        switch self {
        case .empty: return "Empty slot"
        case .filled: return "Filled slot"
        case .retroactive: return "Retroactively filled slot"
        case .autoFilled: return "Auto-filled slot"
        case .flagged: return "Flagged slot"
        }
    }
}

// MARK: - Time Journal Day Status

/// Overall status of a day's time journal entries.
enum TimeJournalDayStatus: String {
    case inProgress
    case overdue
    case completed

    /// Human-readable label.
    var label: String {
        switch self {
        case .inProgress: return "In Progress"
        case .overdue: return "Overdue"
        case .completed: return "Completed"
        }
    }

    /// The color associated with this day status (per iOS design spec §1.3).
    var color: Color {
        switch self {
        case .inProgress: return .blue
        case .overdue:    return .orange
        case .completed:  return .rrSuccess
        }
    }

    /// Maps to the WorkStatus enum used by RecoveryWorkViewModel.
    var workStatus: WorkStatus {
        switch self {
        case .inProgress: return .inProgress
        case .overdue: return .overdue
        case .completed: return .completed
        }
    }

    /// Evaluates the day status based on entries, mode, current time, and the date being evaluated.
    ///
    /// Algorithm (TJ-060 through TJ-064):
    /// - A slot is "elapsed" when its full time period has passed:
    ///   slot N covers [N * interval, (N+1) * interval) minutes from day start.
    /// - If ANY elapsed slot is unfilled, the status is `.overdue` (even if later slots are filled).
    /// - If all slots are filled AND the final slot has elapsed, the status is `.completed`.
    /// - Otherwise the status is `.inProgress`.
    static func evaluate(
        entries: [RRTimeJournalEntry],
        mode: TimeJournalMode,
        now: Date = Date(),
        forDate date: Date
    ) -> TimeJournalDayStatus {
        let calendar = Calendar.current

        // Build a set of filled slot indices
        let filledSlots = Set(entries.map(\.slotIndex))

        // Determine how many minutes have elapsed in the target day relative to now
        let dayStart = calendar.startOfDay(for: date)
        let minutesElapsed: Int
        if calendar.isDate(now, inSameDayAs: date) {
            minutesElapsed = Int(now.timeIntervalSince(dayStart)) / 60
        } else if now > dayStart {
            // Evaluating a past day — all slots have elapsed
            minutesElapsed = 24 * 60
        } else {
            // Evaluating a future day — no slots have elapsed
            minutesElapsed = 0
        }

        let interval = mode.intervalMinutes

        // Check each slot up to finalSlotIndex
        var allSlotsFilled = true
        var hasUnfilledElapsed = false
        let finalSlotElapsed = minutesElapsed >= (mode.finalSlotIndex + 1) * interval

        for slotIndex in 0..<mode.slotsPerDay {
            let slotEndMinute = (slotIndex + 1) * interval
            let isElapsed = minutesElapsed >= slotEndMinute
            let isFilled = filledSlots.contains(slotIndex)

            if !isFilled {
                allSlotsFilled = false
                if isElapsed {
                    hasUnfilledElapsed = true
                }
            }
        }

        if hasUnfilledElapsed {
            return .overdue
        }

        if allSlotsFilled && finalSlotElapsed {
            return .completed
        }

        return .inProgress
    }
}

// MARK: - Person Entry

/// A person referenced in a time journal slot.
struct PersonEntry: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var gender: String?

    init(id: UUID = UUID(), name: String, gender: String? = nil) {
        self.id = id
        self.name = name
        self.gender = gender
    }
}

// MARK: - Emotion Entry

/// An emotion recorded in a time journal slot.
struct EmotionEntry: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var category: String
    var intensity: Int
    var context: String?

    init(id: UUID = UUID(), name: String, category: String, intensity: Int, context: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.intensity = max(1, min(10, intensity))
        self.context = context
    }
}

// MARK: - Emotion Catalog

/// Static catalog of emotions organized by category for the Time Journal.
struct EmotionCatalog {

    struct Category {
        let name: String
        let color: Color
        let emotions: [String]
    }

    static let categories: [Category] = [
        Category(name: "Happy", color: .yellow, emotions: [
            "Joyful", "Grateful", "Content", "Peaceful", "Hopeful", "Proud", "Relieved", "Playful",
        ]),
        Category(name: "Sad", color: .blue, emotions: [
            "Lonely", "Grieving", "Disappointed", "Hopeless", "Ashamed", "Empty", "Melancholic", "Homesick",
        ]),
        Category(name: "Angry", color: .red, emotions: [
            "Frustrated", "Resentful", "Irritated", "Bitter", "Jealous", "Betrayed", "Enraged", "Disgusted",
        ]),
        Category(name: "Fearful", color: .purple, emotions: [
            "Anxious", "Insecure", "Overwhelmed", "Vulnerable", "Panicked", "Worried", "Terrified", "Dread",
        ]),
        Category(name: "Shame", color: Color(red: 0.55, green: 0.27, blue: 0.07), emotions: [
            "Guilty", "Humiliated", "Embarrassed", "Unworthy", "Exposed", "Self-loathing",
        ]),
        Category(name: "The Three I's", color: .rrDestructive, emotions: [
            "Insignificant", "Incompetent", "Impotent",
        ]),
        Category(name: "Numb", color: .gray, emotions: [
            "Disconnected", "Flat", "Apathetic", "Foggy", "Exhausted", "Dissociated",
        ]),
        Category(name: "Surprise", color: .orange, emotions: [
            "Shocked", "Confused", "Amazed", "Startled", "Curious",
        ]),
        Category(name: "Connected", color: .rrSuccess, emotions: [
            "Loved", "Accepted", "Seen", "Understood", "Safe", "Belonging",
        ]),
    ]

    /// Flat list of all emotion names across all categories.
    static var allEmotions: [String] {
        categories.flatMap(\.emotions)
    }

    /// Returns the category name for a given emotion, or nil if not found.
    static func category(for emotion: String) -> String? {
        categories.first { $0.emotions.contains(emotion) }?.name
    }
}
