import SwiftUI

struct BookChapterReaderView: View {
    let book: Book
    let chapter: BookChapter

    @AppStorage("books.fontSize") private var fontSize: Double = 17.0
    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 1
    @State private var viewportHeight: CGFloat = 1
    @State private var text: String = ""
    @State private var tts = TextToSpeechService()
    @State private var showPlayer = false

    private static let readingBackground = Color(red: 0.98, green: 0.96, blue: 0.93)

    private var paragraphs: [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var currentIndex: Int? {
        book.chapters.firstIndex(where: { $0.id == chapter.id })
    }

    private var previousChapter: BookChapter? {
        guard let idx = currentIndex, idx > 0 else { return nil }
        return book.chapters[idx - 1]
    }

    private var nextChapter: BookChapter? {
        guard let idx = currentIndex, idx < book.chapters.count - 1 else { return nil }
        return book.chapters[idx + 1]
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    chapterHeader
                        .padding(.bottom, 28)

                    bodyText
                        .padding(.bottom, 40)

                    navigationFooter
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: BookReaderScrollOffsetPreferenceKey.self,
                                value: -geo.frame(in: .named("bookReaderScroll")).origin.y
                            )
                            .onAppear {
                                contentHeight = max(geo.size.height, 1)
                            }
                            .onChange(of: geo.size.height) { _, newValue in
                                contentHeight = max(newValue, 1)
                            }
                    }
                )
            }
            .coordinateSpace(name: "bookReaderScroll")
            .background(
                GeometryReader { geo in
                    Self.readingBackground
                        .onAppear {
                            viewportHeight = geo.size.height
                        }
                        .onChange(of: geo.size.height) { _, newValue in
                            viewportHeight = newValue
                        }
                }
            )
            .onPreferenceChange(BookReaderScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .onChange(of: tts.currentParagraphIndex) { _, newIndex in
                guard tts.state != .stopped else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollProxy.scrollTo(newIndex, anchor: .center)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if showPlayer {
                    ttsPlayerBar
                }
            }
        }
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    ttsToolbarButton
                    fontSizeMenu
                }
            }
        }
        .onAppear {
            text = book.loadText(for: chapter)
            let language = TextToSpeechService.resolveLanguage()
            tts.load(paragraphs: paragraphs, language: language)
        }
        .onDisappear {
            tts.stop()
            saveProgress()
        }
    }

    // MARK: - Chapter Header

    private var chapterHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let number = chapter.number {
                Text("\(book.chapterLabel) \(book.numberStyle.display(for: number))")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.rrPrimary)
                    .tracking(1.5)
                    .textCase(.uppercase)
            }

            Text(chapter.title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(Color.rrText)

            if !chapter.subtitle.isEmpty {
                Text(chapter.subtitle)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.top, 2)
            }

            Rectangle()
                .fill(Color.rrPrimary.opacity(0.3))
                .frame(width: 40, height: 2)
                .padding(.top, 12)
        }
    }

    // MARK: - Body Text

    private var isTTSActive: Bool {
        tts.state == .playing || tts.state == .paused
    }

    private var bodyText: some View {
        VStack(alignment: .leading, spacing: fontSize * 0.9) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, paragraph in
                Group {
                    if index == 0 {
                        firstParagraphView(paragraph)
                    } else {
                        Text(paragraph)
                            .font(.system(size: fontSize, weight: .regular, design: .serif))
                            .foregroundStyle(Color.rrText.opacity(0.87))
                            .lineSpacing(fontSize * 0.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, isTTSActive && tts.currentParagraphIndex == index ? 8 : 0)
                .padding(.vertical, isTTSActive && tts.currentParagraphIndex == index ? 6 : 0)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isTTSActive && tts.currentParagraphIndex == index
                              ? Color.rrPrimary.opacity(0.08)
                              : Color.clear)
                )
                .animation(.easeInOut(duration: 0.2), value: tts.currentParagraphIndex)
                .id(index)
            }
        }
    }

    private func firstParagraphView(_ paragraph: String) -> some View {
        Group {
            if paragraph.count > 1 {
                let firstChar = String(paragraph.prefix(1))
                let rest = String(paragraph.dropFirst())
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(firstChar)
                            .font(.system(size: fontSize * 2.8, weight: .bold, design: .serif))
                            .foregroundStyle(Color.rrPrimary)
                            .baselineOffset(-(fontSize * 0.3))
                        Text(rest)
                            .font(.system(size: fontSize, weight: .regular, design: .serif))
                            .foregroundStyle(Color.rrText.opacity(0.87))
                            .lineSpacing(fontSize * 0.5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Text(paragraph)
                    .font(.system(size: fontSize, weight: .regular, design: .serif))
                    .foregroundStyle(Color.rrText.opacity(0.87))
                    .lineSpacing(fontSize * 0.5)
            }
        }
    }

    // MARK: - Navigation Footer

    private var navigationFooter: some View {
        VStack(spacing: 16) {
            Divider()

            HStack {
                if let prev = previousChapter {
                    NavigationLink(destination: BookChapterReaderView(book: book, chapter: prev)) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Previous")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(prev.title)
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundStyle(Color.rrPrimary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if let next = nextChapter {
                    NavigationLink(destination: BookChapterReaderView(book: book, chapter: next)) {
                        HStack(spacing: 6) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Next")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color.rrTextSecondary)
                                Text(next.title)
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundStyle(Color.rrPrimary)
                                    .lineLimit(1)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Font Size Menu

    private var fontSizeMenu: some View {
        Menu {
            Button {
                if fontSize > 13 { fontSize -= 1 }
            } label: {
                Label("Smaller Text", systemImage: "textformat.size.smaller")
            }

            Button {
                if fontSize < 24 { fontSize += 1 }
            } label: {
                Label("Larger Text", systemImage: "textformat.size.larger")
            }

            Divider()

            Button {
                fontSize = 17
            } label: {
                Label("Reset Size", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "textformat.size")
                .font(.body)
                .foregroundStyle(Color.rrPrimary)
        }
    }

    // MARK: - TTS Toolbar Button

    private var ttsToolbarButton: some View {
        Button {
            showPlayer.toggle()
            if !showPlayer {
                tts.stop()
            }
        } label: {
            Image(systemName: showPlayer ? "headphones.circle.fill" : "headphones")
                .font(.body)
                .foregroundStyle(Color.rrPrimary)
        }
    }

    // MARK: - TTS Player Bar

    private var ttsPlayerBar: some View {
        VStack(spacing: 8) {
            Divider()

            HStack(spacing: 20) {
                Button {
                    tts.skipBackward()
                } label: {
                    Image(systemName: "backward.end.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.rrText)
                }
                .disabled(tts.state == .stopped && tts.currentParagraphIndex == 0)

                Button {
                    switch tts.state {
                    case .stopped:
                        tts.play()
                    case .playing:
                        tts.pause()
                    case .paused:
                        tts.resume()
                    }
                } label: {
                    Image(systemName: tts.state == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.rrPrimary)
                }

                Button {
                    tts.skipForward()
                } label: {
                    Image(systemName: "forward.end.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.rrText)
                }
                .disabled(tts.currentParagraphIndex >= paragraphs.count - 1 && tts.state == .stopped)

                Spacer()

                Menu {
                    ForEach(TextToSpeechService.RatePreset.presets) { preset in
                        Button {
                            tts.setRate(preset)
                        } label: {
                            HStack {
                                Text(preset.label)
                                if preset.utteranceRate == tts.rate {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(tts.rateLabel)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.rrPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)

            if !paragraphs.isEmpty {
                Text("Paragraph \(tts.currentParagraphIndex + 1) of \(paragraphs.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
        .padding(.vertical, 10)
        .background(Self.readingBackground)
    }

    // MARK: - Progress Tracking

    private func saveProgress() {
        let scrollableHeight = contentHeight - viewportHeight
        guard scrollableHeight > 0 else {
            updateProgress(1.0)
            return
        }
        let normalized = min(max(scrollOffset / scrollableHeight, 0), 1.0)
        updateProgress(normalized)
    }

    private func updateProgress(_ value: Double) {
        let key = book.progressStorageKey
        let defaults = UserDefaults.standard
        let existing = defaults.data(forKey: key) ?? Data()
        var dict = (try? JSONDecoder().decode([String: Double].self, from: existing)) ?? [:]
        let previous = dict[chapter.filename] ?? 0.0
        if value > previous {
            dict[chapter.filename] = value
            if let encoded = try? JSONEncoder().encode(dict) {
                defaults.set(encoded, forKey: key)
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct BookReaderScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
