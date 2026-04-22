# Task 4: Library Fixes

Three issues: broken book progress bar, journal from paragraph, and FAB clearance.

---

## Issue 1: Book Progress Bar Not Working Properly

### Root Cause

1. **`contentHeight` measured before text loads.** The GeometryReader in `BookChapterReaderView` (line 53-66) fires before text renders in `.onAppear` (line 106), so `contentHeight` may be wrong.
2. **Progress only saved in `onDisappear`** (line 112-113). If `onDisappear` fires before final scroll preference propagates, saved value is stale.
3. **`BookLibraryView` doesn't observe UserDefaults reactively.** `bookProgress()` (line 155) reads from UserDefaults but SwiftUI can't detect changes.
4. **`BookTableOfContentsView.loadProgress()`** only runs in `onAppear` (line 24).

### Fixes

#### Step 1a: Debounced progress saving on scroll

**File:** `ios/.../Views/Content/BookChapterReaderView.swift`

In `onPreferenceChange` (lines 80-82), after setting `scrollOffset`, call debounced save:

```swift
.onPreferenceChange(BookReaderScrollOffsetPreferenceKey.self) { value in
    scrollOffset = value
    debouncedSaveProgress()
}
```

Add:
```swift
@State private var saveTask: Task<Void, Never>?

private func debouncedSaveProgress() {
    saveTask?.cancel()
    saveTask = Task {
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await MainActor.run { saveProgress() }
    }
}
```

#### Step 1b: Detect scroll-to-bottom for chapter completion

Add `GeometryReader` to `navigationFooter` to detect when it enters viewport:

```swift
.background(
    GeometryReader { geo in
        Color.clear
            .onChange(of: geo.frame(in: .named("bookReaderScroll")).maxY) { _, maxY in
                if maxY <= viewportHeight + 50 {
                    updateProgress(1.0)
                }
            }
    }
)
```

#### Step 1c: Handle short chapters

In `onAppear`, after text loads with a short delay: if `contentHeight <= viewportHeight`, mark chapter complete.

#### Step 1d: Make `BookTableOfContentsView` progress reactive

**File:** `ios/.../Views/Content/BookTableOfContentsView.swift`

Ensure `loadProgress()` fires on `onAppear` reliably (it should on NavigationStack pop).

#### Step 1e: Make `BookLibraryView` progress reactive

**File:** `ios/.../Views/Content/BookLibraryView.swift`

Add `@State private var refreshTrigger = UUID()` toggled in `.onAppear` to force recomputation of progress values.

---

## Issue 2: Journal from Paragraph

### Design

Long-press on any paragraph in `BookChapterReaderView` opens JournalView with that paragraph as a prompt. The journal entry stores a back-reference to the source book/chapter.

### Step 2a: Add source fields to `RRJournalEntry`

**File:** `ios/.../Data/Models/RRModels.swift` (~line 386)

```swift
var sourceBookId: String?
var sourceChapterId: String?
var sourceParagraphIndex: Int?
```

Backward-compatible (optional fields, lightweight migration).

### Step 2b: Add journal sheet state to `BookChapterReaderView`

**File:** `ios/.../Views/Content/BookChapterReaderView.swift`

```swift
struct ParagraphJournalContext: Identifiable {
    let id = UUID()
    let text: String
    let index: Int
}

@State private var journalParagraph: ParagraphJournalContext?
```

### Step 2c: Add context menu to paragraphs

In `bodyText` (line 152-178), wrap each paragraph Group with:

```swift
.contextMenu {
    Button {
        journalParagraph = ParagraphJournalContext(text: paragraph, index: index)
    } label: {
        Label("Journal About This", systemImage: "note.text.badge.plus")
    }
    Button {
        UIPasteboard.general.string = paragraph
    } label: {
        Label("Copy", systemImage: "doc.on.doc")
    }
}
```

### Step 2d: Add journal sheet

```swift
.sheet(item: $journalParagraph) { paragraph in
    NavigationStack {
        JournalView(
            bookParagraphPrompt: paragraph.text,
            bookTitle: book.localizedTitle,
            chapterTitle: chapter.title,
            sourceBookId: book.id,
            sourceChapterId: chapter.id,
            sourceParagraphIndex: paragraph.index
        )
    }
}
```

### Step 2e: Update `JournalView`

**File:** `ios/.../Views/Activities/JournalView.swift`

Add new optional parameters:
```swift
var bookParagraphPrompt: String? = nil
var bookTitle: String? = nil
var chapterTitle: String? = nil
var sourceBookId: String? = nil
var sourceChapterId: String? = nil
var sourceParagraphIndex: Int? = nil
```

Add `bookParagraphContextCard` (similar to existing `devotionalContextCard`, line 554-573):
- Shows book title, chapter title, and quoted paragraph text
- Displayed above the editor when present

Update `saveEntry()` (line 722-758) to persist source fields.

Update `.onAppear`: set `mode = .freeform` when `bookParagraphPrompt != nil`.

Hide mode selector when opened from book paragraph.

### Step 2f: Update `JournalEntryDetailView`

Show book source context badge if `sourceBookId` exists.

---

## Issue 3: Bottom Padding to Clear FAB

The FAB is 56pt circle positioned with `.padding(.bottom, 60)` at the app level. Library pages need ~80pt bottom padding.

### Step 3a: `BookLibraryView.swift`

Add `.padding(.bottom, 80)` after existing `.padding(.vertical, 20)` at line 22.

### Step 3b: `BookTableOfContentsView.swift`

Add `.padding(.bottom, 80)` after `.padding(.vertical, 24)` at line 19.

### Step 3c: `BookChapterReaderView.swift`

Increase `navigationFooter` bottom padding from 24pt to 100pt (line 48).

### Step 3d: `ContentTabView.swift`

Add `.padding(.bottom, 80)` after `.padding()` at line 87.

---

## Files Modified Summary

| File | Change |
|------|--------|
| `Views/Content/BookChapterReaderView.swift` | Debounced save, scroll-to-bottom detection, context menu, journal sheet, increased bottom padding |
| `Views/Content/BookLibraryView.swift` | Reactive progress refresh, bottom padding |
| `Views/Content/BookTableOfContentsView.swift` | Bottom padding |
| `Views/Content/ContentTabView.swift` | Bottom padding |
| `Data/Models/RRModels.swift` | Add `sourceBookId`, `sourceChapterId`, `sourceParagraphIndex` to `RRJournalEntry` |
| `Views/Activities/JournalView.swift` | Accept book paragraph prompt, show context card, save source fields |
| `Views/Activities/JournalEntryDetailView.swift` | Show book source context |

## Implementation Order

1. **Issue 3** (FAB clearance) — quickest, pure padding changes
2. **Issue 1** (Progress bar) — computation/lifecycle fixes
3. **Issue 2** (Journal from paragraph) — model + view changes, largest scope
