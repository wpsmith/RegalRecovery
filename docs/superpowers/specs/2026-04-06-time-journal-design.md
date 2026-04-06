# Time Journal (T-30/T-60) -- iOS Design Specification

**Date:** 2026-04-06
**Scope:** Core Time Journal feature: data model, daily journal view, quick entry, Today screen integration, Recovery Work integration, sleep auto-fill
**PRD Reference:** `docs/prd/specific-features/TimeJournal/prd.md` (TJ-001 through TJ-085)
**Deferred:** Partner sharing/access (TJ-021 through TJ-028), weekly/monthly heatmap (TJ-032), calendar import (TJ-014), wearable integration (TJ-040), PDF export (TJ-028), acting-out correlations (TJ-044 P2), emotion re-evaluation (TJ-045), confession assist (TJ-049), screenshot prevention (TJ-054)

---

## 1. Data Model

### 1.1 TimeJournalMode Enum

Controls slot granularity. Persisted as a user preference.

```swift
enum TimeJournalMode: String, Codable, CaseIterable {
    case t30   // 48 slots per day (every 30 minutes)
    case t60   // 24 slots per day (every 60 minutes)

    var slotsPerDay: Int {
        switch self {
        case .t30: return 48
        case .t60: return 24
        }
    }

    var intervalMinutes: Int {
        switch self {
        case .t30: return 30
        case .t60: return 60
        }
    }

    var displayName: String {
        switch self {
        case .t30: return "T-30 (every 30 min)"
        case .t60: return "T-60 (every 60 min)"
        }
    }

    /// Returns the slot index (0-based) for a given hour and minute.
    func slotIndex(hour: Int, minute: Int) -> Int {
        switch self {
        case .t30: return hour * 2 + (minute >= 30 ? 1 : 0)
        case .t60: return hour
        }
    }

    /// Returns the start hour and minute for a given slot index.
    func slotStartTime(index: Int) -> (hour: Int, minute: Int) {
        switch self {
        case .t30: return (hour: index / 2, minute: (index % 2) * 30)
        case .t60: return (hour: index, minute: 0)
        }
    }

    /// Returns a display label for a slot, e.g. "2:00 PM" or "2:30 PM".
    func slotLabel(index: Int) -> String {
        let (hour, minute) = slotStartTime(index: index)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    /// The index of the final slot in the day.
    var finalSlotIndex: Int { slotsPerDay - 1 }
}
```

### 1.2 TimeJournalSlotStatus Enum

Visual and logical status for each time slot in the daily view.

```swift
enum TimeJournalSlotStatus: String, Codable {
    case empty          // No entry exists for this slot
    case filled         // Manually entered in real-time
    case retroactive    // Filled after the slot's time period elapsed (TJ-011)
    case autoFilled     // System-generated entry, e.g. sleep auto-fill (TJ-082)
    case flagged        // Marked with extras/flags (TJ-006)

    var color: Color {
        switch self {
        case .empty:       return .gray.opacity(0.3)
        case .filled:      return .rrPrimary
        case .retroactive: return .rrSecondary.opacity(0.7)
        case .autoFilled:  return .blue.opacity(0.5)
        case .flagged:     return .orange
        }
    }

    /// Border style for slot card rendering (TJ-016).
    var useDashedBorder: Bool {
        self == .retroactive
    }

    var accessibilityLabel: String {
        switch self {
        case .empty:       return "Empty slot"
        case .filled:      return "Filled"
        case .retroactive: return "Filled retroactively"
        case .autoFilled:  return "Auto-filled"
        case .flagged:     return "Flagged entry"
        }
    }
}
```

### 1.3 TimeJournalDayStatus Enum

Day-level status derived from scanning all slots. Shared by Today screen (TJ-065) and Recovery Work (TJ-071).

