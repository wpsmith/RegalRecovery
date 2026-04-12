import SwiftUI

/// Sheet that lets the user add, remove, reorder, and edit commitment statements.
/// Used by both SobrietyCommitmentView and MorningCommitmentView.
struct EditCommitmentStatementsView: View {
    let title: String
    @Binding var statements: [String]
    let defaults: [String]
    let onSave: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var draft: [String]
    @FocusState private var focusedIndex: Int?

    private var missingRecommended: [String] {
        defaults.filter { rec in !draft.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines) == rec.trimmingCharacters(in: .whitespacesAndNewlines) }) }
    }

    init(
        title: String,
        statements: Binding<[String]>,
        defaults: [String],
        onSave: @escaping ([String]) -> Void
    ) {
        self.title = title
        self._statements = statements
        self.defaults = defaults
        self.onSave = onSave
        self._draft = State(initialValue: statements.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compassionate header
                Text("These are your commitments. Make them meaningful to you.")
                    .font(RRFont.footnote)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                List {
                    Section {
                        ForEach(Array(draft.enumerated()), id: \.offset) { index, _ in
                            HStack(alignment: .top, spacing: 8) {
                                TextField(
                                    "Enter your commitment...",
                                    text: $draft[index],
                                    axis: .vertical
                                )
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .lineLimit(2...4)
                                .focused($focusedIndex, equals: index)

                                if draft.count > 1 {
                                    Button {
                                        withAnimation {
                                            _ = draft.remove(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.body)
                                            .foregroundStyle(Color.rrDestructive)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .onMove { indices, destination in
                            draft.move(fromOffsets: indices, toOffset: destination)
                        }
                    }

                    if !missingRecommended.isEmpty {
                        Section {
                            Button {
                                withAnimation {
                                    draft.append(contentsOf: missingRecommended)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                    Text("Add \(missingRecommended.count) Recommended")
                                }
                                .font(RRFont.body)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rrSecondary)
                            }
                        }
                    }

                    Section {
                        Button {
                            withAnimation {
                                draft.append("")
                                focusedIndex = draft.count - 1
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Statement")
                            }
                            .font(RRFont.body)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrPrimary)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .environment(\.editMode, .constant(.active))
            }
            .background(Color.rrBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Filter out empty statements before saving
                        let cleaned = draft.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        let result = cleaned.isEmpty ? defaults : cleaned
                        statements = result
                        onSave(result)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rrPrimary)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
    }
}

#Preview {
    EditCommitmentStatementsView(
        title: "Edit Morning Commitments",
        statements: .constant(CommitmentStatementsManager.defaultMorningStatements),
        defaults: CommitmentStatementsManager.defaultMorningStatements,
        onSave: { _ in }
    )
}
