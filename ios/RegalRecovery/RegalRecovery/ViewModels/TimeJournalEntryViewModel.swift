import Foundation
import SwiftData
import SwiftUI

@Observable
class TimeJournalEntryViewModel {

    // MARK: - State

    var slotIndex: Int
    var mode: TimeJournalMode
    var date: Date
    var locationLabel: String = ""
    var activity: String = ""
    var selectedEmotions: [EmotionEntry] = []
    var people: [PersonEntry] = []
    var isSleep: Bool = false
    var isFlagged: Bool = false
    var redlineNote: String = ""
    var latitude: Double?
    var longitude: Double?
    var locationAddress: String?
    var locationAccuracyMeters: Double?
    var isExpanded: Bool = false
    var isEditing: Bool = false
    var isSaving: Bool = false
    var existingEntryId: UUID?

    // MARK: - Init

    init(slotIndex: Int, mode: TimeJournalMode, date: Date) {
        self.slotIndex = slotIndex
        self.mode = mode
        self.date = date
    }

    // MARK: - Computed

    var isValid: Bool {
        !locationLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isRetroactive: Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let slotEndMinutes = (slotIndex + 1) * mode.intervalMinutes
        guard let slotEnd = calendar.date(byAdding: .minute, value: slotEndMinutes, to: dayStart) else {
            return false
        }
        return Date() >= slotEnd
    }

    var slotTimeLabel: String {
        mode.slotLabel(index: slotIndex)
    }

    /// Keywords that suggest other people were involved in the activity.
    private static let peopleKeywords: Set<String> = [
        "meeting", "lunch", "dinner", "coffee", "call", "group", "session", "church", "class",
    ]

    var shouldPromptForPeople: Bool {
        let lower = activity.lowercased()
        return Self.peopleKeywords.contains { lower.contains($0) }
    }

    // MARK: - Actions

    /// Validates the entry and returns an array of error strings (empty if valid).
    func validate() -> [String] {
        var errors: [String] = []
        if locationLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Location is required.")
        }
        if activity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Activity is required.")
        }
        return errors
    }

    /// Creates or updates an RRTimeJournalEntry in the given model context.
    @discardableResult
    func save(modelContext: ModelContext, userId: UUID) -> RRTimeJournalEntry {
        isSaving = true
        defer { isSaving = false }

        let now = Date()

        // Encode people and emotions to JSON
        let peopleJSON: String? = {
            guard !people.isEmpty, let data = try? JSONEncoder().encode(people) else { return nil }
            return String(data: data, encoding: .utf8)
        }()

        let emotionsJSON: String? = {
            guard !selectedEmotions.isEmpty, let data = try? JSONEncoder().encode(selectedEmotions) else { return nil }
            return String(data: data, encoding: .utf8)
        }()

        if let existingId = existingEntryId {
            // Update existing entry
            let descriptor = FetchDescriptor<RRTimeJournalEntry>(
                predicate: #Predicate { $0.id == existingId }
            )
            if let existing = try? modelContext.fetch(descriptor).first {
                existing.locationLabel = locationLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                existing.activity = activity.trimmingCharacters(in: .whitespacesAndNewlines)
                existing.peopleJSON = peopleJSON
                existing.emotionsJSON = emotionsJSON
                existing.isSleep = isSleep
                existing.isFlagged = isFlagged
                existing.redlineNote = redlineNote.isEmpty ? nil : redlineNote
                existing.latitude = latitude
                existing.longitude = longitude
                existing.locationAddress = locationAddress
                existing.locationAccuracyMeters = locationAccuracyMeters
                existing.modifiedAt = now
                return existing
            }
        }

        // Create new entry
        let entry = RRTimeJournalEntry(
            userId: userId,
            date: date,
            slotIndex: slotIndex,
            mode: mode.rawValue,
            locationLabel: locationLabel.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: latitude,
            longitude: longitude,
            locationAddress: locationAddress,
            locationAccuracyMeters: locationAccuracyMeters,
            activity: activity.trimmingCharacters(in: .whitespacesAndNewlines),
            peopleJSON: peopleJSON,
            emotionsJSON: emotionsJSON,
            isFlagged: isFlagged,
            isSleep: isSleep,
            isRetroactive: isRetroactive,
            retroactiveFilledAt: isRetroactive ? now : nil,
            redlineNote: redlineNote.isEmpty ? nil : redlineNote,
            createdAt: now,
            modifiedAt: now
        )
        modelContext.insert(entry)
        return entry
    }

    /// Copies location fields from a previous entry for carry-forward convenience.
    func carryForwardLocation(from previousEntry: RRTimeJournalEntry) {
        locationLabel = previousEntry.locationLabel
        latitude = previousEntry.latitude
        longitude = previousEntry.longitude
        locationAddress = previousEntry.locationAddress
        locationAccuracyMeters = previousEntry.locationAccuracyMeters
    }

    /// Populates all fields from an existing entry for editing.
    func loadFromEntry(_ entry: RRTimeJournalEntry) {
        existingEntryId = entry.id
        isEditing = true
        slotIndex = entry.slotIndex
        date = entry.date
        locationLabel = entry.locationLabel
        activity = entry.activity
        selectedEmotions = entry.emotions
        people = entry.people
        isSleep = entry.isSleep
        isFlagged = entry.isFlagged
        redlineNote = entry.redlineNote ?? ""
        latitude = entry.latitude
        longitude = entry.longitude
        locationAddress = entry.locationAddress
        locationAccuracyMeters = entry.locationAccuracyMeters
    }

    /// Stub for GPS location capture (P1 feature).
    func captureGPSLocation() {
        // TODO: Implement GPS capture using CLLocationManager
    }
}
