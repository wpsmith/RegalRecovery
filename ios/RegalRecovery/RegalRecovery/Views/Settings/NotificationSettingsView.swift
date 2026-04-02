import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = NotificationViewModel()
    @State private var permissionGranted = false

    var body: some View {
        List {
            // Master toggle
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.allNotificationsEnabled },
                    set: { newValue in
                        Task { await viewModel.toggleAll(enabled: newValue) }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Notifications")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                        Text("Reminders for your daily recovery plan")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            } header: {
                Text("Notifications")
            }

            if viewModel.allNotificationsEnabled {
                // Time block sections
                if viewModel.timeBlockGroups.isEmpty {
                    Section {
                        VStack(spacing: 8) {
                            Image(systemName: "bell.slash")
                                .font(.title2)
                                .foregroundStyle(Color.rrTextSecondary)
                            Text("No plan configured")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                            Text("Set up your Recovery Plan in Settings to receive activity reminders.")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                } else {
                    ForEach(viewModel.timeBlockGroups, id: \.hour) { group in
                        timeBlockSection(group)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .task {
            viewModel.load(modelContext: modelContext)
            permissionGranted = await viewModel.requestPermission()
            if permissionGranted {
                await viewModel.scheduleFromPlan()
            }
        }
    }

    @ViewBuilder
    private func timeBlockSection(_ group: (block: String, hour: Int, minute: Int, items: [RRDailyPlanItem])) -> some View {
        let timeKey = "\(group.hour):\(group.minute)"
        let isEnabled = !viewModel.disabledTimeBlocks.contains(timeKey)

        Section {
            // Toggle for this time block
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    Task { await viewModel.toggleTimeBlock(timeKey, enabled: newValue) }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.block)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Text(viewModel.formattedTime(hour: group.hour, minute: group.minute))
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }

            // Activity list
            ForEach(group.items, id: \.id) { item in
                HStack(spacing: 12) {
                    let activity = DailyEligibleActivity.all.first { $0.activityType == item.activityType }
                    Image(systemName: activity?.icon ?? "circle")
                        .font(.body)
                        .foregroundStyle(isEnabled ? Color.rrPrimary : Color.rrTextSecondary)
                        .frame(width: 24)

                    Text(viewModel.formattedActivityName(item))
                        .font(RRFont.body)
                        .foregroundStyle(isEnabled ? Color.rrText : Color.rrTextSecondary)
                }
                .padding(.leading, 8)
            }

            // Preview
            if isEnabled {
                let preview = viewModel.previewText(for: group.items)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .textCase(.uppercase)
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrPrimary)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preview.title)
                                .font(RRFont.caption.bold())
                                .foregroundStyle(Color.rrText)
                            Text(preview.body)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.rrBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - ViewModel Extension for Display

extension NotificationViewModel {
    func formattedActivityName(_ item: RRDailyPlanItem) -> String {
        DailyEligibleActivity.all.first { $0.activityType == item.activityType }?.displayName ?? item.activityType
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
    }
}
