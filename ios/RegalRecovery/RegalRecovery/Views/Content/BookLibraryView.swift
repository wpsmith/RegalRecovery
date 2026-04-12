import SwiftUI

struct BookLibraryView: View {
    @State private var hasMigrated = false

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
        .onAppear {
            if !hasMigrated {
                migrateProgressIfNeeded()
                hasMigrated = true
            }
        }
    }

    // MARK: - Book Card

    private func bookCard(_ book: Book) -> some View {
        let progress = bookProgress(book)
        let percent = Int(progress * 100)

        return RRCard {
            HStack(spacing: 16) {
                // Book icon
                Image(systemName: book.icon)
                    .font(.title2)
                    .foregroundStyle(book.iconColor)
                    .frame(width: 48, height: 48)
                    .background(book.iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                // Book details
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.title)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        BookLibraryView()
    }
}
