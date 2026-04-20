import SwiftUI

struct VisionValuesStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    @State private var customValueText = ""
    @State private var showCustomField = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("What values guide your recovery?")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text("Select up to \(VisionLimits.maxValues) values. Drag to reorder by priority.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)

                FlowLayout(spacing: 8) {
                    ForEach(CuratedValue.allCases, id: \.rawValue) { value in
                        valueChip(value.rawValue)
                    }
                }

                let customValues = viewModel.selectedValues.filter { val in
                    !CuratedValue.allCases.contains(where: { $0.rawValue == val })
                }
                if !customValues.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(customValues, id: \.self) { value in
                            valueChip(value)
                        }
                    }
                }

                if showCustomField {
                    HStack {
                        TextField("Custom value", text: $customValueText)
                            .padding(10)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Button {
                            let trimmed = customValueText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && !viewModel.selectedValues.contains(trimmed) {
                                viewModel.toggleValue(trimmed)
                                customValueText = ""
                                showCustomField = false
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color.rrPrimary)
                        }
                        .disabled(customValueText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    Button {
                        showCustomField = true
                    } label: {
                        Label("Add Custom Value", systemImage: "plus")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .disabled(viewModel.isAtValueLimit)
                }

                if viewModel.isAtValueLimit {
                    Text("Maximum \(VisionLimits.maxValues) values selected.")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrDestructive)
                }

                if !viewModel.selectedValues.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your values (drag to reorder)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        List {
                            ForEach(viewModel.selectedValues, id: \.self) { value in
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundStyle(Color.rrTextSecondary)
                                    Text(value)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                    if let index = viewModel.selectedValues.firstIndex(of: value), index < 5 {
                                        RRBadge(text: "#\(index + 1)", color: .rrPrimary)
                                    }
                                }
                            }
                            .onMove { source, destination in
                                viewModel.moveValue(from: source, to: destination)
                            }
                        }
                        .listStyle(.plain)
                        .frame(minHeight: CGFloat(viewModel.selectedValues.count) * 50)
                    }
                }
            }
            .padding()
        }
    }

    private func valueChip(_ value: String) -> some View {
        let isSelected = viewModel.selectedValues.contains(value)
        let isDisabled = !isSelected && viewModel.isAtValueLimit

        return Button {
            viewModel.toggleValue(value)
        } label: {
            Text(value)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? .white : (isDisabled ? Color.rrTextSecondary.opacity(0.5) : Color.rrPrimary))
                .background(isSelected ? Color.rrPrimary : (isDisabled ? Color.rrSurface.opacity(0.5) : Color.rrPrimary.opacity(0.1)))
                .clipShape(Capsule())
        }
        .disabled(isDisabled)
    }
}

#Preview {
    VisionValuesStepView(viewModel: VisionWizardViewModel())
}
