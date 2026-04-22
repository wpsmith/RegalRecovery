import SwiftUI
import SwiftData

struct GratitudeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var entries: [RRGratitudeEntry]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var viewModel = GratitudeEntryViewModel()
    @FocusState private var focusedItemId: UUID?

    private var userId: UUID {
        users.first?.id ?? UUID()
    }

    private var isFirstUse: Bool {
        entries.isEmpty
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // First-use onboarding
                    if isFirstUse {
                        firstUseCard
                    }

                    // Daily prompt card
                    if !viewModel.dailyPromptDismissed, let prompt = viewModel.dailyPrompt {
                        dailyPromptCard(prompt: prompt)
                    }

                    // Entry card
                    entryCard

                    // Mood selector
                    moodCard

                    // Prompt link
                    promptLink

                    // Save button
                    saveButton

                    // Save confirmation
                    if viewModel.showSaveAnimation, let message = viewModel.savedMessage {
                        saveConfirmation(message: message)
                    }

                    // History
                    if !entries.isEmpty {
                        historyCard
                    }
                }
                .padding(.vertical)
            }
            .background(Color.rrBackground)

            // Prompt overlay
            if viewModel.showPrompt {
                promptOverlay
            }
        }
        .onAppear { viewModel.loadDailyPrompt(userId: userId) }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showSaveAnimation)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showPrompt)
    }

    // MARK: - First Use Card

    private var firstUseCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.rrPrimary)
                    Text("Welcome to Gratitude")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }

                Text(GratitudeEntryViewModel.firstUseMessage)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Entry Card

    private var entryCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(title: "Today\u{2019}s Gratitude")

                VStack(spacing: 12) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        gratitudeItemRow(index: index, item: item)
                    }
                }

                // Add another button
                Button {
                    viewModel.addItem()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add another")
                            .font(RRFont.callout)
                    }
                    .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Gratitude Item Row

    private func gratitudeItemRow(index: Int, item: GratitudeItemDraft) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(index + 1).")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrPrimary)
                    .frame(width: 24)

                TextField("I\u{2019}m grateful for...", text: binding(for: index), axis: .vertical)
                    .font(RRFont.body)
                    .textFieldStyle(.roundedBorder)
                    .focused($focusedItemId, equals: item.id)
                    .onChange(of: viewModel.items[safe: index]?.text ?? "") { _, newValue in
                        if newValue.count > GratitudeEntryViewModel.maxCharacters {
                            viewModel.items[index].text = String(newValue.prefix(GratitudeEntryViewModel.maxCharacters))
                        }
                    }
                    .onSubmit {
                        viewModel.addItem()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedItemId = viewModel.items.last?.id
                        }
                    }

                if viewModel.items.count > 1 {
                    Button {
                        viewModel.removeItem(at: index)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.rrTextSecondary)
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Character counter
            let text = viewModel.items[safe: index]?.text ?? ""
            if viewModel.shouldShowCounter(text) {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(GratitudeEntryViewModel.maxCharacters)")
                        .font(RRFont.caption2)
                        .foregroundStyle(
                            viewModel.isAtCharacterLimit(text) ? Color.rrDestructive : Color.rrTextSecondary
                        )
                }
                .padding(.leading, 34)
            }

            // Category pills
            categoryPills(for: index)
        }
    }

    // MARK: - Category Pills

    private func categoryPills(for index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(GratitudeCategory.allCases) { category in
                        let isSelected = viewModel.items[safe: index]?.category == category
                        Button {
                            if isSelected {
                                viewModel.items[index].category = nil
                            } else {
                                viewModel.items[index].category = category
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: category.icon)
                                    .font(.caption2)
                                Text(category.rawValue)
                                    .font(RRFont.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .foregroundStyle(isSelected ? .white : category.color)
                            .background(isSelected ? category.color : category.color.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if viewModel.items[safe: index]?.category == .custom {
                TextField("Tag name (e.g., Pets, Music)", text: customTagNameBinding(for: index))
                    .font(RRFont.caption)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
            }
        }
        .padding(.leading, 34)
    }

    // MARK: - Mood Card

    private var moodCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                RRSectionHeader(title: "How are you feeling?")

                Text("Optional \u{2014} capture your mood during this practice")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { score in
                        let isSelected = viewModel.moodScore == score

                        Button {
                            viewModel.toggleMood(score)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: MoodIcon.symbolName(for: score))
                                    .font(.system(size: isSelected ? 28 : 22))
                                    .foregroundStyle(isSelected ? MoodIcon.color(for: score) : Color.rrTextSecondary)
                                Text(MoodIcon.label(for: score))
                                    .font(RRFont.caption2)
                                    .foregroundStyle(isSelected ? Color.rrPrimary : Color.rrTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                    ? Color.rrPrimary.opacity(0.1)
                                    : Color.clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Prompt Link

    private var promptLink: some View {
        Button {
            viewModel.requestPrompt(userId: userId)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                Text("Need a prompt?")
                    .font(RRFont.callout)
            }
            .foregroundStyle(Color.rrPrimary)
        }
    }

    // MARK: - Prompt Overlay

    private var promptOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissPrompt()
                }

            if let prompt = viewModel.currentPrompt {
                RRCard {
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title2)
                            .foregroundStyle(Color.rrPrimary)

                        Text(prompt.text)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        RRBadge(text: prompt.category, color: .rrPrimary)

                        VStack(spacing: 10) {
                            RRButton("Use this", icon: "checkmark") {
                                viewModel.usePrompt()
                            }

                            Button {
                                viewModel.nextPrompt()
                            } label: {
                                Text("Different prompt")
                                    .font(RRFont.callout)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.rrPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                            }

                            Button {
                                viewModel.dismissPrompt()
                            } label: {
                                Text("Dismiss")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 32)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        RRButton("Save Gratitude", icon: "leaf.fill") {
            viewModel.save(context: modelContext, userId: userId)
        }
        .opacity(viewModel.canSave ? 1.0 : 0.5)
        .disabled(!viewModel.canSave)
        .padding(.horizontal)
    }

    // MARK: - Save Confirmation

    private func saveConfirmation(message: String) -> some View {
        RRCard {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.rrSuccess)
                    .symbolEffect(.bounce, value: viewModel.showSaveAnimation)

                Text("Saved")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Text(message)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - History Card

    private var historyCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(title: "History")

                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(relativeDay(entry.date))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Spacer()
                            if let mood = entry.moodScore {
                                Image(systemName: MoodIcon.symbolName(for: mood))
                                    .font(.caption)
                                    .foregroundStyle(MoodIcon.color(for: mood))
                            }
                        }

                        ForEach(entry.items, id: \.id) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "leaf.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.rrSuccess)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.text)
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrText)
                                    if let category = item.category {
                                        HStack(spacing: 4) {
                                            Image(systemName: category.icon)
                                                .font(.caption2)
                                            Text(item.displayCategoryName ?? category.rawValue)
                                                .font(RRFont.caption2)
                                        }
                                        .foregroundStyle(category.color)
                                    }
                                }
                            }
                        }
                    }
                    Divider()
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Daily Prompt Card

    private func dailyPromptCard(prompt: GratitudePrompt) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)

                    Text("Today\u{2019}s Prompt")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Spacer()

                    Button {
                        withAnimation { viewModel.dismissDailyPrompt() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    .buttonStyle(.plain)
                }

                Text(prompt.text)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .fixedSize(horizontal: false, vertical: true)

                RRBadge(text: prompt.category, color: .rrPrimary)

                Button {
                    withAnimation { viewModel.useDailyPrompt() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.caption)
                        Text("Use this prompt")
                            .font(RRFont.callout)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Helpers

    private func customTagNameBinding(for index: Int) -> Binding<String> {
        Binding(
            get: { viewModel.items[safe: index]?.customTagName ?? "" },
            set: { newValue in
                guard viewModel.items.indices.contains(index) else { return }
                viewModel.items[index].customTagName = newValue
            }
        )
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { viewModel.items[safe: index]?.text ?? "" },
            set: { newValue in
                guard viewModel.items.indices.contains(index) else { return }
                viewModel.items[index].text = newValue
            }
        )
    }

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

}

// MARK: - Preview

#Preview {
    NavigationStack {
        GratitudeListView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
