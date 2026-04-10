import SwiftUI

// MARK: - Timeline View

/// Horizontal scrollable timeline visualization of daily circle check-ins.
///
/// Design:
/// - Color-coded bars per day: green (outer), orange (middle), red (inner), gray (no checkin)
/// - Color-blind safe: uses shapes (circle, diamond, square) in addition to colors
/// - Scrollable horizontally, most recent days on the right
/// - Tap a day to reveal check-in details via sheet callback
/// - Current consecutive outer days shown subtly, not primary metric
/// - Optional mood/urge overlay dots
struct TimelineView: View {

    let entries: [TimelineEntry]
    let showMoodOverlay: Bool
    let showUrgeOverlay: Bool
    let consecutiveOuterDays: Int
    let onDayTapped: (TimelineEntry) -> Void

    private let barWidth: CGFloat = 14
    private let barSpacing: CGFloat = 3
    private let maxBarHeight: CGFloat = 100

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Legend
            legend

            // MARK: - Timeline Bars
            if entries.isEmpty {
                emptyState
            } else {
                timelineContent
            }

            // MARK: - Consecutive Outer (subtle)
            if consecutiveOuterDays > 0 {
                Text("Current consecutive outer circle days: \(consecutiveOuterDays)")
                    .font(RRFont.caption2)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: .rrSuccess, shape: "circle.fill", label: "Outer")
            legendItem(color: .orange, shape: "diamond.fill", label: "Middle")
            legendItem(color: .rrDestructive, shape: "square.fill", label: "Inner")
            legendItem(
                color: Color.rrTextSecondary.opacity(0.3),
                shape: "minus",
                label: "No log"
            )
        }
        .font(RRFont.caption2)
    }

    private func legendItem(color: Color, shape: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: shape)
                .font(.system(size: 8))
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    // MARK: - Timeline Content

    private var timelineContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(Array(entries.enumerated()), id: \.element.date) { index, entry in
                        dayBar(entry: entry, index: index)
                            .id(entry.date)
                    }
                }
                .padding(.vertical, 8)
            }
            .onAppear {
                // Scroll to most recent day
                if let last = entries.last {
                    proxy.scrollTo(last.date, anchor: .trailing)
                }
            }
        }
        .frame(height: maxBarHeight + 40)
    }

    // MARK: - Day Bar

    private func dayBar(entry: TimelineEntry, index: Int) -> some View {
        let color = colorForEntry(entry)
        let height = heightForEntry(entry)

        return VStack(spacing: 4) {
            // Mood/urge overlay dots
            if showMoodOverlay, let mood = entry.checkinDetails?.mood {
                moodDot(mood: mood)
            }

            if showUrgeOverlay, let urge = entry.checkinDetails?.urgeIntensity {
                urgeDot(urge: urge)
            }

            // Bar with accessibility shape
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(color)
                    .frame(width: barWidth, height: height)

                // Shape indicator for color-blind accessibility
                shapeIndicator(for: entry.circle)
                    .offset(y: -4)
            }

            // Date label (every 7th day or first/last)
            if shouldShowDateLabel(index: index) {
                Text(shortDateLabel(entry.date))
                    .font(.system(size: 8))
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(width: barWidth + 8)
            } else {
                Color.clear.frame(height: 10)
            }
        }
        .onTapGesture {
            onDayTapped(entry)
        }
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel(for: entry))
    }

    // MARK: - Shape Indicators (Color-Blind Safe)

    @ViewBuilder
    private func shapeIndicator(for circle: CircleType?) -> some View {
        switch circle {
        case .outer:
            Circle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 5, height: 5)
        case .middle:
            Image(systemName: "diamond.fill")
                .font(.system(size: 5))
                .foregroundStyle(Color.white.opacity(0.6))
        case .inner:
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 5, height: 5)
        case nil:
            EmptyView()
        }
    }

    // MARK: - Overlay Dots

    private func moodDot(mood: Int) -> some View {
        Circle()
            .fill(moodColor(mood))
            .frame(width: 6, height: 6)
    }

    private func urgeDot(urge: Int) -> some View {
        Circle()
            .stroke(urgeColor(urge), lineWidth: 1.5)
            .frame(width: 6, height: 6)
    }

    private func moodColor(_ mood: Int) -> Color {
        switch mood {
        case 1...3: return .rrDestructive
        case 4...6: return .orange
        case 7...10: return .rrSuccess
        default: return Color.rrTextSecondary.opacity(0.3)
        }
    }

    private func urgeColor(_ urge: Int) -> Color {
        switch urge {
        case 1...3: return .rrSuccess
        case 4...6: return .orange
        case 7...10: return .rrDestructive
        default: return Color.rrTextSecondary.opacity(0.3)
        }
    }

    // MARK: - Helpers

    private func colorForEntry(_ entry: TimelineEntry) -> Color {
        switch entry.circle {
        case .outer: return .rrSuccess
        case .middle: return .orange
        case .inner: return .rrDestructive
        case nil: return Color.rrTextSecondary.opacity(0.3)
        }
    }

    private func heightForEntry(_ entry: TimelineEntry) -> CGFloat {
        guard entry.circle != nil else { return maxBarHeight * 0.2 }
        // Mood-proportional height when overlay is on, otherwise uniform
        if showMoodOverlay, let mood = entry.checkinDetails?.mood {
            return max(maxBarHeight * 0.3, maxBarHeight * CGFloat(mood) / 10.0)
        }
        return maxBarHeight * 0.75
    }

    private func shouldShowDateLabel(index: Int) -> Bool {
        index == 0 || index == entries.count - 1 || index % 7 == 0
    }

    private func shortDateLabel(_ dateString: String) -> String {
        // dateString format: "YYYY-MM-DD"
        let components = dateString.split(separator: "-")
        guard components.count == 3 else { return dateString }
        return "\(components[1])/\(components[2])"
    }

    private func accessibilityLabel(for entry: TimelineEntry) -> String {
        let circleName = entry.circle?.displayName ?? "No check-in"
        return "\(entry.date): \(circleName)"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.system(size: 36))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.4))
            Text("No timeline data yet")
                .font(RRFont.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
            Text("Check in daily to build your pattern timeline.")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxBarHeight + 40)
    }
}

#Preview {
    TimelineView(
        entries: [
            TimelineEntry(date: "2026-04-01", circle: .outer, checkinDetails: .init(mood: 8, urgeIntensity: 2, notes: nil)),
            TimelineEntry(date: "2026-04-02", circle: .outer, checkinDetails: .init(mood: 7, urgeIntensity: 3, notes: nil)),
            TimelineEntry(date: "2026-04-03", circle: .middle, checkinDetails: .init(mood: 5, urgeIntensity: 6, notes: "Tough day")),
            TimelineEntry(date: "2026-04-04", circle: nil, checkinDetails: nil),
            TimelineEntry(date: "2026-04-05", circle: .outer, checkinDetails: .init(mood: 9, urgeIntensity: 1, notes: nil)),
            TimelineEntry(date: "2026-04-06", circle: .inner, checkinDetails: .init(mood: 3, urgeIntensity: 9, notes: nil)),
            TimelineEntry(date: "2026-04-07", circle: .outer, checkinDetails: .init(mood: 7, urgeIntensity: 2, notes: nil)),
        ],
        showMoodOverlay: false,
        showUrgeOverlay: false,
        consecutiveOuterDays: 1,
        onDayTapped: { _ in }
    )
    .padding()
}
