import SwiftUI
import SwiftData

struct EveningReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var statements: [String] = []
    @State private var toggles: [Bool] = []
    @State private var showEditSheet = false

    private var latestEvening: RRCommitment? {
        commitments.first { $0.type == "evening" && Calendar.current.isDateInToday($0.date) }
    }

    private var isAlreadySubmitted: Bool {
        latestEvening != nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .foregroundStyle(.rrPrimary)
                            Text("Evening Review")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            if let time = latestEvening?.completedAt?.formatted(date: .omitted, time: .shortened) {
                                RRBadge(text: time, color: .rrSuccess)
                            } else {
                                RRBadge(text: "Not yet", color: .rrTextSecondary)
                            }
                        }

                        // Statements
                        ForEach(Array(statements.enumerated()), id: \.offset) { index, statement in
                            Button {
                                guard !isAlreadySubmitted, index < toggles.count else { return }
                                toggles[index].toggle()
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: (index < toggles.count && toggles[index]) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle((index < toggles.count && toggles[index]) ? Color.rrSuccess : Color.rrTextSecondary)
                                        .font(.title3)

                                    Text(statement)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(isAlreadySubmitted)
                        }

                        // Submit button
                        if !isAlreadySubmitted {
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
        .navigationTitle("Evening Review")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditCommitmentStatementsView(
                title: "Edit Evening Review",
                statements: $statements,
                defaults: CommitmentStatementsManager.defaultEveningStatements
            ) { saved in
                CommitmentStatementsManager.shared.eveningStatements = saved
                resizeToggles()
            }
        }
        .onAppear {
            loadStatements()
        }
    }

    // MARK: - Helpers

    private func loadStatements() {
        statements = CommitmentStatementsManager.shared.eveningStatements
        resizeToggles()

        if let existing = latestEvening {
            let answers = existing.answers.data
            for i in 0..<toggles.count {
                toggles[i] = answers["statement_\(i)"]?.boolValue ?? false
            }
        }
    }

    private func resizeToggles() {
        let needed = statements.count
        if toggles.count < needed {
            toggles.append(contentsOf: Array(repeating: false, count: needed - toggles.count))
        } else if toggles.count > needed {
            toggles = Array(toggles.prefix(needed))
        }
    }

    private func submitReview() {
        let userId = users.first?.id ?? UUID()
        var answersDict: [String: AnyCodableValue] = [:]
        for i in 0..<min(toggles.count, statements.count) {
            answersDict["statement_\(i)"] = .bool(toggles[i])
            answersDict["statement_\(i)_text"] = .string(statements[i])
        }
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "evening",
            completedAt: Date(),
            answers: JSONPayload(answersDict)
        )
        modelContext.insert(commitment)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EveningReviewView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
