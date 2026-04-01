import Foundation

@Observable
class MoodViewModel {

    // MARK: - State

    var todayMood: Int?
    var weeklyMoods: [(date: Date, score: Int)] = []
    var averageMood: Double = 0
    var isLoading = false
    var error: String?

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await loadFromStorage()
            weeklyMoods = data.weekly
            todayMood = data.today
        } catch {
            // Fallback to mock data
            let calendar = Calendar.current
            let today = Date()
            let mockScores = [6, 5, 7, 8, 6, 8, 7]
            weeklyMoods = mockScores.enumerated().map { index, score in
                let date = calendar.date(byAdding: .day, value: -(6 - index), to: today)!
                return (date: date, score: score)
            }
            todayMood = 7
            self.error = error.localizedDescription
        }

        calculateAverage()
    }

    // MARK: - Submit

    func submit(score: Int) async throws {
        guard (1...10).contains(score) else {
            throw ActivityError.validationFailed("Mood score must be between 1 and 10.")
        }

        // TODO: Replace with repository save
        todayMood = score

        // Update weekly moods — replace today's entry or append
        let calendar = Calendar.current
        let today = Date()
        if let index = weeklyMoods.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
            weeklyMoods[index] = (date: today, score: score)
        } else {
            weeklyMoods.append((date: today, score: score))
        }

        // Keep only last 7 days
        weeklyMoods = weeklyMoods
            .sorted { $0.date < $1.date }
            .suffix(7)
            .map { $0 }

        calculateAverage()
    }

    // MARK: - Emoji

    func emojiForScore(_ score: Int) -> String {
        switch score {
        case 1...2: return "\u{1F622}"  // crying
        case 3...4: return "\u{1F61F}"  // worried
        case 5...6: return "\u{1F610}"  // neutral
        case 7...8: return "\u{1F60A}"  // smiling
        default:    return "\u{1F604}"  // grinning
        }
    }

    // MARK: - Private

    private func calculateAverage() {
        guard !weeklyMoods.isEmpty else {
            averageMood = 0
            return
        }
        averageMood = Double(weeklyMoods.reduce(0) { $0 + $1.score }) / Double(weeklyMoods.count)
    }

    private func loadFromStorage() async throws -> (today: Int?, weekly: [(date: Date, score: Int)]) {
        throw ActivityError.notImplemented
    }
}
