import XCTest
import SwiftData
@testable import RegalRecovery

final class RolesManagerViewModelTests: XCTestCase {
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

    func testAddRole_InsertsRoleWithCorrectLabel() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Husband", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())
        XCTAssertEqual(roles.count, 1)
        XCTAssertEqual(roles[0].label, "Husband")
        XCTAssertFalse(roles[0].isArchived)
    }

    func testAddSubRole_SetsParentRoleId() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Father", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())
        let parentId = roles[0].id
        vm.addSubRole(label: "Father — Oldest", parentId: parentId, context: context)
        let allRoles = try! context.fetch(FetchDescriptor<RRUserRole>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(allRoles.count, 2)
        XCTAssertEqual(allRoles[1].parentRoleId, parentId)
    }

    func testArchiveRole_SetsIsArchived() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Coworker", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())
        vm.archiveRole(roles[0], context: context)
        let updated = try! context.fetch(FetchDescriptor<RRUserRole>())
        XCTAssertTrue(updated[0].isArchived)
    }

    func testActiveRoles_ExcludesArchived() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Active", context: context)
        vm.addRole(label: "Archived", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>(sortBy: [SortDescriptor(\.sortOrder)]))
        vm.archiveRole(roles[1], context: context)
        vm.loadRoles(context: context)
        XCTAssertEqual(vm.activeRoles.count, 1)
        XCTAssertEqual(vm.activeRoles[0].label, "Active")
    }

    func testDeleteRole_RemovesFromStore() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Temp", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())
        vm.deleteRole(roles[0], context: context)
        let remaining = try! context.fetch(FetchDescriptor<RRUserRole>())
        XCTAssertTrue(remaining.isEmpty)
    }

    func testReorderRoles_UpdatesSortOrder() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "A", context: context)
        vm.addRole(label: "B", context: context)
        vm.addRole(label: "C", context: context)
        vm.loadRoles(context: context)
        let reordered = [vm.activeRoles[2], vm.activeRoles[0], vm.activeRoles[1]]
        vm.reorderRoles(reordered, context: context)
        XCTAssertEqual(vm.activeRoles[0].label, "C")
        XCTAssertEqual(vm.activeRoles[1].label, "A")
        XCTAssertEqual(vm.activeRoles[2].label, "B")
    }
}
