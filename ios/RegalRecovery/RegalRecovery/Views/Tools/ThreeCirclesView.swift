import SwiftUI

/// Entry point for the Three Circles feature.
/// Enforces a single circle set — shows the detail view if one exists,
/// or the builder to create the first (and only) set.
struct ThreeCirclesView: View {
    @State private var circleSet: CircleSet?
    @State private var isLoading = true
    @State private var showBuilder = false
    @State private var selectedCircle: CircleType?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.rrBackground)
            } else if let circleSet {
                localDetailView(circleSet)
            } else {
                emptyStateView
            }
        }
        .navigationTitle("Three Circles")
        .background(Color.rrBackground)
        .onAppear { loadSet() }
        .fullScreenCover(isPresented: $showBuilder, onDismiss: { loadSet() }) {
            NavigationStack {
                ThreeCirclesBuilderView()
            }
        }
    }

    // MARK: - Local Detail View

    private func localDetailView(_ set: CircleSet) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                CircleVisualizationView(
                    innerItems: set.innerCircle,
                    middleItems: set.middleCircle,
                    outerItems: set.outerCircle
                )

                HStack(spacing: 12) {
                    RRStatCard(title: "Inner", value: "\(set.innerCircle.count)", icon: "exclamationmark.octagon", color: .rrDestructive)
                    RRStatCard(title: "Middle", value: "\(set.middleCircle.count)", icon: "exclamationmark.triangle", color: .orange)
                    RRStatCard(title: "Outer", value: "\(set.outerCircle.count)", icon: "checkmark.shield", color: .rrSuccess)
                }

                statusCard(set)

                circleItemSection("Inner Circle", subtitle: "Hard boundaries — behaviors to completely avoid", items: set.innerCircle, color: .rrDestructive)
                circleItemSection("Middle Circle", subtitle: "Warning signs — not failure, but signals to act", items: set.middleCircle, color: .orange)
                circleItemSection("Outer Circle", subtitle: "Healthy behaviors — self-care and recovery practices", items: set.outerCircle, color: .rrSuccess)

                Button {
                    showBuilder = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Rebuild Circles")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(Color.rrPrimary)
                    .background(Color.rrPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    // MARK: - Status Card

    private func statusCard(_ set: CircleSet) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Status")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                    Spacer()
                    RRBadge(text: set.status.displayName, color: set.status == .active ? .rrPrimary : .gray)
                }

                if let version = set.versionNumber {
                    HStack {
                        Text("Version")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text("v\(version)")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                    }
                }

                HStack {
                    Text("Recovery Area")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                    Spacer()
                    Text(set.recoveryArea.displayName)
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrText)
                }

                if let committed = set.committedAt {
                    HStack {
                        Text("Committed")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer()
                        Text(committed.formatted(date: .abbreviated, time: .omitted))
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
        }
    }

    // MARK: - Circle Item Section

    private func circleItemSection(_ title: String, subtitle: String, items: [CircleItem], color: Color) -> some View {
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
                    RRCard {
                        HStack(spacing: 12) {
                            RRColorDot(color, size: 8)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(item.behaviorName)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                        .lineLimit(2)

                                    if item.flags?.uncertain == true {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }

                                if let notes = item.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

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

            RRButton("Create Your Circles", icon: "plus") {
                showBuilder = true
            }
            .frame(width: 260)

            Spacer()
        }
        .padding(.vertical, 40)
    }

    // MARK: - Data Loading

    private func loadSet() {
        let localSets = ThreeCirclesBuilderViewModel.loadSavedSets()
        circleSet = localSets.first { $0.status != .archived }
        isLoading = false
    }
}

#Preview {
    NavigationStack {
        ThreeCirclesView()
    }
}
