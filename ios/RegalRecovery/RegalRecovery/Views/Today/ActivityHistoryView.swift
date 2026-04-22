import SwiftUI
import SwiftData

struct ActivityHistoryView: View {
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var journals: [RRJournalEntry]
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var fasterEntries: [RRFASTEREntry]
    @Query(sort: \RRUrgeLog.date, order: .reverse) private var urgeLogs: [RRUrgeLog]
    @Query(sort: \RRMoodEntry.date, order: .reverse) private var moodEntries: [RRMoodEntry]
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var gratitudeEntries: [RRGratitudeEntry]
    @Query(sort: \RRPrayerLog.date, order: .reverse) private var prayerLogs: [RRPrayerLog]
    @Query(sort: \RRExerciseLog.date, order: .reverse) private var exerciseLogs: [RRExerciseLog]
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var phoneCallLogs: [RRPhoneCallLog]
    @Query(sort: \RRMeetingLog.date, order: .reverse) private var meetingLogs: [RRMeetingLog]
    @Query(sort: \RRSpouseCheckIn.date, order: .reverse) private var spouseCheckIns: [RRSpouseCheckIn]

    @State private var displayLimit = 50

    private var allActivities: [(date: Date, item: RecentActivity)] {
        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short

        var all: [(date: Date, item: RecentActivity)] = []

        for c in commitments {
            let label = c.type == "morning" ? "Morning Commitment" : "Evening Review"
            let icon = c.type == "morning" ? "sunrise.fill" : "moon.stars.fill"
            let color: Color = c.type == "morning" ? .rrSecondary : .rrPrimary
            all.append((c.date, RecentActivity(title: label, detail: "Completed", time: fmt.localizedString(for: c.date, relativeTo: Date()), icon: icon, iconColor: color, sourceType: c.type == "morning" ? .morningCommitment : .eveningReview, sourceId: c.id)))
        }
        for m in moodEntries {
            let detail: String = {
                var parts = [m.primaryMood]
                if let secondary = m.secondaryEmotion { parts.append(secondary) }
                return parts.joined(separator: " · ")
            }()
            all.append((m.date, RecentActivity(title: "Mood Check-In", detail: detail, time: fmt.localizedString(for: m.date, relativeTo: Date()), icon: ActivityType.mood.icon, iconColor: ActivityType.mood.iconColor, sourceType: .mood, sourceId: m.id)))
        }
        for p in prayerLogs {
            all.append((p.date, RecentActivity(title: "Prayer", detail: p.prayerType, time: fmt.localizedString(for: p.date, relativeTo: Date()), icon: ActivityType.prayer.icon, iconColor: ActivityType.prayer.iconColor, sourceType: .prayer, sourceId: p.id)))
        }
        for e in exerciseLogs {
            all.append((e.date, RecentActivity(title: "Exercise", detail: "\(e.durationMinutes) min \(e.exerciseType)", time: fmt.localizedString(for: e.date, relativeTo: Date()), icon: ActivityType.exercise.icon, iconColor: ActivityType.exercise.iconColor, sourceType: .exercise, sourceId: e.id)))
        }
        for f in fasterEntries {
            let stage = FASTERStage(rawValue: f.stage) ?? .forgettingPriorities
            all.append((f.date, RecentActivity(title: "FASTER Scale", detail: stage.name, time: fmt.localizedString(for: f.date, relativeTo: Date()), icon: ActivityType.fasterScale.icon, iconColor: stage.color, sourceType: .fasterScale, sourceId: f.id)))
        }
        for j in journals {
            let snippet = String(j.content.prefix(40))
            all.append((j.date, RecentActivity(title: "Journal", detail: snippet, time: fmt.localizedString(for: j.date, relativeTo: Date()), icon: ActivityType.journal.icon, iconColor: ActivityType.journal.iconColor, sourceType: .journal, sourceId: j.id)))
        }
        for g in gratitudeEntries {
            all.append((g.date, RecentActivity(title: "Gratitude", detail: "\(g.items.count) items", time: fmt.localizedString(for: g.date, relativeTo: Date()), icon: ActivityType.gratitude.icon, iconColor: ActivityType.gratitude.iconColor, sourceType: .gratitude, sourceId: g.id)))
        }
        for u in urgeLogs {
            all.append((u.date, RecentActivity(title: "Urge Log", detail: "\(u.intensity)/10", time: fmt.localizedString(for: u.date, relativeTo: Date()), icon: ActivityType.urgeLog.icon, iconColor: ActivityType.urgeLog.iconColor, sourceType: .urgeLog, sourceId: u.id)))
        }
        for pc in phoneCallLogs {
            all.append((pc.date, RecentActivity(title: "Phone Call", detail: "\(pc.contactName), \(pc.durationMinutes) min", time: fmt.localizedString(for: pc.date, relativeTo: Date()), icon: ActivityType.phoneCalls.icon, iconColor: ActivityType.phoneCalls.iconColor, sourceType: .phoneCall, sourceId: pc.id)))
        }
        for ml in meetingLogs {
            all.append((ml.date, RecentActivity(title: "Meeting", detail: ml.meetingName, time: fmt.localizedString(for: ml.date, relativeTo: Date()), icon: ActivityType.meetingsAttended.icon, iconColor: ActivityType.meetingsAttended.iconColor, sourceType: .meeting, sourceId: ml.id)))
        }
        for sc in spouseCheckIns {
            let type: ActivityType = sc.framework == "FANOS" ? .fanos : .fitnap
            all.append((sc.date, RecentActivity(title: "\(sc.framework) Check-in", detail: sc.framework, time: fmt.localizedString(for: sc.date, relativeTo: Date()), icon: type.icon, iconColor: type.iconColor, sourceType: sc.framework == "FANOS" ? .fanos : .fitnap, sourceId: sc.id)))
        }

        return all.sorted { $0.date > $1.date }
    }