```swift
enum TimeJournalDayStatus: String {
    case inProgress  // Default; no overdue slots
    case overdue     // At least one elapsed slot is unfilled
    case completed   // Every slot filled, including final slot after its period elapsed

    var label: String {
        switch self {
        case .inProgress: return "In Progress"
        case .overdue:    return "Overdue"
        case .completed:  return "Completed"
        }
    }

    var color: Color {
        switch self {
        case .inProgress: return .blue
        case .overdue:    return .orange
        case .completed:  return .rrSuccess
        }
    }

    /// Maps to WorkStatus for Recovery Work integration (TJ-071).
    var workStatus: WorkStatus {
        switch self {
        case .inProgress: return .inProgress
        case .overdue:    return .overdue
        case .completed:  return .completed
        }
    }

    /// Status evaluation algorithm (TJ-060 through TJ-064).
    ///
    /// Scans all slots from midnight through the current time:
    /// 1. A slot is "elapsed" when the full time period it represents has passed.
    ///    - T-60: slot 11 (11:00 AM) is elapsed at 12:00 PM.
    ///    - T-30: slot 23 (11:30 AM) is elapsed at 12:00 PM.
    /// 2. If ANY elapsed slot is unfilled, status = `.overdue` -- even if later slots are filled.
    /// 3. Status = `.completed` only when EVERY slot in the day (including the final slot) is
    ///    filled AND the final slot's period has elapsed.
    /// 4. Otherwise, status = `.inProgress`.
    ///
    /// The final slot:
    /// - T-60: index 23 (11:00 PM), elapsed at midnight.
    /// - T-30: index 47 (11:30 PM), elapsed at midnight.
    static func evaluate(
        entries: [RRTimeJournalEntry],
        mode: TimeJournalMode,
        now: Date = Date(),
        forDate: Date
    ) -> TimeJournalDayStatus {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: forDate)

        // Build a set of filled slot indexes
        let filledSlots = Set(entries.map { $0.slotIndex })

        // Determine the current elapsed boundary
        let secondsSinceDayStart = now.timeIntervalSince(dayStart)
        let minutesSinceDayStart = Int(secondsSinceDayStart / 60)

        // A slot is elapsed when its END time has passed
        // Slot N covers [N * interval, (N+1) * interval) minutes
        // It is elapsed when minutesSinceDayStart >= (N+1) * interval
        let interval = mode.intervalMinutes
        let totalSlots = mode.slotsPerDay

        // How many slots have fully elapsed?
        let elapsedSlotCount = min(totalSlots, minutesSinceDayStart / interval)

        // Check if any elapsed slot is unfilled
        for slotIndex in 0..<elapsedSlotCount {
            if !filledSlots.contains(slotIndex) {
                return .overdue
            }
        }

        // Check for completion: all slots filled AND final slot elapsed
        let allSlotsFilled = filledSlots.count == totalSlots
        let finalSlotElapsed = elapsedSlotCount == totalSlots

        if allSlotsFilled && finalSlotElapsed {
            return .completed
        }

        return .inProgress
    }
}
```

### 1.4 RRTimeJournalEntry SwiftData Model

Replaces the existing `RRTimeBlock` model with full PRD field coverage.

