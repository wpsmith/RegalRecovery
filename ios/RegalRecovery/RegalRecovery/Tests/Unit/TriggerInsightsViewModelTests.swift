import Testing
@testable import RegalRecovery

@Suite("TriggerInsightsViewModel Tests")
struct TriggerInsightsViewModelTests {

    // MARK: - Helper Functions

    private func makeEntry(
        intensity: Int? = 5,
        dayOfWeek: Int = 1,
        timeSlot: TimeOfDaySlot = .evening,
        category: String = "emotional",
        hasLinkedUrge: Bool = false
    ) -> TriggerInsightsViewModel.InsightEntry {
        TriggerInsightsViewModel.InsightEntry(
            id: UUID(),
            timestamp: Date(),
            intensity: intensity,
            dayOfWeek: dayOfWeek,
            timeOfDaySlot: timeSlot,
            triggerCategories: [category],
            hasLinkedUrge: hasLinkedUrge
        )
    }

    // MARK: - Tests

    @Test("total count matches entries")
    func testTotalCount_MatchesEntries() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(),
            makeEntry(),
            makeEntry()
        ]

        vm.recompute()

        #expect(vm.totalCount == 3)
    }

    @Test("resilience percentage excludes entries with linked urges")
    func testResiliencePercent_ExcludesLinkedUrges() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(hasLinkedUrge: false),
            makeEntry(hasLinkedUrge: false),
            makeEntry(hasLinkedUrge: true)
        ]

        vm.recompute()

        // 2 out of 3 without linked urge = 67%
        #expect(vm.resiliencePercent == 67)
    }

    @Test("average intensity excludes nil entries")
    func testAverageIntensity_ExcludesNilEntries() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(intensity: 4),
            makeEntry(intensity: 8),
            makeEntry(intensity: nil)
        ]

        vm.recompute()

        // (4 + 8) / 2 = 6.0
        #expect(vm.averageIntensity == 6.0)
    }

    @Test("category distribution counts correctly")
    func testCategoryDistribution_CountsCorrectly() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(category: "emotional"),
            makeEntry(category: "emotional"),
            makeEntry(category: "physical")
        ]

        vm.recompute()

        #expect(vm.categoryDistribution[.emotional] == 2)
        #expect(vm.categoryDistribution[.physical] == 1)
    }

    @Test("heat map cell counts by day and time slot")
    func testHeatMapData_CountsByDayAndTimeSlot() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(dayOfWeek: 2, timeSlot: .evening),
            makeEntry(dayOfWeek: 2, timeSlot: .evening),
            makeEntry(dayOfWeek: 3, timeSlot: .morning)
        ]

        vm.recompute()

        #expect(vm.heatMapData[2]?[.evening] == 2)
        #expect(vm.heatMapData[3]?[.morning] == 1)
    }

    @Test("top triggers ranked by frequency")
    func testTopTriggers_RankedByFrequency() {
        let vm = TriggerInsightsViewModel()

        vm.triggerFrequencies = [
            "Stress": 10,
            "Anxiety": 8,
            "Boredom": 7,
            "Loneliness": 5,
            "Anger": 3,
            "Fatigue": 2
        ]

        let topThree = vm.topTriggers(limit: 3)

        #expect(topThree.count == 3)
        #expect(topThree[0].label == "Stress")
        #expect(topThree[0].count == 10)
        #expect(topThree[1].label == "Anxiety")
        #expect(topThree[1].count == 8)
        #expect(topThree[2].label == "Boredom")
        #expect(topThree[2].count == 7)
    }

    @Test("empty entries produce zero metrics")
    func testEmptyEntries_ProduceZeroMetrics() {
        let vm = TriggerInsightsViewModel()

        vm.entries = []

        vm.recompute()

        #expect(vm.totalCount == 0)
        #expect(vm.resiliencePercent == 0)
        #expect(vm.averageIntensity == nil)
        #expect(vm.categoryDistribution.isEmpty)
        #expect(vm.heatMapData.isEmpty)
    }

    @Test("resilience percent rounds correctly")
    func testResiliencePercent_RoundsCorrectly() {
        let vm = TriggerInsightsViewModel()

        // 1 without urge, 2 with urge = 33.33% → rounds to 33%
        vm.entries = [
            makeEntry(hasLinkedUrge: false),
            makeEntry(hasLinkedUrge: true),
            makeEntry(hasLinkedUrge: true)
        ]

        vm.recompute()

        #expect(vm.resiliencePercent == 33)
    }

    @Test("average intensity nil when no intensities present")
    func testAverageIntensity_NilWhenNoIntensities() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(intensity: nil),
            makeEntry(intensity: nil),
            makeEntry(intensity: nil)
        ]

        vm.recompute()

        #expect(vm.averageIntensity == nil)
    }

    @Test("category distribution handles multiple categories per entry")
    func testCategoryDistribution_HandlesMultipleCategoriesPerEntry() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            TriggerInsightsViewModel.InsightEntry(
                id: UUID(),
                timestamp: Date(),
                intensity: 5,
                dayOfWeek: 1,
                timeOfDaySlot: .morning,
                triggerCategories: ["emotional", "physical"],
                hasLinkedUrge: false
            )
        ]

        vm.recompute()

        #expect(vm.categoryDistribution[.emotional] == 1)
        #expect(vm.categoryDistribution[.physical] == 1)
    }

    @Test("heat map handles multiple time slots for same day")
    func testHeatMapData_HandlesMultipleSlotsPerDay() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(dayOfWeek: 2, timeSlot: .morning),
            makeEntry(dayOfWeek: 2, timeSlot: .evening),
            makeEntry(dayOfWeek: 2, timeSlot: .morning)
        ]

        vm.recompute()

        #expect(vm.heatMapData[2]?[.morning] == 2)
        #expect(vm.heatMapData[2]?[.evening] == 1)
    }

    @Test("top triggers returns empty array when no frequencies")
    func testTopTriggers_EmptyWhenNoFrequencies() {
        let vm = TriggerInsightsViewModel()

        vm.triggerFrequencies = [:]

        let top = vm.topTriggers(limit: 5)

        #expect(top.isEmpty)
    }

    @Test("top triggers respects limit parameter")
    func testTopTriggers_RespectsLimit() {
        let vm = TriggerInsightsViewModel()

        vm.triggerFrequencies = [
            "A": 10,
            "B": 9,
            "C": 8,
            "D": 7,
            "E": 6,
            "F": 5,
            "G": 4
        ]

        let topTwo = vm.topTriggers(limit: 2)

        #expect(topTwo.count == 2)
        #expect(topTwo[0].label == "A")
        #expect(topTwo[1].label == "B")
    }

    @Test("100% resilience when no linked urges")
    func testResiliencePercent_100WhenNoLinkedUrges() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(hasLinkedUrge: false),
            makeEntry(hasLinkedUrge: false),
            makeEntry(hasLinkedUrge: false)
        ]

        vm.recompute()

        #expect(vm.resiliencePercent == 100)
    }

    @Test("0% resilience when all have linked urges")
    func testResiliencePercent_0WhenAllHaveLinkedUrges() {
        let vm = TriggerInsightsViewModel()

        vm.entries = [
            makeEntry(hasLinkedUrge: true),
            makeEntry(hasLinkedUrge: true),
            makeEntry(hasLinkedUrge: true)
        ]

        vm.recompute()

        #expect(vm.resiliencePercent == 0)
    }
}
