import SwiftUI

/// Goal trends view showing completion rates, consistency score, and streaks (AC-TI-1 through AC-TI-4).
struct GoalTrendsView: View {
    @State private var viewModel = WeeklyDailyGoalsViewModel()
    @State private var selectedPeriod = "30d"

    private let periods = ["7d", "30d", "90d"]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period picker
                Picker("Period", selection: $selectedPeriod) {
                    Text("7 Days").tag("7d")
                    Text("30 Days").tag("30d")
                    Text("90 Days").tag("90d")
                }
                .pickerStyle(.segmented)

                if let trends = viewModel.trendsData {
                    // AC-TI-3: Consistency score
                    consistencyCard(score: trends.consistencyScore)

                    // AC-TI-4: Streaks
                    streakCards(streaks: trends.streaks)

                    // AC-TI-1: Completion rate over time (placeholder chart)
                    completionRateCard(rates: trends.dailyCompletionRates)

                    // AC-TI-2: Per-dynamic trends
                    if let dynamicTrends = trends.dynamicTrends {
                        dynamicTrendsSection(trends: dynamicTrends)
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    emptyTrendsView
                }
            }
            .padding()
        }
        .navigationTitle("Goal Trends")
        .onChange(of: selectedPeriod) {
            Task { await viewModel.loadTrends(period: selectedPeriod) }
        }
        .task {
            await viewModel.loadTrends(period: selectedPeriod)
        }
    }

    // MARK: - Consistency Card

    private func consistencyCard(score: Double) -> some View {
        VStack(spacing: 8) {
            Text("Consistency Score")
                .font(.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
            Text("\(Int(score))%")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(score >= 70 ? Color.rrSuccess : score >= 50 ? Color.orange : Color.rrDestructive)
            Text("Days with 3+ dynamics completed")
                .font(.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Streak Cards

    private func streakCards(streaks: GoalStreaks) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.title2)
                    .foregroundStyle(Color.orange)
                Text("\(streaks.allGoalsCompleted)")
                    .font(.title.bold())
                Text("All Goals\nStreak")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 4) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(Color.rrPrimary)
                Text("\(streaks.weeklyEightyPercent)")
                    .font(.title.bold())
                Text("Weekly 80%+\nStreak")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Completion Rate Card

    private func completionRateCard(rates: [DailyCompletionRate]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Completion Rate")
                .font(.subheadline.bold())

            if rates.isEmpty {
                Text("No data available yet")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                // Simple bar chart representation.
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(rates.suffix(30)) { rate in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(rate.completionRate >= 80 ? Color.rrSuccess : rate.completionRate >= 50 ? Color.orange : Color.rrDestructive)
                            .frame(height: max(4, CGFloat(rate.completionRate) * 0.8))
                    }
                }
                .frame(height: 80)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Dynamic Trends

    private func dynamicTrendsSection(trends: [String: [DailyCompletionRate]]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Per-Dynamic Trends")
                .font(.subheadline.bold())

            ForEach(RecoveryDynamic.allCases) { dynamic in
                if let rates = trends[dynamic.rawValue], !rates.isEmpty {
                    HStack {
                        Image(systemName: dynamic.icon)
                            .font(.caption)
                            .foregroundStyle(Color.rrPrimary)
                        Text(dynamic.displayName)
                            .font(.caption)
                        Spacer()
                        let avg = rates.map(\.completionRate).reduce(0, +) / Double(rates.count)
                        Text("\(Int(avg))% avg")
                            .font(.caption.bold())
                            .foregroundStyle(avg >= 70 ? Color.rrSuccess : Color.rrTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty

    private var emptyTrendsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrTextSecondary)
            Text("No trend data yet")
                .font(.headline)
            Text("Complete goals for a few days to see your trends here.")
                .font(.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

#Preview {
    NavigationStack {
        GoalTrendsView()
    }
}
