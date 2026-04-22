// ViewModels/MotivationDiscoveryViewModel.swift
import Foundation
import Observation

@Observable
final class MotivationDiscoveryViewModel {

    // MARK: - Flow State

    var currentStep: MotivationDiscoveryStep = .intro

    // MARK: - Data

    var miracleResponse: String = ""
    var selectedValues: [MotivationCategory] = []
    var concreteResponses: [MotivationCategory: String] = [:]
    var concreteScriptures: [MotivationCategory: String] = [:]
    var currentConcretePromptIndex: Int = 0

    // MARK: - Draft Persistence Key

    private static let draftKey = "motivations.discovery.draft"

    // MARK: - Navigation

    var canProceed: Bool {
        switch currentStep {
        case .intro:
            return true
        case .miracleQuestion:
            return true
        case .valuesSelection:
            return !selectedValues.isEmpty
        case .concretePrompts:
            return true
        case .summary:
            return true
        }
    }

    var canGoBack: Bool {
        currentStep != .intro
    }

    func goToNextStep() {
        switch currentStep {
        case .intro:
            currentStep = .miracleQuestion
        case .miracleQuestion:
            currentStep = .valuesSelection
        case .valuesSelection:
            currentConcretePromptIndex = 0
            currentStep = .concretePrompts
        case .concretePrompts:
            if currentConcretePromptIndex < selectedValues.count - 1 {
                currentConcretePromptIndex += 1
            } else {
                currentStep = .summary
            }
        case .summary:
            break
        }
    }

    func goToPreviousStep() {
        switch currentStep {
        case .intro:
            break
        case .miracleQuestion:
            currentStep = .intro
        case .valuesSelection:
            currentStep = .miracleQuestion
        case .concretePrompts:
            if currentConcretePromptIndex > 0 {
                currentConcretePromptIndex -= 1
            } else {
                currentStep = .valuesSelection
            }
        case .summary:
            currentConcretePromptIndex = max(0, selectedValues.count - 1)
            currentStep = .concretePrompts
        }
    }

    // MARK: - Values

    func toggleValue(_ category: MotivationCategory) {
        if let index = selectedValues.firstIndex(of: category) {
            selectedValues.remove(at: index)
            concreteResponses.removeValue(forKey: category)
            concreteScriptures.removeValue(forKey: category)
        } else if selectedValues.count < MotivationLimits.maxValuesSelection {
            selectedValues.append(category)
        }
    }

    var concretePromptCategories: [MotivationCategory] {
        selectedValues
    }

    var currentConcreteCategory: MotivationCategory? {
        guard currentConcretePromptIndex < selectedValues.count else { return nil }
        return selectedValues[currentConcretePromptIndex]
    }

    func concretePromptText(for category: MotivationCategory) -> String {
        switch category {
        case .spiritual:
            return String(localized: "You chose Spiritual. What about your faith specifically motivates your recovery?")
        case .relational:
            return String(localized: "You chose Relational. What specifically about your relationships motivates your recovery?")
        case .health:
            return String(localized: "You chose Health. What about your health specifically motivates your recovery?")
        case .professional:
            return String(localized: "You chose Professional. What about your career or calling motivates your recovery?")
        case .personalGrowth:
            return String(localized: "You chose Personal Growth. What kind of person are you becoming through recovery?")
        case .financial:
            return String(localized: "You chose Financial. What about your finances motivates your recovery?")
        }
    }

    // MARK: - Build Motivations

    func buildMotivations(userId: UUID) -> [RRMotivation] {
        selectedValues.compactMap { category in
            let text = concreteResponses[category]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { return nil }
            let scripture = concreteScriptures[category]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanScripture = (scripture?.isEmpty ?? true) ? nil : scripture
            return RRMotivation(
                userId: userId,
                text: String(text.prefix(MotivationLimits.maxTextLength)),
                category: category,
                importanceRating: MotivationImportance.defaultRating,
                scriptureReference: cleanScripture,
                source: .discovery
            )
        }
    }

    // MARK: - Draft Persistence

    func saveDraft() {
        let draft: [String: Any] = [
            "step": currentStep.rawValue,
            "miracleResponse": miracleResponse,
            "selectedValues": selectedValues.map(\.rawValue),
            "concreteResponses": concreteResponses.reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value },
            "concreteScriptures": concreteScriptures.reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value },
        ]
        UserDefaults.standard.set(draft, forKey: Self.draftKey)
    }

    func loadDraft() -> Bool {
        guard let draft = UserDefaults.standard.dictionary(forKey: Self.draftKey) else { return false }
        if let stepRaw = draft["step"] as? Int,
           let step = MotivationDiscoveryStep(rawValue: stepRaw) {
            currentStep = step
        }
        miracleResponse = draft["miracleResponse"] as? String ?? ""
        if let valuesRaw = draft["selectedValues"] as? [String] {
            selectedValues = valuesRaw.compactMap { MotivationCategory(rawValue: $0) }
        }
        if let responsesRaw = draft["concreteResponses"] as? [String: String] {
            concreteResponses = responsesRaw.reduce(into: [:]) { result, pair in
                if let cat = MotivationCategory(rawValue: pair.key) {
                    result[cat] = pair.value
                }
            }
        }
        if let scripturesRaw = draft["concreteScriptures"] as? [String: String] {
            concreteScriptures = scripturesRaw.reduce(into: [:]) { result, pair in
                if let cat = MotivationCategory(rawValue: pair.key) {
                    result[cat] = pair.value
                }
            }
        }
        return true
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }
}
