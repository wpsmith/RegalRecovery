import SwiftUI

/// Single activity row with state-dependent appearance and swipe gestures.
struct TodayActivityRow: View {
    let item: TodayPlanItem
    var onComplete: (() -> Void)?
    var onSkip: ((String) -> Void)?

    private static let completedTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        HStack(spacing: 12) {
            // State icon
            Image(systemName: item.state.icon)
                .font(.body)
                .foregroundStyle(item.state.color)
                .frame(width: 24)

            // Activity info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .font(RRFont.body)
                    .foregroundStyle(textColor)
                    .strikethrough(item.state == .skipped)

                Text(item.scheduledTimeString)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Spacer()

            if item.state == .completed, let completedAt = item.completedAt {
                Text("Done \(Self.completedTimeFormatter.string(from: completedAt))")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrSuccess)
            } else {
                // State label
                Text(item.state.displayName)
                    .font(RRFont.caption)
                    .foregroundStyle(item.state.color)
            }

            if item.state == .pending || item.state == .upcoming || item.state == .overdue {
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if item.state != .completed && item.state != .skipped {
                Button {
                    onSkip?(String(localized: "Not today"))
                } label: {
                    Label("Skip", systemImage: "xmark.circle")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if item.state != .completed && item.state != .skipped {
                Button {
                    onComplete?()
                } label: {
                    Label("Complete", systemImage: "checkmark.circle")
                }
                .tint(.rrSuccess)
            }
        }
    }

    private var textColor: Color {
        switch item.state {
        case .completed: return Color.rrTextSecondary
        case .pending: return Color.rrText
        case .upcoming: return Color.rrTextSecondary
        case .overdue: return Color.rrText
        case .skipped: return Color.rrTextSecondary
        }
    }
}
