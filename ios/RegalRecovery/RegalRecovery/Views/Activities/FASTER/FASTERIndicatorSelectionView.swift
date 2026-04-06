import SwiftUI

struct FASTERIndicatorSelectionView: View {
    @Bindable var viewModel: FASTERCheckInViewModel
    @State private var expandedStage: FASTERStage? = nil

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
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What are you experiencing?")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                Text("Tap each section to review indicators. Toggle any that apply.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 12)

            // Accordion
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(stageOrder) { stage in
                        stageCard(stage)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }

            // Submit button
            VStack {
                RRButton("See My Results", icon: "arrow.right") {
                    viewModel.finishIndicators()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(
                Color.rrBackground
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color.rrBackground)
    }

    @ViewBuilder
    private func stageCard(_ stage: FASTERStage) -> some View {
        let isExpanded = expandedStage == stage
        let count = viewModel.selectedCount(for: stage)

        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedStage = isExpanded ? nil : stage
                }
            } label: {
                HStack(spacing: 12) {
                    Text(stage.letter)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(count > 0 ? .white : stage.color)
                        .frame(width: 36, height: 36)
                        .background(count > 0 ? stage.color : stage.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text(stage.description)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(stage.color)
                            .clipShape(Circle())
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                FlowLayout(spacing: 8) {
                    ForEach(stage.indicators, id: \.self) { indicator in
                        indicatorChip(stage: stage, indicator: indicator)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(count > 0 ? stage.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }

    private func indicatorChip(stage: FASTERStage, indicator: String) -> some View {
        let selected = viewModel.isSelected(stage: stage, indicator: indicator)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.toggleIndicator(stage: stage, indicator: indicator)
            }
        } label: {
            Text(indicator)
                .font(RRFont.caption)
                .fontWeight(selected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? .white : Color.rrText)
                .background(selected ? stage.color : stage.color.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(indicator), \(selected ? "selected" : "not selected")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    FASTERIndicatorSelectionView(viewModel: FASTERCheckInViewModel())
        .background(Color.rrBackground)
}
