import SwiftUI
import SwiftData

struct BowtieHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<RRUserRole> { !$0.isArchived }, sort: \RRUserRole.sortOrder)
    private var roles: [RRUserRole]

    @State private var viewModel = BowtieHistoryViewModel()
    @State private var sessionToDelete: RRBowtieSession?
    @State private var showDeleteConfirmation = false
    @State private var selectedSession: RRBowtieSession?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rrBackground.ignoresSafeArea()

                if viewModel.completedSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle(String(localized: "Bowtie History"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        BowtieInsightsView(viewModel: viewModel, roles: roles)
                    } label: {
                        Text(String(localized: "Insights"))
                    }
                    .disabled(viewModel.completedSessions.isEmpty)
                }
            }
            .confirmationDialog(
                String(localized: "Delete this Bowtie session?"),
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "Delete"), role: .destructive) {
                    if let session = sessionToDelete {
                        viewModel.deleteSession(session, context: modelContext)
                        sessionToDelete = nil
                    }
                }
            } message: {
                Text(String(localized: "This action cannot be undone."))
            }
            .navigationDestination(item: $selectedSession) { session in
                BowtieSessionDetailView(session: session)
            }
            .onAppear {
                viewModel.loadSessions(context: modelContext)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bowtie")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.5))
                .accessibilityHidden(true)

            Text(String(localized: "The Bowtie Diagram helps you see what's really going on inside \u{2014} the subtle wounds and unmet needs that build up beneath the surface. When you're ready, this is where you start building that awareness."))
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }

    // MARK: - Session List

    private var sessionListView: some View {
        List {
            ForEach(viewModel.completedSessions, id: \.id) { session in
                Button {
                    selectedSession = session
                } label: {
                    sessionRow(session)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        sessionToDelete = session
                        showDeleteConfirmation = true
                    } label: {
                        Label(String(localized: "Delete"), systemImage: "trash")
                    }
                }
                .listRowBackground(Color.rrSurface)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Session Row

    private func sessionRow(_ session: RRBowtieSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date
            HStack {
                Text(formattedDate(session.completedAt ?? session.modifiedAt))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            // Roles examined
            Text(rolesLabel(for: session))
                .font(RRFont.subheadline)
                .foregroundStyle(Color.rrTextSecondary)

            // Tally summary
            HStack(spacing: 16) {
                tallySummaryLabel(
                    label: String(localized: "Past"),
                    is_: session.pastInsignificanceTotal,
                    ic: session.pastIncompetenceTotal,
                    im: session.pastImpotenceTotal
                )
                tallySummaryLabel(
                    label: String(localized: "Future"),
                    is_: session.futureInsignificanceTotal,
                    ic: session.futureIncompetenceTotal,
                    im: session.futureImpotenceTotal
                )
            }

            // Processing status
            let totalMarkers = session.markers.count
            let processed = session.processedMarkerCount
            Text(String(localized: "\(processed) of \(totalMarkers) processed"))
                .font(RRFont.caption)
                .foregroundStyle(processed == totalMarkers ? Color.rrPrimary : Color.rrTextSecondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Double tap to view session details"))
    }

    private func tallySummaryLabel(label: String, is_: Int, ic: Int, im: Int) -> some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            Text("Is \(is_)")
                .font(RRFont.caption)
                .foregroundStyle(ThreeIType.insignificance.color)
            Text("Ic \(ic)")
                .font(RRFont.caption)
                .foregroundStyle(ThreeIType.incompetence.color)
            Text("Im \(im)")
                .font(RRFont.caption)
                .foregroundStyle(ThreeIType.impotence.color)
        }
    }

    private func rolesLabel(for session: RRBowtieSession) -> String {
        let roleIds = session.selectedRoleIds
        let matchedRoles = roles.filter { roleIds.contains($0.id) }
        let labels = matchedRoles.prefix(3).map(\.label)

        if matchedRoles.count > 3 {
            return labels.joined(separator: ", ") + " +\(matchedRoles.count - 3) more"
        }
        if labels.isEmpty {
            return String(localized: "\(roleIds.count) roles")
        }
        return labels.joined(separator: ", ")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Session Detail (Read-Only Wrapper)

private struct BowtieSessionDetailView: View {
    let session: RRBowtieSession

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<RRUserRole> { !$0.isArchived }, sort: \RRUserRole.sortOrder)
    private var roles: [RRUserRole]
    @Query(sort: \RRKnownEmotionalTrigger.createdAt) private var triggers: [RRKnownEmotionalTrigger]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Tallies Card
                BowtieTalliesCard(
                    pastInsignificance: session.pastInsignificanceTotal,
                    pastIncompetence: session.pastIncompetenceTotal,
                    pastImpotence: session.pastImpotenceTotal,
                    futureInsignificance: session.futureInsignificanceTotal,
                    futureIncompetence: session.futureIncompetenceTotal,
                    futureImpotence: session.futureImpotenceTotal
                )

                // Past Markers
                if !session.pastMarkers.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Past 48 Hours"))
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            ForEach(session.pastMarkers, id: \.id) { marker in
                                markerRow(marker)
                            }
                        }
                    }
                }

                // Future Markers
                if !session.futureMarkers.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(String(localized: "Next 48 Hours"))
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            ForEach(session.futureMarkers, id: \.id) { marker in
                                markerRow(marker)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle(String(localized: "Session Details"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func markerRow(_ marker: RRBowtieMarker) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                let roleName = roles.first(where: { $0.id == marker.roleId })?.label ?? String(localized: "Unknown Role")
                Text(roleName)
                    .font(RRFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrText)

                Spacer()

                Text(marker.bowtieSide.labelForInterval(marker.timeIntervalHours))
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            HStack(spacing: 8) {
                ForEach(marker.iActivations) { activation in
                    HStack(spacing: 3) {
                        Image(systemName: activation.iType.icon)
                            .font(.caption2)
                            .foregroundStyle(activation.iType.color)
                        Text("\(activation.iType.displayName) \(activation.intensity)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            }

            if let desc = marker.briefDescription, !desc.isEmpty {
                Text(desc)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .lineLimit(2)
            }

            if marker.isProcessed {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.rrPrimary)
                    Text(String(localized: "Processed"))
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrPrimary)
                }
            }

            Divider()
        }
    }
}
