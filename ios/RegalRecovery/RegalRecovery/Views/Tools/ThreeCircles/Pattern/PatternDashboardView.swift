import SwiftUI

// MARK: - Pattern Dashboard View

/// Main pattern visualization screen.
///
/// Sections:
/// - Summary stats header (outer / middle / inner / no-checkin days)
/// - Period selector (segmented: 7d, 30d, 90d, 1y, all)
/// - Timeline visualization
/// - Drift alert banner (if active)
/// - Insight cards
/// - Share summary button
///
/// Framing rules (PRD 2):
/// - No "streak lost" language
/// - No percentages implying grading
/// - Descriptive framing only
struct PatternDashboardView: View {

    @Bindable var viewModel: PatternViewModel

    @State private var selectedDayEntry: TimelineEntry?
    @State private var showShareSheet = false
    @State private var showCrisisSupport = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Summary Stats Header
                summaryStatsHeader

                // MARK: - Period Selector
                periodSelector

                // MARK: - Drift Alert Banner
                ForEach(viewModel.activeDriftAlerts) { alert in
                    DriftAlertBannerView(
                        alert: alert,
                        onDismiss: {
                            Task { await viewModel.dismissDriftAlert(alert) }
                        }
                    )
                }

                // MARK: - Timeline
                TimelineView(
                    entries: viewModel.timelineData?.entries ?? [],
                    showMoodOverlay: viewModel.showMoodOverlay,
                    showUrgeOverlay: viewModel.showUrgeOverlay,
                    consecutiveOuterDays: viewModel.consecutiveOuterDays,
                    onDayTapped: { entry in
                        selectedDayEntry = entry
                    }
                )

                // MARK: - Framing Message
                if !viewModel.framingMessage.isEmpty {
                    Text(viewModel.framingMessage)
                        .font(RRFont.footnote)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }

                // MARK: - Overlay Toggles
                overlayToggles

                // MARK: - Insights
                if !viewModel.insights.isEmpty {
                    insightsSection
                }

                // MARK: - Actions
                actionButtons
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle("Patterns")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCrisisSupport = true
                } label: {
                    Text("I need support")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .sheet(item: $selectedDayEntry) { entry in
            dayDetailSheet(entry)
        }
        .sheet(isPresented: $showShareSheet) {
            SummaryShareView(summary: viewModel.patternSummary)
        }
        .sheet(isPresented: $showCrisisSupport) {
            CrisisSupportView()
        }
        .task {
            await viewModel.loadAll()
        }
    }

    // MARK: - Summary Stats Header

    private var summaryStatsHeader: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
            spacing: 12
        ) {
            statPill(
                value: viewModel.summary?.outerDays ?? 0,
                label: "Outer",
                color: .rrSuccess,
                icon: "circle"
            )
            statPill(
                value: viewModel.summary?.middleDays ?? 0,
                label: "Middle",
                color: .orange,
                icon: "circle.dashed"
            )
            statPill(
                value: viewModel.summary?.innerDays ?? 0,
                label: "Inner",
                color: .rrDestructive,
                icon: "circle.fill"
            )
            statPill(
                value: viewModel.summary?.noCheckinDays ?? 0,
                label: "No Log",
                color: Color.rrTextSecondary.opacity(0.5),
                icon: "minus.circle"
            )
        }
    }

    private func statPill(value: Int, label: String, color: Color, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.rrText)
            Text(label)
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        Picker("Period", selection: Binding(
            get: { viewModel.selectedPeriod },
            set: { newPeriod in
                Task { await viewModel.selectPeriod(newPeriod) }
            }
        )) {
            ForEach(TimelinePeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Overlay Toggles

    private var overlayToggles: some View {
        HStack(spacing: 16) {
            Toggle(isOn: Binding(
                get: { viewModel.showMoodOverlay },
                set: { _ in viewModel.toggleMoodOverlay() }
            )) {
                Label("Mood", systemImage: "face.smiling")
                    .font(RRFont.caption)
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .tint(viewModel.showMoodOverlay ? .rrPrimary : .rrTextSecondary)

            Toggle(isOn: Binding(
                get: { viewModel.showUrgeOverlay },
                set: { _ in viewModel.toggleUrgeOverlay() }
            )) {
                Label("Urges", systemImage: "bolt")
                    .font(RRFont.caption)
            }
            .toggleStyle(.button)
            .buttonStyle(.bordered)
            .tint(viewModel.showUrgeOverlay ? .rrPrimary : .rrTextSecondary)

            Spacer()
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Insights")

            ForEach(viewModel.insights) { insight in
                InsightCardView(
                    insight: insight,
                    onDismiss: {
                        viewModel.dismissInsight(insight)
                    }
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            RRButton("Share Summary", icon: "square.and.arrow.up") {
                showShareSheet = true
            }
        }
    }

    // MARK: - Day Detail Sheet

    private func dayDetailSheet(_ entry: TimelineEntry) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(entry.date)
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                if let circle = entry.circle {
                    HStack(spacing: 8) {
                        RRColorDot(circle.displayColor, size: 12)
                        Text(circle.displayName)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                    }
                } else {
                    Text("No check-in logged")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                if let details = entry.checkinDetails {
                    VStack(alignment: .leading, spacing: 12) {
                        if let mood = details.mood {
                            HStack {
                                Text("Mood:")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text("\(mood)/10")
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                        }

                        if let urge = details.urgeIntensity {
                            HStack {
                                Text("Urge Intensity:")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text("\(urge)/10")
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                        }

                        if let notes = details.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes:")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(notes)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.rrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer()
            }
            .padding()
            .background(Color.rrBackground)
            .navigationTitle("Day Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        selectedDayEntry = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - TimelineEntry Identifiable

extension TimelineEntry: @retroactive Identifiable {
    var id: String { date }
}

// MARK: - CircleType Display Color

extension CircleType {
    var displayColor: Color {
        switch self {
        case .inner: return .rrDestructive
        case .middle: return .orange
        case .outer: return .rrSuccess
        }
    }
}

#Preview {
    NavigationStack {
        PatternDashboardView(
            viewModel: PatternViewModel(
                apiClient: ThreeCirclesAPIClient(apiClient: APIClient.shared),
                setId: "preview-set"
            )
        )
    }
}
