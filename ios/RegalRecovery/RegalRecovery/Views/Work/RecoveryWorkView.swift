import SwiftData
import SwiftUI

struct RecoveryWorkView: View {
    @Environment(\.modelContext) private var modelContext

    // MARK: - Queries for today's status
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
    @Query(filter: #Predicate<RRActivity> { $0.activityType == "Affirmation Log" },
           sort: \RRActivity.date, order: .reverse)
    private var affirmationSessions: [RRActivity]

    @State private var showUrgeSurfingTimer = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(WorkTileCategory.allCases, id: \.self) { category in
                        workSection(for: category)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.rrBackground)
            .navigationTitle("Recovery Work")
        }
        .fullScreenCover(isPresented: $showUrgeSurfingTimer) {
            UrgeSurfingTimerView(isPresented: $showUrgeSurfingTimer)
        }
    }

    // MARK: - Section

    @ViewBuilder
    private func workSection(for category: WorkTileCategory) -> some View {
        let tiles = RecoveryWorkViewModel.allTiles.filter { $0.category == category }
        if !tiles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .font(.subheadline)
                        .foregroundStyle(Color.rrPrimary)
                    Text(category.rawValue)
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)
                }
                .padding(.leading, 4)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(tiles) { tile in
                        tileContent(for: tile)
                    }
                }
            }
        }
    }

    // MARK: - Tile Content

    @ViewBuilder
    private func tileContent(for tile: WorkTileItem) -> some View {
        let status = tileStatus(for: tile)

        if tile.implemented && tile.isEnabled {
            // Clickable tile — navigates or presents
            if tile.activityTypeKey == "urgeSurfingTimer" {
                Button {
                    showUrgeSurfingTimer = true
                } label: {
                    WorkTileView(tile: tile, status: status)
                }
                .buttonStyle(.plain)
            } else {
                NavigationLink {
                    destinationView(for: tile)
                } label: {
                    WorkTileView(tile: tile, status: status)
                }
                .buttonStyle(.plain)
            }
        } else {
            // Non-clickable: disabled flag or not implemented
            WorkTileView(tile: tile, status: .none)
        }
    }

    // MARK: - Status Lookup

    private func tileStatus(for tile: WorkTileItem) -> TileStatus {
        RecoveryWorkViewModel.todayStatus(
            for: tile,
            commitments: commitments,
            journals: journals,
            timeBlocks: timeBlocks,
            fasterEntries: fasterEntries,
            urgeLogs: urgeLogs,
            moodEntries: moodEntries,
            gratitudeEntries: gratitudeEntries,
            prayerLogs: prayerLogs,
            exerciseLogs: exerciseLogs,
            phoneCallLogs: phoneCallLogs,
            meetingLogs: meetingLogs,
            spouseCheckIns: spouseCheckIns,
            stepWork: stepWork,
            goals: goals,
            affirmationSessions: affirmationSessions
        )
    }

    // MARK: - Navigation

    @ViewBuilder
    private func destinationView(for tile: WorkTileItem) -> some View {
        switch tile.activityTypeKey {
        case ActivityType.sobrietyCommitment.rawValue:
            MorningCommitmentView()
        case ActivityType.prayer.rawValue:
            PrayerLogView()
        case ActivityType.exercise.rawValue:
            ExerciseLogView()
        case ActivityType.journal.rawValue:
            JournalView()
        case ActivityType.mood.rawValue:
            MoodRatingView()
        case ActivityType.gratitude.rawValue:
            GratitudeTabView()
        case ActivityType.fasterScale.rawValue:
            FASTERScaleView()
        case "devotional":
            DevotionalView()
        case ActivityType.affirmationLog.rawValue:
            AffirmationLogView()
        case ActivityType.phoneCalls.rawValue:
            PhoneCallLogView()
        case ActivityType.meetingsAttended.rawValue:
            MeetingsAttendedView()
        case "fanos":
            FANOSCheckInView()
        case "fitnap":
            FITNAPCheckInView()
        case "personCheckInSpouse":
            SpouseCheckInPrepView()
        case ActivityType.weeklyGoals.rawValue:
            WeeklyGoalsView()
        case ActivityType.stepWork.rawValue:
            StepWorkView()
        case ActivityType.timeJournal.rawValue:
            TimeJournalDailyView()
        case ActivityType.postMortem.rawValue:
            PostMortemView()
        case ActivityType.urgeLog.rawValue:
            UrgeLogView()
        case "supportNetwork":
            SupportNetworkView()
        case "recoveryPlan":
            RecoveryPlanSetupView()
        case "threeCircles":
            ThreeCirclesView()
        case "analytics":
            RecoveryProgressView()
        case "contentResources":
            ContentTabView()
        case "pci":
            Text("PCI - Coming Soon")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)
        case "integrityInventory":
            EveningReviewView()
        case "memoryVerseReview":
            Text("Memory Verse - Coming Soon")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)
        default:
            Text("Coming Soon")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }
}

// MARK: - Work Tile View

private struct WorkTileView: View {
    let tile: WorkTileItem
    let status: TileStatus

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: tile.icon)
                    .font(.title2)
                    .foregroundStyle(tileIconColor)
                    .frame(width: 40, height: 40)
                    .background(tileIconBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Status indicator
                if status.checkmarkVisible {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white, Color.rrSuccess)
                        .offset(x: 4, y: -4)
                } else if let subtitle = status.subtitle {
                    Text(subtitle)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(tile.iconColor)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -6)
                }
            }

            Text(tile.title)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(tileTitleColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(minHeight: 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(tileBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(tileBorder, lineWidth: 1)
        )
        .opacity(tile.implemented ? 1.0 : 0.5)
    }

    private var tileIconColor: Color {
        if !tile.implemented { return .gray }
        if !tile.isEnabled { return tile.iconColor.opacity(0.4) }
        return tile.iconColor
    }

    private var tileIconBackground: Color {
        if !tile.implemented { return .gray.opacity(0.08) }
        if !tile.isEnabled { return tile.iconColor.opacity(0.06) }
        return tile.iconColor.opacity(0.12)
    }

    private var tileTitleColor: Color {
        if !tile.implemented { return .rrTextSecondary }
        if !tile.isEnabled { return .rrTextSecondary }
        return .rrText
    }

    private var tileBackground: Color {
        if !tile.implemented { return Color.rrSurface.opacity(0.6) }
        return Color.rrSurface
    }

    private var tileBorder: Color {
        if !tile.implemented { return .clear }
        if !tile.isEnabled { return Color.rrTextSecondary.opacity(0.15) }
        return Color.rrTextSecondary.opacity(0.1)
    }
}

#Preview {
    RecoveryWorkView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
