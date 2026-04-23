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
    var searchQuery: String = ""
    var selectedCategory: TriggerCategory?
    var isLoading = false
    var error: String?

    // Custom trigger creation
    var newTriggerLabel: String = ""
    var newTriggerCategory: TriggerCategory = .emotional

    // MARK: - Computed Properties

    var filteredTriggers: [LibraryItem] {
        var results = allTriggers

        // Filter by category if selected
        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        // Filter by search query if non-empty
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            results = results.filter { $0.label.lowercased().contains(query) }
        }

        return results
    }

    var groupedByCategory: [(category: TriggerCategory, items: [LibraryItem])] {
        var grouped: [(category: TriggerCategory, items: [LibraryItem])] = []

        for category in TriggerCategory.allCases {
            let items = filteredTriggers.filter { $0.category == category }
            if !items.isEmpty {
                grouped.append((category: category, items: items))
            }
        }

        return grouped
    }

    var customTriggers: [LibraryItem] {
        allTriggers.filter { $0.isCustom }
    }

    // MARK: - Methods

    func validateCustomTrigger(label: String, category: TriggerCategory) -> ValidationResult {
        // Empty/whitespace-only label
        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLabel.isEmpty {
            return ValidationResult(isValid: false, message: "Please enter a trigger name.")
        }

        // Label > 100 characters
        if trimmedLabel.count > 100 {
            return ValidationResult(isValid: false, message: "Trigger name must be 100 characters or less.")
        }

        // Duplicate label (case-insensitive match)
        let existingLabels = allTriggers.map { $0.label.lowercased() }
        if existingLabels.contains(trimmedLabel.lowercased()) {
            return ValidationResult(isValid: false, message: "A trigger with this name already exists.")
        }

        // Valid
        return ValidationResult(isValid: true, message: nil)
    }
}
