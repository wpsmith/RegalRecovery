import SwiftUI
import SwiftData

struct PrayersView: View {
    let prayer: PrayerItem
    let isCompletedToday: Bool
    let isOnCooldown: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var logged = false

    private var isLoggingDisabled: Bool {
        logged || isCompletedToday || isOnCooldown
    }

    private var disabledMessage: String? {
        if isCompletedToday {
            return "Already prayed today"
        } else if isOnCooldown {
            return "Please wait before logging again"
        }
        return nil
    }

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

                Spacer(minLength: 24)

                if logged {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.rrSuccess)
                        Text("Prayer logged")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrSuccess)
                    }
                    .frame(maxWidth: .infinity)
                } else if let message = disabledMessage {
                    HStack {
                        Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(message)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    RRButton("Log Prayer", icon: "hands.and.sparkles.fill") {
                        submitPrayer()
                    }
                }
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

    private func submitPrayer() {
        let userId = users.first?.id ?? UUID()
        let entry = RRPrayerLog(
            userId: userId,
            date: Date(),
            durationMinutes: 0,
            prayerType: prayer.title
        )
        modelContext.insert(entry)
        logged = true
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PrayersView(prayer: ContentData.prayers[0], isCompletedToday: false, isOnCooldown: false)
    }
}
