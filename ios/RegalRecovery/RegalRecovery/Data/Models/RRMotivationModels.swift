import Foundation
import SwiftData

// MARK: - Motivation

@Model
final class RRMotivation {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var text: String
    var category: String
    var importanceRating: Int
    var scriptureReference: String?
    var isArchived: Bool
    var source: String
    var lastSurfacedAt: Date?
    var surfaceCount: Int
    var reflectionCount: Int
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        text: String,
        category: MotivationCategory,
        importanceRating: Int = MotivationImportance.defaultRating,
        scriptureReference: String? = nil,
        isArchived: Bool = false,
        source: MotivationSource = .manual,
        lastSurfacedAt: Date? = nil,
        surfaceCount: Int = 0,
        reflectionCount: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.text = text
        self.category = category.rawValue
        self.importanceRating = importanceRating
        self.scriptureReference = scriptureReference
        self.isArchived = isArchived
        self.source = source.rawValue
        self.lastSurfacedAt = lastSurfacedAt
        self.surfaceCount = surfaceCount
        self.reflectionCount = reflectionCount
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var motivationCategory: MotivationCategory {
        MotivationCategory(rawValue: category) ?? .personalGrowth
    }

    var motivationSource: MotivationSource {
        MotivationSource(rawValue: source) ?? .manual
    }

    var importanceLabel: String {
        MotivationImportance.label(for: importanceRating)
    }
}

// MARK: - Motivation History

@Model
final class RRMotivationHistory {

    @Attribute(.unique) var id: UUID
    var motivationId: UUID
    var changeType: String
    var previousValue: String?
    var newValue: String?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        motivationId: UUID,
        changeType: MotivationChangeType,
        previousValue: String? = nil,
        newValue: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.motivationId = motivationId
        self.changeType = changeType.rawValue
        self.previousValue = previousValue
        self.newValue = newValue
        self.timestamp = timestamp
    }

    var motivationChangeType: MotivationChangeType {
        MotivationChangeType(rawValue: changeType) ?? .created
    }
}
