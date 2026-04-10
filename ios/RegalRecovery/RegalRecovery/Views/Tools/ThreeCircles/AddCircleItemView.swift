import SwiftUI

// MARK: - Add Circle Item View

/// Sheet for adding a new item to a circle. Shows circle selector, behavior name,
/// notes, specificity detail, and category picker. Displays an advisory when
/// adding to the inner circle.
struct AddCircleItemView: View {

    // MARK: - Properties

    let apiClient: ThreeCirclesAPIClient
    let viewModel: CircleSetDetailViewModel

    // MARK: - State

    @Environment(\.dismiss) private var dismiss

    @State private var selectedCircle: CircleType = .outer
    @State private var behaviorName = ""
    @State private var notes = ""
    @State private var specificityDetail = ""
    @State private var category = ""
    @State private var isUncertain = false
    @State private var isSaving = false
    @State private var showInnerAdvisory = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Circle selector
                    circleSelector

                    // Inner circle advisory
                    if selectedCircle == .inner {
                        innerCircleAdvisory
                    }

                    // Behavior name (required)
                    fieldSection(
                        title: "Behavior",
                        required: true
                    ) {
                        TextField("What is this behavior?", text: $behaviorName)
                            .font(RRFont.body)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Notes (optional)
                    fieldSection(title: "Notes") {
                        TextEditor(text: $notes)
                            .font(RRFont.body)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Specificity detail (optional)
                    fieldSection(
                        title: "Specificity Detail",
                        subtitle: "What exactly counts as this behavior? Being specific helps with accountability."
                    ) {
                        TextEditor(text: $specificityDetail)
                            .font(RRFont.body)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                            )
                    }

                    // Category (optional)
                    fieldSection(title: "Category") {
                        TextField("Optional category (e.g., digital, relational)", text: $category)
                            .font(RRFont.body)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Uncertain flag
                    RRCard {
                        Toggle(isOn: $isUncertain) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mark as Uncertain")
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                                Text("Not sure this belongs here? Flag it for your sponsor to review.")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                        .tint(Color.rrPrimary)
                    }

                    // Save button
                    RRButton("Add Item", icon: "plus") {
                        Task { await addItem() }
                    }
                    .disabled(!isValid || isSaving)
                    .opacity(isValid && !isSaving ? 1.0 : 0.5)

                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var circleSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Which circle?")
                .font(RRFont.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrText)

            HStack(spacing: 12) {
                ForEach(CircleType.allCases, id: \.self) { circleType in
                    circleOption(circleType)
                }
            }
        }
    }

    private func circleOption(_ circleType: CircleType) -> some View {
        let isSelected = selectedCircle == circleType
        let color = colorForCircle(circleType)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCircle = circleType
            }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .stroke(color, lineWidth: isSelected ? 3 : 1.5)
                    .background(
                        Circle().fill(isSelected ? color.opacity(0.15) : Color.clear)
                    )
                    .frame(width: 44, height: 44)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(color)
                        }
                    }

                Text(circleType.displayName)
                    .font(RRFont.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? color : Color.rrTextSecondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(circleType.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var innerCircleAdvisory: some View {
        RRCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.rrDestructive)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Inner Circle Item")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Text("Inner circle items are your hard boundaries — the behaviors you are committed to completely avoiding. Adding something here means you consider it a bottom line. Be thoughtful and specific. If you are unsure, consider placing it in the middle circle first and discussing with your sponsor.")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.rrDestructive.opacity(0.3), lineWidth: 1)
        )
    }

    private func fieldSection(
        title: String,
        required: Bool = false,
        subtitle: String? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(title)
                    .font(RRFont.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rrText)
                if required {
                    Text("*")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrDestructive)
                }
            }

            if let subtitle {
                Text(subtitle)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            content()
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !behaviorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func addItem() async {
        isSaving = true
        defer { isSaving = false }

        let request = CreateCircleItemRequest(
            circle: selectedCircle,
            behaviorName: behaviorName.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines),
            specificityDetail: specificityDetail.isEmpty ? nil : specificityDetail.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category.isEmpty ? nil : category.trimmingCharacters(in: .whitespacesAndNewlines),
            flags: isUncertain ? CircleItemFlags(uncertain: true) : nil
        )

        await viewModel.addItem(request: request)

        if viewModel.actionError == nil {
            dismiss()
        }
    }

    // MARK: - Helpers

    private func colorForCircle(_ type: CircleType) -> Color {
        switch type {
        case .inner: return .rrDestructive
        case .middle: return .orange
        case .outer: return .rrSuccess
        }
    }
}

// MARK: - Preview

#Preview {
    Text("AddCircleItemView requires dependencies")
}
