import SwiftUI
import SwiftData

struct ActivitiesListView: View {
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var journals: [RRJournalEntry]
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
    @Query(filter: #Predicate<RRBowtieSession> { $0.status == "draft" },
           sort: \RRBowtieSession.modifiedAt, order: .reverse)
    private var bowtieDrafts: [RRBowtieSession]
    @Query(filter: #Predicate<RRBowtieSession> { $0.status == "complete" },
           sort: \RRBowtieSession.modifiedAt, order: .reverse)
    private var completedBowties: [RRBowtieSession]

    // MARK: - Subtitle Helpers

    private var morningSubtitle: String {
        if let latest = commitments.first(where: { $0.type == "morning" && Calendar.current.isDateInToday($0.date) }) {
            let time = latest.date.formatted(date: .omitted, time: .shortened)
            return String(localized: "Today, \(time) \u{2713}")
        }
        return String(localized: "Pending")
    }

    private var eveningSubtitle: String {
        if let latest = commitments.first(where: { $0.type == "evening" && Calendar.current.isDateInToday($0.date) }) {
            let time = latest.date.formatted(date: .omitted, time: .shortened)
            return String(localized: "Today, \(time) \u{2713}")
        }
        return String(localized: "Pending")
    }

    private var journalSubtitle: String {
        if let latest = journals.first {
            return relativeDay(latest.date)
        }
        return String(localized: "No entries")
    }

    private var timeJournalSubtitle: String {
        let todayBlocks = timeBlocks.filter { Calendar.current.isDateInToday($0.date) }
        if !todayBlocks.isEmpty {
            return String(localized: "Today, \(todayBlocks.count) entries")
        }
        if let latest = timeBlocks.first {
            let dayBlocks = timeBlocks.filter { Calendar.current.isDate($0.date, inSameDayAs: latest.date) }
            return String(localized: "\(relativeDay(latest.date)), \(dayBlocks.count) entries")
        }
        return String(localized: "No entries")
    }