```swift
@Model
final class RRTimeJournalEntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date                          // Calendar date this slot belongs to
    var slotIndex: Int                      // 0-based slot index (TJ-001)
    var mode: String                        // "t30" or "t60" (TimeJournalMode raw value)

    // Location (TJ-002)
    var locationLabel: String               // Free-text or quick-select label ("@home", "@work")
    var latitude: Double?                   // GPS latitude (auto-captured)
    var longitude: Double?                  // GPS longitude (auto-captured)
    var locationAddress: String?            // Reverse-geocoded address from Apple POI
    var locationAccuracyMeters: Double?     // CLLocation horizontal accuracy

    // Activity (TJ-003)
    var activity: String                    // Free-text description, multi-line supported

    // People (TJ-004)
    var peopleJSON: String?                 // JSON-encoded array of PersonEntry
    // PersonEntry: { "name": String, "gender": String? }

    // Emotions (TJ-005)
    var emotionsJSON: String?               // JSON-encoded array of EmotionEntry
    // EmotionEntry: { "name": String, "category": String, "intensity": Int (1-10) }

    // Extras/Flags (TJ-006)
    var extrasJSON: String?                 // JSON-encoded dictionary of optional structured fields
    var isFlagged: Bool                     // Whether this entry has been flagged (TJ-006)

    // Sleep (TJ-008)
    var isSleep: Bool                       // Marked as sleeping

    // Entry metadata
    var isRetroactive: Bool                 // Filled after the slot period elapsed (TJ-011)
    var retroactiveFilledAt: Date?          // Timestamp when retroactive entry was saved
    var isAutoFilled: Bool                  // System-generated (e.g. sleep auto-fill, TJ-082)
    var autoFillAttribution: String?        // e.g. "Sleep Focus detected" (TJ-082)

    // Redline (TJ-048, P1)
    var redlineNote: String?                // Confidential note NOT shared with Trust Partners

    // Standard timestamps
    var synced: Bool
    var createdAt: Date
    var modifiedAt: Date

    // MARK: - Computed

    /// Decoded people array
    var people: [PersonEntry] {
        get {
            guard let json = peopleJSON,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([PersonEntry].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                peopleJSON = json
            }
        }
    }

    /// Decoded emotions array
    var emotions: [EmotionEntry] {
        get {
            guard let json = emotionsJSON,
                  let data = json.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([EmotionEntry].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                emotionsJSON = json
            }
        }
    }

    /// Slot status for UI rendering (TJ-016)
    var slotStatus: TimeJournalSlotStatus {
        if isFlagged { return .flagged }
        if isAutoFilled { return .autoFilled }
        if isRetroactive { return .retroactive }
        return .filled
    }

    /// Whether this entry is still editable (TJ-017: entries uneditable after 24hrs)
    var isEditable: Bool {
        Date().timeIntervalSince(createdAt) < 24 * 60 * 60
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        slotIndex: Int,
        mode: String,
        locationLabel: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationAddress: String? = nil,
        locationAccuracyMeters: Double? = nil,
        activity: String = "",
        peopleJSON: String? = nil,
        emotionsJSON: String? = nil,
        extrasJSON: String? = nil,
        isFlagged: Bool = false,
        isSleep: Bool = false,
        isRetroactive: Bool = false,
        retroactiveFilledAt: Date? = nil,
        isAutoFilled: Bool = false,
        autoFillAttribution: String? = nil,
        redlineNote: String? = nil,
        synced: Bool = false,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.slotIndex = slotIndex
        self.mode = mode
        self.locationLabel = locationLabel
        self.latitude = latitude
        self.longitude = longitude
        self.locationAddress = locationAddress
        self.locationAccuracyMeters = locationAccuracyMeters
        self.activity = activity
        self.peopleJSON = peopleJSON
        self.emotionsJSON = emotionsJSON
        self.extrasJSON = extrasJSON
        self.isFlagged = isFlagged
        self.isSleep = isSleep
        self.isRetroactive = isRetroactive
        self.retroactiveFilledAt = retroactiveFilledAt
        self.isAutoFilled = isAutoFilled
        self.autoFillAttribution = autoFillAttribution
        self.redlineNote = redlineNote
        self.synced = synced
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
```

### 1.5 Supporting Codable Types

```swift
struct PersonEntry: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var gender: String?     // "male", "female", "other", nil
}

struct EmotionEntry: Codable, Equatable, Identifiable {
    var id: UUID = UUID()
    var name: String        // e.g. "Anxious"
    var category: String    // e.g. "Fearful" (primary emotion category)
    var intensity: Int      // 1-10 (TJ-042)
    var context: String?    // Optional "why" prompt (TJ-043, P1)
}
```

### 1.6 Emotion Catalog

A static catalog of 40+ emotions grouped by primary category. Includes the "three I's" (insignificance, incompetence, impotence) as a recovery-specific group (TJ-005, TJ-041).

| Primary Category | Emotions |
|-----------------|----------|
| **Happy** | Joyful, Grateful, Content, Peaceful, Hopeful, Proud, Relieved, Playful |
| **Sad** | Lonely, Grieving, Disappointed, Hopeless, Ashamed, Empty, Melancholic, Homesick |
| **Angry** | Frustrated, Resentful, Irritated, Bitter, Jealous, Betrayed, Enraged, Disgusted |
| **Fearful** | Anxious, Insecure, Overwhelmed, Vulnerable, Panicked, Worried, Terrified, Dread |
| **Shame** | Guilty, Humiliated, Embarrassed, Unworthy, Exposed, Self-loathing |
| **The Three I's** | Insignificant, Incompetent, Impotent |
| **Numb** | Disconnected, Flat, Apathetic, Foggy, Exhausted, Dissociated |
| **Surprise** | Shocked, Confused, Amazed, Startled, Curious |
| **Connected** | Loved, Accepted, Seen, Understood, Safe, Belonging |

Implementation as a static struct:

