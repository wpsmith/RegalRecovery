import SwiftUI
import SwiftData

/// The main Today tab view -- a personalized daily recovery plan execution view
/// that replaces the dashboard HomeView.
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = TodayViewModel()
    @State private var hideCompleted = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasPlan {
                    planContent
                } else {
                    emptyState
                }
            }
            .background(Color.rrBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        RecoveryPlanSetupView()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }
            .onAppear {
                viewModel.load(context: modelContext)
            }
        }
    }

    // MARK: - Plan Content

    private var planContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                greetingHeader
                scoreSummary
                recoveryWorkCards
                activityListHeader
                activityList
                sobrietyModule
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack {
            Text(viewModel.greeting)
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)

            Spacer()

            RRBadge(
                text: "Day \(viewModel.streakDays)",
                color: .rrPrimary
            )
        }
    }

    // MARK: - Score Summary

    private var scoreSummary: some View {
        RecoveryScoreSummaryView(
            score: viewModel.score,
            scoreLevel: viewModel.scoreLevel,
            totalCompleted: viewModel.totalCompleted,
            totalPlanned: viewModel.totalPlanned
        )
    }

    // MARK: - Sobriety Module

    @ViewBuilder
    private var sobrietyModule: some View {
        if !viewModel.sobrietyAddictions.isEmpty {
            SobrietyModuleView(
                addictions: viewModel.sobrietyAddictions,
                onResetSobriety: { addictionId, newDate in
                    viewModel.resetSobrietyDate(addictionId: addictionId, newDate: newDate, context: modelContext)
                }
            )
        }
    }

    // MARK: - Recovery Work Cards

    @ViewBuilder
    private var recoveryWorkCards: some View {
        if !viewModel.recoveryWorkCards.isEmpty {
            ForEach(viewModel.recoveryWorkCards.prefix(3)) { card in
                RecoveryWorkCardView(
                    card: card,
                    onStart: {
                        // Navigation handled by parent or future implementation
                    },
                    onDismiss: {
                        viewModel.recoveryWorkCards.removeAll { $0.id == card.id }
                    }
                )
            }

            if viewModel.recoveryWorkCards.count > 3 {
                NavigationLink {
                    RecoveryWorkView()
                } label: {
                    Text("View all recovery work")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
    }

    // MARK: - Activity List Header

    private var activityListHeader: some View {
        HStack {
            Text("Activities")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
            Spacer()
            Button {
                withAnimation { hideCompleted.toggle() }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: hideCompleted ? "eye.slash" : "eye")
                        .font(.caption)
                    Text(hideCompleted ? "Show completed" : "Hide completed")
                        .font(RRFont.caption)
                }
                .foregroundStyle(Color.rrPrimary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Activity List (flat chronological)

    private var activityList: some View {
        let visibleItems = hideCompleted
            ? viewModel.planItems.filter { $0.state != .completed && $0.state != .skipped }
            : viewModel.planItems

        return VStack(spacing: 4) {
            ForEach(visibleItems) { item in
                NavigationLink {
                    destinationView(for: item.activityType)
                } label: {
                    TodayActivityRow(
                        item: item,
                        onComplete: {
                            viewModel.completeActivity(item, context: modelContext)
                        },
                        onSkip: { reason in
                            viewModel.skipActivity(item, reason: reason)
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(Color.rrPrimary.opacity(0.6))

            Text("Set up your recovery plan to get started")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)

            Text("Your daily plan will appear here, showing each activity and tracking your progress throughout the day.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NavigationLink {
                RecoveryPlanSetupView()
            } label: {
                Text("Set Up My Plan")
                    .font(RRFont.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.rrPrimary)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - Activity Destination Mapping

    @ViewBuilder
    private func destinationView(for activityType: String) -> some View {
        switch activityType {
        case ActivityType.sobrietyCommitment.rawValue:
            MorningCommitmentView()
        case ActivityType.recoveryCheckIn.rawValue:
            RecoveryCheckInView()
        case ActivityType.prayer.rawValue:
            PrayerLogView()
        case ActivityType.exercise.rawValue:
            ExerciseLogView()
        case ActivityType.journal.rawValue:
            JournalView()
        case ActivityType.emotionalJournal.rawValue:
            EmotionalJournalView()
        case ActivityType.mood.rawValue:
            MoodRatingView()
        case ActivityType.gratitude.rawValue:
            GratitudeListView()
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
        case ActivityType.spouseCheckIn.rawValue:
            SpouseCheckInPrepView()
        case "pci":
            Text("PCI - Coming Soon")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)
        case ActivityType.weeklyGoals.rawValue:
            WeeklyGoalsView()
        case ActivityType.stepWork.rawValue:
            StepWorkView()
        case ActivityType.timeJournal.rawValue:
            TimeJournalView()
        case ActivityType.postMortem.rawValue:
            PostMortemView()
        case ActivityType.urgeLog.rawValue:
            UrgeLogView()
        default:
            Text("Activity")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
