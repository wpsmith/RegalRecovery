# Task 7: FAB Breathing Layout & Urge Log Flow

## Part A: Breathing Exercise Layout Fixes

### A1: Better spacing above words for circle growth

**File:** `ios/.../Views/Emergency/BreathingExerciseView.swift`

The circle scales to 1.8x its 180pt base = 324pt diameter, but the ZStack doesn't reserve space for it. The text overlaps when the circle grows.

**Fix:** Set the ZStack frame to accommodate max circle size:
```swift
ZStack {
    Circle() ...  // 240pt outer ring
    Circle() ...  // 180pt, scaleEffect to 1.8x
    // Phase text overlay
}
.frame(width: 330, height: 330) // 180 * 1.8 = 324, rounded up
```

### A2: Centralize content on the screen

**File:** `ios/.../Views/Emergency/BreathingExerciseView.swift` (lines 38-128)

Current layout gravitates to top. Restructure to center:

```swift
var body: some View {
    ZStack(alignment: .topTrailing) {
        VStack(spacing: 24) {
            Spacer()
            // Circle animation area
            ZStack { ... }
            .frame(width: 330, height: 330)
            // Phase/completion/intro text
            ...
            Spacer()
            // Action button
            ...
        }
        .padding()

        // Close button (overlay, outside VStack flow)
        Button { dismiss() } label: { ... }
            .padding(.top, 16)
            .padding(.trailing, 16)
    }
    .background(Color.rrBackground.ignoresSafeArea())
}
```

### A3: Done should automatically close

**File:** `ios/.../Views/Emergency/BreathingExerciseView.swift`

**Line 117:** Change `resetExercise()` to `dismiss()`:
```swift
} else if isComplete {
    RRButton("Done", icon: "checkmark") {
        dismiss()
    }
}
```

Also add auto-dismiss after completion in `tick()` (lines 193-198):
```swift
if cycleCount >= totalCycles {
    timerCancellable?.cancel()
    isComplete = true
    isRunning = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        dismiss()
    }
    return
}
```

---

## Part B: FAB Dismiss Should Show Urge in Today's Activity Log

### Approach: NotificationCenter-based communication

The FAB is at the app level (`RegalRecoveryApp.swift` lines 73-78), while TodayView is inside the TabView. Use notifications to bridge them.

### Step B1: Define notification

```swift
extension Notification.Name {
    static let emergencyDismissed = Notification.Name("emergencyDismissed")
}
```

### Step B2: Post notification from emergency views

**File:** `ios/.../Views/Emergency/UrgeSurfingTimerView.swift`

- **X button** (line 124-135): Post notification with `userInfo: ["reason": "closedByUser"]`
- **"I'm okay now" button** (lines 283-298): Post notification with `userInfo: ["reason": "okayNow"]`

**File:** `ios/.../Views/Emergency/EmergencyOverlayView.swift`

- **X dismiss button** (lines 122-133): Post notification with `userInfo: ["reason": "closedByUser"]`

### Step B3: Listen in TodayView

**File:** `ios/.../Views/Today/TodayView.swift`

```swift
.onReceive(NotificationCenter.default.publisher(for: .emergencyDismissed)) { _ in
    viewModel.load(context: modelContext)
}
```

This re-queries `RRUrgeLog` from SwiftData, and any urge auto-logged by the emergency views will appear immediately.

---

## Part C: After "I'm okay now", Launch Urge Log Activity

### Step C1: Add state for UrgeLogView sheet

**File:** `ios/.../RegalRecoveryApp.swift`

```swift
@State private var showUrgeLogAfterDismiss = false
```

### Step C2: Handle notification at app level

```swift
.onReceive(NotificationCenter.default.publisher(for: .emergencyDismissed)) { notification in
    if let reason = notification.userInfo?["reason"] as? String, reason == "okayNow" {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showUrgeLogAfterDismiss = true
        }
    }
}
```

### Step C3: Add UrgeLog sheet

```swift
.sheet(isPresented: $showUrgeLogAfterDismiss) {
    NavigationStack {
        UrgeLogView()
            .navigationTitle("Log Urge")
            .navigationBarTitleDisplayMode(.inline)
    }
}
```

Place after existing `.fullScreenCover` modifiers.

---

## Files Modified Summary

| File | Changes |
|------|--------|
| `BreathingExerciseView.swift` | Reserve space for circle growth; center content with Spacers; auto-dismiss on Done |
| `RegalRecoveryApp.swift` | Add notification name; add `showUrgeLogAfterDismiss` state; handle notification; add UrgeLog sheet |
| `UrgeSurfingTimerView.swift` | Post notification with reason from X and "I'm okay now" buttons |
| `EmergencyOverlayView.swift` | Post notification with reason from X button |
| `TodayView.swift` | Listen for `emergencyDismissed` notification to reload activity log |

## Critical Files

- `ios/.../Views/Emergency/BreathingExerciseView.swift`
- `ios/.../RegalRecoveryApp.swift`
- `ios/.../Views/Emergency/UrgeSurfingTimerView.swift`
- `ios/.../Views/Emergency/EmergencyOverlayView.swift`
- `ios/.../Views/Today/TodayView.swift`
