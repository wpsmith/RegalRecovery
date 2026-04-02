import SwiftUI

struct FASTERThermometerView: View {
    let assessedStage: FASTERStage
    let selectedIndicators: [FASTERStage: Set<String>]

    private let stages = FASTERStage.allCases
    private let segmentHeight: CGFloat = 32

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thermometer bar
            VStack(spacing: 0) {
                ForEach(stages) { stage in
                    ZStack {
                        Rectangle()
                            .fill(stage.color)
                            .frame(height: segmentHeight)

                        // Marker for assessed stage
                        if stage == assessedStage {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(.white)
                                    .frame(width: 14, height: 14)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    .padding(.trailing, 4)
                            }
                        }
                    }
                }
            }
            .frame(width: 36)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Stage labels
            VStack(spacing: 0) {
                ForEach(stages) { stage in
                    HStack(spacing: 6) {
                        Text(stage.letter)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(stage == assessedStage ? stage.color : Color.rrTextSecondary)
                        Text(stage.name)
                            .font(RRFont.caption)
                            .foregroundStyle(stage == assessedStage ? Color.rrText : Color.rrTextSecondary)
                            .fontWeight(stage == assessedStage ? .semibold : .regular)

                        Spacer()

                        let count = selectedIndicators[stage]?.count ?? 0
                        if count > 0 {
                            Text("\(count)")
                                .font(RRFont.caption2)
                                .foregroundStyle(stage.color)
                        }
                    }
                    .frame(height: segmentHeight)
                }
            }
        }
        .padding()
    }
}

#Preview {
    FASTERThermometerView(
        assessedStage: .speedingUp,
        selectedIndicators: [
            .restoration: ["Attending meetings"],
            .forgettingPriorities: ["Isolating", "Overconfidence"],
            .anxiety: ["Sleep problems"],
            .speedingUp: ["Workaholic behavior"],
        ]
    )
    .background(Color.rrBackground)
}
