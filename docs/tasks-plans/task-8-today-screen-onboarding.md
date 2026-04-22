# Task 8: Today Screen Conditional Onboarding Flow

## Overview

The Today screen needs a three-state conditional layout based on the user's setup progress:

| State | Condition | Displayed Content |
|-------|-----------|-------------------|
| **Step 1: No Addictions** | `RRAddiction` table is empty | Addiction selector only (full screen, nothing else) |
| **Step 2: Has Addictions, No Plan** | `RRAddiction` has records, but no active plan | Hello greeting, "Setup My Plan" CTA, Quick Actions, Today's Activity Log, FAB |
| **Step 3: Full Plan** | Has addictions AND active plan | Current `planContent` (unchanged) |

## Current State

- **TodayView** (`ios/.../Views/Today/TodayView.swift`) has two states: `hasPlan` (full content) vs `!hasPlan` (empty state CTA).
- **TodayViewModel** loads addictions via `loadSobriety()` and plan items via `loadPlanItems()`, but has no concept of "has addictions selected" as a gating condition.
- **AddictionManagementView** (`ios/.../Views/Settings/AddictionManagementView.swift`) is a full settings-style view with reorder/delete — not suitable for inline first-time setup.
- **EmergencyFABButton** lives in `RegalRecoveryApp.swift` at the tab level (line 73), so it appears in all states automatically.

## Step-by-Step Implementation

### Step A: Add `hasAddictions` state to TodayViewModel

**File:** `ios/.../ViewModels/TodayViewModel.swift`

1. Add new published property (~line 58):
   ```swift
   var hasAddictions: Bool = false
   ```

2. Add new method:
   ```swift
   private func loadAddictions(context: ModelContext) {
       let descriptor = FetchDescriptor<RRAddiction>()
       let addictions = (try? context.fetch(descriptor)) ?? []
       hasAddictions = !addictions.isEmpty
   }
   ```

3. Call `loadAddictions` at the beginning of `load(context:)` (line 70), before `loadUser`.

### Step B: Create Inline Addiction Selector View (NEW FILE)

**New File:** `ios/.../Views/Today/AddictionSelectorView.swift`

Streamlined first-time addiction picker (not the full settings `AddictionManagementView`):
- Title: "What are you recovering from?"
- Multi-select grid of addiction types (same list as `AddAddictionSheet` lines 205-251)
- Sobriety date picker per addiction (or shared date)
- "Save & Continue" button — requires at least one addiction + sobriety date
- Takes `onSave: () -> Void` closure to trigger `viewModel.load()` in parent

```swift
struct AddictionSelectorView: View {
    let onSave: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    
    @State private var selectedAddictions: Set<String> = []
    @State private var sobrietyDates: [String: Date] = [:]
    @State private var sharedSobrietyDate = Date()
    
    // Uses same addiction type lists as AddAddictionSheet
}
```

On save: creates `RRAddiction` and `RRStreak` records (pattern from `RecoverySetupView.completeSetup()` line 131).

### Step C: Create "Setup My Plan" CTA Card (NEW FILE)

**New File:** `ios/.../Views/Today/SetupMyPlanCard.swift`

Prominent card for Step 2 state using existing `RRCard` component:

```swift
struct SetupMyPlanCard: View {
    var body: some View {
        NavigationLink {
            RecoveryPlanSetupView()
        } label: {
            RRCard {
                HStack(spacing: 14) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Setup My Plan")
                            .font(RRFont.headline)
                        Text("Create your daily recovery plan")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
```

### Step D: Modify TodayView for Three-State Conditional Layout

**File:** `ios/.../Views/Today/TodayView.swift`

Replace the two-state `body` Group (lines 41-47):

```swift
Group {
    if !viewModel.hasAddictions {
        addictionSelectorState
    } else if !viewModel.hasPlan {
        noPlanState
    } else {
        planContent
    }
}
```

Add new computed properties:

```swift
private var addictionSelectorState: some View {
    AddictionSelectorView {
        viewModel.load(context: modelContext)
    }
}

private var noPlanState: some View {
    ScrollView {
        VStack(spacing: 16) {
            greetingHeader          // "Good Morning" etc.
            SetupMyPlanCard()       // CTA immediately below greeting
            quickActions            // Quick Actions row
            todayActivityLogSection // Today's Activity Log
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
```

Conditionally hide toolbar in Step 1:
```swift
.toolbar {
    if viewModel.hasAddictions {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink { RecoveryPlanSetupView() } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(Color.rrPrimary)
            }
        }
    }
}
```

### Step E: Remove Old `emptyState`

**File:** `ios/.../Views/Today/TodayView.swift` (lines 367-400)

Delete the old `emptyState` computed property — its role is now split between `addictionSelectorState` (Step 1) and `noPlanState` (Step 2).

### Step F: Conditionally Hide Streak Badge in Step 2

**File:** `ios/.../Views/Today/TodayView.swift` — in `greetingHeader`:

```swift
if viewModel.hasPlan {
    RRBadge(text: "Day \(viewModel.streakDays)", color: .rrPrimary)
}
```

## State Transitions

**Step 1 → Step 2:** `AddictionSelectorView` saves and calls `onSave()` → `viewModel.load()` → `hasAddictions = true`, `hasPlan = false` → renders `noPlanState`.

**Step 2 → Step 3:** User navigates to `RecoveryPlanSetupView` from "Setup My Plan" card → saves plan → pops back → `onAppear` fires `viewModel.load()` → `hasPlan = true` → renders `planContent`.

**Reverse (delete all addictions):** If user deletes all addictions in Settings, next `onAppear` → `hasAddictions = false` → Step 1 shows. Correct behavior.

## Files Summary

### New Files
| File | Purpose |
|------|---------|
| `ios/.../Views/Today/AddictionSelectorView.swift` | Inline addiction selection for Step 1 |
| `ios/.../Views/Today/SetupMyPlanCard.swift` | "Setup My Plan" CTA card for Step 2 |

### Modified Files
| File | Changes |
|------|---------|
| `ios/.../ViewModels/TodayViewModel.swift` | Add `hasAddictions` property, `loadAddictions()` method |
| `ios/.../Views/Today/TodayView.swift` | Three-state conditional; add `addictionSelectorState`, `noPlanState`; remove `emptyState`; conditional toolbar/badge |

### Unchanged Files
- **`RegalRecoveryApp.swift`** — FAB already at app level
- **`AddictionManagementView.swift`** — Settings view, not modified
- **Backend/API files** — Not modified

## Edge Cases
1. **"Skip to Demo" onboarding** — may have no `RRUser` record. `AddictionSelectorView` should use fallback `UUID()` for `userId`.
2. **Empty activity log in Step 2** — `todayActivityLogSection` already handles empty state.
3. **Query reactivity** — SwiftData does not auto-trigger `@Observable` reload; explicit `onSave` closure pattern handles this.
