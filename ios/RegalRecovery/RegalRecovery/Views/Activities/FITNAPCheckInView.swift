import SwiftUI
import SwiftData

struct FITNAPCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var showSummary = false

    // FITNAP fields
    @State private var fitnapFeelings = ""
    @State private var fitnapIntegrity = ""
    @State private var fitnapTriggers = ""
    @State private var fitnapNeeds = ""
    @State private var fitnapAmends = ""
    @State private var fitnapPositives = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                fitnapView

                RRButton("Review Summary", icon: "doc.text.magnifyingglass") {
                    showSummary = true
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .navigationTitle("FITNAP Check-in")
        .sheet(isPresented: $showSummary) {
            summarySheet
        }
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

    // MARK: - Summary Sheet

    private var summarySheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    summaryRow("Feelings", value: fitnapFeelings)
                    summaryRow("Integrity / Sobriety", value: fitnapIntegrity)
                    summaryRow("Triggers", value: fitnapTriggers)
                    summaryRow("Needs", value: fitnapNeeds)
                    summaryRow("Amends", value: fitnapAmends)
                    summaryRow("Positives", value: fitnapPositives)

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
        var sections: [String: AnyCodableValue] = [:]
        sections["feelings"] = .string(fitnapFeelings)
        sections["integrity"] = .string(fitnapIntegrity)
        sections["triggers"] = .string(fitnapTriggers)
        sections["needs"] = .string(fitnapNeeds)
        sections["amends"] = .string(fitnapAmends)
        sections["positives"] = .string(fitnapPositives)
        let entry = RRSpouseCheckIn(
            userId: userId,
            date: Date(),
            framework: "FITNAP",
            sections: JSONPayload(sections)
        )
        modelContext.insert(entry)
    }
}

#Preview {
    NavigationStack {
        FITNAPCheckInView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
