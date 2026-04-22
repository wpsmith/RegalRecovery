# Task 6: Urge Log Improvements

## Current State

- **Addiction selection** (Step 2 in `UrgeLogView.swift`): Single-select radio buttons using `@State private var selectedAddictionIndex = 0`
- **Trigger selection** (Step 3): Hardcoded list of 8 triggers on line 15, no custom entry mechanism
- **Submit flow**: `submitUrge()` (line 228-241) inserts `RRUrgeLog` but does NOT call `dismiss()` — user stays on Notes step
- **`RRUrgeLog` model**: Stores `var addictionId: UUID?` — single optional UUID

## Implementation

### Change 1: Multi-Select Addictions

#### Step 1a: Update `RRUrgeLog` model

**File:** `ios/.../Data/Models/RRModels.swift` (lines 526-562)

- Remove `var addictionId: UUID?` (line 532)
- Add `var addictionIdsJSON: String?`
- Add computed property:
  ```swift
  var addictionIds: [UUID] {
      get { /* decode from addictionIdsJSON */ }
      set { /* encode to addictionIdsJSON */ }
  }
  ```
- Update `init` to accept `addictionIds: [UUID] = []`

**Migration note:** Keep `addictionId` as deprecated field and populate `addictionIds` from it on first read if `addictionIdsJSON` is nil.

#### Step 1b: Update seed data

- **`SeedData.swift`** (line 448): `addictionIds: [addictionId]`
- **`SeedPersonaData.swift`** (line 821): `addictionIds: [addictionId]`

#### Step 1c: Update `UrgeLogView` addiction selection

**File:** `ios/.../Views/Activities/UrgeLogView.swift`

- **Line 13:** Change `@State private var selectedAddictionIndex = 0` to `@State private var selectedAddictionIds: Set<UUID> = []`
- **Lines 130-157 (`step2Addiction`):** Replace radio buttons with multi-select toggles:
  - Use `selectedAddictionIds.contains(addiction.id)` instead of `selectedAddictionIndex == index`
  - Change icons from `checkmark.circle.fill`/`circle` to `checkmark.square.fill`/`square`
- **Lines 228-241 (`submitUrge`):** Change to:
  ```swift
  let selectedIds = addictions.filter { selectedAddictionIds.contains($0.id) }.map(\.id)
  // Use addictionIds: selectedIds in RRUrgeLog construction
  ```

#### Step 1d: Update `UrgeLogViewModel`

**File:** `ios/.../ViewModels/UrgeLogViewModel.swift`

- Line 8: `var addictions: [String]` in `UrgeEntry`
- Line 36: `var selectedAddictions: Set<String> = []`
- Lines 64-66: Validate `selectedAddictions.isEmpty`
- Line 78: `addictions: Array(selectedAddictions)`

### Change 2: Custom Trigger Entry with Persistence

#### Step 2a: Add custom trigger state

**File:** `ios/.../Views/Activities/UrgeLogView.swift`

```swift
@State private var customTriggerText = ""
@State private var showCustomTriggerField = false
@AppStorage("customUrgeLogTriggers") private var customTriggersData: Data = Data()
```

Add helpers:
```swift
private var customTriggers: [String] { /* decode customTriggersData */ }
private func addCustomTrigger(_ trigger: String) { /* encode and save */ }
private var allTriggers: [String] { triggers + customTriggers }
```

#### Step 2b: Modify `step3Triggers` UI

**File:** `ios/.../Views/Activities/UrgeLogView.swift` (lines 159-198)

- Use `allTriggers` instead of `triggers` in the `FlowLayout`
- Add a "+" pill button at the end that toggles `showCustomTriggerField`
- When shown, display `TextField` with "Add custom trigger..." placeholder and confirm button
- On confirm: save to `@AppStorage`, add to `selectedTriggers`, clear field, hide input

#### Step 2c: Update `EmergencyOverlayView`

**File:** `ios/.../Views/Emergency/EmergencyOverlayView.swift` (lines 389-418)

Add same `@AppStorage("customUrgeLogTriggers")` integration so custom triggers appear in the emergency overlay's urge logging sheet.

### Change 3: Log Urge Should Dismiss

#### Step 3a: Add dismiss environment

**File:** `ios/.../Views/Activities/UrgeLogView.swift`

```swift
@Environment(\.dismiss) private var dismiss
```

#### Step 3b: Update `submitUrge()`

After `modelContext.insert(entry)`, add:
```swift
try? modelContext.save()
dismiss()
```

This matches the pattern used by `MorningCommitmentView`, `EveningReviewView`, `FANOSCheckInView`, and other activity views that dismiss after logging.

### Change 4: Update Tests

**File:** `ios/.../Tests/Unit/UrgeLogViewModelTests.swift`

- Update all `vm.selectedAddiction = "..."` to `vm.selectedAddictions = ["..."]`
- Update assertions checking `.addiction` to `.addictions`
- Add test for multi-select submission
- Add test for empty addictions validation

## Implementation Order

1. Model change (`RRModels.swift` — addictionId → addictionIds)
2. Seed data updates
3. ViewModel updates (`UrgeLogViewModel.swift`)
4. Tests
5. View: multi-select (`UrgeLogView.swift` step2)
6. View: custom triggers (`UrgeLogView.swift` step3)
7. View: dismiss (`UrgeLogView.swift` submitUrge)
8. Emergency overlay triggers
9. Activity detail display (optional)

## Files Modified Summary

| File | Change |
|------|--------|
| `Data/Models/RRModels.swift` | `addictionId` → `addictionIdsJSON` + computed `addictionIds` |
| `Views/Activities/UrgeLogView.swift` | Multi-select addictions, custom trigger entry, dismiss on submit |
| `ViewModels/UrgeLogViewModel.swift` | `selectedAddiction` → `selectedAddictions`, `UrgeEntry.addictions` |
| `Views/Emergency/EmergencyOverlayView.swift` | Custom triggers in emergency overlay |
| `Models/SeedData.swift` | Use `addictionIds: [...]` |
| `Models/SeedPersonaData.swift` | Use `addictionIds: [...]` |
| `Tests/Unit/UrgeLogViewModelTests.swift` | Update for multi-select API |

## Risks

- **SwiftData migration:** Adding `addictionIdsJSON` and removing `addictionId` is a schema change. Keep old field as deprecated for backward compat.
- **UserDefaults for custom triggers** is appropriate for lightweight data; future sync would need SwiftData model.
