import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var users: [RRUser]
    @Query private var streaks: [RRStreak]
    @Query(sort: \RRMilestone.days) private var milestones: [RRMilestone]
    @Query(sort: \RRActivity.timestamp, order: .reverse) private var activities: [RRActivity]
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRMoodEntry.date, order: .reverse) private var moodEntries: [RRMoodEntry]
    @Query(sort: \RRPrayerLog.date, order: .reverse) private var prayerLogs: [RRPrayerLog]
    @Query(sort: \RRExerciseLog.date, order: .reverse) private var exerciseLogs: [RRExerciseLog]
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var fasterEntries: [RRFASTEREntry]
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var journals: [RRJournalEntry]
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var gratitudeEntries: [RRGratitudeEntry]
    @Query(sort: \RRUrgeLog.date, order: .reverse) private var urgeLogs: [RRUrgeLog]
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var phoneCalls: [RRPhoneCallLog]
    @Query(sort: \RRMeetingLog.date, order: .reverse) private var meetingLogs: [RRMeetingLog]
    @Query(filter: #Predicate<RRActivity> { $0.activityType == "Affirmation Log" }, sort: \RRActivity.date, order: .reverse)
    private var affirmationSessions: [RRActivity]
    @Query(filter: #Predicate<RRVisionStatement> { $0.isCurrent == true })
    private var currentVisions: [RRVisionStatement]
    @Query(filter: #Predicate<RRBowtieSession> { $0.status == "complete" },
           sort: \RRBowtieSession.modifiedAt, order: .reverse)
    private var completedBowties: [RRBowtieSession]

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
            let label = c.type == "morning" ? String(localized: "Morning Commitment") : String(localized: "Evening Review")
            let icon = c.type == "morning" ? "sunrise.fill" : "moon.stars.fill"
            all.append((c.date, RecentActivity(title: label, detail: String(localized: "Completed"), time: fmt.localizedString(for: c.date, relativeTo: Date()), icon: icon, iconColor: c.type == "morning" ? .rrSecondary : .rrPrimary, sourceType: c.type == "morning" ? .morningCommitment : .eveningReview, sourceId: c.id)))
        }
        for m in moodEntries.prefix(3) {
            let detail: String = {
                var parts = [m.primaryMood]
                if let secondary = m.secondaryEmotion { parts.append(secondary) }
                return parts.joined(separator: " · ")
            }()
            all.append((m.date, RecentActivity(title: "Mood Check-In", detail: detail, time: fmt.localizedString(for: m.date, relativeTo: Date()), icon: "face.smiling", iconColor: .yellow, sourceType: .mood, sourceId: m.id)))
        }
        for p in prayerLogs.prefix(3) {
            all.append((p.date, RecentActivity(title: String(localized: "Prayer"), detail: "\(p.durationMinutes) min", time: fmt.localizedString(for: p.date, relativeTo: Date()), icon: "hands.and.sparkles.fill", iconColor: .rrPrimary, sourceType: .prayer, sourceId: p.id)))
        }
        for e in exerciseLogs.prefix(3) {
            all.append((e.date, RecentActivity(title: String(localized: "Exercise"), detail: "\(e.durationMinutes) min \(e.exerciseType)", time: fmt.localizedString(for: e.date, relativeTo: Date()), icon: "figure.run", iconColor: .blue, sourceType: .exercise, sourceId: e.id)))
        }
        for f in fasterEntries.prefix(3) {
            let stage = FASTERStage(rawValue: f.stage) ?? .restoration
            all.append((f.date, RecentActivity(title: String(localized: "FASTER Scale"), detail: stage.name, time: fmt.localizedString(for: f.date, relativeTo: Date()), icon: "gauge.with.needle", iconColor: stage.color, sourceType: .fasterScale, sourceId: f.id)))
        }
        for j in journals.prefix(3) {
            let snippet = String(j.content.prefix(40))
            all.append((j.date, RecentActivity(title: String(localized: "Journal"), detail: snippet, time: fmt.localizedString(for: j.date, relativeTo: Date()), icon: "note.text", iconColor: .purple, sourceType: .journal, sourceId: j.id)))
        }
        for g in gratitudeEntries.prefix(2) {
            all.append((g.date, RecentActivity(title: String(localized: "Gratitude"), detail: "\(g.items.count) items", time: fmt.localizedString(for: g.date, relativeTo: Date()), icon: "leaf.fill", iconColor: .rrSuccess, sourceType: .gratitude, sourceId: g.id)))
        }
        for u in urgeLogs.prefix(2) {
            all.append((u.date, RecentActivity(title: String(localized: "Urge Log"), detail: "\(u.intensity)/10", time: fmt.localizedString(for: u.date, relativeTo: Date()), icon: "exclamationmark.triangle.fill", iconColor: .orange, sourceType: .urgeLog, sourceId: u.id)))
        }
        for pc in phoneCalls.prefix(2) {
            all.append((pc.date, RecentActivity(title: String(localized: "Phone Call"), detail: "\(pc.contactName), \(pc.durationMinutes) min", time: fmt.localizedString(for: pc.date, relativeTo: Date()), icon: "phone.fill", iconColor: .green, sourceType: .phoneCall, sourceId: pc.id)))
        }
        for ml in meetingLogs.prefix(2) {
            all.append((ml.date, RecentActivity(title: String(localized: "Meeting"), detail: ml.meetingName, time: fmt.localizedString(for: ml.date, relativeTo: Date()), icon: "person.3.fill", iconColor: .rrPrimary, sourceType: .meeting, sourceId: ml.id)))
        }
        for a in affirmationSessions.prefix(3) {
            let cardsViewed: Int = {
                if case .int(let v) = a.data.data["cardsViewed"] { return v }
                return 0
            }()
            let totalCards: Int = {
                if case .int(let v) = a.data.data["totalCards"] { return v }
                return 0
            }()
            let durationSeconds: Int = {
                if case .int(let v) = a.data.data["durationSeconds"] { return v }
                return 0
            }()
            let detail = "\(cardsViewed)/\(totalCards) cards, \(formatDuration(durationSeconds))"
            all.append((a.date, RecentActivity(title: String(localized: "Affirmations"), detail: detail, time: fmt.localizedString(for: a.date, relativeTo: Date()), icon: ActivityType.affirmationLog.icon, iconColor: ActivityType.affirmationLog.iconColor)))
        }
        for b in completedBowties.prefix(3) {
            let completedDate = b.completedAt ?? b.modifiedAt
            let markerCount = b.markers.count
            let detail = String(localized: "\(markerCount) markers, \(b.selectedRoleIds.count) roles")
            all.append((completedDate, RecentActivity(title: String(localized: "Bowtie Diagram"), detail: detail, time: fmt.localizedString(for: completedDate, relativeTo: Date()), icon: "suit.diamond.fill", iconColor: .rrPrimary)))
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

                    if FeatureFlagStore.shared.isEnabled("feature.vision"),
                       let vision = currentVisions.first {
                        VisionCard(
                            identityStatement: vision.identityStatement,
                            scriptureReference: vision.scriptureReference
                        )
                    }

                    QuickActionsRow()

                    RecentActivityFeed(activities: recentActivities)

                    // MARK: - My Motivations
                    if let motivations = user?.motivations, !motivations.isEmpty {
                        RRSectionHeader(title: String(localized: "My Motivations"))

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

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(remainingSeconds)s"
    }

    private func motivationQuote(for motivation: String) -> String {
        switch motivation {
        case "Faith":   return String(localized: "Trust in the Lord with all your heart. — Proverbs 3:5")
        case "Family":  return String(localized: "The ones who matter most are counting on you.")
        case "Freedom": return String(localized: "It is for freedom that Christ has set us free. — Galatians 5:1")
        default:        return ""
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
