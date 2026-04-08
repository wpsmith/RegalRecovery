import Foundation
import SwiftData

// MARK: - SwiftData Models for Offline Prayer Support

/// Local prayer session stored in SwiftData for offline support (PR-AC8.1).
@Model
final class PrayerSessionLocal {
    @Attribute(.unique) var prayerId: String
    var timestamp: Date
    var prayerType: String
    var durationMinutes: Int?
    var notes: String?
    var linkedPrayerId: String?
    var linkedPrayerTitle: String?
    var moodBefore: Int?
    var moodAfter: Int?
    var isEphemeral: Bool
    var isSynced: Bool
    var createdAt: Date
    var modifiedAt: Date

    init(
        prayerId: String,
        timestamp: Date,
        prayerType: String,
        durationMinutes: Int? = nil,
        notes: String? = nil,
        linkedPrayerId: String? = nil,
        linkedPrayerTitle: String? = nil,
        moodBefore: Int? = nil,
        moodAfter: Int? = nil,
        isEphemeral: Bool = false,
        isSynced: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.prayerId = prayerId
        self.timestamp = timestamp
        self.prayerType = prayerType
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.linkedPrayerId = linkedPrayerId
        self.linkedPrayerTitle = linkedPrayerTitle
        self.moodBefore = moodBefore
        self.moodAfter = moodAfter
        self.isEphemeral = isEphemeral
        self.isSynced = isSynced
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

/// Local library prayer cached for offline browsing (PR-AC8.2).
@Model
final class LibraryPrayerLocal {
    @Attribute(.unique) var prayerId: String
    var title: String
    var body: String
    var topicTags: [String]
    var sourceAttribution: String
    var scriptureConnection: String?
    var packId: String
    var packName: String
    var stepNumber: Int?
    var tier: String
    var isLocked: Bool
    var isFavorite: Bool
    var language: String
    var cachedAt: Date

    init(
        prayerId: String,
        title: String,
        body: String,
        topicTags: [String] = [],
        sourceAttribution: String = "",
        scriptureConnection: String? = nil,
        packId: String,
        packName: String = "",
        stepNumber: Int? = nil,
        tier: String = "free",
        isLocked: Bool = false,
        isFavorite: Bool = false,
        language: String = "en",
        cachedAt: Date = Date()
    ) {
        self.prayerId = prayerId
        self.title = title
        self.body = body
        self.topicTags = topicTags
        self.sourceAttribution = sourceAttribution
        self.scriptureConnection = scriptureConnection
        self.packId = packId
        self.packName = packName
        self.stepNumber = stepNumber
        self.tier = tier
        self.isLocked = isLocked
        self.isFavorite = isFavorite
        self.language = language
        self.cachedAt = cachedAt
    }
}

/// Local personal prayer stored in SwiftData.
@Model
final class PersonalPrayerLocal {
    @Attribute(.unique) var personalPrayerId: String
    var title: String
    var body: String
    var topicTags: [String]
    var scriptureReference: String?
    var isFavorite: Bool
    var sortOrder: Int
    var isSynced: Bool
    var createdAt: Date
    var modifiedAt: Date

    init(
        personalPrayerId: String,
        title: String,
        body: String,
        topicTags: [String] = [],
        scriptureReference: String? = nil,
        isFavorite: Bool = false,
        sortOrder: Int = 0,
        isSynced: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.personalPrayerId = personalPrayerId
        self.title = title
        self.body = body
        self.topicTags = topicTags
        self.scriptureReference = scriptureReference
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.isSynced = isSynced
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}

// MARK: - Prayer Store

/// Manages local prayer data with offline support and sync (PR-AC8.1, PR-AC8.3).
@MainActor
@Observable
final class PrayerStore {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Offline Prayer Session Queue

    /// Stores a prayer session locally when offline (PR-AC8.1).
    func enqueueSession(_ session: PrayerSessionLocal) throws {
        session.isSynced = false
        modelContext.insert(session)
        try modelContext.save()
    }

    /// Gets all unsynced prayer sessions for sync.
    func getUnsyncedSessions() throws -> [PrayerSessionLocal] {
        let descriptor = FetchDescriptor<PrayerSessionLocal>(
            predicate: #Predicate { !$0.isSynced },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Marks a session as synced after successful upload.
    func markSynced(_ session: PrayerSessionLocal) throws {
        session.isSynced = true
        try modelContext.save()
    }

    /// Union merge for offline conflict resolution (PR-AC8.3).
    /// All sessions are preserved -- no prayer session is lost.
    func mergeRemoteSessions(_ remoteSessions: [PrayerSessionDTO]) throws {
        for remote in remoteSessions {
            let descriptor = FetchDescriptor<PrayerSessionLocal>(
                predicate: #Predicate<PrayerSessionLocal> { $0.prayerId == remote.prayerId }
            )
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                // New session from remote -- insert locally.
                let local = PrayerSessionLocal(
                    prayerId: remote.prayerId,
                    timestamp: ISO8601DateFormatter().date(from: remote.timestamp) ?? Date(),
                    prayerType: remote.prayerType,
                    durationMinutes: remote.durationMinutes,
                    notes: remote.notes,
                    linkedPrayerId: remote.linkedPrayerId,
                    linkedPrayerTitle: remote.linkedPrayerTitle,
                    moodBefore: remote.moodBefore,
                    moodAfter: remote.moodAfter,
                    isEphemeral: remote.isEphemeral ?? false,
                    isSynced: true
                )
                modelContext.insert(local)
            }
        }
        try modelContext.save()
    }

    // MARK: - Library Cache

    /// Caches library prayers for offline browsing (PR-AC8.2).
    func cacheLibraryPrayers(_ prayers: [LibraryPrayerDTO]) throws {
        for dto in prayers {
            let local = LibraryPrayerLocal(
                prayerId: dto.id,
                title: dto.title,
                body: dto.body,
                topicTags: dto.topicTags ?? [],
                sourceAttribution: dto.sourceAttribution ?? "",
                scriptureConnection: dto.scriptureConnection,
                packId: dto.packId ?? "",
                packName: dto.packName ?? "",
                stepNumber: dto.stepNumber,
                tier: dto.tier ?? "free",
                isLocked: dto.isLocked ?? false,
                isFavorite: dto.isFavorite ?? false,
                language: dto.language ?? "en"
            )
            modelContext.insert(local)
        }
        try modelContext.save()
    }

    /// Gets cached library prayers for offline browsing.
    func getCachedLibraryPrayers(packId: String? = nil) throws -> [LibraryPrayerLocal] {
        var descriptor: FetchDescriptor<LibraryPrayerLocal>
        if let packId {
            descriptor = FetchDescriptor<LibraryPrayerLocal>(
                predicate: #Predicate { $0.packId == packId },
                sortBy: [SortDescriptor(\.title)]
            )
        } else {
            descriptor = FetchDescriptor<LibraryPrayerLocal>(
                sortBy: [SortDescriptor(\.title)]
            )
        }
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Prayer History

    /// Gets all local prayer sessions sorted by timestamp descending.
    func getLocalSessions() throws -> [PrayerSessionLocal] {
        let descriptor = FetchDescriptor<PrayerSessionLocal>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