```swift
struct EmotionCatalog {
    struct Category: Identifiable {
        let id: String          // raw key
        let name: String        // display name
        let color: Color
        let emotions: [String]
    }

    static let categories: [Category] = [
        Category(id: "happy", name: "Happy", color: .yellow, emotions: [
            "Joyful", "Grateful", "Content", "Peaceful", "Hopeful", "Proud", "Relieved", "Playful"
        ]),
        Category(id: "sad", name: "Sad", color: .blue, emotions: [
            "Lonely", "Grieving", "Disappointed", "Hopeless", "Ashamed", "Empty", "Melancholic", "Homesick"
        ]),
        Category(id: "angry", name: "Angry", color: .red, emotions: [
            "Frustrated", "Resentful", "Irritated", "Bitter", "Jealous", "Betrayed", "Enraged", "Disgusted"
        ]),
        Category(id: "fearful", name: "Fearful", color: .purple, emotions: [
            "Anxious", "Insecure", "Overwhelmed", "Vulnerable", "Panicked", "Worried", "Terrified", "Dread"
        ]),
        Category(id: "shame", name: "Shame", color: Color(red: 0.55, green: 0.27, blue: 0.07), emotions: [
            "Guilty", "Humiliated", "Embarrassed", "Unworthy", "Exposed", "Self-loathing"
        ]),
        Category(id: "threeIs", name: "The Three I's", color: .rrDestructive, emotions: [
            "Insignificant", "Incompetent", "Impotent"
        ]),
        Category(id: "numb", name: "Numb", color: .gray, emotions: [
            "Disconnected", "Flat", "Apathetic", "Foggy", "Exhausted", "Dissociated"
        ]),
        Category(id: "surprise", name: "Surprise", color: .orange, emotions: [
            "Shocked", "Confused", "Amazed", "Startled", "Curious"
        ]),
        Category(id: "connected", name: "Connected", color: .rrSuccess, emotions: [
            "Loved", "Accepted", "Seen", "Understood", "Safe", "Belonging"
        ]),
    ]

    /// Flat list of all emotion names for search/autocomplete.
    static var allEmotions: [String] {
        categories.flatMap(\.emotions)
    }

    /// Lookup the category for a given emotion name.
    static func category(for emotion: String) -> Category? {
        categories.first { $0.emotions.contains(emotion) }
    }
}
```

---

## 2. UI Flow & Architecture

### 2.1 Daily Journal View (TJ-015 through TJ-020)

The primary view for a single day's Time Journal. Displays a 24-hour timeline with all slots.

**Layout:**
- **Header:** Date navigation (left/right arrows, date label), completion ring showing % filled (TJ-018), day status badge
- **Timeline:** Vertical scrollable list of slot cards. Each card shows the time label, a colored status indicator, and a summary of the entry (location, activity, top emotion). Unfilled slots show a "+" tap target.
- **Emotion Graph (P1):** Horizontal line chart below the timeline showing emotion intensity across the day (TJ-019). X-axis = time slots, Y-axis = max intensity for the slot. Color-coded by primary emotion category.
- **Floating Action Button:** Opens the Quick Entry Sheet for the current time slot.

**Color coding per slot status (TJ-016):**

| Status | Background | Border | Badge |
|--------|-----------|--------|-------|
| Empty (past) | Gray 30% opacity | Solid gray | -- |
| Empty (future) | Clear | Dotted gray | -- |
| Filled | `rrPrimary` tint | Solid | -- |
| Retroactive | `rrSecondary` 70% | Dashed border | "Late" chip |
| Auto-filled | Blue 50% | Solid | "Auto" chip |
| Flagged | Orange tint | Solid | Flag icon |

**Slot card content (filled):**
- Time label (e.g. "2:00 PM")
- Location label (truncated, e.g. "@work")
- Activity (first line, truncated)
- Emotion pills (up to 3, with intensity dot)
- People count badge if > 0

**Tap behavior (TJ-017):**
- Tapping a filled slot opens the Quick Entry Sheet pre-populated for editing. Entries older than 24 hours are displayed read-only.
- Tapping an empty slot opens the Quick Entry Sheet for that slot. If the slot's time period has elapsed, the entry is automatically marked as retroactive.

### 2.2 Quick Entry Card (TJ-010)

A half-sheet (`presentationDetents([.medium, .large])`) optimized for the 3-tap minimum flow. Expandable for full detail.

**Minimal flow (3 taps, < 30 seconds):**
1. **Location** -- Quick-select row of recent/saved location chips ("@home", "@work", "@church", "@gym"). Tap one to select. "Other..." opens free-text field. GPS coordinates captured automatically in background. Carry-forward (TJ-013): if location matches the previous slot, pre-filled.
2. **Activity** -- Text field with mic button for voice-to-text (TJ-012, P1). Placeholder: "What were you doing?"
3. **Emotion** -- Horizontal scroll of emotion category pills. Tap a category to expand into specific emotions. Tap an emotion to select with default intensity 5. Done.

