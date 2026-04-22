import SwiftUI
import SwiftData

// MARK: - Quick Action Item State

struct QuickActionItemState: Identifiable, Equatable {
    let id: UUID
    let definition: QuickActionDefinition
    var sortOrder: Int

    static func == (lhs: QuickActionItemState, rhs: QuickActionItemState) -> Bool {
        lhs.id == rhs.id && lhs.definition.id == rhs.definition.id && lhs.sortOrder == rhs.sortOrder
    }
}

// MARK: - View Model

@Observable
class QuickActionsViewModel {
    var items: [QuickActionItemState] = []
    var hasUnsavedChanges = false
    var isSaving = false
    var saveError: String?
    var didSave = false
    private var originalSnapshot: [QuickActionItemState] = []

    var availableActions: [QuickActionDefinition] {
        let currentIds = Set(items.map(\.definition.id))
        return QuickActionDefinition.enabled.filter { !currentIds.contains($0.id) }
    }

    var canAddMore: Bool { items.count < 10 }
    var canRemove: Bool { items.count > 1 }

    private func markChanged() { hasUnsavedChanges = true }

    func checkForChanges() {
        hasUnsavedChanges = items != originalSnapshot
    }

    // MARK: - Load

    func load(context: ModelContext) {
        let descriptor = FetchDescriptor<RRQuickActionItem>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let saved = (try? context.fetch(descriptor)) ?? []

        if saved.isEmpty {
            items = QuickActionDefinition.defaults.enumerated().map { index, def in
                QuickActionItemState(id: UUID(), definition: def, sortOrder: index)
            }
        } else {
            items = saved.compactMap { item in
                guard let def = QuickActionDefinition.find(item.activityType),
                      FeatureFlagStore.shared.isEnabled(def.featureFlagKey) else { return nil }
                return QuickActionItemState(id: item.id, definition: def, sortOrder: item.sortOrder)
            }
            if items.isEmpty {
                items = QuickActionDefinition.defaults.enumerated().map { index, def in
                    QuickActionItemState(id: UUID(), definition: def, sortOrder: index)
                }
            }
        }

        originalSnapshot = items
        hasUnsavedChanges = false
    }

    // MARK: - Add / Remove / Move

    func addAction(_ definition: QuickActionDefinition) {
        guard canAddMore else { return }
        let newItem = QuickActionItemState(
            id: UUID(),
            definition: definition,
            sortOrder: items.count
        )
        items.append(newItem)
        markChanged()
    }

    func removeAction(at offsets: IndexSet) {
        guard items.count - offsets.count >= 1 else { return }
        items.remove(atOffsets: offsets)
        markChanged()
    }

    func moveAction(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        markChanged()
    }

    func resetToDefaults() {
        items = QuickActionDefinition.defaults.enumerated().map { index, def in
            QuickActionItemState(id: UUID(), definition: def, sortOrder: index)
        }
        markChanged()
    }

    // MARK: - Save

    func save(context: ModelContext) {
        isSaving = true
        saveError = nil

        do {
            let descriptor = FetchDescriptor<RRQuickActionItem>()
            let existing = (try? context.fetch(descriptor)) ?? []
            for item in existing { context.delete(item) }

            for (index, item) in items.enumerated() {
                let record = RRQuickActionItem(
                    activityType: item.definition.id,
                    sortOrder: index
                )
                context.insert(record)
            }

            try context.save()
            originalSnapshot = items
            hasUnsavedChanges = false
            didSave = true
        } catch {
            saveError = "Failed to save quick actions. Please try again."
        }

        isSaving = false
    }
}
