import SwiftUI

/// Starter pack browser and selection screen.
///
/// Lists available packs filtered by recovery area, allows previewing
/// pack contents, and applies the selected pack to populate all three circles.
struct StarterPackSelectionView: View {
    let viewModel: ThreeCirclesBuilderViewModel

    @State private var expandedPackId: String?
    @State private var selectedPackDetail: StarterPack?
    @State private var isLoadingDetail: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("Choose a Starter Pack")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("These are clinically reviewed starting points, not finished plans. You will be able to customize everything before committing.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 8)

                // Packs list
                if viewModel.isLoadingStarterPacks {
                    loadingView
                } else if viewModel.availableStarterPacks.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.availableStarterPacks) { pack in
                            packCard(pack)
                        }
                    }
                    .padding(.horizontal)
                }

                // Encouragement note
                RRCard {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.body)
                            .foregroundStyle(Color.rrPrimary)

                        Text("Starting with a pack does not mean your recovery looks like anyone else's. Think of it as a conversation starter for your work with your sponsor.")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Pack Card

    private func packCard(_ pack: StarterPackListItem) -> some View {
        let isExpanded = expandedPackId == pack.packId

        return VStack(spacing: 0) {
            // Pack header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedPackId = isExpanded ? nil : pack.packId
                }
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: "shippingbox.fill")
                            .font(.title3)
                            .foregroundStyle(Color.rrPrimary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.name)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            if let variant = pack.variant {
                                RRBadge(text: variant.displayName, color: variantColor(variant))
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }

                    if let description = pack.description {
                        Text(description)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }

                    // Item counts
                    if let counts = pack.itemCounts {
                        HStack(spacing: 16) {
                            itemCountBadge("Inner", count: counts.inner ?? 0, color: Color.rrDestructive)
                            itemCountBadge("Middle", count: counts.middle ?? 0, color: .orange)
                            itemCountBadge("Outer", count: counts.outer ?? 0, color: Color.rrSuccess)
                        }
                    }
                }
                .padding()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(pack.name)\(isExpanded ? ", expanded" : "")")

            // Expanded content: preview + apply button
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal)

                    if isLoadingDetail {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if let detail = selectedPackDetail, detail.packId == pack.packId {
                        packPreview(detail)
                    } else {
                        Button("Preview Contents") {
                            // In production, this would call the API to get pack detail.
                            // For now, show a placeholder.
                            isLoadingDetail = true
                            // Simulate loading
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isLoadingDetail = false
                            }
                        }
                        .font(RRFont.callout)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(minHeight: 44)
                    }

                    // Apply button
                    Button {
                        if let detail = selectedPackDetail, detail.packId == pack.packId {
                            viewModel.applyStarterPack(detail)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Use This Pack")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 14)
                    .accessibilityLabel("Use \(pack.name) starter pack")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Pack Preview

    private func packPreview(_ pack: StarterPack) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let inner = pack.innerCircle, !inner.isEmpty {
                circlePreviewSection("Inner Circle", items: inner.map(\.behaviorName), color: Color.rrDestructive)
            }
            if let middle = pack.middleCircle, !middle.isEmpty {
                circlePreviewSection("Middle Circle", items: middle.map(\.behaviorName), color: .orange)
            }
            if let outer = pack.outerCircle, !outer.isEmpty {
                circlePreviewSection("Outer Circle", items: outer.map(\.behaviorName), color: Color.rrSuccess)
            }
        }
        .padding(.horizontal)
    }

    private func circlePreviewSection(_ title: String, items: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                RRColorDot(color, size: 8)
                Text(title)
                    .font(RRFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }

            FlowLayout(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Loading & Empty States

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading starter packs...")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyState: some View {
        RRCard {
            VStack(spacing: 12) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.rrTextSecondary)

                Text("No starter packs available for this recovery area yet.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)

                Text("You can use the guided builder to create your circles from scratch.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func itemCountBadge(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            RRColorDot(color, size: 6)
            Text("\(count) \(label)")
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    private func variantColor(_ variant: StarterPackVariant) -> Color {
        switch variant {
        case .secular: return Color.rrPrimary
        case .faithBased: return Color(red: 0.55, green: 0.36, blue: 0.72)
        case .lgbtqAffirming: return Color(red: 0.85, green: 0.45, blue: 0.60)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StarterPackSelectionView(viewModel: {
            let vm = ThreeCirclesBuilderViewModel()
            vm.availableStarterPacks = [
                StarterPackListItem(
                    packId: "1",
                    name: "SA Recovery Essentials",
                    description: "A solid starting point for sexual addiction recovery based on common SA fellowship practices.",
                    variant: .faithBased,
                    itemCounts: .init(inner: 5, middle: 8, outer: 10)
                ),
                StarterPackListItem(
                    packId: "2",
                    name: "Secular Recovery Basics",
                    description: "Evidence-based behaviors for sexual addiction recovery without religious content.",
                    variant: .secular,
                    itemCounts: .init(inner: 4, middle: 7, outer: 9)
                ),
            ]
            return vm
        }())
    }
}
