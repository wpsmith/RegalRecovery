import SwiftUI

// MARK: - Review Reflection View

/// Per-circle reflection step during the quarterly review.
///
/// Shows current items for one circle type with a reflection prompt.
/// Users can confirm items look right or make inline edits.
/// Change tracking feeds back to the quarterly review summary.
struct ReviewReflectionView: View {

    let circleType: CircleType
    let items: [CircleItem]
    let onChangesRecorded: ([String]) -> Void

    @State private var wantsChanges = false
    @State private var editableItems: [EditableCircleItem] = []
    @State private var newItemName = ""
    @State private var localChanges: [String] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Circle Header
                circleHeader

                // MARK: - Reflection Prompt
                reflectionPrompt

                // MARK: - Current Items
                currentItemsList

                // MARK: - Change Toggle
                changeToggle

                // MARK: - Inline Editor
                if wantsChanges {
                    inlineEditor
                }

                Spacer().frame(height: 20)
            }
            .padding()
        }
        .onAppear {
            editableItems = items.map { EditableCircleItem(from: $0) }
        }
        .onDisappear {
            onChangesRecorded(localChanges)
        }
    }

    // MARK: - Circle Header

    private var circleHeader: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(circleType.displayColor)
                .frame(width: 16, height: 16)

            Text(circleType.displayName)
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
        }
        .padding(.top, 16)
    }

    // MARK: - Reflection Prompt

    private var reflectionPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(promptForCircle)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .fixedSize(horizontal: false, vertical: true)

            Text(subPromptForCircle)
                .font(RRFont.footnote)
                .foregroundStyle(Color.rrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.rrPrimary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var promptForCircle: String {
        switch circleType {
        case .inner:
            return String(localized: "Are your bottom lines still accurate? Has anything changed in what you need to completely avoid?")
        case .middle:
            return String(localized: "Do your warning signs still ring true? Have you noticed new patterns that should be here?")
        case .outer:
            return String(localized: "Are your healthy behaviors still serving you? Is there anything new that has been helping?")
        }
    }

    private var subPromptForCircle: String {
        switch circleType {
        case .inner:
            return String(localized: "Recovery evolves. What felt like a clear line months ago might need adjusting, and that is okay.")
        case .middle:
            return String(localized: "Middle circle items are your early warning system. Keeping them accurate helps you stay aware.")
        case .outer:
            return String(localized: "Your outer circle is your foundation. It should reflect what actually supports your recovery today.")
        }
    }

    // MARK: - Current Items List

    private var currentItemsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current items (\(items.count))")
                .font(RRFont.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrTextSecondary)

            if items.isEmpty {
                Text("No items in this circle yet.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(items) { item in
                    HStack(spacing: 10) {
                        RRColorDot(circleType.displayColor, size: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.behaviorName)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)

                            if let notes = item.notes, !notes.isEmpty {
                                Text(notes)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        if item.flags?.uncertain == true {
                            RRBadge(text: "Uncertain", color: .orange)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Change Toggle

    private var changeToggle: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation { wantsChanges = false }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: wantsChanges ? "circle" : "checkmark.circle.fill")
                        .foregroundStyle(wantsChanges ? Color.rrTextSecondary : Color.rrSuccess)
                    Text("This looks right")
                        .font(RRFont.subheadline)
                        .foregroundStyle(wantsChanges ? Color.rrTextSecondary : Color.rrText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(wantsChanges ? Color.clear : Color.rrSuccess.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(wantsChanges ? Color.rrTextSecondary.opacity(0.3) : Color.rrSuccess.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                withAnimation { wantsChanges = true }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: wantsChanges ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(wantsChanges ? Color.rrPrimary : Color.rrTextSecondary)
                    Text("I want to make changes")
                        .font(RRFont.subheadline)
                        .foregroundStyle(wantsChanges ? Color.rrText : Color.rrTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(wantsChanges ? Color.rrPrimary.opacity(0.1) : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(wantsChanges ? Color.rrPrimary.opacity(0.3) : Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Inline Editor

    private var inlineEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Items")
                .font(RRFont.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrText)

            // Existing items with remove option
            ForEach($editableItems) { $item in
                HStack {
                    TextField("Behavior name", text: $item.name)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: item.name) { _, newName in
                            if newName != item.originalName {
                                recordChange("Updated \"\(item.originalName)\" to \"\(newName)\" in \(circleType.displayName)")
                            }
                        }

                    Button {
                        recordChange("Removed \"\(item.name)\" from \(circleType.displayName)")
                        editableItems.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Color.rrDestructive)
                    }
                }
            }

            // Add new item
            HStack {
                TextField("Add new item...", text: $newItemName)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addNewItem)

                Button(action: addNewItem) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.rrPrimary)
                }
                .disabled(newItemName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Actions

    private func addNewItem() {
        let trimmed = newItemName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        editableItems.append(EditableCircleItem(
            id: UUID().uuidString,
            name: trimmed,
            originalName: trimmed
        ))
        recordChange("Added \"\(trimmed)\" to \(circleType.displayName)")
        newItemName = ""
    }

    private func recordChange(_ description: String) {
        if !localChanges.contains(description) {
            localChanges.append(description)
        }
    }
}

// MARK: - Editable Circle Item

private struct EditableCircleItem: Identifiable {
    let id: String
    var name: String
    let originalName: String

    init(from item: CircleItem) {
        self.id = item.itemId
        self.name = item.behaviorName
        self.originalName = item.behaviorName
    }

    init(id: String, name: String, originalName: String) {
        self.id = id
        self.name = name
        self.originalName = originalName
    }
}

#Preview {
    ReviewReflectionView(
        circleType: .inner,
        items: [
            CircleItem(itemId: "1", circle: .inner, behaviorName: "Pornography", notes: nil, specificityDetail: nil, category: nil, source: .user, flags: nil, createdAt: Date(), modifiedAt: nil),
            CircleItem(itemId: "2", circle: .inner, behaviorName: "Masturbation", notes: "Any form", specificityDetail: nil, category: nil, source: .user, flags: CircleItemFlags(uncertain: true), createdAt: Date(), modifiedAt: nil),
        ],
        onChangesRecorded: { _ in }
    )
}
