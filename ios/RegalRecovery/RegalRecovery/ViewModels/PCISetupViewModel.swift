import Foundation
import SwiftUI
import SwiftData

// MARK: - Setup Step

enum PCISetupStep: Equatable {
    case psychoeducation
    case dimension(Int)
    case criticalSelection
    case confirmation
}

// MARK: - PCI Setup ViewModel

@Observable
class PCISetupViewModel {

    // MARK: - Flow State

    var currentStep: PCISetupStep = .psychoeducation

    // MARK: - Dimension Entry State

    /// Working copy of indicator texts entered for each dimension. Maps dimension type to array of indicator texts.
    var dimensionIndicators: [PCIDimensionType: [String]] = [:]

    /// Current dimension's text field values (1-5 fields). Updated as user types.
    var currentIndicatorTexts: [String] = [""]

    /// All built indicators from all dimensions, for display in critical selection.
    var allBuiltIndicators: [(dimensionType: PCIDimensionType, indicator: PCIIndicator)] = []

    // MARK: - Critical Selection State

    /// Selected critical item IDs (max 7).
    var selectedCriticalIds: Set<UUID> = []

    // MARK: - Computed Properties

    /// Current dimension index (0-9), extracted from step.
    var currentDimensionIndex: Int {
        if case .dimension(let index) = currentStep {
            return index
        }
        return 0
    }

    /// Current dimension type based on sorted order.
    var currentDimensionType: PCIDimensionType? {
        let sorted = PCIDimensionType.allCases.sorted { $0.sortOrder < $1.sortOrder }
        guard currentDimensionIndex < sorted.count else { return nil }
        return sorted[currentDimensionIndex]
    }

    /// Current dimension content for display.
    var currentDimensionContent: PCIDimensionContent? {
        guard let type = currentDimensionType else { return nil }
        return PCIDimensionContent.content(for: type)
    }

    /// Progress fraction (0.0 - 1.0) for dimension entry.
    var progressFraction: Double {
        Double(currentDimensionIndex) / 10.0
    }

    /// Progress label "X of 10".
    var progressLabel: String {
        "\(currentDimensionIndex + 1) of 10"
    }

    /// Can select more critical items.
    var canSelectMore: Bool {
        selectedCriticalIds.count < 7
    }

    /// Number of critical items selected.
    var selectedCount: Int {
        selectedCriticalIds.count
    }

    /// Selection is complete (exactly 7 items).
    var isSelectionComplete: Bool {
        selectedCriticalIds.count == 7
    }

    /// Is first dimension (index 0).
    var isFirstDimension: Bool {
        currentDimensionIndex == 0
    }

    /// Is last dimension (index 9).
    var isLastDimension: Bool {
        currentDimensionIndex == 9
    }

    // MARK: - Navigation

    /// Start the setup flow by advancing to the first dimension.
    func startSetup() {
        currentStep = .dimension(0)
        loadCurrentDimensionIndicators()
    }

    /// Move to the next dimension or critical selection.
    /// Caller is responsible for calling saveCurrentDimensionIndicators() first.
    func nextDimension() {
        if isLastDimension {
            // Build all indicators and advance to critical selection
            buildAllIndicators()
            currentStep = .criticalSelection
        } else {
            // Move to next dimension
            currentStep = .dimension(currentDimensionIndex + 1)
            loadCurrentDimensionIndicators()
        }
    }

    /// Move to the previous dimension.
    func previousDimension() {
        saveCurrentDimensionIndicators()

        if isFirstDimension {
            currentStep = .psychoeducation
        } else {
            currentStep = .dimension(currentDimensionIndex - 1)
            loadCurrentDimensionIndicators()
        }
    }

    /// Skip the current dimension without saving indicators.
    func skipDimension() {
        guard let dimensionType = currentDimensionType else { return }
        dimensionIndicators[dimensionType] = []
        nextDimension()
    }

    /// Advance to confirmation screen.
    func finishCriticalSelection() {
        currentStep = .confirmation
    }

    /// Go back to critical selection from confirmation.
    func backToCriticalSelection() {
        currentStep = .criticalSelection
    }

    // MARK: - Indicator Entry

    /// Add a new indicator text field (max 5).
    func addIndicatorField() {
        guard currentIndicatorTexts.count < 5 else { return }
        currentIndicatorTexts.append("")
    }

    /// Add an example behavior as an indicator (fills the first empty slot, or appends).
    func addExampleAsIndicator(_ text: String) {
        guard !currentIndicatorTexts.contains(text) else { return }
        if let emptyIndex = currentIndicatorTexts.firstIndex(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            currentIndicatorTexts[emptyIndex] = text
        } else if currentIndicatorTexts.count < 5 {
            currentIndicatorTexts.append(text)
        }
    }

