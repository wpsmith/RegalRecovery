import SwiftUI
import SwiftData
import UIKit

// MARK: - Rich Text Editor (UIViewRepresentable)

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    var minHeight: CGFloat = 200

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor.label
        textView.typingAttributes = [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ]
        textView.attributedText = attributedText
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.attributedText != attributedText {
            let selectedRange = uiView.selectedRange
            uiView.attributedText = attributedText
            if selectedRange.location + selectedRange.length <= uiView.attributedText.length {
                uiView.selectedRange = selectedRange
            }
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }
    }
}

// MARK: - Formatting Toolbar

struct FormattingToolbar: View {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange

    var body: some View {
        HStack(spacing: 4) {
            formatButton("B", trait: .traitBold)
            formatButton("I", trait: .traitItalic)
            underlineButton()
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func formatButton(_ label: String, trait: UIFontDescriptor.SymbolicTraits) -> some View {
        Button {
            toggleTrait(trait)
        } label: {
            Text(label)
                .font(.system(size: 15, weight: trait == .traitBold ? .bold : .regular))
                .italic(trait == .traitItalic)
                .foregroundStyle(Color.rrText)
                .frame(width: 36, height: 32)
                .background(isTraitActive(trait) ? Color.rrPrimary.opacity(0.2) : Color.rrBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    @ViewBuilder
    private func underlineButton() -> some View {
        Button {
            toggleUnderline()
        } label: {
            Text("U")
                .font(.system(size: 15))
                .underline()
                .foregroundStyle(Color.rrText)
                .frame(width: 36, height: 32)
                .background(isUnderlineActive ? Color.rrPrimary.opacity(0.2) : Color.rrBackground)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }

    private func isTraitActive(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
        let range = validRange()
        guard range.length > 0 else { return false }
        var active = true
        attributedText.enumerateAttribute(.font, in: range, options: []) { value, _, _ in
            guard let font = value as? UIFont else { active = false; return }
            if !font.fontDescriptor.symbolicTraits.contains(trait) { active = false }
        }
        return active
    }

    private var isUnderlineActive: Bool {
        let range = validRange()
        guard range.length > 0 else { return false }
        var active = true
        attributedText.enumerateAttribute(.underlineStyle, in: range, options: []) { value, _, _ in
            guard let style = value as? Int, style != 0 else { active = false; return }
        }
        return active
    }

    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        let mutable = NSMutableAttributedString(attributedString: attributedText)
        let range = validRange()

        mutable.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            guard let currentFont = value as? UIFont else { return }
            let descriptor = currentFont.fontDescriptor
            let hasTrait = descriptor.symbolicTraits.contains(trait)
            if hasTrait {
                let newTraits = descriptor.symbolicTraits.subtracting(trait)
                if let newDescriptor = descriptor.withSymbolicTraits(newTraits) {
                    let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                    mutable.addAttribute(.font, value: newFont, range: subRange)
                }
            } else {
                let newTraits = descriptor.symbolicTraits.union(trait)
                if let newDescriptor = descriptor.withSymbolicTraits(newTraits) {
                    let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                    mutable.addAttribute(.font, value: newFont, range: subRange)
                }
            }
        }
        attributedText = mutable
    }

    private func toggleUnderline() {
        let mutable = NSMutableAttributedString(attributedString: attributedText)
        let range = validRange()
        var hasUnderline = false

        mutable.enumerateAttribute(.underlineStyle, in: range, options: []) { value, _, _ in
            if let style = value as? Int, style != 0 {
                hasUnderline = true
            }
        }

        let newValue = hasUnderline ? 0 : NSUnderlineStyle.single.rawValue
        mutable.addAttribute(.underlineStyle, value: newValue, range: range)
        attributedText = mutable
    }

    private func validRange() -> NSRange {
        let length = attributedText.length
        if selectedRange.location + selectedRange.length <= length, selectedRange.length > 0 {
            return selectedRange
        }
        return NSRange(location: 0, length: length)
    }
}

// MARK: - Journaling Info View

struct JournalingInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("What is Journaling?", systemImage: "book.fill")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)

                            Text("Journaling is the practice of writing down your thoughts, feelings, and experiences. In recovery, it serves as a powerful tool for self-reflection and emotional processing.")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }

                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Benefits for Recovery", systemImage: "heart.fill")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)

                            VStack(alignment: .leading, spacing: 10) {
                                benefitRow(icon: "brain.head.profile", text: "Increases self-awareness and helps identify triggers")
                                benefitRow(icon: "waveform.path.ecg", text: "Reduces stress and helps regulate emotions")
                                benefitRow(icon: "eye.fill", text: "Creates clarity around patterns and behaviors")
                                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Tracks your growth and progress over time")
                                benefitRow(icon: "shield.checkered", text: "Strengthens accountability and honesty")
                                benefitRow(icon: "hands.sparkles.fill", text: "Deepens your connection with God and others")
                            }
                        }
                    }

                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Tips", systemImage: "lightbulb.fill")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)

                            Text("Write honestly -- this is for your eyes only. There is no wrong way to journal. Even a few sentences can make a difference. If you are not sure what to write, try tapping \"Need a prompt?\" for inspiration.")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("About Journaling")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
    }

    @ViewBuilder
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.rrPrimary)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)
            Text(text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
        }
    }
}

