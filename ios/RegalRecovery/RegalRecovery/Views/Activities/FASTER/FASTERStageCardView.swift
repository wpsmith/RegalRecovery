import SwiftUI

struct FASTERStageCardView: View {
    let stage: FASTERStage
    let isExpanded: Bool
    let selectedCount: Int
    let isIndicatorSelected: (String) -> Bool
    let onToggleExpand: () -> Void
    let onToggleIndicator: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header — always visible
            Button(action: onToggleExpand) {
                HStack(spacing: 14) {
                    Text(stage.letter)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(stage.color)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text(stage.subtitle)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(RRFont.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(stage.color)
                            .clipShape(Circle())
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Body — expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider()

                    Text(stage.description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    FlowLayout(spacing: 8) {
                        ForEach(stage.indicators, id: \.self) { indicator in
                            FASTERIndicatorChip(
                                label: indicator,
                                color: stage.color,
                                isSelected: isIndicatorSelected(indicator),
                                action: { onToggleIndicator(indicator) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        FASTERStageCardView(
            stage: .forgettingPriorities,
            isExpanded: true,
            selectedCount: 2,
            isIndicatorSelected: { $0 == "Isolating" || $0 == "Overconfidence" },
            onToggleExpand: {},
            onToggleIndicator: { _ in }
        )
        FASTERStageCardView(
            stage: .anxiety,
            isExpanded: false,
            selectedCount: 0,
            isIndicatorSelected: { _ in false },
            onToggleExpand: {},
            onToggleIndicator: { _ in }
        )
    }
    .padding()
    .background(Color.rrBackground)
}
