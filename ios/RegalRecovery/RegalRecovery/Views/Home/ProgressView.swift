import SwiftUI
import SwiftData
import Charts

struct RecoveryProgressView: View {
    @Query private var streaks: [RRStreak]
    @Query(sort: \RRCheckIn.date, order: .reverse) private var checkIns: [RRCheckIn]
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var fasterEntries: [RRFASTEREntry]
    @Query(sort: \RREmotionalJournal.date, order: .reverse) private var emotionalEntries: [RREmotionalJournal]
    @Query(sort: \RRActivity.timestamp, order: .reverse) private var activities: [RRActivity]
    @Query private var stepWork: [RRStepWork]
    @Query(sort: \RRMeetingLog.date, order: .reverse) private var meetings: [RRMeetingLog]
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var phoneCalls: [RRPhoneCallLog]
    @Query(sort: \RRUrgeLog.date, order: .reverse) private var urges: [RRUrgeLog]
    @Query(sort: \RRDevotionalProgress.day) private var devotionalProgress: [RRDevotionalProgress]

    private var primaryStreak: RRStreak? { streaks.first }

    private var currentDays: Int { primaryStreak?.currentDays ?? 0 }

    private var sobrietyDate: Date {
        primaryStreak?.addiction?.sobrietyDate ?? Date()
    }

    private var nextMilestoneDays: Int {
        StreakViewModel.milestoneThresholds.first(where: { $0 > currentDays }) ?? ((currentDays / 365) + 1) * 365
    }

