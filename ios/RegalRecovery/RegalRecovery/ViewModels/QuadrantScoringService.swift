import Foundation

struct QuadrantScoringService {

    static func balanceScore(body: Int, mind: Int, heart: Int, spirit: Int) -> Double {
        let mean = (Double(body) + Double(mind) + Double(heart) + Double(spirit)) / 4.0
        let variance = (
            pow(Double(body) - mean, 2) +
            pow(Double(mind) - mean, 2) +
            pow(Double(heart) - mean, 2) +
            pow(Double(spirit) - mean, 2)
        ) / 4.0
        let stdev = sqrt(variance)
        let score = (mean / 10.0) * (1.0 - (stdev / 4.5)) * 100.0
        return min(max(score, 0.0), 100.0)
    }

    static func wellnessLevel(body: Int, mind: Int, heart: Int, spirit: Int) -> WellnessLevel {
        let mean = (Double(body) + Double(mind) + Double(heart) + Double(spirit)) / 4.0
        let variance = (
            pow(Double(body) - mean, 2) +
            pow(Double(mind) - mean, 2) +
            pow(Double(heart) - mean, 2) +
            pow(Double(spirit) - mean, 2)
        ) / 4.0
        let stdev = sqrt(variance)

        if mean >= 8.0 && stdev <= 1.5 {
            return .flourishing
        } else if mean >= 6.0 {
            return .growing
        } else if mean >= 4.0 {
            return .rebuilding
        } else {
            return .struggling
        }
    }

    static func detectImbalances(body: Int, mind: Int, heart: Int, spirit: Int) -> [QuadrantType] {
        let scores: [(QuadrantType, Int)] = [
            (.body, body),
            (.mind, mind),
            (.heart, heart),
            (.spirit, spirit),
        ]
        return scores.compactMap { (quadrant, score) in
            let others = scores.filter { $0.0 != quadrant }.map { Double($0.1) }
            let meanOfOthers = others.reduce(0.0, +) / Double(others.count)
            return Double(score) <= meanOfOthers - 3.0 ? quadrant : nil
        }
    }

    static func weekStartDate(for date: Date) -> Date {
        var calendar = Calendar(identifier: .iso8601)
        calendar.firstWeekday = 2
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components)!
    }

    static func isoWeekComponents(for date: Date) -> (weekNumber: Int, year: Int) {
        let calendar = Calendar(identifier: .iso8601)
        let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)
        return (weekNumber: components.weekOfYear ?? 0, year: components.yearForWeekOfYear ?? 0)
    }
}
