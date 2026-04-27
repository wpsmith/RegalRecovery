import Foundation
import SwiftData

enum AssessmentStep: Equatable {
    case quadrant(QuadrantType)
    case summary
}

@Observable
class QuadrantAssessmentViewModel {

    var currentStep: AssessmentStep = .quadrant(.body)
    var scores: [QuadrantType: Int] = Dictionary(uniqueKeysWithValues: QuadrantType.allCases.map { ($0, 5) })
    var indicators: [QuadrantType: Set<String>] = Dictionary(uniqueKeysWithValues: QuadrantType.allCases.map { ($0, []) })
    var reflections: [QuadrantType: String] = Dictionary(uniqueKeysWithValues: QuadrantType.allCases.map { ($0, "") })
    var isEditingExisting: Bool = false
    var existingAssessmentId: UUID?
    var isSaved: Bool = false

    var isAtSummary: Bool {
        currentStep == .summary
    }

    var progress: Double {
        switch currentStep {
        case .quadrant(.body): return 0.25
        case .quadrant(.mind): return 0.5
        case .quadrant(.heart): return 0.75
        case .quadrant(.spirit): return 1.0
        case .summary: return 1.0
        }
    }

    var computedBalanceScore: Double {
        QuadrantScoringService.balanceScore(
            body: scores[.body] ?? 5,
            mind: scores[.mind] ?? 5,
            heart: scores[.heart] ?? 5,
            spirit: scores[.spirit] ?? 5
        )
    }

    var computedWellnessLevel: WellnessLevel {
        QuadrantScoringService.wellnessLevel(
            body: scores[.body] ?? 5,
            mind: scores[.mind] ?? 5,
            heart: scores[.heart] ?? 5,
            spirit: scores[.spirit] ?? 5
        )
    }

    var computedImbalances: [QuadrantType] {
        QuadrantScoringService.detectImbalances(
            body: scores[.body] ?? 5,
            mind: scores[.mind] ?? 5,
            heart: scores[.heart] ?? 5,
            spirit: scores[.spirit] ?? 5
        )
    }

    var recommendations: [(quadrant: QuadrantType, activities: [(key: String, label: String)])] {
        let imbalanced = Set(computedImbalances)
        let lowScoreQuadrants = QuadrantType.allCases.filter { (scores[$0] ?? 5) <= 5 }
        let imbalancedFirst = lowScoreQuadrants.filter { imbalanced.contains($0) }
        let otherLow = lowScoreQuadrants.filter { !imbalanced.contains($0) }
        return (imbalancedFirst + otherLow).map { quadrant in
            (quadrant: quadrant, activities: quadrant.recommendedActivities)
        }
    }

    private static let orderedSteps: [AssessmentStep] = [
        .quadrant(.body),
        .quadrant(.mind),
        .quadrant(.heart),
        .quadrant(.spirit),
        .summary,
    ]

    func next() {
        guard let idx = Self.orderedSteps.firstIndex(of: currentStep),
              idx + 1 < Self.orderedSteps.count else { return }
        currentStep = Self.orderedSteps[idx + 1]
    }

    func previous() {
        guard let idx = Self.orderedSteps.firstIndex(of: currentStep), idx > 0 else { return }
        currentStep = Self.orderedSteps[idx - 1]
    }

    func load(context: ModelContext, userId: UUID) {
        let weekStart = QuadrantScoringService.weekStartDate(for: Date())
        let (weekNum, yr) = QuadrantScoringService.isoWeekComponents(for: weekStart)
        let uid = userId

        let descriptor = FetchDescriptor<RRQuadrantAssessment>(
            predicate: #Predicate { $0.userId == uid && $0.isoWeekNumber == weekNum && $0.isoYear == yr }
        )

        guard let existing = try? context.fetch(descriptor).first else {
            reset()
            return
        }

        scores[.body] = existing.bodyScore
        scores[.mind] = existing.mindScore
        scores[.heart] = existing.heartScore
        scores[.spirit] = existing.spiritScore
        indicators[.body] = Set(existing.bodyIndicators)
        indicators[.mind] = Set(existing.mindIndicators)
        indicators[.heart] = Set(existing.heartIndicators)
        indicators[.spirit] = Set(existing.spiritIndicators)
        reflections[.body] = existing.bodyReflection ?? ""
        reflections[.mind] = existing.mindReflection ?? ""
        reflections[.heart] = existing.heartReflection ?? ""
        reflections[.spirit] = existing.spiritReflection ?? ""
        isEditingExisting = true
        existingAssessmentId = existing.id
    }

