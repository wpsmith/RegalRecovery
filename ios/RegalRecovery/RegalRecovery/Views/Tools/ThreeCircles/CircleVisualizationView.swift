import SwiftUI

// MARK: - Circle Visualization View

/// Interactive concentric circles diagram with three rings (inner/red, middle/orange, outer/green).
/// Tap a ring to expand it and show its items. Animated transitions and VoiceOver support.
struct CircleVisualizationView: View {

    // MARK: - Properties

    let innerItems: [CircleItem]
    let middleItems: [CircleItem]
    let outerItems: [CircleItem]

    // MARK: - State

    @State private var expandedCircle: CircleType?

    // MARK: - Constants

    private enum Layout {
        static let outerDiameter: CGFloat = 280
        static let middleDiameter: CGFloat = 185
        static let innerDiameter: CGFloat = 95
        static let ringLineWidth: CGFloat = 3
        static let expandedExtraWidth: CGFloat = 6
        static let badgeSize: CGFloat = 26
        static let itemListMaxHeight: CGFloat = 200
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer ring — green
                circleRing(
                    type: .outer,
                    diameter: Layout.outerDiameter,
                    color: .rrSuccess,
                    items: outerItems,
                    labelOffset: -(Layout.outerDiameter / 2 + 14)
                )

                // Middle ring — orange
                circleRing(
                    type: .middle,
                    diameter: Layout.middleDiameter,
                    color: .orange,
                    items: middleItems,
                    labelOffset: -(Layout.middleDiameter / 2 + 10)
                )

                // Inner ring — red
                circleRing(
                    type: .inner,
                    diameter: Layout.innerDiameter,
                    color: .rrDestructive,
                    items: innerItems,
                    labelOffset: 0
                )
            }
            .frame(width: Layout.outerDiameter + 40, height: Layout.outerDiameter + 40)
            .frame(maxWidth: .infinity)

            // Expanded item list
            if let expandedCircle {
                expandedItemList(for: expandedCircle)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Tap hint
            if expandedCircle == nil {
                Text("Tap a circle to see its items")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: expandedCircle)
    }

    // MARK: - Circle Ring

