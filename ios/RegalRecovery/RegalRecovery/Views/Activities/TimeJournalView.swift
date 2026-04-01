import SwiftUI
import SwiftData

struct TimeJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRTimeBlock.startHour) private var allBlocks: [RRTimeBlock]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    private var todayBlocks: [RRTimeBlock] {
        allBlocks.filter { Calendar.current.isDateInToday($0.date) }
    }

    private func needColor(_ need: String) -> Color {
        switch need {
        case "Peace": return .rrPrimary
        case "Agency": return .blue
        case "Connection", "Love": return .pink
        case "Belonging": return .rrPrimary
        case "Comfort": return .orange
        case "Understanding": return .purple
        case "Hope": return .rrPrimary
        default: return .rrTextSecondary
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        RRSectionHeader(title: "Today's Timeline")
                        Text("\(todayBlocks.count) entries logged")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .padding(.horizontal)

                // Timeline
                VStack(spacing: 0) {
                    ForEach(todayBlocks) { block in
                        HStack(alignment: .top, spacing: 12) {
                            // Time label
                            VStack {
                                Text(timeString(hour: block.startHour, minute: block.startMinute))
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .frame(width: 56, alignment: .trailing)
                            }

                            // Block
                            VStack(alignment: .leading, spacing: 4) {
                                Text(block.activity)
                                    .font(RRFont.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.rrText)

                                HStack(spacing: 6) {
                                    RRBadge(text: block.need, color: needColor(block.need))
                                    Text("\(block.durationMinutes) min")
                                        .font(RRFont.caption2)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(needColor(block.need).opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .frame(minHeight: CGFloat(block.durationMinutes))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                    }
                }

                // Pattern card
                RRCard {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.pie.fill")
                            .font(.title2)
                            .foregroundStyle(Color.pink)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly Pattern")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            let connectionMinutes = allBlocks.filter { $0.need == "Connection" || $0.need == "Love" }.reduce(0) { $0 + $1.durationMinutes }
                            let hours = String(format: "%.1f", Double(connectionMinutes) / 60.0)
                            Text("\(hours) hrs Connection this week")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    private func timeString(hour: Int, minute: Int) -> String {
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
}

#Preview {
    NavigationStack {
        TimeJournalView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
