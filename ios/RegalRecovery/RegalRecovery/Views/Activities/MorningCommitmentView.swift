import SwiftUI
import SwiftData

struct MorningCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var statements: [String] = CommitmentStatementsManager.shared.morningStatements
    @State private var toggles: [Bool] = []
    @State private var showEditSheet = false

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
                            Button {
                                showEditSheet = true
                            } label: {
                                Image(systemName: "pencil.circle")
                                    .font(.title3)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            RRBadge(
                                text: completedTime ?? "Pending",
                                color: completedTime != nil ? .rrSuccess : .rrTextSecondary
                            )
                        }

                        ForEach(Array(statements.enumerated()), id: \.offset) { index, question in
                            Button {
                                if index < toggles.count {
                                    toggles[index].toggle()
                                }
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: (index < toggles.count && toggles[index]) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle((index < toggles.count && toggles[index]) ? Color.rrSuccess : Color.rrTextSecondary)
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
        .sheet(isPresented: $showEditSheet) {
            EditCommitmentStatementsView(
                title: "Edit Morning Commitments",
                statements: $statements,
                defaults: CommitmentStatementsManager.defaultMorningStatements
            ) { saved in
                CommitmentStatementsManager.shared.morningStatements = saved
                resizeToggles()
            }
        }
        .onAppear {
            statements = CommitmentStatementsManager.shared.morningStatements
            resizeToggles()

            if let existing = latestMorning {
                let answers = existing.answers.data
                for i in 0..<toggles.count {
                    toggles[i] = answers["statement_\(i)"]?.boolValue ?? false
                }
            }
        }
    }

    // MARK: - Helpers

    private func resizeToggles() {
        let needed = statements.count
        if toggles.count < needed {
            toggles.append(contentsOf: Array(repeating: false, count: needed - toggles.count))
        } else if toggles.count > needed {
            toggles = Array(toggles.prefix(needed))
        }
    }

    private func submitCommitment() {
        let userId = users.first?.id ?? UUID()
        var answersDict: [String: AnyCodableValue] = [:]
        for i in 0..<min(toggles.count, statements.count) {
            answersDict["statement_\(i)"] = .bool(toggles[i])
        }
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "morning",
            completedAt: Date(),
            answers: JSONPayload(answersDict)
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
