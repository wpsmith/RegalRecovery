import SwiftUI
import SwiftData

struct ActingInCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var viewModel = ActingInCheckInViewModel()

    private var userId: UUID {
        users.first?.id ?? UUID()
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // First-use onboarding
                    if viewModel.isFirstUse {
                        firstUseCard
                    }

                    // Behavior checklist
                    behaviorChecklistCard

                    // Submit button
                    submitButton

                    // Save confirmation
                    if viewModel.showSaveAnimation, let message = viewModel.savedMessage {
                        saveConfirmation(message: message)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.rrBackground)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSaveAnimation)
        .onAppear {
            viewModel.loadBehaviors(context: modelContext, userId: userId)
        }
    }

    // MARK: - First Use Card

    private var firstUseCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(Color.rrPrimary)
                    Text("Acting-In Behaviors")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }

                Text(ActingInMessages.firstUseHelper)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Behavior Checklist Card

    private var behaviorChecklistCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(title: "Check-In")

                Text("Which behaviors occurred since your last check-in?")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                VStack(spacing: 0) {
                    ForEach(Array(viewModel.behaviorDrafts.enumerated()), id: \.element.id) { index, draft in
                        behaviorRow(index: index, draft: draft)

                        if index < viewModel.behaviorDrafts.count - 1 {
                            Divider()
                                .padding(.leading, 44)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Behavior Row

    private func behaviorRow(index: Int, draft: ActingInBehaviorDraft) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Checkbox row
            Button {
                viewModel.toggleBehavior(draft.behaviorId)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: draft.isChecked ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(draft.isChecked ? Color.rrPrimary : Color.rrTextSecondary)

                    Text(draft.behaviorName)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)

            // Expanded details when checked
            if draft.isChecked {
                VStack(alignment: .leading, spacing: 12) {
                    // Context note
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("What happened?", text: contextNoteBinding(for: index), axis: .vertical)
                            .font(RRFont.body)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                            .onChange(of: viewModel.behaviorDrafts[safe: index]?.contextNote ?? "") { _, _ in
                                viewModel.enforceContextNoteLimit(for: draft.behaviorId)
                            }

                        let note = viewModel.behaviorDrafts[safe: index]?.contextNote ?? ""
                        if viewModel.shouldShowCounter(note) {
                            HStack {
                                Spacer()
                                Text("\(note.count)/\(ActingInCheckInViewModel.maxContextNoteLength)")
                                    .font(RRFont.caption2)
                                    .foregroundStyle(
                                        viewModel.isAtCharacterLimit(note) ? Color.rrDestructive : Color.rrTextSecondary
                                    )
                            }
                        }
                    }

                    // Trigger chips
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What prompted this?")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        triggerChips(for: index)
                    }

                    // Relationship tag chips
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Who was affected?")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)

                        relationshipChips(for: index)
                    }
                }
                .padding(.leading, 44)
                .padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: draft.isChecked)
    }

    // MARK: - Trigger Chips

    private func triggerChips(for index: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ActingInTrigger.allCases) { trigger in
                    let isSelected = viewModel.behaviorDrafts[safe: index]?.trigger == trigger
                    Button {
                        if isSelected {
                            viewModel.behaviorDrafts[index].trigger = nil
                        } else {
                            viewModel.behaviorDrafts[index].trigger = trigger
                        }
                    } label: {
                        Text(trigger.displayName)
                            .font(RRFont.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(isSelected ? .white : Color.rrPrimary)
                            .background(isSelected ? Color.rrPrimary : Color.rrPrimary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Relationship Chips

    private func relationshipChips(for index: Int) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ActingInRelationshipTag.allCases) { tag in
                    let isSelected = viewModel.behaviorDrafts[safe: index]?.relationshipTag == tag
                    Button {
                        if isSelected {
                            viewModel.behaviorDrafts[index].relationshipTag = nil
                        } else {
                            viewModel.behaviorDrafts[index].relationshipTag = tag
                        }
                    } label: {
                        Text(tag.displayName)
                            .font(RRFont.caption2)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .foregroundStyle(isSelected ? .white : Color.rrSecondary)
                            .background(isSelected ? Color.rrSecondary : Color.rrSecondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        RRButton(viewModel.checkedCount == 0 ? "Submit (No Behaviors)" : "Submit Check-In", icon: "checkmark.shield.fill") {
            viewModel.submit(context: modelContext, userId: userId)
        }
        .padding(.horizontal)
    }

    // MARK: - Save Confirmation

    private func saveConfirmation(message: String) -> some View {
        RRCard {
            VStack(spacing: 12) {
                Image(systemName: viewModel.checkedCount == 0 ? "star.fill" : "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(viewModel.checkedCount == 0 ? Color.rrWarning : Color.rrSuccess)
                    .symbolEffect(.bounce, value: viewModel.showSaveAnimation)

                Text(viewModel.checkedCount == 0 ? "Growth" : "Recorded")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Text(message)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                if viewModel.streakCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color.rrPrimary)
                        Text("\(viewModel.streakCount) consecutive check-ins")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func contextNoteBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { viewModel.behaviorDrafts[safe: index]?.contextNote ?? "" },
            set: { newValue in
                guard viewModel.behaviorDrafts.indices.contains(index) else { return }
                viewModel.behaviorDrafts[index].contextNote = newValue
            }
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ActingInCheckInView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