    private func circleRing(
        type: CircleType,
        diameter: CGFloat,
        color: Color,
        items: [CircleItem],
        labelOffset: CGFloat
    ) -> some View {
        let isExpanded = expandedCircle == type
        let lineWidth = isExpanded
            ? Layout.ringLineWidth + Layout.expandedExtraWidth
            : Layout.ringLineWidth

        return ZStack {
            // Ring stroke
            Circle()
                .stroke(
                    color.opacity(isExpanded ? 1.0 : 0.7),
                    lineWidth: lineWidth
                )
                .frame(width: diameter, height: diameter)

            // Filled background when expanded
            if isExpanded {
                Circle()
                    .fill(color.opacity(0.08))
                    .frame(width: diameter, height: diameter)
            }

            // Label (only on inner circle center, others at top)
            if type == .inner {
                VStack(spacing: 2) {
                    Text(type.displayName)
                        .font(RRFont.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                    Text("\(items.count)")
                        .font(RRFont.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(color)
                }
            } else {
                VStack(spacing: 2) {
                    Text(type.displayName)
                        .font(RRFont.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }
                .offset(y: labelOffset)
            }

            // Count badge (for middle and outer, positioned at bottom of ring)
            if type != .inner {
                countBadge(count: items.count, color: color)
                    .offset(y: diameter / 2 - Layout.badgeSize / 2)
            }
        }
        .contentShape(Circle().size(CGSize(width: diameter, height: diameter)))
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                if expandedCircle == type {
                    expandedCircle = nil
                } else {
                    expandedCircle = type
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(type.displayName), \(items.count) items")
        .accessibilityHint(isExpanded ? "Double tap to collapse" : "Double tap to expand and show items")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Count Badge

    private func countBadge(count: Int, color: Color) -> some View {
        Text("\(count)")
            .font(RRFont.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .frame(width: Layout.badgeSize, height: Layout.badgeSize)
            .background(color)
            .clipShape(Circle())
    }

    // MARK: - Expanded Item List

    private func expandedItemList(for circleType: CircleType) -> some View {
        let items: [CircleItem]
        let color: Color
        let description: String

        switch circleType {
        case .inner:
            items = innerItems
            color = .rrDestructive
            description = "Hard boundaries — behaviors to completely avoid"
        case .middle:
            items = middleItems
            color = .orange
            description = "Warning signs — not failure, but signals to act"
        case .outer:
            items = outerItems
            color = .rrSuccess
            description = "Healthy behaviors — self-care and recovery practices"
        }

        return RRCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    RRColorDot(color, size: 10)
                    Text(circleType.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    Button {
                        withAnimation { expandedCircle = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    .accessibilityLabel("Close \(circleType.displayName) list")
                }

                Text(description)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                Divider()

                if items.isEmpty {
                    Text("No items in this circle yet")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 12)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(items) { item in
                                HStack(spacing: 10) {
                                    RRColorDot(color, size: 6)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.behaviorName)
                                            .font(RRFont.body)
                                            .foregroundStyle(Color.rrText)
                                            .lineLimit(1)
                                        if let notes = item.notes, !notes.isEmpty {
                                            Text(notes)
                                                .font(RRFont.caption)
                                                .foregroundStyle(Color.rrTextSecondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    if item.flags?.uncertain == true {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                            .accessibilityLabel("Uncertain")
                                    }
                                }
                                .padding(.vertical, 4)
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .frame(maxHeight: Layout.itemListMaxHeight)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        CircleVisualizationView(
            innerItems: [
                CircleItem(
                    itemId: "1", circle: .inner, behaviorName: "Pornography",
                    notes: nil, specificityDetail: nil, category: nil,
                    source: .user, flags: nil, createdAt: Date(), modifiedAt: nil
                ),
                CircleItem(
                    itemId: "2", circle: .inner, behaviorName: "Masturbation",
                    notes: "Any form", specificityDetail: nil, category: nil,
                    source: .user, flags: CircleItemFlags(uncertain: true),
                    createdAt: Date(), modifiedAt: nil
                ),
            ],
            middleItems: [
                CircleItem(
                    itemId: "3", circle: .middle, behaviorName: "Isolating from others",
                    notes: nil, specificityDetail: nil, category: nil,
                    source: .user, flags: nil, createdAt: Date(), modifiedAt: nil
                ),
                CircleItem(
                    itemId: "4", circle: .middle, behaviorName: "Staying up late alone",
                    notes: nil, specificityDetail: nil, category: nil,
                    source: .user, flags: nil, createdAt: Date(), modifiedAt: nil
                ),
                CircleItem(
                    itemId: "5", circle: .middle, behaviorName: "Skipping meetings",
                    notes: nil, specificityDetail: nil, category: nil,
                    source: .template, flags: nil, createdAt: Date(), modifiedAt: nil
                ),
            ],
            outerItems: [
                CircleItem(
                    itemId: "6", circle: .outer, behaviorName: "Prayer",
                    notes: "Morning and evening", specificityDetail: nil,
                    category: nil, source: .user, flags: nil,
                    createdAt: Date(), modifiedAt: nil
                ),
                CircleItem(
                    itemId: "7", circle: .outer, behaviorName: "Exercise",
                    notes: nil, specificityDetail: nil, category: nil,
                    source: .user, flags: nil, createdAt: Date(), modifiedAt: nil
                ),
                CircleItem(
                    itemId: "8", circle: .outer, behaviorName: "Calling sponsor",
                    notes: nil, specificityDetail: nil, category: nil,
                    source: .user, flags: nil, createdAt: Date(), modifiedAt: nil
                ),
                CircleItem(
                    itemId: "9", circle: .outer, behaviorName: "Attending meetings",
                    notes: nil, specificityDetail: nil, category: nil,
                    source: .user, flags: nil, createdAt: Date(), modifiedAt: nil
                ),
            ]
        )
        .padding()
    }
    .background(Color.rrBackground)
}
