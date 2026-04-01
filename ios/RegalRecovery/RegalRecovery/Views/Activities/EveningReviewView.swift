import SwiftUI
import SwiftData

struct EveningReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    private static let questionTexts: [String] = [
        "Did I maintain my sobriety commitment today?",
        "Was I honest in all my interactions today?",
        "Did I reach out for support when I needed it?",
        "What am I grateful for today?",
    ]

    @State private var toggles: [Bool] = Array(repeating: false, count: 4)

    private var latestEvening: RRCommitment? {
        commitments.first { $0.type == "evening" && Calendar.current.isDateInToday($0.date) }
    }

    private var completedTime: String? {
        latestEvening?.completedAt.map { $0.formatted(date: .omitted, time: .shortened) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(.rrPrimary)
                            Text("Evening Review")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            RRBadge(
                                text: completedTime ?? "Not yet",
                                color: completedTime != nil ? .rrSuccess : .rrTextSecondary
                            )
                        }

                        ForEach(Array(Self.questionTexts.enumerated()), id: \.offset) { index, question in
                            HStack(alignment: .top, spacing: 12) {
                                Button {
                                    toggles[index].toggle()
                                } label: {
                                    Image(systemName: toggles[index] ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(toggles[index] ? Color.rrSuccess : Color.rrTextSecondary)
                                        .font(.title3)
                                }

                                Text(question)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                        }

                        if latestEvening == nil {
                            RRButton("Submit Review", icon: "moon.stars.fill") {
                                submitReview()
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
            if let existing = latestEvening {
                let answers = existing.answers.data
                toggles = [
                    answers["sobrietyMaintained"]?.boolValue ?? false,
                    answers["honest"]?.boolValue ?? false,
                    answers["reachedOut"]?.boolValue ?? false,
                    answers["grateful"]?.boolValue ?? false,
                ]
            }
        }
    }

    private func submitReview() {
        let userId = users.first?.id ?? UUID()
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "evening",
            completedAt: Date(),
            answers: JSONPayload([
                "sobrietyMaintained": .bool(toggles[0]),
                "honest": .bool(toggles[1]),
                "reachedOut": .bool(toggles[2]),
                "grateful": .bool(toggles[3]),
            ])
        )
        modelContext.insert(commitment)
    }
}

#Preview {
    NavigationStack {
        EveningReviewView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
