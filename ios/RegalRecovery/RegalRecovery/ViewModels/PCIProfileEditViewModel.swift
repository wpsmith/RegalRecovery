// ViewModels/PCIProfileEditViewModel.swift

import Foundation
import SwiftUI
import SwiftData

@Observable
class PCIProfileEditViewModel {

    // MARK: - State

    var dimensions: [PCIDimension] = []
    var criticalItems: [PCICriticalItem] = []
    var selectedCriticalIds: Set<UUID> = []
    var currentVersionNumber: Int = 0
    var profileId: UUID?
    var isLoading: Bool = true

    // MARK: - Computed Properties

    var canSelectMore: Bool {
        selectedCriticalIds.count < 7
    }

    var selectedCount: Int {
        selectedCriticalIds.count
    }

    var isSelectionComplete: Bool {
        selectedCriticalIds.count == 7
    }

    /// Flat list of all indicators across all dimensions for critical selection.
    var allIndicators: [(dimensionType: PCIDimensionType, indicator: PCIIndicator)] {
        var result: [(PCIDimensionType, PCIIndicator)] = []
        for dimension in dimensions {
            for indicator in dimension.indicators {
                result.append((dimension.dimensionType, indicator))
            }
        }
        return result
    }

    // MARK: - Load Profile

    /// Load the active profile's latest completed version (versionNumber > 0).
    func load(context: ModelContext, userId: UUID) {
        isLoading = true
        defer { isLoading = false }

        // Fetch active profile
        let uid = userId
        let profileDescriptor = FetchDescriptor<RRPCIProfile>(
            predicate: #Predicate { $0.userId == uid && $0.isActive == true }
        )
        guard let profile = try? context.fetch(profileDescriptor).first else {
            return
        }

        profileId = profile.id
        let pid = profile.id

        // Fetch latest completed version (versionNumber > 0)
        let versionDescriptor = FetchDescriptor<RRPCIProfileVersion>(
            predicate: #Predicate { $0.profileId == pid && $0.versionNumber > 0 },
            sortBy: [SortDescriptor(\.versionNumber, order: .reverse)]
        )
        guard let latestVersion = try? context.fetch(versionDescriptor).first else {
            return
        }

        currentVersionNumber = latestVersion.versionNumber
        dimensions = latestVersion.dimensions
        criticalItems = latestVersion.criticalItems

        // Populate selected critical IDs
        selectedCriticalIds = Set(criticalItems.map { $0.id })
    }

    // MARK: - Save Indicator Changes

    /// Save indicator edits as a new profile version with incremented version number.
    func saveIndicatorChanges(context: ModelContext, userId: UUID) {
        guard let profileId = profileId else { return }

        // Create new version with incremented number
        let newVersionNumber = currentVersionNumber + 1

        // Encode updated dimensions and current critical items
        let dimensionsData = try? JSONEncoder().encode(dimensions)
        let dimensionsJSON = dimensionsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let criticalItemsData = try? JSONEncoder().encode(criticalItems)
        let criticalItemsJSON = criticalItemsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        // Create new version
        let newVersion = RRPCIProfileVersion(
            profileId: profileId,
            versionNumber: newVersionNumber,
            dimensionsJSON: dimensionsJSON,
            criticalItemsJSON: criticalItemsJSON,
            effectiveFrom: Date(),
            createdAt: Date()
        )
        context.insert(newVersion)

        // Update current version number
        currentVersionNumber = newVersionNumber

        // Save context
        try? context.save()
    }

    // MARK: - Save Critical Changes

