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

            if selectedTab == 2 {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        customTriggersTab
                    }
                    .padding(16)
                }
            } else {
                List {
                    if selectedTab == 0 {
                        myTriggersTab
                    } else {
                        allTriggersTab
                    }
                }
                .listStyle(.plain)
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

    @ViewBuilder
    private var myTriggersTab: some View {
        if viewModel.myTriggers.isEmpty && viewModel.searchQuery.isEmpty {
            Section {
                ContentUnavailableView(
                    "No triggers added yet",
                    systemImage: "bolt.trianglebadge.exclamationmark",
                    description: Text("Browse All Triggers and swipe to add triggers here.")
                )
                .frame(maxWidth: .infinity, minHeight: 300)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        } else {
            ForEach(viewModel.myTriggersGroupedByCategory, id: \.category) { group in
                Section {
                    if !viewModel.isCategoryCollapsed(group.category) {
                        ForEach(group.items) { trigger in
                            triggerRow(trigger)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        viewModel.removeFromMyTriggers(trigger.id)
                                    } label: {
                                        Label("Remove", systemImage: "minus.circle")
                                    }
                                }
                        }
                    }
                } header: {
                    categoryHeader(group.category, count: group.items.count)
                }
            }
        }
    }

    // MARK: - All Triggers Tab

    @ViewBuilder
    private var allTriggersTab: some View {
        if viewModel.filteredTriggers.isEmpty {
            Section {
                ContentUnavailableView(
                    "No triggers found",
                    systemImage: "bolt.trianglebadge.exclamationmark",
                    description: Text("Try adjusting your search.")
                )
                .frame(maxWidth: .infinity, minHeight: 300)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
        } else {
            ForEach(viewModel.groupedByCategory, id: \.category) { group in
                Section {
                    if !viewModel.isCategoryCollapsed(group.category) {
                        ForEach(group.items) { trigger in
                            allTriggersRow(trigger)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    swipeAction(for: trigger)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    swipeAction(for: trigger)
                                }
                        }
                    }
                } header: {
                    categoryHeader(group.category, count: group.items.count)
                }
            }
        }
    }

    @ViewBuilder
    private func swipeAction(for trigger: TriggerLibraryViewModel.LibraryItem) -> some View {
        if viewModel.isInMyTriggers(trigger.id) {
            Button {
                viewModel.removeFromMyTriggers(trigger.id)
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
            .tint(.rrDestructive)
        } else {
            Button {
                viewModel.addToMyTriggers(trigger.id)
            } label: {
                Label("Add to Mine", systemImage: "plus.circle")
            }
            .tint(.rrSuccess)
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

    // MARK: - Category Header

    private func categoryHeader(_ category: TriggerCategory, count: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                viewModel.toggleCategoryCollapsed(category)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: viewModel.isCategoryCollapsed(category) ? "chevron.right" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.rrTextSecondary)
                    .frame(width: 12)

                Image(systemName: category.icon)
                    .font(.subheadline)
                    .foregroundStyle(category.color)

                Text(category.displayName)
                    .font(.headline)
                    .foregroundStyle(.rrText)

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(category.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(category.color.opacity(0.15))
                    )

                Spacer()
            }
            .contentShape(Rectangle())
        }
    }

    // MARK: - Trigger Row

    private func triggerRow(_ trigger: TriggerLibraryViewModel.LibraryItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: trigger.category.icon)
                .font(.subheadline)
                .foregroundStyle(trigger.category.color)
                .frame(width: 24)

            Text(trigger.label)
                .font(.body)
                .foregroundStyle(.rrText)

            Spacer()

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

    private func allTriggersRow(_ trigger: TriggerLibraryViewModel.LibraryItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: trigger.category.icon)
                .font(.subheadline)
                .foregroundStyle(trigger.category.color)
                .frame(width: 24)

            Text(trigger.label)
                .font(.body)
                .foregroundStyle(.rrText)

            Spacer()

            if viewModel.isInMyTriggers(trigger.id) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(.rrSuccess)
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
            let item = TriggerLibraryViewModel.LibraryItem(
                id: UUID(),
                label: newTriggerLabel.trimmingCharacters(in: .whitespacesAndNewlines),
                category: newTriggerCategory,
                isCustom: true,
                useCount: 0
            )
            viewModel.allTriggers.append(item)
            viewModel.addToMyTriggers(item.id)
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

#Preview {
    NavigationStack {
        TriggerLibraryView()
    }
}
