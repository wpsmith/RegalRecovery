import XCTest
import SwiftData
@testable import RegalRecovery

final class BowtieSessionViewModelTests: XCTestCase {
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

    func testCreateSession_InsertsDraftSession() {
        let vm = BowtieSessionViewModel()
        vm.selectedRoleIds = [UUID()]
        vm.selectedVocabulary = .threeIs
        vm.createSession(context: context)

        let sessions = try! context.fetch(FetchDescriptor<RRBowtieSession>())
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].bowtieStatus, .draft)
        XCTAssertFalse(vm.showSetup)
        XCTAssertNotNil(vm.session)
    }

    func testAddMarker_UpdatesTallies() {
        let vm = BowtieSessionViewModel()
        vm.selectedRoleIds = [UUID()]
        vm.createSession(context: context)

        let marker = RRBowtieMarker(
            side: .past,
            timeIntervalHours: 6,
            roleId: UUID(),
            iActivations: [IActivation(iType: .insignificance, intensity: 7)]
        )
        vm.addMarker(marker, context: context)

        XCTAssertEqual(vm.markers.count, 1)
        XCTAssertEqual(vm.pastInsignificance, 7)
        XCTAssertEqual(vm.pastIncompetence, 0)
    }

    func testRemoveMarker_UpdatesTallies() {
        let vm = BowtieSessionViewModel()
        vm.selectedRoleIds = [UUID()]
        vm.createSession(context: context)

        let marker = RRBowtieMarker(
            side: .past,
            timeIntervalHours: 6,
            roleId: UUID(),
            iActivations: [IActivation(iType: .impotence, intensity: 4)]
        )
        vm.addMarker(marker, context: context)
        XCTAssertEqual(vm.pastImpotence, 4)

        vm.removeMarker(marker, context: context)
        XCTAssertEqual(vm.pastImpotence, 0)
        XCTAssertTrue(vm.markers.isEmpty)
    }

    func testCompleteSession_SetsStatusAndCreatesActivity() {
        let vm = BowtieSessionViewModel()
        vm.selectedRoleIds = [UUID()]
        vm.createSession(context: context)

        let marker = RRBowtieMarker(
            side: .past,
            timeIntervalHours: 12,
            roleId: UUID(),
            iActivations: [IActivation(iType: .incompetence, intensity: 3)]
        )
        vm.addMarker(marker, context: context)

        let userId = UUID()
        vm.completeSession(context: context, userId: userId)

        XCTAssertEqual(vm.session?.bowtieStatus, .complete)
        XCTAssertNotNil(vm.session?.completedAt)
        XCTAssertTrue(vm.showCompletion)

        let activities = try! context.fetch(FetchDescriptor<RRActivity>())
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities[0].activityType, "BOWTIE")
        XCTAssertEqual(activities[0].userId, userId)
    }

    func testRecalculateTallies_SumsCorrectly() {
        let vm = BowtieSessionViewModel()
        vm.selectedRoleIds = [UUID()]
        vm.createSession(context: context)

        let pastMarker = RRBowtieMarker(
            side: .past,
            timeIntervalHours: 6,
            roleId: UUID(),
            iActivations: [
                IActivation(iType: .insignificance, intensity: 3),
                IActivation(iType: .incompetence, intensity: 5)
            ]
        )
        vm.addMarker(pastMarker, context: context)

        let futureMarker = RRBowtieMarker(
            side: .future,
            timeIntervalHours: 12,
            roleId: UUID(),
            iActivations: [
                IActivation(iType: .insignificance, intensity: 2),
                IActivation(iType: .impotence, intensity: 8)
            ]
        )
        vm.addMarker(futureMarker, context: context)

        XCTAssertEqual(vm.pastInsignificance, 3)
        XCTAssertEqual(vm.pastIncompetence, 5)
        XCTAssertEqual(vm.pastImpotence, 0)
        XCTAssertEqual(vm.futureInsignificance, 2)
        XCTAssertEqual(vm.futureIncompetence, 0)
        XCTAssertEqual(vm.futureImpotence, 8)
    }
}