    private var fasterSubtitle: String {
        if let latest = fasterEntries.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? String(localized: "Today") : relativeDay(latest.date)
            let stage = FASTERStage(rawValue: latest.stage) ?? .restoration
            return String(localized: "\(dayLabel), \(stage.name)")
        }
        return String(localized: "No entries")
    }

    private var urgeSubtitle: String {
        if let latest = urgeLogs.first {
            return String(localized: "\(relativeDay(latest.date)), \(latest.intensity)/10")
        }
        return String(localized: "No entries")
    }

    private var moodSubtitle: String {
        if let latest = moodEntries.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? "Today" : relativeDay(latest.date)
            var parts = [latest.primaryMood]
            if let secondary = latest.secondaryEmotion { parts.append(secondary) }
            return "\(dayLabel), \(parts.joined(separator: " · "))"
        }
        return String(localized: "No entries")
    }

    private var gratitudeSubtitle: String {
        if let latest = gratitudeEntries.first {
            return String(localized: "\(relativeDay(latest.date)), \(latest.items.count) items")
        }
        return String(localized: "No entries")
    }

    private var prayerSubtitle: String {
        if let latest = prayerLogs.first {
            let dayLabel = Calendar.current.isDateInToday(latest.date) ? String(localized: "Today") : relativeDay(latest.date)
            return String(localized: "\(dayLabel), \(latest.durationMinutes) min")
        }
        return String(localized: "No entries")
    }

    private var exerciseSubtitle: String {
        if let latest = exerciseLogs.first {
            return String(localized: "\(relativeDay(latest.date)), \(latest.durationMinutes) min \(latest.exerciseType)")
        }
        return String(localized: "No entries")
    }

    private var phoneCallSubtitle: String {
        if let latest = phoneCallLogs.first {
            return String(localized: "\(relativeDay(latest.date)), \(latest.contactName), \(latest.durationMinutes) min")
        }
        return String(localized: "No entries")
    }

    private var meetingSubtitle: String {
        if let latest = meetingLogs.first {
            return String(localized: "\(relativeDay(latest.date)), \(latest.meetingName)")
        }
        return String(localized: "No entries")
    }

    private var fanosSubtitle: String {
        if let latest = spouseCheckIns.first(where: { $0.framework == "FANOS" }) {
            return relativeDay(latest.date)
        }
        return String(localized: "No entries")
    }

    private var fitnapSubtitle: String {
        if let latest = spouseCheckIns.first(where: { $0.framework == "FITNAP" }) {
            return relativeDay(latest.date)
        }
        return String(localized: "No entries")
    }

    private var stepWorkSubtitle: String {
        if let inProgress = stepWork.first(where: { $0.status == "inProgress" }) {
            return String(localized: "Step \(inProgress.stepNumber) \u{2014} In Progress")
        }
        if let lastComplete = stepWork.last(where: { $0.status == "complete" }) {
            return String(localized: "Step \(lastComplete.stepNumber) \u{2014} Complete")
        }
        return String(localized: "Not started")
    }

    private var goalsSubtitle: String {
        let completed = goals.filter { $0.isComplete }.count
        return String(localized: "\(completed) of \(goals.count) complete")
    }

    private var affirmationSubtitle: String {
        if let latest = affirmationFavorites.first {
            let dayLabel = Calendar.current.isDateInToday(latest.createdAt) ? String(localized: "Today") : relativeDay(latest.createdAt)
            return dayLabel
        }
        return String(localized: "No entries")
    }

    private var motivationsSubtitle: String {
        if let user = users.first {
            return user.motivations.joined(separator: ", ")
        }
        return String(localized: "Faith, Family, Freedom")
    }

    private var bowtieSubtitle: String {
        if let draft = bowtieDrafts.first {
            let dayLabel = Calendar.current.isDateInToday(draft.modifiedAt) ? String(localized: "Today") : relativeDay(draft.modifiedAt)
            return String(localized: "\(dayLabel) — Draft")
        }
        if let latest = completedBowties.first {
            return relativeDay(latest.completedAt ?? latest.modifiedAt)
        }
        return String(localized: "Emotional awareness tool")
    }

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return String(localized: "Today") }
        if cal.isDateInYesterday(date) { return String(localized: "Yesterday") }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return String(localized: "\(days) days ago")
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
                            title: String(localized: "Morning Commitment"),
                            subtitle: morningSubtitle
                        )
                    }

                    NavigationLink {
                        EveningReviewView()
                    } label: {
                        RRActivityRow(
                            icon: "moon.stars.fill",
                            iconColor: .rrPrimary,
                            title: String(localized: "Evening Review"),
                            subtitle: eveningSubtitle
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
                            title: String(localized: "Journaling"),
                            subtitle: journalSubtitle
                        )
                    }

                    NavigationLink {
                        FASTERScaleView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.fasterScale.icon,
                            iconColor: ActivityType.fasterScale.iconColor,
                            title: String(localized: "FASTER Scale"),
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
                                title: String(localized: "Time Journal"),
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
                                title: String(localized: "Post-Mortem"),
                                subtitle: String(localized: "142 days ago")
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
                            title: String(localized: "Urge Log"),
                            subtitle: urgeSubtitle
                        )
                    }

                    NavigationLink {
                        MoodRatingView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.mood.icon,
                            iconColor: ActivityType.mood.iconColor,
                            title: String(localized: "Mood"),
                            subtitle: moodSubtitle
                        )
                    }

                    NavigationLink {
                        GratitudeListView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.gratitude.icon,
                            iconColor: ActivityType.gratitude.iconColor,
                            title: String(localized: "Gratitude"),
                            subtitle: gratitudeSubtitle
                        )
                    }

                    NavigationLink {
                        PrayerLogView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.prayer.icon,
                            iconColor: ActivityType.prayer.iconColor,
                            title: String(localized: "Prayer"),
                            subtitle: prayerSubtitle
                        )
                    }

                    NavigationLink {
                        ExerciseLogView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.exercise.icon,
                            iconColor: ActivityType.exercise.iconColor,
                            title: String(localized: "Exercise"),
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
                            title: String(localized: "Phone Calls"),
                            subtitle: phoneCallSubtitle
                        )
                    }

                    NavigationLink {
                        MeetingsAttendedView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.meetingsAttended.icon,
                            iconColor: ActivityType.meetingsAttended.iconColor,
                            title: String(localized: "Meetings Attended"),
                            subtitle: meetingSubtitle
                        )
                    }

                    NavigationLink {
                        FANOSCheckInView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.fanos.icon,
                            iconColor: ActivityType.fanos.iconColor,
                            title: String(localized: "FANOS Check-in"),
                            subtitle: fanosSubtitle
                        )
                    }

                    NavigationLink {
                        FITNAPCheckInView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.fitnap.icon,
                            iconColor: ActivityType.fitnap.iconColor,
                            title: String(localized: "FITNAP Check-in"),
                            subtitle: fitnapSubtitle
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
                            title: String(localized: "12-Step Work"),
                            subtitle: stepWorkSubtitle
                        )
                    }

                    NavigationLink {
                        WeeklyGoalsView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.weeklyGoals.icon,
                            iconColor: ActivityType.weeklyGoals.iconColor,
                            title: String(localized: "Weekly Goals"),
                            subtitle: goalsSubtitle
                        )
                    }

                    NavigationLink {
                        AffirmationPackPickerView()
                    } label: {
                        RRActivityRow(
                            icon: ActivityType.affirmationLog.icon,
                            iconColor: ActivityType.affirmationLog.iconColor,
                            title: String(localized: "Affirmation Log"),
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
                                title: String(localized: "3 Circles"),
                                subtitle: String(localized: "Boundary Tool")
                            )
                        }
                    }

                    if isFlagEnabled("activity.bowtie") {
                        NavigationLink {
                            BowtieSessionView()
                        } label: {
                            HStack {
                                RRActivityRow(
                                    icon: "asset:bowtie.icon",
                                    iconColor: .rrPrimary,
                                    title: String(localized: "Bowtie Diagram"),
                                    subtitle: bowtieSubtitle
                                )
                                if !bowtieDrafts.isEmpty {
                                    Text("Continue")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.rrPrimary.opacity(0.15))
                                        .foregroundStyle(.rrPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    RRActivityRow(
                        icon: "sparkles",
                        iconColor: .rrSecondary,
                        title: String(localized: "Motivations"),
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