    /// Remove an indicator text field at the given index (min 1).
    func removeIndicatorField(at index: Int) {
        guard currentIndicatorTexts.count > 1, index < currentIndicatorTexts.count else { return }
        currentIndicatorTexts.remove(at: index)
    }

    /// Load the current dimension's existing indicators into text fields.
    func loadCurrentDimensionIndicators() {
        guard let dimensionType = currentDimensionType else {
            currentIndicatorTexts = [""]
            return
        }

        let existing = dimensionIndicators[dimensionType] ?? []
        if existing.isEmpty {
            currentIndicatorTexts = [""]
        } else {
            currentIndicatorTexts = existing
        }
    }

    /// Save the current dimension's indicator texts (trim, filter empty).
    func saveCurrentDimensionIndicators() {
        guard let dimensionType = currentDimensionType else { return }

        let trimmed = currentIndicatorTexts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        dimensionIndicators[dimensionType] = trimmed
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

    /// Build all indicators from all dimensions into flat list for critical selection.
    private func buildAllIndicators() {
        allBuiltIndicators = []

        let sortedTypes = PCIDimensionType.allCases.sorted { $0.sortOrder < $1.sortOrder }

        for dimensionType in sortedTypes {
            let texts = dimensionIndicators[dimensionType] ?? []
            for text in texts {
                let indicator = PCIIndicator(
                    text: text,
                    isPositive: dimensionType.isPositiveCategory
                )
                allBuiltIndicators.append((dimensionType: dimensionType, indicator: indicator))
            }
        }
    }

    // MARK: - Build Final Data

    /// Build final dimensions array for profile version.
    func buildDimensions() -> [PCIDimension] {
        let sortedTypes = PCIDimensionType.allCases.sorted { $0.sortOrder < $1.sortOrder }

        return sortedTypes.compactMap { dimensionType in
            let texts = dimensionIndicators[dimensionType] ?? []
            guard !texts.isEmpty else { return nil }

            let indicators = texts.map { text in
                PCIIndicator(text: text, isPositive: dimensionType.isPositiveCategory)
            }

            return PCIDimension(dimensionType: dimensionType, indicators: indicators)
        }
    }

    /// Build final critical items array from selected indicator IDs.
    func buildCriticalItems() -> [PCICriticalItem] {
        var criticalItems: [PCICriticalItem] = []

        for (index, selected) in allBuiltIndicators.enumerated() {
            guard selectedCriticalIds.contains(selected.indicator.id) else { continue }

            let dimensionType = selected.dimensionType
            let indicator = selected.indicator
            let originalText = indicator.text

            // For Interests dimension, display as "Lack of [activity]"
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

            criticalItems.append(criticalItem)
        }

        return criticalItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Persistence

    /// Save completed setup as version 1.
    func save(context: ModelContext, userId: UUID) {
        // Build final data
        let dimensions = buildDimensions()
        let criticalItems = buildCriticalItems()

        // Find or create profile
        let profileDescriptor = FetchDescriptor<RRPCIProfile>(
            predicate: #Predicate { $0.userId == userId }
        )
        let existingProfile = try? context.fetch(profileDescriptor).first

        let profile: RRPCIProfile
        if let existing = existingProfile {
            profile = existing
        } else {
            profile = RRPCIProfile(userId: userId, isActive: true)
            context.insert(profile)
        }

        // Encode dimensions and critical items as JSON
        let dimensionsData = try? JSONEncoder().encode(dimensions)
        let dimensionsJSON = dimensionsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let criticalItemsData = try? JSONEncoder().encode(criticalItems)
        let criticalItemsJSON = criticalItemsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        // Create version 1 (completed setup)
        let version = RRPCIProfileVersion(
            profileId: profile.id,
            versionNumber: 1,
            dimensionsJSON: dimensionsJSON,
            criticalItemsJSON: criticalItemsJSON,
            effectiveFrom: Date(),
            createdAt: Date()
        )
        context.insert(version)

        // Mark any draft version (version 0) as obsolete by deleting it
        let profileId = profile.id
        let draftDescriptor = FetchDescriptor<RRPCIProfileVersion>(
            predicate: #Predicate<RRPCIProfileVersion> { version in
                version.profileId == profileId && version.versionNumber == 0
            }
        )
        if let draftVersion = try? context.fetch(draftDescriptor).first {
            context.delete(draftVersion)
        }

        // Save context
        try? context.save()
    }

    /// Save partial progress as version 0 (draft).
    func saveDraftProgress(context: ModelContext, userId: UUID) {
        // Build current progress
        let dimensions = buildDimensions()
        let criticalItems: [PCICriticalItem] = [] // Draft doesn't include critical items yet

        // Find or create profile
        let profileDescriptor = FetchDescriptor<RRPCIProfile>(
            predicate: #Predicate { $0.userId == userId }
        )
        let existingProfile = try? context.fetch(profileDescriptor).first

        let profile: RRPCIProfile
        if let existing = existingProfile {
            profile = existing
        } else {
            profile = RRPCIProfile(userId: userId, isActive: true)
            context.insert(profile)
        }

        // Encode dimensions as JSON
        let dimensionsData = try? JSONEncoder().encode(dimensions)
        let dimensionsJSON = dimensionsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let criticalItemsData = try? JSONEncoder().encode(criticalItems)
        let criticalItemsJSON = criticalItemsData.flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        // Find existing draft version or create new
        let profileId = profile.id
        let draftDescriptor = FetchDescriptor<RRPCIProfileVersion>(
            predicate: #Predicate<RRPCIProfileVersion> { version in
                version.profileId == profileId && version.versionNumber == 0
            }
        )
        if let existingDraft = try? context.fetch(draftDescriptor).first {
            // Update existing draft
            existingDraft.dimensionsJSON = dimensionsJSON
            existingDraft.criticalItemsJSON = criticalItemsJSON
        } else {
            // Create new draft version
            let draftVersion = RRPCIProfileVersion(
                profileId: profile.id,
                versionNumber: 0,
                dimensionsJSON: dimensionsJSON,
                criticalItemsJSON: criticalItemsJSON,
                effectiveFrom: Date(),
                createdAt: Date()
            )
            context.insert(draftVersion)
        }

        // Save context
        try? context.save()
    }

