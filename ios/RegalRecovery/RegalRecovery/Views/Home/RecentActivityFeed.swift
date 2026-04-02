import SwiftUI

struct RecentActivityFeed: View {
    let activities: [RecentActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Recent Activity")

            VStack(spacing: 0) {
                ForEach(activities) { activity in
                    RecentActivityRow(activity: activity)

                    if activity.id != activities.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
        }
    }
}

#Preview {
    RecentActivityFeed(activities: [])
        .padding()
        .background(Color.rrBackground)
}
