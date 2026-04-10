import SwiftUI

// MARK: - Circle Item Detail View

/// Detail/edit view for a single circle item. Shows all fields, allows editing,
/// moving between circles, and deletion with appropriate confirmation dialogs.
struct CircleItemDetailView: View {

    // MARK: - Properties

    let apiClient: ThreeCirclesAPIClient
    let viewModel: CircleSetDetailViewModel
    let item: CircleItem

    // MARK: - State

    @Environment(\.dismiss) private var dismiss

    @State private var behaviorName: String
    @State private var notes: String
    @State private var specificityDetail: String
    @State private var category: String
    @State private var isUncertain: Bool
    @State private var selectedCircle: CircleType

    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var showMoveConfirmation = false
    @State private var hasChanges = false

    // MARK: - Init

    init(apiClient: ThreeCirclesAPIClient, viewModel: CircleSetDetailViewModel, item: CircleItem) {
        self.apiClient = apiClient
        self.viewModel = viewModel
        self.item = item

        _behaviorName = State(initialValue: item.behaviorName)
        _notes = State(initialValue: item.notes ?? "")
        _specificityDetail = State(initialValue: item.specificityDetail ?? "")
        _category = State(initialValue: item.category ?? "")
        _isUncertain = State(initialValue: item.flags?.uncertain ?? false)
        _selectedCircle = State(initialValue: item.circle)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Circle indicator
                circleHeader

                // Behavior name
                fieldSection(title: "Behavior") {
                    TextField("What is this behavior?", text: $behaviorName)
                        .font(RRFont.body)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: behaviorName) { _, _ in hasChanges = true }
                }

                // Notes
                fieldSection(title: "Notes") {
                    TextEditor(text: $notes)
                        .font(RRFont.body)
                        .frame(minHeight: 80)
                        .padding(4)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: notes) { _, _ in hasChanges = true }
                }

                // Specificity detail
                fieldSection(
                    title: "Specificity Detail",
                    subtitle: "What exactly counts as this behavior?"
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
                        .onChange(of: specificityDetail) { _, _ in hasChanges = true }
                }

                // Category
                fieldSection(title: "Category") {
                    TextField("Optional category", text: $category)
                        .font(RRFont.body)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: category) { _, _ in hasChanges = true }
                }

                // Source badge (read-only)
                if let source = item.source {
                    fieldSection(title: "Source") {
                        HStack {
                            sourceBadge(source)
                            Spacer()
                        }
                    }
                }

                // Uncertain flag
                RRCard {
                    Toggle(isOn: $isUncertain) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mark as Uncertain")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                            Text("Flag this item for sponsor review. Your sponsor can help you decide if this belongs here.")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                    .tint(Color.rrPrimary)
                    .onChange(of: isUncertain) { _, _ in hasChanges = true }
                }

                // Move to different circle
                moveCircleSection

                Divider()
                    .padding(.vertical, 4)

                // Delete button
                deleteButton

                // Metadata
                metadataSection
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle("Item Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await save() }
                }
                .disabled(!hasChanges || behaviorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            }
        }
        .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    viewModel.requestDeleteItem(item)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if item.circle == .inner {
                Text("This is an inner circle boundary. Removing it changes your bottom lines. Consider discussing this with your sponsor first.")
            } else {
                Text("Are you sure you want to remove \"\(item.behaviorName)\"?")
            }
        }
        .alert("Move Item?", isPresented: $showMoveConfirmation) {
            Button("Move") {
                Task { await performMove() }
            }
            Button("Cancel", role: .cancel) {
                selectedCircle = item.circle
            }
        } message: {
            Text("Move \"\(item.behaviorName)\" from \(item.circle.displayName) to \(selectedCircle.displayName)?")
        }
    }

    // MARK: - Subviews

    private var circleHeader: some View {
        HStack(spacing: 12) {
            RRColorDot(colorForCircle(item.circle), size: 14)
            Text(item.circle.displayName)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
            Spacer()
            if item.flags?.uncertain == true {
                HStack(spacing: 4) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Uncertain")
                        .font(RRFont.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(colorForCircle(item.circle).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func fieldSection(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(RRFont.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrText)

            if let subtitle {
                Text(subtitle)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            content()
        }
    }

    private func sourceBadge(_ source: CircleItemSource) -> some View {
        HStack(spacing: 6) {
            Image(systemName: sourceIcon(source))
                .font(.caption)
            Text(sourceLabel(source))
                .font(RRFont.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(Color.rrTextSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.rrTextSecondary.opacity(0.1))
        .clipShape(Capsule())
    }

    private var moveCircleSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Move to Circle")
                    .font(RRFont.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rrText)

                Picker("Circle", selection: $selectedCircle) {
                    ForEach(CircleType.allCases, id: \.self) { circleType in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorForCircle(circleType))
                                .frame(width: 8, height: 8)
                            Text(circleType.displayName)
                        }
                        .tag(circleType)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedCircle) { oldValue, newValue in
                    if newValue != item.circle {
                        showMoveConfirmation = true
                    }
                }
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Delete Item")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Color.rrDestructive)
            .background(Color.rrDestructive.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .accessibilityLabel("Delete \(item.behaviorName)")
        .accessibilityHint(item.circle == .inner
            ? "This is an inner circle boundary. Extra confirmation required."
            : "Removes this item from your circles")
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Created \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)

            if let modifiedAt = item.modifiedAt {
                Text("Modified \(modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(RRFont.caption2)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Actions

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let request = UpdateCircleItemRequest(
            behaviorName: behaviorName.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.isEmpty ? nil : notes,
            specificityDetail: specificityDetail.isEmpty ? nil : specificityDetail,
            category: category.isEmpty ? nil : category,
            flags: CircleItemFlags(uncertain: isUncertain)
        )

        await viewModel.updateItem(itemId: item.itemId, request: request)
        hasChanges = false
    }

    private func performMove() async {
        await viewModel.moveItem(itemId: item.itemId, to: selectedCircle)
        dismiss()
    }

    // MARK: - Helpers

    private func colorForCircle(_ type: CircleType) -> Color {
        switch type {
        case .inner: return .rrDestructive
        case .middle: return .orange
        case .outer: return .rrSuccess
        }
    }

    private func sourceIcon(_ source: CircleItemSource) -> String {
        switch source {
        case .user: return "person.fill"
        case .template: return "doc.text.fill"
        case .starterPack: return "shippingbox.fill"
        }
    }

    private func sourceLabel(_ source: CircleItemSource) -> String {
        switch source {
        case .user: return "Added by you"
        case .template: return "From template"
        case .starterPack: return "From starter pack"
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        Text("CircleItemDetailView requires dependencies")
    }
}
