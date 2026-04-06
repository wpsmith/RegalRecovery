import Foundation
import SwiftData

/// SwiftData model representing a single time journal entry (one slot in a day).
@Model
final class RRTimeJournalEntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var slotIndex: Int
    var mode: String
    var locationLabel: String
    var latitude: Double?
    var longitude: Double?
    var locationAddress: String?
    var locationAccuracyMeters: Double?
    var activity: String
    var peopleJSON: String?
    var emotionsJSON: String?
    var extrasJSON: String?
    var isFlagged: Bool
    var isSleep: Bool
    var isRetroactive: Bool
    var retroactiveFilledAt: Date?
    var isAutoFilled: Bool
    var autoFillAttribution: String?
    var redlineNote: String?
    var synced: Bool
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Computed Properties

    /// Decoded array of people referenced in this slot.
    var people: [PersonEntry] {
        get {
            guard let json = peopleJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([PersonEntry].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                peopleJSON = nil
                return
            }
            peopleJSON = String(data: data, encoding: .utf8)
        }
    }

    /// Decoded array of emotions recorded in this slot.
    var emotions: [EmotionEntry] {
        get {
            guard let json = emotionsJSON, let data = json.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([EmotionEntry].self, from: data)) ?? []
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else {
                emotionsJSON = nil
                return
            }
            emotionsJSON = String(data: data, encoding: .utf8)
        }
    }

    /// The visual status of this slot based on its fill state.
    var slotStatus: TimeJournalSlotStatus {
        if isFlagged { return .flagged }
        if isAutoFilled { return .autoFilled }
        if isRetroactive { return .retroactive }
        if !activity.isEmpty { return .filled }
        return .empty
    }

    /// Whether this entry can still be edited (within 24 hours of creation).
    var isEditable: Bool {
        Date().timeIntervalSince(createdAt) < 24 * 60 * 60
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        slotIndex: Int,
        mode: String = TimeJournalMode.t30.rawValue,
        locationLabel: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationAddress: String? = nil,
        locationAccuracyMeters: Double? = nil,
        activity: String = "",
        peopleJSON: String? = nil,
        emotionsJSON: String? = nil,
        extrasJSON: String? = nil,
        isFlagged: Bool = false,
        isSleep: Bool = false,
        isRetroactive: Bool = false,
        retroactiveFilledAt: Date? = nil,
        isAutoFilled: Bool = false,
        autoFillAttribution: String? = nil,
        redlineNote: String? = nil,
        synced: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.slotIndex = slotIndex
        self.mode = mode
        self.locationLabel = locationLabel
        self.latitude = latitude
        self.longitude = longitude
        self.locationAddress = locationAddress
        self.locationAccuracyMeters = locationAccuracyMeters
        self.activity = activity
        self.peopleJSON = peopleJSON
        self.emotionsJSON = emotionsJSON
        self.extrasJSON = extrasJSON
        self.isFlagged = isFlagged
        self.isSleep = isSleep
        self.isRetroactive = isRetroactive
        self.retroactiveFilledAt = retroactiveFilledAt
        self.isAutoFilled = isAutoFilled
        self.autoFillAttribution = autoFillAttribution
        self.redlineNote = redlineNote
        self.synced = synced
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
