# Gratitude List: History & Browse Specification

**Spec ID:** GL-HS-001
**Version:** 1.0
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md > Gratitude History

---

## 1. Screen: `GratitudeHistoryView`

### Tabs / View Modes

1. **List View** (default) — reverse chronological
2. **Calendar View** — monthly calendar with entry indicators
3. **Favorites** — all individually favorited gratitude items

### List View Layout

```
NavigationStack
  VStack
    ┌─ Search Bar ──────────────────────┐
    │ [Search gratitude items...]       │
    └───────────────────────────────────┘

    ┌─ Filter Chips (horizontal scroll) ┐
    │ [All] [Faith] [Family] [...] [📷] │
    └───────────────────────────────────┘

    ScrollView / LazyVStack
      ┌─ Entry Card ─────────────────────┐
      │ Mar 28, 2026 · 3 items          │
      │ 🌿 "Grateful for sobriety..."   │
      │ 🌿 "My sponsor's patience..."   │
      │ [Family] [Recovery]   [📷]      │
      │ Mood: 😊                        │
      └──────────────────────────────────┘
```

### Entry Card Behavior

- Shows: date, item count, first 2 items as preview (truncated), category tags, photo indicator, mood emoji
- Tap to navigate to `GratitudeDetailView` showing full entry
- Long-press on individual items in detail view to favorite

### Calendar View

- Monthly calendar grid (standard iOS-style)
- Days with entries show a green dot indicator
- Tap any day to view that day's entries
- Navigate months via left/right arrows or swipe

### Favorites View

- Flat list of all individually favorited `GratitudeItem`s
- Shows: item text, date of parent entry, category tag
- Tap to navigate to parent entry detail

---

## 2. Screen: `GratitudeDetailView`

### Layout

```
ScrollView
  VStack
    ┌─ Header ───────────────────────────┐
    │ March 28, 2026 · 7:00 AM          │
    │ Mood: 😊 (4/5)                    │
    └────────────────────────────────────┘

    ┌─ Photo (if attached) ──────────────┐
    │ [Full-width photo]                 │
    └────────────────────────────────────┘

    ┌─ Items ────────────────────────────┐
    │ 1. Grateful for sobriety    [♡/♥] │
    │    [Recovery]                      │
    │ 2. My sponsor's patience    [♡/♥] │
    │    [Relationships]                 │
    │ 3. Morning coffee           [♡/♥] │
    │    [Small Moments]                 │
    └────────────────────────────────────┘

    ┌─ Actions ──────────────────────────┐
    │ [Edit] (if within 24h)  [Share]    │
    └────────────────────────────────────┘
```

### Behavior

- Each item shows favorite toggle (heart icon)
- Long-press item to favorite/unfavorite
- Edit button visible only if `createdAt` is within 24 hours
- Share button opens sharing options (see spec 06-sharing)

---

## 3. Search

- Full-text search across all `GratitudeItem.text` fields
- Results show matching items with parent entry date
- Tap result navigates to parent entry detail
- Minimum 2 characters to trigger search

---

## 4. Filters

| Filter | Type | Behavior |
|--------|------|----------|
| Category | Multi-select chips | Show entries containing items with selected categories |
| Date Range | Date picker (from/to) | Filter by entry date |
| Has Photo | Toggle chip (camera icon) | Show only entries with photos |
| Mood Rating | 1-5 selector | Show entries matching mood score |

Filters are combinable (AND logic).

---

## 5. Acceptance Criteria

| ID | Criterion | Test Reference |
|----|-----------|----------------|
| GL-HS-AC1 | List view shows entries in reverse chronological order | `TestGratitude_GL_HS_AC1_ReverseChronological` |
| GL-HS-AC2 | Entry card shows date, item count, first 2 items preview | `TestGratitude_GL_HS_AC2_EntryCardPreview` |
| GL-HS-AC3 | Category tags shown as pills on entry card | `TestGratitude_GL_HS_AC3_CategoryTagsVisible` |
| GL-HS-AC4 | Calendar view shows green dot on days with entries | `TestGratitude_GL_HS_AC4_CalendarIndicators` |
| GL-HS-AC5 | Tap calendar day navigates to that day's entries | `TestGratitude_GL_HS_AC5_CalendarNavigation` |
| GL-HS-AC6 | Full-text search returns matching items | `TestGratitude_GL_HS_AC6_SearchResults` |
| GL-HS-AC7 | Filters by category, date range, photo, mood combinable | `TestGratitude_GL_HS_AC7_FilterCombination` |
| GL-HS-AC8 | Favorites tab shows all individually favorited items | `TestGratitude_GL_HS_AC8_FavoritesTab` |
| GL-HS-AC9 | Long-press item in detail view toggles favorite | `TestGratitude_GL_HS_AC9_FavoriteToggle` |
| GL-HS-AC10 | Detail view shows edit button only within 24h window | `TestGratitude_GL_HS_AC10_EditButtonVisibility` |
