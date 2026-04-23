import Foundation
import SwiftData

enum BackboneStep: Int, CaseIterable {
    case lifeSituation, emotions, threeIs, spiritualReflection, emotionalNeeds, intimacyActions

    var title: String {
        switch self {
        case .lifeSituation: return String(localized: "Life Situation")
        case .emotions: return String(localized: "Emotions")
        case .threeIs: return String(localized: "Three I's")
        case .spiritualReflection: return String(localized: "Spiritual Reflection")
        case .emotionalNeeds: return String(localized: "Emotional Needs")
        case .intimacyActions: return String(localized: "Intimacy Actions")
        }
    }
}

@Observable
class BackboneProcessingViewModel {
    var currentStep: BackboneStep = .lifeSituation
    var showCompletion = false

    // Step 1: Life Situation
    var lifeSituation: String = ""

    // Step 2: Emotions
    var selectedEmotions: Set<String> = []
    var customEmotionText: String = ""

    // Step 3: Three I's
    var iActivations: [IActivation] = []

    // Step 4: Spiritual Reflection
    var spiritualReflectionText: String = ""

    // Step 5: Emotional Needs
    var selectedNeeds: Set<String> = []
    var customNeedText: String = ""

    // Step 6: Intimacy Actions
    var selectedActions: [IntimacyAction] = []
    var customActionText: String = ""

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(BackboneStep.allCases.count)
    }

    var isFirstStep: Bool { currentStep == .lifeSituation }
    var isLastStep: Bool { currentStep == .intimacyActions }

    var canAdvance: Bool {
        switch currentStep {
        case .lifeSituation: return !lifeSituation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .emotions: return !selectedEmotions.isEmpty
        case .threeIs: return !iActivations.isEmpty
        case .spiritualReflection: return true // optional
        case .emotionalNeeds: return !selectedNeeds.isEmpty
        case .intimacyActions: return !selectedActions.isEmpty
        }
    }

    func goForward() {
        guard canAdvance, let next = BackboneStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func goBack() {
        guard currentStep.rawValue > 0, let prev = BackboneStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func toggleEmotion(_ emotion: String) {
        if selectedEmotions.contains(emotion) { selectedEmotions.remove(emotion) }
        else { selectedEmotions.insert(emotion) }
    }

    func addCustomEmotion() {
        let trimmed = customEmotionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectedEmotions.insert(trimmed.lowercased())
        customEmotionText = ""
    }

    func toggleNeed(_ need: String) {
        if selectedNeeds.contains(need) { selectedNeeds.remove(need) }
        else { selectedNeeds.insert(need) }
    }

    func addCustomNeed() {
        let trimmed = customNeedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectedNeeds.insert(trimmed.lowercased())
        customNeedText = ""
    }

    func toggleIActivation(_ iType: ThreeIType, intensity: Int = 5) {
        if let index = iActivations.firstIndex(where: { $0.iType == iType }) {
            iActivations.remove(at: index)
        } else {
            iActivations.append(IActivation(iType: iType, intensity: intensity))
        }
    }

    func updateIntensity(for iType: ThreeIType, to intensity: Int) {
        guard let index = iActivations.firstIndex(where: { $0.iType == iType }) else { return }
        iActivations[index] = IActivation(iType: iType, intensity: max(1, min(10, intensity)))
    }

    func toggleAction(_ action: IntimacyAction) {
        if let index = selectedActions.firstIndex(of: action) { selectedActions.remove(at: index) }
        else { selectedActions.append(action) }
    }

    func addCustomAction(category: IntimacyCategory, label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selectedActions.append(IntimacyAction(category: category, label: trimmed, isCustom: true))
    }

    func save(marker: RRBowtieMarker, context: ModelContext) {
        let processing = RRBackboneProcessing(
            lifeSituation: lifeSituation.trimmingCharacters(in: .whitespacesAndNewlines),
            emotions: Array(selectedEmotions).sorted(),
            threeIs: iActivations,
            emotionalNeeds: Array(selectedNeeds).sorted(),
            intimacyActions: selectedActions,
            spiritualReflection: spiritualReflectionText.isEmpty ? nil : spiritualReflectionText
        )
        processing.marker = marker
        context.insert(processing)
        marker.isProcessed = true
        showCompletion = true
    }
}
