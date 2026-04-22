# Task 5: Affirmations Favoriting Fix

## Root Cause Analysis

Four interconnected bugs cause "favoriting is not working properly and does not show that one has already been favorited."

### Bug 1: Favorite button is a no-op
`AffirmationDeckView.swift` line 39-41 — the button action body is empty:
```swift
Button {
    // Toggle favorite — no-op in dummy app
} label: {
```

### Bug 2: `Affirmation.isFavorite` is immutable (`let`)
`Types.swift` lines 613-618 — `isFavorite` is a `let` constant, so even if toggled, the UI could never reflect it. Additionally, `id = UUID()` generates a new UUID on every construction, making identity-based lookups against SwiftData favorites impossible.

### Bug 3: No SwiftData access in deck view
`AffirmationDeckView` takes plain `[Affirmation]` data from `ContentData.affirmationPacks`. It has no `@Query` for `RRAffirmationFavorite`, no `@Environment(\.modelContext)`, and no way to determine whether an affirmation is already favorited.

### Bug 4: `AffirmationsViewModel.toggleFavorite()` is disconnected from persistence
`AffirmationsViewModel.swift` lines 28-34 — only modifies an in-memory array loaded from `MockData.favoriteAffirmations`. Never calls `SwiftDataAffirmationRepository.saveFavorite()` or `removeFavorite()`.

## Step-by-Step Implementation

### Step 1: Make `Affirmation` identity deterministic and `isFavorite` mutable

**File:** `ios/.../Models/Types.swift` (lines 613-618)

- Change `isFavorite` from `let` to `var`
- Add a `stableKey` computed property for text-based matching against SwiftData favorites
- Keep `id = UUID()` for `Identifiable` conformance, use `stableKey` (the `text` property) for favorite lookups

```swift
struct Affirmation: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let scripture: String
    var isFavorite: Bool

    var stableKey: String { text }
}
```

### Step 2: Wire the favorite button in `AffirmationDeckView` to SwiftData

**File:** `ios/.../Views/Content/AffirmationDeckView.swift`

a) Add `@Environment(\.modelContext) private var modelContext`

b) Add `@Query(sort: \RRAffirmationFavorite.createdAt) private var favorites: [RRAffirmationFavorite]`

c) Add helper method:
```swift
private func isFavorited(_ affirmation: Affirmation) -> Bool {
    favorites.contains { $0.affirmationText == affirmation.text && $0.scripture == affirmation.scripture }
}
```

d) Replace the no-op button (line 39-41) with actual toggle logic:
```swift
Button {
    toggleFavorite(affirmation)
} label: {
    Image(systemName: isFavorited(affirmation) ? "heart.fill" : "heart")
        .font(.title2)
        .foregroundStyle(isFavorited(affirmation) ? Color.rrDestructive : Color.rrTextSecondary)
}
```

e) Add `toggleFavorite` method:
```swift
private func toggleFavorite(_ affirmation: Affirmation) {
    if let existing = favorites.first(where: { $0.affirmationText == affirmation.text && $0.scripture == affirmation.scripture }) {
        modelContext.delete(existing)
    } else {
        let favorite = RRAffirmationFavorite(
            userId: UUID(),
            affirmationText: affirmation.text,
            scripture: affirmation.scripture,
            packName: packName
        )
        modelContext.insert(favorite)
    }
    try? modelContext.save()
}
```

f) Change `affirmationCard` to use `isFavorited()` instead of `affirmation.isFavorite` (lines 42-44)

### Step 3: Fix heart icon in ContentTabView's Today's Affirmation card

**File:** `ios/.../Views/Content/ContentTabView.swift` (line 120)

Currently reads `affirmation.isFavorite` from `ContentData.todaysAffirmation` (always `false`). Change to check against existing `@Query` favorites list:

```swift
private func isAffirmationFavorited(_ affirmation: Affirmation) -> Bool {
    favorites.contains { $0.affirmationText == affirmation.text }
}
```

Update line 120:
```swift
Image(systemName: isAffirmationFavorited(affirmation) ? "heart.fill" : "heart")
```

### Step 4: Remove hardcoded `isFavorite` values from static data

**Files:**
- `ios/.../Models/ContentData.swift` (lines 22-95) — keep all `isFavorite: false`
- `ios/.../Models/MockData.swift` (lines 176-262) — change all `isFavorite: true` to `false`. Favorite state should exclusively come from `RRAffirmationFavorite` queries

### Step 5: Remove disconnected `AffirmationsViewModel.toggleFavorite()`

**File:** `ios/.../ViewModels/AffirmationsViewModel.swift`

**Recommended approach (matches codebase patterns):** Remove the in-memory favorites system entirely. All other affirmation views already use `@Query` directly.

- Remove the `favorites` property (line 7)
- Remove `toggleFavorite()` (lines 28-34)
- In `load()`, remove `favorites = MockData.favoriteAffirmations` (line 24)
- Update `getTodaysAffirmation()` favorites bucket (lines 57-62) to accept favorites from caller or remove

### Step 6: Update tests

**File:** `ios/.../Tests/Unit/AffirmationsViewModelTests.swift`

- Toggle tests (lines 17-47) should be replaced with integration tests verifying SwiftData insert/delete of `RRAffirmationFavorite`
- Weighted rotation test (lines 49-72) should be updated to work without ViewModel's favorites array

## Files Modified Summary

| File | Change |
|------|--------|
| `Types.swift` (lines 613-618) | Change `isFavorite` to `var`; add `stableKey` computed property |
| `AffirmationDeckView.swift` | Add `@Environment`, `@Query`; wire button to SwiftData; replace `isFavorite` reads |
| `ContentTabView.swift` (line 120) | Replace `affirmation.isFavorite` with `@Query` lookup |
| `AffirmationsViewModel.swift` | Remove in-memory favorites and `toggleFavorite()` |
| `ContentData.swift` (lines 100-106) | Clarify `defaultFavoriteAffirmations` is seed-data-only |
| `MockData.swift` (lines 176-262) | Remove misleading `isFavorite: true` |
| `AffirmationsViewModelTests.swift` | Update tests for new architecture |

## Critical Files

- `ios/.../Views/Content/AffirmationDeckView.swift`
- `ios/.../Models/Types.swift`
- `ios/.../ViewModels/AffirmationsViewModel.swift`
- `ios/.../Views/Content/ContentTabView.swift`
- `ios/.../Data/Models/RRModels.swift`
