# Task 3: Progress Screen — Clickable Activity History Items

## Overview

The `ActivityHistoryView` currently displays activity history items as static rows. The goal is to make each item tappable, navigating to a detail view (`ActivityDetailView`) that already exists and supports all activity types. The main work involves (1) populating the `sourceType` and `sourceId` fields on each `RecentActivity` constructed in `ActivityHistoryView`, and (2) wrapping each `RecentActivityRow` in a `NavigationLink` that pushes to `ActivityDetailView`.

## Current State

- **ActivityHistoryView** (`ios/.../Views/Today/ActivityHistoryView.swift`): Constructs `RecentActivity` items from 11 SwiftData queries but does NOT set `sourceType` or `sourceId`. Renders items via `RecentActivityRow` with no navigation wrapper.
- **ActivityDetailView** (`ios/.../Views/Today/ActivityDetailView.swift`): Fully built detail view that accepts a `RecentActivity`, reads its `sourceType` and `sourceId`, fetches the underlying SwiftData model, and renders type-specific detail cards for all 12 `HistoryItemType` cases.
- **RecentActivity** struct (`ios/.../Models/Types.swift`, lines 704-713): Already has optional `sourceType: HistoryItemType?` and `sourceId: UUID?` properties.
- **HistoryItemType** enum (`ios/.../Models/Types.swift`, lines 688-702): Already defines all 12 cases needed.

## Gap Analysis

The `ActivityDetailView` is fully functional. The only missing pieces are:

1. `ActivityHistoryView` does not populate `sourceType` / `sourceId` when building `RecentActivity` items.
2. `ActivityHistoryView` does not wrap `RecentActivityRow` items in `NavigationLink`.
3. `RecentActivityRow` has no visual affordance (chevron) indicating tappability.

## Step-by-Step Implementation

### Step 1: Populate `sourceType` and `sourceId` in `ActivityHistoryView`

**File**: `ios/.../Views/Today/ActivityHistoryView.swift`

For each loop in `allActivities` (lines 25-68), add the `sourceType` and `sourceId` parameters to each `RecentActivity` constructor call.

**Commitments** (lines 25-29):
```swift
sourceType: c.type == "morning" ? .morningCommitment : .eveningReview,
sourceId: c.id
```

**Mood entries** (lines 31-38):
```swift
sourceType: .mood,
sourceId: m.id
```

**Prayer logs** (lines 39-41):
```swift
sourceType: .prayer,
sourceId: p.id
```

**Exercise logs** (lines 42-44):
```swift
sourceType: .exercise,
sourceId: e.id
```

**FASTER entries** (lines 45-48):
```swift
sourceType: .fasterScale,
sourceId: f.id
```

**Journal entries** (lines 49-52):
```swift
sourceType: .journal,
sourceId: j.id
```

**Gratitude entries** (lines 53-55):
```swift
sourceType: .gratitude,
sourceId: g.id
```

**Urge logs** (lines 56-58):
```swift
sourceType: .urgeLog,
sourceId: u.id
```

**Phone call logs** (lines 59-61):
```swift
sourceType: .phoneCall,
sourceId: pc.id
```

**Meeting logs** (lines 62-64):
```swift
sourceType: .meeting,
sourceId: ml.id
```

**Spouse check-ins** (lines 65-68):
```swift
sourceType: sc.framework == "FANOS" ? .fanos : .fitnap,
sourceId: sc.id
```

### Step 2: Wrap each `RecentActivityRow` in a `NavigationLink`

**File**: `ios/.../Views/Today/ActivityHistoryView.swift`

Replace the `ForEach` loop body at lines 113-119:

```swift
ForEach(section.items) { activity in
    NavigationLink {
        ActivityDetailView(activity: activity)
    } label: {
        RecentActivityRow(activity: activity)
    }
    .buttonStyle(.plain)

    if activity.id != section.items.last?.id {
        Divider()
            .padding(.leading, 44)
    }
}
```