**Expanded detail (pull sheet to .large):**
- Intensity slider per selected emotion (1-10)
- People field: tag-style input with name + optional gender. Activity field scanned for keywords ("meeting", "lunch", "call") to prompt "Who was there?"
- "Why" context field per emotion (TJ-043, P1)
- Extras/flags toggle section (TJ-006, P1)
- Sleep toggle (TJ-008)
- Redline note (TJ-048, P1): expandable section labeled "Private note (not shared)"

**Save behavior:**
- "Save" button enabled when location and activity are non-empty.
- Automatically determines `isRetroactive` based on whether the slot's time period has elapsed.
- GPS coordinates and reverse-geocoded address captured asynchronously; entry saves immediately with label, coordinates backfilled.

### 2.3 Today Screen Integration (TJ-065 through TJ-068)

A dedicated `TimeJournalTodayCard` view displayed at the top of the Today screen plan items list when the Time Journal is in the user's Recovery Plan and `activity.time-journal` feature flag is enabled (TJ-074).

**Card layout:**
- **Left:** Clock icon in purple circle
- **Title:** "Time Journal (T-30)" or "Time Journal (T-60)"
- **Status badge:** Colored pill showing `TimeJournalDayStatus.label` (TJ-060-064)
- **Progress bar:** Horizontal bar beneath the title showing `filledCount / totalSlots` (TJ-066). Uses `rrPrimary` fill for filled portion, gray for remaining.
- **Subtitle:** "Last updated 11:32 AM" (TJ-067) or "No entries yet today" if empty
- **Tap:** Navigates to `TimeJournalDailyView` for today (TJ-068)
- **Chevron:** Right-facing disclosure indicator

### 2.4 Recovery Work Integration (TJ-069 through TJ-076)

The Time Journal generates a `RecoveryWorkItem` daily, visible on the Recovery Work screen.

**Work item generation:**
- `activityType`: `"timeJournal"`
- `title`: "Time Journal"
- `icon`: `"clock.fill"`, `iconColor`: `.purple`
- `priority`: `.high` (daily accountability tool)
- `status`: Derived from `TimeJournalDayStatus.evaluate().workStatus` (TJ-071). Never uses `.notStarted`; begins as `.inProgress` at midnight.
- `triggerReason`: Dynamic summary (TJ-072):
  - In Progress: `"14 of 24 slots filled -- Last updated 2:32 PM"`
  - Overdue: `"3 overdue slots -- Last updated 11:05 AM"`
  - Completed: `"All 24 slots filled"`
- `dueDate`: End of current day

**Row enhancement (TJ-075, P1):**
- `RecoveryWorkItemRow` for the Time Journal includes a slim progress bar beneath the title, consistent with `TimeJournalTodayCard`.

**Tap navigation (TJ-073):**
- Tapping the work item or "Start" button navigates to `TimeJournalDailyView` for today.

**Historical completion (TJ-076, P1):**
- Completed Time Journal work items appear in the "Completed" section: "100% -- April 5, 2026". Items older than 7 days are archived.

### 2.5 Sleep Auto-Fill (TJ-080 through TJ-085)

Integrates with iOS Focus API to automatically fill overnight slots.

**FocusStatusMonitor:**
- Uses `FocusStatus` from the `ManagedSettings` framework (iOS 16+) to detect when the device enters/exits "Sleep" Focus mode.
- Observes `FocusStatusCenter.default` for authorization and state changes.
- Records `sleepStartedAt` and `sleepEndedAt` timestamps.

**Auto-fill logic (TJ-081, TJ-084):**
- On Sleep Focus exit, determine all time slots whose entire duration falls within `[sleepStartedAt, sleepEndedAt]`.
- Partial overlaps are NOT auto-filled (TJ-084). Only slots where `slotStart >= sleepStartedAt AND slotEnd <= sleepEndedAt`.
- For each qualifying slot, create an `RRTimeJournalEntry` with:
  - `activity`: "Sleep"
  - `isSleep`: true
  - `isAutoFilled`: true
  - `autoFillAttribution`: "Auto -- Sleep Focus detected"
  - `locationLabel`: Carried forward from last manually entered slot
  - `emotionsJSON`: nil (left empty per TJ-081)

