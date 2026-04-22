import SwiftUI
import SwiftData

// MARK: - RRTriggerDefinition

/// Stores user's personal trigger library (both system-provided and custom triggers).
/// Tracks usage statistics for adaptive suggestions.
@Model
final class RRTriggerDefinition {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var label: String
    var categoryRaw: String  // Store enum as string for SwiftData
    var isCustom: Bool
    var useCount: Int
    var lastUsed: Date?
    var createdAt: Date
    var modifiedAt: Date

    /// Type-safe access to trigger category
    var category: TriggerCategory {
        get { TriggerCategory(rawValue: categoryRaw) ?? .emotional }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        label: String,
        category: TriggerCategory,
        isCustom: Bool = false,
        useCount: Int = 0,
        lastUsed: Date? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.label = label
        self.categoryRaw = category.rawValue
        self.isCustom = isCustom
        self.useCount = useCount
        self.lastUsed = lastUsed
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