    private var groupedActivities: [(key: String, items: [RecentActivity])] {
        let limited = allActivities.prefix(displayLimit)
        let calendar = Calendar.current

        let grouped = Dictionary(grouping: limited) { entry -> String in
            if calendar.isDateInToday(entry.date) { return String(localized: "Today") }
            if calendar.isDateInYesterday(entry.date) { return String(localized: "Yesterday") }
            return entry.date.formatted(.dateTime.month(.wide).day().year())
        }

        // Sort groups by the latest date in each group (descending)
        return grouped
            .map { (key: $0.key, items: $0.value.map(\.item)) }
            .sorted { lhs, rhs in
                let lhsDate = limited.first(where: { sectionLabel(for: $0.date) == lhs.key })?.date ?? .distantPast
                let rhsDate = limited.first(where: { sectionLabel(for: $0.date) == rhs.key })?.date ?? .distantPast
                return lhsDate > rhsDate
            }
    }

    private func sectionLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return String(localized: "Today") }
        if calendar.isDateInYesterday(date) { return String(localized: "Yesterday") }
        return date.formatted(.dateTime.month(.wide).day().year())
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if allActivities.isEmpty {
                    emptyState
                } else {
                    ForEach(groupedActivities, id: \.key) { section in
                        Text(section.key)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                            .padding(.top, 20)
                            .padding(.bottom, 8)

                        ForEach(section.items) { activity in
                            NavigationLink {
                                ActivityDetailView(activity: activity)
                            } label: {
                                RecentActivityRow(activity: activity)
                            }
                            .buttonStyle(.plain)

                            if activity.id != section.items.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }

                    if allActivities.count > displayLimit {
                        Button {
                            displayLimit += 50
                        } label: {
                            Text("Load More")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.rrBackground)
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.large)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrPrimary.opacity(0.5))

            Text("No activities yet")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            Text("Activities you log will appear here.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        ActivityHistoryView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