**Editability (TJ-083):**
- Auto-filled entries are fully editable. When the user modifies any field, `isAutoFilled` is set to `false` and `autoFillAttribution` is cleared.

**Background processing:**
- Sleep auto-fill runs via `BGAppRefreshTask` or on app foreground after a Sleep Focus window closes.
- If the app was terminated during sleep, the monitor reconstructs the window from `FocusStatusCenter` history on next launch.

---

## 3. ViewModel Architecture

### 3.1 TimeJournalViewModel

Primary orchestrator for the daily journal view. One instance per visible day.

```swift
@Observable
class TimeJournalViewModel {

    // MARK: - State

    var entries: [RRTimeJournalEntry] = []
    var currentDate: Date = Calendar.current.startOfDay(for: Date())
    var mode: TimeJournalMode = .t60
    var isLoading = false
    var error: String?

    // MARK: - Computed (Status Engine: TJ-060 through TJ-064)

    var dayStatus: TimeJournalDayStatus {
        TimeJournalDayStatus.evaluate(
            entries: entries,
            mode: mode,
            now: Date(),
            forDate: currentDate
        )
    }

    var filledCount: Int {
        entries.count
    }

    var totalSlots: Int {
        mode.slotsPerDay
    }

    var completionPercent: Double {
        guard totalSlots > 0 else { return 0 }
        return Double(filledCount) / Double(totalSlots)
    }

    var overdueCount: Int {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: currentDate)
        let minutesElapsed = Int(Date().timeIntervalSince(dayStart) / 60)
        let elapsedSlotCount = min(totalSlots, minutesElapsed / mode.intervalMinutes)
        let filledSlots = Set(entries.map(\.slotIndex))
        return (0..<elapsedSlotCount).filter { !filledSlots.contains($0) }.count
    }

    var lastUpdated: Date? {
        entries.map(\.modifiedAt).max()
    }

    /// Trigger reason string for Recovery Work integration (TJ-072).
    var triggerReason: String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"

        switch dayStatus {
        case .completed:
            return "All \(totalSlots) slots filled"
        case .overdue:
            let lastStr = lastUpdated.map { "Last updated \(timeFormatter.string(from: $0))" } ?? "No entries yet"
            return "\(overdueCount) overdue slot\(overdueCount == 1 ? "" : "s") -- \(lastStr)"
        case .inProgress:
            let lastStr = lastUpdated.map { "Last updated \(timeFormatter.string(from: $0))" } ?? "No entries yet"
            return "\(filledCount) of \(totalSlots) slots filled -- \(lastStr)"
        }
    }

    // MARK: - Slot Helpers

    /// Returns the entry for a given slot index, or nil if empty.
    func entry(for slotIndex: Int) -> RRTimeJournalEntry? {
        entries.first { $0.slotIndex == slotIndex }
    }

    /// Returns the status for a given slot index.
    func slotStatus(for slotIndex: Int) -> TimeJournalSlotStatus {
        guard let entry = entry(for: slotIndex) else {
            return .empty
        }
        return entry.slotStatus
    }

    /// Whether a given slot's time period has fully elapsed.
    func isSlotElapsed(_ slotIndex: Int) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: currentDate)
        let slotEndMinutes = (slotIndex + 1) * mode.intervalMinutes
        let slotEndDate = dayStart.addingTimeInterval(TimeInterval(slotEndMinutes * 60))
        return Date() >= slotEndDate
    }

    // MARK: - Actions

    func loadDay(date: Date) async { ... }
    func saveEntry(_ entry: RRTimeJournalEntry) async { ... }
    func deleteEntry(_ entry: RRTimeJournalEntry) async { ... }
    func navigateDay(offset: Int) async { ... }
    func fillSleepSlots(from: Date, to: Date) async { ... }
    func changeMode(_ newMode: TimeJournalMode) async { ... }
}
```

### 3.2 TimeJournalEntryViewModel

Manages the state for the Quick Entry Sheet (creating or editing a single entry).

