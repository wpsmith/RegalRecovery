import Foundation
import Observation
import SwiftData

@Observable
final class MotivationLibraryViewModel {

    // MARK: - State

    var motivations: [RRMotivation] = []
    var isLoading: Bool = false
    var error: String?

    // MARK: - Grouped Access

    struct CategoryGroup: Identifiable {
        let category: MotivationCategory
        let motivations: [RRMotivation]
        var id: String { category.rawValue }
    }

    var groupedByCategory: [CategoryGroup] {
        let active = motivations.filter { !$0.isArchived }
        let grouped = Dictionary(grouping: active) { $0.motivationCategory }
        return MotivationCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let sorted = items.sorted {
                if $0.importanceRating != $1.importanceRating {
                    return $0.importanceRating > $1.importanceRating
                }
                return $0.createdAt > $1.createdAt
            }
            return CategoryGroup(category: category, motivations: sorted)
        }
    }

    var totalCount: Int {
        motivations.filter { !$0.isArchived }.count
    }

    var isEmpty: Bool {
        motivations.filter { !$0.isArchived }.isEmpty
    }

    // MARK: - CRUD

    func addMotivation(
        text: String,
        category: MotivationCategory,
        importanceRating: Int,
        scriptureReference: String?,
        source: MotivationSource
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Motivation text cannot be empty"
            return
        }
        let clamped = max(1, min(5, importanceRating))
        let truncated = String(trimmed.prefix(MotivationLimits.maxTextLength))
        let scripture = scriptureReference?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanScripture = (scripture?.isEmpty ?? true) ? nil : scripture

        let motivation = RRMotivation(
            userId: UUID(),
            text: truncated,
            category: category,
            importanceRating: clamped,
            scriptureReference: cleanScripture,
            source: source
        )
        motivations.insert(motivation, at: 0)
        error = nil
    }

    func deleteMotivation(id: UUID) {
        motivations.removeAll { $0.id == id }
    }

    func updateMotivation(
        id: UUID,
        text: String,
        category: MotivationCategory,
        importanceRating: Int,
        scriptureReference: String?
    ) {
        guard let index = motivations.firstIndex(where: { $0.id == id }) else { return }
        let motivation = motivations[index]
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Motivation text cannot be empty"
            return
        }
        motivation.text = String(trimmed.prefix(MotivationLimits.maxTextLength))
        motivation.category = category.rawValue
        motivation.importanceRating = max(1, min(5, importanceRating))
        let scripture = scriptureReference?.trimmingCharacters(in: .whitespacesAndNewlines)
        motivation.scriptureReference = (scripture?.isEmpty ?? true) ? nil : scripture
        motivation.modifiedAt = Date()
        error = nil
    }

    // MARK: - Persistence

    func loadMotivations(context: ModelContext, userId: UUID) {
        isLoading = true
        let descriptor = FetchDescriptor<RRMotivation>(
            sortBy: [
                SortDescriptor(\.importanceRating, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        )
        do {
            motivations = try context.fetch(descriptor)
        } catch {
            self.error = "Failed to load motivations"
        }
        isLoading = false
    }

    func saveMotivation(_ motivation: RRMotivation, context: ModelContext) {
        context.insert(motivation)
        try? context.save()
    }

    func persistDelete(id: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.id == id }
        )
        if let motivation = try? context.fetch(descriptor).first {
            let motivationId = motivation.id
            let historyDescriptor = FetchDescriptor<RRMotivationHistory>(
                predicate: #Predicate { $0.motivationId == motivationId }
            )
            if let history = try? context.fetch(historyDescriptor) {
                for entry in history {
                    context.delete(entry)
                }
            }
            context.delete(motivation)
            try? context.save()
        }
    }

    func persistUpdate(_ motivation: RRMotivation, context: ModelContext) {
        try? context.save()
    }

    func recordHistory(
        motivationId: UUID,
        changeType: MotivationChangeType,
        previousValue: String?,
        newValue: String?,
        context: ModelContext
    ) {
        let history = RRMotivationHistory(
            motivationId: motivationId,
            changeType: changeType,
            previousValue: previousValue,
            newValue: newValue
        )
        context.insert(history)
        try? context.save()
    }
}
