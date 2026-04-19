import SwiftUI

struct VisionScriptureStepView: View {
    @Bindable var viewModel: VisionWizardViewModel
    @State private var selectedCategory: ScriptureCategory? = nil
    @State private var searchText = ""
    @State private var showCustomEntry = false
    @State private var customReference = ""
    @State private var customText = ""

    private var filteredEntries: [ScriptureEntry] {
        if !searchText.isEmpty {
            return ScriptureLibrary.search(searchText)
        }
        return ScriptureLibrary.filtered(by: selectedCategory)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Anchor your vision in Scripture")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text("Choose a verse that speaks to the man you are becoming. This is optional.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Search verses...", text: $searchText)
                }
                .padding(10)
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        categoryChip(nil, label: "All")
                        ForEach(ScriptureCategory.allCases, id: \.rawValue) { category in
                            categoryChip(category, label: category.rawValue)
                        }
                    }
                }

                LazyVStack(spacing: 12) {
                    ForEach(filteredEntries) { entry in
                        scriptureRow(entry)
                    }
                }

                Divider()

                Button {
                    showCustomEntry.toggle()
                } label: {
                    Label("Or enter your own", systemImage: showCustomEntry ? "chevron.up" : "chevron.down")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrPrimary)
                }

                if showCustomEntry {
                    VStack(spacing: 12) {
                        TextField("Reference (e.g., John 3:16)", text: $customReference)
                            .padding(10)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        TextField("Verse text", text: $customText, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(10)
                            .background(Color.rrSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Button {
                            let ref = customReference.trimmingCharacters(in: .whitespacesAndNewlines)
                            let txt = customText.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !ref.isEmpty {
                                viewModel.scriptureReference = ref
                                viewModel.scriptureText = txt.isEmpty ? nil : txt
                            }
                        } label: {
                            Text("Use This Verse")
                                .font(RRFont.body)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(customReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.rrTextSecondary.opacity(0.3) : Color.rrPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .disabled(customReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if let ref = viewModel.scriptureReference {
                    RRCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.rrSuccess)
                                Text("Selected")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrSuccess)
                                Spacer()
                                Button {
                                    viewModel.scriptureReference = nil
                                    viewModel.scriptureText = nil
                                } label: {
                                    Image(systemName: "xmark.circle")
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }
                            Text(ref)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            if let text = viewModel.scriptureText {
                                Text(text)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .italic()
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func categoryChip(_ category: ScriptureCategory?, label: String) -> some View {
        let isActive = selectedCategory == category
        return Button {
            selectedCategory = category
        } label: {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(isActive ? .white : Color.rrPrimary)
                .background(isActive ? Color.rrPrimary : Color.rrPrimary.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private func scriptureRow(_ entry: ScriptureEntry) -> some View {
        let isSelected = viewModel.scriptureReference == entry.reference

        return Button {
            viewModel.scriptureReference = entry.reference
            viewModel.scriptureText = entry.text
        } label: {
            RRCard {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.reference)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.rrSuccess)
                        }
                    }
                    Text(entry.text)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                        .lineLimit(3)
                    RRBadge(text: entry.category.rawValue, color: .rrPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VisionScriptureStepView(viewModel: VisionWizardViewModel())
}
