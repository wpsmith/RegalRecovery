import SwiftUI

/// Quick-add goal sheet (AC-DV-7).
/// Allows rapid goal creation from the daily view.
struct QuickAddGoalView: View {
    @Bindable var viewModel: WeeklyDailyGoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("What do you want to accomplish?", text: $viewModel.newGoalText, axis: .vertical)
                        .lineLimit(1...3)

                    Picker("Priority", selection: $viewModel.newGoalPriority) {
                        ForEach(GoalPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }
                }

                Section("Dynamics") {
                    ForEach(RecoveryDynamic.allCases) { dynamic in
                        Button {
                            if viewModel.newGoalDynamics.contains(dynamic) {
                                viewModel.newGoalDynamics.remove(dynamic)
                            } else {
                                viewModel.newGoalDynamics.insert(dynamic)
                            }
                        } label: {
                            HStack {
                                Image(systemName: dynamic.icon)
                                    .foregroundStyle(Color.rrPrimary)
                                Text(dynamic.displayName)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                if viewModel.newGoalDynamics.contains(dynamic) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.rrSuccess)
                                }
                            }
                        }
                    }
                }

                Section("Recurrence") {
                    Picker("Scope", selection: $viewModel.newGoalScope) {
                        Text("Daily").tag(GoalScope.daily)
                        Text("Weekly").tag(GoalScope.weekly)
                    }

                    Picker("Repeats", selection: $viewModel.newGoalRecurrence) {
                        Text("One-time").tag(GoalRecurrence.oneTime)
                        Text("Every day").tag(GoalRecurrence.daily)
                        Text("Specific days").tag(GoalRecurrence.specificDays)
                        Text("Weekly").tag(GoalRecurrence.weekly)
                    }

                    if viewModel.newGoalRecurrence == .specificDays {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(GoalDayOfWeek.allCases) { day in
                                    Button {
                                        if viewModel.newGoalSelectedDays.contains(day) {
                                            viewModel.newGoalSelectedDays.remove(day)
                                        } else {
                                            viewModel.newGoalSelectedDays.insert(day)
                                        }
                                    } label: {
                                        Text(day.shortName)
                                            .font(.caption.bold())
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(viewModel.newGoalSelectedDays.contains(day) ? Color.rrPrimary : Color.rrSurface)
                                            .foregroundStyle(viewModel.newGoalSelectedDays.contains(day) ? .white : Color.rrText)
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                Section("Notes (optional)") {
                    TextField("Additional context or intention", text: $viewModel.newGoalNotes, axis: .vertical)
                        .lineLimit(2...5)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(Color.rrDestructive)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            do {
                                try await viewModel.addGoal()
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(viewModel.newGoalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.newGoalDynamics.isEmpty)
                }
            }
        }
    }
}
