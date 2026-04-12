import SwiftUI
import SwiftData

struct CommitmentSetupView: View {
    let onComplete: () -> Void

    @Query(sort: \RRAddiction.sortOrder) private var addictions: [RRAddiction]
    @Query(filter: #Predicate<RRDailyPlanItem> { $0.isEnabled == true })
    private var planItems: [RRDailyPlanItem]

    @State private var selectedStatements: [SelectableStatement] = []
    @State private var customText = ""
    @FocusState private var customFocused: Bool

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
            VStack(spacing: 24) {
                // MARK: - Welcome Header
                VStack(spacing: 8) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.rrPrimary)

                    Text("Set Up Your Morning Commitment")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("These statements will greet you each morning. Check off the ones that resonate with you, or add your own.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                .padding(.horizontal)

                // MARK: - Recommended Statements
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended Statements")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        ForEach($selectedStatements) { $item in
                            Button {
                                item.isSelected.toggle()
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isSelected ? Color.rrSuccess : Color.rrTextSecondary)
                                        .font(.title3)

                                    Text(item.text)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)

                // MARK: - Add Custom Statement
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add Your Own")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        HStack(spacing: 8) {
                            TextField("Write a personal commitment...", text: $customText, axis: .vertical)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .lineLimit(2...4)
                                .focused($customFocused)

                            Button {
                                addCustomStatement()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            .disabled(customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding(.horizontal)

                // MARK: - Save Button
                RRButton("Save Commitments", icon: "checkmark.circle") {
                    saveAndComplete()
                }
                .padding(.horizontal)
                .disabled(selectedStatements.filter(\.isSelected).isEmpty)
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .navigationTitle("Setup")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDefaults()
        }
    }

    // MARK: - Helpers

    private func loadDefaults() {
        guard selectedStatements.isEmpty else { return }
        let defaults = CommitmentStatementsManager.dynamicMorningDefaults(
            addictions: addictionNames,
            hasMeetingToday: hasMeetingToday
        )
        selectedStatements = defaults.map {
            SelectableStatement(text: $0, isSelected: true, isCustom: false)
        }
    }

    private func addCustomStatement() {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            selectedStatements.append(
                SelectableStatement(text: trimmed, isSelected: true, isCustom: true)
            )
            customText = ""
            customFocused = false
        }
    }

    private func saveAndComplete() {
        let chosen = selectedStatements
            .filter(\.isSelected)
            .map(\.text)
        CommitmentStatementsManager.shared.morningStatements = chosen
        onComplete()
    }
}

// MARK: - Supporting Types

private struct SelectableStatement: Identifiable {
    let id = UUID()
    var text: String
    var isSelected: Bool
    var isCustom: Bool
}

#Preview {
    NavigationStack {
        CommitmentSetupView {
            print("Setup complete")
        }
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
