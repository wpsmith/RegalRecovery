// Views/Activities/LBI/LBICriticalItemEditView.swift

import SwiftUI
import SwiftData
import UIKit

struct LBICriticalItemEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var viewModel = LBIProfileEditViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with counter and warning
                headerSection

                // List of indicators grouped by dimension
                if viewModel.isLoading {
                    ProgressView()
                } else {
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
                }
            }
            .navigationTitle(String(localized: "Edit Critical Items"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save Changes")) {
                        saveChanges()
                    }
                    .disabled(!viewModel.isSelectionComplete)
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
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

            // Warning about historical entries
            RRCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrPrimary)
                    Text(String(localized: "Historical entries will keep your previous selections. Only new check-ins will use the updated critical items."))
                        .font(RRFont.callout)
                        .foregroundStyle(Color.rrText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .background(Color.rrBackground)
    }

    // MARK: - Indicator Row

    @ViewBuilder
    private func indicatorRow(dimensionType: LBIDimensionType, indicator: LBIIndicator) -> some View {
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
        var groups: [LBIDimensionType: [(dimensionType: LBIDimensionType, indicator: LBIIndicator)]] = [:]

        for item in viewModel.allIndicators {
            groups[item.dimensionType, default: []].append(item)
        }

        // Sort by dimension type sort order
        let sortedTypes = LBIDimensionType.allCases.sorted { $0.sortOrder < $1.sortOrder }

        return sortedTypes.compactMap { dimensionType in
            guard let indicators = groups[dimensionType], !indicators.isEmpty else {
                return nil
            }
            return GroupedIndicators(dimensionType: dimensionType, indicators: indicators)
        }
    }

    // MARK: - Actions

    private func loadProfile() {
        guard let userId = users.first?.id else { return }
        viewModel.load(context: modelContext, userId: userId)
    }

    private func saveChanges() {
        guard let userId = users.first?.id else { return }
        viewModel.saveCriticalChanges(context: modelContext, userId: userId)
        dismiss()
    }
}

// MARK: - Supporting Types

private struct GroupedIndicators {
    let dimensionType: LBIDimensionType
    let indicators: [(dimensionType: LBIDimensionType, indicator: LBIIndicator)]
}

#Preview {
    LBICriticalItemEditView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
