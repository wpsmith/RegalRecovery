import SwiftUI
import SwiftData

struct MorningCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    private static let questionTexts: [String] = [
        "I commit to sexual sobriety today \u{2014} no sex with self, no sex outside of marriage.",
        "I will reach out to my sponsor or accountability partner if I am struggling.",
        "I will attend my scheduled recovery meeting.",
        "I will spend time in prayer and scripture today.",
        "I will be honest with myself and others today.",
        "I surrender this day to God and trust His plan for my recovery.",
    ]

    @State private var toggles: [Bool] = Array(repeating: false, count: 6)

    private var latestMorning: RRCommitment? {
        commitments.first { $0.type == "morning" && Calendar.current.isDateInToday($0.date) }
    }

    private var completedTime: String? {
        latestMorning?.completedAt.map { $0.formatted(date: .omitted, time: .shortened) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundStyle(.rrSecondary)
                            Text("Morning Commitment")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            RRBadge(
                                text: completedTime ?? "Pending",
                                color: completedTime != nil ? .rrSuccess : .rrTextSecondary
                            )
                        }

                        ForEach(Array(Self.questionTexts.enumerated()), id: \.offset) { index, question in
                            Button {
                                toggles[index].toggle()
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: toggles[index] ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(toggles[index] ? Color.rrSuccess : Color.rrTextSecondary)
                                        .font(.title3)

                                    Text(question)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        if latestMorning == nil {
                            RRButton("Submit Commitment", icon: "sunrise.fill") {
                                submitCommitment()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .onAppear {
            if let existing = latestMorning {
                let answers = existing.answers.data
                toggles = [
                    answers["sobrietyCommit"]?.boolValue ?? false,
                    answers["reachOut"]?.boolValue ?? false,
                    answers["attendMeeting"]?.boolValue ?? false,
                    answers["prayerScripture"]?.boolValue ?? false,
                    answers["honest"]?.boolValue ?? false,
                    answers["surrender"]?.boolValue ?? false,
                ]
            }
        }
    }

    private func submitCommitment() {
        let userId = users.first?.id ?? UUID()
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "morning",
            completedAt: Date(),
            answers: JSONPayload([
                "sobrietyCommit": .bool(toggles[0]),
                "reachOut": .bool(toggles[1]),
                "attendMeeting": .bool(toggles[2]),
                "prayerScripture": .bool(toggles[3]),
                "honest": .bool(toggles[4]),
                "surrender": .bool(toggles[5]),
            ])
        )
        modelContext.insert(commitment)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MorningCommitmentView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
