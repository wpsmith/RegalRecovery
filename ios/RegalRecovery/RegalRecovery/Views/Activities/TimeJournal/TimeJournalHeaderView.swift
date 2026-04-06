import SwiftUI

struct TimeJournalHeaderView: View {
    let date: Date
    let status: TimeJournalDayStatus
    let completionPercent: Double
    let mode: TimeJournalMode
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void

    private var dateLabel: String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        }
    }

    private var isFutureDate: Bool {
        date > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        VStack(spacing: 12) {
            // Date navigation row
            HStack {
                Button(action: onPreviousDay) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.rrPrimary)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                Text(dateLabel)
                    .font(RRFont.title)
                    .foregroundStyle(.rrText)

                Spacer()

                Button(action: onNextDay) {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isFutureDate ? .rrTextSecondary.opacity(0.4) : .rrPrimary)
                        .frame(width: 44, height: 44)
                }
                .disabled(isFutureDate)
            }
            .padding(.horizontal, 8)

            // Status row with completion ring
            HStack(spacing: 16) {
                // Completion ring
                ZStack {
                    Circle()
                        .stroke(Color.rrTextSecondary.opacity(0.2), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: completionPercent)
                        .stroke(status.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: completionPercent)

                    Text("\(Int(completionPercent * 100))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.rrText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Status badge
                    Text(status.label)
                        .font(RRFont.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(status.color)
                        .clipShape(Capsule())

                    // Mode indicator
                    Text(mode.displayName)
                        .font(RRFont.caption)
                        .foregroundStyle(.rrTextSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(Color.rrSurface)
    }
}

#Preview {
    VStack(spacing: 0) {
        TimeJournalHeaderView(
            date: Date(),
            status: .inProgress,
            completionPercent: 0.45,
            mode: .t60,
            onPreviousDay: {},
            onNextDay: {}
        )
        Spacer()
    }
}
