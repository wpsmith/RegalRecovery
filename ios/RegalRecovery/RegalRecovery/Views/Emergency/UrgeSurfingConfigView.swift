import SwiftUI
import SwiftData

struct UrgeSurfingConfigView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<RRSupportContact> { $0.role == "sponsor" })
    private var sponsors: [RRSupportContact]

    @State private var timerMinutes: Int
    @State private var selectedActivityIds: [String]
    @State private var showingActivityPicker = false

    private var hasSponsor: Bool { !sponsors.isEmpty }

    private static let timerOptions = [5, 10, 15, 20, 25, 30]
    private static let maxSelectableActivities = 3

    private static let defaultSelectableActivities = [
        ActivityType.prayer.rawValue,
        ActivityType.affirmationLog.rawValue,
    ]

    init() {
        let stored = UserDefaults.standard.integer(forKey: "urgeSurfing.timerMinutes")
        let minutes = stored > 0 ? stored : 20
        _timerMinutes = State(initialValue: minutes)

        if let data = UserDefaults.standard.data(forKey: "urgeSurfing.selectableActivities"),
           let ids = try? JSONDecoder().decode([String].self, from: data) {
            _selectedActivityIds = State(initialValue: ids)
        } else {
            _selectedActivityIds = State(initialValue: Self.defaultSelectableActivities)
        }
    }

    var body: some View {
        List {
            timerSection
            permanentActivitiesSection
            selectableActivitiesSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Urge Surfing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingActivityPicker) {
            ActivityPickerSheet(
                currentIds: selectedActivityIds,
                onSelect: { id in
                    guard selectedActivityIds.count < Self.maxSelectableActivities else { return }
                    selectedActivityIds.append(id)
                    saveSelectableActivities()
                    showingActivityPicker = false
                }
            )
        }
    }

    // MARK: - Timer Section

    private var timerSection: some View {
        Section {
            Picker(String(localized: "Timer Length"), selection: $timerMinutes) {
                ForEach(Self.timerOptions, id: \.self) { minutes in
                    Text("\(minutes) minutes").tag(minutes)
                }
            }
            .onChange(of: timerMinutes) { _, newValue in
                UserDefaults.standard.set(newValue, forKey: "urgeSurfing.timerMinutes")
            }
        } header: {
            Text("Timer")
        } footer: {
            Text("How long the urge surfing timer runs. Most urges peak and subside within 15-20 minutes.")
        }
    }

    // MARK: - Permanent Activities Section

    private var permanentActivitiesSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "wind")
                    .font(.body)
                    .foregroundStyle(.cyan)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Breathing Exercise")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                    Text("Always available")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            if hasSponsor {
                HStack(spacing: 12) {
                    Image(systemName: "phone.fill")
                        .font(.body)
                        .foregroundStyle(.green)
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Call Sponsor")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                        Text("Shown when sponsor is configured")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        } header: {
            Text("Permanent Activities")
        } footer: {
            if !hasSponsor {
                Text("Call Sponsor will appear automatically once you add a sponsor to your Support Network.")
            } else {
                Text("These activities are always shown during urge surfing and cannot be removed.")
            }
        }
    }

    // MARK: - Selectable Activities Section

    private var selectableActivitiesSection: some View {
        Section {
            ForEach(selectedActivityIds, id: \.self) { activityId in
                if let activity = Self.selectableActivityOption(for: activityId) {
                    HStack(spacing: 12) {
                        Image(systemName: activity.icon)
                            .font(.body)
                            .foregroundStyle(activity.iconColor)
                            .frame(width: 28, height: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.displayName)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                            if let note = activity.note {
                                Text(note)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                        Spacer()
                        Button {
                            removeSelectableActivity(activityId)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if selectedActivityIds.count < Self.maxSelectableActivities {
                Button {
                    showingActivityPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.rrPrimary)
                        Text("Add Activity")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }
        } header: {
            HStack {
                Text("Companion Activities")
                Spacer()
                Text("\(selectedActivityIds.count)/\(Self.maxSelectableActivities)")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        } footer: {
            Text("Choose up to \(Self.maxSelectableActivities) activities to show as companion tools during the urge surfing timer.")
        }
    }

    // MARK: - Helpers

    private func removeSelectableActivity(_ id: String) {
        selectedActivityIds.removeAll { $0 == id }
        saveSelectableActivities()
    }

    private func saveSelectableActivities() {
        if let data = try? JSONEncoder().encode(selectedActivityIds) {
            UserDefaults.standard.set(data, forKey: "urgeSurfing.selectableActivities")
        }
    }

    // MARK: - Activity Options

    struct SelectableActivityOption {
        let id: String
        let displayName: String
        let icon: String
        let iconColor: Color
        let note: String?
    }

    static let allSelectableOptions: [SelectableActivityOption] = [
        SelectableActivityOption(
            id: ActivityType.prayer.rawValue,
            displayName: String(localized: "Prayer"),
            icon: "hands.and.sparkles.fill",
            iconColor: .rrPrimary,
            note: String(localized: "(Serenity Prayer)")
        ),
        SelectableActivityOption(
            id: ActivityType.affirmationLog.rawValue,
            displayName: String(localized: "Affirmations"),
            icon: "text.quote",
            iconColor: .rrSecondary,
            note: String(localized: "(Uses configured pack)")
        ),
        SelectableActivityOption(
            id: ActivityType.journal.rawValue,
            displayName: String(localized: "Journaling"),
            icon: "note.text",
            iconColor: .purple,
            note: nil
        ),
        SelectableActivityOption(
            id: ActivityType.mood.rawValue,
            displayName: String(localized: "Mood Rating"),
            icon: "face.smiling",
            iconColor: .yellow,
            note: nil
        ),
        SelectableActivityOption(
            id: ActivityType.gratitude.rawValue,
            displayName: String(localized: "Gratitude"),
            icon: "leaf.fill",
            iconColor: .rrSuccess,
            note: nil
        ),
        SelectableActivityOption(
            id: ActivityType.exercise.rawValue,
            displayName: String(localized: "Exercise"),
            icon: "figure.run",
            iconColor: .blue,
            note: nil
        ),
        SelectableActivityOption(
            id: "devotional",
            displayName: String(localized: "Devotional"),
            icon: "book.fill",
            iconColor: .brown,
            note: nil
        ),
    ]

    static func selectableActivityOption(for id: String) -> SelectableActivityOption? {
        allSelectableOptions.first { $0.id == id }
    }
}

// MARK: - Activity Picker Sheet

private struct ActivityPickerSheet: View {
    let currentIds: [String]
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    private var availableOptions: [UrgeSurfingConfigView.SelectableActivityOption] {
        UrgeSurfingConfigView.allSelectableOptions.filter { option in
            !currentIds.contains(option.id)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if availableOptions.isEmpty {
                    Text("All available activities have been added.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(availableOptions, id: \.id) { option in
                        Button {
                            onSelect(option.id)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: option.icon)
                                    .font(.body)
                                    .foregroundStyle(option.iconColor)
                                    .frame(width: 28, height: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(option.displayName)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    if let note = option.note {
                                        Text(note)
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.rrPrimary)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Companion Activity")
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
        UrgeSurfingConfigView()
    }
}
