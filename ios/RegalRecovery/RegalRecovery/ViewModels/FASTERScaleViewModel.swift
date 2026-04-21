import SwiftUI

@Observable
class FASTERScaleViewModel {
    // MARK: - Check-In State

    var currentPhase: CheckInPhase = .mood
    var moodScore: Int?
    var selectedIndicators: [FASTERStage: Set<String>] = [:]
    var expandedStages: Set<FASTERStage> = []
    var journalInsight: String = ""
    var journalWarning: String = ""
    var journalFreeText: String = ""

    // MARK: - History State

    var history: [FASTEREntry] = []
    var isLoading = false
    var error: String?

    // MARK: - Computed

    /// The assessed stage: lowest (most severe) stage with at least one selected indicator.
    /// If only restoration indicators are selected, returns .restoration.
    /// Returns nil if nothing is selected.
    var assessedStage: FASTERStage? {
        // Walk stages from most severe (relapse) to least severe (restoration)
        for stage in FASTERStage.allCases.reversed() {
            if stage == .restoration { continue }
            if let indicators = selectedIndicators[stage], !indicators.isEmpty {
                return stage
            }
        }
        // Only restoration selected?
        if let restorationIndicators = selectedIndicators[.restoration], !restorationIndicators.isEmpty {
            return .restoration
        }
        return nil
    }

    /// Total number of selected indicators across all stages.
    var totalSelectedCount: Int {
        selectedIndicators.values.reduce(0) { $0 + $1.count }
    }

    /// Count of selected indicators for a specific stage.
    func selectedCount(for stage: FASTERStage) -> Int {
        selectedIndicators[stage]?.count ?? 0
    }

    /// Whether the check-in can be submitted (at least one indicator selected).
    var canSubmit: Bool {
        totalSelectedCount > 0
    }

    /// All selected indicator strings flattened into a single array.
    var allSelectedIndicatorStrings: [String] {
        selectedIndicators.values.flatMap { $0 }
    }

    /// Number of check-ins completed this month.
    var checkInsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return history.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    // MARK: - Actions

    func selectMood(_ score: Int) {
        moodScore = score
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .scale
        }
    }

    func toggleIndicator(stage: FASTERStage, indicator: String) {
        var set = selectedIndicators[stage] ?? []
        if set.contains(indicator) {
            set.remove(indicator)
        } else {
            set.insert(indicator)
        }
        if set.isEmpty {
            selectedIndicators.removeValue(forKey: stage)
        } else {
            selectedIndicators[stage] = set
        }
    }

    func isIndicatorSelected(stage: FASTERStage, indicator: String) -> Bool {
        selectedIndicators[stage]?.contains(indicator) ?? false
    }

    func toggleExpanded(stage: FASTERStage) {
        if expandedStages.contains(stage) {
            expandedStages.remove(stage)
        } else {
            expandedStages.insert(stage)
        }
    }

    func isExpanded(stage: FASTERStage) -> Bool {
        expandedStages.contains(stage)
    }

    func submit() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .results
        }
    }

    func reset() {
        currentPhase = .mood
        moodScore = nil
        selectedIndicators = [:]
        expandedStages = []
        journalInsight = ""
        journalWarning = ""
        journalFreeText = ""
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        error = nil

        do {
            try await loadFromMockData()
        } catch {
            self.error = "Unable to load FASTER Scale data. Please try again."
        }

        isLoading = false
    }

    // MARK: - Convenience Computed

    /// The most recent stage logged, or nil if no history
    var currentStage: FASTERStage? {
        history.first?.stage
    }

    /// Human-readable summary of the current FASTER state
    var statusLabel: String {
        guard let stage = currentStage else { return String(localized: "Not assessed") }
        return stage.name
    }

    /// Color zone: "Green", "Yellow", or "Red"
    var zoneLabel: String {
        guard let stage = currentStage else { return String(localized: "Green") }
        switch stage {
        case .restoration, .forgettingPriorities:
            return String(localized: "Green")
        case .anxiety, .speedingUp:
            return String(localized: "Yellow")
        case .tickedOff, .exhausted, .relapse:
            return String(localized: "Red")
        }
    }


    // MARK: - Private

    private func loadFromMockData() async throws {
        history = MockData.fasterHistory
    }
}
