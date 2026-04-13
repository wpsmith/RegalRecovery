import SwiftUI

struct BookLibraryView: View {
    @State private var hasMigrated = false
    @State private var showLanguagePicker = false

    private var langManager: BookLanguageManager { .shared }
    private var isNonEnglish: Bool { langManager.currentLanguage != "en" }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(BookCatalog.allBooks) { book in
                    NavigationLink(destination: BookTableOfContentsView(book: book)) {
                        bookCard(book)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.rrBackground)
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                languageButton
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            BookLanguagePickerView()
        }
        .onAppear {
            if !hasMigrated {
                migrateProgressIfNeeded()
                hasMigrated = true
            }
        }
    }

    // MARK: - Language Button

    private var languageButton: some View {
        Button {
            showLanguagePicker = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "globe")
                    .font(.body)

                if isNonEnglish {
                    Text(langManager.currentLanguage.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(Color.rrPrimary)
        }
    }

    // MARK: - Book Card

    private func bookCard(_ book: Book) -> some View {
        let progress = bookProgress(book)
        let percent = Int(progress * 100)

        return RRCard {
            HStack(spacing: 16) {
                // Book icon
                ZStack(alignment: .topTrailing) {
                    Image(systemName: book.icon)
                        .font(.title2)
                        .foregroundStyle(book.iconColor)
                        .frame(width: 48, height: 48)
                        .background(book.iconColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // Language badge overlay
                    if isNonEnglish {
                        Text(langManager.currentLanguage.uppercased())
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 3)
                            .padding(.vertical, 1)
                            .background(
                                Capsule()
                                    .fill(book.isUsingFallback ? Color.rrTextSecondary : Color.rrPrimary)
                            )
                            .offset(x: 4, y: -4)
                    }
                }

                // Book details
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.localizedTitle)
                        .font(.system(size: 17, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.rrText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(book.author)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    if let edition = book.edition {
                        Text(edition)
                            .font(RRFont.caption2)
                            .foregroundStyle(Color.rrTextSecondary.opacity(0.8))
                            .tracking(0.5)
                    }

                    // English fallback indicator
                    if isNonEnglish && book.isUsingFallback {
                        Text("English \u{2014} translation not yet available")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.rrTextSecondary.opacity(0.7))
                            .italic()
                    }

                    // Progress bar row
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.rrTextSecondary.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(progress > 0 ? Color.rrSuccess : Color.clear)
                                    .frame(width: geo.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text("\(percent)%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(progress > 0 ? Color.rrSuccess : Color.rrTextSecondary)
                            .frame(width: 36, alignment: .trailing)
                    }
                    .padding(.top, 4)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rrTextSecondary.opacity(0.5))
            }
        }
    }

    // MARK: - Progress Calculation

    private func bookProgress(_ book: Book) -> Double {
        guard let data = UserDefaults.standard.data(forKey: book.progressStorageKey),
              let map = try? JSONDecoder().decode([String: Double].self, from: data) else { return 0 }
        let total = book.chapters.count
        guard total > 0 else { return 0 }
        let completed = map.values.filter { $0 >= 0.95 }.count
        return Double(completed) / Double(total)
    }

    // MARK: - Migration

    private func migrateProgressIfNeeded() {
        let defaults = UserDefaults.standard

        // Migrate old Big Book reading progress to new key format
        let oldKey = "bigbook.readingProgress"
        let newKey = "book.bigbook.readingProgress"
        if let existing = defaults.data(forKey: oldKey),
           defaults.data(forKey: newKey) == nil {
            defaults.set(existing, forKey: newKey)
        }

        // Migrate font size preference
        let oldFontKey = "bigbook.fontSize"
        let newFontKey = "books.fontSize"
        if defaults.object(forKey: oldFontKey) != nil,
           defaults.object(forKey: newFontKey) == nil {
            defaults.set(defaults.double(forKey: oldFontKey), forKey: newFontKey)
        }
    }
}

// MARK: - Language Picker

struct BookLanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss

    private var langManager: BookLanguageManager { .shared }

    var body: some View {
        NavigationStack {
            List {
                // Follow Device option
                Section {
                    Button {
                        langManager.selectedLanguage = nil
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Follow Device")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.rrText)

                                let resolved = BookLanguageManager.displayName(
                                    for: BookLanguageManager.resolvedDeviceLanguage
                                )
                                Text("Currently: \(resolved)")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }

                            Spacer()

                            if langManager.selectedLanguage == nil {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.rrPrimary)
                            }
                        }
                    }
                }

                // Explicit language choices
                Section {
                    ForEach(BookLanguageManager.supportedLanguages, id: \.code) { lang in
                        Button {
                            langManager.selectedLanguage = lang.code
                            dismiss()
                        } label: {
                            HStack {
                                Text(lang.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.rrText)

                                Spacer()

                                if langManager.selectedLanguage == lang.code {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.rrPrimary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Language")
                }
            }
            .navigationTitle("Book Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookLibraryView()
    }
}
