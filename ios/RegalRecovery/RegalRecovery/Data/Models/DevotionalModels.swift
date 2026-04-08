// DevotionalModels.swift
// Regal Recovery
//
// Hand-written Swift types matching the Devotionals OpenAPI spec.
// Source of truth: docs/specs/openapi/devotionals.yaml

import Foundation
import SwiftData

// MARK: - Content Tier

enum DevotionalContentTier: String, Codable, Sendable {
    case free
    case premium
}

// MARK: - Topic

enum DevotionalTopic: String, Codable, CaseIterable, Sendable {
    case shame
    case temptation
    case identity
    case marriage
    case forgiveness
    case surrender
    case gratitude
    case restoration
    case fear
    case hope
}

// MARK: - Mood Tag

enum DevotionalMoodTag: String, Codable, CaseIterable, Sendable {
    case grateful
    case hopeful
    case peaceful
    case convicted
    case challenged
    case comforted
    case anxious
    case struggling
    case numb

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Bible Translation

enum BibleTranslation: String, Codable, CaseIterable, Sendable {
    case NIV, ESV, NLT, KJV, RVR1960, NVI
}

// MARK: - Series Status

enum DevotionalSeriesStatus: String, Codable, Sendable {
    case notStarted = "not_started"
    case active
    case paused
    case completed
}

// MARK: - Series Category

enum DevotionalSeriesCategory: String, Codable, Sendable {
    case recovery
    case marriage
    case identity
    case spiritualGrowth = "spiritual-growth"
}

// MARK: - Share Type

enum DevotionalShareType: String, Codable, Sendable {
    case contact
    case link
    case image
}

// MARK: - Full Devotional

struct DevotionalDTO: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let scriptureReference: String
    let scriptureText: String
    let bibleTranslation: BibleTranslation
    let reading: String
    let recoveryConnection: String
    let reflectionQuestion: String
    let prayer: String
    let authorName: String?
    let authorBio: String?
    let date: String
    let topic: DevotionalTopic
    let seriesId: String?
    let seriesDay: Int?
    let seriesTotalDays: Int?
    let tier: DevotionalContentTier
    let language: String
    let isCompleted: Bool
    let isFavorite: Bool
    let links: [String: String]?
}

// MARK: - Devotional Summary (List View)

struct DevotionalSummaryDTO: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let scriptureReference: String
    let topic: DevotionalTopic
    let authorName: String?
    let date: String
    let seriesId: String?
    let tier: DevotionalContentTier
    let isLocked: Bool
    let isCompleted: Bool
    let isFavorite: Bool
    let language: String
    let links: [String: String]?
}

// MARK: - Completion Request

struct DevotionalCompletionRequestDTO: Codable, Sendable {
    let timestamp: String
    let reflection: String?
    let moodTag: DevotionalMoodTag?
}

// MARK: - Completion Response

struct DevotionalCompletionDTO: Codable, Identifiable, Sendable {
    var id: String { completionId }
    let completionId: String
    let devotionalId: String
    let devotionalTitle: String?
    let scriptureReference: String?
    let timestamp: String
    let reflection: String?
    let moodTag: DevotionalMoodTag?
    let seriesId: String?
    let seriesDay: Int?
    let devotionalStreak: DevotionalStreakDTO?
    let links: [String: String]?
}

// MARK: - Completion Update Request

struct DevotionalCompletionUpdateDTO: Codable, Sendable {
    let reflection: String?
    let moodTag: DevotionalMoodTag?
}

// MARK: - Streak

struct DevotionalStreakDTO: Codable, Sendable {
    let currentDays: Int
    let longestDays: Int
    let lastCompletedDate: String?
}

// MARK: - Series

struct DevotionalSeriesDTO: Codable, Identifiable, Sendable {
    var id: String { seriesId }
    let seriesId: String
    let name: String
    let description: String
    let authorName: String?
    let totalDays: Int
    let tier: DevotionalContentTier
    let price: Double?
    let currency: String?
    let isOwned: Bool
    let isActive: Bool
    let currentDay: Int?
    let completedDays: Int
    let status: DevotionalSeriesStatus
    let category: DevotionalSeriesCategory
    let language: String
    let thumbnailUrl: String?
    let links: [String: String]?
}

// MARK: - Activate Series Response

