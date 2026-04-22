# Task 1: Quick Action > Affirmations History Logging

## Problem

The `AffirmationDeckView` (card-swiping view accessed via Quick Actions and Today screen) never creates an `RRActivity` record. The `AffirmationTodayCard` queries for `RRActivity` records with `activityType == "Affirmation Log"` and shows completion status, but no code path ever writes these records. Affirmation sessions never appear in Recent Activity Feed, Activity History, or Today Activity Log.

## Existing Infrastructure

The read side is fully built — only the write path is missing:

- `RRActivity` model (`RRModels.swift` lines 288-335) has a `JSONPayload data` field for structured metadata
- `ActivityType.affirmationLog` already exists in `Types.swift` with the correct icon and color
- `AffirmationTodayCard` already queries `RRActivity` with the right predicate
- `TodayViewModel` lines 516-520 and 642-648 already handle `"Affirmation Log"` for daily score calculation

## Data to Track

| Field | Type | Source |
|-------|------|--------|
| `cardsViewed` | `Int` | Count of distinct card indices the user swiped to |
| `totalCards` | `Int` | `affirmations.count` in `AffirmationDeckView` |
| `durationSeconds` | `Int` | Elapsed time from view appear to completion/dismiss |
| `packName` | `String` | The pack name passed into `AffirmationDeckView` |

## Step-by-Step Implementation

### Step 1: Add session tracking state to `AffirmationDeckView`

**File:** `ios/.../Views/Content/AffirmationDeckView.swift`

1. Add `@Environment(\.modelContext) private var modelContext`
2. Add `@Environment(\.dismiss) private var dismiss`
3. Add `@Query(sort: \RRUser.createdAt) private var users: [RRUser]` for userId
4. Add `@State private var sessionStartDate = Date()`
5. Add `@State private var viewedIndices: Set<Int> = [0]` (card 0 is visible on appear)
6. Add `@State private var hasLoggedSession = false`

7. In the `TabView(selection: $currentIndex)`, add `.onChange(of: currentIndex)` to track viewed cards:
   ```swift
   .onChange(of: currentIndex) { _, newIndex in
       viewedIndices.insert(newIndex)
   }
   ```

8. Add `.onDisappear` modifier that calls `logSession()`

9. Implement `logSession()`:
   ```swift
   private func logSession() {
       guard !hasLoggedSession else { return }
       let durationSeconds = Int(Date().timeIntervalSince(sessionStartDate))
       guard durationSeconds >= 3 else { return } // skip accidental taps
       
       let activity = RRActivity(
           userId: users.first?.id ?? UUID(),
           activityType: ActivityType.affirmationLog.rawValue,
           date: Date(),
           data: JSONPayload([
               "cardsViewed": AnyCodableValue.int(viewedIndices.count),
               "totalCards": AnyCodableValue.int(affirmations.count),
               "durationSeconds": AnyCodableValue.int(durationSeconds),
               "packName": AnyCodableValue.string(packName)
           ])
       )
       modelContext.insert(activity)
       hasLoggedSession = true
   }
   ```

### Step 2: Update Recent Activity Feed in `HomeView`

**File:** `ios/.../Views/Home/HomeView.swift`

1. Add `@Query` for `RRActivity` filtered to affirmation logs
2. In `recentActivities` computed property (~line 103), add loop for affirmation sessions:
   ```swift
   for a in affirmationSessions.prefix(3) {
       let cardsViewed = a.data.data["cardsViewed"]?.intValue ?? 0
       let totalCards = a.data.data["totalCards"]?.intValue ?? 0
       let durationSeconds = a.data.data["durationSeconds"]?.intValue ?? 0
       let detail = "\(cardsViewed)/\(totalCards) cards, \(formatDuration(durationSeconds))"
       all.append((a.date, RecentActivity(
           title: "Affirmations",
           detail: detail,
           time: fmt.localizedString(for: a.date, relativeTo: Date()),
           icon: ActivityType.affirmationLog.icon,
           iconColor: ActivityType.affirmationLog.iconColor
       )))
   }
   ```

### Step 3: Update Activity History View

**File:** `ios/.../Views/Today/ActivityHistoryView.swift`

Add same `@Query` and loop pattern as Step 2 to include affirmation sessions in `allActivities`.

### Step 4: Update Today Activity Log in `TodayViewModel`

**File:** `ios/.../ViewModels/TodayViewModel.swift`

In `loadTodayActivityLog(context:)` (~line 313+), add affirmation session fetch after existing activity blocks:

```swift
let affirmationDesc = FetchDescriptor<RRActivity>(
    predicate: #Predicate { $0.activityType == "Affirmation Log" && $0.date >= todayStart && $0.date < tomorrow },
    sortBy: [SortDescriptor(\.date, order: .reverse)]
)
```

### Step 5: Duration formatting helper

Add private helper in each file where needed:
- 0-59 seconds: "< 1 min"
- 60-3599 seconds: "Xm Ys"
- 3600+ seconds: "Xh Ym"

## Files Modified Summary

| File | Change |
|------|--------|
| `Views/Content/AffirmationDeckView.swift` | Add session tracking and log `RRActivity` on disappear |
| `Views/Home/HomeView.swift` | Add `@Query` for affirmation sessions in `recentActivities` |
| `Views/Today/ActivityHistoryView.swift` | Add `@Query` for affirmation sessions in `allActivities` |
| `ViewModels/TodayViewModel.swift` | Add affirmation session fetch in `loadTodayActivityLog()` |

## No Changes Needed

- `RRModels.swift` — `RRActivity` with `JSONPayload` already sufficient
- `Types.swift` — `ActivityType.affirmationLog` already exists
- `AffirmationTodayCard.swift` — Already queries correctly, will work once records exist

## Edge Cases

1. **Double-logging:** `hasLoggedSession` flag prevents multiple `onDisappear` calls
2. **Minimum duration:** 3-second threshold skips accidental navigations
3. **Initial card:** Card 0 added to `viewedIndices` on init since it's visible without swiping
4. **App termination:** If app is killed, `onDisappear` may not fire — acceptable for MVP
