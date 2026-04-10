import SwiftUI

// MARK: - Circle Visualization View

/// Interactive concentric circles diagram with three rings (inner/red, middle/orange, outer/green).
/// Tap a ring to filter the item list below to only that circle. Tap again to show all.
struct CircleVisualizationView: View {

    // MARK: - Properties

    let innerItems: [CircleItem]
    let middleItems: [CircleItem]
    let outerItems: [CircleItem]

    // MARK: - State

    @State private var selectedCircle: CircleType?

    // MARK: - Constants

    private enum Layout {
        static let outerDiameter: CGFloat = 280
        static let middleDiameter: CGFloat = 185
        static let innerDiameter: CGFloat = 95
        static let ringLineWidth: CGFloat = 3
        static let selectedLineWidth: CGFloat = 5
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // Concentric circles
            ZStack {
                outerRing
                middleRing
                innerRing
            }
            .frame(width: Layout.outerDiameter + 20, height: Layout.outerDiameter + 20)
            .frame(maxWidth: .infinity)

            // Item list below
            itemSections
        }
        .animation(.easeInOut(duration: 0.25), value: selectedCircle)
    }

    // MARK: - Rings

    private var outerRing: some View {
        let isSelected = selectedCircle == .outer
        return Circle()
            .stroke(Color.rrSuccess.opacity(isSelected || selectedCircle == nil ? 1.0 : 0.3),
                    lineWidth: isSelected ? Layout.selectedLineWidth : Layout.ringLineWidth)
            .background(
                Circle().fill(Color.rrSuccess.opacity(isSelected ? 0.1 : 0.03))
            )
            .frame(width: Layout.outerDiameter, height: Layout.outerDiameter)
            .overlay(
                ringLabel("Outer", count: outerItems.count, color: .rrSuccess)
                    .offset(y: -Layout.outerDiameter / 2 + 28)
            )
            .contentShape(
                ringShape(outer: Layout.outerDiameter, inner: Layout.middleDiameter)
            )
            .onTapGesture { toggle(.outer) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Outer Circle, \(outerItems.count) items")
            .accessibilityHint(isSelected ? "Double tap to show all circles" : "Double tap to filter to outer circle")
            .accessibilityAddTraits(.isButton)
    }

    private var middleRing: some View {
        let isSelected = selectedCircle == .middle
        return Circle()
            .stroke(Color.orange.opacity(isSelected || selectedCircle == nil ? 1.0 : 0.3),
                    lineWidth: isSelected ? Layout.selectedLineWidth : Layout.ringLineWidth)
            .background(
                Circle().fill(Color.orange.opacity(isSelected ? 0.1 : 0.03))
            )
            .frame(width: Layout.middleDiameter, height: Layout.middleDiameter)
            .overlay(
                ringLabel("Middle", count: middleItems.count, color: .orange)
                    .offset(y: -Layout.middleDiameter / 2 + 24)
            )
            .contentShape(
                ringShape(outer: Layout.middleDiameter, inner: Layout.innerDiameter)
            )
            .onTapGesture { toggle(.middle) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Middle Circle, \(middleItems.count) items")
            .accessibilityHint(isSelected ? "Double tap to show all circles" : "Double tap to filter to middle circle")
            .accessibilityAddTraits(.isButton)
    }

    private var innerRing: some View {
        let isSelected = selectedCircle == .inner
        return Circle()
            .stroke(Color.rrDestructive.opacity(isSelected || selectedCircle == nil ? 1.0 : 0.3),
                    lineWidth: isSelected ? Layout.selectedLineWidth : Layout.ringLineWidth)
            .background(
                Circle().fill(Color.rrDestructive.opacity(isSelected ? 0.12 : 0.05))
            )
            .frame(width: Layout.innerDiameter, height: Layout.innerDiameter)
            .overlay(
                ringLabel("Inner", count: innerItems.count, color: .rrDestructive)
            )
            .contentShape(Circle())
            .onTapGesture { toggle(.inner) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Inner Circle, \(innerItems.count) items")
            .accessibilityHint(isSelected ? "Double tap to show all circles" : "Double tap to filter to inner circle")
            .accessibilityAddTraits(.isButton)
    }

    // MARK: - Ring Label (inside the ring)

    private func ringLabel(_ name: String, count: Int, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(name)
                .font(RRFont.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            Text("\(count)")
                .font(RRFont.caption)
                .fontWeight(.bold)
                .foregroundStyle(color)
        }
    }

    // MARK: - Ring Hit Shape

    /// Creates an annular (donut) hit-test shape so tapping between rings
    /// targets the correct ring, not the one on top.
    private func ringShape(outer: CGFloat, inner: CGFloat) -> some Shape {
        RingShape(outerRadius: outer / 2, innerRadius: inner / 2)
    }

    // MARK: - Toggle

    private func toggle(_ circle: CircleType) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if selectedCircle == circle {
                selectedCircle = nil
            } else {
                selectedCircle = circle
            }
        }
    }

    // MARK: - Item Sections

    @ViewBuilder
    private var itemSections: some View {
        let sections = visibleSections

        if sections.isEmpty {
            Text("Tap a circle above to see its items")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.top, 4)
        } else {
            VStack(spacing: 12) {
                ForEach(sections, id: \.type) { section in
                    circleSection(section.type, items: section.items, color: section.color)
                }
            }
        }
    }

    private var visibleSections: [(type: CircleType, items: [CircleItem], color: Color)] {
        if let selected = selectedCircle {
            switch selected {
            case .inner: return [(.inner, innerItems, .rrDestructive)]
            case .middle: return [(.middle, middleItems, .orange)]
            case .outer: return [(.outer, outerItems, .rrSuccess)]
            }
        } else {
            // Show all three
            var result: [(type: CircleType, items: [CircleItem], color: Color)] = []
            if !innerItems.isEmpty { result.append((.inner, innerItems, .rrDestructive)) }
            if !middleItems.isEmpty { result.append((.middle, middleItems, .orange)) }
            if !outerItems.isEmpty { result.append((.outer, outerItems, .rrSuccess)) }
            return result
        }
    }

    private func circleSection(_ type: CircleType, items: [CircleItem], color: Color) -> some View {
        RRCard {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items) { item in
                        HStack(spacing: 10) {
                            RRColorDot(color, size: 6)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.behaviorName)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
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
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 6)
            } label: {
                HStack(spacing: 8) {
                    Circle().fill(color).frame(width: 10, height: 10)
                    Text(type.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    Text("\(items.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
            .tint(color)
        }
    }
}

// MARK: - Ring Shape (annular hit area)

/// A donut-shaped path for hit-testing taps on concentric rings.
struct RingShape: Shape {
    let outerRadius: CGFloat
    let innerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: .zero, endAngle: .degrees(360), clockwise: true)
        return path
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
            ]
        )
        .padding()
    }
    .background(Color.rrBackground)
}
