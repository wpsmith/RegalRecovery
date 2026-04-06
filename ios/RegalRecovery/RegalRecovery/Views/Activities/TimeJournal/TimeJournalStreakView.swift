import SwiftUI

// MARK: - Milestone

/// Defines streak milestone thresholds and their clinically framed affirmation text.
private struct StreakMilestone {
    let days: Int
    let label: String
    let affirmation: String

    static let all: [StreakMilestone] = [
        StreakMilestone(
            days: 7,
            label: "1 Week",
            affirmation: "One week of honest accountability. Each slot filled is a step toward trust."
        ),
        StreakMilestone(
            days: 30,
            label: "1 Month",
            affirmation: "A month of daily transparency. Your consistency tells a story of commitment."
        ),
        StreakMilestone(
            days: 60,
            label: "2 Months",
            affirmation: "Two months of meticulous honesty. The discipline of journaling is building new neural pathways."
        ),
        StreakMilestone(
            days: 90,
            label: "3 Months",
            affirmation: "Three months \u{2014} a full quarter of radical transparency. This is no longer a task; it\u{2019}s becoming who you are."
        ),
        StreakMilestone(
            days: 180,
            label: "6 Months",
            affirmation: "Half a year of daily accountability. Your journal is a living testimony of recovery."
        ),
        StreakMilestone(
            days: 365,
            label: "1 Year",
            affirmation: "One year. Every slot, every emotion, every honest entry \u{2014} proof that recovery is real."
        ),
    ]

    /// Returns the milestone matching the given day count, if any.
    static func matching(days: Int) -> StreakMilestone? {
        all.first { $0.days == days }
    }

    /// Returns the next milestone after the given day count, if any.
    static func next(after days: Int) -> StreakMilestone? {
        all.first { $0.days > days }
    }
}

// MARK: - TimeJournalStreakView

struct TimeJournalStreakView: View {
    let currentStreakDays: Int
    let longestStreakDays: Int
    let completionScore: Double
    let nextMilestone: (days: Int, label: String)?

    /// Whether the current streak exactly hits a milestone threshold.
    private var activeMilestone: StreakMilestone? {
        StreakMilestone.matching(days: currentStreakDays)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Streak counter + completion ring
            HStack(spacing: 24) {
                streakCounter
                completionRing
            }
            .padding(.horizontal, 16)

            // Trust partner indicator
            trustPartnerIndicator

            // Milestone celebration (if applicable)
            if let milestone = activeMilestone {
                milestoneCelebration(milestone)
            }

            // Next milestone hint
            if let next = nextMilestone, activeMilestone == nil {
                nextMilestoneHint(days: next.days, label: next.label)
            }

            // Longest streak
            longestStreakRow
        }
        .padding(.vertical, 16)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Subviews

    private var streakCounter: some View {
        VStack(spacing: 4) {
            Text("\(currentStreakDays)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.rrPrimary)
                .contentTransition(.numericText())

            Text(currentStreakDays == 1 ? "day" : "days")
                .font(RRFont.caption)
                .foregroundStyle(.rrTextSecondary)

            Text("Current Streak")
                .font(RRFont.caption2)
                .foregroundStyle(.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var completionRing: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.rrTextSecondary.opacity(0.2), lineWidth: 6)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: completionScore)
                    .stroke(
                        completionScoreColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: completionScore)

                Text("\(Int(completionScore * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.rrText)
            }

            Text("Completion")
                .font(RRFont.caption2)
                .foregroundStyle(.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var completionScoreColor: Color {
        switch completionScore {
        case 0.8...1.0: return .rrSuccess
        case 0.5..<0.8: return .orange
        default: return .rrDestructive
        }
    }

    private var trustPartnerIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.caption)
                .foregroundStyle(.rrPrimary)
            Text("Shared with Trust Partners")
                .font(RRFont.caption)
                .foregroundStyle(.rrTextSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.rrPrimary.opacity(0.1))
        .clipShape(Capsule())
    }

    private func milestoneCelebration(_ milestone: StreakMilestone) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                Text("Milestone: \(milestone.label)")
                    .font(RRFont.headline)
                    .foregroundStyle(.rrText)
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }

            Text(milestone.affirmation)
                .font(RRFont.body)
                .foregroundStyle(.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.rrPrimary.opacity(0.08))
        )
        .padding(.horizontal, 16)
    }

    private func nextMilestoneHint(days: Int, label: String) -> some View {
        let remaining = days - currentStreakDays
        return HStack(spacing: 6) {
            Image(systemName: "flag.fill")
                .font(.caption)
                .foregroundStyle(.rrSecondary)
            Text("\(remaining) day\(remaining == 1 ? "" : "s") to \(label)")
                .font(RRFont.caption)
                .foregroundStyle(.rrTextSecondary)
        }
    }

    private var longestStreakRow: some View {
        HStack {
            Text("Longest Streak")
                .font(RRFont.caption)
                .foregroundStyle(.rrTextSecondary)
            Spacer()
            Text("\(longestStreakDays) day\(longestStreakDays == 1 ? "" : "s")")
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.rrText)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            TimeJournalStreakView(
                currentStreakDays: 7,
                longestStreakDays: 14,
                completionScore: 0.85,
                nextMilestone: (days: 30, label: "1 Month")
            )

            TimeJournalStreakView(
                currentStreakDays: 90,
                longestStreakDays: 90,
                completionScore: 0.92,
                nextMilestone: (days: 180, label: "6 Months")
            )

            TimeJournalStreakView(
                currentStreakDays: 3,
                longestStreakDays: 45,
                completionScore: 0.40,
                nextMilestone: (days: 7, label: "1 Week")
            )
        }
        .padding()
    }
    .background(Color.rrBackground)
}
