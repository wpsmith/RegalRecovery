import XCTest
@testable import RegalRecovery

final class PhoneCallViewModelTests: XCTestCase {

    var viewModel: PhoneCallViewModel!

    override func setUp() {
        super.setUp()
        viewModel = PhoneCallViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Quick Log Tests (AC-PC-20)

    func testQuickLog_defaultsDirectionToMade() async throws {
        // Given a fresh view model
        // When quick log is triggered
        try await viewModel.quickLog()

        // Then direction defaults to "made"
        XCTAssertEqual(viewModel.history.first?.direction, .made)
    }

    func testQuickLog_defaultsConnectedToTrue() async throws {
        // Given a fresh view model
        // When quick log is triggered
        try await viewModel.quickLog()

        // Then connected defaults to true
        XCTAssertEqual(viewModel.history.first?.connected, true)
    }

    func testQuickLog_timestampDefaultsToNow() async throws {
        let before = Date()
        try await viewModel.quickLog()
        let after = Date()

        guard let entry = viewModel.history.first else {
            XCTFail("Expected entry in history")
            return
        }

        XCTAssertTrue(entry.timestamp >= before && entry.timestamp <= after,
                      "Timestamp should be approximately now")
    }

    // MARK: - Duration Quick-Select (AC-PC-9)

    func testDurationQuickSelect_mapsToCorrectIntegers() {
        let expected: [DurationQuickSelect: Int] = [
            .five: 5,
            .ten: 10,
            .fifteen: 15,
            .twenty: 20,
            .thirty: 30,
            .sixty: 60,
        ]

        for (quickSelect, value) in expected {
            XCTAssertEqual(quickSelect.rawValue, value,
                          "Quick-select \(quickSelect) should map to \(value)")
        }
    }

    // MARK: - Streak Display

    func testStreakDisplay_singularDay_omitsPlural() {
        viewModel.currentStreakDays = 1
        XCTAssertEqual(viewModel.streakDisplayText, "1 day")
    }

    func testStreakDisplay_pluralDays_includesPlural() {
        viewModel.currentStreakDays = 12
        XCTAssertEqual(viewModel.streakDisplayText, "12 days")
    }

    func testStreakDisplay_zeroDays() {
        viewModel.currentStreakDays = 0
        XCTAssertEqual(viewModel.streakDisplayText, "0 days")
    }

    // MARK: - Isolation Warning

    func testIsolationWarning_showsAfterThresholdDays() {
        viewModel.daysSinceLastCall = 4
        viewModel.isolationWarning = true

        XCTAssertTrue(viewModel.isolationWarning)
        XCTAssertTrue(viewModel.isolationWarningText.contains("4 days"))
    }

    func testIsolationWarning_notShownBelowThreshold() {
        viewModel.daysSinceLastCall = 1
        viewModel.isolationWarning = false

        XCTAssertFalse(viewModel.isolationWarning)
    }

    // MARK: - Post-Log Message Rotation

    func testPostLogMessage_rotatesEncouragingText() async throws {
        // Log multiple times and verify messages rotate.
        try await viewModel.quickLog()
        let firstMessage = viewModel.postLogMessage
        XCTAssertFalse(firstMessage.isEmpty, "Post-log message should not be empty")

        try await viewModel.quickLog()
        let secondMessage = viewModel.postLogMessage
        XCTAssertFalse(secondMessage.isEmpty, "Post-log message should not be empty")

        // After 4 logs, should cycle back to first message.
        try await viewModel.quickLog()
        try await viewModel.quickLog()
        let fifthMessage = viewModel.postLogMessage
        // Fifth message (index 4) wraps to index 0.
        XCTAssertEqual(fifthMessage, firstMessage,
                      "Messages should rotate through the list")
    }

    // MARK: - Today Status

    func testTodayStatus_noCallsMessage() {
        XCTAssertEqual(viewModel.todayStatusText, "No calls yet today")
    }

    func testTodayStatus_singularCall() async throws {
        try await viewModel.quickLog()
        XCTAssertEqual(viewModel.todayStatusText, "1 call today")
    }

    func testTodayStatus_pluralCalls() async throws {
        try await viewModel.quickLog()
        try await viewModel.quickLog()
        XCTAssertEqual(viewModel.todayStatusText, "2 calls today")
    }

    // MARK: - Expand Quick Log (AC-PC-21)

    func testExpandQuickLog_addsNameDurationNotes() async throws {
        try await viewModel.quickLog()
        guard let callId = viewModel.history.first?.id else {
            XCTFail("Expected entry in history")
            return
        }

        try await viewModel.expandQuickLog(
            callId: callId,
            contactName: "Mike S.",
            durationMinutes: 15,
            notes: "Great conversation"
        )

        guard let updated = viewModel.history.first(where: { $0.id == callId }) else {
            XCTFail("Expected to find updated entry")
            return
        }

        XCTAssertEqual(updated.contactName, "Mike S.")
        XCTAssertEqual(updated.durationMinutes, 15)
        XCTAssertEqual(updated.notes, "Great conversation")
    }

    func testExpandQuickLog_preservesTimestamp() async throws {
        try await viewModel.quickLog()
        guard let callId = viewModel.history.first?.id,
              let originalTimestamp = viewModel.history.first?.timestamp else {
            XCTFail("Expected entry in history")
            return
        }

        try await viewModel.expandQuickLog(
            callId: callId,
            contactName: "Mike S.",
            durationMinutes: nil,
            notes: nil
        )

        guard let updated = viewModel.history.first(where: { $0.id == callId }) else {
            XCTFail("Expected to find updated entry")
            return
        }

        XCTAssertEqual(updated.timestamp, originalTimestamp,
                      "Timestamp must be preserved (immutable, FR2.7)")
    }

    // MARK: - Direction and Contact Type Enums

    func testCallDirection_allCases() {
        XCTAssertEqual(CallDirection.allCases.count, 2)
        XCTAssertTrue(CallDirection.allCases.contains(.made))
        XCTAssertTrue(CallDirection.allCases.contains(.received))
    }

    func testRecoveryContactType_allCases() {
        XCTAssertEqual(RecoveryContactType.allCases.count, 6)
        XCTAssertEqual(RecoveryContactType.sponsor.rawValue, "sponsor")
        XCTAssertEqual(RecoveryContactType.accountabilityPartner.rawValue, "accountability-partner")
        XCTAssertEqual(RecoveryContactType.counselor.rawValue, "counselor")
        XCTAssertEqual(RecoveryContactType.coach.rawValue, "coach")
        XCTAssertEqual(RecoveryContactType.supportPerson.rawValue, "support-person")
        XCTAssertEqual(RecoveryContactType.custom.rawValue, "custom")
    }
}
