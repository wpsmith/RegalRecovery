import SwiftUI

struct RecentActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.caption)
                .foregroundStyle(activity.iconColor)
                .frame(width: 32, height: 32)
                .background(activity.iconColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)

                Text(activity.detail)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(activity.time)
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RecentActivityRow(activity: RecentActivity(
        title: "Morning Commitment",
        detail: "Completed",
        time: "2h ago",
        icon: "sunrise.fill",
        iconColor: .orange
    ))
    .padding(.horizontal)
}