// MARK: - Journal Mode

enum JournalMode: String, CaseIterable {
    case jotting = "jotting"
    case prompted = "prompted"
    case freeform = "freeform"

    var label: String {
        switch self {
        case .jotting: return "Quick Jot"
        case .prompted: return "Prompted"
        case .freeform: return "Freeform"
        }
    }

    var icon: String {
        switch self {
        case .jotting: return "bolt.fill"
        case .prompted: return "lightbulb.fill"
        case .freeform: return "pencil.line"
        }
    }
}

// MARK: - Journal View

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var entries: [RRJournalEntry]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var attributedText = NSAttributedString(
        string: "",
        attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ]
    )
    @State private var selectedRange = NSRange(location: 0, length: 0)
    @State private var showPrompt = false
    @State private var currentPrompt: PromptItem?
    @State private var selectedCategory: String? = nil
    @State private var showInfoSheet = false
    @State private var showSavedConfirmation = false
    @State private var entryToDelete: RRJournalEntry?
    @State private var showDeleteConfirmation = false
    @State private var mode: JournalMode = .prompted
    @State private var jotText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mode selector
                modeSelector

                // Prompt offering (prompted mode only)
                if mode == .prompted {
                    promptSection
                }

                // Editor or Jot section
                if mode == .jotting {
                    jotSection
                } else {
                    editorSection
                }

                // History
                historySection
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .navigationTitle("Journaling")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            JournalingInfoView()
        }
        .overlay(alignment: .bottom) {
            if showSavedConfirmation {
                savedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(JournalMode.allCases, id: \.self) { m in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { mode = m }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: m.icon)
                            .font(.caption2)
                        Text(m.label)
                            .font(RRFont.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(mode == m ? .white : Color.rrPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(mode == m ? Color.rrPrimary : Color.rrPrimary.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Prompt Section

    @ViewBuilder
    private var promptSection: some View {
        VStack(spacing: 12) {
            // Category pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    categoryPill(label: "Any", category: nil)
                    ForEach(ContentData.promptCategories, id: \.self) { category in
                        categoryPill(label: category.capitalized, category: category)
                    }
                }
                .padding(.horizontal)
            }

            if let prompt = currentPrompt {
                // Show the active prompt card
                RRCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.subheadline)
                            Text("Prompt")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                                .textCase(.uppercase)
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    currentPrompt = nil
                                    showPrompt = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .padding(6)
                                    .background(Color.rrBackground)
                                    .clipShape(Circle())
                            }
                        }

                        Text(prompt.text)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                            .italic()

                        // Category label and framework tags
                        HStack(spacing: 6) {
                            Text(prompt.category.capitalized)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                                .textCase(.uppercase)

                            ForEach(prompt.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.rrPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.rrPrimary.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentPrompt = ContentData.randomPrompt(category: selectedCategory)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.trianglehead.2.clockwise")
                                    .font(.caption)
                                Text("Different prompt")
                                    .font(RRFont.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Color.rrPrimary)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                // "Need a prompt?" pill
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        currentPrompt = ContentData.randomPrompt(category: selectedCategory)
                        showPrompt = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        Text("Need a prompt?")
                            .font(RRFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.rrPrimary.opacity(0.08))
                    .clipShape(Capsule())
                }
            }
        }
    }

    @ViewBuilder
    private func categoryPill(label: String, category: String?) -> some View {
        let isSelected = selectedCategory == category
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
                currentPrompt = ContentData.randomPrompt(category: category)
                showPrompt = true
            }
        } label: {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color.rrPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.rrPrimary : Color.rrPrimary.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    // MARK: - Editor Section

    @ViewBuilder
    private var editorSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                FormattingToolbar(
                    attributedText: $attributedText,
                    selectedRange: $selectedRange
                )

                RichTextEditor(attributedText: $attributedText, selectedRange: $selectedRange)
                    .frame(minHeight: mode == .freeform ? 300 : 200)
                    .background(Color.rrBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                RRButton("Save Entry", icon: "square.and.arrow.down") {
                    saveEntry()
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Jot Section

    @ViewBuilder
    private var jotSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                TextField("What's on your mind?", text: $jotText, axis: .vertical)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .lineLimit(3...8)
                    .padding(.vertical, 4)

                RRButton("Jot it down", icon: "bolt.fill") {
                    saveJot()
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - History Section

    @ViewBuilder
    private var historySection: some View {
        if !entries.isEmpty {
            RRCard {
                VStack(alignment: .leading, spacing: 16) {
                    RRSectionHeader(title: "Past Entries")

                    ForEach(entries.prefix(5)) { entry in
                        NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(relativeDay(entry.date))
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                    Text(entry.mode.capitalized)
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrPrimary.opacity(0.7))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.rrPrimary.opacity(0.08))
                                        .clipShape(Capsule())
                                    Spacer()
                                    if let prompt = entry.prompt {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.caption2)
                                            .foregroundStyle(.yellow.opacity(0.7))
                                            .help(prompt)
                                    }
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(Color.rrTextSecondary.opacity(0.5))
                                }
                                Text(entry.content)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                entryToDelete = entry
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        if entry.id != entries.prefix(5).last?.id {
                            Divider()
                        }
                    }

                    if entries.count > 5 {
                        NavigationLink(destination: JournalHistoryView()) {
                            HStack {
                                Text("See all \(entries.count) entries")
                                    .font(RRFont.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.rrPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrPrimary.opacity(0.5))
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirmation, presenting: entryToDelete) { entry in
                Button("Delete", role: .destructive) {
                    modelContext.delete(entry)
                }
            }
        }
    }

    // MARK: - Saved Toast

    private var savedToast: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Entry saved")
                .font(RRFont.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.rrText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        }
        if cal.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 {
            return "\(days) days ago"
        }
        return date.formatted(date: .abbreviated, time: .omitted)
    }

    private func saveEntry() {
        let plainText = attributedText.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !plainText.isEmpty else { return }

        let userId = users.first?.id ?? UUID()
        let entry = RRJournalEntry(
            userId: userId,
            date: Date(),
            mode: mode.rawValue,
            content: plainText,
            prompt: currentPrompt?.text
        )
        entry.setRichContent(from: attributedText)
        modelContext.insert(entry)

        // Reset editor
        attributedText = NSAttributedString(
            string: "",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label,
            ]
        )
        currentPrompt = nil
        showPrompt = false

        // Show confirmation
        withAnimation(.easeInOut(duration: 0.3)) {
            showSavedConfirmation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showSavedConfirmation = false
            }
        }
    }

    private func saveJot() {
        let text = jotText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userId = users.first?.id ?? UUID()
        let entry = RRJournalEntry(
            userId: userId,
            date: Date(),
            mode: "jotting",
            content: text,
            prompt: nil
        )
        modelContext.insert(entry)
        jotText = ""

        withAnimation(.easeInOut(duration: 0.3)) { showSavedConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) { showSavedConfirmation = false }
        }
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
