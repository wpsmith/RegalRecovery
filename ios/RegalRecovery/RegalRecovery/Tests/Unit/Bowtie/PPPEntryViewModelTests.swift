import XCTest
import SwiftData
@testable import RegalRecovery

final class PPPEntryViewModelTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        super.setUp()
        container = try! RRModelConfiguration.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testCanSave_RequiresAtLeastOneField() {
        let vm = PPPEntryViewModel()
        XCTAssertFalse(vm.canSave)
        vm.prayer = "Pray for peace"
        XCTAssertTrue(vm.canSave)
    }

    func testCanSave_WhitespaceOnlyDoesNotCount() {
        let vm = PPPEntryViewModel()
        vm.prayer = "   "
        XCTAssertFalse(vm.canSave)

        vm.planBefore = " \n "
        XCTAssertFalse(vm.canSave)

        vm.planDuring = "Stay calm"
        XCTAssertTrue(vm.canSave)
    }

    func testCanSave_ContactIdsAloneSuffice() {
        let vm = PPPEntryViewModel()
        XCTAssertFalse(vm.canSave)
        vm.selectedContactIds.insert(UUID())
        XCTAssertTrue(vm.canSave)
    }

    func testSave_CreatesPPPEntry() {
        let session = RRBowtieSession(selectedRoleIds: [UUID()])
        context.insert(session)
        let marker = RRBowtieMarker(side: .future, timeIntervalHours: 12, roleId: UUID())
        marker.session = session
        context.insert(marker)

        let vm = PPPEntryViewModel()
        vm.prayer = "Pray for peace"
        vm.planBefore = "Arrive early"
        vm.save(marker: marker, context: context)

        XCTAssertNotNil(marker.pppEntry)
        XCTAssertEqual(marker.pppEntry?.prayer, "Pray for peace")
        XCTAssertEqual(marker.pppEntry?.planBefore, "Arrive early")
    }

    func testSave_WithReminder_SetsReminderTime() {
        let session = RRBowtieSession(selectedRoleIds: [UUID()])
        context.insert(session)
        let marker = RRBowtieMarker(side: .future, timeIntervalHours: 12, roleId: UUID())
        marker.session = session
        context.insert(marker)

        let vm = PPPEntryViewModel()
        vm.prayer = "Pray"
        vm.reminderEnabled = true
        vm.reminderMinutesBefore = 60
        vm.save(marker: marker, context: context)

        XCTAssertNotNil(marker.pppEntry?.reminderTime)
    }

    func testSave_WithoutReminder_NoReminderTime() {
        let session = RRBowtieSession(selectedRoleIds: [UUID()])
        context.insert(session)
        let marker = RRBowtieMarker(side: .future, timeIntervalHours: 12, roleId: UUID())
        marker.session = session
        context.insert(marker)

        let vm = PPPEntryViewModel()
        vm.prayer = "Pray"
        vm.reminderEnabled = false
        vm.save(marker: marker, context: context)

        XCTAssertNil(marker.pppEntry?.reminderTime)
    }

    func testRecordFollowUp_SetsOutcome() {
        let entry = RRPPPEntry(prayer: "Test")
        let vm = PPPEntryViewModel()
        vm.recordFollowUp(entry: entry, outcome: .better, reflection: "It went well")
        XCTAssertEqual(entry.outcome, .better)
        XCTAssertEqual(entry.followUpReflection, "It went well")
    }

    func testRecordFollowUp_EmptyReflectionBecomesNil() {
        let entry = RRPPPEntry(prayer: "Test")
        let vm = PPPEntryViewModel()
        vm.recordFollowUp(entry: entry, outcome: .harder, reflection: "")
        XCTAssertEqual(entry.outcome, .harder)
        XCTAssertNil(entry.followUpReflection)
    }

    func testLoadFromExisting_PopulatesAllFields() {
        let contactId = UUID()
        let entry = RRPPPEntry(
            prayer: "My prayer",
            peopleContactIds: [contactId],
            planBefore: "Plan before",
            planDuring: "Plan during",
            planAfter: "Plan after",
            reminderTime: Date()
        )
        entry.outcome = .expected
        entry.followUpReflection = "Reflection text"

        let vm = PPPEntryViewModel()
        vm.loadFromExisting(entry)

        XCTAssertEqual(vm.prayer, "My prayer")
        XCTAssertTrue(vm.selectedContactIds.contains(contactId))
        XCTAssertEqual(vm.planBefore, "Plan before")
        XCTAssertEqual(vm.planDuring, "Plan during")
        XCTAssertEqual(vm.planAfter, "Plan after")
        XCTAssertTrue(vm.reminderEnabled)
        XCTAssertEqual(vm.followUpOutcome, .expected)
        XCTAssertEqual(vm.followUpReflection, "Reflection text")
    }

    func testLoadFromExisting_NilFieldsDefaultToEmpty() {
        let entry = RRPPPEntry()

        let vm = PPPEntryViewModel()
        vm.loadFromExisting(entry)

        XCTAssertEqual(vm.prayer, "")
        XCTAssertTrue(vm.selectedContactIds.isEmpty)
        XCTAssertEqual(vm.planBefore, "")
        XCTAssertEqual(vm.planDuring, "")
        XCTAssertEqual(vm.planAfter, "")
        XCTAssertFalse(vm.reminderEnabled)
        XCTAssertNil(vm.followUpOutcome)
        XCTAssertEqual(vm.followUpReflection, "")
    }
}
