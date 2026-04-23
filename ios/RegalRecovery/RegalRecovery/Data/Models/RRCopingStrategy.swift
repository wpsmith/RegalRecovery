import SwiftUI
import SwiftData

// MARK: - RRCopingStrategy

/// User-defined coping plans with effectiveness tracking.
/// System-provided strategies are marked with `isSystem = true`.
@Model
final class RRCopingStrategy {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var label: String
    var strategyDescription: String?  // "description" is reserved in some contexts
    var categoryRaw: String
    var isSystem: Bool
    var effectivenessSum: Int
    var effectivenessCount: Int
    var createdAt: Date
    var modifiedAt: Date

    /// Type-safe access to trigger category
    var category: TriggerCategory {
        get { TriggerCategory(rawValue: categoryRaw) ?? .emotional }
        set { categoryRaw = newValue.rawValue }
    }

    /// Average effectiveness score (1-5), computed from sum and count
    var averageEffectiveness: Double? {
        guard effectivenessCount > 0 else { return nil }
        return Double(effectivenessSum) / Double(effectivenessCount)
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        label: String,
        strategyDescription: String? = nil,
        category: TriggerCategory,
        isSystem: Bool = false,
        effectivenessSum: Int = 0,
        effectivenessCount: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.label = label
        self.strategyDescription = strategyDescription
        self.categoryRaw = category.rawValue
        self.isSystem = isSystem
        self.effectivenessSum = effectivenessSum
        self.effectivenessCount = effectivenessCount
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