    func save(context: ModelContext, userId: UUID) {
        let weekStart = QuadrantScoringService.weekStartDate(for: Date())
        let body = scores[.body] ?? 5
        let mind = scores[.mind] ?? 5
        let heart = scores[.heart] ?? 5
        let spirit = scores[.spirit] ?? 5
        let balance = QuadrantScoringService.balanceScore(body: body, mind: mind, heart: heart, spirit: spirit)
        let level = QuadrantScoringService.wellnessLevel(body: body, mind: mind, heart: heart, spirit: spirit)
        let imbalances = QuadrantScoringService.detectImbalances(body: body, mind: mind, heart: heart, spirit: spirit)
        let now = Date()

        if let existingId = existingAssessmentId {
            let eid = existingId
            let descriptor = FetchDescriptor<RRQuadrantAssessment>(
                predicate: #Predicate { $0.id == eid }
            )
            if let assessment = try? context.fetch(descriptor).first {
                applyScores(to: assessment, body: body, mind: mind, heart: heart, spirit: spirit,
                            balance: balance, level: level, imbalances: imbalances, modifiedAt: now)
            }
        } else {
            let assessment = RRQuadrantAssessment(userId: userId, weekStartDate: weekStart)
            applyScores(to: assessment, body: body, mind: mind, heart: heart, spirit: spirit,
                        balance: balance, level: level, imbalances: imbalances, modifiedAt: now)
            context.insert(assessment)
            existingAssessmentId = assessment.id
            isEditingExisting = true
        }

        try? context.save()
        isSaved = true
    }

    private func applyScores(
        to assessment: RRQuadrantAssessment,
        body: Int, mind: Int, heart: Int, spirit: Int,
        balance: Double,
        level: WellnessLevel,
        imbalances: [QuadrantType],
        modifiedAt: Date
    ) {
        assessment.bodyScore = body
        assessment.mindScore = mind
        assessment.heartScore = heart
        assessment.spiritScore = spirit
        assessment.balanceScore = balance
        assessment.wellnessLevel = level.rawValue
        assessment.bodyIndicators = Array(indicators[.body] ?? [])
        assessment.mindIndicators = Array(indicators[.mind] ?? [])
        assessment.heartIndicators = Array(indicators[.heart] ?? [])
        assessment.spiritIndicators = Array(indicators[.spirit] ?? [])
        assessment.bodyReflection = reflections[.body]?.isEmpty == true ? nil : reflections[.body]
        assessment.mindReflection = reflections[.mind]?.isEmpty == true ? nil : reflections[.mind]
        assessment.heartReflection = reflections[.heart]?.isEmpty == true ? nil : reflections[.heart]
        assessment.spiritReflection = reflections[.spirit]?.isEmpty == true ? nil : reflections[.spirit]
        assessment.imbalancedQuadrants = imbalances
        assessment.modifiedAt = modifiedAt
        assessment.needsSync = true
    }

    private func reset() {
        scores = Dictionary(uniqueKeysWithValues: QuadrantType.allCases.map { ($0, 5) })
        indicators = Dictionary(uniqueKeysWithValues: QuadrantType.allCases.map { ($0, []) })
        reflections = Dictionary(uniqueKeysWithValues: QuadrantType.allCases.map { ($0, "") })
        isEditingExisting = false
        existingAssessmentId = nil
        isSaved = false
    }
}
