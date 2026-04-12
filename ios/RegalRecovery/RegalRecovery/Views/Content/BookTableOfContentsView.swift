import SwiftUI

struct BookTableOfContentsView: View {
    let book: Book

    @State private var progressMap: [String: Double] = [:]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                    .padding(.bottom, 32)

                chapterList
            }
            .padding(.vertical, 24)
        }
        .background(Color.rrBackground)
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadProgress() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: book.icon)
                .font(.system(size: 48))
                .foregroundStyle(book.iconColor)
                .padding(.bottom, 4)

            Text(book.title)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)

            Text(book.subtitle)
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .italic()
                .padding(.horizontal, 32)

            Text(book.author)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundStyle(Color.rrTextSecondary)

            if let edition = book.edition {
                Text(edition)
                    .font(.system(size: 12, weight: .medium, design: .serif))
                    .foregroundStyle(Color.rrTextSecondary)
                    .tracking(2)
                    .textCase(.uppercase)
                    .padding(.top, 4)
            }

            Divider()
                .padding(.horizontal, 48)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Chapter List

    private var chapterList: some View {
        VStack(spacing: 0) {
            ForEach(book.chapters) { chapter in
                NavigationLink(destination: BookChapterReaderView(book: book, chapter: chapter)) {
                    chapterRow(chapter)
                }
                .buttonStyle(.plain)

                if chapter.id != book.chapters.last?.id {
                    Divider()
                        .padding(.leading, 60)
                        .padding(.trailing, 24)
                }
            }
        }
    }

    private func chapterRow(_ chapter: BookChapter) -> some View {
        HStack(spacing: 14) {
            chapterNumberView(chapter)

            VStack(alignment: .leading, spacing: 3) {
                Text(chapter.title)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color.rrText)

                if !chapter.subtitle.isEmpty {
                    Text(chapter.subtitle)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }

            Spacer()

            progressIndicator(for: chapter)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private func chapterNumberView(_ chapter: BookChapter) -> some View {
        Group {
            if let number = chapter.number {
                Text(book.numberStyle.display(for: number))
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(book.iconColor)
                    .frame(width: 28, height: 28)
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 13))
                    .foregroundStyle(book.iconColor.opacity(0.7))
                    .frame(width: 28, height: 28)
            }
        }
    }

    private func progressIndicator(for chapter: BookChapter) -> some View {
        let value = progressMap[chapter.filename] ?? 0.0

        return Group {
            if value >= 0.95 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.rrSuccess)
            } else if value > 0.0 {
                BookCircularProgressView(progress: value)
            } else {
                EmptyView()
            }
        }
    }

    // MARK: - Persistence

    private func loadProgress() {
        guard let data = UserDefaults.standard.data(forKey: book.progressStorageKey),
              let map = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return
        }
        progressMap = map
    }
}

// MARK: - Circular Progress

private struct BookCircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.rrSuccess.opacity(0.2), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.rrSuccess, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 18, height: 18)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookTableOfContentsView(book: Book(
            id: "big-book",
            title: "Alcoholics Anonymous",
            subtitle: "The Story of How Many Thousands of Men and Women Have Recovered from Alcoholism",
            author: "Alcoholics Anonymous World Services",
            edition: "Second Edition",
            icon: "book.closed.fill",
            iconColor: .blue,
            subdirectory: "BigBook",
            headerLinesToSkip: 3,
            chapters: [
                BookChapter(id: "ch1", filename: "ch1", title: "Bill's Story", subtitle: "Co-founder's journey", number: 1),
                BookChapter(id: "ch2", filename: "ch2", title: "There Is a Solution", subtitle: "", number: 2),
                BookChapter(id: "foreword", filename: "foreword", title: "Foreword", subtitle: "", number: nil),
            ],
            chapterLabel: "Chapter",
            numberStyle: .arabic
        ))
    }
}
