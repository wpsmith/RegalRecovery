import SwiftUI
import SwiftData

struct MorningCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    @Query(filter: #Predicate<RRDailyPlanItem> { $0.isEnabled == true })
    private var planItems: [RRDailyPlanItem]

    @State private var statements: [String] = []
    @State private var toggles: [Bool] = []
    @State private var showEditSheet = false
    @State private var showSetup = false

    private var latestMorning: RRCommitment? {
        commitments.first { $0.type == "morning" && Calendar.current.isDateInToday($0.date) }
    }

    private var isAlreadySubmitted: Bool {
        latestMorning != nil
    }

    private var hasMeetingToday: Bool {
        let today = Calendar.current.component(.weekday, from: Date())
        return planItems.contains { item in
            item.activityType == "Meetings Attended" && item.daysOfWeek.contains(today)
        }
    }

    private var addictionNames: [String] {
        addictions.map(\.name)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundStyle(.rrSecondary)
                            Text("Morning Commitment")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Spacer()
                            if let time = latestMorning?.completedAt?.formatted(date: .omitted, time: .shortened) {
                                RRBadge(text: time, color: .rrSuccess)
                            } else {
                                RRBadge(text: "Pending", color: .rrTextSecondary)
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
        .navigationTitle("Sobriety Commitment")
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
                title: "Edit Commitments",
                statements: $statements,
                defaults: CommitmentStatementsManager.dynamicMorningDefaults(
                    addictions: addictionNames,
                    hasMeetingToday: hasMeetingToday
                )
            ) { saved in
                CommitmentStatementsManager.shared.morningStatements = saved
                resizeToggles()
            }
        }
        .fullScreenCover(isPresented: $showSetup) {
            NavigationStack {
                CommitmentSetupView {
                    showSetup = false
                    loadStatements()
                }
            }
        }
        .onAppear {
            loadStatements()
            if !CommitmentStatementsManager.shared.hasCustomized {
                showSetup = true
            }
        }
    }

    // MARK: - Helpers

    private func loadStatements() {
        statements = CommitmentStatementsManager.shared.morningStatements(
            addictions: addictionNames,
            hasMeetingToday: hasMeetingToday
        )
        resizeToggles()

        if let existing = latestMorning {
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

    private func submitCommitment() {
        let userId = users.first?.id ?? UUID()
        var answersDict: [String: AnyCodableValue] = [:]
        for i in 0..<min(toggles.count, statements.count) {
            answersDict["statement_\(i)"] = .bool(toggles[i])
            answersDict["statement_\(i)_text"] = .string(statements[i])
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
