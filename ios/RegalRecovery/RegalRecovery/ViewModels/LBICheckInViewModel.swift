import Foundation
import SwiftUI
import SwiftData

@Observable
class LBICheckInViewModel {

    // MARK: - State

    var criticalItems: [LBICriticalItem] = []
    var toggleStates: [UUID: Bool] = [:]
    var isEditingExisting: Bool = false
    var existingEntryId: UUID?
    var isLoading: Bool = true
    var hasActiveProfile: Bool = false
    var setupComplete: Bool = false
    var activeProfileVersionId: UUID?

    // MARK: - Computed Properties

    var dailyScore: Int {
        toggleStates.values.filter { $0 }.count
    }

    var scoreLabel: String {
        "\(dailyScore) / 7"
    }

    // MARK: - Load

    func load(context: ModelContext, userId: UUID) {
        isLoading = true
        defer { isLoading = false }

        // 1. Fetch active RRLBIProfile for userId
        let uid = userId // UUID capture for predicate
        let profileDescriptor = FetchDescriptor<RRLBIProfile>(
            predicate: #Predicate { $0.userId == uid && $0.isActive }
        )

        guard let profile = try? context.fetch(profileDescriptor).first else {
            hasActiveProfile = false
            setupComplete = false
            return
        }

        hasActiveProfile = true

        // 2. Get latest RRLBIProfileVersion (highest versionNumber > 0)
        let profileId = profile.id
        let versionDescriptor = FetchDescriptor<RRLBIProfileVersion>(
            predicate: #Predicate<RRLBIProfileVersion> { version in
                version.profileId == profileId && version.versionNumber > 0
            },
            sortBy: [SortDescriptor(\.versionNumber, order: .reverse)]
        )

        guard let latestVersion = try? context.fetch(versionDescriptor).first else {
            setupComplete = false
            return
        }

        setupComplete = true
        activeProfileVersionId = latestVersion.id

        // 3. Decode criticalItemsJSON -> [LBICriticalItem]
        let items = latestVersion.criticalItems

        // 4. Set criticalItems sorted by sortOrder
        criticalItems = items.sorted { $0.sortOrder < $1.sortOrder }

        // 5. Check for existing RRLBIDailyEntry for today
        let todayStart = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: todayStart) else {
            // Initialize all toggleStates to false
            for item in criticalItems {
                toggleStates[item.id] = false
            }
            return
        }

        let entryDescriptor = FetchDescriptor<RRLBIDailyEntry>(
            predicate: #Predicate<RRLBIDailyEntry> { entry in
                entry.userId == uid && entry.date >= todayStart && entry.date < tomorrow
            }
        )

        if let existingEntry = try? context.fetch(entryDescriptor).first {
            // Load existing entry
            isEditingExisting = true
            existingEntryId = existingEntry.id

            // Parse scores dict and load into toggleStates
            let scores = existingEntry.scores
            for item in criticalItems {
                toggleStates[item.id] = scores[item.id.uuidString] ?? false
            }
        } else {
            // Initialize all toggleStates to false
            for item in criticalItems {
                toggleStates[item.id] = false
            }
        }
    }

    // MARK: - Toggle

    func toggleItem(_ itemId: UUID) {
        toggleStates[itemId] = !(toggleStates[itemId] ?? false)
    }

    func isItemToggled(_ itemId: UUID) -> Bool {
        toggleStates[itemId] ?? false
    }

    // MARK: - Save

    func save(context: ModelContext, userId: UUID) {
        guard let versionId = activeProfileVersionId else { return }

        // Encode toggleStates to [String: Bool] where key is UUID.uuidString
        let scoresDict: [String: Bool] = toggleStates.reduce(into: [:]) { result, pair in
            result[pair.key.uuidString] = pair.value
        }

        // Encode to JSON
        guard let scoresData = try? JSONEncoder().encode(scoresDict),
              let scoresJSON = String(data: scoresData, encoding: .utf8) else {
            return
        }

        let totalScore = dailyScore
        let now = Date()
        let todayStart = Calendar.current.startOfDay(for: now)

        if isEditingExisting, let entryId = existingEntryId {
            // Update existing entry
            let entryDescriptor = FetchDescriptor<RRLBIDailyEntry>(
                predicate: #Predicate { $0.id == entryId }
            )

            if let entry = try? context.fetch(entryDescriptor).first {
                entry.scoresJSON = scoresJSON
                entry.totalScore = totalScore
                entry.modifiedAt = now
            }
        } else {
            // Create new entry
            let newEntry = RRLBIDailyEntry(
                userId: userId,
                date: todayStart,
                profileVersionId: versionId,
                scoresJSON: scoresJSON,
                totalScore: totalScore,
                isMissedDay: false,
                createdAt: now,
                modifiedAt: now
            )
            context.insert(newEntry)
        }

        // Save context
        try? context.save()
    }
}
