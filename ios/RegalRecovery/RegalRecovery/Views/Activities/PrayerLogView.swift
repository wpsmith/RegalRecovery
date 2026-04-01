import SwiftUI
import SwiftData

struct PrayerLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRPrayerLog.date, order: .reverse) private var entries: [RRPrayerLog]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var duration: Double = 12
    @State private var prayerType = "Morning"

    private let prayerTypes = ["Morning", "Evening", "Intercessory", "Meditative", "Free"]

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        }
        if cal.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        RRSectionHeader(title: "New Prayer Entry")

                        // Duration
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                Text("\(Int(duration)) min")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            Slider(value: $duration, in: 1...120, step: 1)
                                .tint(Color.rrPrimary)
                        }

                        Divider()

                        // Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prayer Type")
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                            Picker("Type", selection: $prayerType) {
                                ForEach(prayerTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        RRButton("Start Timer", icon: "timer")
                        RRButton("Log Prayer", icon: "hands.and.sparkles.fill") {
                            submitPrayer()
                        }
                    }
                }
                .padding(.horizontal)

                // History
                if !entries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            RRSectionHeader(title: "History")

                            ForEach(entries) { entry in
                                HStack {
                                    Image(systemName: "hands.and.sparkles.fill")
                                        .foregroundStyle(Color.rrPrimary)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(relativeDay(entry.date))
                                            .font(RRFont.subheadline)
                                            .foregroundStyle(Color.rrText)
                                        Text(entry.prayerType.capitalized)
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }

                                    Spacer()

                                    Text("\(entry.durationMinutes) min")
                                        .font(RRFont.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.rrPrimary)
                                }
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    private func submitPrayer() {
        let userId = users.first?.id ?? UUID()
        let entry = RRPrayerLog(
            userId: userId,
            date: Date(),
            durationMinutes: Int(duration),
            prayerType: prayerType.lowercased()
        )
        modelContext.insert(entry)
    }
}

#Preview {
    NavigationStack {
        PrayerLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
