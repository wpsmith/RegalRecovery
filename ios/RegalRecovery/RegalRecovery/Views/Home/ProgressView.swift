import SwiftUI
import SwiftData

struct RecoveryProgressView: View {
    @Query private var streaks: [RRStreak]
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var fasterEntries: [RRFASTEREntry]
    @Query(sort: \RRActivity.timestamp, order: .reverse) private var activities: [RRActivity]
    @Query private var stepWork: [RRStepWork]
    @Query(sort: \RRMeetingLog.date, order: .reverse) private var meetings: [RRMeetingLog]
    @Query(sort: \RRPhoneCallLog.date, order: .reverse) private var phoneCalls: [RRPhoneCallLog]
    @Query(sort: \RRUrgeLog.date, order: .reverse) private var urges: [RRUrgeLog]
    @Query(sort: \RRMoodEntry.date, order: .reverse) private var moodEntries: [RRMoodEntry]
    @Query(sort: \RRDevotionalProgress.day) private var devotionalProgress: [RRDevotionalProgress]
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var gratitudeEntries: [RRGratitudeEntry]

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
    private var fasterScaleMode: String {
        guard let latest = fasterEntries.first else { return "Green" }
        switch latest.stage {
        case -1, 0: return "Green"
        case 1, 2: return "Yellow"
        default: return "Red"
        }
    }

    private var moodAverage: Double {
        let scores = Array(moodEntries.prefix(7)).map { Double($0.score) }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
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
                    if isFlagEnabled("activity.gratitude") && !gratitudeEntries.isEmpty {
                        gratitudeSection
                    }
                    monthlyStatsSection
                    stepProgressSection

                    // MARK: - History
                    NavigationLink(destination: ActivityHistoryView()) {
                        RRCard {
                            HStack(spacing: 12) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title3)
                                    .foregroundStyle(Color.rrPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Activity History")
                                        .font(RRFont.headline)
                                        .foregroundStyle(Color.rrText)
                                    Text("View all past recovery activities")
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
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
    // MARK: - Gratitude Trends

    private var gratitudeStreak: Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let uniqueDays = Set(gratitudeEntries.map { formatter.string(from: cal.startOfDay(for: $0.date)) })
            .compactMap { formatter.date(from: $0) }
            .sorted(by: >)

        guard let mostRecent = uniqueDays.first else { return 0 }
        let daysSinceLast = cal.dateComponents([.day], from: mostRecent, to: today).day ?? 0
        guard daysSinceLast <= 1 else { return 0 }

        var streak = 1
        var expected = mostRecent
        for i in 1..<uniqueDays.count {
            let prev = cal.date(byAdding: .day, value: -1, to: expected)!
            if cal.isDate(uniqueDays[i], inSameDayAs: prev) {
                streak += 1
                expected = prev
            } else {
                break
            }
        }
        return streak
    }

    private var gratitudeTopCategories: [(name: String, count: Int, color: Color)] {
        var counts: [GratitudeCategory: Int] = [:]
        for entry in gratitudeEntries {
            for item in entry.items {
                if let category = item.category {
                    counts[category, default: 0] += 1
                }
            }
        }
        return counts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { (name: $0.key.rawValue, count: $0.value, color: $0.key.color) }
    }

    private var gratitudeTotalItems: Int {
        gratitudeEntries.reduce(0) { $0 + $1.items.count }
    }

    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Gratitude")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                summaryCard(
                    title: "Current Streak",
                    value: "\(gratitudeStreak) days",
                    detail: nil,
                    icon: "flame.fill",
                    iconColor: .orange
                )

                summaryCard(
                    title: "Total Items",
                    value: "\(gratitudeTotalItems)",
                    detail: "\(gratitudeEntries.count) entries",
                    icon: "leaf.fill",
                    iconColor: .rrSuccess
                )
            }

            if !gratitudeTopCategories.isEmpty {
                RRCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Top Categories")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        ForEach(Array(gratitudeTopCategories.enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(RRFont.callout)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                Text("\(item.count)")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
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
