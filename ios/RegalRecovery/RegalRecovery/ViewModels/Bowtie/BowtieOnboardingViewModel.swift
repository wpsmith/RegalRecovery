import Foundation
import SwiftData

enum BowtieOnboardingStep: Int, CaseIterable {
    case explanation, visualMetaphor, roleSetup, triggerSetup
}

@Observable
class BowtieOnboardingViewModel {
    var currentStep: BowtieOnboardingStep = .explanation
    var selectedSuggestionRoles: Set<String> = []
    var customRoleLabel: String = ""
    var selectedSuggestionTriggers: Set<String> = []
    var customTriggerLabel: String = ""

    private static let completedKey = "bowtie.onboardingCompleted"

    static var isOnboardingCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    var isLastStep: Bool { currentStep == .triggerSetup }
    var isFirstStep: Bool { currentStep == .explanation }

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(BowtieOnboardingStep.allCases.count)
    }

    func goForward() {
        guard let next = BowtieOnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func goBack() {
        guard currentStep.rawValue > 0,
              let prev = BowtieOnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func toggleSuggestionRole(_ role: String) {
        if selectedSuggestionRoles.contains(role) { selectedSuggestionRoles.remove(role) }
        else { selectedSuggestionRoles.insert(role) }
    }

    func addCustomRole() {
        let trimmed = customRoleLabel.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        selectedSuggestionRoles.insert(trimmed)
        customRoleLabel = ""
    }

    func toggleSuggestionTrigger(_ trigger: String) {
        if selectedSuggestionTriggers.contains(trigger) { selectedSuggestionTriggers.remove(trigger) }
        else { selectedSuggestionTriggers.insert(trigger) }
    }

    func addCustomTrigger() {
        let trimmed = customTriggerLabel.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        selectedSuggestionTriggers.insert(trimmed)
        customTriggerLabel = ""
    }

    func completeOnboarding(context: ModelContext) {
        for (index, label) in selectedSuggestionRoles.sorted().enumerated() {
            context.insert(RRUserRole(label: label, sortOrder: index))
        }
        for label in selectedSuggestionTriggers.sorted() {
            let mapping = suggestedMapping(for: label)
            context.insert(RRKnownEmotionalTrigger(label: label, mappedIType: mapping))
        }
        UserDefaults.standard.set(true, forKey: Self.completedKey)
    }

    private func suggestedMapping(for trigger: String) -> ThreeIType? {
        switch trigger.lowercased() {
        case "rejection", "being overlooked", "abandonment", "loneliness": return .insignificance
        case "failure", "feeling stupid", "criticism": return .incompetence
        case "being controlled", "overwhelm": return .impotence
        default: return nil
        }
    }
}
