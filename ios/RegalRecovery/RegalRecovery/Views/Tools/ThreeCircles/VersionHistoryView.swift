import SwiftUI

// MARK: - Version History View

/// Timeline of version snapshots for a circle set. Supports viewing snapshots,
/// comparing two versions, and restoring to a previous version.
struct VersionHistoryView: View {

    // MARK: - Properties

    let apiClient: ThreeCirclesAPIClient
    let viewModel: CircleSetDetailViewModel

    // MARK: - State

    @State private var selectedVersionForDetail: VersionListItem?
    @State private var showVersionDetail = false
    @State private var comparisonSelection: Set<Int> = []
    @State private var isCompareMode = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with compare toggle
                headerBar

                if viewModel.isLoading && viewModel.versions.isEmpty {
                    loadingView
                } else if viewModel.versions.isEmpty {
                    emptyStateView
                } else {
                    // Version timeline
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.versions.enumerated()), id: \.element.versionNumber) { index, version in
                            VersionTimelineRow(
                                version: version,
                                isFirst: index == 0,
                                isLast: index == viewModel.versions.count - 1,
                                isCompareMode: isCompareMode,
                                isSelectedForCompare: comparisonSelection.contains(version.versionNumber),
                                onTap: {
                                    if isCompareMode {
                                        toggleCompareSelection(version.versionNumber)
                                    } else {
                                        selectedVersionForDetail = version
                                        showVersionDetail = true
                                    }
                                },
                                onRestore: {
                                    viewModel.requestRestoreVersion(version)
                                }
                            )
                        }
                    }

                    // Compare button when two versions selected
                    if isCompareMode && comparisonSelection.count == 2 {
                        RRButton("Compare Selected Versions", icon: "arrow.left.arrow.right") {
                            // Compare action — show side-by-side
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .padding()
        }
        .background(Color.rrBackground)
        .sheet(isPresented: $showVersionDetail) {
            if let version = selectedVersionForDetail {
                VersionDetailSheet(
                    apiClient: apiClient,
                    viewModel: viewModel,
                    version: version
                )
            }
        }
        .task {
            await viewModel.loadVersions()
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Version History")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                Text("\(viewModel.versions.count) versions")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Spacer()

            if viewModel.versions.count >= 2 {
                Button {
                    withAnimation {
                        isCompareMode.toggle()
                        comparisonSelection.removeAll()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCompareMode ? "xmark" : "arrow.left.arrow.right")
                            .font(.caption)
                        Text(isCompareMode ? "Cancel" : "Compare")
                            .font(RRFont.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .foregroundStyle(isCompareMode ? Color.rrDestructive : Color.rrPrimary)
                    .background(
                        (isCompareMode ? Color.rrDestructive : Color.rrPrimary).opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
                .accessibilityLabel(isCompareMode ? "Cancel comparison" : "Compare versions")
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)
            Text("Loading version history...")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.5))

            Text("No Version History Yet")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            Text("Changes to your circles will be tracked here. Each edit creates a new version so you can always go back.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 32)
    }

    // MARK: - Compare Selection

    private func toggleCompareSelection(_ versionNumber: Int) {
        if comparisonSelection.contains(versionNumber) {
            comparisonSelection.remove(versionNumber)
        } else if comparisonSelection.count < 2 {
            comparisonSelection.insert(versionNumber)
        }
    }
}

// MARK: - Version Timeline Row

/// A single row in the version history timeline with connecting line.
private struct VersionTimelineRow: View {

    let version: VersionListItem
    let isFirst: Bool
    let isLast: Bool
    let isCompareMode: Bool
    let isSelectedForCompare: Bool
    let onTap: () -> Void
    let onRestore: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot + line
            VStack(spacing: 0) {
                if !isFirst {
                    Rectangle()
                        .fill(Color.rrTextSecondary.opacity(0.3))
                        .frame(width: 2, height: 16)
                } else {
                    Color.clear.frame(width: 2, height: 16)
                }

                ZStack {
                    Circle()
                        .fill(isFirst ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                        .frame(width: 12, height: 12)

                    if isCompareMode && isSelectedForCompare {
                        Circle()
                            .stroke(Color.rrPrimary, lineWidth: 2)
                            .frame(width: 18, height: 18)
                    }
                }

                if !isLast {
                    Rectangle()
                        .fill(Color.rrTextSecondary.opacity(0.3))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                } else {
                    Color.clear.frame(width: 2)
                }
            }
            .frame(width: 20)

            // Content card
            Button(action: onTap) {
                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Version \(version.versionNumber)")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            Spacer()

                            Text(version.changedAt.formatted(.relative(presentation: .named)))
                                .font(RRFont.caption2)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        if let changeNote = version.changeNote, !changeNote.isEmpty {
                            Text(changeNote)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                                .lineLimit(2)
                        }

                        // Item counts
                        if let inner = version.innerCount,
                           let middle = version.middleCount,
                           let outer = version.outerCount {
                            HStack(spacing: 12) {
                                itemCountLabel(count: inner, color: .rrDestructive, label: "Inner")
                                itemCountLabel(count: middle, color: .orange, label: "Middle")
                                itemCountLabel(count: outer, color: .rrSuccess, label: "Outer")
                            }
                        }

                        // Restore button (not on latest version)
                        if !isFirst && !isCompareMode {
                            Button {
                                onRestore()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward")
                                        .font(.caption)
                                    Text("Restore")
                                        .font(RRFont.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(Color.rrPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.rrPrimary.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .accessibilityLabel("Restore to version \(version.versionNumber)")
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelectedForCompare ? Color.rrPrimary : Color.clear,
                            lineWidth: 2
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Version \(version.versionNumber), \(version.changedAt.formatted(date: .abbreviated, time: .shortened))")
        .accessibilityHint(isCompareMode
            ? "Double tap to \(isSelectedForCompare ? "deselect" : "select") for comparison"
            : "Double tap to view snapshot")
    }

    private func itemCountLabel(count: Int, color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RRColorDot(color, size: 6)
            Text("\(count)")
                .font(RRFont.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrText)
            Text(label)
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }
}

// MARK: - Version Detail Sheet

/// Sheet showing the full snapshot of a specific version.
private struct VersionDetailSheet: View {

    let apiClient: ThreeCirclesAPIClient
    let viewModel: CircleSetDetailViewModel
    let version: VersionListItem

    @Environment(\.dismiss) private var dismiss
    @State private var snapshot: CircleSetVersion?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .controlSize(.large)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if let snapshot {
                        // Version info header
                        RRCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Version \(snapshot.versionNumber)")
                                        .font(RRFont.title)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                }

                                Text(snapshot.changedAt.formatted(date: .long, time: .shortened))
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrTextSecondary)

                                if let note = snapshot.changeNote, !note.isEmpty {
                                    Text(note)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                        .padding(.top, 4)
                                }
                            }
                        }

                        // Snapshot circles
                        if let circleSnapshot = snapshot.snapshot {
                            snapshotCircleSection(
                                title: "Inner Circle",
                                items: circleSnapshot.innerCircle,
                                color: .rrDestructive
                            )
                            snapshotCircleSection(
                                title: "Middle Circle",
                                items: circleSnapshot.middleCircle,
                                color: .orange
                            )
                            snapshotCircleSection(
                                title: "Outer Circle",
                                items: circleSnapshot.outerCircle,
                                color: .rrSuccess
                            )
                        }

                        // Restore button
                        RRButton("Restore This Version", icon: "arrow.uturn.backward") {
                            viewModel.requestRestoreVersion(version)
                            dismiss()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("Version \(version.versionNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await loadSnapshot()
            }
        }
    }

    private func snapshotCircleSection(
        title: String,
        items: [CircleItem],
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
            }

            if items.isEmpty {
                Text("No items")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.vertical, 4)
            } else {
                RRCard {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(items) { item in
                            HStack(spacing: 8) {
                                RRColorDot(color, size: 6)
                                Text(item.behaviorName)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                if item.flags?.uncertain == true {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
    }

    private func loadSnapshot() async {
        isLoading = true
        defer { isLoading = false }
        await viewModel.loadVersionSnapshot(versionNumber: version.versionNumber)
        snapshot = viewModel.selectedVersionSnapshot
    }
}

// MARK: - Preview

#Preview {
    Text("VersionHistoryView requires dependencies")
}
