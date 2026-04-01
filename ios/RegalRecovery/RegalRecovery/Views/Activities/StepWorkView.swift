import SwiftUI
import SwiftData

struct StepWorkView: View {
    @Query(sort: \RRStepWork.stepNumber) private var steps: [RRStepWork]

    @State private var selectedStep: RRStepWork?

    private static let stepMeta: [(String, String, String, [String])] = [
        ("Powerlessness", "We admitted that we were powerless over lust \u{2014} that our lives had become unmanageable.", "Romans 7:18", []),
        ("Hope", "Came to believe that a Power greater than ourselves could restore us to sanity.", "Hebrews 11:1", []),
        ("Surrender", "Made a decision to turn our will and our lives over to the care of God.", "Proverbs 3:5-6", []),
        ("Moral Inventory", "Made a searching and fearless moral inventory of ourselves.", "Lamentations 3:40", []),
        ("Confession", "Admitted to God, to ourselves, and to another human being the exact nature of our wrongs.", "James 5:16", []),
        ("Readiness", "Were entirely ready to have God remove all these defects of character.", "James 4:10", []),
        ("Humility", "Humbly asked Him to remove our shortcomings.", "1 John 1:9", []),
        ("Amends List", "Made a list of all persons we had harmed, and became willing to make amends to them all.", "Matthew 5:23-24", [
            "Who have I harmed through my addiction? List every person.",
            "What specific harm did I cause each person?",
            "Am I willing to make amends to each of these people?",
            "Which amends might cause further harm if made directly?",
            "What fears do I have about making amends?",
            "How has my addiction affected my spouse/partner?",
            "How has my addiction affected my children or family?",
            "How has my addiction affected my work relationships?",
            "What amends do I need to make to myself?",
            "What does willingness to make amends look like in my daily life?"
        ]),
        ("Making Amends", "Made direct amends to such people wherever possible, except when to do so would injure them or others.", "Romans 12:18", []),
        ("Continued Inventory", "Continued to take personal inventory and when we were wrong promptly admitted it.", "1 Corinthians 10:12", []),
        ("Prayer & Meditation", "Sought through prayer and meditation to improve our conscious contact with God, praying only for knowledge of His will for us and the power to carry that out.", "Psalm 46:10", []),
        ("Service", "Having had a spiritual awakening as the result of these steps, we tried to carry this message to sexaholics, and to practice these principles in all our affairs.", "Galatians 6:1", []),
    ]

    private func statusForStep(_ step: RRStepWork) -> StepStatus {
        switch step.status {
        case "complete": return .complete
        case "inProgress": return .inProgress
        default: return .locked
        }
    }

    private func answeredCount(_ step: RRStepWork) -> Int {
        if case .int(let count) = step.answers.data["answeredCount"] {
            return count
        }
        return 0
    }

    private func meta(for stepNumber: Int) -> (String, String, String, [String]) {
        guard stepNumber >= 1 && stepNumber <= Self.stepMeta.count else {
            return ("Unknown", "", "", [])
        }
        return Self.stepMeta[stepNumber - 1]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(steps) { step in
                    let (title, description, _, _) = meta(for: step.stepNumber)
                    let status = statusForStep(step)
                    Button {
                        selectedStep = step
                    } label: {
                        HStack(spacing: 14) {
                            Text("\(step.stepNumber)")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(statusColor(status))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(title)
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                                Text(description)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            statusBadge(status)
                        }
                        .padding(14)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .sheet(item: $selectedStep) { step in
            stepDetailSheet(step)
        }
    }

    @ViewBuilder
    private func statusBadge(_ status: StepStatus) -> some View {
        switch status {
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.rrSuccess)
        case .inProgress:
            RRBadge(text: "In Progress", color: .orange)
        case .locked:
            Image(systemName: "lock.fill")
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    private func statusColor(_ status: StepStatus) -> Color {
        switch status {
        case .complete: return .rrSuccess
        case .inProgress: return .orange
        case .locked: return .rrTextSecondary
        }
    }

    private func stepDetailSheet(_ step: RRStepWork) -> some View {
        let (title, description, scripture, questions) = meta(for: step.stepNumber)
        let status = statusForStep(step)
        let answered = answeredCount(step)

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    RRCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Step \(step.stepNumber)")
                                    .font(RRFont.title)
                                    .foregroundStyle(Color.rrPrimary)
                                Spacer()
                                statusBadge(status)
                            }
                            Text(title)
                                .font(RRFont.title3)
                                .foregroundStyle(Color.rrText)
                            Text(description)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)

                            HStack(spacing: 6) {
                                Image(systemName: "book.fill")
                                    .foregroundStyle(Color.rrPrimary)
                                    .font(.caption)
                                Text(scripture)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Content based on status
                    switch status {
                    case .complete:
                        completeStepContent(answered: answered)
                    case .inProgress:
                        StepWorkQuestionsView(step: step, questions: questions, answeredCount: answered)
                    case .locked:
                        lockedStepContent(step)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.rrBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { selectedStep = nil }
                }
            }
        }
    }

    private func completeStepContent(answered: Int) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.rrSuccess)
                    Text("Completed")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrSuccess)
                }
                Text("All \(answered) reflection questions answered. This step is part of your foundation.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .padding(.horizontal)
    }

    private func lockedStepContent(_ step: RRStepWork) -> some View {
        RRCard {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title)
                    .foregroundStyle(Color.rrTextSecondary)
                Text("Complete Step \(step.stepNumber - 1) first")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrTextSecondary)
                Text("Steps are completed in order to build a strong recovery foundation.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal)
    }
}

// MARK: - Step Work Questions View

private struct StepWorkQuestionsView: View {
    let step: RRStepWork
    let questions: [String]
    let answeredCount: Int

    @State private var answers: [String] = []

    private let prefilledAnswers = [
        "Rachel \u{2014} my wife. My addiction caused deep betrayal trauma, broken trust, and emotional distance. I owe her honesty, amends, and consistent changed behavior.",
        "My children \u{2014} they experienced an emotionally unavailable father. I need to be present and engaged.",
        "James (my sponsor) \u{2014} I wasn't always honest with him early in recovery. I need to continue building trust through transparency.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reflection Questions")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(answeredCount) of \(questions.count)")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .padding(.horizontal)

            ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top) {
                            Text("\(index + 1).")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)
                            Text(question)
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                        }

                        if index < answers.count {
                            TextEditor(text: $answers[index])
                                .frame(minHeight: 80)
                                .font(RRFont.body)
                                .scrollContentBackground(.hidden)
                                .padding(6)
                                .background(Color.rrBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            var initial = prefilledAnswers
            while initial.count < questions.count {
                initial.append("")
            }
            answers = initial
        }
    }
}

#Preview {
    NavigationStack {
        StepWorkView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
