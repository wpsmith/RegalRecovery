import XCTest
@testable import RegalRecovery

final class BowtieMarkerViewModelTests: XCTestCase {

    func testCanSave_RequiresRoleAndActivation() {
        let vm = BowtieMarkerViewModel()

        // No role, no activations
        XCTAssertFalse(vm.canSave)

        // Role set, no activations
        vm.selectedRoleId = UUID()
        XCTAssertFalse(vm.canSave)

        // Role set, with I activation
        vm.toggleIActivation(.insignificance)
        XCTAssertTrue(vm.canSave)

        // Remove I activation, add big ticket
        vm.toggleIActivation(.insignificance)
        XCTAssertFalse(vm.canSave)

        vm.toggleBigTicket(.abandonment)
        XCTAssertTrue(vm.canSave)

        // Remove big ticket, add custom emotion
        vm.toggleBigTicket(.abandonment)
        XCTAssertFalse(vm.canSave)

        vm.customEmotions = ["anxiety"]
        XCTAssertTrue(vm.canSave)
    }

    func testToggleIActivation_AddsAndRemoves() {
        let vm = BowtieMarkerViewModel()

        // Add
        vm.toggleIActivation(.incompetence)
        XCTAssertEqual(vm.iActivations.count, 1)
        XCTAssertEqual(vm.iActivations[0].iType, .incompetence)
        XCTAssertEqual(vm.iActivations[0].intensity, 5) // default intensity

        // Add another
        vm.toggleIActivation(.impotence)
        XCTAssertEqual(vm.iActivations.count, 2)

        // Remove first
        vm.toggleIActivation(.incompetence)
        XCTAssertEqual(vm.iActivations.count, 1)
        XCTAssertEqual(vm.iActivations[0].iType, .impotence)
    }

    func testBuildMarker_ClampsDescription() {
        let vm = BowtieMarkerViewModel()
        vm.selectedRoleId = UUID()
        vm.toggleIActivation(.insignificance)
        vm.briefDescription = String(repeating: "a", count: 300)

        let marker = vm.buildMarker()
        XCTAssertEqual(marker.briefDescription?.count, BowtieMarkerViewModel.maxDescriptionLength)
    }

    func testLoadFromMarker_PopulatesFields() {
        let roleId = UUID()
        let triggerId = UUID()
        let marker = RRBowtieMarker(
            side: .future,
            timeIntervalHours: 24,
            roleId: roleId,
            iActivations: [IActivation(iType: .impotence, intensity: 8)],
            bigTicketEmotions: [BigTicketActivation(emotion: .loneliness, intensity: 6)],
            customEmotions: ["stress"],
            knownTriggerIds: [triggerId],
            briefDescription: "test description"
        )

        let vm = BowtieMarkerViewModel()
        vm.loadFromMarker(marker)

        XCTAssertEqual(vm.selectedSide, .future)
        XCTAssertEqual(vm.selectedTimeInterval, 24)
        XCTAssertEqual(vm.selectedRoleId, roleId)
        XCTAssertEqual(vm.iActivations.count, 1)
        XCTAssertEqual(vm.iActivations[0].iType, .impotence)
        XCTAssertEqual(vm.iActivations[0].intensity, 8)
        XCTAssertEqual(vm.bigTicketEmotions.count, 1)
        XCTAssertEqual(vm.bigTicketEmotions[0].emotion, .loneliness)
        XCTAssertEqual(vm.customEmotions, ["stress"])
        XCTAssertTrue(vm.selectedTriggerIds.contains(triggerId))
        XCTAssertEqual(vm.briefDescription, "test description")
    }
}
