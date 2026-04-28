import SwiftUI

/// Compact score bar displayed at the top of the Today view.
struct RecoveryScoreSummaryView: View {
    let score: Int
    let scoreLevel: DailyScoreLevel
    let totalCompleted: Int
    let totalPlanned: Int

    @State private var showScoreInfo = false

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Today's Recovery Progress & Score")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                Spacer()

                Button {
                    showScoreInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .alert("Recovery Score", isPresented: $showScoreInfo) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("Your daily recovery score reflects an algorithmic calculation of completing your planned activities, your profile, foundation work, and your stage of recovery.")
                }
            }

            HStack(spacing: 12) {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.rrTextSecondary.opacity(0.15))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(scoreLevel.color)
                            .frame(
                                width: geometry.size.width * CGFloat(score) / 100.0,
                                height: 10
                            )
                            .animation(.easeInOut(duration: 0.4), value: score)
                    }
                }
                .frame(height: 10)

                // Score number
                Text("\(score)")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(scoreLevel.color)
                    .frame(minWidth: 36)
            }

            // Completed label
            Text("\(totalCompleted) of \(totalPlanned) activities completed")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
