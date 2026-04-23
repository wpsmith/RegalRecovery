import Foundation
import SwiftUI

struct UrgeEntry: Identifiable {
    let id: UUID
    let date: Date
    let intensity: Int
    let addictions: [String]
    let triggers: [String]
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), intensity: Int, addictions: [String], triggers: [String], notes: String) {
        self.id = id
        self.date = date
        self.intensity = intensity
        self.addictions = addictions
        self.triggers = triggers
        self.notes = notes
    }
}

@Observable
class UrgeLogViewModel {

    // MARK: - State

    var recentUrges: [UrgeEntry] = []
    var isSubmitting = false
    var isLoading = false
    var error: String?

    // Entry state
    var intensity: Int = 5
    var selectedAddictions: Set<String> = []
    var selectedTriggers: Set<String> = []
    var notes: String = ""
    var linkedTriggerLogId: UUID?

    static let defaultTriggers = [
        "Stress", "Loneliness", "Boredom", "Anger",
        "Tiredness", "Social Media", "Late Night", "Conflict"
    ]

    var triggerLibraryOptions: [TriggerLogViewModel.TriggerOption] = []
    var useFullLibrary: Bool = false

    var displayTriggers: [String] {
        if useFullLibrary {
            return triggerLibraryOptions.map(\.label)
        }
        return Self.defaultTriggers
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            recentUrges = try await loadFromStorage()
        } catch {
            // Fallback to mock data representation
            recentUrges = []
            self.error = error.localizedDescription
        }

        if selectedAddictions.isEmpty {
            if let first = MockData.profile.addictions.first {
                selectedAddictions = [first]
            }
        }
    }

    // MARK: - Submit

    func submit() async throws {
        guard !selectedAddictions.isEmpty else {
            throw ActivityError.validationFailed("Please select at least one addiction type.")
        }
        guard intensity >= 1, intensity <= 10 else {
            throw ActivityError.validationFailed("Intensity must be between 1 and 10.")
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let entry = UrgeEntry(
            intensity: intensity,
            addictions: Array(selectedAddictions),
            triggers: Array(selectedTriggers),
            notes: notes
        )

        // TODO: Replace with repository save
        recentUrges.insert(entry, at: 0)
        reset()
    }

    // MARK: - Reset

    func reset() {
        intensity = 5
        if let first = MockData.profile.addictions.first {
            selectedAddictions = [first]
        } else {
            selectedAddictions = []
        }
        selectedTriggers = []
        notes = ""
    }

    // MARK: - Private

    private func loadFromStorage() async throws -> [UrgeEntry] {
        throw ActivityError.notImplemented
    }
}
