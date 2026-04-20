import Foundation
import SwiftUI
import SwiftData

enum FASTERCheckInStep {
    case mood
    case indicators
    case results
}

@Observable
class FASTERCheckInViewModel {

    // MARK: - Flow State

    var currentStep: FASTERCheckInStep = .mood

    // MARK: - Mood (S-01)

    var moodScore: Int = 0  // 1-5, 0 = not yet selected

    // MARK: - Indicators (S-02, S-03, S-04)

    /// Selected indicators keyed by stage. Each value is a Set of indicator label strings.
    var selectedIndicators: [FASTERStage: Set<String>] = [:]

    // MARK: - Assessment (S-05)

    /// The assessed stage: the most severe (highest rawValue) stage with at least one indicator selected.
    /// Returns `.restoration` if no indicators are selected outside Restoration.
    var assessedStage: FASTERStage {
        let activeStages = selectedIndicators
            .filter { $0.key != .restoration && !$0.value.isEmpty }
            .map(\.key)

        if activeStages.isEmpty {
            return .restoration
        }

        return activeStages.max(by: { $0.rawValue < $1.rawValue }) ?? .restoration
    }

    // MARK: - Journal (S-08)

    var journalInsight: String = ""
    var journalWarning: String = ""
    var journalFreeText: String = ""

    // MARK: - Indicator Helpers

    func isSelected(stage: FASTERStage, indicator: String) -> Bool {
        selectedIndicators[stage]?.contains(indicator) ?? false
    }

    func toggleIndicator(stage: FASTERStage, indicator: String) {
        if selectedIndicators[stage] == nil {
            selectedIndicators[stage] = []
        }
        if selectedIndicators[stage]!.contains(indicator) {
            selectedIndicators[stage]!.remove(indicator)
            if selectedIndicators[stage]!.isEmpty {
                selectedIndicators[stage] = nil
            }
        } else {
            selectedIndicators[stage]!.insert(indicator)
        }
    }

    func selectedCount(for stage: FASTERStage) -> Int {
        selectedIndicators[stage]?.count ?? 0
    }

    // MARK: - Flow Navigation

    func selectMood(_ score: Int) {
        moodScore = score
        currentStep = .indicators
    }

    func finishIndicators() {
        currentStep = .results
    }

    func goBackToIndicators() {
        currentStep = .indicators
    }

    var isFirstStep: Bool {
        currentStep == .mood
    }

    func goBack() {
        switch currentStep {
        case .mood:
            break
        case .indicators:
            currentStep = .mood
        case .results:
            currentStep = .indicators
        }
    }

    // MARK: - Persistence (S-09)

    func save(context: ModelContext, userId: UUID) {
        let encodable: [String: [String]] = selectedIndicators.reduce(into: [:]) { result, pair in
            result[pair.key.name] = Array(pair.value).sorted()
        }
        let json = (try? JSONEncoder().encode(encodable)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let entry = RRFASTEREntry(
            userId: userId,
            date: Date(),
            stage: assessedStage.rawValue,
            moodScore: moodScore,
            selectedIndicatorsJSON: json,
            journalInsight: journalInsight.isEmpty ? nil : journalInsight,
            journalWarning: journalWarning.isEmpty ? nil : journalWarning,
            journalFreeText: journalFreeText.isEmpty ? nil : journalFreeText
        )
        context.insert(entry)
    }
}
