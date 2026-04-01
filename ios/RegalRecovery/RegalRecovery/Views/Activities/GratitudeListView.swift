import SwiftUI
import SwiftData

struct GratitudeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var entries: [RRGratitudeEntry]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var item1 = ""
    @State private var item2 = ""
    @State private var item3 = ""

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        RRSectionHeader(title: "Today's Gratitude")

                        VStack(spacing: 12) {
                            gratitudeField(number: 1, text: $item1)
                            gratitudeField(number: 2, text: $item2)
                            gratitudeField(number: 3, text: $item3)
                        }

                        RRButton("Save Gratitude", icon: "leaf.fill") {
                            submitGratitude()
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
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(relativeDay(entry.date))
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                    ForEach(entry.items, id: \.self) { item in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "leaf.fill")
                                                .font(.caption2)
                                                .foregroundStyle(Color.rrSuccess)
                                            Text(item)
                                                .font(RRFont.body)
                                                .foregroundStyle(Color.rrText)
                                        }
                                    }
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

    private func gratitudeField(number: Int, text: Binding<String>) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number).")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrPrimary)
                .frame(width: 24)
            TextField("I'm grateful for...", text: text, axis: .vertical)
                .font(RRFont.body)
                .textFieldStyle(.roundedBorder)
        }
    }

    private func submitGratitude() {
        let userId = users.first?.id ?? UUID()
        let items = [item1, item2, item3].filter { !$0.isEmpty }
        guard !items.isEmpty else { return }
        let entry = RRGratitudeEntry(
            userId: userId,
            date: Date(),
            items: items
        )
        modelContext.insert(entry)
        item1 = ""
        item2 = ""
        item3 = ""
    }
}

#Preview {
    NavigationStack {
        GratitudeListView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
