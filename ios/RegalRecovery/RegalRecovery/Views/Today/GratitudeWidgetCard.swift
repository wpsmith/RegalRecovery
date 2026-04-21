import SwiftUI
import SwiftData

/// Compact card for the Today screen showing gratitude status, streak, and a random past item.
struct GratitudeWidgetCard: View {
    @Query(sort: \RRGratitudeEntry.date, order: .reverse)
    private var entries: [RRGratitudeEntry]

    private let calendar = Calendar.current

    // MARK: - Computed Properties

    private var hasTodayEntry: Bool {
        entries.contains { calendar.isDateInToday($0.date) }
    }

    private var currentStreak: Int {
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        guard !uniqueDays.isEmpty else { return 0 }

        let sortedDays = uniqueDays.sorted(by: >)
        let today = calendar.startOfDay(for: Date())

        guard let mostRecent = sortedDays.first else { return 0 }
        let daysSinceLast = calendar.dateComponents([.day], from: mostRecent, to: today).day ?? 0
        guard daysSinceLast <= 1 else { return 0 }

        var streak = 1
        var expectedDate = mostRecent

        for i in 1..<sortedDays.count {
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: expectedDate) else { break }
            if calendar.isDate(sortedDays[i], inSameDayAs: previousDay) {
                streak += 1
                expectedDate = previousDay
            } else {
                break
            }
        }

        return streak
    }

    /// Deterministic daily rotation: pick a random past item based on day hash.
    private var randomPastItem: (text: String, daysAgo: Int)? {
        let pastEntries = entries.filter { !calendar.isDateInToday($0.date) }
        let allItems = pastEntries.flatMap { entry in
            entry.items.map { item in
                let daysAgo = calendar.dateComponents([.day], from: entry.date, to: Date()).day ?? 0
                return (text: item.text, daysAgo: daysAgo)
            }
        }
        guard !allItems.isEmpty else { return nil }

        // Deterministic daily seed from day components
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let daySeed = (components.year ?? 0) * 10000 + (components.month ?? 0) * 100 + (components.day ?? 0)
        let index = abs(daySeed) % allItems.count
        return allItems[index]
    }

    // MARK: - Body

    var body: some View {
        NavigationLink {
            GratitudeTabView()
        } label: {
            HStack(spacing: 12) {
                // Left icon
                ZStack {
                    Circle()
                        .fill(Color.rrSuccess.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.rrSuccess)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Title row with status and add button
                    HStack {
                        Text("Gratitude")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        // Status badge
                        if hasTodayEntry {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text("Done")
                                    .font(RRFont.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Color.rrSuccess)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.rrSuccess.opacity(0.12))
                            .clipShape(Capsule())
                        } else {
                            Text("Not yet")
                                .font(RRFont.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rrTextSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.rrTextSecondary.opacity(0.12))
                                .clipShape(Capsule())
                        }

                        // Add button
                        NavigationLink {
                            GratitudeListView()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.rrPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    // Streak
                    if currentStreak > 0 {
                        Text(String(localized: "Streak: \(currentStreak) day\(currentStreak == 1 ? "" : "s")"))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    // Random past item as encouragement
                    if let pastItem = randomPastItem {
                        HStack(alignment: .top, spacing: 0) {
                            Text("\"\(pastItem.text)\"")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrText)
                                .lineLimit(1)
                                .italic()

                            Text(String(localized: " -- \(pastItem.daysAgo) day\(pastItem.daysAgo == 1 ? "" : "s") ago"))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                                .layoutPriority(1)
                        }
                    }
                }

                // Disclosure indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .padding(14)
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 16) {
            GratitudeWidgetCard()
        }
        .padding()
        .background(Color.rrBackground)
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