```swift
@Observable
class TimeJournalEntryViewModel {

    // MARK: - State

    var slotIndex: Int
    var mode: TimeJournalMode
    var date: Date

    // Entry fields
    var locationLabel: String = ""
    var activity: String = ""
    var selectedEmotions: [EmotionEntry] = []
    var people: [PersonEntry] = []
    var isSleep: Bool = false
    var isFlagged: Bool = false
    var redlineNote: String = ""

    // GPS (captured automatically)
    var latitude: Double?
    var longitude: Double?
    var locationAddress: String?
    var locationAccuracyMeters: Double?

    // UI state
    var isExpanded: Bool = false
    var isEditing: Bool = false     // true when editing existing entry
    var isSaving: Bool = false
    var existingEntryId: UUID?

    // MARK: - Computed

    var isValid: Bool {
        !locationLabel.trimmingCharacters(in: .whitespaces).isEmpty &&
        !activity.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var isRetroactive: Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let slotEndMinutes = (slotIndex + 1) * mode.intervalMinutes
        let slotEndDate = dayStart.addingTimeInterval(TimeInterval(slotEndMinutes * 60))
        return Date() >= slotEndDate
    }

    var slotTimeLabel: String {
        mode.slotLabel(index: slotIndex)
    }

    /// Whether the activity text suggests people should be prompted (TJ-004).
    var shouldPromptForPeople: Bool {
        let keywords = ["meeting", "lunch", "dinner", "coffee", "call", "group", "session", "church", "class"]
        let lowered = activity.lowercased()
        return keywords.contains { lowered.contains($0) }
    }

    // MARK: - Actions

    func save() async -> RRTimeJournalEntry? { ... }
    func validate() -> [String] { ... }

    /// Carry-forward location from the previous slot (TJ-013).
    func carryForwardLocation(from previousEntry: RRTimeJournalEntry?) {
        guard let prev = previousEntry else { return }
        locationLabel = prev.locationLabel
        latitude = prev.latitude
        longitude = prev.longitude
        locationAddress = prev.locationAddress
    }

    /// Populate fields from an existing entry for editing.
    func loadFromEntry(_ entry: RRTimeJournalEntry) {
        existingEntryId = entry.id
        isEditing = true
        locationLabel = entry.locationLabel
        activity = entry.activity
        selectedEmotions = entry.emotions
        people = entry.people
        isSleep = entry.isSleep
        isFlagged = entry.isFlagged
        redlineNote = entry.redlineNote ?? ""
        latitude = entry.latitude
        longitude = entry.longitude
        locationAddress = entry.locationAddress
        locationAccuracyMeters = entry.locationAccuracyMeters
    }

    func captureGPSLocation() async { ... }
}
```

---

## 4. View Hierarchy

```
TimeJournalDailyView (TJ-015)
|-- TimeJournalHeaderView
|   |-- Date navigation (< Today >)
|   |-- TimeJournalDayStatus badge
|   |-- Completion ring (circular progress, TJ-018)
|   |-- Mode indicator (T-30 / T-60)
|
|-- TimeJournalTimelineView (ScrollView, 24hr slot list)
|   |-- ForEach 0..<mode.slotsPerDay
|       |-- TimeJournalSlotRow (per slot)
|           |-- Time label
|           |-- Status color bar (left edge)
|           |-- Entry summary (location, activity, emotion pills)
|           |-- "+" button for empty slots
|           |-- "Late" / "Auto" badge for retroactive / auto-filled
|
|-- TimeJournalEmotionGraphView (P1, TJ-019)
|   |-- Horizontal line chart (emotion intensity across day)
|   |-- Color-coded by primary emotion category
|
|-- FloatingActionButton -> presents TimeJournalQuickEntrySheet
|
TimeJournalQuickEntrySheet (TJ-010, .sheet)
|-- Slot time label header
|-- LocationField
|   |-- Quick-select chips row (recent/saved locations)
|   |-- Free-text field with "Other..."
|   |-- GPS indicator (auto-capturing in background)
|
|-- ActivityField (TJ-003)
|   |-- TextEditor with placeholder
|   |-- Mic button for voice-to-text (P1, TJ-012)
|
|-- EmotionPicker (TJ-005)
|   |-- Horizontal category scroll (pills)
|   |-- Expanded: emotion grid for selected category
|   |-- Intensity slider per selected emotion (1-10)
|   |-- Selected emotions summary row
|
|-- (Expanded section, when sheet pulled to .large)
|   |-- PeopleField (TJ-004)
|   |   |-- Tag-style name entry
|   |   |-- Gender picker per person
|   |   |-- "Who was there?" prompt (contextual, TJ-004)
|   |
|   |-- EmotionContextField (TJ-043, P1)
|   |   |-- "Why?" one-line field per emotion
|   |
|   |-- ExtrasSection (TJ-006, P1)
|   |   |-- Financial transaction toggle
|   |   |-- Screen-time event toggle
|   |   |-- Notable interaction toggle
|   |
|   |-- SleepToggle (TJ-008)
|   |-- RedlineNoteField (TJ-048, P1)
|
|-- SaveButton (disabled until isValid)
|-- Retroactive badge (shown when isRetroactive)

TimeJournalTodayCard (TJ-065-068)
|-- HStack: icon, title, status badge
|-- ProgressView (linear, TJ-066)
|-- "Last updated" timestamp (TJ-067)
|-- NavigationLink to TimeJournalDailyView (TJ-068)

TimeJournalWorkItem (TJ-069-076)
|-- Generated as RecoveryWorkItem in RecoveryWorkViewModel
|-- RecoveryWorkItemRow with optional progress bar (TJ-075, P1)
|-- Tap navigates to TimeJournalDailyView (TJ-073)
```

