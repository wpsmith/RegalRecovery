import XCTest
@testable import RegalRecovery

/// Unit tests for the Acting-In Behaviors ViewModel.
///
/// Test naming convention: test<Component>_<AC_ID>_<Scenario>
final class ActingInViewModelTests: XCTestCase {

    // MARK: - AC-AIB-012: Displays All Enabled Behaviors

    /// AC-AIB-012: Check-in behavior list matches enabled behaviors from config.
    func testBehaviorChecklist_AC_AIB_012_displaysAllEnabledBehaviors() {
        let vm = ActingInCheckInViewModel()
        // Simulate loading 15 default behaviors.
        vm.behaviorDrafts = ActingInDefaults.behaviors.enumerated().map { index, def in
            ActingInBehaviorDraft(
                behaviorId: def.id,
                behaviorName: def.name
            )
        }
        XCTAssertEqual(vm.behaviorDrafts.count, 15, "Should display all 15 default behaviors")
    }

    // MARK: - AC-AIB-016: Zero Behaviors Shows Celebration

    /// AC-AIB-016: Zero-behavior check-in shows celebration message.
    func testCheckIn_AC_AIB_016_zeroBehaviors_showsCelebration() {
        let message = ActingInMessages.messageForCheckIn(behaviorCount: 0, streakCount: 5)
        XCTAssertEqual(message, ActingInMessages.zeroBehaviors,
                       "Zero behaviors should show celebration message")
    }

    // MARK: - AC-AIB-014: Context Note Character Limit

    /// AC-AIB-014: Context note enforces 500-char max.
    func testContextNote_AC_AIB_014_enforcesCharLimit() {
        let vm = ActingInCheckInViewModel()
        vm.behaviorDrafts = [
            ActingInBehaviorDraft(
                behaviorId: "beh_default_blame",
                behaviorName: "Blame",
                isChecked: true,
                contextNote: String(repeating: "x", count: 600)
            )
        ]

        vm.enforceContextNoteLimit(for: "beh_default_blame")

        XCTAssertEqual(vm.behaviorDrafts[0].contextNote.count, 500,
                       "Context note should be truncated to 500 characters")
    }

    // MARK: - AC-AIB-015: Compassionate Messages

    /// AC-AIB-015: Post-check-in message matches rotating compassionate messages.
    func testCheckIn_AC_AIB_015_compassionateMessage() {
        let message = ActingInMessages.messageForCheckIn(behaviorCount: 2, streakCount: 0)
        XCTAssertTrue(ActingInMessages.rotatingMessages.contains(message),
                      "Message should be one of the rotating messages")
    }

    // MARK: - AC-AIB-071: Rotating Messages

    /// AC-AIB-071: Messages rotate among the 3 defined messages.
    func testCheckIn_AC_AIB_071_rotatingMessages() {
        var seen = Set<String>()
        for i in 0..<ActingInMessages.rotatingMessages.count {
            let message = ActingInMessages.messageForCheckIn(behaviorCount: 1, streakCount: i)
            seen.insert(message)
        }
        XCTAssertEqual(seen.count, ActingInMessages.rotatingMessages.count,
                       "All rotating messages should appear with different streak counts")
    }

    // MARK: - Toggle Behavior

    /// Verifies that toggling a behavior updates its checked state.
    func testToggleBehavior_updatesCheckedState() {
        let vm = ActingInCheckInViewModel()
        vm.behaviorDrafts = [
            ActingInBehaviorDraft(behaviorId: "beh_default_blame", behaviorName: "Blame"),
        ]

        XCTAssertFalse(vm.behaviorDrafts[0].isChecked)
        vm.toggleBehavior("beh_default_blame")
        XCTAssertTrue(vm.behaviorDrafts[0].isChecked)
        vm.toggleBehavior("beh_default_blame")
        XCTAssertFalse(vm.behaviorDrafts[0].isChecked)
    }

    // MARK: - Checked Count

    /// Verifies that checkedCount returns the correct number of checked behaviors.
    func testCheckedCount_returnsCorrectCount() {
        let vm = ActingInCheckInViewModel()
        vm.behaviorDrafts = [
            ActingInBehaviorDraft(behaviorId: "a", behaviorName: "A", isChecked: true),
            ActingInBehaviorDraft(behaviorId: "b", behaviorName: "B", isChecked: false),
            ActingInBehaviorDraft(behaviorId: "c", behaviorName: "C", isChecked: true),
        ]

        XCTAssertEqual(vm.checkedCount, 2)
    }

    // MARK: - Can Always Submit

    /// Verifies that submit is always possible (zero behaviors is valid).
    func testCanSubmit_alwaysTrue() {
        let vm = ActingInCheckInViewModel()
        XCTAssertTrue(vm.canSubmit, "Should always be able to submit (zero behaviors is valid)")
    }

    // MARK: - First Use Helper Text

    /// AC-AIB-070: First-use helper text is present and non-empty.
    func testFirstUseHelperText_AC_AIB_070_isNonEmpty() {
        XCTAssertFalse(ActingInMessages.firstUseHelper.isEmpty,
                       "First-use helper text should be non-empty")
        XCTAssertTrue(ActingInMessages.firstUseHelper.contains("acting-in behaviors"),
                      "First-use text should mention acting-in behaviors")
    }

    // MARK: - Counter Display Logic

    /// Verifies counter shows near the limit.
    func testShouldShowCounter_nearLimit() {
        let vm = ActingInCheckInViewModel()
        XCTAssertFalse(vm.shouldShowCounter("short text"))
        XCTAssertTrue(vm.shouldShowCounter(String(repeating: "x", count: 460)))
    }
}
