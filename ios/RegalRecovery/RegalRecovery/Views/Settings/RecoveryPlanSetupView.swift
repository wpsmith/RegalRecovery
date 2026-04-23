import SwiftData
import SwiftUI

struct RecoveryPlanSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = RecoveryPlanViewModel()
    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    @Query(filter: #Predicate<RRDailyPlanItem> { $0.isEnabled == true }) private var planItems: [RRDailyPlanItem]

    @State private var showingActivityPicker = false
    @State private var showUnsavedAlert = false
@State private var editMode: EditMode = .active
    @State private var showCommitmentSetupPrompt = false
    @State private var pendingActivity: DailyEligibleActivity?
    @State private var showCommitmentSetup = false

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
                    if activity.activityType == ActivityType.sobrietyCommitment.rawValue
                        && !CommitmentStatementsManager.shared.hasCustomized {
                        pendingActivity = activity
                        showCommitmentSetupPrompt = true
                    } else {
                        viewModel.addActivity(activity)
                    }
                    showingActivityPicker = false
                }
            )
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
        .alert("Set Up Commitments", isPresented: $showCommitmentSetupPrompt) {
            Button("Use Recommended") {
                if let activity = pendingActivity {
                    let addictionNames = addictions.map(\.name)
                    let today = Calendar.current.component(.weekday, from: Date())
                    let hasMeeting = planItems.contains { $0.activityType == "Meetings Attended" && $0.daysOfWeek.contains(today) }
                    CommitmentStatementsManager.shared.morningStatements = CommitmentStatementsManager.dynamicMorningDefaults(addictions: addictionNames, hasMeetingToday: hasMeeting)
                    viewModel.addActivity(activity)
                    pendingActivity = nil
                }
            }
            Button("Set My Own") {
                showCommitmentSetup = true
            }
            Button("Cancel", role: .cancel) {
                pendingActivity = nil
            }
        } message: {
            Text("Your morning commitment statements haven't been configured yet. Would you like to use the recommended defaults or set your own?")
        }
        .fullScreenCover(isPresented: $showCommitmentSetup) {
            NavigationStack {
                CommitmentSetupView {
                    showCommitmentSetup = false
                    if let activity = pendingActivity {
                        viewModel.addActivity(activity)
                        pendingActivity = nil
                    }
                }
            }
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
                                    Group {
                                        if activity.icon.hasPrefix("asset:") {
                                            Image(String(activity.icon.dropFirst(6)))
                                                .renderingMode(.template)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 14, height: 14)
                                        } else {
                                            Image(systemName: activity.icon)
                                                .font(.caption)
                                        }
                                    }
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
