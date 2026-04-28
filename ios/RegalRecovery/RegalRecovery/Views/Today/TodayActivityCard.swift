import SwiftUI

struct TodayActivityCard: View {
    let item: TodayPlanItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(item.iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Spacer()

                    statusBadge
                }

                Text(item.scheduledTimeString)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(14)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch item.state {
        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                Text(completedTimeText)
                    .font(RRFont.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.rrSuccess)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.rrSuccess.opacity(0.12))
            .clipShape(Capsule())
        case .overdue:
            Text("Overdue")
                .font(RRFont.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrDestructive)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.rrDestructive.opacity(0.12))
                .clipShape(Capsule())
        case .skipped:
            Text("Skipped")
                .font(RRFont.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.rrTextSecondary.opacity(0.12))
                .clipShape(Capsule())
        default:
            Text("Not yet")
                .font(RRFont.caption2)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.rrTextSecondary.opacity(0.12))
                .clipShape(Capsule())
        }
    }

    private var completedTimeText: String {
        if let completedAt = item.completedAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Done \(formatter.string(from: completedAt))"
        }
        return "Done"
    }
}
