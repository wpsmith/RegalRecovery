import SwiftUI

/// Weekly Goals view showing goal completion for the current week (AC-WV-1 through AC-WV-4).
struct WeeklyGoalsView: View {
    @State private var viewModel = WeeklyDailyGoalsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // AC-WV-2: Weekly progress summary
                weeklyProgressHeader

                // AC-WV-3: Dynamic balance for the week
                weeklyDynamicBalance

                // AC-WV-1: Weekly goals grouped by dynamic
                weeklyGoalsList
            }
            .padding()
        }
        .navigationTitle("This Week's Goals")
        .task {
            await viewModel.loadWeeklyGoals()
        }
    }

    // MARK: - Weekly Progress Header

    private var weeklyProgressHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(viewModel.weeklyCompletedCount) of \(viewModel.weeklyTotalCount) goals completed this week")
                    .font(.headline)
                Spacer()
            }

            ProgressView(value: viewModel.weeklyCompletionPercentage)
                .tint(viewModel.weeklyCompletionPercentage >= 0.8 ? Color.rrSuccess : Color.rrPrimary)

            HStack {
                Text("\(Int(viewModel.weeklyCompletionPercentage * 100))% completion")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Dynamic Balance

    private var weeklyDynamicBalance: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dynamic Balance")
                .font(.subheadline.bold())

            ForEach(RecoveryDynamic.allCases) { dynamic in
                HStack {
                    Image(systemName: dynamic.icon)
                        .font(.caption)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(width: 24)
                    Text(dynamic.displayName)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)

                    GeometryReader { geometry in
                        let total = dynamicGoalCount(dynamic)
                        let completed = dynamicCompletedCount(dynamic)
                        let percentage = total > 0 ? CGFloat(completed) / CGFloat(total) : 0

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.rrSurface)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.rrPrimary)
                                .frame(width: geometry.size.width * percentage, height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text("\(dynamicCompletedCount(dynamic))/\(dynamicGoalCount(dynamic))")
                        .font(.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(width: 30)
                }
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Goals List

    private var weeklyGoalsList: some View {
        ForEach(viewModel.weeklyGoals) { goal in
            HStack(spacing: 12) {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(goal.isCompleted ? Color.rrSuccess : Color.rrTextSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.text)
                        .font(.subheadline)
                        .strikethrough(goal.isCompleted)
                    HStack(spacing: 4) {
                        ForEach(goal.dynamics) { dynamic in
                            Text(dynamic.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.rrPrimary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Helpers

    private func dynamicGoalCount(_ dynamic: RecoveryDynamic) -> Int {
        viewModel.weeklyGoals.filter { $0.dynamics.contains(dynamic) && $0.status != .dismissed }.count
    }

    private func dynamicCompletedCount(_ dynamic: RecoveryDynamic) -> Int {
        viewModel.weeklyGoals.filter { $0.dynamics.contains(dynamic) && $0.isCompleted }.count
    }
}

#Preview {
    NavigationStack {
        WeeklyGoalsView()
    }
}
