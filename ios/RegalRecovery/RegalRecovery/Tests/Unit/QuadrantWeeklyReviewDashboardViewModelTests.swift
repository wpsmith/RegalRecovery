import Testing
import SwiftData
@testable import RegalRecovery

@Suite("QuadrantWeeklyReviewDashboardViewModel Tests")
struct QuadrantWeeklyReviewDashboardViewModelTests {

    private func makeAssessment(userId: UUID, weeksAgo: Int) -> RRQuadrantAssessment {
        let date = Calendar.current.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date())!
        let weekStart = QuadrantWeeklyReviewScoringService.weekStartDate(for: date)
        let assessment = RRQuadrantAssessment(userId: userId, weekStartDate: weekStart)
        return assessment
    }

    @Test("trend data is ordered chronologically ascending")
    func testQuadrant_AC3_1_TrendDataOrderedChronologically() throws {
        let container = try RRModelConfiguration.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let userId = UUID()

        let a3 = makeAssessment(userId: userId, weeksAgo: 3)
        let a1 = makeAssessment(userId: userId, weeksAgo: 1)
        let a2 = makeAssessment(userId: userId, weeksAgo: 2)
        context.insert(a3)
        context.insert(a1)
        context.insert(a2)
        try context.save()

        let vm = QuadrantWeeklyReviewDashboardViewModel()
        vm.load(context: context, userId: userId)

        #expect(vm.trendData.count == 3)
        #expect(vm.trendData[0].weekStartDate <= vm.trendData[1].weekStartDate)
        #expect(vm.trendData[1].weekStartDate <= vm.trendData[2].weekStartDate)
    }

    @Test("trend data is limited to 8 weeks")
    func testQuadrant_AC3_2_TrendShowsMaximum8Weeks() throws {
        let container = try RRModelConfiguration.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let userId = UUID()

        for weeksAgo in 1...10 {
            context.insert(makeAssessment(userId: userId, weeksAgo: weeksAgo))
        }
        try context.save()

        let vm = QuadrantWeeklyReviewDashboardViewModel()
        vm.load(context: context, userId: userId)

        #expect(vm.trendData.count <= 8)
    }

    @Test("hasAssessedThisWeek is false before load")
    func testQuadrant_AC3_3_HasAssessedThisWeekFalseInitially() {
        let vm = QuadrantWeeklyReviewDashboardViewModel()
        #expect(vm.hasAssessedThisWeek == false)
    }

    @Test("hasEverAssessed is false before load")
    func testQuadrant_AC3_4_HasEverAssessedFalseInitially() {
        let vm = QuadrantWeeklyReviewDashboardViewModel()
        #expect(vm.hasEverAssessed == false)
    }

    @Test("spirit score of 4 generates a spirit recommendation")
    func testQuadrant_AC3_5_RecommendationsForLowScore() throws {
        let container = try RRModelConfiguration.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let userId = UUID()

        let assessment = RRQuadrantAssessment(userId: userId, weekStartDate: QuadrantWeeklyReviewScoringService.weekStartDate(for: Date()))
        assessment.spiritScore = 4
        assessment.bodyScore = 7
        assessment.mindScore = 7
        assessment.heartScore = 7
        assessment.balanceScore = QuadrantWeeklyReviewScoringService.balanceScore(body: 7, mind: 7, heart: 7, spirit: 4)
        assessment.wellnessLevel = QuadrantWeeklyReviewScoringService.wellnessLevel(body: 7, mind: 7, heart: 7, spirit: 4).rawValue
        assessment.imbalancedQuadrants = QuadrantWeeklyReviewScoringService.detectImbalances(body: 7, mind: 7, heart: 7, spirit: 4)
        context.insert(assessment)
        try context.save()

        let vm = QuadrantWeeklyReviewDashboardViewModel()
        vm.load(context: context, userId: userId)

        let quadrants = vm.recommendations.map(\.quadrant)
        #expect(quadrants.contains(.spirit))
    }
}
