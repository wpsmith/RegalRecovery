import XCTest
@testable import RegalRecovery

final class CheckInViewModelTests: XCTestCase {

    // MARK: - calculateScore

    func testCalculateScore_AllMax_Returns100() {
        let vm = CheckInViewModel()
        let answers: [String: Int] = [
            "sobriety": 10,
            "engagement": 10,
            "emotionalHealth": 10,
            "connection": 10,
            "growth": 10
        ]

        let score = vm.calculateScore(from: answers)
        XCTAssertEqual(score, 100)
    }

    func testCalculateScore_AllMin_Returns0() {
        let vm = CheckInViewModel()
        let answers: [String: Int] = [
            "sobriety": 0,
            "engagement": 0,
            "emotionalHealth": 0,
            "connection": 0,
            "growth": 0
        ]

        let score = vm.calculateScore(from: answers)
        XCTAssertEqual(score, 0)
    }

    func testCalculateScore_MixedValues_ReturnsWeightedAverage() {
        let vm = CheckInViewModel()

        // sobriety=10 (0.30), engagement=8 (0.25), emotionalHealth=6 (0.20), connection=4 (0.15), growth=2 (0.10)
        // weighted = (10*0.30 + 8*0.25 + 6*0.20 + 4*0.15 + 2*0.10) / 1.0 = 3.0 + 2.0 + 1.2 + 0.6 + 0.2 = 7.0
        // score = 7.0 * 10 = 70
        let answers: [String: Int] = [
            "sobriety": 10,
            "engagement": 8,
            "emotionalHealth": 6,
            "connection": 4,
            "growth": 2
        ]

        let score = vm.calculateScore(from: answers)
        XCTAssertEqual(score, 70)
    }

    func testCalculateScore_EmptyAnswers_Returns0() {
        let vm = CheckInViewModel()
        let score = vm.calculateScore(from: [:])
        XCTAssertEqual(score, 0)
    }

    func testCalculateScore_SingleCategory_ReturnsScaled() {
        let vm = CheckInViewModel()
        let answers: [String: Int] = ["sobriety": 8]

        let score = vm.calculateScore(from: answers)
        // 8 * 0.30 / 0.30 * 10 = 80
        XCTAssertEqual(score, 80)
    }
}
