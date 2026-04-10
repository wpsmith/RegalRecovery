import SwiftUI

// MARK: - Circle Set List View

/// Displays all user circle sets as cards with recovery area badge, status badge,
/// and per-circle item counts. Supports creating new sets and archiving via swipe.
struct CircleSetListView: View {

    // MARK: - State

    @State private var circleSets: [CircleSet] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showCreateSheet = false

    private let apiClient: ThreeCirclesAPIClient

    // MARK: - Init

    init(apiClient: ThreeCirclesAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if isLoading && circleSets.isEmpty {
                        loadingView
                    } else if let error {
                        errorView(error)
                    } else if circleSets.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(circleSets) { circleSet in
                            NavigationLink(value: circleSet.setId) {
                                CircleSetCard(circleSet: circleSet)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if circleSet.status != .archived {
                                    Button(role: .destructive) {
                                        Task { await archiveSet(circleSet) }
                                    } label: {
                                        Label("Archive", systemImage: "archivebox")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)

            // Create new FAB
            createButton
                .padding(24)
        }
        .navigationTitle("Three Circles")
        .navigationDestination(for: String.self) { setId in
            CircleSetDetailView(apiClient: apiClient, setId: setId)
        }
        .task {
            await loadSets()
        }
        .refreshable {
            await loadSets()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading your circles...")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.rrDestructive)
            Text(message)
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
            RRButton("Try Again", icon: "arrow.clockwise") {
                Task { await loadSets() }
            }
            .frame(width: 180)
        }
        .padding()
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "circles.hexagongrid")
                .font(.system(size: 56))
                .foregroundStyle(Color.rrPrimary.opacity(0.4))

            Text("Start Your Three Circles")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)

            Text("The Three Circles tool helps you define clear boundaries. Your inner circle contains behaviors to avoid, the middle circle holds warning signs, and the outer circle captures healthy practices.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            RRButton("Create Your First Set", icon: "plus") {
                showCreateSheet = true
            }
            .frame(width: 260)
        }
        .padding(.vertical, 40)
    }

    private var createButton: some View {
        Button {
            showCreateSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.rrPrimary)
                .clipShape(Circle())
                .shadow(color: Color.rrPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Create new circle set")
        .accessibilityHint("Opens a form to create a new set of three circles")
    }

    // MARK: - Actions

    private func loadSets() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response = try await apiClient.listCircleSets()
            circleSets = response.data
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func archiveSet(_ circleSet: CircleSet) async {
        do {
            try await apiClient.deleteCircleSet(setId: circleSet.setId)
            await loadSets()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Circle Set Card

/// Card for a single circle set showing name, recovery area, status, and item counts.
private struct CircleSetCard: View {

    let circleSet: CircleSet

    var body: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header row: name + badges
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(circleSet.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                            .lineLimit(2)

                        Text(circleSet.recoveryArea.displayName)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    statusBadge
                }

                Divider()

                // Item counts row
                HStack(spacing: 0) {
                    circleCountPill(
                        label: "Inner",
                        count: circleSet.innerCircle.count,
                        color: .rrDestructive
                    )
                    Spacer()
                    circleCountPill(
                        label: "Middle",
                        count: circleSet.middleCircle.count,
                        color: .orange
                    )
                    Spacer()
                    circleCountPill(
                        label: "Outer",
                        count: circleSet.outerCircle.count,
                        color: .rrSuccess
                    )
                }

                // Last modified
                HStack {
                    Spacer()
                    Text("Updated \(circleSet.modifiedAt.formatted(.relative(presentation: .named)))")
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(circleSet.name), \(circleSet.recoveryArea.displayName), \(circleSet.status.displayName)")
        .accessibilityHint("Double tap to view details")
    }

    private var statusBadge: some View {
        RRBadge(
            text: circleSet.status.displayName,
            color: statusColor
        )
    }

    private var statusColor: Color {
        switch circleSet.status {
        case .draft: return .gray
        case .active: return .rrPrimary
        case .archived: return .rrTextSecondary
        }
    }

    private func circleCountPill(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 6) {
            RRColorDot(color, size: 8)
            Text("\(count)")
                .font(RRFont.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrText)
            Text(label)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label) circle items")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        // Preview would use mock API client
        Text("CircleSetListView requires an API client")
    }
}
