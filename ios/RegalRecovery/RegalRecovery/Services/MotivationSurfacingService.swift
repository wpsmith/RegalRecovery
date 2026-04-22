import Foundation

enum MotivationSurfacingService {

    static func select(
        from motivations: [RRMotivation],
        context: SurfacingContext,
        count: Int
    ) -> [RRMotivation] {
        let active = motivations.filter { !$0.isArchived }
        guard !active.isEmpty else { return [] }

        let prioritizedCategories = context.prioritizedCategories
        let now = Date()

        let scored = active.map { motivation -> (RRMotivation, Double) in
            var score = Double(motivation.importanceRating) * 3.0

            if prioritizedCategories.contains(motivation.motivationCategory) {
                score += 1.0
            }

            if let lastSurfaced = motivation.lastSurfacedAt {
                let daysSince = now.timeIntervalSince(lastSurfaced) / 86400.0
                score += min(daysSince * 0.1, 3.0)
            } else {
                score += 3.0
            }

            return (motivation, score)
        }

        let sorted = scored.sorted { $0.1 > $1.1 }
        let selected = sorted.prefix(count).map(\.0)
        return Array(selected)
    }
}
