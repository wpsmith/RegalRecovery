import SwiftUI
import SwiftData

struct QuickActionsCustomizeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: QuickActionsViewModel

    @State private var showingPicker = false
    @State private var showUnsavedAlert = false
    @State private var editMode: EditMode = .active

    var body: some View {
        NavigationStack {
            List {
                if viewModel.items.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Spacer().frame(height: 16)
                            Image(systemName: "bolt.circle")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.rrPrimary.opacity(0.5))
                            Text("Tap + to add a quick action")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Spacer().frame(height: 16)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                    }
                } else {
                    Section {
                        ForEach(viewModel.items) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.definition.icon)
                                    .font(.body)
                                    .foregroundStyle(item.definition.iconColor)
                                    .frame(width: 28, height: 28)
                                Text(item.definition.displayName)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                        .onDelete { offsets in
                            viewModel.removeAction(at: offsets)
                        }
                        .onMove { source, destination in
                            viewModel.moveAction(from: source, to: destination)
                        }
                    } header: {
                        HStack {
                            Text("\(viewModel.items.count) quick actions")
                            Spacer()
                            Text("Drag to reorder")
                                .font(RRFont.caption2)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    } footer: {
                        Text("Minimum 1, maximum 10 quick actions.")
                            .font(RRFont.caption)
                    }
                }

                Section {
                    Button {
                        viewModel.resetToDefaults()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(Color.rrPrimary)
                            Text("Reset to Defaults")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }
                }

                Section {
                    if let error = viewModel.saveError {
                        Text(error)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrDestructive)
                    }

                    RRButton("Save", icon: "checkmark.circle") {
                        viewModel.save(context: modelContext)
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, $editMode)
            .deleteDisabled(!viewModel.canRemove)
            .navigationTitle("Customize Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.hasUnsavedChanges {
                        Button {
                            showUnsavedAlert = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                Text("Back")
                            }
                        }
                    } else {
                        Button("Done") { dismiss() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .disabled(!viewModel.canAddMore || viewModel.availableActions.isEmpty)
                }
            }
            .sheet(isPresented: $showingPicker) {
                QuickActionPickerSheet(
                    availableActions: viewModel.availableActions,
                    onSelect: { definition in
                        viewModel.addAction(definition)
                        showingPicker = false
                    }
                )
            }
            .alert("Unsaved Changes", isPresented: $showUnsavedAlert) {
                Button("Save & Close") {
                    viewModel.save(context: modelContext)
                    dismiss()
                }
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You have unsaved changes to your quick actions.")
            }
            .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
            .navigationBarBackButtonHidden(viewModel.hasUnsavedChanges)
            .onChange(of: viewModel.didSave) { _, saved in
                if saved { dismiss() }
            }
        }
    }
}

// MARK: - Quick Action Picker Sheet

private struct QuickActionPickerSheet: View {
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
    QuickActionsCustomizeView(viewModel: QuickActionsViewModel())
}
