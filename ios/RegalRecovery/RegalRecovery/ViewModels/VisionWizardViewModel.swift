import Foundation
import Observation
import SwiftData

@Observable
final class VisionWizardViewModel {

    // MARK: - Flow State

    var currentStep: VisionWizardStep = .prompts(index: 0)

    // MARK: - Data

    var promptResponses: [Int: String] = [:]
    var identityStatement: String = ""
    var visionBody: String = ""
    var selectedValues: [String] = []
    var scriptureReference: String? = nil
    var scriptureText: String? = nil

    // MARK: - Editing

    var editingVisionId: UUID?

    // MARK: - UI State

    var showResumeAlert: Bool = false

    // MARK: - Persistence Key

    private static let draftKey = "vision.wizard.draft"

    // MARK: - Init

    init() {}

    init(editing vision: RRVisionStatement) {
        editingVisionId = vision.id
        identityStatement = vision.identityStatement
        visionBody = vision.visionBody
        selectedValues = vision.coreValues
        scriptureReference = vision.scriptureReference
        scriptureText = vision.scriptureText

        let responses = vision.promptResponses
        for (key, value) in responses {
            if let index = Int(key) {
                promptResponses[index] = value
            }
        }

        currentStep = .review
    }

    // MARK: - Navigation

    var canProceed: Bool {
        switch currentStep {
        case .prompts:
            return true
        case .identity:
            return !identityStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .values:
            return !selectedValues.isEmpty
        case .scripture:
            return true
        case .review:
            return !identityStatement.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var canGoBack: Bool {
        switch currentStep {
        case .prompts(let index):
            return index > 0
        default:
            return true
        }
    }

    var canSkip: Bool {
        switch currentStep {
        case .prompts, .scripture:
            return true
        case .identity, .values, .review:
            return false
        }
    }

    func goToNextStep() {
        saveDraft()
        switch currentStep {
        case .prompts(let index):
            if index < VisionPrompt.allCases.count - 1 {
                currentStep = .prompts(index: index + 1)
            } else {
                currentStep = .identity
            }
        case .identity:
            currentStep = .values
        case .values:
            currentStep = .scripture
        case .scripture:
            currentStep = .review
        case .review:
            break
        }
    }

    func goToPreviousStep() {
        switch currentStep {
        case .prompts(let index):
            if index > 0 {
                currentStep = .prompts(index: index - 1)
            }
        case .identity:
            currentStep = .prompts(index: VisionPrompt.allCases.count - 1)
        case .values:
            currentStep = .identity
        case .scripture:
            currentStep = .values
        case .review:
            currentStep = .scripture
        }
    }

    func skipCurrentStep() {
        guard canSkip else { return }
        goToNextStep()
    }

    // MARK: - Values Management

    func toggleValue(_ value: String) {
        if let index = selectedValues.firstIndex(of: value) {
            selectedValues.remove(at: index)
        } else if selectedValues.count < VisionLimits.maxValues {
            selectedValues.append(value)
        }
    }

    func moveValue(from source: IndexSet, to destination: Int) {
        selectedValues.move(fromOffsets: source, toOffset: destination)
    }

    var isAtValueLimit: Bool {
        selectedValues.count >= VisionLimits.maxValues
    }

    // MARK: - Save

    func save(context: ModelContext, userId: UUID) {
        let trimmedIdentity = identityStatement.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = visionBody.trimmingCharacters(in: .whitespacesAndNewlines)

        var responsesDict: [String: String] = [:]
        for (index, text) in promptResponses {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                responsesDict[String(index)] = trimmed
            }
        }
        let responsesJSON: String? = {
            guard !responsesDict.isEmpty,
                  let data = try? JSONEncoder().encode(responsesDict),
                  let json = String(data: data, encoding: .utf8) else { return nil }
            return json
        }()

        var newVersion = 1
        if let editingId = editingVisionId {
            let descriptor = FetchDescriptor<RRVisionStatement>(
                predicate: #Predicate { $0.id == editingId }
            )
            if let existing = try? context.fetch(descriptor).first {
                newVersion = existing.version + 1
                existing.isCurrent = false
            }
        } else {
            let descriptor = FetchDescriptor<RRVisionStatement>(
                predicate: #Predicate { $0.isCurrent == true }
            )
            if let existing = try? context.fetch(descriptor).first {
                newVersion = existing.version + 1
                existing.isCurrent = false
            }
        }

        let statement = RRVisionStatement(
            userId: userId,
            identityStatement: trimmedIdentity,
            visionBody: trimmedBody,
            coreValues: selectedValues,
            scriptureReference: scriptureReference,
            scriptureText: scriptureText,
            promptResponsesJSON: responsesJSON,
            version: newVersion,
            isCurrent: true
        )
        context.insert(statement)

        clearDraft()
    }

    // MARK: - Draft Persistence

    func saveDraft() {
        let draft = VisionDraft(
            currentStep: currentStep,
            promptResponses: promptResponses,
            identityStatement: identityStatement,
            visionBody: visionBody,
            selectedValues: selectedValues,
            scriptureReference: scriptureReference,
            scriptureText: scriptureText,
            editingVisionId: editingVisionId
        )
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: Self.draftKey)
        }
    }

    func resumeDraft() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: Self.draftKey),
              let draft = try? JSONDecoder().decode(VisionDraft.self, from: data) else {
            return false
        }
        currentStep = draft.currentStep
        promptResponses = draft.promptResponses
        identityStatement = draft.identityStatement
        visionBody = draft.visionBody
        selectedValues = draft.selectedValues
        scriptureReference = draft.scriptureReference
        scriptureText = draft.scriptureText
        editingVisionId = draft.editingVisionId
        return true
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }

    var hasSavedDraft: Bool {
        UserDefaults.standard.data(forKey: Self.draftKey) != nil
    }
}

// MARK: - Draft Model

private struct VisionDraft: Codable {
    let currentStep: VisionWizardStep
    let promptResponses: [Int: String]
    let identityStatement: String
    let visionBody: String
    let selectedValues: [String]
    let scriptureReference: String?
    let scriptureText: String?
    let editingVisionId: UUID?
}
