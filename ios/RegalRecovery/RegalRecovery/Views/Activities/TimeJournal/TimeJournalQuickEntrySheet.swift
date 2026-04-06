import SwiftUI
import SwiftData

struct TimeJournalQuickEntrySheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @Bindable var viewModel: TimeJournalEntryViewModel
    var onSave: ((RRTimeJournalEntry) -> Void)?

    // MARK: - Integrity Prompt State

    @State private var integrityPrompt: String?
    @State private var showIntegrityBanner: Bool = false
    @State private var showConfirmationAlert: Bool = false
    @State private var confirmationShownThisSession: Bool = false
    @State private var showRedlineTooltip: Bool = false

    private static let integrityPrompts: [String] = [
        "Is there anything you're tempted to leave out?",
        "Take a breath. Is this the whole picture?",
        "Recovery lives in the details we'd rather skip.",
        "Honesty with yourself is the first step.",
        "What would your accountability partner want to know?",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if showIntegrityBanner, let prompt = integrityPrompt {
                        integrityBannerView(prompt: prompt)
                    }

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
                        handleSaveTapped()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel.isValid ? Color.rrPrimary : Color.rrTextSecondary)
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .alert("Before you save", isPresented: $showConfirmationAlert) {
                Button("Save As-Is") {
                    saveEntry()
                }
                Button("Edit More", role: .cancel) { }
            } message: {
                Text("Are you satisfied this entry reflects the whole truth?")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            rollIntegrityPrompt()
        }
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
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.rrDestructive.opacity(0.7))
                    Text("Private note (not shared)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrDestructive.opacity(0.8))
                    Button {
                        showRedlineTooltip.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showRedlineTooltip) {
                        Text("This note stays on your device only. It is never shared with Trust Partners.")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrText)
                            .padding()
                            .presentationCompactAdaptation(.popover)
                    }
                }
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

    // MARK: - Integrity Banner

    private func integrityBannerView(prompt: String) -> some View {
        HStack {
            Image(systemName: "heart.text.square")
                .foregroundStyle(Color.rrPrimary.opacity(0.7))
            Text(prompt)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrText.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    showIntegrityBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.rrPrimary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Integrity Helpers

    private func rollIntegrityPrompt() {
        // 30% chance to show an integrity prompt on open
        if Double.random(in: 0..<1) < 0.3 {
            integrityPrompt = Self.integrityPrompts.randomElement()
            showIntegrityBanner = true
        }
    }

    private func handleSaveTapped() {
        // 50% chance to show confirmation, but only once per session
        if !confirmationShownThisSession && Double.random(in: 0..<1) < 0.5 {
            confirmationShownThisSession = true
            showConfirmationAlert = true
        } else {
            saveEntry()
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
