import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct QuickActionsRow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = QuickActionsViewModel()
    @State private var showFASTER = false
    @State private var isEditing = false
    @State private var showActionPicker = false
    @State private var draggedItemId: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RRSectionHeader(title: String(localized: "Quick Actions"))
                Spacer()
                if isEditing {
                    Button {
                        exitEditMode()
                    } label: {
                        Text("Done")
                            .font(RRFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .transition(.opacity)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.items) { item in
                        quickActionCapsule(item)
                    }

                    if isEditing {
                        addButton
                    }
                }
                .padding(.vertical, isEditing ? 4 : 0)
            }
            .padding(.vertical, isEditing ? 4 : 0)
            .padding(.horizontal, isEditing ? -2 : 0)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        Color.rrPrimary.opacity(isEditing ? 0.25 : 0),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
                    .padding(.horizontal, isEditing ? -6 : 0)
                    .padding(.vertical, isEditing ? -2 : 0)
            )
            .animation(.easeInOut(duration: 0.2), value: isEditing)
        }
        .fullScreenCover(isPresented: $showFASTER) {
            FASTERCheckInFlowView()
        }
        .sheet(isPresented: $showActionPicker) {
            QuickActionInlinePickerSheet(
                availableActions: viewModel.availableActions,
                onSelect: { definition in
                    viewModel.addAction(definition)
                    showActionPicker = false
                }
            )
        }
        .task {
            viewModel.load(context: modelContext)
        }
    }

    // MARK: - Capsule

    @ViewBuilder
    private func quickActionCapsule(_ item: QuickActionItemState) -> some View {
        let label = quickActionLabel(item.definition.shortTitle, icon: item.definition.icon)

        if isEditing {
            label
                .overlay(alignment: .topTrailing) {
                    if viewModel.canRemove {
                        deleteButton(for: item)
                    }
                }
                .opacity(draggedItemId == item.id ? 0.4 : 1.0)
                .onDrag {
                    draggedItemId = item.id
                    return NSItemProvider(object: item.id.uuidString as NSString)
                }
                .onDrop(of: [UTType.text], delegate: QuickActionDropDelegate(
                    targetId: item.id,
                    draggedItemId: $draggedItemId,
                    viewModel: viewModel
                ))
        } else {
            if item.definition.presentationStyle == .fullScreenCover {
                Button {
                    showFASTER = true
                } label: {
                    label
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    enterEditMode()
                }
            } else {
                NavigationLink {
                    ActivityDestinationView(activityType: item.definition.id)
                } label: {
                    label
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    enterEditMode()
                }
            }
        }
    }

    // MARK: - Delete Badge

    private func deleteButton(for item: QuickActionItemState) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.removeAction(id: item.id)
            }
            if viewModel.items.isEmpty {
                exitEditMode()
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white, Color.rrDestructive)
        }
        .offset(x: 6, y: -6)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            if viewModel.canAddMore && !viewModel.availableActions.isEmpty {
                showActionPicker = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(viewModel.canAddMore && !viewModel.availableActions.isEmpty
                    ? Color.rrPrimary
                    : Color.rrTextSecondary.opacity(0.5))
                .background(Color.rrPrimary.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.rrPrimary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                )
        }
        .disabled(!viewModel.canAddMore || viewModel.availableActions.isEmpty)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    // MARK: - Label

    private func quickActionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(RRFont.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(Color.rrPrimary)
        .background(Color.rrPrimary.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Edit Mode

    private func enterEditMode() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditing = true
        }
    }

    private func exitEditMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isEditing = false
        }
        if viewModel.hasUnsavedChanges {
            viewModel.save(context: modelContext)
        }
    }
}

// MARK: - Drop Delegate

private struct QuickActionDropDelegate: DropDelegate {
    let targetId: UUID
    @Binding var draggedItemId: UUID?
    let viewModel: QuickActionsViewModel

    func performDrop(info: DropInfo) -> Bool {
        draggedItemId = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let sourceId = draggedItemId, sourceId != targetId else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.moveAction(fromId: sourceId, toId: targetId)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Inline Picker Sheet

private struct QuickActionInlinePickerSheet: View {
    let availableActions: [QuickActionDefinition]
    let onSelect: (QuickActionDefinition) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var groupedActions: [(section: String, actions: [QuickActionDefinition])] {
        let filtered: [QuickActionDefinition]
        if searchText.isEmpty {
            filtered = availableActions
        } else {
            filtered = availableActions.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        var groups: [String: [QuickActionDefinition]] = [:]
        for action in filtered {
            groups[action.section.rawValue, default: []].append(action)
        }

        let sectionOrder = ActivitySection.allCases.map(\.rawValue)
        return sectionOrder.compactMap { name in
            guard let items = groups[name], !items.isEmpty else { return nil }
            return (section: name, actions: items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedActions, id: \.section) { group in
                    Section(group.section) {
                        ForEach(group.actions) { action in
                            Button {
                                onSelect(action)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: action.icon)
                                        .font(.caption)
                                        .foregroundStyle(action.iconColor)
                                        .frame(width: 22, height: 22)
                                    Text(action.displayName)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.rrText)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Color.rrPrimary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $searchText, prompt: "Search activities")
            .navigationTitle("Add Quick Action")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        QuickActionsRow()
            .padding()
            .background(Color.rrBackground)
            .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
    }
}
