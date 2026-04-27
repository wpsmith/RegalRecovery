import Foundation
import SwiftData

struct QuadrantTrendPoint: Identifiable {
    let id: UUID
    let weekStartDate: Date
    let bodyScore: Int
    let mindScore: Int
    let heartScore: Int
    let spiritScore: Int
    let balanceScore: Double
    let wellnessLevel: WellnessLevel
}

@Observable
class QuadrantDashboardViewModel {

    var currentAssessment: RRQuadrantAssessment?
    var trendData: [QuadrantTrendPoint] = []
    var hasAssessedThisWeek: Bool = false
    var hasEverAssessed: Bool = false
    var recommendations: [(quadrant: QuadrantType, activities: [(key: String, label: String)], isImbalanced: Bool)] = []

    func load(context: ModelContext, userId: UUID) {
        let uid = userId
        let weekStart = QuadrantScoringService.weekStartDate(for: Date())
        let (weekNum, yr) = QuadrantScoringService.isoWeekComponents(for: weekStart)

        let thisWeekDescriptor = FetchDescriptor<RRQuadrantAssessment>(
            predicate: #Predicate { $0.userId == uid && $0.isoWeekNumber == weekNum && $0.isoYear == yr }
        )
        currentAssessment = try? context.fetch(thisWeekDescriptor).first
        hasAssessedThisWeek = currentAssessment != nil

        var trendDescriptor = FetchDescriptor<RRQuadrantAssessment>(
            predicate: #Predicate { $0.userId == uid },
            sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
        )
        trendDescriptor.fetchLimit = 8
        let recent = (try? context.fetch(trendDescriptor)) ?? []
        hasEverAssessed = !recent.isEmpty

        trendData = recent.reversed().map { assessment in
            QuadrantTrendPoint(
                id: assessment.id,
                weekStartDate: assessment.weekStartDate,
                bodyScore: assessment.bodyScore,
                mindScore: assessment.mindScore,
                heartScore: assessment.heartScore,
                spiritScore: assessment.spiritScore,
                balanceScore: assessment.balanceScore,
                wellnessLevel: assessment.wellnessLevelEnum
            )
        }

        recommendations = buildRecommendations(from: currentAssessment)
    }

    private func buildRecommendations(
        from assessment: RRQuadrantAssessment?
    ) -> [(quadrant: QuadrantType, activities: [(key: String, label: String)], isImbalanced: Bool)] {
        guard let assessment else { return [] }

        let imbalanced = Set(assessment.imbalancedQuadrants)
        let scores: [QuadrantType: Int] = [
            .body: assessment.bodyScore,
            .mind: assessment.mindScore,
            .heart: assessment.heartScore,
            .spirit: assessment.spiritScore,
        ]
        let lowScoreQuadrants = QuadrantType.allCases.filter { (scores[$0] ?? 5) <= 5 }
        let imbalancedFirst = lowScoreQuadrants.filter { imbalanced.contains($0) }
        let otherLow = lowScoreQuadrants.filter { !imbalanced.contains($0) }

        return (imbalancedFirst + otherLow).map { quadrant in
            (quadrant: quadrant, activities: quadrant.recommendedActivities, isImbalanced: imbalanced.contains(quadrant))
        }
    }
}
