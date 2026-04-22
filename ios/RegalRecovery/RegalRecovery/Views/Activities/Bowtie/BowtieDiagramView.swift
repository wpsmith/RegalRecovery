import SwiftUI

struct BowtieDiagramView: View {
    let markers: [RRBowtieMarker]
    let onTapInterval: (BowtieSide, Int) -> Void
    let onTapMarker: (RRBowtieMarker) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let intervals = BowtieSide.timeIntervals // [1, 3, 6, 12, 24, 36, 48]

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                let layout = DiagramLayout(size: geometry.size, intervals: intervals)

                ZStack {
                    // Triangle outlines
                    bowtieShape(layout: layout)

                    // Dashed interval lines
                    intervalLines(layout: layout)

                    // Markers
                    markerOverlay(layout: layout)

                    // Column tap targets
                    columnTapTargets(layout: layout)
                }
            }
            .frame(height: 220)

            // Labels row
            intervalLabels
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(String(localized: "Use list view for detailed interaction"))
    }

    // MARK: - Bowtie Shape

    private func bowtieShape(layout: DiagramLayout) -> some View {
        Canvas { context, size in
            let center = layout.center

            // Past triangle (left): wide at left edge, narrows to center
            var pastPath = Path()
            pastPath.move(to: CGPoint(x: layout.leftEdge, y: layout.topEdge))
            pastPath.addLine(to: CGPoint(x: center.x, y: center.y))
            pastPath.addLine(to: CGPoint(x: layout.leftEdge, y: layout.bottomEdge))
            pastPath.closeSubpath()

            context.stroke(pastPath, with: .color(.rrTextSecondary.opacity(0.5)), lineWidth: 1.5)
            context.fill(pastPath, with: .color(.rrSurface.opacity(0.3)))

            // Future triangle (right): narrows from center, widens to right edge
            var futurePath = Path()
            futurePath.move(to: CGPoint(x: layout.rightEdge, y: layout.topEdge))
            futurePath.addLine(to: CGPoint(x: center.x, y: center.y))
            futurePath.addLine(to: CGPoint(x: layout.rightEdge, y: layout.bottomEdge))
            futurePath.closeSubpath()

            context.stroke(futurePath, with: .color(.rrTextSecondary.opacity(0.5)), lineWidth: 1.5)
            context.fill(futurePath, with: .color(.rrSurface.opacity(0.3)))
        }
    }

    // MARK: - Interval Lines

    private func intervalLines(layout: DiagramLayout) -> some View {
        Canvas { context, size in
            let dashStyle = StrokeStyle(lineWidth: 0.5, dash: [4, 4])

            // Past side interval lines (left of center)
            for interval in intervals {
                let x = layout.pastX(for: interval)
                var path = Path()
                path.move(to: CGPoint(x: x, y: layout.topEdge))
                path.addLine(to: CGPoint(x: x, y: layout.bottomEdge))
                context.stroke(path, with: .color(.rrTextSecondary.opacity(0.3)), style: dashStyle)
            }

            // Future side interval lines (right of center)
            for interval in intervals {
                let x = layout.futureX(for: interval)
                var path = Path()
                path.move(to: CGPoint(x: x, y: layout.topEdge))
                path.addLine(to: CGPoint(x: x, y: layout.bottomEdge))
                context.stroke(path, with: .color(.rrTextSecondary.opacity(0.3)), style: dashStyle)
            }
        }
    }

    // MARK: - Markers

    private func markerOverlay(layout: DiagramLayout) -> some View {
        ForEach(groupedMarkers.keys.sorted(by: { $0.sortKey < $1.sortKey }), id: \.self) { key in
            let group = groupedMarkers[key] ?? []
            ForEach(Array(group.enumerated()), id: \.element.id) { index, marker in
                markerCircle(marker: marker, index: index, total: group.count, layout: layout)
            }
        }
    }

    private func markerCircle(marker: RRBowtieMarker, index: Int, total: Int, layout: DiagramLayout) -> some View {
        let side = marker.bowtieSide
        let x = side == .past
            ? layout.pastX(for: marker.timeIntervalHours)
            : layout.futureX(for: marker.timeIntervalHours)

        let baseY = layout.center.y
        let markerSize: CGFloat = 44
        let verticalSpacing: CGFloat = markerSize * 0.6
        let totalHeight = CGFloat(total - 1) * verticalSpacing
        let startY = baseY - totalHeight / 2
        let y = startY + CGFloat(index) * verticalSpacing

        let primaryColor = primaryITypeColor(for: marker)
        let isPast = side == .past

        return Button {
            onTapMarker(marker)
        } label: {
            ZStack {
                if isPast {
                    Circle()
                        .fill(primaryColor)
                        .frame(width: markerSize * 0.55, height: markerSize * 0.55)
                } else {
                    Circle()
                        .stroke(primaryColor, lineWidth: 2)
                        .frame(width: markerSize * 0.55, height: markerSize * 0.55)
                }
            }
            .frame(width: markerSize, height: markerSize)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .position(x: x, y: y)
    }

    // MARK: - Column Tap Targets

    private func columnTapTargets(layout: DiagramLayout) -> some View {
        // Invisible tap targets for each interval column
        ForEach(intervals, id: \.self) { interval in
            // Past side tap target
            columnTapTarget(side: .past, interval: interval, layout: layout)

            // Future side tap target
            columnTapTarget(side: .future, interval: interval, layout: layout)
        }
    }

    private func columnTapTarget(side: BowtieSide, interval: Int, layout: DiagramLayout) -> some View {
        let x = side == .past ? layout.pastX(for: interval) : layout.futureX(for: interval)
        let markersAtColumn = markers.filter {
            $0.bowtieSide == side && $0.timeIntervalHours == interval
        }

        // Only show tap target if no markers at this column
        return Group {
            if markersAtColumn.isEmpty {
                Button {
                    onTapInterval(side, interval)
                } label: {
                    Circle()
                        .fill(Color.rrPrimary.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.caption2)
                                .foregroundStyle(Color.rrPrimary.opacity(0.5))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(String(localized: "Add marker at \(interval) hours on \(side.displayName) side"))
                .position(x: x, y: layout.center.y)
            }
        }
    }

    // MARK: - Labels

    private var intervalLabels: some View {
        GeometryReader { geometry in
            let layout = DiagramLayout(size: CGSize(width: geometry.size.width, height: 220), intervals: intervals)

            ZStack {
                // "Now" label at center
                Text(String(localized: "Now"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rrText)
                    .position(x: layout.center.x, y: 10)

                // Past labels
                ForEach(intervals, id: \.self) { interval in
                    Text("\(interval)h")
                        .font(.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                        .position(x: layout.pastX(for: interval), y: 10)
                }

                // Future labels
                ForEach(intervals, id: \.self) { interval in
                    Text("\(interval)h")
                        .font(.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                        .position(x: layout.futureX(for: interval), y: 10)
                }
            }
        }
        .frame(height: 24)
    }

    // MARK: - Helpers

    private var groupedMarkers: [MarkerGroupKey: [RRBowtieMarker]] {
        var dict: [MarkerGroupKey: [RRBowtieMarker]] = [:]
        for marker in markers {
            let key = MarkerGroupKey(side: marker.bowtieSide, interval: marker.timeIntervalHours)
            dict[key, default: []].append(marker)
        }
        return dict
    }

    private func primaryITypeColor(for marker: RRBowtieMarker) -> Color {
        guard let first = marker.iActivations.max(by: { $0.intensity < $1.intensity }) else {
            return .rrTextSecondary
        }
        return first.iType.color
    }

    private var accessibilitySummary: String {
        let pastCount = markers.filter { $0.bowtieSide == .past }.count
        let futureCount = markers.filter { $0.bowtieSide == .future }.count
        return String(localized: "Bowtie diagram. Past side: \(pastCount) markers. Future side: \(futureCount) markers.")
    }
}

// MARK: - Diagram Layout

private struct DiagramLayout {
    let size: CGSize
    let intervals: [Int]

    private let horizontalPadding: CGFloat = 16
    private let verticalPadding: CGFloat = 16

    var leftEdge: CGFloat { horizontalPadding }
    var rightEdge: CGFloat { size.width - horizontalPadding }
    var topEdge: CGFloat { verticalPadding }
    var bottomEdge: CGFloat { size.height - verticalPadding }

    var center: CGPoint {
        CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private var halfWidth: CGFloat {
        (size.width - horizontalPadding * 2) / 2
    }

    /// Returns X position for a past-side interval.
    /// Past: 48h is at left edge, 1h is near center.
    func pastX(for interval: Int) -> CGFloat {
        let fraction = normalizedPosition(for: interval)
        // fraction 0 = closest to center (1h), fraction 1 = farthest (48h)
        return center.x - fraction * halfWidth
    }

    /// Returns X position for a future-side interval.
    /// Future: 1h is near center, 48h is at right edge.
    func futureX(for interval: Int) -> CGFloat {
        let fraction = normalizedPosition(for: interval)
        return center.x + fraction * halfWidth
    }

    /// Normalized position from 0 (closest to center) to 1 (farthest).
    /// Uses log scale for better visual distribution of [1, 3, 6, 12, 24, 36, 48].
    private func normalizedPosition(for interval: Int) -> CGFloat {
        let maxHours: CGFloat = 48
        let logValue = log(CGFloat(interval) + 1)
        let logMax = log(maxHours + 1)
        return logValue / logMax
    }
}

// MARK: - Marker Group Key

private struct MarkerGroupKey: Hashable, Comparable {
    let side: BowtieSide
    let interval: Int

    var sortKey: Int {
        let sideValue = side == .past ? 0 : 1000
        return sideValue + interval
    }

    static func < (lhs: MarkerGroupKey, rhs: MarkerGroupKey) -> Bool {
        lhs.sortKey < rhs.sortKey
    }
}
