import SwiftUI

@Observable
class FASTERScaleViewModel {
    var selectedStage: FASTERStage = .forgettingPriorities
    var history: [FASTEREntry] = []
    var isLoading = false
    var error: String?

    // MARK: - Loading

    func load() async {
        isLoading = true
        error = nil

        do {
            // TODO: Replace MockData fallback with real repository calls
            try await loadFromMockData()
        } catch {
            self.error = "Unable to load FASTER Scale data. Please try again."
        }

        isLoading = false
    }

    // MARK: - Actions

    func submit(stage: FASTERStage) async throws {
        // TODO: Persist to repository
        let entry = FASTEREntry(date: Date(), stage: stage)
        history.insert(entry, at: 0)
        selectedStage = stage
    }

    // MARK: - Computed

    /// The most recent stage logged, or nil if no history
    var currentStage: FASTERStage? {
        history.first?.stage
    }

    /// Human-readable summary of the current FASTER state
    var statusLabel: String {
        guard let stage = currentStage else { return "Not assessed" }
        return stage.name
    }

    /// Color zone: "Green", "Yellow", or "Red"
    var zoneLabel: String {
        guard let stage = currentStage else { return "Green" }
        switch stage {
        case .forgettingPriorities:
            return "Green"
        case .anxiety, .speedingUp:
            return "Yellow"
        case .tickedOff, .exhausted, .relapse:
            return "Red"
        }
    }

    // MARK: - Private

    private func loadFromMockData() async throws {
        history = MockData.fasterHistory
        if let latest = history.first {
            selectedStage = latest.stage
        }
    }
}
