import SwiftUI

struct FASTERThermometerView: View {
    let assessedStage: FASTERStage
    let selectedIndicators: [FASTERStage: Set<String>]

    private let stageOrder: [FASTERStage] = [
        .restoration,
        .forgettingPriorities,
        .anxiety,
        .speedingUp,
        .tickedOff,
        .exhausted,
        .relapse,
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            gradientBar
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(stageOrder) { stage in
                    stageRow(stage)
                }
            }
        }
    }

    private var gradientBar: some View {
        GeometryReader { geo in
            let segmentHeight = geo.size.height / CGFloat(stageOrder.count)

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: stageOrder.map(\.color),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                let stageIndex = stageOrder.firstIndex(of: assessedStage) ?? 0
                let yOffset = CGFloat(stageIndex) * segmentHeight + segmentHeight / 2

                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: assessedStage.color.opacity(0.5), radius: 4)
                    .overlay(
                        Circle()
                            .fill(assessedStage.color)
                            .frame(width: 10, height: 10)
                    )
                    .offset(y: yOffset - 9)
            }
        }
    }

    private func stageRow(_ stage: FASTERStage) -> some View {
        let isAssessed = stage == assessedStage
        let count = selectedIndicators[stage]?.count ?? 0

        return HStack(spacing: 8) {
            Text(stage.letter)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isAssessed ? .white : stage.color)
                .frame(width: 28, height: 28)
                .background(isAssessed ? stage.color : stage.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(stage.name)
                    .font(isAssessed ? RRFont.headline : RRFont.caption)
                    .foregroundStyle(isAssessed ? Color.rrText : Color.rrTextSecondary)

                if count > 0 {
                    Text("\(count) indicator\(count == 1 ? "" : "s")")
                        .font(RRFont.caption2)
                        .foregroundStyle(stage.color)
                }
            }

            Spacer()

            if isAssessed {
                Image(systemName: "arrow.left")
                    .font(.caption)
                    .foregroundStyle(assessedStage.color)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isAssessed ? assessedStage.color.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    RRCard {
        FASTERThermometerView(
            assessedStage: .anxiety,
            selectedIndicators: [
                .restoration: ["Attending meetings regularly"],
                .forgettingPriorities: ["Isolating from others"],
                .anxiety: ["Sleep problems or insomnia", "Vague worry or dread"],
            ]
        )
    }
    .padding()
    .background(Color.rrBackground)
}
