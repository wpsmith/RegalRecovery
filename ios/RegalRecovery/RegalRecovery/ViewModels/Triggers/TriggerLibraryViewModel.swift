import Foundation
import SwiftUI

@Observable
final class TriggerLibraryViewModel {

    // MARK: - Nested Types

    struct LibraryItem: Identifiable {
        let id: UUID
        let label: String
        let category: TriggerCategory
        let isCustom: Bool
        let useCount: Int
    }

    struct ValidationResult {
        let isValid: Bool
        let message: String?
    }

    // MARK: - State Properties

    var allTriggers: [LibraryItem] = []
    var myTriggerIds: Set<UUID> = []
    var favoriteTriggerIds: Set<UUID> = []
    var searchQuery: String = ""
    var selectedCategory: TriggerCategory?
    var collapsedCategories: Set<TriggerCategory> = []
    var isLoading = false
    var error: String?

    var newTriggerLabel: String = ""
    var newTriggerCategory: TriggerCategory = .emotional

    // MARK: - My Triggers

    var myTriggers: [LibraryItem] {
        let items = allTriggers.filter { myTriggerIds.contains($0.id) }
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            return items.filter { $0.label.lowercased().contains(query) }
        }
        return items.sorted { $0.useCount > $1.useCount }
    }

    var myTriggersGroupedByCategory: [(category: TriggerCategory, items: [LibraryItem])] {
        TriggerCategory.allCases.compactMap { category in
            let items = myTriggers.filter { $0.category == category }
            return items.isEmpty ? nil : (category: category, items: items)
        }
    }

    func isInMyTriggers(_ id: UUID) -> Bool {
        myTriggerIds.contains(id)
    }

    func addToMyTriggers(_ id: UUID) {
        myTriggerIds.insert(id)
    }

    func removeFromMyTriggers(_ id: UUID) {
        myTriggerIds.remove(id)
        favoriteTriggerIds.remove(id)
    }

    // MARK: - Favorites

    func isFavorite(_ id: UUID) -> Bool {
        favoriteTriggerIds.contains(id)
    }

    func canFavorite(_ id: UUID) -> Bool {
        if favoriteTriggerIds.contains(id) { return true }

        guard let item = allTriggers.first(where: { $0.id == id }) else { return false }

        if item.category == .threeIs {
            let currentThreeIsFavorites = favoriteTriggerIds.filter { favId in
                allTriggers.first(where: { $0.id == favId })?.category == .threeIs
            }
            return currentThreeIsFavorites.count < 2
        }

        return true
    }

    func toggleFavorite(_ id: UUID) {
        if favoriteTriggerIds.contains(id) {
            favoriteTriggerIds.remove(id)
        } else if canFavorite(id) {
            favoriteTriggerIds.insert(id)
            myTriggerIds.insert(id)
        }
    }

    // MARK: - All Triggers (full library)

    var filteredTriggers: [LibraryItem] {
        var results = allTriggers

        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            results = results.filter { $0.label.lowercased().contains(query) }
        }

        return results
    }

    var groupedByCategory: [(category: TriggerCategory, items: [LibraryItem])] {
        TriggerCategory.allCases.compactMap { category in
            let items = filteredTriggers.filter { $0.category == category }
            return items.isEmpty ? nil : (category: category, items: items)
        }
    }

    // MARK: - Custom Triggers

    var customTriggers: [LibraryItem] {
        allTriggers.filter { $0.isCustom }
    }

    // MARK: - Collapsible Sections

    func isCategoryCollapsed(_ category: TriggerCategory) -> Bool {
        collapsedCategories.contains(category)
    }

    func toggleCategoryCollapsed(_ category: TriggerCategory) {
        if collapsedCategories.contains(category) {
            collapsedCategories.remove(category)
        } else {
            collapsedCategories.insert(category)
        }
    }

    // MARK: - Validation

    func validateCustomTrigger(label: String, category: TriggerCategory) -> ValidationResult {
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLabel.isEmpty {
            return ValidationResult(isValid: false, message: "Please enter a trigger name.")
        }

        if trimmedLabel.count > 100 {
            return ValidationResult(isValid: false, message: "Trigger name must be 100 characters or less.")
        }

        let existingLabels = allTriggers.map { $0.label.lowercased() }
        if existingLabels.contains(trimmedLabel.lowercased()) {
            return ValidationResult(isValid: false, message: "A trigger with this name already exists.")
        }

        return ValidationResult(isValid: true, message: nil)
    }
}
