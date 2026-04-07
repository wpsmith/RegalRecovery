import SwiftUI
import SwiftData

struct GratitudeTrendsView: View {
    @Query(sort: \RRGratitudeEntry.date, order: .reverse)
    private var entries: [RRGratitudeEntry]

    @Query(sort: \RRCheckIn.date, order: .reverse)
    private var checkIns: [RRCheckIn]

    @Query(sort: \RRUrgeLog.date, order: .reverse)
    private var urgeLogs: [RRUrgeLog]

    @State private var viewModel = GratitudeTrendsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                streakCard
                categoryBreakdownCard
                volumeTrendsCard
                correlationInsightsCard
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle("Gratitude Trends")
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        let data = viewModel.streakData(from: entries)

        return RRCard {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                    Text("\(data.currentStreak)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.rrPrimary)
                    Text(data.currentStreak == 1 ? "day" : "days")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Text("Current Streak")
                    .font(RRFont.subheadline)
                    .foregroundStyle(Color.rrTextSecondary)

                Divider()

                HStack(spacing: 24) {
                    streakStat(label: "Best", value: "\(data.longestStreak)", icon: "trophy.fill")
                    streakStat(label: "Total Days", value: "\(data.totalDaysWithEntries)", icon: "calendar")
                }
            }
        }
    }

    private func streakStat(label: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(Color.rrPrimary)
                Text(value)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.rrText)
            }
            Text(label)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownCard: some View {
        let breakdown = viewModel.categoryBreakdown(from: entries, period: viewModel.selectedPeriod)

        return VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Category Breakdown")

            RRCard {
                VStack(spacing: 16) {
                    periodPicker

                    if breakdown.isEmpty {
                        Text("No categorized items yet")
                            .font(RRFont.callout)
                            .foregroundStyle(Color.rrTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(breakdown) { item in
                                categoryBar(item: item, maxPercentage: breakdown.first?.percentage ?? 100)
                            }
                        }

                        if let top = breakdown.first {
                            Text("Your top source: \(top.category.rawValue)")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(TrendPeriod.allCases) { period in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(
                            viewModel.selectedPeriod == period ? .white : Color.rrTextSecondary
                        )
                        .background(
                            viewModel.selectedPeriod == period
                                ? Color.rrPrimary
                                : Color.rrSurface
                        )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.rrTextSecondary.opacity(0.2), lineWidth: 1)
        )
    }

    private func categoryBar(item: CategoryBreakdownItem, maxPercentage: Double) -> some View {
        HStack(spacing: 12) {
            RRColorDot(item.category.color)

            Text(item.category.rawValue)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrText)
                .frame(width: 100, alignment: .leading)

            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(item.category.color)
                    .frame(
                        width: max(4, proxy.size.width * (item.percentage / max(maxPercentage, 1))),
                        height: 12
                    )
                    .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 16)

            Text("\(Int(item.percentage.rounded()))%")
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrTextSecondary)
                .frame(width: 36, alignment: .trailing)
        }
    }

    // MARK: - Volume Trends

    private var volumeTrendsCard: some View {
        let avgItems = viewModel.averageItemsPerEntry(from: entries)
        let weeklyData = viewModel.weeklyEntryData(from: entries)
        let maxDays = weeklyData.map(\.daysWithEntries).max() ?? 7

        return VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Volume Trends")

            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(Color.rrPrimary)
                            .font(.caption)
                        Text("Avg items per entry:")
                            .font(RRFont.callout)
                            .foregroundStyle(Color.rrText)
                        Text(String(format: "%.1f", avgItems))
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.rrPrimary)
                    }

                    Divider()

                    Text("Days with entries per week")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(weeklyData) { week in
                            VStack(spacing: 4) {
                                Text("\(week.daysWithEntries)")
                                    .font(RRFont.caption2)
                                    .foregroundStyle(Color.rrTextSecondary)

                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.rrPrimary.opacity(week.daysWithEntries > 0 ? 1.0 : 0.15))
                                    .frame(
                                        height: max(4, CGFloat(week.daysWithEntries) / CGFloat(max(maxDays, 1)) * 80)
                                    )

                                Text(week.weekLabel)
                                    .font(.system(size: 9))
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 110)
                }
            }
        }
    }

    // MARK: - Correlation Insights

    @ViewBuilder
    private var correlationInsightsCard: some View {
        let checkInInsight = viewModel.checkInCorrelation(entries: entries, checkIns: checkIns)
        let urgeInsight = viewModel.urgeCorrelation(entries: entries, urgeLogs: urgeLogs)

        if checkInInsight != nil || urgeInsight != nil {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: "Insights")

                VStack(spacing: 12) {
                    if let insight = checkInInsight {
                        insightCard(text: insight)
                    }
                    if let insight = urgeInsight {
                        insightCard(text: insight)
                    }
                }
            }
        }
    }

    private func insightCard(text: String) -> some View {
        RRCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)

                Text(text)
                    .font(RRFont.callout)
                    .foregroundStyle(Color.rrText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        GratitudeTrendsView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
