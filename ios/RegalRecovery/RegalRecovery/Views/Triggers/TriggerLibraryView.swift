import SwiftUI

struct TriggerLibraryView: View {
    @State private var viewModel = TriggerLibraryViewModel()
    @State private var selectedTab = 0
    @State private var showAddCustom = false
    @State private var newTriggerLabel = ""
    @State private var newTriggerCategory: TriggerCategory = .emotional
    @State private var validationMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Picker("Tab", selection: $selectedTab) {
                Text("My Triggers").tag(0)
                Text("All Triggers").tag(1)
                Text("Custom").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            searchBar

            ScrollView {
                LazyVStack(spacing: 12) {
                    if selectedTab == 0 {
                        myTriggersTab
                    } else if selectedTab == 1 {
                        allTriggersTab
                    } else {
                        customTriggersTab
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle("Trigger Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddCustom = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCustom) {
            addCustomTriggerSheet
        }
        .task {
            if viewModel.allTriggers.isEmpty {
                viewModel.allTriggers = TriggerSeedData.allTriggers.map { seed in
                    TriggerLibraryViewModel.LibraryItem(
                        id: UUID(),
                        label: seed.label,
                        category: seed.category,
                        isCustom: false,
                        useCount: 0
                    )
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.rrTextSecondary)
                .font(.subheadline)

            TextField("Search triggers", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.rrTextSecondary)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - My Triggers Tab

    private var myTriggersTab: some View {
        Group {
            if viewModel.filteredTriggers.isEmpty {
                ContentUnavailableView(
                    "No triggers found",
                    systemImage: "bolt.trianglebadge.exclamationmark",
                    description: Text("Try adjusting your search or browse all triggers.")
                )
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                ForEach(viewModel.filteredTriggers.sorted(by: { $0.useCount > $1.useCount })) { trigger in
                    triggerRow(trigger)
                }
            }
        }
    }

    // MARK: - All Triggers Tab

    private var allTriggersTab: some View {
        Group {
            if viewModel.filteredTriggers.isEmpty {
                ContentUnavailableView(
                    "No triggers found",
                    systemImage: "bolt.trianglebadge.exclamationmark",
                    description: Text("Try adjusting your search.")
                )
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                ForEach(viewModel.groupedByCategory, id: \.category) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        // Section header
                        HStack(spacing: 8) {
                            Image(systemName: group.category.icon)
                                .font(.subheadline)
                                .foregroundStyle(group.category.color)

                            Text(group.category.displayName)
                                .font(.headline)
                                .foregroundStyle(.rrText)

                            Text("\(group.items.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(group.category.color)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(group.category.color.opacity(0.15))
                                )

                            Spacer()
                        }
                        .padding(.top, 8)

                        // Items in this category
                        ForEach(group.items) { trigger in
                            triggerRow(trigger)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Custom Triggers Tab

    private var customTriggersTab: some View {
        Group {
            if viewModel.customTriggers.isEmpty {
                ContentUnavailableView(
                    "No Custom Triggers",
                    systemImage: "plus.circle.dashed",
                    description: Text("Tap the + button to add your own custom triggers.")
                )
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                ForEach(viewModel.customTriggers) { trigger in
                    triggerRow(trigger)
                }
            }
        }
    }

    // MARK: - Trigger Row

    private func triggerRow(_ trigger: TriggerLibraryViewModel.LibraryItem) -> some View {
        HStack(spacing: 12) {
            // Category icon
            Image(systemName: trigger.category.icon)
                .font(.subheadline)
                .foregroundStyle(trigger.category.color)
                .frame(width: 24)

            // Label
            Text(trigger.label)
                .font(.body)
                .foregroundStyle(.rrText)

            Spacer()

            // Use count badge (if > 0)
            if trigger.useCount > 0 {
                Text("\(trigger.useCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.rrTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(.tertiarySystemBackground))
                    )
            }

            // Edit icon (if custom)
            if trigger.isCustom {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundStyle(.rrPrimary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Add Custom Trigger Sheet

    private var addCustomTriggerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Trigger name", text: $newTriggerLabel)
                        .textInputAutocapitalization(.sentences)
                } header: {
                    Text("Name")
                }

                Section {
                    Picker("Category", selection: $newTriggerCategory) {
                        ForEach(TriggerCategory.allCases) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                                Text(category.displayName)
                            }
                            .tag(category)
                        }
                    }
                } header: {
                    Text("Category")
                }

                if let message = validationMessage {
                    Section {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.rrDestructive)
                    }
                }
            }
            .navigationTitle("Add Custom Trigger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        resetForm()
                        showAddCustom = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCustomTrigger()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        let result = viewModel.validateCustomTrigger(label: newTriggerLabel, category: newTriggerCategory)
        validationMessage = result.message
        return result.isValid
    }

    private func addCustomTrigger() {
        let result = viewModel.validateCustomTrigger(label: newTriggerLabel, category: newTriggerCategory)

        if result.isValid {
            // In real implementation, this would add to repository/database
            // For now, just dismiss
            resetForm()
            showAddCustom = false
        } else {
            validationMessage = result.message
        }
    }

    private func resetForm() {
        newTriggerLabel = ""
        newTriggerCategory = .emotional
        validationMessage = nil
    }
}

#Preview("My Triggers") {
    TriggerLibraryView()
}

#Preview("Empty Custom") {
    let view = TriggerLibraryView()
    // Note: selectedTab state cannot be set directly in preview
    view
}
