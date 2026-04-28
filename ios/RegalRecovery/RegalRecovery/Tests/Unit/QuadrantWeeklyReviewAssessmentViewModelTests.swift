import Testing
import SwiftData
@testable import RegalRecovery

@Suite("QuadrantWeeklyReviewAssessmentViewModel Tests")
struct QuadrantWeeklyReviewAssessmentViewModelTests {

    @Test("initial step is body quadrant")
    func testQuadrant_AC2_1_InitialStepIsBody() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        #expect(vm.currentStep == .quadrant(.body))
    }

    @Test("next from body advances to mind")
    func testQuadrant_AC2_2_NextAdvancesToMind() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        vm.next()
        #expect(vm.currentStep == .quadrant(.mind))
    }

    @Test("can navigate all four quadrants to summary")
    func testQuadrant_AC2_3_CanNavigateAllFour() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        vm.next()
        vm.next()
        vm.next()
        vm.next()
        #expect(vm.currentStep == .summary)
    }

    @Test("each score defaults to 5")
    func testQuadrant_AC2_4_ScoreDefaultsTo5() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        for quadrant in QuadrantWeeklyReviewType.allCases {
            #expect(vm.scores[quadrant] == 5)
        }
    }

    @Test("score updates persist after navigation")
    func testQuadrant_AC2_5_ScoreUpdatesPersist() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        vm.scores[.body] = 8
        vm.next()
        vm.previous()
        #expect(vm.scores[.body] == 8)
    }

    @Test("all indicator sets start empty")
    func testQuadrant_AC2_6_IndicatorsStartEmpty() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        for quadrant in QuadrantWeeklyReviewType.allCases {
            #expect(vm.indicators[quadrant]?.isEmpty == true)
        }
    }

    @Test("save does not crash when reflections are empty")
    func testQuadrant_AC2_7_ReflectionIsOptional() throws {
        let container = try RRModelConfiguration.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let userId = UUID()
        let vm = QuadrantWeeklyReviewAssessmentViewModel()

        vm.save(context: context, userId: userId)

        #expect(vm.isSaved == true)
    }

    @Test("isAtSummary is true after four next() calls")
    func testQuadrant_AC2_8_IsAtSummaryAfterAllFour() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        vm.next()
        vm.next()
        vm.next()
        vm.next()
        #expect(vm.isAtSummary == true)
    }

    @Test("progress values match spec per step")
    func testQuadrant_AC2_9_ProgressValues() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        #expect(vm.progress == 0.25)
        vm.next()
        #expect(vm.progress == 0.5)
        vm.next()
        #expect(vm.progress == 0.75)
        vm.next()
        #expect(vm.progress == 1.0)
        vm.next()
        #expect(vm.progress == 1.0)
    }

    @Test("computed imbalances reflect low body score")
    func testQuadrant_AC2_10_ComputedImbalancesReflectScores() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        vm.scores[.body] = 3
        vm.scores[.mind] = 8
        vm.scores[.heart] = 8
        vm.scores[.spirit] = 8
        #expect(vm.computedImbalances == [.body])
    }

    @Test("spirit score of 4 appears in recommendations")
    func testQuadrant_AC2_11_RecommendationsForLowScore() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        vm.scores[.spirit] = 4
        vm.scores[.body] = 7
        vm.scores[.mind] = 7
        vm.scores[.heart] = 7
        let quadrants = vm.recommendations.map(\.quadrant)
        #expect(quadrants.contains(.spirit))
    }

    @Test("all scores above 5 produces no recommendations")
    func testQuadrant_AC2_12_NoRecommendationsWhenAllHigh() {
        let vm = QuadrantWeeklyReviewAssessmentViewModel()
        for quadrant in QuadrantWeeklyReviewType.allCases {
            vm.scores[quadrant] = 8
        }
        #expect(vm.recommendations.isEmpty)
    }
}
