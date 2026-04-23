import SwiftUI

struct MotivationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let motivation: RRMotivation
    var libraryViewModel: MotivationLibraryViewModel

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    @State private var editText: String = ""
    @State private var editCategory: MotivationCategory = .personalGrowth
    @State private var editImportance: Int = 3
    @State private var editScripture: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                categoryHeader
                motivationTextSection
                if let scripture = motivation.scriptureReference, !scripture.isEmpty {
                    scriptureSection(scripture)
                }
                importanceSection
                metadataSection
                actionButtons
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle("Motivation")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            editSheet
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteMotivation() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This motivation and its history will be permanently removed. If you are reconsidering this motivation rather than removing it, consider lowering its importance instead.")
        }
    }

    private var categoryHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: motivation.motivationCategory.icon)
                .font(.title2)
                .foregroundStyle(motivation.motivationCategory.color)
            Text(motivation.motivationCategory.displayName)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
        }
    }

    private var motivationTextSection: some View {
        RRCard {
            Text(motivation.text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func scriptureSection(_ scripture: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "book.fill")
                .foregroundStyle(Color.rrPrimary)
            Text(scripture)
                .font(RRFont.body)
                .italic()
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    private var importanceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Importance")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { value in
                    Image(systemName: value <= motivation.importanceRating ? "flame.fill" : "flame")
                        .foregroundStyle(value <= motivation.importanceRating ? Color.orange : Color.rrTextSecondary)
                }
                Text(motivation.importanceLabel)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.leading, 4)
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Added \(motivation.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            if motivation.modifiedAt > motivation.createdAt {
                Text("Last updated \(motivation.modifiedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                editText = motivation.text
                editCategory = motivation.motivationCategory
                editImportance = motivation.importanceRating
                editScripture = motivation.scriptureReference ?? ""
                isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.rrPrimary)
            .frame(minHeight: 44)

            Button {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.rrDestructive)
            .frame(minHeight: 44)
        }
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("Motivation") {
                    TextField("Motivation text", text: $editText, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section("Category") {
                    Picker("Category", selection: $editCategory) {
                        ForEach(MotivationCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                Section("Importance") {
                    HStack {
                        ForEach(1...5, id: \.self) { value in
                            Button { editImportance = value } label: {
                                Image(systemName: value <= editImportance ? "flame.fill" : "flame")
                                    .font(.title2)
                                    .foregroundStyle(value <= editImportance ? .orange : .rrTextSecondary)
                            }
                            .buttonStyle(.plain)
                            .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                }
                Section("Scripture (Optional)") {
                    TextField("e.g. Romans 8:28", text: $editScripture)
                }
            }
            .navigationTitle("Edit Motivation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdit() }
                        .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveEdit() {
        let previousText = motivation.text
        let previousCategory = motivation.category
        let previousImportance = motivation.importanceRating
        let previousScripture = motivation.scriptureReference

        let trimmedText = String(editText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(MotivationLimits.maxTextLength))
        let trimmedScripture = editScripture.trimmingCharacters(in: .whitespacesAndNewlines)

        motivation.text = trimmedText
        motivation.category = editCategory.rawValue
        motivation.importanceRating = editImportance
        motivation.scriptureReference = trimmedScripture.isEmpty ? nil : trimmedScripture
        motivation.modifiedAt = Date()
        try? modelContext.save()

        if previousText != trimmedText {
            recordChange(.textEdited, previousValue: previousText, newValue: trimmedText)
        }
        if previousCategory != editCategory.rawValue {
            recordChange(.categoryChanged, previousValue: previousCategory, newValue: editCategory.rawValue)
        }
        if previousImportance != editImportance {
            recordChange(.importanceChanged, previousValue: "\(previousImportance)", newValue: "\(editImportance)")
        }
        if previousScripture != (trimmedScripture.isEmpty ? nil : trimmedScripture) {
            recordChange(.scriptureChanged, previousValue: previousScripture, newValue: trimmedScripture.isEmpty ? nil : trimmedScripture)
        }

        isEditing = false
    }

    private func recordChange(_ type: MotivationChangeType, previousValue: String?, newValue: String?) {
        let history = RRMotivationHistory(
            motivationId: motivation.id,
            changeType: type,
            previousValue: previousValue,
            newValue: newValue
        )
        modelContext.insert(history)
        try? modelContext.save()
    }

    private func deleteMotivation() {
        libraryViewModel.deleteMotivation(id: motivation.id)
        libraryViewModel.persistDelete(id: motivation.id, context: modelContext)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MotivationDetailView(
            motivation: RRMotivation(
                userId: UUID(),
                text: "My daughter deserves a father who keeps his promises.",
                category: .relational,
                importanceRating: 5,
                scriptureReference: "Proverbs 22:6"
            ),
            libraryViewModel: MotivationLibraryViewModel()
        )
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
