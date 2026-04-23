import Foundation
import SwiftUI

@Observable
final class TriggerLogViewModel {

    // MARK: - Nested Types

    struct TriggerOption: Identifiable {
        let id: UUID
        let label: String
        let category: TriggerCategory
    }

    struct NextAction: Identifiable {
        let id: String
        let label: String
        let icon: String
        let style: ActionStyle

        enum ActionStyle {
            case primary, secondary, destructive
        }
    }

    struct SubmittedEntry: Identifiable {
        let id: UUID
        let triggerSnapshots: [TriggerSnapshot]
        let intensity: Int?
        let riskLevel: RiskLevel?
        let timestamp: Date
    }

    // MARK: - State Properties

    var availableTriggers: [TriggerOption] = []
    var selectedTriggerIds: Set<UUID> = []
    var intensity: Int = 5
    var includeIntensity: Bool = true
    var logDepth: LogDepth = .quick

    // Standard depth
    var mood: String?
    var situation: String?
    var socialContext: SocialContext?
    var bodySensation: String?
    var responseTaken: String?

    // Deep depth
    var unmetNeed: UnmetNeed?
    var teacherReflection: String?
    var fasterPosition: FASTERStage?
    var copingStrategyId: UUID?
    var copingEffectiveness: Int?
    var locationCategory: LocationCategory?

    // Submission state
    var isSubmitting = false
    var isLoading = false
    var error: String?
    var recentEntries: [SubmittedEntry] = []

    // MARK: - Methods

    func toggleTrigger(id: UUID) {
        if selectedTriggerIds.contains(id) {
            selectedTriggerIds.remove(id)
        } else {
            if selectedTriggerIds.count < 10 {
                selectedTriggerIds.insert(id)
            }
        }
    }

    func submit() async throws {
        guard !selectedTriggerIds.isEmpty else {
            throw ActivityError.validationFailed("Please select at least one trigger.")
        }

        isSubmitting = true
        defer { isSubmitting = false }

        // Build trigger snapshots from selected triggers
        let snapshots = availableTriggers
            .filter { selectedTriggerIds.contains($0.id) }
            .map { TriggerSnapshot(id: $0.id, label: $0.label, category: $0.category.rawValue) }

        // Compute intensity and risk level
        let finalIntensity = includeIntensity ? intensity : nil
        let finalRiskLevel = finalIntensity.map { RiskLevel.from(intensity: $0) }

        // Create submitted entry
        let entry = SubmittedEntry(
            id: UUID(),
            triggerSnapshots: snapshots,
            intensity: finalIntensity,
            riskLevel: finalRiskLevel,
            timestamp: Date()
        )

        recentEntries.insert(entry, at: 0)
        reset()
    }

    func reset() {
        selectedTriggerIds = []
        intensity = 5
        includeIntensity = true
        logDepth = .quick

        // Reset standard depth fields
        mood = nil
        situation = nil
        socialContext = nil
        bodySensation = nil
        responseTaken = nil

        // Reset deep depth fields
        unmetNeed = nil
        teacherReflection = nil
        fasterPosition = nil
        copingStrategyId = nil
        copingEffectiveness = nil
        locationCategory = nil
    }

    // MARK: - Static Methods

    static func randomAffirmingMessage() -> String {
        let messages = [
            "You saw it. You named it. That matters.",
            "Recognizing what you're experiencing is a recovery skill.",
            "Noticing a trigger is strength, not weakness.",
            "Every trigger you name is self-knowledge gained.",
            "Awareness is the first step. You just took it.",
            "This is what recovery looks like — paying attention.",
            "You chose to notice instead of numb. That's courage."
        ]
        return messages.randomElement() ?? messages[0]
    }

    static func nextActions(for riskLevel: RiskLevel?) -> [NextAction] {
        var actions: [NextAction] = []

        // Always include these
        actions.append(NextAction(
            id: "dismiss",
            label: "Continue your day",
            icon: "checkmark.circle",
            style: .secondary
        ))
        actions.append(NextAction(
            id: "logAnother",
            label: "Log another trigger",
            icon: "plus.circle",
            style: .secondary
        ))

        // Low/nil risk
        if riskLevel == nil || riskLevel == .low {
            actions.append(NextAction(
                id: "journal",
                label: "Reflect in journal",
                icon: "note.text",
                style: .secondary
            ))
        }

        // Moderate risk
        if riskLevel == .moderate {
            actions.append(NextAction(
                id: "journal",
                label: "Reflect in journal",
                icon: "note.text",
                style: .secondary
            ))
            actions.append(NextAction(
                id: "copingExercise",
                label: "Try a coping exercise",
                icon: "wind",
                style: .primary
            ))
            actions.append(NextAction(
                id: "fasterScale",
                label: "Check in with FASTER Scale",
                icon: "gauge.with.needle",
                style: .secondary
            ))
        }

        // High risk
        if riskLevel == .high {
            actions.append(NextAction(
                id: "reachOut",
                label: "Reach out now",
                icon: "phone.fill",
                style: .destructive
            ))
            actions.append(NextAction(
                id: "urgeSurfing",
                label: "Urge surfing exercise",
                icon: "water.waves",
                style: .primary
            ))
            actions.append(NextAction(
                id: "crisisLine",
                label: "Call crisis line (988)",
                icon: "phone.arrow.up.right",
                style: .destructive
            ))
            actions.append(NextAction(
                id: "logUrge",
                label: "This became an urge — log it now",
                icon: "exclamationmark.triangle.fill",
                style: .primary
            ))
        }

        return actions
    }
}
