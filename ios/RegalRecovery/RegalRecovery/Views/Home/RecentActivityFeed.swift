import SwiftUI

struct RecentActivityFeed: View {
    let activities: [RecentActivity]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: String(localized: "Recent Activity"))

            VStack(spacing: 0) {
                ForEach(activities) { activity in
                    NavigationLink {
                        ActivityDetailView(activity: activity)
                    } label: {
                        RecentActivityRow(activity: activity)
                    }
                    .buttonStyle(.plain)

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
