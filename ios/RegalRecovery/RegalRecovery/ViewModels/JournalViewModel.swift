import SwiftUI
import SwiftData

@Observable
class JournalViewModel {
    var isSubmitting = false
    var error: String?

    func createEntry(
        in context: ModelContext,
        userId: UUID,
        mode: String,
        content: String,
        prompt: String? = nil,
        isEphemeral: Bool = false
    ) {
        isSubmitting = true
        defer { isSubmitting = false }

        let entry = RRJournalEntry(
            userId: userId,
            date: Date(),
            mode: mode,
            content: content,
            prompt: prompt,
            isEphemeral: isEphemeral
        )
        context.insert(entry)
    }

    func deleteEntry(_ entry: RRJournalEntry, in context: ModelContext) {
        context.delete(entry)
    }
}