The `.buttonStyle(.plain)` matches the existing pattern used throughout the app to prevent the default blue tint on NavigationLink labels.

### Step 3: Add chevron visual affordance to `RecentActivityRow`

**File**: `ios/.../Views/Home/RecentActivityRow.swift`

Add a chevron after the time text (before closing HStack, ~line 31):

```swift
Text(activity.time)
    .font(RRFont.caption2)
    .foregroundStyle(Color.rrTextSecondary)

if activity.sourceType != nil {
    Image(systemName: "chevron.right")
        .font(.caption2)
        .foregroundStyle(Color.rrTextSecondary)
}
```

The conditional ensures the chevron only appears when the item is navigable (preserves backward compatibility for HomeView's RecentActivityFeed which doesn't set `sourceType`).

### Step 4 (Optional): Make HomeView's RecentActivityFeed clickable too

- **`ios/.../Views/Home/HomeView.swift`**: Apply same `sourceType`/`sourceId` population to `recentActivities` computed property (lines 59-105).
- **`ios/.../Views/Home/RecentActivityFeed.swift`**: Wrap each `RecentActivityRow` in a `NavigationLink` to `ActivityDetailView`.

## Files Modified Summary

| File | Change |
|------|--------|
| `ios/.../Views/Today/ActivityHistoryView.swift` | Add `sourceType`/`sourceId` to all `RecentActivity` constructors; wrap rows in `NavigationLink` |
| `ios/.../Views/Home/RecentActivityRow.swift` | Add conditional chevron indicator when `sourceType` is non-nil |
| `ios/.../Views/Home/RecentActivityFeed.swift` | (Optional) Wrap rows in `NavigationLink` for home screen clickability |
| `ios/.../Views/Home/HomeView.swift` | (Optional) Add `sourceType`/`sourceId` to `recentActivities` items |

## No New Files Needed

- **ActivityDetailView.swift** — Already complete with all 12 detail renderers.
- **Types.swift** — `RecentActivity` and `HistoryItemType` already have the needed properties.
- **RRModels.swift** — No schema changes needed; all SwiftData models already have `id: UUID`.

## Navigation Approach

**Push navigation via `NavigationLink`** because:
1. `ActivityHistoryView` is already inside a `NavigationStack` (uses `.navigationTitle("Activity History")` and is pushed from `RecoveryProgressView`).
2. Matches navigation pattern used everywhere else in the app.
3. Sheets would be inappropriate since this is drill-down into content, not a modal workflow.

## What ActivityDetailView Shows Per Activity Type

| HistoryItemType | Detail Content |
|---|---|
| `.morningCommitment` / `.eveningReview` | Type, date, completion time |
| `.journal` | Mode, date, prompt (if any), full entry content |
| `.fasterScale` | Mood icon/label, thermometer visualization, selected indicators per stage, adaptive content card, reflections |
| `.urgeLog` | Intensity, date, resolution, triggers (flow layout badges), notes |
| `.mood` | Sensa emoji, primary mood with color, secondary emotion, intensity, urge to act out, context tags |
| `.gratitude` | Item count, date, numbered list of all gratitude items |
| `.prayer` | Duration, type, date |
| `.exercise` | Type, duration, date, notes |
| `.phoneCall` | Contact name, role, duration, date, notes |
| `.meeting` | Meeting name, duration, date, notes |
| `.fanos` / `.fitnap` | Framework name, date |

## Testing Considerations

1. Verify each of the 11 activity types can be tapped and navigates to the correct detail view.
2. Verify the "Load More" button still works after adding NavigationLinks.
3. Verify the empty state still displays correctly when there are no activities.
4. Verify the chevron appears on history items but NOT on home feed items (unless Step 4 is also implemented).
5. Verify backward navigation (swipe back / back button) returns to the Activity History list correctly.
6. Verify that items with missing underlying data show the "Details unavailable" fallback in `ActivityDetailView`.
