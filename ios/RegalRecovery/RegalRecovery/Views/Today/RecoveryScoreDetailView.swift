import SwiftUI

/// Expanded score breakdown displayed at the bottom of the Today view.
struct RecoveryScoreDetailView: View {
    let score: Int
    let scoreLevel: DailyScoreLevel
    let planItems: [TodayPlanItem]
    let morningCommitmentDone: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("TODAY'S RECOVERY SCORE")
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Large score
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreLevel.color)

                Text(scoreLevel.label)
                    .font(RRFont.headline)
                    .foregroundStyle(scoreLevel.color)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if FeatureFlagStore.shared.isEnabled("feature.analytics-dashboard") {
                Divider()

                // Breakdown toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text("View Score Breakdown")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrPrimary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }

                if isExpanded {
                    VStack(spacing: 10) {
                        ForEach(planItems) { item in
                            HStack(spacing: 10) {
                                Image(systemName: item.state == .completed ? "checkmark.circle.fill" : "circle")
                                    .font(.body)
                                    .foregroundStyle(item.state == .completed ? Color.rrSuccess : Color.rrTextSecondary)

                                Text(item.displayName)
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(item.state == .completed ? Color.rrText : Color.rrTextSecondary)

                                Spacer()

                                Text(String(format: "%.0f%%", item.weight))
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
