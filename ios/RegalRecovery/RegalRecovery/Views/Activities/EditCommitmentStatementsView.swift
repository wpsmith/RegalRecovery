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
    @State private var showResetConfirmation = false
    @FocusState private var focusedIndex: Int?

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

                    Section {
                        Button {
                            showResetConfirmation = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset to Defaults")
                            }
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
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
            .confirmationDialog(
                "Reset to Defaults",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    withAnimation {
                        draft = defaults
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will replace all your current statements with the original defaults.")
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
