import Foundation
import SwiftUI

struct UrgeEntry: Identifiable {
    let id: UUID
    let date: Date
    let intensity: Int
    let addiction: String
    let triggers: [String]
    let notes: String

    init(id: UUID = UUID(), date: Date = Date(), intensity: Int, addiction: String, triggers: [String], notes: String) {
        self.id = id
        self.date = date
        self.intensity = intensity
        self.addiction = addiction
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
    var selectedAddiction: String = ""
    var selectedTriggers: Set<String> = []
    var notes: String = ""

    static let availableTriggers = [
        "Stress", "Loneliness", "Boredom", "Anger",
        "Tiredness", "Social Media", "Late Night", "Conflict"
    ]

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

        if selectedAddiction.isEmpty {
            selectedAddiction = MockData.profile.addictions.first ?? ""
        }
    }

    // MARK: - Submit

    func submit() async throws {
        guard !selectedAddiction.isEmpty else {
            throw ActivityError.validationFailed("Please select an addiction type.")
        }
        guard intensity >= 1, intensity <= 10 else {
            throw ActivityError.validationFailed("Intensity must be between 1 and 10.")
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let entry = UrgeEntry(
            intensity: intensity,
            addiction: selectedAddiction,
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
        selectedAddiction = MockData.profile.addictions.first ?? ""
        selectedTriggers = []
        notes = ""
    }

    // MARK: - Private

    private func loadFromStorage() async throws -> [UrgeEntry] {
        throw ActivityError.notImplemented
    }
}
