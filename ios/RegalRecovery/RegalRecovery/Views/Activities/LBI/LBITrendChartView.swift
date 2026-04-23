// Views/Activities/LBI/LBITrendChartView.swift

import SwiftUI
import Charts
import SwiftData

struct LBITrendChartView: View {
    let entries: [RRLBIDailyEntry]
    var setupDate: Date? = nil

    private var filteredEntries: [RRLBIDailyEntry] {
        guard let setupDate else { return entries }
        return entries.filter { $0.date >= setupDate }
    }

    private var weeklyData: [(weekStart: Date, score: Int, riskLevel: LBIRiskLevel)] {
        LBIScoringService.weeklyScores(weeks: 12, entries: filteredEntries)
    }

    private var currentWeekData: (weekStart: Date, score: Int, riskLevel: LBIRiskLevel, delta: Int?, daysCompleted: Int, isPartial: Bool) {
        let currentWeekStart = LBIScoringService.weekStart(for: Date())
        let score = LBIScoringService.weeklyScore(for: currentWeekStart, entries: filteredEntries)
        let riskLevel = LBIRiskLevel.from(weeklyScore: score)
        let delta = LBIScoringService.weeklyDelta(currentWeekStart: currentWeekStart, entries: filteredEntries)
        let partialInfo = LBIScoringService.partialWeekInfo(weekStart: currentWeekStart, entries: filteredEntries)

        return (currentWeekStart, score, riskLevel, delta, partialInfo.daysCompleted, partialInfo.daysCompleted < 7)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Current week summary card
            LBIWeeklySummaryCard(
                weeklyScore: currentWeekData.score,
                riskLevel: currentWeekData.riskLevel,
                delta: currentWeekData.delta,
                daysCompleted: currentWeekData.daysCompleted,
                isPartialWeek: currentWeekData.isPartial
            )

            if weeklyData.count < 2 {
                placeholderView
            } else {
                chartView
            }
        }
        .padding(.bottom, 80)
    }

    // MARK: - Chart View

    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("12-Week Trend")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
                .padding(.horizontal)

            Chart {
                // Background risk level bands
                ForEach(riskLevelBands, id: \.level) { band in
                    RectangleMark(
                        xStart: .value("Start", weeklyData.first?.weekStart ?? Date()),
                        xEnd: .value("End", weeklyData.last?.weekStart ?? Date()),
                        yStart: .value("Low", band.range.lowerBound),
                        yEnd: .value("High", band.range.upperBound)
                    )
                    .foregroundStyle(band.color.opacity(0.1))
                }

                // Line connecting data points
                ForEach(weeklyData, id: \.weekStart) { dataPoint in
                    LineMark(
                        x: .value("Week", dataPoint.weekStart),
                        y: .value("Score", dataPoint.score)
                    )
                    .foregroundStyle(Color.rrTextSecondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }

                // Data point circles colored by risk level
                ForEach(weeklyData, id: \.weekStart) { dataPoint in
                    PointMark(
                        x: .value("Week", dataPoint.weekStart),
                        y: .value("Score", dataPoint.score)
                    )
                    .foregroundStyle(dataPoint.riskLevel.color)
                    .symbolSize(100)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatWeekLabel(date))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: [0, 10, 20, 30, 40, 49]) { value in
                    AxisValueLabel {
                        if let score = value.as(Int.self) {
                            Text("\(score)")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYScale(domain: 0...49)
            .frame(height: 280)
            .padding(.horizontal)

            // Legend
            legendView
        }
        .padding(.vertical, 12)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Placeholder View

    private var placeholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.3))

            Text("Not enough data yet")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            Text("Complete at least 2 weeks of daily check-ins to see your trend chart")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(.vertical, 24)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Legend View

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Levels")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(LBIRiskLevel.allCases, id: \.self) { level in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(level.color)
                            .frame(width: 10, height: 10)

                        Text(level.displayName)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrText)

                        Spacer(minLength: 0)

                        Text("\(level.scoreRange.lowerBound)-\(level.scoreRange.upperBound)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private struct RiskBand {
        let level: LBIRiskLevel
        let range: ClosedRange<Int>
        let color: Color
    }

    private var riskLevelBands: [RiskBand] {
        LBIRiskLevel.allCases.map { level in
            RiskBand(level: level, range: level.scoreRange, color: level.color)
        }
    }

    private func formatWeekLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview("With Data") {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)
    let userId = UUID()

    // Generate 12 weeks of sample data
    var entries: [RRLBIDailyEntry] = []
    let calendar = Calendar.current
    let today = Date()

    for weekOffset in 0..<12 {
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else { continue }

        // Generate 5-7 entries per week with varying scores
        let daysToGenerate = weekOffset == 0 ? 4 : Int.random(in: 5...7)

        for dayOffset in 0..<daysToGenerate {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

            // Vary scores to show different risk levels
            let baseScore = Int.random(in: 0...7)
            let entry = RRLBIDailyEntry(
                userId: userId,
                date: date,
                profileVersionId: UUID(),
                totalScore: baseScore
            )
            container.mainContext.insert(entry)
            entries.append(entry)
        }
    }

    return ScrollView {
        LBITrendChartView(entries: entries)
            .padding()
    }
    .modelContainer(container)
}

#Preview("Insufficient Data") {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)
    let userId = UUID()

    // Only 1 week of data
    let calendar = Calendar.current
    let today = Date()
    var entries: [RRLBIDailyEntry] = []

    for dayOffset in 0..<5 {
        guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
        let entry = RRLBIDailyEntry(
            userId: userId,
            date: date,
            profileVersionId: UUID(),
            totalScore: Int.random(in: 0...5)
        )
        container.mainContext.insert(entry)
        entries.append(entry)
    }

    return ScrollView {
        LBITrendChartView(entries: entries)
            .padding()
    }
    .modelContainer(container)
}

#Preview("High Risk Trend") {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)
    let userId = UUID()

    // Generate 12 weeks with increasing scores (worsening trend)
    var entries: [RRLBIDailyEntry] = []
    let calendar = Calendar.current
    let today = Date()

    for weekOffset in 0..<12 {
        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else { continue }

        let daysToGenerate = 7
        // Start low, get progressively worse
        let weeklyBaseScore = max(1, min(6, 1 + (11 - weekOffset) / 2))

        for dayOffset in 0..<daysToGenerate {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            let entry = RRLBIDailyEntry(
                userId: userId,
                date: date,
                profileVersionId: UUID(),
                totalScore: weeklyBaseScore + Int.random(in: -1...1)
            )
            container.mainContext.insert(entry)
            entries.append(entry)
        }
    }

    return ScrollView {
        LBITrendChartView(entries: entries)
            .padding()
    }
    .modelContainer(container)
}
