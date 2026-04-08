import SwiftUI

/// Daily Goals view showing goals grouped by dynamic with completion tracking.
/// AC-DV-1: Goals grouped by dynamic.
/// AC-DV-2: Progress summary.
/// AC-DV-3: Dynamic balance indicator.
/// AC-DV-7: Quick add goal FAB.
struct DailyGoalsView: View {
    @State private var viewModel = WeeklyDailyGoalsViewModel()
    @State private var showQuickAdd = false
    @State private var showReview = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // AC-DV-2: Progress summary
                progressHeader

                // AC-DV-3: Dynamic balance
                dynamicBalanceBar

                // AC-DV-1: Goals grouped by dynamic
                if viewModel.dailyGoals.isEmpty && !viewModel.isLoading {
                    emptyState
                } else {
                    goalSections
                }

                // AC-DN-1: Dynamic gap nudges
                nudgeSection
            }
            .padding()
        }
        .navigationTitle("Today's Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showReview = true
                } label: {
                    Image(systemName: "checkmark.circle")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // AC-DV-7: Quick add FAB
            Button {
                showQuickAdd = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.rrPrimary)
                    .clipShape(Circle())
                    .shadow(radius: 4, y: 2)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddGoalView(viewModel: viewModel)
        }
        .sheet(isPresented: $showReview) {
            DailyReviewView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadDailyGoals()
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(viewModel.dailyCompletedCount) of \(viewModel.dailyTotalCount) goals completed")
                    .font(.headline)
                Spacer()
                Text("\(Int(viewModel.dailyCompletionPercentage * 100))%")
                    .font(.headline)
                    .foregroundStyle(viewModel.dailyCompletionPercentage >= 0.8 ? Color.rrSuccess : Color.rrPrimary)
            }

            ProgressView(value: viewModel.dailyCompletionPercentage)
                .tint(viewModel.dailyCompletionPercentage >= 0.8 ? Color.rrSuccess : Color.rrPrimary)
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Dynamic Balance Bar

    private var dynamicBalanceBar: some View {
        HStack(spacing: 8) {
            ForEach(RecoveryDynamic.allCases) { dynamic in
                let count = viewModel.dailySummary?.dynamicBalance.count(for: dynamic)
                VStack(spacing: 4) {
                    Image(systemName: dynamic.icon)
                        .font(.caption)
                        .foregroundStyle(count?.completed == count?.total && (count?.total ?? 0) > 0 ? Color.rrSuccess : Color.rrTextSecondary)
                    Text("\(count?.completed ?? 0)/\(count?.total ?? 0)")
                        .font(.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Goal Sections

    private var goalSections: some View {
        ForEach(viewModel.goalsByDynamic, id: \.dynamic) { group in
            DisclosureGroup {
                ForEach(group.goals) { goal in
                    GoalRowView(goal: goal) {
                        Task { await viewModel.toggleGoal(goal) }
                    } onDismiss: {
                        Task { await viewModel.dismissGoal(goal) }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: group.dynamic.icon)
                        .foregroundStyle(Color.rrPrimary)
                    Text(group.dynamic.displayName)
                        .font(.subheadline.bold())
                    Spacer()
                    let completed = group.goals.filter(\.isCompleted).count
                    Text("\(completed)/\(group.goals.count)")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Empty State (AC-EC-1)

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrTextSecondary)
            Text("No goals set for today")
                .font(.headline)
                .foregroundStyle(Color.rrText)
            Text("Tap + to add your first goal")
                .font(.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Nudge Section

    private var nudgeSection: some View {
        ForEach(viewModel.nudges) { nudge in
            HStack {
                Image(systemName: nudge.dynamic.icon)
                    .foregroundStyle(Color.rrSecondary)
                Text(nudge.message)
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
                Button {
                    Task { await viewModel.dismissNudge(nudge) }
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
            .padding()
            .background(Color.rrSurface.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Goal Row

struct GoalRowView: View {
    let goal: GoalInstance
    let onToggle: () -> Void
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(goal.isCompleted ? Color.rrSuccess : Color.rrTextSecondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(goal.text)
                        .font(.subheadline)
                        .foregroundStyle(goal.isCompleted ? Color.rrTextSecondary : Color.rrText)
                        .strikethrough(goal.isCompleted)

                    if goal.isAutoPopulated {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.caption2)
                            .foregroundStyle(Color.rrSecondary)
                    }

                    if goal.carriedFrom != nil {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.caption2)
                            .foregroundStyle(Color.orange)
                    }
                }

                if let notes = goal.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Priority indicator
            priorityIndicator(goal.priority)

            // Dismiss button for auto-populated goals
            if goal.isAutoPopulated && goal.isPending {
                Button {
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func priorityIndicator(_ priority: GoalPriority) -> some View {
        Circle()
            .fill(priorityColor(priority))
            .frame(width: 8, height: 8)
    }

    private func priorityColor(_ priority: GoalPriority) -> Color {
        switch priority {
        case .high: return .rrDestructive
        case .medium: return .orange
        case .low: return .rrTextSecondary
        }
    }
}

#Preview {
    NavigationStack {
        DailyGoalsView()
    }
}