    private var sobrietyDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: sobrietyDate)
    }

    private var daysToNext: Int {
        nextMilestoneDays - currentDays
    }

    private var milestoneProgress: Double {
        guard nextMilestoneDays > 0 else { return 0 }
        return Double(currentDays) / Double(nextMilestoneDays)
    }

    // Weekly data helpers
    private var weeklyCheckInAverage: Int {
        let weekScores = Array(checkIns.prefix(7)).map(\.score)
        guard !weekScores.isEmpty else { return 0 }
        return weekScores.reduce(0, +) / weekScores.count
    }

    private var fasterScaleMode: String {
        guard let latest = fasterEntries.first else { return "Green" }
        switch latest.assessedStage {
        case 0: return "Green"
        case 1, 2: return "Yellow"
        default: return "Red"
        }
    }

    private var moodAverage: Double {
        let intensities = Array(emotionalEntries.prefix(7)).map { Double($0.intensity) }
        guard !intensities.isEmpty else { return 0 }
        return intensities.reduce(0, +) / Double(intensities.count)
    }

    private var weeklyActivityCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return activities.filter { $0.timestamp >= weekAgo }.count
    }

    private var completedSteps: Int {
        stepWork.filter { $0.status == "complete" }.count
    }

    private var currentStepNumber: Int {
        stepWork.first(where: { $0.status == "inProgress" })?.stepNumber ?? (completedSteps + 1)
    }

    private var monthlyMeetingCount: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return meetings.filter { $0.date >= monthAgo }.count
    }

    private var monthlyPhoneCallCount: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return phoneCalls.filter { $0.date >= monthAgo }.count
    }

    private var monthlyUrgeCount: Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return urges.filter { $0.date >= monthAgo }.count
    }

    // 7-Day Trend helpers
    private var trendScores: [Int] {
        Array(checkIns.prefix(7).reversed().map { $0.score })
    }

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private func isFlagEnabled(_ key: String) -> Bool {
        FeatureFlagStore.shared.isEnabled(key)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    sobrietySection
                    // MARK: - Devotional Progress
                    if isFlagEnabled("activity.devotionals") {
                        devotionalSection
                    }
                    weeklySummarySection
                    checkInTrendSection
                    monthlyStatsSection
                    stepProgressSection
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("Progress")
        }
    }

    // MARK: - Devotional

    private var devotionalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(destination: DevotionalView()) {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundStyle(Color.rrPrimary)
                            Text("30-Day Recovery Devotional")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            Text("Day \(currentDevotionalDay) of 30")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        // Progress grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 15), spacing: 4) {
                            ForEach(1...30, id: \.self) { day in
                                Circle()
                                    .fill(devotionalDayColor(day))
                                    .frame(width: 16, height: 16)
                            }
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var completedDevotionalDays: Set<Int> {
        Set(devotionalProgress.compactMap { $0.completedAt != nil ? $0.day : nil })
    }

    private var currentDevotionalDay: Int {
        let completed = completedDevotionalDays
        for day in 1...30 {
            if !completed.contains(day) { return day }
        }
        return 30
    }

    private func devotionalDayColor(_ day: Int) -> Color {
        if completedDevotionalDays.contains(day) { return .rrSuccess }
        if day == currentDevotionalDay { return .rrPrimary }
        return .rrTextSecondary.opacity(0.3)
    }

    // MARK: - Sobriety

    private var sobrietySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Sobriety")

            RRCard {
                VStack(spacing: 16) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(currentDays)")
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.rrPrimary)
                        Text("Days")
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Text("Sober since \(sobrietyDateFormatted)")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Next milestone: \(nextMilestoneDays) days")
                                .font(RRFont.callout)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            Text("\(daysToNext) to go")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        ProgressView(value: milestoneProgress)
                            .tint(Color.rrPrimary)
                    }
                }
            }
        }
    }

    // MARK: - Weekly Summary

    private var weeklySummaryCards: [(flag: String?, view: AnyView)] {
        var cards: [(flag: String?, view: AnyView)] = []
        if isFlagEnabled("activity.check-ins") {
            cards.append((flag: "activity.check-ins", view: AnyView(summaryCard(
                title: "Check-in Average",
                value: "\(weeklyCheckInAverage)/100",
                detail: nil,
                icon: "arrow.up.right",
                iconColor: .rrSuccess
            ))))
        }
        if isFlagEnabled("activity.faster-scale") {
            cards.append((flag: "activity.faster-scale", view: AnyView(summaryCard(
                title: "FASTER Scale",
                value: "Mostly \(fasterScaleMode)",
                detail: nil,
                icon: "circle.fill",
                iconColor: fasterScaleMode == "Green" ? .rrSuccess : (fasterScaleMode == "Yellow" ? .yellow : .rrDestructive)
            ))))
        }
        if isFlagEnabled("activity.mood") {
            cards.append((flag: "activity.mood", view: AnyView(summaryCard(
                title: "Mood Average",
                value: String(format: "%.1f/10", moodAverage),
                detail: nil,
                icon: "face.smiling",
                iconColor: .rrSecondary
            ))))
        }
        // Activities Logged is always shown (meta stat)
        cards.append((flag: nil, view: AnyView(summaryCard(
            title: "Activities Logged",
            value: "\(weeklyActivityCount)",
            detail: "this week",
            icon: "checkmark.circle.fill",
            iconColor: .rrPrimary
        ))))
        return cards
    }

    @ViewBuilder
    private var weeklySummarySection: some View {
        let cards = weeklySummaryCards
        if !cards.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: "Weekly Summary")

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(Array(cards.enumerated()), id: \.offset) { _, card in
                        card.view
                    }
                }
            }
        }
    }

    private func summaryCard(title: String, value: String, detail: String?, icon: String, iconColor: Color) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.caption)
                    Text(title)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Text(value)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                if let detail {
                    Text(detail)
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - 7-Day Check-in Trend

    @ViewBuilder
    private var checkInTrendSection: some View {
        if isFlagEnabled("activity.check-ins") && trendScores.count >= 2 {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: "7-Day Check-in Trend")

                RRCard {
                    Chart {
                        ForEach(Array(trendScores.enumerated()), id: \.offset) { index, score in
                            let label = index < dayLabels.count ? dayLabels[index] : "\(index)"
                            LineMark(
                                x: .value("Day", label),
                                y: .value("Score", score)
                            )
                            .foregroundStyle(Color.rrPrimary)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Day", label),
                                y: .value("Score", score)
                            )
                            .foregroundStyle(Color.rrPrimary)
                        }
                    }
                    .chartYScale(domain: 50...100)
                    .chartYAxis {
                        AxisMarks(position: .leading, values: [50, 75, 100])
                    }
                    .frame(height: 160)
                }
            }
        }
    }

    // MARK: - Monthly Stats

    private var monthlyStatRows: [(icon: String, iconColor: Color, title: String, value: String)] {
        var rows: [(icon: String, iconColor: Color, title: String, value: String)] = []
        if isFlagEnabled("activity.meetings") {
            rows.append((icon: "person.3.fill", iconColor: .rrPrimary, title: "Meetings attended", value: "\(monthlyMeetingCount) this month"))
        }
        if isFlagEnabled("activity.phone-calls") {
            rows.append((icon: "phone.fill", iconColor: .rrSecondary, title: "Phone calls", value: "\(monthlyPhoneCallCount) this month"))
        }
        if isFlagEnabled("activity.urge-logging") {
            rows.append((icon: "exclamationmark.triangle.fill", iconColor: .orange, title: "Urges logged", value: "\(monthlyUrgeCount) this month"))
        }
        return rows
    }

    @ViewBuilder
    private var monthlyStatsSection: some View {
        let rows = monthlyStatRows
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: "Monthly Stats")

                RRCard {
                    VStack(spacing: 0) {
                        ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                            monthlyRow(icon: row.icon, iconColor: row.iconColor, title: row.title, value: row.value, isLast: index == rows.count - 1)
                        }
                    }
                }
            }
        }
    }

    private func monthlyRow(icon: String, iconColor: Color, title: String, value: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 24)

                Text(title)
                    .font(RRFont.callout)
                    .foregroundStyle(Color.rrText)

                Spacer()

                Text(value)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .padding(.vertical, 10)

            if !isLast {
                Divider()
            }
        }
    }

    // MARK: - 12-Step Progress

    @ViewBuilder
    private var stepProgressSection: some View {
        if isFlagEnabled("activity.step-work") {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: "12-Step Progress")

                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Step \(currentStepNumber) of 12")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            RRBadge(
                                text: completedSteps >= 12 ? "Complete" : "In Progress",
                                color: completedSteps >= 12 ? .rrSuccess : .rrPrimary
                            )
                        }

                        ProgressView(value: Double(completedSteps), total: 12.0)
                            .tint(Color.rrPrimary)
                    }
                }
            }
        }
    }
}

#Preview {
    RecoveryProgressView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
