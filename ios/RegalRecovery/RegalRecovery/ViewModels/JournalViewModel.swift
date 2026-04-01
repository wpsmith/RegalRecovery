import SwiftUI

struct JournalEntry: Identifiable {
    let id: UUID
    let date: Date
    let mode: String
    let content: String
    let prompt: String?
}

@Observable
class JournalViewModel {
    var entries: [JournalEntry] = []
    var isSubmitting = false
    var isLoading = false
    var error: String?

    // MARK: - Loading

    func load(limit: Int = 20) async {
        isLoading = true
        error = nil

        do {
            // TODO: Replace MockData fallback with real repository calls
            try await loadFromMockData(limit: limit)
        } catch {
            self.error = "Unable to load journal entries. Please try again."
        }

        isLoading = false
    }

    // MARK: - Actions

    func createEntry(mode: String, content: String, prompt: String?, isEphemeral: Bool) async throws {
        isSubmitting = true
        defer { isSubmitting = false }

        // TODO: Persist to repository (handle isEphemeral for auto-delete)
        let entry = JournalEntry(
            id: UUID(),
            date: Date(),
            mode: mode,
            content: content,
            prompt: prompt
        )
        entries.insert(entry, at: 0)
    }

    // MARK: - Private

    private func loadFromMockData(limit: Int) async throws {
        // Build journal entries from MockData emotional journal as a starting point
        let mockEntries = MockData.emotionalJournalEntries.prefix(limit)
        entries = mockEntries.map { ejEntry in
            JournalEntry(
                id: UUID(),
                date: ejEntry.date,
                mode: "emotional",
                content: "Feeling \(ejEntry.emotion.lowercased()) during \(ejEntry.activity.lowercased()).",
                prompt: nil
            )
        }
    }
}
