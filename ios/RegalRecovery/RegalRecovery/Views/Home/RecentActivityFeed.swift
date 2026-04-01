import SwiftUI

struct RecentActivityFeed: View {
    let activities: [RecentActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Recent Activity")

            VStack(spacing: 0) {
                ForEach(activities) { activity in
                    activityRow(activity)

                    if activity.id != activities.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
    }

    private func activityRow(_ activity: RecentActivity) -> some View {
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
    RecentActivityFeed(activities: [])
        .padding()
        .background(Color.rrBackground)
}
