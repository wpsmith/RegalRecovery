// Views/Activities/PCI/PCICriticalSelectionView.swift

import SwiftUI
import UIKit

struct PCICriticalSelectionView: View {
    @Bindable var viewModel: PCISetupViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Text(String(localized: "Choose Your Critical 7"))
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(String(localized: "Select the 7 indicators you'll track daily — the warning signs most predictive of your personal patterns."))
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Counter
                HStack {
                    Text(String(localized: "\(viewModel.selectedCount) of 7 selected"))
                        .font(RRFont.headline)
                        .foregroundStyle(selectionCounterColor)
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color.rrBackground)

            // List
            List {
                ForEach(groupedIndicators, id: \.dimensionType) { group in
                    if !group.indicators.isEmpty {
                        Section {
                            ForEach(group.indicators, id: \.indicator.id) { item in
                                indicatorRow(
                                    dimensionType: group.dimensionType,
                                    indicator: item.indicator
                                )
                            }
                        } header: {
                            HStack(spacing: 8) {
                                Image(systemName: group.dimensionType.icon)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrPrimary)
                                Text(group.dimensionType.displayName)
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.bottom, 80)

            // Done Button
            VStack {
                RRButton(
                    String(localized: "Done"),
                    action: {
                        viewModel.currentStep = .confirmation
                    }
                )
                .disabled(!viewModel.isSelectionComplete)
                .opacity(viewModel.isSelectionComplete ? 1.0 : 0.5)
                .padding()
            }
            .background(Color.rrBackground)
        }
        .background(Color.rrBackground)
    }

    @ViewBuilder
    private func indicatorRow(dimensionType: PCIDimensionType, indicator: PCIIndicator) -> some View {
        let isSelected = viewModel.selectedCriticalIds.contains(indicator.id)
        let isDisabled = !isSelected && !viewModel.canSelectMore

        Button {
            if !isDisabled {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                viewModel.toggleCriticalSelection(indicatorId: indicator.id)
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(indicator.text)
                        .font(RRFont.body)
                        .foregroundStyle(isDisabled ? Color.rrTextSecondary.opacity(0.5) : Color.rrText)
                        .multilineTextAlignment(.leading)

                    // Show "will track as" subtitle for Interests indicators
                    if dimensionType.isPositiveCategory {
                        Text(String(localized: "(will track as: Lack of \(indicator.text))"))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary.opacity(isDisabled ? 0.5 : 1.0))
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.rrPrimary : (isDisabled ? Color.rrTextSecondary.opacity(0.3) : Color.rrTextSecondary))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    // MARK: - Computed Properties

    private var selectionCounterColor: Color {
        if viewModel.isSelectionComplete {
            return .rrSuccess
        } else if viewModel.selectedCount > 0 {
            return .rrPrimary
        } else {
            return .rrTextSecondary
        }
    }

    private var groupedIndicators: [GroupedIndicators] {
        // Group indicators by dimension type
        var groups: [PCIDimensionType: [(dimensionType: PCIDimensionType, indicator: PCIIndicator)]] = [:]

        for item in viewModel.allBuiltIndicators {
            groups[item.dimensionType, default: []].append(item)
        }

        // Sort by dimension type sort order
        let sortedTypes = PCIDimensionType.allCases.sorted { $0.sortOrder < $1.sortOrder }

        return sortedTypes.compactMap { dimensionType in
            guard let indicators = groups[dimensionType], !indicators.isEmpty else {
                return nil
            }
            return GroupedIndicators(dimensionType: dimensionType, indicators: indicators)
        }
    }
}

// MARK: - Supporting Types

private struct GroupedIndicators {
    let dimensionType: PCIDimensionType
    let indicators: [(dimensionType: PCIDimensionType, indicator: PCIIndicator)]
}

#Preview {
    @Previewable @State var viewModel = PCISetupViewModel()

    // Set up preview data
    viewModel.dimensionIndicators = [
        .physicalHealth: ["Skipped breakfast", "Less than 6 hours sleep"],
        .interests: ["Playing guitar", "Reading"],
        .recoveryPractice: ["Missed meeting", "Skipped meditation"]
    ]
    viewModel.allBuiltIndicators = [
        (.physicalHealth, PCIIndicator(text: "Skipped breakfast", isPositive: false)),
        (.physicalHealth, PCIIndicator(text: "Less than 6 hours sleep", isPositive: false)),
        (.interests, PCIIndicator(text: "Playing guitar", isPositive: true)),
        (.interests, PCIIndicator(text: "Reading", isPositive: true)),
        (.recoveryPractice, PCIIndicator(text: "Missed meeting", isPositive: false)),
        (.recoveryPractice, PCIIndicator(text: "Skipped meditation", isPositive: false))
    ]

    return PCICriticalSelectionView(viewModel: viewModel)
}
