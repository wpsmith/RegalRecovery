import Foundation
import SwiftData

@Observable
class RolesManagerViewModel {
    var activeRoles: [RRUserRole] = []
    var archivedRoles: [RRUserRole] = []

    func loadRoles(context: ModelContext) {
        let descriptor = FetchDescriptor<RRUserRole>(sortBy: [SortDescriptor(\.sortOrder)])
        let all = (try? context.fetch(descriptor)) ?? []
        activeRoles = all.filter { !$0.isArchived }
        archivedRoles = all.filter { $0.isArchived }
    }

    func addRole(label: String, context: ModelContext) {
        let nextOrder = (activeRoles.last?.sortOrder ?? -1) + 1
        let role = RRUserRole(label: label, sortOrder: nextOrder)
        context.insert(role)
        loadRoles(context: context)
    }

    func addSubRole(label: String, parentId: UUID, context: ModelContext) {
        let nextOrder = (activeRoles.last?.sortOrder ?? -1) + 1
        let role = RRUserRole(label: label, sortOrder: nextOrder, parentRoleId: parentId)
        context.insert(role)
        loadRoles(context: context)
    }

    func archiveRole(_ role: RRUserRole, context: ModelContext) {
        role.isArchived = true
        loadRoles(context: context)
    }

    func unarchiveRole(_ role: RRUserRole, context: ModelContext) {
        role.isArchived = false
        role.sortOrder = (activeRoles.last?.sortOrder ?? -1) + 1
        loadRoles(context: context)
    }

    func deleteRole(_ role: RRUserRole, context: ModelContext) {
        context.delete(role)
        loadRoles(context: context)
    }

    func updateLabel(_ role: RRUserRole, newLabel: String, context: ModelContext) {
        role.label = newLabel
        loadRoles(context: context)
    }

    func reorderRoles(_ roles: [RRUserRole], context: ModelContext) {
        for (index, role) in roles.enumerated() {
            role.sortOrder = index
        }
        loadRoles(context: context)
    }

    func subRoles(of parentId: UUID) -> [RRUserRole] {
        activeRoles.filter { $0.parentRoleId == parentId }
    }
}
