import SwiftUI
import SwiftData

struct SpouseCheckInPrepView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var selectedFormat = 0
    @State private var showSummary = false

    // FANOS fields
    @State private var fanosFeeling = ""
    @State private var fanosSelectedEmotion: PrimaryEmotion?
    @State private var fanosAppreciation = ""
    @State private var fanosSelectedNeeds: Set<String> = []
    @State private var fanosOwnership = ""
    @State private var fanosSobriety = ""

    // FANOS expand states
    @State private var fanosExpandedSection: Int?

    // FITNAP fields
    @State private var fitnapFeelings = ""
    @State private var fitnapIntegrity = ""
    @State private var fitnapTriggers = ""
    @State private var fitnapNeeds = ""
    @State private var fitnapAmends = ""
    @State private var fitnapPositives = ""

    private let needs = [
        "Acceptance", "Affirmation", "Agency", "Belonging", "Comfort",
        "Compassion", "Connection", "Empathy", "Encouragement", "Forgiveness",
        "Grace", "Hope", "Love", "Peace", "Reassurance",
        "Respect", "Safety", "Security", "Understanding", "Validation"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Format", selection: $selectedFormat) {
                    Text("FANOS").tag(0)
                    Text("FITNAP").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if selectedFormat == 0 {
                    fanosView
                } else {
                    fitnapView
                }

                RRButton("Review Summary", icon: "doc.text.magnifyingglass") {
                    showSummary = true
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .sheet(isPresented: $showSummary) {
            summarySheet
        }
    }

    // MARK: - FANOS

    private var fanosView: some View {
        VStack(spacing: 12) {
            // Feelings
            expandableCard(
                index: 0,
                letter: "F",
                title: "Feelings",
                color: .purple
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What emotions are you experiencing?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                        ForEach(PrimaryEmotion.allCases, id: \.rawValue) { emotion in
                            Button {
                                fanosSelectedEmotion = emotion
                            } label: {
                                Text(emotion.rawValue)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(fanosSelectedEmotion == emotion ? .white : emotion.color)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(fanosSelectedEmotion == emotion ? emotion.color : emotion.color.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }

                    TextEditor(text: $fanosFeeling)
                        .frame(minHeight: 60)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            // Affirmations / Appreciation
            expandableCard(
                index: 1,
                letter: "A",
                title: "Appreciation",
                color: .yellow
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you appreciate about your spouse?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextEditor(text: $fanosAppreciation)
                        .frame(minHeight: 80)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            // Needs
            expandableCard(
                index: 2,
                letter: "N",
                title: "Needs",
                color: .blue
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you need from the relationship?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                        ForEach(needs, id: \.self) { need in
                            Button {
                                if fanosSelectedNeeds.contains(need) {
                                    fanosSelectedNeeds.remove(need)
                                } else {
                                    fanosSelectedNeeds.insert(need)
                                }
                            } label: {
                                Text(need)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(fanosSelectedNeeds.contains(need) ? .white : Color.rrText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(fanosSelectedNeeds.contains(need) ? Color.blue : Color.rrBackground)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Ownership
            expandableCard(
                index: 3,
                letter: "O",
                title: "Ownership",
                color: .orange
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What do you need to own or take responsibility for?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextEditor(text: $fanosOwnership)
                        .frame(minHeight: 80)
                        .font(RRFont.body)
                        .scrollContentBackground(.hidden)
                        .padding(6)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            // Sobriety
            expandableCard(
                index: 4,
                letter: "S",
                title: "Sobriety",
                color: .rrSuccess
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Share your sobriety status honestly and openly.")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextEditor(text: $fanosSobriety)
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

    // MARK: - FITNAP

    private var fitnapView: some View {
        VStack(spacing: 12) {
            fitnapSection(letter: "F", title: "Feelings", prompt: "Share your feelings. What early memory does this remind you of?", text: $fitnapFeelings, color: .purple)
            fitnapSection(letter: "I", title: "Integrity / Sobriety", prompt: "How is your sobriety? Any integrity issues to share?", text: $fitnapIntegrity, color: .rrSuccess)
            fitnapSection(letter: "T", title: "Triggers", prompt: "What has triggered you recently?", text: $fitnapTriggers, color: .orange)
            fitnapSection(letter: "N", title: "Needs", prompt: "What do you need from your spouse?", text: $fitnapNeeds, color: .blue)
            fitnapSection(letter: "A", title: "Amends", prompt: "Is there anything you need to make amends for?", text: $fitnapAmends, color: .rrDestructive)
            fitnapSection(letter: "P", title: "Positives", prompt: "What positives can you share?", text: $fitnapPositives, color: .yellow)
        }
        .padding(.horizontal)
    }

    private func fitnapSection(letter: String, title: String, prompt: String, text: Binding<String>, color: Color) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Text(letter)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(color)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text(title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }

                Text(prompt)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                TextEditor(text: text)
                    .frame(minHeight: 60)
                    .font(RRFont.body)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(Color.rrBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
    }

    // MARK: - Expandable Card

    private func expandableCard<Content: View>(
        index: Int,
        letter: String,
        title: String,
        color: Color,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation {
                        fanosExpandedSection = fanosExpandedSection == index ? nil : index
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(letter)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(color)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        Text(title)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                        Image(systemName: fanosExpandedSection == index ? "chevron.up" : "chevron.down")
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }

                if fanosExpandedSection == index {
                    Divider()
                        .padding(.vertical, 10)
                    content()
                }
            }
        }
    }

    // MARK: - Summary Sheet

    private var summarySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if selectedFormat == 0 {
                        summaryRow("Feelings", value: fanosSelectedEmotion?.rawValue ?? fanosFeeling)
                        summaryRow("Appreciation", value: fanosAppreciation)
                        summaryRow("Needs", value: fanosSelectedNeeds.joined(separator: ", "))
                        summaryRow("Ownership", value: fanosOwnership)
                        summaryRow("Sobriety", value: fanosSobriety)
                    } else {
                        summaryRow("Feelings", value: fitnapFeelings)
                        summaryRow("Integrity / Sobriety", value: fitnapIntegrity)
                        summaryRow("Triggers", value: fitnapTriggers)
                        summaryRow("Needs", value: fitnapNeeds)
                        summaryRow("Amends", value: fitnapAmends)
                        summaryRow("Positives", value: fitnapPositives)
                    }

                    RRButton("Save Check-in Prep", icon: "heart.fill") {
                        submitSpouseCheckIn()
                        showSummary = false
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showSummary = false }
                }
            }
        }
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            Text(value.isEmpty ? "Not filled in" : value)
                .font(RRFont.body)
                .foregroundStyle(value.isEmpty ? Color.rrTextSecondary : Color.rrText)
                .italic(value.isEmpty)
        }
    }

    private func submitSpouseCheckIn() {
        let userId = users.first?.id ?? UUID()
        let framework = selectedFormat == 0 ? "FANOS" : "FITNAP"
        var sections: [String: AnyCodableValue] = [:]
        if selectedFormat == 0 {
            sections["feelings"] = .string(fanosSelectedEmotion?.rawValue ?? fanosFeeling)
            sections["appreciation"] = .string(fanosAppreciation)
            sections["needs"] = .string(fanosSelectedNeeds.joined(separator: ", "))
            sections["ownership"] = .string(fanosOwnership)
            sections["sobriety"] = .string(fanosSobriety)
        } else {
            sections["feelings"] = .string(fitnapFeelings)
            sections["integrity"] = .string(fitnapIntegrity)
            sections["triggers"] = .string(fitnapTriggers)
            sections["needs"] = .string(fitnapNeeds)
            sections["amends"] = .string(fitnapAmends)
            sections["positives"] = .string(fitnapPositives)
        }
        let entry = RRSpouseCheckIn(
            userId: userId,
            date: Date(),
            framework: framework,
            sections: JSONPayload(sections)
        )
        modelContext.insert(entry)
    }
}

#Preview {
    NavigationStack {
        SpouseCheckInPrepView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
