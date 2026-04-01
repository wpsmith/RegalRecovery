import Foundation
import SwiftUI

struct SpouseCheckInEntry: Identifiable {
    let id: UUID
    let date: Date
    let framework: String
    let summary: String

    init(id: UUID = UUID(), date: Date = Date(), framework: String, summary: String) {
        self.id = id
        self.date = date
        self.framework = framework
        self.summary = summary
    }
}

@Observable
class SpouseCheckInViewModel {

    // MARK: - State

    var framework: String = "FANOS"
    var history: [SpouseCheckInEntry] = []
    var isLoading = false
    var error: String?

    // FANOS sections
    var feelings: String = ""
    var selectedEmotion: PrimaryEmotion?
    var appreciation: String = ""
    var needs: Set<String> = []
    var ownership: String = ""
    var sobriety: String = ""

    // FITNAP sections
    var fitnapFeelings: String = ""
    var integrity: String = ""
    var triggers: String = ""
    var fitnapNeeds: String = ""
    var amends: String = ""
    var positives: String = ""

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            history = try await loadFromStorage()
        } catch {
            history = []
            self.error = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit() async throws {
        let summary = getSummary()
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ActivityError.validationFailed("Please fill in at least one section before submitting.")
        }

        let entry = SpouseCheckInEntry(
            framework: framework,
            summary: summary
        )

        // TODO: Replace with repository save
        history.insert(entry, at: 0)
        resetForm()
    }

    // MARK: - Summary

    func getSummary() -> String {
        if framework == "FANOS" {
            return buildFANOSSummary()
        } else {
            return buildFITNAPSummary()
        }
    }

    // MARK: - FANOS Summary

    private func buildFANOSSummary() -> String {
        var sections: [String] = []

        let feelingText = selectedEmotion?.rawValue ?? feelings
        if !feelingText.isEmpty {
            var line = "Feelings: \(feelingText)"
            if !feelings.isEmpty, selectedEmotion != nil {
                line += " — \(feelings)"
            }
            sections.append(line)
        }

        if !appreciation.isEmpty {
            sections.append("Appreciation: \(appreciation)")
        }

        if !needs.isEmpty {
            sections.append("Needs: \(needs.sorted().joined(separator: ", "))")
        }

        if !ownership.isEmpty {
            sections.append("Ownership: \(ownership)")
        }

        if !sobriety.isEmpty {
            sections.append("Sobriety: \(sobriety)")
        }

        return sections.joined(separator: "\n")
    }

    // MARK: - FITNAP Summary

    private func buildFITNAPSummary() -> String {
        var sections: [String] = []

        if !fitnapFeelings.isEmpty {
            sections.append("Feelings: \(fitnapFeelings)")
        }

        if !integrity.isEmpty {
            sections.append("Integrity / Sobriety: \(integrity)")
        }

        if !triggers.isEmpty {
            sections.append("Triggers: \(triggers)")
        }

        if !fitnapNeeds.isEmpty {
            sections.append("Needs: \(fitnapNeeds)")
        }

        if !amends.isEmpty {
            sections.append("Amends: \(amends)")
        }

        if !positives.isEmpty {
            sections.append("Positives: \(positives)")
        }

        return sections.joined(separator: "\n")
    }

    // MARK: - Private

    private func resetForm() {
        feelings = ""
        selectedEmotion = nil
        appreciation = ""
        needs = []
        ownership = ""
        sobriety = ""
        fitnapFeelings = ""
        integrity = ""
        triggers = ""
        fitnapNeeds = ""
        amends = ""
        positives = ""
    }

    private func loadFromStorage() async throws -> [SpouseCheckInEntry] {
        throw ActivityError.notImplemented
    }
}
