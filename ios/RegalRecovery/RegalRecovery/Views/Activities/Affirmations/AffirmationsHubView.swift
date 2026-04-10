import SwiftUI
import SwiftData

/// Main landing page for the Affirmations experience.
///
/// Displays today's morning/evening session status, cumulative progress metrics,
/// and recent favorites. Launches full-screen session flows for morning and evening
/// practice. Per AFF-FR-004 this view NEVER displays streaks or consecutive-day
/// counters -- only cumulative totals.
struct AffirmationsHubView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: AffirmationSessionViewModel
    @State private var showMorningSession = false
    @State private var showEveningSession = false

    // Query today's affirmation activities
    @Query(
        filter: #Predicate<RRActivity> { $0.activityType == "Affirmation Log" },
        sort: \RRActivity.date,
        order: .reverse
    )
    private var sessions: [RRActivity]

    @Query(sort: \RRAffirmationFavorite.createdAt, order: .reverse)
    private var favorites: [RRAffirmationFavorite]

    private let calendar = Calendar.current

    private var hasMorningToday: Bool {
        sessions.contains { calendar.isDateInToday($0.date) }
    }

    private var hasEveningToday: Bool {
        // More than one session today means evening is also done
        sessions.filter { calendar.isDateInToday($0.date) }.count > 1
    }

    init() {
        let apiClient = AffirmationsAPIClient(
            apiClient: ServiceContainer.shared.apiClient
        )
        _viewModel = State(initialValue: AffirmationSessionViewModel(apiClient: apiClient))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                todaysPractice
                progressSummary
                recentFavorites
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.rrBackground)
        .task { await viewModel.loadHubData() }
        .fullScreenCover(isPresented: $showMorningSession) {
            MorningSessionFlowView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $showEveningSession) {
            EveningReflectionFlowView(viewModel: viewModel)
        }
        .onChange(of: showMorningSession) { _, isShowing in
            if !isShowing { Task { await viewModel.loadHubData() } }
        }
        .onChange(of: showEveningSession) { _, isShowing in
            if !isShowing { Task { await viewModel.loadHubData() } }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("Affirmations")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
            Spacer()
            if let level = viewModel.levelInfo {
                RRBadge(
                    text: "Level \(level.currentLevel) \u{00B7} \(level.levelName ?? "")",
                    color: .rrPrimary
                )
            }
        }
    }

    // MARK: - Today's Practice

    private var todaysPractice: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Practice")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                // Morning row
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(.orange)
                    Text("Morning Session")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    if hasMorningToday {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Done")
                                .font(RRFont.caption2)
                        }
                        .foregroundStyle(Color.rrSuccess)
                    } else {
                        Button("Start") {
                            showMorningSession = true
                        }
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.rrPrimary)
                        .clipShape(Capsule())
                    }
                }

                Divider()

                // Evening row
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(.indigo)
                    Text("Evening Reflection")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    if hasEveningToday {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Done")
                                .font(RRFont.caption2)
                        }
                        .foregroundStyle(Color.rrSuccess)
                    } else {
                        Button("Start") {
                            showEveningSession = true
                        }
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.rrPrimary)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Progress Summary

    @ViewBuilder
    private var progressSummary: some View {
        if let progress = viewModel.progress {
            HStack(spacing: 12) {
                statCard(value: progress.totalSessions ?? 0, label: "Sessions")
                statCard(value: progress.totalAffirmationsPracticed ?? 0, label: "Affirmations")
                statCard(value: progress.totalFavorites ?? 0, label: "Favorites")
            }
        }
    }

    private func statCard(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.rrText)
            Text(label)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Recent Favorites

    @ViewBuilder
    private var recentFavorites: some View {
        if !favorites.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Favorites")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                ForEach(favorites.prefix(5)) { fav in
                    RRCard {
                        Text("\"\(fav.affirmationText)\"")
                            .font(RRFont.body)
                            .italic()
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AffirmationsHubView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
