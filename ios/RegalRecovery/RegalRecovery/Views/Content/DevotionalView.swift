import SwiftData
import SwiftUI

struct DevotionalView: View {
    @Query(sort: \RRDevotionalProgress.day) private var devotionalProgress: [RRDevotionalProgress]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDay: DevotionalDay?

    private var completedDays: Set<Int> {
        Set(devotionalProgress.compactMap { $0.completedAt != nil ? $0.day : nil })
    }

    private var currentDay: Int {
        let completed = completedDays
        for day in 1...30 {
            if !completed.contains(day) { return day }
        }
        return 30
    }

    /// Merge static content with user progress
    private var days: [DevotionalDay] {
        let progressMap = Dictionary(uniqueKeysWithValues: devotionalProgress.map { ($0.day, $0) })
        return ContentData.devotionalDays.map { day in
            DevotionalDay(
                day: day.day,
                title: day.title,
                scripture: day.scripture,
                scriptureText: day.scriptureText,
                reflection: day.reflection,
                isComplete: progressMap[day.day]?.completedAt != nil,
                completedAt: progressMap[day.day]?.completedAt
            )
        }
    }

    private var todayDays: [DevotionalDay] {
        days.filter { $0.day == currentDay }
    }

    private var upcomingDays: [DevotionalDay] {
        days.filter { $0.day != currentDay && !$0.isComplete }
            .sorted { $0.day < $1.day }
    }

    private var completedDaysList: [DevotionalDay] {
        days.filter { $0.day != currentDay && $0.isComplete }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    private static let completedDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f
    }()

    var body: some View {
        List {
            // MARK: - Today
            Section {
                ForEach(todayDays) { day in
                    Button {
                        selectedDay = day
                    } label: {
                        dayRow(day)
                    }
                    .listRowBackground(Color.rrPrimary.opacity(0.08))
                }
            } header: {
                Text("Today")
            }

            // MARK: - Upcoming
            if !upcomingDays.isEmpty {
                Section {
                    ForEach(upcomingDays) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            dayRow(day)
                        }
                        .listRowBackground(Color.rrSurface)
                    }
                } header: {
                    Text("Upcoming")
                }
            }

            // MARK: - Completed
            if !completedDaysList.isEmpty {
                Section {
                    ForEach(completedDaysList) { day in
                        Button {
                            selectedDay = day
                        } label: {
                            dayRow(day)
                        }
                        .listRowBackground(Color.rrSurface)
                    }
                } header: {
                    Text("Completed")
                }
            }
        }
        .listStyle(.plain)
        .background(Color.rrBackground)
        .navigationTitle("Devotional")
        .sheet(item: $selectedDay) { day in
            DevotionalDetailSheet(day: day) { completedDay in
                markComplete(day: completedDay)
            }
        }
    }

    private func dayRow(_ day: DevotionalDay) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(dayCircleColor(day))
                    .frame(width: 36, height: 36)
                Text("\(day.day)")
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundStyle(day.isComplete || day.day == currentDay ? .white : Color.rrTextSecondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(day.title)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Text(day.scripture)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Spacer()

            if day.isComplete {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.rrSuccess)
                    if let completedAt = day.completedAt {
                        Text("Completed \(Self.completedDateFormatter.string(from: completedAt))")
                            .font(RRFont.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            } else if day.day == currentDay {
                RRBadge(text: "Today", color: .rrPrimary)
            }
        }
        .padding(.vertical, 4)
    }

    private func dayCircleColor(_ day: DevotionalDay) -> Color {
        if day.isComplete { return .rrSuccess }
        if day.day == currentDay { return .rrPrimary }
        return .rrTextSecondary.opacity(0.2)
    }

    private func markComplete(day: Int) {
        // Check if progress already exists for this day
        if let existing = devotionalProgress.first(where: { $0.day == day }) {
            existing.completedAt = Date()
            existing.modifiedAt = Date()
        } else {
            let progress = RRDevotionalProgress(
                userId: UUID(), // Will be replaced with actual user ID
                day: day,
                completedAt: Date()
            )
            modelContext.insert(progress)
        }
    }
}

// MARK: - Detail Sheet

private struct DevotionalDetailSheet: View {
    let day: DevotionalDay
    let onMarkComplete: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(day.day)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrPrimary)
                            .fontWeight(.semibold)
                        Text(day.title)
                            .font(RRFont.largeTitle)
                            .foregroundStyle(Color.rrText)
                    }

                    // Scripture reference
                    Text(day.scripture)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrPrimary)

                    // Scripture text
                    Text("\"\(day.scriptureText)\"")
                        .font(.title3)
                        .italic()
                        .foregroundStyle(Color.rrText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.rrPrimary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Reflection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reflection")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text(day.reflection)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineSpacing(4)
                    }

                    // Mark complete
                    if !day.isComplete {
                        RRButton("Mark Complete", icon: "checkmark.circle") {
                            onMarkComplete(day.day)
                            dismiss()
                        }
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.rrSuccess)
                            Text("Completed")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrSuccess)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DevotionalView()
    }
}
