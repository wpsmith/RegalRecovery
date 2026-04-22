import Foundation
import Observation

@Observable
class AffirmationsViewModel {
    var packs: [AffirmationPack] = []
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
        todaysAffirmation = getTodaysAffirmation()
    }

    /// Weighted rotation algorithm:
    /// - 40% chance: affirmation related to recent triggers
    /// - 40% chance: least-recently-shown affirmation
    /// - 20% chance: random from any pack
    /// Note: favorites are now managed via SwiftData (RRAffirmationFavorite),
    /// not in-memory on the view model.
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

        if roll < 0.8 {
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

        // 20% random fallback (or fallback if other buckets were empty)
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
