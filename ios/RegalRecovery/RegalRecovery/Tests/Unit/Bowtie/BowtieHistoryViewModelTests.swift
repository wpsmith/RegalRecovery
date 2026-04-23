import XCTest
import SwiftData
@testable import RegalRecovery

final class BowtieHistoryViewModelTests: XCTestCase {
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

    func testLoadSessions_ReturnsOnlyComplete() {
        let draft = RRBowtieSession()
        context.insert(draft)
        let complete = RRBowtieSession(status: .complete)
        complete.completedAt = Date()
        context.insert(complete)

        let vm = BowtieHistoryViewModel()
        vm.loadSessions(context: context)
        XCTAssertEqual(vm.completedSessions.count, 1)
    }

    func testAnticipatoryRatio_CalculatesCorrectly() {
        let session = RRBowtieSession(status: .complete, selectedRoleIds: [UUID()])
        session.completedAt = Date()
        context.insert(session)
        let roleId = UUID()
        let pastMarker = RRBowtieMarker(side: .past, timeIntervalHours: 6, roleId: roleId, iActivations: [IActivation(iType: .insignificance, intensity: 5)])
        pastMarker.session = session
        context.insert(pastMarker)
        let futureMarker1 = RRBowtieMarker(side: .future, timeIntervalHours: 6, roleId: roleId, iActivations: [IActivation(iType: .insignificance, intensity: 3)])
        futureMarker1.session = session
        context.insert(futureMarker1)
        let futureMarker2 = RRBowtieMarker(side: .future, timeIntervalHours: 12, roleId: roleId, iActivations: [IActivation(iType: .incompetence, intensity: 4)])
        futureMarker2.session = session
        context.insert(futureMarker2)

        let vm = BowtieHistoryViewModel()
        vm.loadSessions(context: context)
        // 2 future out of 3 total = 0.666...
        XCTAssertEqual(vm.anticipatoryRatio, 2.0 / 3.0, accuracy: 0.01)
    }

    func testTotalIDistribution_SumsAcrossSessions() {
        let session = RRBowtieSession(status: .complete, selectedRoleIds: [UUID()])
        session.pastInsignificanceTotal = 10
        session.pastIncompetenceTotal = 5
        session.futureInsignificanceTotal = 3
        session.completedAt = Date()
        context.insert(session)

        let vm = BowtieHistoryViewModel()
        vm.loadSessions(context: context)
        XCTAssertEqual(vm.totalIDistribution.insignificance, 13)
        XCTAssertEqual(vm.totalIDistribution.incompetence, 5)
        XCTAssertEqual(vm.totalIDistribution.dominant, .insignificance)
    }
}
