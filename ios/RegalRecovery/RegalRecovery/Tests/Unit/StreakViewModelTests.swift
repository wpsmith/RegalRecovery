import XCTest
@testable import RegalRecovery

final class StreakViewModelTests: XCTestCase {

    // MARK: - calculateStreakDays

    func testCalculateStreakDays_270DaysAgo_Returns270() {
        let vm = StreakViewModel()
        let calendar = Calendar.current
        vm.sobrietyDate = calendar.date(byAdding: .day, value: -270, to: calendar.startOfDay(for: Date()))!

        let days = vm.calculateStreakDays()
        XCTAssertEqual(days, 270)
    }

    func testCalculateStreakDays_Today_Returns0() {
        let vm = StreakViewModel()
        vm.sobrietyDate = Calendar.current.startOfDay(for: Date())

        let days = vm.calculateStreakDays()
        XCTAssertEqual(days, 0)
    }

    // MARK: - nextMilestone

    func testNextMilestone_270Days_Returns300() {
        // 270 is itself a milestone threshold, so the next one after 270 is 365
        let vm = StreakViewModel()
        let next = vm.nextMilestone(for: 270)
        XCTAssertEqual(next, 365)
    }

    func testNextMilestone_0Days_Returns1() {
        let vm = StreakViewModel()
        let next = vm.nextMilestone(for: 0)
        XCTAssertEqual(next, 1)
    }

    func testNextMilestone_1Day_Returns3() {
        let vm = StreakViewModel()
        let next = vm.nextMilestone(for: 1)
        XCTAssertEqual(next, 3)
    }

    func testNextMilestone_BeyondAllThresholds_ReturnsNextYear() {
        let vm = StreakViewModel()
        // 3650 is the last threshold, so 3651 should go to the next yearly milestone
        let next = vm.nextMilestone(for: 3651)
        XCTAssertEqual(next, 3650 + 365) // 11 years = 4015
    }

    // MARK: - recordRelapse

    func testRecordRelapse_ResetsStreak() async throws {
        let vm = StreakViewModel()
        vm.currentDays = 270
        vm.sobrietyDate = Calendar.current.date(byAdding: .day, value: -270, to: Date())!
        vm.totalRelapses = 2

        try await vm.recordRelapse(notes: "Triggered by stress", triggers: ["stress", "isolation"])

        XCTAssertEqual(vm.currentDays, 0)
        XCTAssertEqual(vm.totalRelapses, 3)
        XCTAssertEqual(vm.nextMilestoneDays, 1)

        // Sobriety date should be approximately now
        let secondsSinceReset = Date().timeIntervalSince(vm.sobrietyDate)
        XCTAssertLessThan(secondsSinceReset, 5.0)
    }

    // MARK: - milestoneScripture

    func testMilestoneScripture_AllMilestonesHaveScripture() {
        let vm = StreakViewModel()

        for threshold in StreakViewModel.milestoneThresholds {
            let scripture = vm.milestoneScripture(for: threshold)
            XCTAssertFalse(scripture.isEmpty, "Milestone at \(threshold) days should have a scripture")
            XCTAssertTrue(scripture.contains("—"), "Scripture for \(threshold) days should contain an em dash separator")
        }
    }

    func testMilestoneScripture_UnknownDay_ReturnsFallback() {
        let vm = StreakViewModel()
        let scripture = vm.milestoneScripture(for: 999)
        XCTAssertTrue(scripture.contains("Psalm 37:5"))
    }
}
