import SwiftUI

/// Recovery area selection screen.
///
/// Presents a grid of tappable cards for each RecoveryArea enum value.
/// Multi-select is supported for co-occurring addictions.
struct RecoveryAreaSelectionView: View {
    let viewModel: ThreeCirclesBuilderViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    /// Recovery area display data with icons.
    private let areaIcons: [RecoveryArea: String] = [
        .sexPornography: "eye.slash.fill",
        .alcohol: "wineglass.fill",
        .drugs: "pills.fill",
        .gambling: "dice.fill",
        .foodEating: "fork.knife",
        .internetTechnology: "iphone",
        .work: "briefcase.fill",
        .shoppingDebt: "creditcard.fill",
        .loveRelationships: "heart.fill",
        .other: "ellipsis.circle.fill",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("What area of recovery are you working on?")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("Select one or more areas. Many people are working on multiple things at once.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 8)

                // Area grid
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(RecoveryArea.allCases, id: \.self) { area in
                        areaCard(area)
                    }
                }
                .padding(.horizontal)

                // Selection summary
                if !viewModel.selectedRecoveryAreas.isEmpty {
                    let count = viewModel.selectedRecoveryAreas.count
                    Text("\(count) area\(count == 1 ? "" : "s") selected")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrPrimary)
                        .padding(.bottom, 8)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Area Card

    private func areaCard(_ area: RecoveryArea) -> some View {
        let isSelected = viewModel.selectedRecoveryAreas.contains(area)
        let icon = areaIcons[area] ?? "circle.fill"

        return Button {
            viewModel.toggleRecoveryArea(area)
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.rrPrimary.opacity(0.15) : Color.rrSurface)
                        .frame(width: 52, height: 52)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.rrPrimary : Color.rrTextSecondary)
                }

                Text(area.displayName)
                    .font(RRFont.callout)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.rrText : Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(isSelected ? Color.rrPrimary.opacity(0.08) : Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? Color.rrPrimary : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(area.displayName)\(isSelected ? ", selected" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecoveryAreaSelectionView(viewModel: ThreeCirclesBuilderViewModel())
    }
}
