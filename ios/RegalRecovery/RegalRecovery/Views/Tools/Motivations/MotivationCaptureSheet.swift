import SwiftUI

struct MotivationCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var libraryViewModel: MotivationLibraryViewModel
    var onSaved: ((RRMotivation) -> Void)?

    @State private var text: String = ""
    @State private var selectedCategory: MotivationCategory = .personalGrowth
    @State private var importanceRating: Int = MotivationImportance.defaultRating
    @State private var scriptureReference: String = ""

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What motivates your recovery?", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .accessibilityLabel("Motivation text")
                    Text("\(text.count)/\(MotivationLimits.maxTextLength)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } header: {
                    Text("Your Motivation")
                }

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(MotivationCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Category")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ForEach(MotivationImportance.range, id: \.self) { value in
                                Button {
                                    importanceRating = value
                                } label: {
                                    Image(systemName: value <= importanceRating ? "flame.fill" : "flame")
                                        .font(.title2)
                                        .foregroundStyle(value <= importanceRating ? Color.orange : Color.rrTextSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(MotivationImportance.label(for: value))")
                                .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                        Text(MotivationImportance.label(for: importanceRating))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                } header: {
                    Text("Importance")
                }

                Section {
                    TextField("e.g. Romans 8:28", text: $scriptureReference)
                        .accessibilityLabel("Scripture reference")
                } header: {
                    Text("Scripture (Optional)")
                }
            }
            .navigationTitle("Add Motivation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        let scripture = scriptureReference.trimmingCharacters(in: .whitespacesAndNewlines)

        let motivation = RRMotivation(
            userId: UUID(),
            text: String(trimmedText.prefix(MotivationLimits.maxTextLength)),
            category: selectedCategory,
            importanceRating: importanceRating,
            scriptureReference: scripture.isEmpty ? nil : scripture,
            source: .manual
        )

        let history = RRMotivationHistory(
            motivationId: motivation.id,
            changeType: .created,
            newValue: motivation.text
        )

        modelContext.insert(motivation)
        modelContext.insert(history)

        do {
            try modelContext.save()
        } catch {
            print("[Motivations] Save failed: \(error)")
        }

        onSaved?(motivation)
        dismiss()
    }
}

#Preview {
    MotivationCaptureSheet(libraryViewModel: MotivationLibraryViewModel())
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
