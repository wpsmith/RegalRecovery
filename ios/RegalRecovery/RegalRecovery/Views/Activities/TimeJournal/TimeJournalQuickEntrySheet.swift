import SwiftUI
import SwiftData

struct TimeJournalQuickEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @Bindable var viewModel: TimeJournalEntryViewModel
    var onSave: ((RRTimeJournalEntry) -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    LocationField(locationLabel: $viewModel.locationLabel)
                    ActivityField(activity: $viewModel.activity)
                    EmotionPicker(selectedEmotions: $viewModel.selectedEmotions)

                    expandedSection
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.isValid ? Color.rrPrimary : Color.rrTextSecondary)
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.slotTimeLabel)
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)
                Text(viewModel.date, style: .date)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            Spacer()
            if viewModel.isRetroactive {
                RRBadge(text: "Retroactive", color: .rrSecondary)
            }
            if viewModel.isEditing {
                RRBadge(text: "Editing", color: .rrPrimary)
            }
        }
    }

    // MARK: - Expanded Section

    private var expandedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            // People field with contextual prompt
            VStack(alignment: .leading, spacing: 4) {
                if viewModel.shouldPromptForPeople {
                    Text("Who was there?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrPrimary)
                        .fontWeight(.medium)
                }
                PeopleField(people: $viewModel.people)
            }

            // Sleep toggle
            Toggle(isOn: $viewModel.isSleep) {
                Label("Sleep", systemImage: "moon.zzz.fill")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
            }
            .tint(.rrPrimary)

            // Redline note
            VStack(alignment: .leading, spacing: 4) {
                Text("Private note (not shared)")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrDestructive.opacity(0.8))
                TextField("Add a private note...", text: $viewModel.redlineNote, axis: .vertical)
                    .font(RRFont.body)
                    .lineLimit(2...4)
                    .padding(8)
                    .background(Color.rrDestructive.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.rrDestructive.opacity(0.2), lineWidth: 1)
                    )
            }

            // Flag toggle
            Toggle(isOn: $viewModel.isFlagged) {
                Label("Flag this entry", systemImage: "flag.fill")
                    .font(RRFont.body)
                    .foregroundStyle(viewModel.isFlagged ? Color.rrDestructive : Color.rrText)
            }
            .tint(.rrDestructive)
        }
    }

    // MARK: - Save

    private func saveEntry() {
        let userId = users.first?.id ?? UUID()
        let entry = viewModel.save(modelContext: modelContext, userId: userId)
        onSave?(entry)
        dismiss()
    }
}

#Preview {
    let vm = TimeJournalEntryViewModel(slotIndex: 14, mode: .t60, date: Date())
    TimeJournalQuickEntrySheet(viewModel: vm)
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
