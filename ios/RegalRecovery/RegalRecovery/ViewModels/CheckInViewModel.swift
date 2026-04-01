import SwiftUI

@Observable
class CheckInViewModel {
    var todayScore: Int?
    var weeklyScores: [Int] = []
    var questions: [(label: String, value: Double)] = []
    var isSubmitting = false
    var isLoading = false
    var error: String?

    /// Recovery Health Score weights (must sum to 1.0)
    /// Sobriety 30%, Engagement 25%, Emotional Health 20%, Connection 15%, Growth 10%
    static let scoreWeights: [String: Double] = [
        "sobriety": 0.30,
        "engagement": 0.25,
        "emotionalHealth": 0.20,
        "connection": 0.15,
        "growth": 0.10
    ]

    static let questionLabels: [String] = [
        "sobriety",
        "engagement",
        "emotionalHealth",
        "connection",
        "growth"
    ]

    // MARK: - Loading

    func loadLatest() async {
        isLoading = true
        error = nil

        do {
            // TODO: Replace MockData fallback with real repository calls
            try await loadFromMockData()
        } catch {
            self.error = "Unable to load check-in data. Please try again."
        }

        isLoading = false
    }

    // MARK: - Actions

    func submit(answers: [String: Int]) async throws {
        isSubmitting = true
        defer { isSubmitting = false }

        let score = calculateScore(from: answers)

        // TODO: Persist to repository
        todayScore = score
        weeklyScores.append(score)
        if weeklyScores.count > 7 {
            weeklyScores = Array(weeklyScores.suffix(7))
        }
    }

    // MARK: - Calculations

    /// Calculate a weighted score (0-100) from answers where each answer is 0-10
    func calculateScore(from answers: [String: Int]) -> Int {
        guard !answers.isEmpty else { return 0 }

        var weightedSum = 0.0
        var totalWeight = 0.0

        for (key, value) in answers {
            let weight = Self.scoreWeights[key] ?? (1.0 / Double(answers.count))
            weightedSum += Double(value) * weight
            totalWeight += weight
        }

        guard totalWeight > 0 else { return 0 }

        // Normalize: answers are 0-10, score is 0-100
        let normalized = (weightedSum / totalWeight) * 10.0
        return Int(normalized.rounded())
    }

    // MARK: - Private

    private func loadFromMockData() async throws {
        weeklyScores = MockData.checkInScores
        todayScore = MockData.checkInScores.last

        questions = Self.questionLabels.map { label in
            (label: label, value: Double(MockData.checkInScores.last ?? 0) / 10.0)
        }
    }
}
