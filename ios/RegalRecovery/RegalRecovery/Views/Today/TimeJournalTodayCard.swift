import SwiftUI

/// A card for the Today screen showing Time Journal progress and status (TJ-065 through TJ-068).
struct TimeJournalTodayCard: View {
    let filledCount: Int
    let totalSlots: Int
    let dayStatus: TimeJournalDayStatus
    let mode: TimeJournalMode
    let lastUpdated: Date?

    private var progressFraction: Double {
        guard totalSlots > 0 else { return 0 }
        return Double(filledCount) / Double(totalSlots)
    }

    private var modeLabel: String {
        switch mode {
        case .t30: return "T-30"
        case .t60: return "T-60"
        }
    }

    private var subtitleText: String {
        if let lastUpdated {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Last updated \(formatter.string(from: lastUpdated))"
        }
        return String(localized: "No entries yet today")
    }

    var body: some View {
        HStack(spacing: 12) {
            // Left icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "clock.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Time Journal (\(modeLabel))")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Spacer()

                    // Status badge
                    Text(dayStatus.label)
                        .font(RRFont.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(dayStatus.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(dayStatus.color.opacity(0.12))
                        .clipShape(Capsule())
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.rrPrimary)
                            .frame(width: geometry.size.width * progressFraction, height: 6)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(subtitleText)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    Spacer()

                    Text("\(filledCount)/\(totalSlots)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
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
}

#Preview {
    VStack(spacing: 16) {
        TimeJournalTodayCard(
            filledCount: 8,
            totalSlots: 24,
            dayStatus: .inProgress,
            mode: .t60,
            lastUpdated: Date()
        )

        TimeJournalTodayCard(
            filledCount: 0,
            totalSlots: 48,
            dayStatus: .overdue,
            mode: .t30,
            lastUpdated: nil
        )

        TimeJournalTodayCard(
            filledCount: 24,
            totalSlots: 24,
            dayStatus: .completed,
            mode: .t60,
            lastUpdated: Date()
        )
    }
    .padding()
    .background(Color.rrBackground)
}
