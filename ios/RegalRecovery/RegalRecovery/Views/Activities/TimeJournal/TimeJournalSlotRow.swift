import SwiftUI

struct TimeJournalSlotRow: View {
    let slotIndex: Int
    let mode: TimeJournalMode
    let entry: RRTimeJournalEntry?
    let status: TimeJournalSlotStatus
    let isElapsed: Bool
    let onTap: () -> Void

    private var timeLabel: String {
        let start = mode.slotStartTime(index: slotIndex)
        let hour = start.hour
        let minute = start.minute
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    private var backgroundColor: Color {
        switch status {
        case .empty:
            return isElapsed ? Color.gray.opacity(0.08) : Color.clear
        case .filled:
            return Color.rrPrimary.opacity(0.08)
        case .retroactive:
            return Color.rrSecondary.opacity(0.08)
        case .autoFilled:
            return Color.blue.opacity(0.08)
        case .flagged:
            return Color.orange.opacity(0.08)
        }
    }

    private var borderColor: Color {
        switch status {
        case .empty:
            return Color.gray.opacity(0.3)
        case .filled:
            return Color.rrPrimary.opacity(0.3)
        case .retroactive:
            return Color.rrSecondary.opacity(0.3)
        case .autoFilled:
            return Color.blue.opacity(0.3)
        case .flagged:
            return Color.orange.opacity(0.3)
        }
    }

    private var useDashedBorder: Bool {
        status.useDashedBorder || (status == .empty && !isElapsed)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 0) {
                // Status bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(status == .empty ? Color.gray.opacity(0.3) : status.color)
                    .frame(width: 4, height: 52)
                    .padding(.leading, 4)

                // Time label
                Text(timeLabel)
                    .font(RRFont.caption)
                    .foregroundStyle(.rrTextSecondary)
                    .frame(width: 64, alignment: .trailing)
                    .padding(.top, 4)

                // Content area
                VStack(alignment: .leading, spacing: 4) {
                    if let entry {
                        filledContent(entry: entry)
                    } else if isElapsed {
                        emptyElapsedContent
                    } else {
                        emptyFutureContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(borderColor, style: StrokeStyle(
                            lineWidth: 1,
                            dash: useDashedBorder ? [5, 3] : []
                        ))
                )
                .padding(.leading, 8)
                .padding(.trailing, 12)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Filled Content

    @ViewBuilder
    private func filledContent(entry: RRTimeJournalEntry) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                // Activity text
                Text(entry.activity)
                    .font(RRFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.rrText)
                    .lineLimit(1)

                // Location label
                if !entry.locationLabel.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                        Text(entry.locationLabel)
                            .font(RRFont.caption2)
                            .lineLimit(1)
                    }
                    .foregroundStyle(.rrTextSecondary)
                }

                // Emotions pills (up to 3)
                let emotions = entry.emotions
                if !emotions.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(emotions.prefix(3)) { emotion in
                            HStack(spacing: 2) {
                                Text(emotion.name)
                                    .font(.system(size: 10))
                                // Intensity dots
                                ForEach(0..<min(emotion.intensity, 3), id: \.self) { _ in
                                    Circle()
                                        .fill(emotionColor(for: emotion.category))
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.rrTextSecondary.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .foregroundStyle(.rrTextSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // People count badge
                let peopleCount = entry.people.count
                if peopleCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 9))
                        Text("\(peopleCount)")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(.rrPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.rrPrimary.opacity(0.1))
                    .clipShape(Capsule())
                }

                // Status chips
                HStack(spacing: 4) {
                    if entry.isRetroactive {
                        chipView(text: "Late", color: .rrSecondary)
                    }
                    if entry.isAutoFilled {
                        chipView(text: "Auto", color: .blue)
                    }
                    if entry.isFlagged {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }

    // MARK: - Empty Content

    private var emptyElapsedContent: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle")
                .font(.system(size: 13))
                .foregroundStyle(.rrTextSecondary)
            Text("Tap to log")
                .font(RRFont.caption)
                .foregroundStyle(.rrTextSecondary)
        }
        .padding(.vertical, 6)
    }

    private var emptyFutureContent: some View {
        Text("Upcoming")
            .font(RRFont.caption)
            .foregroundStyle(.rrTextSecondary.opacity(0.5))
            .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private func chipView(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    private func emotionColor(for category: String) -> Color {
        EmotionCatalog.categories.first { $0.name == category }?.color ?? .gray
    }

    private var accessibilityDescription: String {
        let time = mode.slotLabel(index: slotIndex)
        if let entry {
            return "\(time), \(entry.activity), \(status.accessibilityLabel)"
        } else if isElapsed {
            return "\(time), empty past slot, tap to log"
        } else {
            return "\(time), upcoming slot"
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        TimeJournalSlotRow(
            slotIndex: 8,
            mode: .t60,
            entry: nil,
            status: .empty,
            isElapsed: true,
            onTap: {}
        )
        Divider().padding(.leading, 72)
        TimeJournalSlotRow(
            slotIndex: 14,
            mode: .t60,
            entry: nil,
            status: .empty,
            isElapsed: false,
            onTap: {}
        )
    }
    .padding()
}
