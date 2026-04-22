import Foundation
import SwiftData

// MARK: - Gratitude Item Draft

/// Mutable draft for an in-progress gratitude item before saving.
struct GratitudeItemDraft: Identifiable {
    let id: UUID = UUID()
    var text: String = ""
    var category: GratitudeCategory?
    var customTagName: String = ""
    var usingSavedTag: Bool = false
}

// MARK: - Gratitude Entry ViewModel

@Observable
class GratitudeEntryViewModel {

    // MARK: - Constants

    static let maxCharacters = 300
    static let warningThreshold = 250

    static let postSaveMessages: [String] = [
        "A grateful heart is a guarded heart. Thank you for pausing to notice the good.",
        "Every item on this list is evidence that God is at work in your life.",
        "Gratitude doesn\u{2019}t ignore the pain \u{2014} it refuses to let pain have the last word.",
        "You just trained your brain to see the good. That\u{2019}s recovery in action.",
        "Even one thing to be thankful for can shift your whole perspective.",
    ]

    static let firstUseMessage: String =
        "Gratitude rewires how your brain processes the world. In recovery, it\u{2019}s one of the most powerful antidotes to shame, self-pity, and resentment. Start with just one thing."

    // MARK: - State

    var items: [GratitudeItemDraft] = [GratitudeItemDraft()]
    var moodScore: Int?
    var showPrompt: Bool = false
    var currentPrompt: GratitudePrompt?
    var savedMessage: String?
    var showSaveAnimation: Bool = false
    var dailyPromptDismissed: Bool = false
    var dailyPrompt: GratitudePrompt?
    var savedCustomTags: [String] = []

    // MARK: - Services

    private let promptService = GratitudePromptService()
    private var postSaveIndex: Int = 0
    private static let customTagsKey = "gratitude.customTags"

    init() {
        savedCustomTags = UserDefaults.standard.stringArray(forKey: Self.customTagsKey) ?? []
    }

    // MARK: - Computed

    var canSave: Bool {
        items.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    // MARK: - Item Management

    func addItem() {
        items.append(GratitudeItemDraft())
    }

    func removeItem(at index: Int) {
        guard items.count > 1 else { return }
        items.remove(at: index)
    }

    func isAtCharacterLimit(_ text: String) -> Bool {
        text.count >= Self.maxCharacters
    }

    func shouldShowCounter(_ text: String) -> Bool {
        text.count >= Self.warningThreshold
    }

    func clampText(_ text: inout String) {
        if text.count > Self.maxCharacters {
            text = String(text.prefix(Self.maxCharacters))
        }
    }

    // MARK: - Custom Tags

    func removeCustomTag(_ tag: String) {
        savedCustomTags.removeAll { $0 == tag }
        UserDefaults.standard.set(savedCustomTags, forKey: Self.customTagsKey)
    }

    // MARK: - Mood

    func toggleMood(_ score: Int) {
        if moodScore == score {
            moodScore = nil
        } else {
            moodScore = score
        }
    }

    // MARK: - Prompts

    func requestPrompt(userId: UUID) {
        if currentPrompt == nil {
            currentPrompt = promptService.dailyPrompt(for: userId, on: Date())
        }
        showPrompt = true
    }

    func nextPrompt() {
        guard let current = currentPrompt else { return }
        currentPrompt = promptService.nextPrompt(after: current)
    }

    func usePrompt() {
        guard let prompt = currentPrompt else { return }
        var draft = GratitudeItemDraft()
        draft.text = prompt.text
        items.append(draft)
        showPrompt = false
    }

    func dismissPrompt() {
        showPrompt = false
    }

    // MARK: - Daily Prompt (auto-prompt before entry)

    func loadDailyPrompt(userId: UUID) {
        if dailyPrompt == nil && !dailyPromptDismissed {
            dailyPrompt = promptService.dailyPrompt(for: userId, on: Date())
        }
    }

    func dismissDailyPrompt() {
        dailyPromptDismissed = true
    }

    func useDailyPrompt() {
        guard let prompt = dailyPrompt else { return }
        var draft = GratitudeItemDraft()
        draft.text = prompt.text
        items.append(draft)
        dailyPromptDismissed = true
    }

    // MARK: - Save

    func save(context: ModelContext, userId: UUID) {
        let gratitudeItems: [GratitudeItem] = items.enumerated().compactMap { index, draft in
            let trimmed = draft.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return GratitudeItem(
                text: trimmed,
                category: draft.category,
                customTagName: draft.category == .custom ? draft.customTagName : nil,
                sortOrder: index
            )
        }

        guard !gratitudeItems.isEmpty else { return }

        // Persist any new custom tags
        let newTags = gratitudeItems
            .compactMap { $0.customTagName }
            .filter { !$0.isEmpty && !savedCustomTags.contains($0) }
        if !newTags.isEmpty {
            savedCustomTags.append(contentsOf: newTags)
            UserDefaults.standard.set(savedCustomTags, forKey: Self.customTagsKey)
        }

        let promptText: String? = currentPrompt.map { $0.text }

        let entry = RRGratitudeEntry(
            userId: userId,
            date: Date(),
            items: gratitudeItems,
            moodScore: moodScore,
            promptUsed: promptText
        )

        context.insert(entry)

        // Show save confirmation
        showSaveAnimation = true
        savedMessage = Self.postSaveMessages[postSaveIndex % Self.postSaveMessages.count]
        postSaveIndex += 1

        // Reset fields
        items = [GratitudeItemDraft()]
        moodScore = nil
        currentPrompt = nil
        showPrompt = false
        dailyPrompt = nil
        dailyPromptDismissed = false

        // Auto-clear confirmation after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.showSaveAnimation = false
            self?.savedMessage = nil
        }
    }
}
