import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var users: [RRUser]
    @Query private var streaks: [RRStreak]
    @Query(sort: \RRMilestone.days) private var milestones: [RRMilestone]
    @Query(sort: \RRActivity.timestamp, order: .reverse) private var activities: [RRActivity]
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRCheckIn.date, order: .reverse) private var checkIns: [RRCheckIn]
    @Query(sort: \RRMoodEntry.date, order: .reverse) private var moodEntries: [RRMoodEntry]
    @Query(sort: \RRPrayerLog.date, order: .reverse) private var prayerLogs: [RRPrayerLog]
    @Query(sort: \RRExerciseLog.date, order: .reverse) private var exerciseLogs: [RRExerciseLog]
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var fasterEntries: [RRFASTEREntry]
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var journals: [RRJournalEntry]
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var gratitudeEntries: [RRGratitudeEntry]
    @Query(sort: \RRUrgeLog.date, order: .reverse) private var urgeLogs: [RRUrgeLog]
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var phoneCalls: [RRPhoneCallLog]
    @Query(sort: \RRMeetingLog.date, order: .reverse) private var meetingLogs: [RRMeetingLog]

    private var user: RRUser? { users.first }

    private var primaryStreak: RRStreak? { streaks.first }

    private var streakData: StreakData? {
        guard let streak = primaryStreak else { return nil }
        let currentDays = streak.currentDays
        let sobrietyDate = streak.addiction?.sobrietyDate ?? Date()
        let nextMilestone = StreakViewModel.milestoneThresholds.first(where: { $0 > currentDays }) ?? ((currentDays / 365) + 1) * 365
        return StreakData(
            currentDays: currentDays,
            sobrietyDate: sobrietyDate,
            longestStreak: streak.longestStreak,
            totalRelapses: streak.totalRelapses,
            nextMilestoneDays: nextMilestone,
            milestones: milestones.map { m in
                Milestone(days: m.days, dateEarned: m.dateEarned, scripture: m.scripture)
            }
        )
    }

    private var commitmentStatus: CommitmentStatus {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let todayCommitments = commitments.filter { calendar.startOfDay(for: $0.date) == todayStart }
        let morning = todayCommitments.first(where: { $0.type == "morning" })
        let evening = todayCommitments.first(where: { $0.type == "evening" })
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        return CommitmentStatus(
            morningComplete: morning?.completedAt != nil,
            morningTime: morning?.completedAt.map { timeFormatter.string(from: $0) },
            eveningComplete: evening?.completedAt != nil,
            eveningTime: evening?.completedAt.map { timeFormatter.string(from: $0) }
        )
    }

    private var recentActivities: [RecentActivity] {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short

        var all: [(date: Date, item: RecentActivity)] = []

        for c in commitments.prefix(3) {
            let label = c.type == "morning" ? "Morning Commitment" : "Evening Review"
            let icon = c.type == "morning" ? "sunrise.fill" : "moon.stars.fill"
            all.append((c.date, RecentActivity(title: label, detail: "Completed", time: fmt.localizedString(for: c.date, relativeTo: Date()), icon: icon, iconColor: c.type == "morning" ? .rrSecondary : .rrPrimary)))
        }
        for ci in checkIns.prefix(3) {
            all.append((ci.date, RecentActivity(title: "Recovery Check-in", detail: "Score: \(ci.score)", time: fmt.localizedString(for: ci.date, relativeTo: Date()), icon: "heart.text.clipboard", iconColor: .rrPrimary)))
        }
        for m in moodEntries.prefix(3) {
            let emoji = m.score >= 7 ? "😊" : m.score >= 5 ? "😐" : "😟"
            all.append((m.date, RecentActivity(title: "Mood", detail: "\(m.score)/10 \(emoji)", time: fmt.localizedString(for: m.date, relativeTo: Date()), icon: "face.smiling", iconColor: .yellow)))
        }
        for p in prayerLogs.prefix(3) {
            all.append((p.date, RecentActivity(title: "Prayer", detail: "\(p.durationMinutes) min", time: fmt.localizedString(for: p.date, relativeTo: Date()), icon: "hands.and.sparkles.fill", iconColor: .rrPrimary)))
        }
        for e in exerciseLogs.prefix(3) {
            all.append((e.date, RecentActivity(title: "Exercise", detail: "\(e.durationMinutes) min \(e.exerciseType)", time: fmt.localizedString(for: e.date, relativeTo: Date()), icon: "figure.run", iconColor: .blue)))
        }
        for f in fasterEntries.prefix(3) {
            let stage = FASTERStage(rawValue: f.stage) ?? .forgettingPriorities
            all.append((f.date, RecentActivity(title: "FASTER Scale", detail: stage.name, time: fmt.localizedString(for: f.date, relativeTo: Date()), icon: "gauge.with.needle", iconColor: stage.color)))
        }
        for j in journals.prefix(3) {
            let snippet = String(j.content.prefix(40))
            all.append((j.date, RecentActivity(title: "Journal", detail: snippet, time: fmt.localizedString(for: j.date, relativeTo: Date()), icon: "note.text", iconColor: .purple)))
        }
        for g in gratitudeEntries.prefix(2) {
            all.append((g.date, RecentActivity(title: "Gratitude", detail: "\(g.items.count) items", time: fmt.localizedString(for: g.date, relativeTo: Date()), icon: "leaf.fill", iconColor: .rrSuccess)))
        }
        for u in urgeLogs.prefix(2) {
            all.append((u.date, RecentActivity(title: "Urge Log", detail: "\(u.intensity)/10", time: fmt.localizedString(for: u.date, relativeTo: Date()), icon: "exclamationmark.triangle.fill", iconColor: .orange)))
        }
        for pc in phoneCalls.prefix(2) {
            all.append((pc.date, RecentActivity(title: "Phone Call", detail: "\(pc.contactName), \(pc.durationMinutes) min", time: fmt.localizedString(for: pc.date, relativeTo: Date()), icon: "phone.fill", iconColor: .green)))
        }
        for ml in meetingLogs.prefix(2) {
            all.append((ml.date, RecentActivity(title: "Meeting", detail: ml.meetingName, time: fmt.localizedString(for: ml.date, relativeTo: Date()), icon: "person.3.fill", iconColor: .rrPrimary)))
        }

        return all.sorted { $0.date > $1.date }.prefix(10).map(\.item)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let streak = streakData {
                        StreakHeroCard(streak: streak)
                    }

                    CommitmentsCard(status: commitmentStatus)

                    QuickActionsRow()

                    RecentActivityFeed(activities: recentActivities)

                    // MARK: - My Motivations
                    if let motivations = user?.motivations, !motivations.isEmpty {
                        RRSectionHeader(title: "My Motivations")

                        ForEach(motivations, id: \.self) { motivation in
                            RRCard {
                                HStack(spacing: 14) {
                                    Image(systemName: motivationIcon(for: motivation))
                                        .font(.title2)
                                        .foregroundStyle(Color.rrPrimary)
                                        .frame(width: 40, height: 40)
                                        .background(Color.rrPrimary.opacity(0.08))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(motivation)
                                            .font(.headline)
                                            .foregroundStyle(Color.rrText)
                                        Text(motivationQuote(for: motivation))
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }

                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.rrPrimary.opacity(0.08))
                            }
                        }
                    }

                    if let streak = streakData {
                        MilestoneBadgesRow(milestones: streak.milestones)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(Color.rrBackground)
        }
    }

    // MARK: - Motivation Helpers

    private func motivationIcon(for motivation: String) -> String {
        switch motivation {
        case "Faith":   return "cross.fill"
        case "Family":  return "figure.2.and.child.holdinghands"
        case "Freedom": return "bird.fill"
        default:        return "star.fill"
        }
    }

    private func motivationQuote(for motivation: String) -> String {
        switch motivation {
        case "Faith":   return "Trust in the Lord with all your heart. — Proverbs 3:5"
        case "Family":  return "The ones who matter most are counting on you."
        case "Freedom": return "It is for freedom that Christ has set us free. — Galatians 5:1"
        default:        return ""
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
