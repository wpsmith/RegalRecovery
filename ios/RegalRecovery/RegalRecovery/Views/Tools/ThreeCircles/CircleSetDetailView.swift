import SwiftUI

// MARK: - Circle Set Detail View

/// Main detail view for a circle set with tab-based navigation:
/// Circles (visualization), Items (flat list), Versions (timeline), Share (sponsor review).
struct CircleSetDetailView: View {

    // MARK: - State

    @State private var viewModel: CircleSetDetailViewModel
    @State private var selectedTab: DetailTab = .circles
    @State private var showAddItemSheet = false
    @State private var showEditNameSheet = false
    @State private var editedName = ""

    enum DetailTab: String, CaseIterable {
        case circles = "Circles"
        case items = "Items"
        case versions = "Versions"
        case share = "Share"

        var icon: String {
            switch self {
            case .circles: return "circles.hexagongrid"
            case .items: return "list.bullet"
            case .versions: return "clock.arrow.circlepath"
            case .share: return "square.and.arrow.up"
            }
        }
    }

    private let apiClient: ThreeCirclesAPIClient

    // MARK: - Init

    init(apiClient: ThreeCirclesAPIClient, setId: String) {
        self.apiClient = apiClient
        _viewModel = State(initialValue: CircleSetDetailViewModel(apiClient: apiClient, setId: setId))
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.circleSetDetail == nil {
                loadingView
            } else if let error = viewModel.error, viewModel.circleSetDetail == nil {
                errorView(error)
            } else if viewModel.circleSetDetail != nil {
                tabBar
                tabContent
            }
        }
        .background(Color.rrBackground)
        .navigationTitle(viewModel.circleSetDetail?.name ?? "Circle Set")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                toolbarMenu
            }
        }
        .alert("Archive Circle Set?", isPresented: $viewModel.showArchiveConfirmation) {
            Button("Archive", role: .destructive) {
                Task { await viewModel.archive() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This circle set will be archived. You can find it later in your archived sets. Your version history will be preserved.")
        }
        .alert("Delete Item?", isPresented: $viewModel.showDeleteItemConfirmation) {
            Button("Delete", role: .destructive) {
                Task { await viewModel.confirmDeleteItem() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.itemPendingDeletion = nil
            }
        } message: {
            if viewModel.itemPendingDeletion?.circle == .inner {
                Text("This is an inner circle boundary. Removing it changes your bottom lines. Are you sure you want to proceed? Consider discussing this with your sponsor first.")
            } else {
                Text("Are you sure you want to remove \"\(viewModel.itemPendingDeletion?.behaviorName ?? "this item")\"?")
            }
        }
        .alert("Restore Version?", isPresented: $viewModel.showRestoreConfirmation) {
            Button("Restore", role: .destructive) {
                Task { await viewModel.confirmRestoreVersion() }
            }
            Button("Cancel", role: .cancel) {
                viewModel.versionPendingRestore = nil
            }
        } message: {
            Text("This will restore your circles to version \(viewModel.versionPendingRestore?.versionNumber ?? 0). A new version will be created so you can undo this change.")
        }
        .sheet(isPresented: $showAddItemSheet) {
            AddCircleItemView(apiClient: apiClient, viewModel: viewModel)
        }
        .sheet(isPresented: $showEditNameSheet) {
            editNameSheet
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.body)
                        Text(tab.rawValue)
                            .font(RRFont.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selectedTab == tab ? Color.rrPrimary : Color.rrTextSecondary)
                    .overlay(alignment: .bottom) {
                        if selectedTab == tab {
                            Rectangle()
                                .fill(Color.rrPrimary)
                                .frame(height: 2)
                        }
                    }
                }
                .accessibilityLabel("\(tab.rawValue) tab")
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .background(Color.rrSurface)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .circles:
            circlesTab
        case .items:
            itemsTab
        case .versions:
            versionsTab
        case .share:
            shareTab
        }
    }

    // MARK: - Circles Tab

    private var circlesTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let detail = viewModel.circleSetDetail {
                    CircleVisualizationView(
                        innerItems: detail.innerCircle,
                        middleItems: detail.middleCircle,
                        outerItems: detail.outerCircle
                    )

                    // Summary stats
                    HStack(spacing: 12) {
                        RRStatCard(
                            title: "Inner",
                            value: "\(detail.innerCircle.count)",
                            icon: "exclamationmark.octagon",
                            color: .rrDestructive
                        )
                        RRStatCard(
                            title: "Middle",
                            value: "\(detail.middleCircle.count)",
                            icon: "exclamationmark.triangle",
                            color: .orange
                        )
                        RRStatCard(
                            title: "Outer",
                            value: "\(detail.outerCircle.count)",
                            icon: "checkmark.shield",
                            color: .rrSuccess
                        )
                    }

                    // Status info
                    if let detail = viewModel.circleSetDetail {
                        statusInfoCard(detail)
                    }
                }
            }
            .padding()
        }
    }

    private func statusInfoCard(_ detail: CircleSetDetail) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                    Spacer()
                    RRBadge(text: detail.status.displayName, color: statusColor(for: detail.status))
                }

                if let versionNumber = detail.versionNumber {
                    HStack {
                        Text("Version")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text("v\(versionNumber)")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                    }
                }

                HStack {
                    Text("Recovery Area")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                    Spacer()
                    Text(detail.recoveryArea.displayName)
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrText)
                }

                if let committedAt = detail.committedAt {
                    HStack {
                        Text("Committed")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text(committedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
        }
    }

    // MARK: - Items Tab

    private var itemsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                circleItemSection(
                    title: "Inner Circle",
                    subtitle: "Hard boundaries — behaviors to completely avoid",
                    items: viewModel.innerItems,
                    color: .rrDestructive,
                    circleType: .inner
                )

                circleItemSection(
                    title: "Middle Circle",
                    subtitle: "Warning signs — not failure, but signals to act",
                    items: viewModel.middleItems,
                    color: .orange,
                    circleType: .middle
                )

                circleItemSection(
                    title: "Outer Circle",
                    subtitle: "Healthy behaviors — self-care and recovery practices",
                    items: viewModel.outerItems,
                    color: .rrSuccess,
                    circleType: .outer
                )

                // Add item button
                RRButton("Add Item", icon: "plus") {
                    showAddItemSheet = true
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private func circleItemSection(
        title: String,
        subtitle: String,
        items: [CircleItem],
        color: Color,
        circleType: CircleType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack(spacing: 8) {
                RRColorDot(color, size: 10)
                Text(title)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(items.count)")
                    .font(RRFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(subtitle)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            if items.isEmpty {
                RRCard {
                    HStack {
                        Spacer()
                        Text("No items yet")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                    }
                }
            } else {
                ForEach(items) { item in
                    NavigationLink {
                        CircleItemDetailView(
                            apiClient: apiClient,
                            viewModel: viewModel,
                            item: item
                        )
                    } label: {
                        CircleItemRow(item: item, color: color)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        itemContextMenu(item: item, currentCircle: circleType)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func itemContextMenu(item: CircleItem, currentCircle: CircleType) -> some View {
        // Move options
        ForEach(CircleType.allCases, id: \.self) { targetCircle in
            if targetCircle != currentCircle {
                Button {
                    Task {
                        await viewModel.moveItem(itemId: item.itemId, to: targetCircle)
                    }
                } label: {
                    Label("Move to \(targetCircle.displayName)", systemImage: "arrow.right.circle")
                }
            }
        }

        Divider()

        Button(role: .destructive) {
            viewModel.requestDeleteItem(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }

    // MARK: - Versions Tab

    private var versionsTab: some View {
        VersionHistoryView(apiClient: apiClient, viewModel: viewModel)
    }

    // MARK: - Share Tab

    private var shareTab: some View {
        SponsorReviewView(apiClient: apiClient, viewModel: viewModel)
    }

    // MARK: - Toolbar

    private var toolbarMenu: some View {
        Menu {
            Button {
                if let detail = viewModel.circleSetDetail {
                    editedName = detail.name
                    showEditNameSheet = true
                }
            } label: {
                Label("Edit Name", systemImage: "pencil")
            }

            if viewModel.circleSetDetail?.status == .draft {
                Button {
                    Task { await viewModel.commit() }
                } label: {
                    Label("Commit", systemImage: "checkmark.seal")
                }
                .disabled(!viewModel.canCommit)
            }

            Divider()

            if viewModel.circleSetDetail?.status != .archived {
                Button(role: .destructive) {
                    viewModel.showArchiveConfirmation = true
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.body)
        }
    }

    // MARK: - Edit Name Sheet

    private var editNameSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Circle Set Name", text: $editedName)
                        .font(RRFont.body)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Choose a name that helps you identify this set of circles.")
                }
            }
            .navigationTitle("Edit Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEditNameSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let request = UpdateCircleSetRequest(name: editedName)
                            await viewModel.updateSet(request: request)
                            showEditNameSheet = false
                        }
                    }
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading circle set...")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            RRButton("Retry", icon: "arrow.clockwise") {
                Task { await viewModel.load() }
            }
            .frame(width: 160)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func statusColor(for status: CircleSetStatus) -> Color {
        switch status {
        case .draft: return .gray
        case .active: return .rrPrimary
        case .archived: return .rrTextSecondary
        }
    }
}

// MARK: - Circle Item Row

/// Compact row for a single circle item in the items list.
private struct CircleItemRow: View {

    let item: CircleItem
    let color: Color

    var body: some View {
        RRCard {
            HStack(spacing: 12) {
                RRColorDot(color, size: 8)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(item.behaviorName)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                            .lineLimit(1)

                        if item.flags?.uncertain == true {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityLabel("Marked as uncertain")
                        }
                    }

                    if let notes = item.notes, !notes.isEmpty {
                        Text(notes)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let source = item.source, source != .user {
                    sourceBadge(source)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.behaviorName)\(item.flags?.uncertain == true ? ", uncertain" : "")")
    }

    private func sourceBadge(_ source: CircleItemSource) -> some View {
        Text(source == .template ? "Template" : "Starter")
            .font(RRFont.caption2)
            .foregroundStyle(Color.rrTextSecondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.rrTextSecondary.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Text("CircleSetDetailView requires an API client and set ID")
    }
}
