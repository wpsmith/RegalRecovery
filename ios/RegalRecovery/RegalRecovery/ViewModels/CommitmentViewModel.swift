import SwiftUI

@Observable
class CommitmentViewModel {
    var morningQuestions: [CommitmentQuestion] = []
    var eveningQuestions: [CommitmentQuestion] = []
    var morningCompletedAt: Date?
    var eveningCompletedAt: Date?
    var isLoading = false
    var error: String?

    // MARK: - Loading

    func loadToday() async {
        isLoading = true
        error = nil

        do {
            // TODO: Replace MockData fallback with real repository calls
            try await loadFromMockData()
        } catch {
            self.error = "Unable to load commitment data. Please try again."
        }

        isLoading = false
    }

    // MARK: - Actions

    func completeMorning(answers: [Bool]) async throws {
        // TODO: Persist to repository
        guard answers.count == morningQuestions.count else {
            throw CommitmentError.invalidAnswerCount
        }

        morningQuestions = zip(morningQuestions, answers).map { question, answer in
            CommitmentQuestion(text: question.text, isChecked: answer)
        }
        morningCompletedAt = Date()
    }

    func completeEvening(answers: [Bool]) async throws {
        // TODO: Persist to repository
        guard answers.count == eveningQuestions.count else {
            throw CommitmentError.invalidAnswerCount
        }

        eveningQuestions = zip(eveningQuestions, answers).map { question, answer in
            CommitmentQuestion(text: question.text, isChecked: answer)
        }
        eveningCompletedAt = Date()
    }

    // MARK: - Private

    private func loadFromMockData() async throws {
        morningQuestions = MockData.morningQuestions
        eveningQuestions = MockData.eveningQuestions

        let status = MockData.commitmentStatus
        if status.morningComplete {
            // Parse the mock time string into a Date for today
            morningCompletedAt = parseTodayTime(status.morningTime)
        }
        if status.eveningComplete {
            eveningCompletedAt = parseTodayTime(status.eveningTime)
        }
    }

    private func parseTodayTime(_ timeString: String?) -> Date? {
        guard let timeString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        guard let timePart = formatter.date(from: timeString) else { return nil }

        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: timePart)
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        todayComponents.hour = timeComponents.hour
        todayComponents.minute = timeComponents.minute
        return calendar.date(from: todayComponents)
    }
}

// MARK: - Errors

enum CommitmentError: LocalizedError {
    case invalidAnswerCount

    var errorDescription: String? {
        switch self {
        case .invalidAnswerCount:
            return "The number of answers does not match the number of questions."
        }
    }
}
