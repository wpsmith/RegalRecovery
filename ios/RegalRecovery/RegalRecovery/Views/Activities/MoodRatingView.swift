import SwiftUI
import SwiftData

struct MoodRatingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRMoodEntry.date, order: .reverse) private var entries: [RRMoodEntry]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var moodValue: Double = 7

    private var emoji: String {
        switch Int(moodValue) {
        case 1...2: return "\u{1F622}"
        case 3...4: return "\u{1F61F}"
        case 5...6: return "\u{1F610}"
        case 7...8: return "\u{1F60A}"
        default: return "\u{1F604}"
        }
    }

    private var weekMoods: [(String, Int, Color)] {
        let dayLabels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let recentSeven = Array(entries.prefix(7).reversed())
        return recentSeven.enumerated().map { index, entry in
            let label = index < dayLabels.count ? dayLabels[index] : "\(index)"
            let color: Color = {
                switch entry.score {
                case 1...4: return .orange
                case 5...6: return .yellow
                default: return .green
                }
            }()
            return (label, entry.score, color)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                RRCard {
                    VStack(spacing: 20) {
                        Text("How are you feeling?")
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)

                        Text(emoji)
                            .font(.system(size: 80))

                        Text("\(Int(moodValue))/10")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.rrPrimary)

                        Slider(value: $moodValue, in: 1...10, step: 1)
                            .tint(Color.rrPrimary)

                        HStack {
                            Text("Terrible")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Spacer()
                            Text("Amazing")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        RRButton("Log Mood", icon: "face.smiling") {
                            submitMood()
                        }
                    }
                }
                .padding(.horizontal)

                // This Week
                if !weekMoods.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            RRSectionHeader(title: "This Week")

                            HStack(spacing: 0) {
                                ForEach(weekMoods, id: \.0) { day, score, color in
                                    VStack(spacing: 8) {
                                        Text("\(score)")
                                            .font(RRFont.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.rrText)

                                        Circle()
                                            .fill(color)
                                            .frame(width: 28, height: 28)

                                        Text(day)
                                            .font(RRFont.caption2)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
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

    private func submitMood() {
        let userId = users.first?.id ?? UUID()
        let entry = RRMoodEntry(
            userId: userId,
            date: Date(),
            score: Int(moodValue)
        )
        modelContext.insert(entry)
    }
}

#Preview {
    NavigationStack {
        MoodRatingView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
