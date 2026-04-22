import SwiftUI
import SwiftData

/// The main Today tab view -- a personalized daily recovery plan execution view
/// that replaces the dashboard HomeView.
struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = TodayViewModel()
    @State private var hideCompleted = false
    @State private var showFASTERMood = false
    @State private var quickActionsVM = QuickActionsViewModel()
    @State private var showFASTERFromQuickAction = false
    @State private var showQuickActionsCustomize = false

    // Time Journal SwiftData query for today's entries
    @Query private var allTimeJournalEntries: [RRTimeJournalEntry]

    private var todayTimeJournalEntries: [RRTimeJournalEntry] {
        allTimeJournalEntries.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var timeJournalMode: TimeJournalMode {
        if let first = todayTimeJournalEntries.first {
            return TimeJournalMode(rawValue: first.mode) ?? .t60
        }
        return .t60
    }

    private var timeJournalDayStatus: TimeJournalDayStatus {
        TimeJournalDayStatus.evaluate(
            entries: todayTimeJournalEntries,
            mode: timeJournalMode,
            forDate: Date()
        )
    }

    private var timeJournalLastUpdated: Date? {
        todayTimeJournalEntries.max(by: { $0.modifiedAt < $1.modifiedAt })?.modifiedAt
    }

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.hasAddictions {
                    addictionSelectorState
                } else if !viewModel.hasPlan {
                    noPlanState
                } else {
                    planContent
                }
            }
            .background(Color.rrBackground)
            .toolbar {
                if viewModel.hasAddictions {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            RecoveryPlanSetupView()
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.load(context: modelContext)
            }
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    viewModel.load(context: modelContext)
                    quickActionsVM.load(context: modelContext)
                }
            }
            .fullScreenCover(isPresented: $showFASTERMood) {
                FASTERCheckInFlowView()
            }
            .fullScreenCover(isPresented: $showFASTERFromQuickAction) {
                FASTERCheckInFlowView()
            }
            .sheet(isPresented: $showQuickActionsCustomize, onDismiss: {
                quickActionsVM.load(context: modelContext)
            }) {
                QuickActionsCustomizeView(viewModel: quickActionsVM)
            }
            .onReceive(NotificationCenter.default.publisher(for: .emergencyDismissed)) { _ in
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
                quickActions
                timeJournalCard
                gratitudeWidgetCard
                affirmationCard
                recoveryWorkCards
                activityListHeader
                activityList
                sobrietyModule
                todayActivityLogSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .onAppear {
            viewModel.load(context: modelContext)
            quickActionsVM.load(context: modelContext)
        }
    }

    // MARK: - Greeting Header

    private var greetingHeader: some View {
        HStack {
            Text(viewModel.greeting)
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)

            Spacer()

            if viewModel.hasPlan {
                RRBadge(
                    text: "Day \(viewModel.streakDays)",
                    color: .rrPrimary
                )
            }
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

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActions: some View {
        if FeatureFlagStore.shared.isEnabled("feature.quick-actions") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickActionsVM.items) { item in
                        if item.definition.presentationStyle == .fullScreenCover {
                            Button { showFASTERFromQuickAction = true } label: {
                                quickActionCard(
                                    icon: item.definition.icon,
                                    label: item.definition.shortTitle,
                                    color: item.definition.iconColor
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink {
                                ActivityDestinationView(activityType: item.definition.id)
                            } label: {
                                quickActionCard(
                                    icon: item.definition.icon,
                                    label: item.definition.shortTitle,
                                    color: item.definition.iconColor
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        showQuickActionsCustomize = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "pencil.circle")
                                .font(.title3)
                                .foregroundStyle(Color.rrTextSecondary)
                            Text(String(localized: "Edit"))
                                .font(RRFont.caption2)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .frame(width: 72, height: 64)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quickActionCard(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(label)
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrText)
        }
        .frame(width: 72, height: 64)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    // MARK: - Time Journal Card

    @ViewBuilder
    private var timeJournalCard: some View {
        if FeatureFlagStore.shared.isEnabled("activity.time-journal"),
           viewModel.planActivityTypes.contains(ActivityType.timeJournal.rawValue) {
            NavigationLink {
                TimeJournalDailyView()
            } label: {
                TimeJournalTodayCard(
                    filledCount: todayTimeJournalEntries.count,
                    totalSlots: timeJournalMode.slotsPerDay,
                    dayStatus: timeJournalDayStatus,
                    mode: timeJournalMode,
                    lastUpdated: timeJournalLastUpdated
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Gratitude Widget Card

    @ViewBuilder
    private var gratitudeWidgetCard: some View {
        if FeatureFlagStore.shared.isEnabled("activity.gratitude"),
           viewModel.planActivityTypes.contains(ActivityType.gratitude.rawValue) {
            GratitudeWidgetCard()
        }
    }

    // MARK: - Affirmation Card

    @ViewBuilder
    private var affirmationCard: some View {
        if FeatureFlagStore.shared.isEnabled("activity.affirmations"),
           viewModel.planActivityTypes.contains(ActivityType.affirmationLog.rawValue) {
            AffirmationTodayCard()
        }
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

    // MARK: - Today Activity Log

    @ViewBuilder
    private var todayActivityLogSection: some View {
        if FeatureFlagStore.shared.isEnabled("feature.activities") {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: String(localized: "Today's Activity Log"))

                if viewModel.todayActivityLog.isEmpty {
                    Text("No activities logged yet today")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.todayActivityLog) { activity in
                            if activity.sourceType != nil {
                                NavigationLink {
                                    ActivityDetailView(activity: activity)
                                } label: {
                                    RecentActivityRow(activity: activity)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            } else {
                                RecentActivityRow(activity: activity)
                            }

                            if activity.id != viewModel.todayActivityLog.last?.id {
                                Divider()
                                    .padding(.leading, 44)
                            }
                        }
                    }
                }

                NavigationLink {
                    ActivityHistoryView()
                } label: {
                    Text("View All History")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
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
                    ActivitiesListView()
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
                .font(RRFont.title3)
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

    // MARK: - Addiction Selector State (no addictions)

    private var addictionSelectorState: some View {
        AddictionSelectorView {
            viewModel.load(context: modelContext)
        }
    }

    // MARK: - No Plan State (has addictions, no plan)

    private var noPlanState: some View {
        ScrollView {
            VStack(spacing: 16) {
                greetingHeader
                SetupMyPlanCard()
                quickActions
                todayActivityLogSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Activity Destination Mapping

    @ViewBuilder
    private func destinationView(for activityType: String) -> some View {
        ActivityDestinationView(activityType: activityType)
    }
}

#Preview {
    TodayView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