    /// Load existing progress from draft version 0, or skip to check-in if completed version exists.
    /// Returns true if should continue setup, false if should skip to check-in.
    func loadExistingProgress(context: ModelContext, userId: UUID) -> Bool {
        // Check for existing profile
        let profileDescriptor = FetchDescriptor<RRPCIProfile>(
            predicate: #Predicate { $0.userId == userId }
        )
        guard let profile = try? context.fetch(profileDescriptor).first else {
            return true // No profile, continue setup
        }

        // Check for completed version (versionNumber > 0)
        let profileId = profile.id
        let completedDescriptor = FetchDescriptor<RRPCIProfileVersion>(
            predicate: #Predicate<RRPCIProfileVersion> { version in
                version.profileId == profileId && version.versionNumber > 0
            }
        )
        if let _ = try? context.fetch(completedDescriptor).first {
            // Profile already completed, skip setup
            return false
        }

        // Check for draft version (versionNumber == 0)
        let draftDescriptor = FetchDescriptor<RRPCIProfileVersion>(
            predicate: #Predicate<RRPCIProfileVersion> { version in
                version.profileId == profileId && version.versionNumber == 0
            }
        )
        guard let draftVersion = try? context.fetch(draftDescriptor).first else {
            return true // No draft, continue fresh setup
        }

        // Load draft dimensions into working state
        let dimensions = draftVersion.dimensions
        dimensionIndicators = [:]
        for dimension in dimensions {
            let texts = dimension.indicators.map { $0.text }
            dimensionIndicators[dimension.dimensionType] = texts
        }

        // Find the first incomplete dimension to resume from
        let sortedTypes = PCIDimensionType.allCases.sorted { $0.sortOrder < $1.sortOrder }
        if let firstIncompleteIndex = sortedTypes.firstIndex(where: { dimensionIndicators[$0] == nil || dimensionIndicators[$0]!.isEmpty }) {
            currentStep = .dimension(firstIncompleteIndex)
        } else {
            // All dimensions have data, resume at last dimension
            currentStep = .dimension(9)
        }

        loadCurrentDimensionIndicators()
        return true
    }

    /// Check if user has completed setup (version > 0 exists).
    func hasCompletedSetup(context: ModelContext, userId: UUID) -> Bool {
        let profileDescriptor = FetchDescriptor<RRPCIProfile>(
            predicate: #Predicate { $0.userId == userId }
        )
        guard let profile = try? context.fetch(profileDescriptor).first else {
            return false
        }

        let profileId = profile.id
        let completedDescriptor = FetchDescriptor<RRPCIProfileVersion>(
            predicate: #Predicate<RRPCIProfileVersion> { version in
                version.profileId == profileId && version.versionNumber > 0
            }
        )
        return (try? context.fetch(completedDescriptor).first) != nil
    }
}
