import SwiftUI
import SwiftData

struct AffirmationLogView: View {
    @Query(sort: \RRAffirmationFavorite.createdAt, order: .reverse) private var favorites: [RRAffirmationFavorite]

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
            VStack(spacing: 12) {
                RRCard {
                    HStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .font(.title2)
                            .foregroundStyle(Color.rrSecondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Affirmation Streak")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Text("\(favorites.count) favorites saved")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                        }
                        Spacer()
                    }
                }
                .padding(.horizontal)

                ForEach(favorites) { entry in
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(relativeDay(entry.createdAt))
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                Spacer()
                                RRBadge(text: entry.packName, color: .rrSecondary)
                            }

                            Text("\"\(entry.affirmationText)\"")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .italic()

                            if !entry.scripture.isEmpty {
                                Text(entry.scripture)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrPrimary)
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
}

#Preview {
    NavigationStack {
        AffirmationLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
