import Testing
@testable import RegalRecovery

@Suite("QuadrantScoringService Tests")
struct QuadrantScoringServiceTests {

    // MARK: - Balance Score

    @Test("high mean, low variance yields score >= 80")
    func testQuadrant_AC4_1_BalanceScoreHighMeanLowVariance() {
        let score = QuadrantScoringService.balanceScore(body: 8, mind: 8, heart: 8, spirit: 8)
        #expect(score >= 80.0)
    }

    @Test("high variance penalizes balance score compared to uniform scores")
    func testQuadrant_AC4_2_BalanceScorePenalizesVariance() {
        let uniform = QuadrantScoringService.balanceScore(body: 8, mind: 8, heart: 8, spirit: 8)
        let variant = QuadrantScoringService.balanceScore(body: 10, mind: 10, heart: 10, spirit: 2)
        #expect(variant < uniform)
    }

    @Test("perfect scores of 10 yield 100.0")
    func testQuadrant_AC4_4_PerfectScoreIs100() {
        let score = QuadrantScoringService.balanceScore(body: 10, mind: 10, heart: 10, spirit: 10)
        #expect(score == 100.0)
    }

    @Test("all-ones score is positive due to zero variance")
    func testQuadrant_AC4_5_AllOnesIsMinimum() {
        let score = QuadrantScoringService.balanceScore(body: 1, mind: 1, heart: 1, spirit: 1)
        #expect(score > 0)
    }

    // MARK: - Wellness Level

    @Test("high mean and low variance yields flourishing")
    func testQuadrant_AC4_6_FlourishingRequiresHighMeanAndLowVariance() {
        let level = QuadrantScoringService.wellnessLevel(body: 8, mind: 8, heart: 9, spirit: 9)
        #expect(level == .flourishing)
    }

    @Test("high mean with high variance is not flourishing")
    func testQuadrant_AC4_7_HighMeanHighVarianceIsNotFlourishing() {
        let level = QuadrantScoringService.wellnessLevel(body: 10, mind: 10, heart: 10, spirit: 2)
        #expect(level != .flourishing)
    }

    @Test("mean in 6-7 range yields growing")
    func testQuadrant_AC4_8_GrowingLevel() {
        let level = QuadrantScoringService.wellnessLevel(body: 6, mind: 7, heart: 6, spirit: 7)
        #expect(level == .growing)
    }

    @Test("mean in 4-5 range yields rebuilding")
    func testQuadrant_AC4_9_RebuildingLevel() {
        let level = QuadrantScoringService.wellnessLevel(body: 4, mind: 5, heart: 4, spirit: 5)
        #expect(level == .rebuilding)
    }

    @Test("mean below 4 yields struggling")
    func testQuadrant_AC4_10_StrugglingLevel() {
        let level = QuadrantScoringService.wellnessLevel(body: 2, mind: 3, heart: 2, spirit: 3)
        #expect(level == .struggling)
    }

    // MARK: - Imbalance Detection

    @Test("body 3+ below mean of others is detected as imbalanced")
    func testQuadrant_AC4_11_DetectsImbalancedQuadrant() {
        let imbalances = QuadrantScoringService.detectImbalances(body: 3, mind: 8, heart: 7, spirit: 8)
        #expect(imbalances == [.body])
    }

    @Test("uniform scores produce no imbalances")
    func testQuadrant_AC4_12_NoImbalanceWhenBalanced() {
        let imbalances = QuadrantScoringService.detectImbalances(body: 7, mind: 7, heart: 7, spirit: 7)
        #expect(imbalances.isEmpty)
    }

    @Test("multiple quadrants 3+ below their peer mean are detected")
    func testQuadrant_AC4_13_MultipleImbalances() {
        let imbalances = QuadrantScoringService.detectImbalances(body: 2, mind: 9, heart: 2, spirit: 9)
        #expect(imbalances.contains(.body))
        #expect(imbalances.contains(.heart))
        #expect(imbalances.count == 2)
    }

    @Test("score exactly 3 below mean of others is imbalanced")
    func testQuadrant_AC4_14_ThresholdExactly3() {
        // mean of others (mind=7, heart=7, spirit=7) = 7.0; body=4 is exactly 3 below
        let imbalances = QuadrantScoringService.detectImbalances(body: 4, mind: 7, heart: 7, spirit: 7)
        #expect(imbalances == [.body])
    }

    @Test("score 2.33 below mean of others is not imbalanced")
    func testQuadrant_AC4_15_ThresholdJustBelow3() {
        // mean of others (mind=7, heart=7, spirit=8) = 7.33; body=5 is 2.33 below
        let imbalances = QuadrantScoringService.detectImbalances(body: 5, mind: 7, heart: 7, spirit: 8)
        #expect(imbalances.isEmpty)
    }

    // MARK: - Week Calculation

    @Test("weekStartDate for a Wednesday returns the preceding Monday")
    func testQuadrant_AC2_3_WeekStartDateIsMonday() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 29 // Wednesday
        let wednesday = Calendar(identifier: .iso8601).date(from: components)!

        let weekStart = QuadrantScoringService.weekStartDate(for: wednesday)
        let weekday = Calendar(identifier: .iso8601).component(.weekday, from: weekStart)
        // In ISO8601 calendar, Monday = 2
        #expect(weekday == 2)

        var expectedComponents = DateComponents()
        expectedComponents.year = 2026
        expectedComponents.month = 4
        expectedComponents.day = 27 // Monday
        let expectedMonday = Calendar(identifier: .iso8601).date(from: expectedComponents)!
        #expect(Calendar(identifier: .iso8601).isDate(weekStart, inSameDayAs: expectedMonday))
    }

    @Test("2026-04-27 is ISO week 18 of year 2026")
    func testQuadrant_AC2_4_ISOWeekNumberCalculation() {
        var components = DateComponents()
        components.year = 2026
        components.month = 4
        components.day = 27 // Monday of week 18
        let date = Calendar(identifier: .iso8601).date(from: components)!

        let (weekNumber, year) = QuadrantScoringService.isoWeekComponents(for: date)
        #expect(weekNumber == 18)
        #expect(year == 2026)
    }
}