---

## 5. Files

### New Files

| File | Responsibility |
|------|---------------|
| `ios/.../Models/TimeJournalTypes.swift` | `TimeJournalMode`, `TimeJournalSlotStatus`, `TimeJournalDayStatus` enums; `PersonEntry`, `EmotionEntry` codable types; `EmotionCatalog` static catalog |
| `ios/.../Data/Models/RRTimeJournalEntry.swift` | `RRTimeJournalEntry` SwiftData model (replaces fields on `RRTimeBlock`) |
| `ios/.../ViewModels/TimeJournalEntryViewModel.swift` | Quick entry sheet state management, validation, GPS capture, carry-forward |
| `ios/.../Views/Activities/TimeJournal/TimeJournalDailyView.swift` | Primary 24-hour timeline view (TJ-015) |
| `ios/.../Views/Activities/TimeJournal/TimeJournalHeaderView.swift` | Date nav, completion ring, status badge, mode indicator |
| `ios/.../Views/Activities/TimeJournal/TimeJournalTimelineView.swift` | Scrollable slot list container |
| `ios/.../Views/Activities/TimeJournal/TimeJournalSlotRow.swift` | Individual slot card with status coloring and entry summary |
| `ios/.../Views/Activities/TimeJournal/TimeJournalQuickEntrySheet.swift` | Half-sheet quick entry flow (TJ-010) |
| `ios/.../Views/Activities/TimeJournal/TimeJournalEmotionGraphView.swift` | P1: Horizontal emotion intensity chart (TJ-019) |
| `ios/.../Views/Activities/TimeJournal/EmotionPickerView.swift` | Category-based emotion selector with intensity sliders |
| `ios/.../Views/Activities/TimeJournal/LocationQuickSelectView.swift` | Recent/saved location chips row |
| `ios/.../Views/Today/TimeJournalTodayCard.swift` | Today screen card with progress bar and status (TJ-065-068) |
| `ios/.../Services/FocusStatusMonitor.swift` | iOS Focus API observer for sleep auto-fill (TJ-080-084) |

### Modified Files

| File | Change |
|------|--------|
| `ios/.../Models/Types.swift` | Add `TimeJournalMode`, `TimeJournalSlotStatus`, `TimeJournalDayStatus` enums (or import from new file). Remove legacy `TimeBlock` struct. |
| `ios/.../Data/Models/RRModels.swift` | Add `RRTimeJournalEntry` to `RRModelConfiguration.allModels`. Mark `RRTimeBlock` as deprecated or remove. |
| `ios/.../ViewModels/TimeJournalViewModel.swift` | Full rewrite: replace `TimeBlock`-based logic with `RRTimeJournalEntry`-based slot management, status engine, trigger reason generation. |
| `ios/.../ViewModels/RecoveryWorkViewModel.swift` | Add Time Journal work item generation using `TimeJournalDayStatus.evaluate()`. Gate behind `activity.time-journal` feature flag. Add to `activityFlagMap`. |
| `ios/.../ViewModels/TodayViewModel.swift` | Surface `TimeJournalTodayCard` data at top of plan items when Time Journal is in recovery plan and flag is enabled. |
| `ios/.../Views/Activities/TimeJournalView.swift` | Replace with navigation to `TimeJournalDailyView` or remove in favor of new view hierarchy. |
| `ios/.../Views/Work/RecoveryWorkItemRow.swift` | Add optional progress bar slot for Time Journal rows (TJ-075, P1). |
| `ios/.../Views/Today/TodayView.swift` | Insert `TimeJournalTodayCard` at top of plan items section when applicable. |
