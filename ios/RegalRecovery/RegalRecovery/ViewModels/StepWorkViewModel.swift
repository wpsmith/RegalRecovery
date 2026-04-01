import Foundation

@Observable
class StepWorkViewModel {

    // MARK: - State

    var steps: [StepWorkItem] = []
    var currentStep: Int = 8
    var isLoading = false
    var error: String?

    // Answer editing state
    var answers: [Int: [String]] = [:]  // stepNumber -> [answers]

    // MARK: - Computed

    var completedSteps: Int {
        steps.filter { $0.status == .complete }.count
    }

    var currentStepItem: StepWorkItem? {
        steps.first { $0.id == currentStep }
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            steps = try await loadFromStorage()
        } catch {
            steps = MockData.stepWork
            self.error = error.localizedDescription
        }

        // Determine current step from data
        if let inProgress = steps.first(where: { $0.status == .inProgress }) {
            currentStep = inProgress.id
        }

        // Initialize answers for in-progress steps
        for step in steps where step.status == .inProgress {
            if answers[step.id] == nil {
                answers[step.id] = Array(repeating: "", count: step.reflectionQuestions.count)
            }
        }
    }

    // MARK: - Save Answer

    func saveAnswer(stepNumber: Int, questionIndex: Int, answer: String) async throws {
        guard let step = steps.first(where: { $0.id == stepNumber }) else {
            throw ActivityError.validationFailed("Step \(stepNumber) not found.")
        }
        guard step.status == .inProgress else {
            throw ActivityError.validationFailed("Step \(stepNumber) is not available for editing.")
        }
        guard questionIndex >= 0, questionIndex < step.reflectionQuestions.count else {
            throw ActivityError.validationFailed("Invalid question index.")
        }

        if answers[stepNumber] == nil {
            answers[stepNumber] = Array(repeating: "", count: step.reflectionQuestions.count)
        }
        answers[stepNumber]?[questionIndex] = answer

        // TODO: Replace with repository save

        // Update answered count
        let answeredCount = answers[stepNumber]?.filter { !$0.isEmpty }.count ?? 0
        updateStepAnsweredCount(stepNumber: stepNumber, count: answeredCount)
    }

    // MARK: - Complete Step

    func completeStep(stepNumber: Int) async throws {
        guard let stepIndex = steps.firstIndex(where: { $0.id == stepNumber }) else {
            throw ActivityError.validationFailed("Step \(stepNumber) not found.")
        }
        guard steps[stepIndex].status == .inProgress else {
            throw ActivityError.validationFailed("Step \(stepNumber) is not in progress.")
        }

        // Verify all questions are answered
        let step = steps[stepIndex]
        if !step.reflectionQuestions.isEmpty {
            let stepAnswers = answers[stepNumber] ?? []
            let answeredCount = stepAnswers.filter { !$0.isEmpty }.count
            guard answeredCount == step.reflectionQuestions.count else {
                throw ActivityError.validationFailed("Please answer all \(step.reflectionQuestions.count) questions before completing this step.")
            }
        }

        // TODO: Replace with repository save

        let completedStep = StepWorkItem(
            id: step.id,
            title: step.title,
            description: step.description,
            scripture: step.scripture,
            status: .complete,
            reflectionQuestions: step.reflectionQuestions,
            answeredCount: step.reflectionQuestions.count
        )
        steps[stepIndex] = completedStep

        unlockNext(after: stepNumber)
    }

    // MARK: - Unlock Next

    func unlockNext(after stepNumber: Int) {
        let nextStepNumber = stepNumber + 1
        guard let nextIndex = steps.firstIndex(where: { $0.id == nextStepNumber }),
              steps[nextIndex].status == .locked else {
            return
        }

        let next = steps[nextIndex]
        let unlockedStep = StepWorkItem(
            id: next.id,
            title: next.title,
            description: next.description,
            scripture: next.scripture,
            status: .inProgress,
            reflectionQuestions: next.reflectionQuestions,
            answeredCount: 0
        )
        steps[nextIndex] = unlockedStep
        currentStep = nextStepNumber

        // Initialize answers for newly unlocked step
        if !unlockedStep.reflectionQuestions.isEmpty {
            answers[nextStepNumber] = Array(repeating: "", count: unlockedStep.reflectionQuestions.count)
        }
    }

    // MARK: - Private

    private func updateStepAnsweredCount(stepNumber: Int, count: Int) {
        guard let index = steps.firstIndex(where: { $0.id == stepNumber }) else { return }
        let step = steps[index]
        let updated = StepWorkItem(
            id: step.id,
            title: step.title,
            description: step.description,
            scripture: step.scripture,
            status: step.status,
            reflectionQuestions: step.reflectionQuestions,
            answeredCount: count
        )
        steps[index] = updated
    }

    private func loadFromStorage() async throws -> [StepWorkItem] {
        throw ActivityError.notImplemented
    }
}