    /// Save critical item selection as a new profile version.
    func saveCriticalChanges(context: ModelContext, userId: UUID) {
        guard let profileId = profileId else { return }

        // Create new version with incremented number
        let newVersionNumber = currentVersionNumber + 1

        // Build new critical items from selected indicator IDs
        let newCriticalItems = buildCriticalItemsFromSelection()

        // Encode current dimensions and new critical items
        let dimensionsData = try? JSONEncoder().encode(dimensions)
        let dimensionsJSON = dimensionsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let criticalItemsData = try? JSONEncoder().encode(newCriticalItems)
        let criticalItemsJSON = criticalItemsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        // Create new version
        let newVersion = RRPCIProfileVersion(
            profileId: profileId,
            versionNumber: newVersionNumber,
            dimensionsJSON: dimensionsJSON,
            criticalItemsJSON: criticalItemsJSON,
            effectiveFrom: Date(),
            createdAt: Date()
        )
        context.insert(newVersion)

        // Update local state
        currentVersionNumber = newVersionNumber
        criticalItems = newCriticalItems

        // Save context
        try? context.save()
    }

    // MARK: - Indicator Management

    /// Add a new indicator to the specified dimension (max 5 per dimension).
    func addIndicator(to dimensionType: PCIDimensionType, text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Find or create dimension
        if let index = dimensions.firstIndex(where: { $0.dimensionType == dimensionType }) {
            guard dimensions[index].indicators.count < 5 else { return }

            let newIndicator = PCIIndicator(
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                isPositive: dimensionType.isPositiveCategory
            )
            dimensions[index].indicators.append(newIndicator)
        } else {
            // Create new dimension if it doesn't exist
            let newIndicator = PCIIndicator(
                text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                isPositive: dimensionType.isPositiveCategory
            )
            let newDimension = PCIDimension(
                dimensionType: dimensionType,
                indicators: [newIndicator]
            )
            dimensions.append(newDimension)
        }
    }

    /// Remove an indicator from the specified dimension.
    func removeIndicator(id: UUID, from dimensionType: PCIDimensionType) {
        guard let dimensionIndex = dimensions.firstIndex(where: { $0.dimensionType == dimensionType }) else {
            return
        }

        dimensions[dimensionIndex].indicators.removeAll { $0.id == id }

        // Also remove from critical selection if it was selected
        selectedCriticalIds.remove(id)
        criticalItems.removeAll { $0.id == id }
    }

    /// Update the text of an existing indicator.
    func updateIndicator(id: UUID, in dimensionType: PCIDimensionType, newText: String) {
        guard let dimensionIndex = dimensions.firstIndex(where: { $0.dimensionType == dimensionType }),
              let indicatorIndex = dimensions[dimensionIndex].indicators.firstIndex(where: { $0.id == id }) else {
            return
        }

        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        dimensions[dimensionIndex].indicators[indicatorIndex].text = trimmed

        // Update critical item display text if this indicator is critical
        if let criticalIndex = criticalItems.firstIndex(where: { $0.id == id }) {
            let isPositive = dimensionType.isPositiveCategory
            let displayText = isPositive ? "Lack of \(trimmed)" : trimmed
            criticalItems[criticalIndex].displayText = displayText
            criticalItems[criticalIndex].originalText = trimmed
        }
    }

    // MARK: - Critical Selection

    /// Toggle selection of a critical item (enforce max 7).
    func toggleCriticalSelection(indicatorId: UUID) {
        if selectedCriticalIds.contains(indicatorId) {
            selectedCriticalIds.remove(indicatorId)
        } else if canSelectMore {
            selectedCriticalIds.insert(indicatorId)
        }
    }

    // MARK: - Private Helpers

    /// Build critical items from current selection.
    private func buildCriticalItemsFromSelection() -> [PCICriticalItem] {
        var items: [PCICriticalItem] = []

        for (index, item) in allIndicators.enumerated() {
            guard selectedCriticalIds.contains(item.indicator.id) else { continue }

            let dimensionType = item.dimensionType
            let indicator = item.indicator
            let originalText = indicator.text

            // For Interests dimension (positive category), display as "Lack of [activity]"
            let displayText: String
            if dimensionType.isPositiveCategory {
                displayText = "Lack of \(originalText)"
            } else {
                displayText = originalText
            }

            let criticalItem = PCICriticalItem(
                id: indicator.id,
                dimensionType: dimensionType,
                displayText: displayText,
                originalText: originalText,
                sortOrder: index
            )

            items.append(criticalItem)
        }

        return items.sorted { $0.sortOrder < $1.sortOrder }
    }
}
