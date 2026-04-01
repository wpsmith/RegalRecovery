import SwiftUI

struct PrayersView: View {
    let prayer: PrayerItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Icon and title
                HStack(spacing: 12) {
                    Image(systemName: prayer.icon)
                        .font(.title)
                        .foregroundStyle(Color.rrPrimary)
                    Text(prayer.title)
                        .font(RRFont.largeTitle)
                        .foregroundStyle(Color.rrText)
                }

                Divider()

                // Prayer text
                Text(prayer.text)
                    .font(.title3)
                    .foregroundStyle(Color.rrText)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 40)
            }
            .padding(24)
        }
        .background(
            ZStack {
                Color.rrBackground
                Color.rrPrimary.opacity(0.05)
            }
            .ignoresSafeArea()
        )
    }
}

#Preview {
    NavigationStack {
        PrayersView(prayer: ContentData.prayers[0])
    }
}
