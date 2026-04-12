import SwiftUI
import SwiftData

struct SobrietyCommitmentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRCommitment.date, order: .reverse) private var commitments: [RRCommitment]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    @Query(filter: #Predicate<RRDailyPlanItem> { $0.isEnabled == true })
    private var planItems: [RRDailyPlanItem]

    @State private var selectedSegment = 0
    @State private var morningStatements: [String] = []
    @State private var eveningStatements: [String] = CommitmentStatementsManager.shared.eveningStatements
    @State private var morningToggles: [Bool] = []
    @State private var eveningToggles: [Bool] = []
    @State private var showEditMorning = false
    @State private var showEditEvening = false

    private var latestMorning: RRCommitment? {
        commitments.first { $0.type == "morning" && Calendar.current.isDateInToday($0.date) }
    }

    private var latestEvening: RRCommitment? {
        commitments.first { $0.type == "evening" && Calendar.current.isDateInToday($0.date) }
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
                Picker("Time of Day", selection: $selectedSegment) {
                    Text("Morning").tag(0)
                    Text("Evening").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedSegment == 0 {
                    morningSection
                } else {
                    eveningSection
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectedSegment == 0 {
                        showEditMorning = true
                    } else {
                        showEditEvening = true
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .sheet(isPresented: $showEditMorning) {
            EditCommitmentStatementsView(
                title: "Edit Morning Commitments",
                statements: $morningStatements,
                defaults: CommitmentStatementsManager.dynamicMorningDefaults(
                    addictions: addictionNames,
                    hasMeetingToday: hasMeetingToday
                )
            ) { saved in
                CommitmentStatementsManager.shared.morningStatements = saved
                resizeMorningToggles()
            }
        }
        .sheet(isPresented: $showEditEvening) {
            EditCommitmentStatementsView(
                title: "Edit Evening Commitments",
                statements: $eveningStatements,
                defaults: CommitmentStatementsManager.defaultEveningStatements
            ) { saved in
                CommitmentStatementsManager.shared.eveningStatements = saved
                resizeEveningToggles()
            }
        }
        .onAppear {
            morningStatements = CommitmentStatementsManager.shared.morningStatements(
                addictions: addictionNames,
                hasMeetingToday: hasMeetingToday
            )
            eveningStatements = CommitmentStatementsManager.shared.eveningStatements
            resizeMorningToggles()
            resizeEveningToggles()

            if let existing = latestMorning {
                let answers = existing.answers.data
                for i in 0..<morningToggles.count {
                    morningToggles[i] = answers["statement_\(i)"]?.boolValue ?? false
                }
            }
            if let existing = latestEvening {
                let answers = existing.answers.data
                for i in 0..<eveningToggles.count {
                    eveningToggles[i] = answers["statement_\(i)"]?.boolValue ?? false
                }
            }
        }
    }

    // MARK: - Morning Section

    private var morningSection: some View {
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

                ForEach(Array(morningStatements.enumerated()), id: \.offset) { index, question in
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            guard latestMorning == nil, index < morningToggles.count else { return }
                            morningToggles[index].toggle()
                        } label: {
                            Image(systemName: (index < morningToggles.count && morningToggles[index]) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle((index < morningToggles.count && morningToggles[index]) ? Color.rrSuccess : Color.rrTextSecondary)
                                .font(.title3)
                        }
                        .disabled(latestMorning != nil)

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
    }

    // MARK: - Evening Section

    private var eveningSection: some View {
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

                ForEach(Array(eveningStatements.enumerated()), id: \.offset) { index, question in
                    HStack(alignment: .top, spacing: 12) {
                        Button {
                            guard latestEvening == nil, index < eveningToggles.count else { return }
                            eveningToggles[index].toggle()
                        } label: {
                            Image(systemName: (index < eveningToggles.count && eveningToggles[index]) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle((index < eveningToggles.count && eveningToggles[index]) ? Color.rrSuccess : Color.rrTextSecondary)
                                .font(.title3)
                        }
                        .disabled(latestEvening != nil)

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

    // MARK: - Helpers

    private func resizeMorningToggles() {
        let needed = morningStatements.count
        if morningToggles.count < needed {
            morningToggles.append(contentsOf: Array(repeating: false, count: needed - morningToggles.count))
        } else if morningToggles.count > needed {
            morningToggles = Array(morningToggles.prefix(needed))
        }
    }

    private func resizeEveningToggles() {
        let needed = eveningStatements.count
        if eveningToggles.count < needed {
            eveningToggles.append(contentsOf: Array(repeating: false, count: needed - eveningToggles.count))
        } else if eveningToggles.count > needed {
            eveningToggles = Array(eveningToggles.prefix(needed))
        }
    }

    private func submitMorning() {
        let userId = users.first?.id ?? UUID()
        var answersDict: [String: AnyCodableValue] = [:]
        for i in 0..<min(morningToggles.count, morningStatements.count) {
            answersDict["statement_\(i)"] = .bool(morningToggles[i])
            answersDict["statement_\(i)_text"] = .string(morningStatements[i])
        }
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "morning",
            completedAt: Date(),
            answers: JSONPayload(answersDict)
        )
        modelContext.insert(commitment)
    }

    private func submitEvening() {
        let userId = users.first?.id ?? UUID()
        var answersDict: [String: AnyCodableValue] = [:]
        for i in 0..<min(eveningToggles.count, eveningStatements.count) {
            answersDict["statement_\(i)"] = .bool(eveningToggles[i])
            answersDict["statement_\(i)_text"] = .string(eveningStatements[i])
        }
        let commitment = RRCommitment(
            userId: userId,
            date: Date(),
            type: "evening",
            completedAt: Date(),
            answers: JSONPayload(answersDict)
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
