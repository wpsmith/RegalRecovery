// Views/Activities/LBI/LBICorrelationView.swift

import SwiftUI
import Charts
import SwiftData

struct LBICorrelationView: View {
    let pciEntries: [RRLBIDailyEntry]
    let fasterEntries: [RRFASTEREntry]

    private var weeklyScores: [(weekStart: Date, score: Int, riskLevel: LBIRiskLevel)] {
        LBIScoringService.weeklyScores(weeks: 12, entries: pciEntries)
    }

    private var dateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let now = Date()
        let start = calendar.date(byAdding: .weekOfYear, value: -12, to: now) ?? now
        return start...now
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title and explanation
                headerSection

                if weeklyScores.isEmpty && fasterEntries.isEmpty {
                    emptyStateView
                } else if weeklyScores.isEmpty {
                    pciEmptyView
                } else if fasterEntries.isEmpty {
                    VStack(spacing: 16) {
                        lbiTrendChart
                        fasterEmptyView
                    }
                } else {
                    VStack(spacing: 16) {
                        lbiTrendChart
                        fasterTimelineChart
                    }
                }
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(Color.rrBackground)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Life Balance & FASTER Correlation")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color.rrText)

            Text("Rising life balance scores often precede FASTER Scale escalation. Look for patterns where your weekly score climbs before you notice emotional or behavioral warning signs.")
                .font(.system(size: 15))
                .foregroundStyle(Color.rrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - LBI Trend Chart

    private var lbiTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Life Balance Index (12 Weeks)")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.rrText)

            Chart {
                ForEach(weeklyScores, id: \.weekStart) { item in
                    LineMark(
                        x: .value("Week", item.weekStart),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(item.riskLevel.color.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    PointMark(
                        x: .value("Week", item.weekStart),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(item.riskLevel.color)
                    .symbolSize(80)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                    AxisGridLine()
                }
            }
            .chartYScale(domain: 0...50)
            .frame(height: 200)
            .padding()
            .background(Color.rrSurface)
            .cornerRadius(12)

            // Risk level legend
            riskLevelLegend
        }
    }

    private var riskLevelLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Risk Levels")
                .font(.caption)
                .foregroundStyle(Color.rrTextSecondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(LBIRiskLevel.allCases, id: \.self) { level in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(level.color)
                            .frame(width: 10, height: 10)

                        Text(level.displayName)
                            .font(.caption)
                            .foregroundStyle(Color.rrText)

                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(Color.rrSurface)
        .cornerRadius(12)
    }

    // MARK: - FASTER Timeline Chart

    private var fasterTimelineChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FASTER Scale Check-ins")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.rrText)

            Chart {
                ForEach(filteredFasterEntries, id: \.id) { entry in
                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Stage", entry.stage)
                    )
                    .foregroundStyle(fasterStageColor(for: entry.stage))
                    .symbolSize(120)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: Array(-1...5)) { value in
                    if let stage = value.as(Int.self) {
                        AxisValueLabel {
                            Text(fasterStageName(for: stage))
                                .font(.caption)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYScale(domain: -1...5)
            .frame(height: 200)
            .padding()
            .background(Color.rrSurface)
            .cornerRadius(12)

            // FASTER stage legend
            fasterStageLegend
        }
    }

    private var filteredFasterEntries: [RRFASTEREntry] {
        fasterEntries.filter { entry in
            dateRange.contains(entry.date)
        }
    }

    private var fasterStageLegend: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FASTER Stages")
                .font(.caption)
                .foregroundStyle(Color.rrTextSecondary)

            VStack(spacing: 6) {
                ForEach(FASTERStage.allCases, id: \.id) { stage in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(stage.color)
                            .frame(width: 10, height: 10)

                        Text(stage.letter)
                            .font(.caption.bold())
                            .foregroundStyle(Color.rrText)
                            .frame(width: 30, alignment: .leading)

                        Text(stage.name)
                            .font(.caption)
                            .foregroundStyle(Color.rrText)

                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(Color.rrSurface)
        .cornerRadius(12)
    }

    // MARK: - Empty States

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 60))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.5))

            Text("No Data Yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.rrText)

            Text("Start tracking your Life Balance Index and FASTER Scale check-ins to see how they relate over time.")
                .font(.system(size: 15))
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }

    private var pciEmptyView: some View {
        VStack(spacing: 16) {
            lbiTrendChart

            VStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.rrTextSecondary.opacity(0.5))

                Text("Begin tracking your Life Balance Index to see the correlation with FASTER stages.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(32)
            .background(Color.rrSurface)
            .cornerRadius(12)
        }
    }

    private var fasterEmptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gauge.with.needle")
                .font(.system(size: 40))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.5))

            Text("Add FASTER Scale check-ins to see how life balance relates to relapse risk.")
                .font(.system(size: 15))
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(32)
        .background(Color.rrSurface)
        .cornerRadius(12)
    }

    // MARK: - Helper Methods

    private func fasterStageColor(for stage: Int) -> Color {
        guard let fasterStage = FASTERStage(rawValue: stage) else {
            return Color.gray
        }
        return fasterStage.color
    }

    private func fasterStageName(for stage: Int) -> String {
        guard let fasterStage = FASTERStage(rawValue: stage) else {
            return ""
        }
        return fasterStage.letter
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let now = Date()

    // Generate sample LBI entries
    let pciEntries = (0..<84).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
        return RRLBIDailyEntry(
            userId: UUID(),
            date: date,
            profileVersionId: UUID(),
            totalScore: Int.random(in: 0...5)
        )
    }

    // Generate sample FASTER entries
    let fasterEntries = (0..<20).map { _ in
        let date = calendar.date(byAdding: .day, value: -Int.random(in: 0...84), to: now)!
        return RRFASTEREntry(
            userId: UUID(),
            date: date,
            stage: Int.random(in: -1...5)
        )
    }

    return LBICorrelationView(pciEntries: pciEntries, fasterEntries: fasterEntries)
}
