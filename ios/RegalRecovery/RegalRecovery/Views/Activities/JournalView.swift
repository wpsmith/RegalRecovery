import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var entries: [RRJournalEntry]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var selectedMode = 0
    @State private var journalText = ""

    private let modes = ["Jotting", "Free-form", "Prompted", "Structured"]
    private let modeKeys = ["jotting", "freeform", "prompted", "structured"]

    private let prompts = [
        "What are you grateful for?",
        "What triggered you today?",
        "What did you learn about yourself?",
        "How did you show up for your recovery?",
        "What would you tell yourself a year from now?",
    ]

    @State private var promptIndex = Int.random(in: 0..<5)

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
                Picker("Mode", selection: $selectedMode) {
                    ForEach(0..<modes.count, id: \.self) { index in
                        Text(modes[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(modes[selectedMode])
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        if selectedMode == 2 {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                Text(prompts[promptIndex])
                                    .font(RRFont.subheadline)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .italic()
                            }
                            .padding(12)
                            .background(Color.yellow.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }

                        TextEditor(text: $journalText)
                            .frame(minHeight: 180)
                            .font(RRFont.body)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color.rrBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        RRButton("Save Entry", icon: "square.and.arrow.down") {
                            submitJournal()
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
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(relativeDay(entry.date))
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                    Text(entry.content)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                        .lineLimit(2)
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

    private func submitJournal() {
        let userId = users.first?.id ?? UUID()
        guard !journalText.isEmpty else { return }
        let entry = RRJournalEntry(
            userId: userId,
            date: Date(),
            mode: modeKeys[selectedMode],
            content: journalText,
            prompt: selectedMode == 2 ? prompts[promptIndex] : nil
        )
        modelContext.insert(entry)
        journalText = ""
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