struct ActivateSeriesResponseDTO: Codable, Sendable {
    struct Data: Codable, Sendable {
        let activeSeriesId: String
        let currentDay: Int
        let totalDays: Int
        let pausedSeries: PausedSeriesDTO?
    }
    let data: Data
}

struct PausedSeriesDTO: Codable, Sendable {
    let seriesId: String
    let pausedAtDay: Int
}

// MARK: - Share Request

struct DevotionalShareRequestDTO: Codable, Sendable {
    let shareType: DevotionalShareType
    let contactId: String?
}

// MARK: - Share Response

struct DevotionalShareResponseDTO: Codable, Sendable {
    struct Data: Codable, Sendable {
        let shareUrl: String?
        let sharedToContactId: String?
        let message: String
    }
    let data: Data
}

// MARK: - Export Request

struct DevotionalExportRequestDTO: Codable, Sendable {
    let startDate: String?
    let endDate: String?
    let includeReflections: Bool?
}

// MARK: - Export Response

struct DevotionalExportResponseDTO: Codable, Sendable {
    struct Data: Codable, Sendable {
        let exportId: String
        let status: String
        let links: [String: String]?
    }
    let data: Data
}

// MARK: - Response Envelopes

struct DevotionalResponseEnvelope: Codable, Sendable {
    let data: DevotionalDTO
    let links: [String: String]?
}

struct DevotionalListResponseEnvelope: Codable, Sendable {
    let data: [DevotionalSummaryDTO]
    let links: [String: String]?
    let meta: CursorPageMeta?
}

struct CompletionResponseEnvelope: Codable, Sendable {
    let data: DevotionalCompletionDTO
    let meta: [String: String]?
}

struct HistoryResponseEnvelope: Codable, Sendable {
    let data: [DevotionalCompletionDTO]
    let links: [String: String]?
    let meta: CursorPageMeta?
}

struct FavoritesResponseEnvelope: Codable, Sendable {
    let data: [DevotionalSummaryDTO]
    let links: [String: String]?
    let meta: CursorPageMeta?
}

struct SeriesListResponseEnvelope: Codable, Sendable {
    let data: [DevotionalSeriesDTO]
    let links: [String: String]?
    let meta: CursorPageMeta?
}

struct SeriesResponseEnvelope: Codable, Sendable {
    let data: DevotionalSeriesDTO
}

struct StreakResponseEnvelope: Codable, Sendable {
    let data: DevotionalStreakDTO
}

struct CursorPageMeta: Codable, Sendable {
    let page: CursorPageDTO?
    let totalCompleted: Int?
}

struct CursorPageDTO: Codable, Sendable {
    let nextCursor: String?
    let prevCursor: String?
    let limit: Int
}

// MARK: - Offline Cache Model (SwiftData)

@Model
final class CachedDevotional {
    @Attribute(.unique) var devotionalId: String
    var title: String
    var scriptureReference: String
    var scriptureText: String
    var reading: String
    var recoveryConnection: String
    var reflectionQuestion: String
    var prayer: String
    var authorName: String?
    var date: String
    var topic: String
    var tier: String
    var cachedAt: Date

    init(from dto: DevotionalDTO) {
        self.devotionalId = dto.id
        self.title = dto.title
        self.scriptureReference = dto.scriptureReference
        self.scriptureText = dto.scriptureText
        self.reading = dto.reading
        self.recoveryConnection = dto.recoveryConnection
        self.reflectionQuestion = dto.reflectionQuestion
        self.prayer = dto.prayer
        self.authorName = dto.authorName
        self.date = dto.date
        self.topic = dto.topic.rawValue
        self.tier = dto.tier.rawValue
        self.cachedAt = Date()
    }
}

@Model
final class PendingDevotionalCompletion {
    @Attribute(.unique) var localId: String
    var devotionalId: String
    var timestamp: Date
    var reflection: String?
    var moodTag: String?
    var isSynced: Bool

    init(devotionalId: String, timestamp: Date, reflection: String?, moodTag: DevotionalMoodTag?) {
        self.localId = UUID().uuidString
        self.devotionalId = devotionalId
        self.timestamp = timestamp
        self.reflection = reflection
        self.moodTag = moodTag?.rawValue
        self.isSynced = false
    }
}
