// Views/Activities/LBI/LBIProfileEditView.swift

import SwiftUI
import SwiftData

struct LBIProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var viewModel = LBIProfileEditViewModel()
    @State private var newIndicatorTexts: [LBIDimensionType: String] = [:]
    @State private var editingIndicatorId: UUID?
    @FocusState private var focusedField: UUID?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(sortedDimensions, id: \.dimensionType) { dimension in
                            dimensionSection(dimension: dimension)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .contentMargins(.bottom, 80)
                }
            }
            .navigationTitle(String(localized: "Edit Indicators"))
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
                    .disabled(viewModel.dimensions.isEmpty)
                }
            }
            .onAppear {
                loadProfile()
            }
        }
    }

    // MARK: - Dimension Section

    @ViewBuilder
    private func dimensionSection(dimension: LBIDimension) -> some View {
        Section {
            // Existing indicators (editable)
            ForEach(dimension.indicators) { indicator in
                indicatorRow(
                    dimensionType: dimension.dimensionType,
                    indicator: indicator
                )
            }
            .onDelete { indexSet in
                deleteIndicators(at: indexSet, from: dimension)
            }

            // Add new indicator field
            if dimension.indicators.count < 5 {
                addIndicatorRow(dimensionType: dimension.dimensionType)
            }
        } header: {
            HStack(spacing: 8) {
                Image(systemName: dimension.dimensionType.icon)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrPrimary)
                Text(dimension.dimensionType.displayName)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
            }
        } footer: {
            if dimension.indicators.count < 5 {
                Text(String(localized: "\(dimension.indicators.count) of 5 indicators"))
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            } else {
                Text(String(localized: "Maximum 5 indicators reached"))
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    // MARK: - Indicator Row

    @ViewBuilder
    private func indicatorRow(dimensionType: LBIDimensionType, indicator: LBIIndicator) -> some View {
        HStack(spacing: 12) {
            TextField(
                String(localized: "Indicator"),
                text: Binding(
                    get: { indicator.text },
                    set: { newValue in
                        if newValue.count <= 200 {
                            viewModel.updateIndicator(
                                id: indicator.id,
                                in: dimensionType,
                                newText: newValue
                            )
                        }
                    }
                )
            )
            .font(RRFont.body)
            .foregroundStyle(Color.rrText)
            .focused($focusedField, equals: indicator.id)

            // Critical badge if selected
            if viewModel.selectedCriticalIds.contains(indicator.id) {
                Image(systemName: "star.fill")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrPrimary)
            }
        }
    }

    // MARK: - Add Indicator Row

    @ViewBuilder
    private func addIndicatorRow(dimensionType: LBIDimensionType) -> some View {
        HStack(spacing: 12) {
            TextField(
                String(localized: "Add new indicator"),
                text: Binding(
                    get: { newIndicatorTexts[dimensionType] ?? "" },
                    set: { newIndicatorTexts[dimensionType] = $0 }
                )
            )
            .font(RRFont.body)
            .foregroundStyle(Color.rrText)
            .onSubmit {
                addNewIndicator(to: dimensionType)
            }

            if let text = newIndicatorTexts[dimensionType], !text.isEmpty {
                Button {
                    addNewIndicator(to: dimensionType)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var sortedDimensions: [LBIDimension] {
        viewModel.dimensions.sorted { $0.dimensionType.sortOrder < $1.dimensionType.sortOrder }
    }

    // MARK: - Actions

    private func loadProfile() {
        guard let userId = users.first?.id else { return }
        viewModel.load(context: modelContext, userId: userId)
    }

    private func addNewIndicator(to dimensionType: LBIDimensionType) {
        guard let text = newIndicatorTexts[dimensionType]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }

        viewModel.addIndicator(to: dimensionType, text: text)
        newIndicatorTexts[dimensionType] = ""
    }

    private func deleteIndicators(at indexSet: IndexSet, from dimension: LBIDimension) {
        for index in indexSet {
            let indicator = dimension.indicators[index]
            viewModel.removeIndicator(id: indicator.id, from: dimension.dimensionType)
        }
    }

    private func saveChanges() {
        guard let userId = users.first?.id else { return }
        viewModel.saveIndicatorChanges(context: modelContext, userId: userId)
        dismiss()
    }
}

#Preview {
    LBIProfileEditView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
