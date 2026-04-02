import Foundation

struct DailyScoreCalculator {

    /// Calculate the Daily Recovery Score (0-100).
    ///
    /// - Parameters:
    ///   - morningDone: Whether the Morning Commitment was completed.
    ///   - otherCompleted: Number of non-commitment activities completed.
    ///   - otherTotal: Total number of non-commitment activities planned.
    /// - Returns: Integer score from 0 to 100.
    static func calculate(morningDone: Bool, otherCompleted: Int, otherTotal: Int, morningInPlan: Bool = true) -> Int {
        if !morningInPlan {
            // Morning Commitment not in plan — all weight goes to other activities
            guard otherTotal > 0 else { return 0 }
            return min(100, Int(Double(otherCompleted) / Double(otherTotal) * 100.0))
        }
        let morningPoints = morningDone ? 20 : 0
        let otherPoints = otherTotal > 0
            ? Int(Double(otherCompleted) / Double(otherTotal) * 80.0)
            : 0
        return min(100, morningPoints + otherPoints)
    }

    /// Determine the score level for a given numeric score.
    static func level(for score: Int) -> DailyScoreLevel {
        DailyScoreLevel.level(for: score)
    }
}
