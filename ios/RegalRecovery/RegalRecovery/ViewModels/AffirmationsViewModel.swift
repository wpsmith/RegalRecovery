import Foundation
import Observation

@Observable
class AffirmationsViewModel {
    var packs: [AffirmationPack] = []
    var favorites: [Affirmation] = []
    var todaysAffirmation: Affirmation?
    var deliveryMode: String = "random" // random, package, dayOfWeek

    // Tracks the last time each affirmation was shown, keyed by affirmation id
    private var lastShownDates: [UUID: Date] = [:]

    // Recent trigger keywords (populated from check-ins, urge logs, etc.)
    private var recentTriggerKeywords: [String] = []

    // All affirmations flattened for convenience
    private var allAffirmations: [Affirmation] {
        packs.flatMap(\.affirmations)
    }

    func load() async {
        packs = MockData.affirmationPacks
        favorites = MockData.favoriteAffirmations
        todaysAffirmation = getTodaysAffirmation()
    }

    func toggleFavorite(_ affirmation: Affirmation) async throws {
        if let index = favorites.firstIndex(where: { $0.id == affirmation.id }) {
            favorites.remove(at: index)
        } else {
            favorites.append(affirmation)
        }
    }

    /// Weighted rotation algorithm:
    /// - 40% chance: affirmation related to recent triggers
    /// - 30% chance: from favorites
    /// - 20% chance: least-recently-shown affirmation
    /// - 10% chance: random from any pack
    func getTodaysAffirmation() -> Affirmation {
        let all = allAffirmations
        guard !all.isEmpty else {
            return MockData.todaysAffirmation
        }

        let roll = Double.random(in: 0..<1)

        if roll < 0.4 {
            // Trigger-related affirmation
            if let match = triggerRelatedAffirmation() {
                return match
            }
        }

        if roll < 0.7 {
            // Favorites
            if !favorites.isEmpty {
                let selected = favorites.randomElement()!
                lastShownDates[selected.id] = Date()
                return selected
            }
        }

        if roll < 0.9 {
            // Least-recently-shown (under-served)
            let sorted = all.sorted { a, b in
                let dateA = lastShownDates[a.id] ?? .distantPast
                let dateB = lastShownDates[b.id] ?? .distantPast
                return dateA < dateB
            }
            if let leastServed = sorted.first {
                lastShownDates[leastServed.id] = Date()
                return leastServed
            }
        }

        // 10% random fallback (or fallback if other buckets were empty)
        let selected = all.randomElement()!
        lastShownDates[selected.id] = Date()
        return selected
    }

    // MARK: - Private

    private func triggerRelatedAffirmation() -> Affirmation? {
        guard !recentTriggerKeywords.isEmpty else { return nil }

        let all = allAffirmations
        let lowered = recentTriggerKeywords.map { $0.lowercased() }

        let matches = all.filter { affirmation in
            let text = affirmation.text.lowercased()
            return lowered.contains(where: { text.contains($0) })
        }

        if let match = matches.randomElement() {
            lastShownDates[match.id] = Date()
            return match
        }

        return nil
    }
}
