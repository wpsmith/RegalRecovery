import SwiftData
import SwiftUI

struct RecoveryPlanSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RecoveryPlanViewModel()
    @State private var showingActivityPicker = false
    @State private var showUnsavedAlert = false
    @State private var showAlgorithmDebug = false
    @State private var editMode: EditMode = .active

    var body: some View {
        List {
            // MARK: - Overload Warning
            if viewModel.showOverloadWarning {
                Section {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("You've planned \(viewModel.enabledCount) activities. Recovery works best when your plan is sustainable.")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrText)
                    }
                }
            }

            // MARK: - Activity List
            if viewModel.planItems.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 16)
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.rrPrimary.opacity(0.5))
                        Text("Tap + to add your first recovery activity")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Spacer().frame(height: 16)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
                }
            } else {
                Section {
                    ForEach($viewModel.planItems) { $item in
                        PlanActivityRowView(
                            item: $item,
                            siblingCount: viewModel.siblingCount(for: item.activity.activityType)
                        )
                    }
                    .onDelete { offsets in
                        viewModel.planItems.remove(atOffsets: offsets)
                        viewModel.hasUnsavedChanges = true
                    }
                    .onMove { source, destination in
                        viewModel.moveActivity(from: source, to: destination)
                    }
                } header: {
                    HStack {
                        Text("\(viewModel.enabledCount) activities")
                        Spacer()
                        Text("Drag to reorder")
                            .font(RRFont.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            }

            // MARK: - Score + Save
            Section {
                if let error = viewModel.saveError {
                    Text(error)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrDestructive)
                }

                RRButton("Save Plan", icon: "checkmark.circle") {
                    viewModel.save(context: modelContext)
                }
                .disabled(viewModel.isSaving)
            }

            // MARK: - Debug
            if FeatureFlagStore.shared.isEnabled("feature.analytics-dashboard") {
                Section {
                    Button {
                        showAlgorithmDebug = true
                    } label: {
                        HStack {
                            Image(systemName: "ladybug.fill")
                                .foregroundStyle(.orange)
                            Text("Score Algorithm Debug")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                } header: {
                    Text("Debug")
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingActivityPicker = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(viewModel.availableActivities.isEmpty)
            }
        }
        .sheet(isPresented: $showingActivityPicker) {
            ActivityPickerSheet(
                availableActivities: viewModel.availableActivities,
                onSelect: { activity in
                    viewModel.addActivity(activity)
                    showingActivityPicker = false
                }
            )
        }
        .sheet(isPresented: $showAlgorithmDebug) {
            NavigationStack {
                ScrollView {
                    Text(viewModel.scoreAlgorithmDebug())
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color.rrText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color.rrBackground)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showAlgorithmDebug = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .alert("Unsaved Changes", isPresented: $showUnsavedAlert) {
            Button("Save & Exit") {
                viewModel.save(context: modelContext)
                dismiss()
            }
            Button("Exit Without Saving", role: .destructive) {
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You have unsaved changes to your recovery plan.")
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
        .navigationBarBackButtonHidden(viewModel.hasUnsavedChanges)
        .onAppear {
            viewModel.load(context: modelContext)
        }
        .onChange(of: viewModel.didSave) { _, saved in
            if saved { dismiss() }
        }
        .onChange(of: viewModel.planItems) {
            viewModel.checkForChanges()
        }
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
                }
            }
        }
    }
}

// MARK: - Activity Picker Sheet

private struct ActivityPickerSheet: View {
    let availableActivities: [DailyEligibleActivity]
    let onSelect: (DailyEligibleActivity) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var groupedActivities: [(section: String, activities: [DailyEligibleActivity])] {
        let filtered: [DailyEligibleActivity]
        if searchText.isEmpty {
            filtered = availableActivities
        } else {
            filtered = availableActivities.filter {
                $0.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        var groups: [String: [DailyEligibleActivity]] = [:]
        for activity in filtered {
            let sectionName: String
            if let at = ActivityType(rawValue: activity.activityType) {
                sectionName = at.section.rawValue
            } else {
                sectionName = "Other"
            }
            groups[sectionName, default: []].append(activity)
        }

        let sectionOrder = ActivitySection.allCases.map(\.rawValue) + ["Other"]
        return sectionOrder.compactMap { name in
            guard let items = groups[name], !items.isEmpty else { return nil }
            return (section: name, activities: items)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedActivities, id: \.section) { group in
                    Section(group.section) {
                        ForEach(group.activities, id: \.activityType) { activity in
                            Button {
                                onSelect(activity)
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: activity.icon)
                                        .font(.caption)
                                        .foregroundStyle(iconColor(for: activity))
                                        .frame(width: 22, height: 22)
                                    Text(activity.displayName)
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func iconColor(for activity: DailyEligibleActivity) -> Color {
        if let at = ActivityType(rawValue: activity.activityType) {
            return at.iconColor
        }
        return .rrPrimary
    }
}

#Preview {
    NavigationStack {
        RecoveryPlanSetupView()
    }
}
