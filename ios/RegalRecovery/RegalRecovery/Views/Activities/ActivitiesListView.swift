import SwiftUI
import SwiftData

struct ActivitiesListView: View {
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRCheckIn.date, order: .reverse) private var checkIns: [RRCheckIn]
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var journals: [RRJournalEntry]
    @Query(sort: \RREmotionalJournal.date, order: .reverse) private var emotionalJournals: [RREmotionalJournal]
    @Query(sort: \RRTimeBlock.date, order: .reverse) private var timeBlocks: [RRTimeBlock]
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var fasterEntries: [RRFASTEREntry]
    @Query(sort: \RRUrgeLog.date, order: .reverse) private var urgeLogs: [RRUrgeLog]
    @Query(sort: \RRMoodEntry.date, order: .reverse) private var moodEntries: [RRMoodEntry]
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var gratitudeEntries: [RRGratitudeEntry]
    @Query(sort: \RRPrayerLog.date, order: .reverse) private var prayerLogs: [RRPrayerLog]
    @Query(sort: \RRExerciseLog.date, order: .reverse) private var exerciseLogs: [RRExerciseLog]
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var phoneCallLogs: [RRPhoneCallLog]
    @Query(sort: \RRMeetingLog.date, order: .reverse) private var meetingLogs: [RRMeetingLog]
    @Query(sort: \RRSpouseCheckIn.date, order: .reverse) private var spouseCheckIns: [RRSpouseCheckIn]
    @Query(sort: \RRStepWork.stepNumber) private var stepWork: [RRStepWork]
    @Query(sort: \RRGoal.title) private var goals: [RRGoal]
    @Query(sort: \RRAffirmationFavorite.createdAt, order: .reverse) private var affirmationFavorites: [RRAffirmationFavorite]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    // MARK: - Subtitle Helpers

    private var morningSubtitle: String {
        if let latest = commitments.first(where: { $0.type == "morning" && Calendar.current.isDateInToday($0.date) }) {
            let time = latest.date.formatted(date: .omitted, time: .shortened)
            return "Today, \(time) \u{2713}"
        }
        return "Pending"
    }

    private var eveningSubtitle: String {
        if let latest = commitments.first(where: { $0.type == "evening" && Calendar.current.isDateInToday($0.date) }) {
            let time = latest.date.formatted(date: .omitted, time: .shortened)
            return "Today, \(time) \u{2713}"
        }
        return "Pending"
    }

    private var checkInSubtitle: String {
        if let latest = checkIns.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? "Today" : relativeDay(latest.date)
            return "\(dayLabel), \(latest.score)/100"
        }
        return "No entries"
    }

    private var journalSubtitle: String {
        if let latest = journals.first {
            return relativeDay(latest.date)
        }
        return "No entries"
    }

    private var emotionalJournalSubtitle: String {
        if let latest = emotionalJournals.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? "Today" : relativeDay(latest.date)
            return "\(dayLabel), \(latest.emotion), \(latest.intensity)/10"
        }
        return "No entries"
    }

    private var timeJournalSubtitle: String {
        let todayBlocks = timeBlocks.filter { Calendar.current.isDateInToday($0.date) }
        if !todayBlocks.isEmpty {
            return "Today, \(todayBlocks.count) entries"
        }
        if let latest = timeBlocks.first {
            let dayBlocks = timeBlocks.filter { Calendar.current.isDate($0.date, inSameDayAs: latest.date) }
            return "\(relativeDay(latest.date)), \(dayBlocks.count) entries"
        }
        return "No entries"
    }

    private var fasterSubtitle: String {
        if let latest = fasterEntries.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? "Today" : relativeDay(latest.date)
            let stage = FASTERStage(rawValue: latest.stage) ?? .restoration
            return "\(dayLabel), \(stage.name)"
        }
        return "No entries"
    }

    private var urgeSubtitle: String {
        if let latest = urgeLogs.first {
            return "\(relativeDay(latest.date)), \(latest.intensity)/10"
        }
        return "No entries"
    }

    private var moodSubtitle: String {
        if let latest = moodEntries.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? "Today" : relativeDay(latest.date)
            let emoji: String = {
                switch latest.score {
                case 1...2: return "\u{1F622}"
                case 3...4: return "\u{1F61F}"
                case 5...6: return "\u{1F610}"
                case 7...8: return "\u{1F60A}"
                default: return "\u{1F604}"
                }
            }()
            return "\(dayLabel), \(latest.score)/10 \(emoji)"
        }
        return "No entries"
    }

    private var gratitudeSubtitle: String {
        if let latest = gratitudeEntries.first {
            return "\(relativeDay(latest.date)), \(latest.items.count) items"
        }
        return "No entries"
    }

    private var prayerSubtitle: String {
        if let latest = prayerLogs.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? "Today" : relativeDay(latest.date)
            return "\(dayLabel), \(latest.durationMinutes) min"
        }
        return "No entries"
    }

    private var exerciseSubtitle: String {
        if let latest = exerciseLogs.first {
            return "\(relativeDay(latest.date)), \(latest.durationMinutes) min \(latest.exerciseType)"
        }
        return "No entries"
    }

    private var phoneCallSubtitle: String {
        if let latest = phoneCallLogs.first {
            return "\(relativeDay(latest.date)), \(latest.contactName), \(latest.durationMinutes) min"
        }
        return "No entries"
    }

    private var meetingSubtitle: String {
        if let latest = meetingLogs.first {
            return "\(relativeDay(latest.date)), \(latest.meetingName)"
        }
        return "No entries"
    }

    private var spouseSubtitle: String {
        if let latest = spouseCheckIns.first {
            return "\(relativeDay(latest.date)), \(latest.framework)"
        }
        return "No entries"
    }

    private var stepWorkSubtitle: String {
        if let inProgress = stepWork.first(where: { $0.status == "inProgress" }) {
            return "Step \(inProgress.stepNumber) \u{2014} In Progress"
        }
        if let lastComplete = stepWork.last(where: { $0.status == "complete" }) {
            return "Step \(lastComplete.stepNumber) \u{2014} Complete"
        }
        return "Not started"
    }

    private var goalsSubtitle: String {
        let completed = goals.filter { $0.isComplete }.count
        return "\(completed) of \(goals.count) complete"
    }

    private var affirmationSubtitle: String {
        if let latest = affirmationFavorites.first {
            let dayLabel = Calendar.current.isDateInToday(latest.createdAt) ? "Today" : relativeDay(latest.createdAt)
            return dayLabel
        }
        return "No entries"
    }

    private var motivationsSubtitle: String {
        if let user = users.first {
            return user.motivations.joined(separator: ", ")
        }
        return "Faith, Family, Freedom"
    }

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

    // MARK: - Feature Flag Helpers

    private func isFlagEnabled(_ key: String) -> Bool {
        FeatureFlagStore.shared.isEnabled(key)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        MorningCommitmentView()
                    } label: {
                        RRActivityRow(
                            icon: "sunrise.fill",
                            iconColor: .rrSecondary,
                            title: "Morning Commitment",
                            subtitle: morningSubtitle
                        )
                    }

                    NavigationLink {
                        EveningReviewView()
                    } label: {
                        RRActivityRow(
                            icon: "moon.stars.fill",
                            iconColor: .rrPrimary,
                            title: "Evening Review",
                            subtitle: eveningSubtitle
                        )
                    }

                    NavigationLink {
                        RecoveryCheckInView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.recoveryCheckIn.icon,
                            iconColor: ActivityType.recoveryCheckIn.iconColor,
                            title: "Recovery Check-in",
                            subtitle: checkInSubtitle
                        )
                    }
                } header: {
                    Text(ActivitySection.sobrietyCommitment.rawValue)
                }

                Section {
                    NavigationLink {
                        JournalView()
                    } label: {
                        RRActivityRow(
                            icon: "book.fill",
                            iconColor: ActivityType.journal.iconColor,
                            title: "Journaling",
                            subtitle: journalSubtitle
                        )
                    }

                    NavigationLink {
                        FASTERScaleView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.fasterScale.icon,
                            iconColor: ActivityType.fasterScale.iconColor,
                            title: "FASTER Scale",
                            subtitle: fasterSubtitle
                        )
                    }

                    if isFlagEnabled("activity.time-journal") {
                        NavigationLink {
                            TimeJournalDailyView()
                        } label: {
                            RRActivityRow(
                                icon: "clock.fill",
                                iconColor: .purple,
                                title: "Time Journal",
                                subtitle: timeJournalSubtitle
                            )
                        }
                    }

                    if isFlagEnabled("feature.post-mortem") {
                        NavigationLink {
                            PostMortemView()
                        } label: {
                            RRActivityRow(
                                icon: ActivityType.postMortem.icon,
                                iconColor: ActivityType.postMortem.iconColor,
                                title: "Post-Mortem",
                                subtitle: "142 days ago"
                            )
                        }
                    }
                } header: {
                    Text(ActivitySection.journalingReflection.rawValue)
                }

                Section {
                    NavigationLink {
                        UrgeLogView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.urgeLog.icon,
                            iconColor: ActivityType.urgeLog.iconColor,
                            title: "Urge Log",
                            subtitle: urgeSubtitle
                        )
                    }

                    NavigationLink {
                        MoodRatingView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.mood.icon,
                            iconColor: ActivityType.mood.iconColor,
                            title: "Mood",
                            subtitle: moodSubtitle
                        )
                    }

                    NavigationLink {
                        GratitudeListView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.gratitude.icon,
                            iconColor: ActivityType.gratitude.iconColor,
                            title: "Gratitude",
                            subtitle: gratitudeSubtitle
                        )
                    }

                    NavigationLink {
                        PrayerLogView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.prayer.icon,
                            iconColor: ActivityType.prayer.iconColor,
                            title: "Prayer",
                            subtitle: prayerSubtitle
                        )
                    }

                    NavigationLink {
                        ExerciseLogView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.exercise.icon,
                            iconColor: ActivityType.exercise.iconColor,
                            title: "Exercise",
                            subtitle: exerciseSubtitle
                        )
                    }
                } header: {
                    Text(ActivitySection.selfCare.rawValue)
                }

                Section {
                    NavigationLink {
                        PhoneCallLogView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.phoneCalls.icon,
                            iconColor: ActivityType.phoneCalls.iconColor,
                            title: "Phone Calls",
                            subtitle: phoneCallSubtitle
                        )
                    }

                    NavigationLink {
                        MeetingsAttendedView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.meetingsAttended.icon,
                            iconColor: ActivityType.meetingsAttended.iconColor,
                            title: "Meetings Attended",
                            subtitle: meetingSubtitle
                        )
                    }

                    NavigationLink {
                        SpouseCheckInPrepView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.spouseCheckIn.icon,
                            iconColor: ActivityType.spouseCheckIn.iconColor,
                            title: "Spouse Check-in Prep",
                            subtitle: spouseSubtitle
                        )
                    }
                } header: {
                    Text(ActivitySection.connection.rawValue)
                }

                Section {
                    NavigationLink {
                        StepWorkView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.stepWork.icon,
                            iconColor: ActivityType.stepWork.iconColor,
                            title: "12-Step Work",
                            subtitle: stepWorkSubtitle
                        )
                    }

                    NavigationLink {
                        WeeklyGoalsView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.weeklyGoals.icon,
                            iconColor: ActivityType.weeklyGoals.iconColor,
                            title: "Weekly Goals",
                            subtitle: goalsSubtitle
                        )
                    }

                    NavigationLink {
                        AffirmationLogView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.affirmationLog.icon,
                            iconColor: ActivityType.affirmationLog.iconColor,
                            title: "Affirmation Log",
                            subtitle: affirmationSubtitle
                        )
                    }

                    if isFlagEnabled("feature.3circles") {
                        NavigationLink {
                            ThreeCirclesView()
                        } label: {
                            RRActivityRow(
                                icon: "circles.hexagongrid",
                                iconColor: .rrPrimary,
                                title: "3 Circles",
                                subtitle: "Boundary Tool"
                            )
                        }
                    }

                    RRActivityRow(
                        icon: "sparkles",
                        iconColor: .rrSecondary,
                        title: "Motivations",
                        subtitle: motivationsSubtitle
                    )
                } header: {
                    Text(ActivitySection.growth.rawValue)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    ActivitiesListView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
