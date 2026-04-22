import SwiftUI
import SwiftData
import Foundation

// MARK: - TriggerSnapshot

/// Captures trigger state at log time. Preserves label + category even if trigger definition is later deleted.
struct TriggerSnapshot: Codable, Hashable {
    let id: UUID
    let label: String
    let category: String  // raw value of TriggerCategory
}

// MARK: - RRTriggerLogEntry

/// Individual trigger log entry with Quick/Standard/Deep depth fields.
/// Stores triggers as JSON-encoded snapshots to preserve historical data.
@Model
final class RRTriggerLogEntry {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var timestamp: Date
    var dayOfWeek: Int  // 1=Sunday, 7=Saturday
    var timeOfDaySlotRaw: String
    var triggerSnapshotsJSON: String  // JSON array of TriggerSnapshot
    var intensity: Int?  // 1-10, nullable
    var riskLevelRaw: String?  // computed from intensity
    var logDepthRaw: String

    // Standard depth fields (all optional)
    var mood: String?
    var situation: String?
    var socialContextRaw: String?
    var bodySensation: String?
    var responseTaken: String?
    var copingStrategyId: UUID?
    var copingEffectiveness: Int?  // 1-5

    // Deep depth fields (all optional)
    var unmetNeedRaw: String?
    var teacherReflection: String?
    var fasterPositionRaw: Int?  // FASTERStage raw value

    // Context
    var locationCategoryRaw: String?
    var linkedUrgeLogId: UUID?

    // Sync
    var syncStatus: String  // "pending", "synced", "failed"
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Computed Properties for Type-Safe Access

    var timeOfDaySlot: TimeOfDaySlot {
        get { TimeOfDaySlot(rawValue: timeOfDaySlotRaw) ?? .morning }
        set { timeOfDaySlotRaw = newValue.rawValue }
    }

    var riskLevel: RiskLevel? {
        get {
            guard let raw = riskLevelRaw else { return nil }
            return RiskLevel(rawValue: raw)
        }
        set { riskLevelRaw = newValue?.rawValue }
    }

    var logDepth: LogDepth {
        get { LogDepth(rawValue: logDepthRaw) ?? .quick }
        set { logDepthRaw = newValue.rawValue }
    }

    var socialContext: SocialContext? {
        get {
            guard let raw = socialContextRaw else { return nil }
            return SocialContext(rawValue: raw)
        }
        set { socialContextRaw = newValue?.rawValue }
    }

    var unmetNeed: UnmetNeed? {
        get {
            guard let raw = unmetNeedRaw else { return nil }
            return UnmetNeed(rawValue: raw)
        }
        set { unmetNeedRaw = newValue?.rawValue }
    }

    var locationCategory: LocationCategory? {
        get {
            guard let raw = locationCategoryRaw else { return nil }
            return LocationCategory(rawValue: raw)
        }
        set { locationCategoryRaw = newValue?.rawValue }
    }

    var fasterPosition: FASTERStage? {
        get {
            guard let raw = fasterPositionRaw else { return nil }
            return FASTERStage(rawValue: raw)
        }
        set { fasterPositionRaw = newValue?.rawValue }
    }

    var triggerSnapshots: [TriggerSnapshot] {
        get {
            guard let data = triggerSnapshotsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([TriggerSnapshot].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                triggerSnapshotsJSON = json
            }
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        userId: UUID,
        timestamp: Date = Date(),
        triggers: [TriggerSnapshot],
        intensity: Int? = nil,
        logDepth: LogDepth,
        mood: String? = nil,
        situation: String? = nil,
        socialContext: SocialContext? = nil,
        bodySensation: String? = nil,
        responseTaken: String? = nil,
        copingStrategyId: UUID? = nil,
        copingEffectiveness: Int? = nil,
        unmetNeed: UnmetNeed? = nil,
        teacherReflection: String? = nil,
        fasterPosition: FASTERStage? = nil,
        locationCategory: LocationCategory? = nil,
        linkedUrgeLogId: UUID? = nil,
        syncStatus: String = "pending",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.timestamp = timestamp

        // Auto-compute dayOfWeek (1=Sunday, 7=Saturday)
        let calendar = Calendar.current
        self.dayOfWeek = calendar.component(.weekday, from: timestamp)

        // Auto-compute timeOfDaySlot from timestamp
        let hour = calendar.component(.hour, from: timestamp)
        self.timeOfDaySlotRaw = TimeOfDaySlot.from(hour: hour).rawValue

        // Encode triggers as JSON
        if let data = try? JSONEncoder().encode(triggers),
           let json = String(data: data, encoding: .utf8) {
            self.triggerSnapshotsJSON = json
        } else {
            self.triggerSnapshotsJSON = "[]"
        }

        self.intensity = intensity

        // Auto-compute riskLevel from intensity
        if let intensity = intensity {
            self.riskLevelRaw = RiskLevel.from(intensity: intensity).rawValue
        } else {
            self.riskLevelRaw = nil
        }

        self.logDepthRaw = logDepth.rawValue
        self.mood = mood
        self.situation = situation
        self.socialContextRaw = socialContext?.rawValue
        self.bodySensation = bodySensation
        self.responseTaken = responseTaken
        self.copingStrategyId = copingStrategyId
        self.copingEffectiveness = copingEffectiveness
        self.unmetNeedRaw = unmetNeed?.rawValue
        self.teacherReflection = teacherReflection
        self.fasterPositionRaw = fasterPosition?.rawValue
        self.locationCategoryRaw = locationCategory?.rawValue
        self.linkedUrgeLogId = linkedUrgeLogId
        self.syncStatus = syncStatus
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
