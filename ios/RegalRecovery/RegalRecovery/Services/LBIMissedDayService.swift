import Foundation
import SwiftData

struct LBIMissedDayService {

    /// Check for and backfill any missed days between the last entry and yesterday.
    /// Does NOT create an entry for today.
    /// Does NOT create entries for days before profile setup was completed.
    static func backfillMissedDays(context: ModelContext, userId: UUID) {
        let calendar = Calendar.current

        // 1. Fetch active RRLBIProfile for userId
        let uid = userId
        let profileDescriptor = FetchDescriptor<RRLBIProfile>(
            predicate: #Predicate { $0.userId == uid && $0.isActive == true }
        )

        guard let profile = try? context.fetch(profileDescriptor).first else {
            return
        }

        // 2. Get all versions with versionNumber > 0, sorted by versionNumber ascending
        let sortedVersions = profile.versions
            .filter { $0.versionNumber > 0 }
            .sorted { $0.versionNumber < $1.versionNumber }

        // If none exist, return early (setup not complete)
        guard let firstVersion = sortedVersions.first else {
            return
        }

        // 3. Determine earliest date to check: the effectiveFrom of version 1 (first completed setup)
        let setupDate = calendar.startOfDay(for: firstVersion.effectiveFrom)

        // 4. Fetch all existing RRLBIDailyEntry dates for this userId
        let entriesDescriptor = FetchDescriptor<RRLBIDailyEntry>(
            predicate: #Predicate { $0.userId == uid }
        )

        let existingEntries = (try? context.fetch(entriesDescriptor)) ?? []
        let existingDates = Set(existingEntries.map { calendar.startOfDay(for: $0.date) })

        // 5. Yesterday = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
            return
        }
        let yesterdayStart = calendar.startOfDay(for: yesterday)

        // If yesterday < setupDate, nothing to backfill
        guard yesterdayStart >= setupDate else {
            return
        }

        // 6. Iterate each calendar day from setupDate to yesterday (inclusive):
        var currentDate = setupDate
        while currentDate <= yesterdayStart {
            if !existingDates.contains(currentDate) {
                // Find active version for this date
                if let version = activeVersion(for: currentDate, versions: sortedVersions) {
                    // Create missed-day entry
                    let entry = RRLBIDailyEntry(
                        userId: userId,
                        date: currentDate,
                        profileVersionId: version.id
                    )

                    // Set all scores to true (all 7 critical items triggered)
                    let criticalItems = version.criticalItems
                    var scores: [String: Bool] = [:]
                    for item in criticalItems {
                        scores[item.id.uuidString] = true
                    }
                    entry.scores = scores
                    entry.totalScore = criticalItems.count
                    entry.isMissedDay = true

                    context.insert(entry)
                }
            }

            // Move to next day
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }

        // 7. Save context
        try? context.save()
    }

    /// Find the profile version active on a given date.
    /// Returns the version with the highest versionNumber whose effectiveFrom <= date.
    static func activeVersion(
        for date: Date,
        versions: [RRLBIProfileVersion]
    ) -> RRLBIProfileVersion? {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        // Sort by effectiveFrom descending, return first where effectiveFrom <= date
        return versions
            .sorted { $0.effectiveFrom > $1.effectiveFrom }
            .first { calendar.startOfDay(for: $0.effectiveFrom) <= targetDate }
    }
}
