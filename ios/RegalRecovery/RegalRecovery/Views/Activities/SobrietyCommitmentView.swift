import SwiftUI
import SwiftData

struct SobrietyCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var selectedSegment = 0

    private static let morningQuestionTexts: [String] = [
        "I commit to sexual sobriety today \u{2014} no sex with self, no sex outside of marriage.",
        "I will reach out to my sponsor or accountability partner if I am struggling.",
        "I will attend my scheduled recovery meeting.",
        "I will spend time in prayer and scripture today.",
        "I will be honest with myself and others today.",
        "I surrender this day to God and trust His plan for my recovery.",
    ]

    private static let eveningQuestionTexts: [String] = [
        "Did I maintain my sobriety commitment today?",
        "Was I honest in all my interactions today?",
        "Did I reach out for support when I needed it?",
        "What am I grateful for today?",
    ]

    @State private var morningToggles: [Bool] = Array(repeating: false, count: 6)
    @State private var eveningToggles: [Bool] = Array(repeating: false, count: 4)

    private var latestMorning: RRCommitment? {
        commitments.first { $0.type == "morning" && Calendar.current.isDateInToday($0.date) }
    }

    private var latestEvening: RRCommitment? {
        commitments.first { $0.type == "evening" && Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Time of Day", selection: $selectedSegment) {
                    Text("Morning").tag(0)
                    Text("Evening").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedSegment == 0 {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "sunrise.fill")
                                    .foregroundStyle(.rrSecondary)
                                Text("Morning Commitment")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                let time = latestMorning?.completedAt?.formatted(date: .omitted, time: .shortened)
                                RRBadge(text: time ?? "Pending", color: time != nil ? .rrSuccess : .rrTextSecondary)
                            }

                            ForEach(Array(Self.morningQuestionTexts.enumerated()), id: \.offset) { index, question in
                                HStack(alignment: .top, spacing: 12) {
                                    Button {
                                        morningToggles[index].toggle()
                                    } label: {
                                        Image(systemName: morningToggles[index] ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(morningToggles[index] ? Color.rrSuccess : Color.rrTextSecondary)
                                            .font(.title3)
                                    }

                                    Text(question)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                }
                            }

                            if latestMorning == nil {
                                RRButton("Submit Commitment", icon: "sunrise.fill") {
                                    submitMorning()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "moon.stars.fill")
                                    .foregroundStyle(.rrPrimary)
                                Text("Evening Review")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                let time = latestEvening?.completedAt?.formatted(date: .omitted, time: .shortened)
                                RRBadge(text: time ?? "Not yet", color: time != nil ? .rrSuccess : .rrTextSecondary)
                            }

                            ForEach(Array(Self.eveningQuestionTexts.enumerated()), id: \.offset) { index, question in
                                HStack(alignment: .top, spacing: 12) {
                                    Button {
                                        eveningToggles[index].toggle()
                                    } label: {
                                        Image(systemName: eveningToggles[index] ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(eveningToggles[index] ? Color.rrSuccess : Color.rrTextSecondary)
                                            .font(.title3)
                                    }

                                    Text(question)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                }
                            }

                            if latestEvening == nil {
                                RRButton("Submit Review", icon: "moon.stars.fill") {
                                    submitEvening()
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
        .onAppear {
            if let existing = latestMorning {
                let answers = existing.answers.data
                morningToggles = [
                    answers["sobrietyCommit"]?.boolValue ?? false,
                    answers["reachOut"]?.boolValue ?? false,
                    answers["attendMeeting"]?.boolValue ?? false,
                    answers["prayerScripture"]?.boolValue ?? false,
                    answers["honest"]?.boolValue ?? false,
                    answers["surrender"]?.boolValue ?? false,
                ]
            }
            if let existing = latestEvening {
                let answers = existing.answers.data
                eveningToggles = [
                    answers["sobrietyMaintained"]?.boolValue ?? false,
                    answers["honest"]?.boolValue ?? false,
                    answers["reachedOut"]?.boolValue ?? false,
                    answers["grateful"]?.boolValue ?? false,
                ]
            }
        }
    }

    private func submitMorning() {
        let userId = users.first?.id ?? UUID()
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "morning",
            completedAt: Date(),
            answers: JSONPayload([
                "sobrietyCommit": .bool(morningToggles[0]),
                "reachOut": .bool(morningToggles[1]),
                "attendMeeting": .bool(morningToggles[2]),
                "prayerScripture": .bool(morningToggles[3]),
                "honest": .bool(morningToggles[4]),
                "surrender": .bool(morningToggles[5]),
            ])
        )
        modelContext.insert(commitment)
    }

    private func submitEvening() {
        let userId = users.first?.id ?? UUID()
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "evening",
            completedAt: Date(),
            answers: JSONPayload([
                "sobrietyMaintained": .bool(eveningToggles[0]),
                "honest": .bool(eveningToggles[1]),
                "reachedOut": .bool(eveningToggles[2]),
                "grateful": .bool(eveningToggles[3]),
            ])
        )
        modelContext.insert(commitment)
    }
}

#Preview {
    NavigationStack {
        SobrietyCommitmentView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
