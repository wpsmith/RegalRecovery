import Foundation
import SwiftData
import Observation

/// Draft state for a behavior being checked during a check-in.
struct ActingInBehaviorDraft: Identifiable {
    var id: String { behaviorId }
    let behaviorId: String
    let behaviorName: String
    var isChecked: Bool = false
    var contextNote: String = ""
    var trigger: ActingInTrigger?
    var relationshipTag: ActingInRelationshipTag?
}

/// ViewModel for the Acting-In Behaviors check-in flow.
@Observable
final class ActingInCheckInViewModel {

    // MARK: - Published State

    var behaviorDrafts: [ActingInBehaviorDraft] = []
    var showSaveAnimation = false
    var savedMessage: String?
    var isFirstUse = false
    var streakCount = 0

    // MARK: - Constants

    static let maxContextNoteLength = 500

    // MARK: - Computed

    var checkedBehaviors: [ActingInBehaviorDraft] {
        behaviorDrafts.filter { $0.isChecked }
    }

    var checkedCount: Int {
        checkedBehaviors.count
    }

    var canSubmit: Bool {
        true // Zero behaviors is valid.
    }

    // MARK: - Actions

    /// Load enabled behaviors from the model context and prepare drafts.
    func loadBehaviors(context: ModelContext, userId: UUID) {
        let descriptor = FetchDescriptor<RRActingInBehavior>(
            predicate: #Predicate { $0.enabled },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        let existing = (try? context.fetch(descriptor)) ?? []

        if existing.isEmpty {
            // First use: seed default behaviors.
            isFirstUse = true
            for (index, def) in ActingInDefaults.behaviors.enumerated() {
                let behavior = RRActingInBehavior(
                    behaviorId: def.id,
                    name: def.name,
                    description: def.description,
                    isDefault: true,
                    enabled: true,
                    sortOrder: index + 1
                )
                context.insert(behavior)
            }
            try? context.save()
            // Re-fetch.
            let refetched = (try? context.fetch(descriptor)) ?? []
            behaviorDrafts = refetched.map { makeDraft(from: $0) }
        } else {
            behaviorDrafts = existing.map { makeDraft(from: $0) }
        }

        // Load settings for streak.
        let settingsDescriptor = FetchDescriptor<RRActingInSettings>()
        if let settings = try? context.fetch(settingsDescriptor).first {
            streakCount = settings.streakCount
            isFirstUse = !settings.firstUseCompleted
        }
    }

    /// Toggle a behavior's checked state.
    func toggleBehavior(_ behaviorId: String) {
        guard let index = behaviorDrafts.firstIndex(where: { $0.behaviorId == behaviorId }) else { return }
        behaviorDrafts[index].isChecked.toggle()
    }

    /// Submit the check-in.
    func submit(context: ModelContext, userId: UUID) {
        let checked = checkedBehaviors.map { draft in
            ActingInCheckedBehavior(
                behaviorId: draft.behaviorId,
                behaviorName: draft.behaviorName,
                contextNote: draft.contextNote.isEmpty ? nil : draft.contextNote,
                trigger: draft.trigger,
                relationshipTag: draft.relationshipTag
            )
        }

        let behaviorsData = try? JSONEncoder().encode(checked)
        let message = ActingInMessages.messageForCheckIn(
            behaviorCount: checked.count,
            streakCount: streakCount
        )

        let checkIn = RRActingInCheckIn(
            checkInId: "aic_\(UUID().uuidString.prefix(8))",
            userId: userId.uuidString,
            timestamp: Date(),
            behaviorCount: checked.count,
            behaviorsData: behaviorsData,
            consecutiveCheckIns: streakCount + 1,
            message: message,
            synced: false
        )
        context.insert(checkIn)

        // Update settings.
        let settingsDescriptor = FetchDescriptor<RRActingInSettings>()
        if let settings = try? context.fetch(settingsDescriptor).first {
            settings.streakCount += 1
            settings.lastCheckInAt = Date()
            settings.firstUseCompleted = true
        } else {
            let settings = RRActingInSettings(
                userId: userId.uuidString,
                streakCount: 1
            )
            settings.firstUseCompleted = true
            settings.lastCheckInAt = Date()
            context.insert(settings)
        }

        try? context.save()

        // Show confirmation.
        savedMessage = message
        showSaveAnimation = true
        streakCount += 1

        // Reset drafts after a delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.showSaveAnimation = false
            self?.savedMessage = nil
            self?.resetDrafts()
        }
    }

    /// Enforce context note character limit.
    func enforceContextNoteLimit(for behaviorId: String) {
        guard let index = behaviorDrafts.firstIndex(where: { $0.behaviorId == behaviorId }) else { return }
        if behaviorDrafts[index].contextNote.count > Self.maxContextNoteLength {
            behaviorDrafts[index].contextNote = String(
                behaviorDrafts[index].contextNote.prefix(Self.maxContextNoteLength)
            )
        }
    }

    func shouldShowCounter(_ text: String) -> Bool {
        text.count >= Self.maxContextNoteLength - 50
    }

    func isAtCharacterLimit(_ text: String) -> Bool {
        text.count >= Self.maxContextNoteLength
    }

    // MARK: - Private

    private func makeDraft(from behavior: RRActingInBehavior) -> ActingInBehaviorDraft {
        ActingInBehaviorDraft(
            behaviorId: behavior.behaviorId,
            behaviorName: behavior.name
        )
    }

    private func resetDrafts() {
        for i in behaviorDrafts.indices {
            behaviorDrafts[i].isChecked = false
            behaviorDrafts[i].contextNote = ""
            behaviorDrafts[i].trigger = nil
            behaviorDrafts[i].relationshipTag = nil
        }
    }
}
