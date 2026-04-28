import SwiftUI
import Charts

struct QuadrantWeeklyReviewTrendChartView: View {
    let trendData: [QuadrantWeeklyReviewTrendPoint]

    private var dateLabel: (Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return { formatter.string(from: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "8-Week Trend"))
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            if trendData.count < 2 {
                placeholderView
            } else {
                chartContent
            }
        }
    }

    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.3))

            Text(String(localized: "Keep assessing — your trends will appear after 2 weeks"))
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(trendData) { point in
                    LineMark(
                        x: .value(String(localized: "Week"), point.weekStartDate),
                        y: .value(String(localized: "Body"), point.bodyScore)
                    )
                    .foregroundStyle(Color(.systemGreen))
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value(String(localized: "Series"), String(localized: "Body")))
                }

                ForEach(trendData) { point in
                    LineMark(
                        x: .value(String(localized: "Week"), point.weekStartDate),
                        y: .value(String(localized: "Mind"), point.mindScore)
                    )
                    .foregroundStyle(Color(.systemBlue))
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value(String(localized: "Series"), String(localized: "Mind")))
                }

                ForEach(trendData) { point in
                    LineMark(
                        x: .value(String(localized: "Week"), point.weekStartDate),
                        y: .value(String(localized: "Heart"), point.heartScore)
                    )
                    .foregroundStyle(Color(.systemOrange))
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value(String(localized: "Series"), String(localized: "Heart")))
                }

                ForEach(trendData) { point in
                    LineMark(
                        x: .value(String(localized: "Week"), point.weekStartDate),
                        y: .value(String(localized: "Spirit"), point.spiritScore)
                    )
                    .foregroundStyle(Color(.systemPurple))
                    .symbol(.circle)
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(by: .value(String(localized: "Series"), String(localized: "Spirit")))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(dateLabel(date))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        AxisGridLine()
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYScale(domain: 0...10)
            .chartForegroundStyleScale([
                String(localized: "Body"): Color(.systemGreen),
                String(localized: "Mind"): Color(.systemBlue),
                String(localized: "Heart"): Color(.systemOrange),
                String(localized: "Spirit"): Color(.systemPurple),
            ])
            .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
            .frame(height: 220)

            legendView
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            ForEach(QuadrantWeeklyReviewType.allCases) { quadrant in
                HStack(spacing: 4) {
                    Circle()
                        .fill(quadrant.color)
                        .frame(width: 8, height: 8)
                    Text(quadrant.displayName)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrText)
                }
            }
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let today = Date()
    var points: [QuadrantWeeklyReviewTrendPoint] = []
    for i in 0..<8 {
        let date = calendar.date(byAdding: .weekOfYear, value: -(7 - i), to: today)!
        points.append(QuadrantWeeklyReviewTrendPoint(
            id: UUID(),
            weekStartDate: date,
            bodyScore: Int.random(in: 4...9),
            mindScore: Int.random(in: 3...8),
            heartScore: Int.random(in: 5...10),
            spiritScore: Int.random(in: 4...9),
            balanceScore: 65,
            wellnessLevel: .growing
        ))
    }
    return ScrollView {
        QuadrantWeeklyReviewTrendChartView(trendData: points)
            .padding()
    }
    .background(Color.rrBackground)
}
