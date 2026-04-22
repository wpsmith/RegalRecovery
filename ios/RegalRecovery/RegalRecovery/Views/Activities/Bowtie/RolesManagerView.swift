import SwiftUI
import SwiftData

struct RolesManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RolesManagerViewModel()

    @State private var newRoleName = ""
    @State private var selectedSuggestions: Set<String> = []

    // Edit alert state
    @State private var showEditAlert = false
    @State private var editingRole: RRUserRole?
    @State private var editLabel = ""

    // Sub-role alert state
    @State private var showSubRoleAlert = false
    @State private var subRoleParentId: UUID?
    @State private var subRoleLabel = ""

    var body: some View {
        List {
            addRoleSection
            if viewModel.activeRoles.isEmpty {
                suggestionsSection
            }
            yourRolesSection
            archivedSection
        }
        .navigationTitle("My Roles")
        .onAppear {
            viewModel.loadRoles(context: modelContext)
        }
        .alert("Edit Role", isPresented: $showEditAlert) {
            TextField("Role name", text: $editLabel)
            Button("Save") {
                if let role = editingRole, !editLabel.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.updateLabel(role, newLabel: editLabel.trimmingCharacters(in: .whitespaces), context: modelContext)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Add Sub-Role", isPresented: $showSubRoleAlert) {
            TextField("Sub-role name", text: $subRoleLabel)
            Button("Add") {
                if let parentId = subRoleParentId, !subRoleLabel.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.addSubRole(label: subRoleLabel.trimmingCharacters(in: .whitespaces), parentId: parentId, context: modelContext)
                    subRoleLabel = ""
                }
            }
            Button("Cancel", role: .cancel) {
                subRoleLabel = ""
            }
        }
    }

    // MARK: - Add Role Section

    private var addRoleSection: some View {
        Section {
            HStack {
                TextField("New role name", text: $newRoleName)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let trimmed = newRoleName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    viewModel.addRole(label: trimmed, context: modelContext)
                    newRoleName = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(Color.rrPrimary)
                        .font(.title2)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .disabled(newRoleName.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel(String(localized: "Add role"))
                .accessibilityHint(String(localized: "Double tap to add a new role"))
            }
        } header: {
            Text("Add Role")
        }
    }

    // MARK: - Your Roles Section

    private var yourRolesSection: some View {
        Section {
            ForEach(viewModel.activeRoles, id: \.id) { role in
                HStack {
                    if role.parentRoleId != nil {
                        Spacer()
                            .frame(width: 24)
                    }
                    Text(role.label)
                        .foregroundStyle(role.parentRoleId != nil ? .secondary : .primary)
                    Spacer()
                    Button {
                        subRoleParentId = role.id
                        subRoleLabel = ""
                        showSubRoleAlert = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.archiveRole(role, context: modelContext)
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        editingRole = role
                        editLabel = role.label
                        showEditAlert = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(Color.rrPrimary)
                }
            }
            .onMove { from, to in
                var roles = viewModel.activeRoles
                roles.move(fromOffsets: from, toOffset: to)
                viewModel.reorderRoles(roles, context: modelContext)
            }
        } header: {
            Text("Your Roles")
        }
    }

    // MARK: - Archived Section

    private var archivedSection: some View {
        Section {
            ForEach(viewModel.archivedRoles, id: \.id) { role in
                Text(role.label)
                    .foregroundStyle(.secondary)
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            viewModel.unarchiveRole(role, context: modelContext)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }
                        .tint(Color.rrPrimary)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            viewModel.deleteRole(role, context: modelContext)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        } header: {
            Text("Archived")
        }
    }

    // MARK: - Suggestions Section

    private var suggestionsSection: some View {
        Section {
            FlowLayout(spacing: 8) {
                ForEach(RoleSuggestions.defaults, id: \.self) { suggestion in
                    Button {
                        if selectedSuggestions.contains(suggestion) {
                            selectedSuggestions.remove(suggestion)
                        } else {
                            selectedSuggestions.insert(suggestion)
                            viewModel.addRole(label: suggestion, context: modelContext)
                        }
                    } label: {
                        Text(suggestion)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedSuggestions.contains(suggestion)
                                    ? Color.rrPrimary.opacity(0.2)
                                    : Color.rrSurface
                            )
                            .foregroundStyle(
                                selectedSuggestions.contains(suggestion)
                                    ? Color.rrPrimary
                                    : .primary
                            )
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedSuggestions.contains(suggestion)
                                            ? Color.rrPrimary
                                            : Color.gray.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedSuggestions.contains(suggestion) ? .isSelected : [])
                    .accessibilityLabel(suggestion)
                    .accessibilityHint(selectedSuggestions.contains(suggestion) ? String(localized: "Double tap to deselect") : String(localized: "Double tap to select"))
                }
            }
        } header: {
            Text("Suggestions")
        }
    }
}
