import SwiftUI

// MARK: - Day Summary

/// Summary data for a single day in the heatmap.
struct HeatmapDaySummary: Identifiable {
    let date: Date
    let completionPercent: Double
    let status: String

    var id: Date { date }

    /// The heatmap color based on completion percentage.
    var color: Color {
        switch completionPercent {
        case 0: return .gray.opacity(0.3)
        case 0.001..<0.50: return .orange.opacity(0.4)
        case 0.50..<0.80: return .orange
        case 0.80..<1.0: return Color.green.opacity(0.6)
        default: return .green
        }
    }
}

// MARK: - View Mode

private enum HeatmapViewMode: String, CaseIterable {
    case weekly = "Week"
    case monthly = "Month"
}

// MARK: - TimeJournalHeatmapView

struct TimeJournalHeatmapView: View {
    let daySummaries: [HeatmapDaySummary]
    var onDayTapped: ((Date) -> Void)?

    @State private var viewMode: HeatmapViewMode = .weekly

    private let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 12) {
            // Mode toggle
            Picker("View", selection: $viewMode) {
                ForEach(HeatmapViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            // Legend
            legendRow

            // Grid
            switch viewMode {
            case .weekly:
                weeklyGrid
            case .monthly:
                monthlyGrid
            }
        }
        .padding(.vertical, 12)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Weekly Grid

    private var weeklyGrid: some View {
        let weekDays = currentWeekDays()
        return VStack(spacing: 8) {
            // Day of week headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.rrTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            // Day cells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(weekDays, id: \.self) { date in
                    let summary = summaryFor(date: date)
                    dayCellView(date: date, summary: summary)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Monthly Grid

    private var monthlyGrid: some View {
        let monthData = currentMonthDays()
        return VStack(spacing: 8) {
            // Month/year header
            Text(monthYearLabel())
                .font(RRFont.headline)
                .foregroundStyle(.rrText)

            // Day of week headers
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.rrTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            // Day cells with leading empty cells for alignment
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Leading empty cells
                ForEach(0..<monthData.leadingEmptyCells, id: \.self) { _ in
                    Color.clear
                        .frame(height: 32)
                }

                // Actual day cells
                ForEach(monthData.days, id: \.self) { date in
                    let summary = summaryFor(date: date)
                    dayCellView(date: date, summary: summary)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Day Cell

    private func dayCellView(date: Date, summary: HeatmapDaySummary?) -> some View {
        let dayNumber = calendar.component(.day, from: date)
        let isFuture = date > calendar.startOfDay(for: Date())
        let cellColor = summary?.color ?? .gray.opacity(0.15)

        return Button {
            onDayTapped?(date)
        } label: {
            Text("\(dayNumber)")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(isFuture ? .rrTextSecondary.opacity(0.4) : .rrText)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isFuture ? Color.gray.opacity(0.08) : cellColor)
                )
        }
        .disabled(isFuture)
        .accessibilityLabel(accessibilityLabel(for: date, summary: summary))
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 12) {
            legendItem(color: .gray.opacity(0.3), label: "0%")
            legendItem(color: .orange.opacity(0.4), label: "1-49%")
            legendItem(color: .orange, label: "50-79%")
            legendItem(color: Color.green.opacity(0.6), label: "80-99%")
            legendItem(color: .green, label: "100%")
        }
        .padding(.horizontal, 16)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.rrTextSecondary)
        }
    }

    // MARK: - Helpers

    private func summaryFor(date: Date) -> HeatmapDaySummary? {
        let targetDay = calendar.startOfDay(for: date)
        return daySummaries.first { calendar.isDate($0.date, inSameDayAs: targetDay) }
    }

    private func currentWeekDays() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        // Find Monday of this week (ISO 8601 weekday: Monday = 2)
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7  // Monday-based offset
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else {
            return []
        }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    private struct MonthData {
        let leadingEmptyCells: Int
        let days: [Date]
    }

    private func currentMonthDays() -> MonthData {
        let today = Date()
        guard let range = calendar.range(of: .day, in: .month, for: today),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))
        else {
            return MonthData(leadingEmptyCells: 0, days: [])
        }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmpty = (firstWeekday + 5) % 7  // Monday-based

        let days = range.compactMap { day -> Date? in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }

        return MonthData(leadingEmptyCells: leadingEmpty, days: days)
    }

    private func monthYearLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    private func accessibilityLabel(for date: Date, summary: HeatmapDaySummary?) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let dateStr = formatter.string(from: date)
        if let summary {
            return "\(dateStr), \(Int(summary.completionPercent * 100))% complete"
        }
        return "\(dateStr), no data"
    }
}

// MARK: - Preview

#Preview {
    let calendar = Calendar.current
    let today = Date()
    let summaries: [HeatmapDaySummary] = (-14..<1).compactMap { offset -> HeatmapDaySummary? in
        guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { return nil }
        let percent = Double.random(in: 0...1)
        return HeatmapDaySummary(date: date, completionPercent: percent, status: "completed")
    }

    ScrollView {
        TimeJournalHeatmapView(daySummaries: summaries) { date in
            print("Tapped: \(date)")
        }
        .padding()
    }
    .background(Color.rrBackground)
}
