# FASTER Scale Standard Tier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the full FASTER Scale Standard tier check-in flow with behavioral indicators, thermometer visualization, stage-adaptive content, and structured journaling.

**Architecture:** Enrich the existing FASTERStage enum with Restoration and behavioral indicators, expand the SwiftData model and Go backend type, then rebuild the check-in views as a multi-phase flow (mood → accordion with indicator chips → results with thermometer/journal). Extracted subviews keep each file focused.

**Tech Stack:** Swift/SwiftUI (iOS), SwiftData (local persistence), Go (backend types)

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `api/internal/domain/activities/types.go` | Modify | Expand `FASTERData` struct with indicators, mood, journal fields |
| `ios/.../Models/Types.swift` | Modify | Rebuild `FASTERStage` enum with restoration, indicators, descriptions, colors, subtitles |
| `ios/.../Models/MockData.swift` | Modify | Update mock FASTER history for new model |
| `ios/.../Data/Models/RRModels.swift` | Modify | Expand `RRFASTEREntry` with indicators, mood, journal fields |
| `ios/.../ViewModels/FASTERScaleViewModel.swift` | Rewrite | Multi-phase check-in orchestrator with assessment logic |
| `ios/.../Views/Activities/FASTER/FASTERIndicatorChip.swift` | Create | Toggleable pill component |
| `ios/.../Views/Activities/FASTER/FASTERMoodPromptView.swift` | Create | 5-icon mood entry screen |
| `ios/.../Views/Activities/FASTER/FASTERStageCardView.swift` | Create | Expandable accordion card with indicator chips |
| `ios/.../Views/Activities/FASTER/FASTERThermometerView.swift` | Create | Vertical gradient bar visualization |
| `ios/.../Views/Activities/FASTER/FASTERResultsView.swift` | Create | Results screen: thermometer + adaptive content + journal |
| `ios/.../Views/Activities/FASTERScaleView.swift` | Rewrite | Multi-phase check-in flow orchestrator view |
| `ios/.../Views/Tools/FASTERScaleToolView.swift` | Rewrite | Read-only reference with enhanced history |

**Base iOS path:** `ios/RegalRecovery/RegalRecovery`

---

### Task 1: Expand Go Backend FASTERData Type

**Files:**
- Modify: `api/internal/domain/activities/types.go:112-116`

- [ ] **Step 1: Update FASTERData struct**

Replace the existing `FASTERData` struct at line 112:

```go
// FASTERData represents FASTER scale assessment data.
type FASTERData struct {
	Stage              string              `json:"stage"`              // "restoration", "F", "A", "S", "T", "E", "R"
	SelectedIndicators map[string][]string `json:"selectedIndicators"` // stage key → selected indicator strings
	MoodScore          int                 `json:"moodScore"`          // 1-5
	JournalInsight     string              `json:"journalInsight"`     // "Ah-ha"
	JournalWarning     string              `json:"journalWarning"`     // "Uh-oh"
	JournalFreeText    string              `json:"journalFreeText"`    // optional free-text
}
```

- [ ] **Step 2: Verify build**

Run: `cd api && go build ./...`
Expected: clean build, no errors

- [ ] **Step 3: Commit**

```bash
git add api/internal/domain/activities/types.go
git commit -m "feat(api): expand FASTERData with indicators, mood, and journal fields"
```

---

### Task 2: Rebuild FASTERStage Enum with Restoration & Indicators

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Models/Types.swift:164-218`

- [ ] **Step 1: Replace the FASTERStage enum and FASTEREntry struct**

Replace everything from `// MARK: - FASTER Scale` (line 164) through `}` closing `FASTEREntry` (line 218) with the full enriched enum. Note: the raw values shift — restoration=0, F=1, A=2, S=3, T=4, E=5, R=6.

```swift
// MARK: - FASTER Scale

enum FASTERStage: Int, CaseIterable, Identifiable {
    case restoration = 0
    case forgettingPriorities
    case anxiety
    case speedingUp
    case tickedOff
    case exhausted
    case relapse

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .restoration: return "Restoration"
        case .forgettingPriorities: return "Forgetting Priorities"
        case .anxiety: return "Anxiety"
        case .speedingUp: return "Speeding Up"
        case .tickedOff: return "Ticked Off"
        case .exhausted: return "Exhausted"
        case .relapse: return "Relapse"
        }
    }

    var letter: String {
        switch self {
        case .restoration: return "✦"
        case .forgettingPriorities: return "F"
        case .anxiety: return "A"
        case .speedingUp: return "S"
        case .tickedOff: return "T"
        case .exhausted: return "E"
        case .relapse: return "R"
        }
    }

    var subtitle: String {
        switch self {
        case .restoration: return "The starting line"
        case .forgettingPriorities: return "The quiet drift"
        case .anxiety: return "The background noise gets louder"
        case .speedingUp: return "Running from the pain you won't name"
        case .tickedOff: return "Anger takes the wheel"
        case .exhausted: return "The crash"
        case .relapse: return "The cycle restarts"
        }
    }

    var description: String {
        switch self {
        case .restoration:
            return "You're being honest, staying connected, keeping your commitments, and dealing with problems as they come up. No current secrets. This is where recovery lives — not perfection, but presence."
        case .forgettingPriorities:
            return "The most subtle stage. You start drifting from the things that keep you healthy — skipping a meeting, losing touch with your partner, spending more time scrolling than connecting. Overconfidence is the hallmark."
        case .anxiety:
            return "A growing sense of unease moves in. Old negative thoughts replay. Your brain picks up on the drift and tags it as danger. Sleep gets worse, you become more judgmental, and current stresses start feeling catastrophic."
        case .speedingUp:
            return "You can't outrun anxiety, but you're going to try. Relentless busyness — staying so occupied you never sit with your feelings. Deceptive because culture rewards it. Underneath is someone terrified to slow down."
        case .tickedOff:
            return "Anger has become your primary coping mechanism. It works temporarily — provides adrenaline, makes you feel powerful, gives you someone to blame. Black-and-white thinking, keeping score, defensiveness, self-pity."
        case .exhausted:
            return "The adrenaline from anger has run out. Heavy fog — depression, hopelessness, emotional numbness. Cravings become overwhelming because your brain is desperately searching for anything that feels normal. This is the danger zone."
        case .relapse:
            return "The behavior returns. And immediately, the shame arrives. The cruelest part: shame drives isolation, which restarts the entire FASTER descent. Relapse is not the end of recovery — it is information."
        }
    }

    var color: Color {
        switch self {
        case .restoration: return Color(red: 0.176, green: 0.416, blue: 0.310)       // #2D6A4F
        case .forgettingPriorities: return Color(red: 0.482, green: 0.620, blue: 0.239) // #7B9E3D
        case .anxiety: return Color(red: 0.788, green: 0.635, blue: 0.153)             // #C9A227
        case .speedingUp: return Color(red: 0.831, green: 0.502, blue: 0.165)          // #D4802A
        case .tickedOff: return Color(red: 0.788, green: 0.365, blue: 0.180)           // #C95D2E
        case .exhausted: return Color(red: 0.651, green: 0.239, blue: 0.251)           // #A63D40
        case .relapse: return Color(red: 0.420, green: 0.153, blue: 0.216)             // #6B2737
        }
    }

    var indicators: [String] {
        switch self {
        case .restoration:
            return [
                "No active secrets",
                "Keeping commitments",
                "Honest relationships",
                "Attending meetings",
                "Processing pain openly",
                "Growing in connection",
            ]
        case .forgettingPriorities:
            return [
                "Skipping meetings",
                "Isolating",
                "Keeping small secrets",
                "Sarcasm and cynicism",
                "Overconfidence",
                "Procrastinating",
                "Losing interest in growth",
                "Entertainment as escape",
            ]
        case .anxiety:
            return [
                "Vague worry or dread",
                "Negative self-talk replaying",
                "Sleep problems",
                "Perfectionism",
                "Judging others harshly",
                "People-pleasing",
                "Flirting for reassurance",
                "Unrealistic to-do lists",
            ]
        case .speedingUp:
            return [
                "Workaholic behavior",
                "Can't relax or sit still",
                "Skipping meals",
                "Excessive caffeine",
                "Over-exercising",
                "Racing thoughts at night",
                "Overspending",
                "Constant device use",
            ]
        case .tickedOff:
            return [
                "Resentment and bitterness",
                "Black-and-white thinking",
                "Blaming everyone else",
                "Defensiveness",
                "Road rage",
                "Self-pity",
                "Silent treatment",
                "Intimidation",
            ]
        case .exhausted:
            return [
                "Emotional numbness",
                "Hopelessness",
                "Spontaneous crying",
                "Intense cravings",
                "Survival mode",
                "Missing work or obligations",
                "Confusion and poor decisions",
                "Thoughts of self-harm",
            ]
        case .relapse:
            return [
                "Acting out on addictive behavior",
                "Breaking sobriety commitment",
            ]
        }
    }

    /// Adaptive content shown after assessment for this stage.
    var adaptiveContent: (title: String, body: String) {
        switch self {
        case .restoration:
            return ("You're in Restoration", "Keep doing what you're doing. Stay connected, keep your commitments, and continue processing life honestly with the people around you. Recovery lives in the daily practice.")
        case .forgettingPriorities:
            return ("Priority Check", "Take a moment to review your commitments. Are you attending your meetings? Have you called your accountability partner this week? Are there small secrets forming? Reconnect with one priority today.")
        case .anxiety:
            return ("Ground Yourself", "Try the 5-4-3-2-1 grounding exercise: Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, and 1 you taste. Take three slow breaths. The anxiety is a signal — not a verdict.")
        case .speedingUp:
            return ("Slow Down", "Your busyness is a shield against feeling. Challenge: take 10 minutes right now to do absolutely nothing. No phone, no tasks. Just sit. Notice what feelings come up when you stop running.")
        case .tickedOff:
            return ("Name What's Underneath", "Anger feels powerful, but it's masking something. What are you really feeling beneath the irritation? Try naming the emotion without judging it. Consider reaching out to your counselor or accountability partner today.")
        case .exhausted:
            return ("You Need Support Now", "You're running on empty and your coping capacity is depleted. This is not the time to push through alone. Please reach out to your accountability partner, sponsor, or counselor today. You don't have to explain everything — just say you're struggling.")
        case .relapse:
            return ("This Is Not the End", "Relapse is painful, but it is not your identity. The shame you're feeling right now is the exact force that restarts the cycle — don't let it drive you into isolation. Call your accountability partner or sponsor. If you're in crisis, contact the 988 Suicide & Crisis Lifeline (call or text 988).")
        }
    }
}

/// Check-in phase for the multi-step FASTER Scale flow.
enum CheckInPhase {
    case mood
    case scale
    case results
}

struct FASTEREntry: Identifiable {
    let id: UUID
    let date: Date
    let stage: FASTERStage
    let moodScore: Int
    let selectedIndicators: [String]

    init(id: UUID = UUID(), date: Date, stage: FASTERStage, moodScore: Int = 3, selectedIndicators: [String] = []) {
        self.id = id
        self.date = date
        self.stage = stage
        self.moodScore = moodScore
        self.selectedIndicators = selectedIndicators
    }
}
```

- [ ] **Step 2: Verify build**

Run: `cd ios/RegalRecovery && xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`

Expected: build errors in files referencing old `FASTERStage` raw values (FASTERScaleView, FASTERScaleToolView, MockData, ViewModel) — these will be fixed in subsequent tasks.

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Models/Types.swift
git commit -m "feat(ios): rebuild FASTERStage enum with restoration, indicators, descriptions, and colors"
```

---

### Task 3: Expand RRFASTEREntry SwiftData Model

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift:541-568`

- [ ] **Step 1: Replace the RRFASTEREntry model**

Replace everything from `// MARK: - FASTER Entry` (line 541) through the closing `}` of the `init` (line 568) with:

```swift
// MARK: - FASTER Entry

@Model
final class RRFASTEREntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var assessedStage: Int  // 0-6 mapping to FASTERStage (0=restoration, 1=F, ..., 6=R)
    var moodScore: Int      // 1-5 opening mood prompt
    var selectedIndicatorsJSON: String  // JSON-encoded [String] of all selected indicators
    var journalInsight: String   // "Ah-ha" field
    var journalWarning: String   // "Uh-oh" field
    var journalFreeText: String  // optional free-text
    var createdAt: Date
    var modifiedAt: Date

    /// Decoded selected indicators from JSON storage.
    var selectedIndicators: [String] {
        get {
            guard let data = selectedIndicatorsJSON.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                selectedIndicatorsJSON = json
            }
        }
    }

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        assessedStage: Int,
        moodScore: Int = 3,
        selectedIndicators: [String] = [],
        journalInsight: String = "",
        journalWarning: String = "",
        journalFreeText: String = "",
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.assessedStage = assessedStage
        self.moodScore = moodScore
        self.journalInsight = journalInsight
        self.journalWarning = journalWarning
        self.journalFreeText = journalFreeText
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt

        // Encode selectedIndicators to JSON
        if let data = try? JSONEncoder().encode(selectedIndicators),
           let json = String(data: data, encoding: .utf8) {
            self.selectedIndicatorsJSON = json
        } else {
            self.selectedIndicatorsJSON = "[]"
        }
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift
git commit -m "feat(ios): expand RRFASTEREntry with indicators, mood, and journal fields"
```

---

### Task 4: Update MockData for New FASTER Model

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Models/MockData.swift:122-131`

- [ ] **Step 1: Replace the fasterHistory mock data**

Replace lines 122-131 (the `fasterHistory` block) with:

```swift
    // MARK: - FASTER Scale History (30 days)

    static let fasterHistory: [FASTEREntry] = {
        var entries: [FASTEREntry] = []
        let stages: [FASTERStage] = [.restoration, .restoration, .forgettingPriorities, .restoration, .anxiety, .forgettingPriorities, .restoration]
        for i in 0..<30 {
            let stage = stages[i % stages.count]
            let indicators = Array(stage.indicators.prefix(i % 3 + 1))
            entries.append(FASTEREntry(
                date: daysAgo(29 - i),
                stage: stage,
                moodScore: (i % 5) + 1,
                selectedIndicators: indicators
            ))
        }
        return entries
    }()
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Models/MockData.swift
git commit -m "feat(ios): update FASTER mock data for enriched model"
```

---

### Task 5: Rewrite FASTERScaleViewModel as Check-In Orchestrator

**Files:**
- Rewrite: `ios/RegalRecovery/RegalRecovery/ViewModels/FASTERScaleViewModel.swift`

- [ ] **Step 1: Replace the entire file contents**

```swift
import SwiftUI

@Observable
class FASTERScaleViewModel {
    // MARK: - Check-In State

    var currentPhase: CheckInPhase = .mood
    var moodScore: Int?
    var selectedIndicators: [FASTERStage: Set<String>] = [:]
    var expandedStages: Set<FASTERStage> = []
    var journalInsight: String = ""
    var journalWarning: String = ""
    var journalFreeText: String = ""

    // MARK: - History State

    var history: [FASTEREntry] = []
    var isLoading = false
    var error: String?

    // MARK: - Computed

    /// The assessed stage: lowest (most severe) stage with at least one selected indicator.
    /// If only restoration indicators are selected, returns .restoration.
    /// Returns nil if nothing is selected.
    var assessedStage: FASTERStage? {
        // Walk stages from most severe (relapse) to least severe (restoration)
        for stage in FASTERStage.allCases.reversed() {
            if stage == .restoration { continue }
            if let indicators = selectedIndicators[stage], !indicators.isEmpty {
                return stage
            }
        }
        // Only restoration selected?
        if let restorationIndicators = selectedIndicators[.restoration], !restorationIndicators.isEmpty {
            return .restoration
        }
        return nil
    }

    /// Total number of selected indicators across all stages.
    var totalSelectedCount: Int {
        selectedIndicators.values.reduce(0) { $0 + $1.count }
    }

    /// Count of selected indicators for a specific stage.
    func selectedCount(for stage: FASTERStage) -> Int {
        selectedIndicators[stage]?.count ?? 0
    }

    /// Whether the check-in can be submitted (at least one indicator selected).
    var canSubmit: Bool {
        totalSelectedCount > 0
    }

    /// All selected indicator strings flattened into a single array.
    var allSelectedIndicatorStrings: [String] {
        selectedIndicators.values.flatMap { $0 }
    }

    /// Number of check-ins completed this month.
    var checkInsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return history.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    // MARK: - Actions

    func selectMood(_ score: Int) {
        moodScore = score
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .scale
        }
    }

    func toggleIndicator(stage: FASTERStage, indicator: String) {
        var set = selectedIndicators[stage] ?? []
        if set.contains(indicator) {
            set.remove(indicator)
        } else {
            set.insert(indicator)
        }
        if set.isEmpty {
            selectedIndicators.removeValue(forKey: stage)
        } else {
            selectedIndicators[stage] = set
        }
    }

    func isIndicatorSelected(stage: FASTERStage, indicator: String) -> Bool {
        selectedIndicators[stage]?.contains(indicator) ?? false
    }

    func toggleExpanded(stage: FASTERStage) {
        if expandedStages.contains(stage) {
            expandedStages.remove(stage)
        } else {
            expandedStages.insert(stage)
        }
    }

    func isExpanded(stage: FASTERStage) -> Bool {
        expandedStages.contains(stage)
    }

    func submit() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhase = .results
        }
    }

    func reset() {
        currentPhase = .mood
        moodScore = nil
        selectedIndicators = [:]
        expandedStages = []
        journalInsight = ""
        journalWarning = ""
        journalFreeText = ""
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        error = nil

        do {
            try await loadFromMockData()
        } catch {
            self.error = "Unable to load FASTER Scale data. Please try again."
        }

        isLoading = false
    }

    // MARK: - Private

    private func loadFromMockData() async throws {
        history = MockData.fasterHistory
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/FASTERScaleViewModel.swift
git commit -m "feat(ios): rewrite FASTERScaleViewModel as multi-phase check-in orchestrator"
```

---

### Task 6: Create FASTERIndicatorChip Subview

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERIndicatorChip.swift`

- [ ] **Step 1: Create the FASTER subdirectory**

```bash
mkdir -p ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER
```

- [ ] **Step 2: Write the indicator chip view**

```swift
import SwiftUI

struct FASTERIndicatorChip: View {
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? color : color.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack {
        FASTERIndicatorChip(label: "Isolating", color: .green, isSelected: false) {}
        FASTERIndicatorChip(label: "Isolating", color: .green, isSelected: true) {}
    }
    .padding()
}
```

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERIndicatorChip.swift
git commit -m "feat(ios): add FASTERIndicatorChip toggleable pill component"
```

---

### Task 7: Create FASTERMoodPromptView Subview

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERMoodPromptView.swift`

- [ ] **Step 1: Write the mood prompt view**

```swift
import SwiftUI

struct FASTERMoodPromptView: View {
    let onSelect: (Int) -> Void

    private let moods: [(score: Int, icon: String, label: String)] = [
        (1, "face.smiling.inverse", "Great"),
        (2, "face.smiling", "Good"),
        (3, "minus.circle", "Okay"),
        (4, "cloud", "Struggling"),
        (5, "cloud.rain", "Rough"),
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("How are you doing right now?")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .multilineTextAlignment(.center)

                Text("Just a quick gut check before we begin.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                ForEach(moods, id: \.score) { mood in
                    Button {
                        onSelect(mood.score)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: mood.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(moodColor(mood.score))
                            Text(mood.label)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.label), mood \(mood.score) of 5")
                }
            }
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
    }

    private func moodColor(_ score: Int) -> Color {
        switch score {
        case 1: return Color(red: 0.176, green: 0.416, blue: 0.310)  // restoration green
        case 2: return Color(red: 0.482, green: 0.620, blue: 0.239)  // olive green
        case 3: return Color(red: 0.788, green: 0.635, blue: 0.153)  // amber
        case 4: return Color(red: 0.831, green: 0.502, blue: 0.165)  // orange
        case 5: return Color(red: 0.651, green: 0.239, blue: 0.251)  // crimson
        default: return Color.rrTextSecondary
        }
    }
}

#Preview {
    FASTERMoodPromptView { score in
        print("Selected mood: \(score)")
    }
    .background(Color.rrBackground)
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERMoodPromptView.swift
git commit -m "feat(ios): add FASTERMoodPromptView 5-icon mood entry screen"
```

---

### Task 8: Create FASTERStageCardView Subview

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERStageCardView.swift`

- [ ] **Step 1: Write the expandable stage card view**

```swift
import SwiftUI

struct FASTERStageCardView: View {
    let stage: FASTERStage
    let isExpanded: Bool
    let selectedCount: Int
    let isIndicatorSelected: (String) -> Bool
    let onToggleExpand: () -> Void
    let onToggleIndicator: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header — always visible
            Button(action: onToggleExpand) {
                HStack(spacing: 14) {
                    Text(stage.letter)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(stage.color)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text(stage.subtitle)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(RRFont.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(stage.color)
                            .clipShape(Circle())
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Body — expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 14) {
                    Divider()

                    Text(stage.description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    FlowLayout(spacing: 8) {
                        ForEach(stage.indicators, id: \.self) { indicator in
                            FASTERIndicatorChip(
                                label: indicator,
                                color: stage.color,
                                isSelected: isIndicatorSelected(indicator),
                                action: { onToggleIndicator(indicator) }
                            )
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        FASTERStageCardView(
            stage: .forgettingPriorities,
            isExpanded: true,
            selectedCount: 2,
            isIndicatorSelected: { $0 == "Isolating" || $0 == "Overconfidence" },
            onToggleExpand: {},
            onToggleIndicator: { _ in }
        )
        FASTERStageCardView(
            stage: .anxiety,
            isExpanded: false,
            selectedCount: 0,
            isIndicatorSelected: { _ in false },
            onToggleExpand: {},
            onToggleIndicator: { _ in }
        )
    }
    .padding()
    .background(Color.rrBackground)
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERStageCardView.swift
git commit -m "feat(ios): add FASTERStageCardView expandable accordion with indicator chips"
```

---

### Task 9: Create FASTERThermometerView Subview

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERThermometerView.swift`

- [ ] **Step 1: Write the thermometer visualization**

```swift
import SwiftUI

struct FASTERThermometerView: View {
    let assessedStage: FASTERStage
    let selectedIndicators: [FASTERStage: Set<String>]

    private let stages = FASTERStage.allCases
    private let segmentHeight: CGFloat = 32

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thermometer bar
            VStack(spacing: 0) {
                ForEach(stages) { stage in
                    ZStack {
                        Rectangle()
                            .fill(stage.color)
                            .frame(height: segmentHeight)

                        // Marker for assessed stage
                        if stage == assessedStage {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(.white)
                                    .frame(width: 14, height: 14)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                    .padding(.trailing, 4)
                            }
                        }
                    }
                }
            }
            .frame(width: 36)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            // Stage labels
            VStack(spacing: 0) {
                ForEach(stages) { stage in
                    HStack(spacing: 6) {
                        Text(stage.letter)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(stage == assessedStage ? stage.color : Color.rrTextSecondary)
                        Text(stage.name)
                            .font(RRFont.caption)
                            .foregroundStyle(stage == assessedStage ? Color.rrText : Color.rrTextSecondary)
                            .fontWeight(stage == assessedStage ? .semibold : .regular)

                        Spacer()

                        let count = selectedIndicators[stage]?.count ?? 0
                        if count > 0 {
                            Text("\(count)")
                                .font(RRFont.caption2)
                                .foregroundStyle(stage.color)
                        }
                    }
                    .frame(height: segmentHeight)
                }
            }
        }
        .padding()
    }
}

#Preview {
    FASTERThermometerView(
        assessedStage: .speedingUp,
        selectedIndicators: [
            .restoration: ["Attending meetings"],
            .forgettingPriorities: ["Isolating", "Overconfidence"],
            .anxiety: ["Sleep problems"],
            .speedingUp: ["Workaholic behavior"],
        ]
    )
    .background(Color.rrBackground)
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERThermometerView.swift
git commit -m "feat(ios): add FASTERThermometerView vertical gradient bar visualization"
```

---

### Task 10: Create FASTERResultsView Subview

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERResultsView.swift`

- [ ] **Step 1: Write the results view (thermometer + adaptive content + journal)**

```swift
import SwiftUI

struct FASTERResultsView: View {
    let assessedStage: FASTERStage
    let selectedIndicators: [FASTERStage: Set<String>]
    @Binding var journalInsight: String
    @Binding var journalWarning: String
    @Binding var journalFreeText: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Thermometer
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    RRSectionHeader(title: "Your Assessment")
                    FASTERThermometerView(
                        assessedStage: assessedStage,
                        selectedIndicators: selectedIndicators
                    )
                }
            }

            // Adaptive content
            adaptiveContentCard

            // Journal
            journalSection

            // Save button
            RRButton("Save Check-In", icon: "checkmark.circle") {
                onSave()
            }
        }
    }

    // MARK: - Adaptive Content

    private var adaptiveContentCard: some View {
        let content = assessedStage.adaptiveContent
        return RRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(assessedStage.color)
                        .frame(width: 10, height: 10)
                    Text(content.title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }
                Text(content.body)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Journal

    private var journalSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(title: "Reflect")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ah-ha (insight)")
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Something I noticed about myself today...", text: $journalInsight, axis: .vertical)
                        .font(RRFont.body)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: journalInsight) { _, newValue in
                            if newValue.count > 1000 { journalInsight = String(newValue.prefix(1000)) }
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Uh-oh (warning sign)")
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Something I need to watch out for...", text: $journalWarning, axis: .vertical)
                        .font(RRFont.body)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: journalWarning) { _, newValue in
                            if newValue.count > 1000 { journalWarning = String(newValue.prefix(1000)) }
                        }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Anything else?")
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Optional — whatever is on your mind...", text: $journalFreeText, axis: .vertical)
                        .font(RRFont.body)
                        .lineLimit(3...6)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.rrBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .onChange(of: journalFreeText) { _, newValue in
                            if newValue.count > 1000 { journalFreeText = String(newValue.prefix(1000)) }
                        }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        FASTERResultsView(
            assessedStage: .anxiety,
            selectedIndicators: [
                .forgettingPriorities: ["Isolating"],
                .anxiety: ["Sleep problems", "Vague worry or dread"],
            ],
            journalInsight: .constant(""),
            journalWarning: .constant(""),
            journalFreeText: .constant(""),
            onSave: {}
        )
        .padding()
    }
    .background(Color.rrBackground)
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERResultsView.swift
git commit -m "feat(ios): add FASTERResultsView with thermometer, adaptive content, and journal"
```

---

### Task 11: Rewrite FASTERScaleView as Multi-Phase Check-In Flow

**Files:**
- Rewrite: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTERScaleView.swift`

- [ ] **Step 1: Replace the entire file contents**

```swift
import SwiftUI
import SwiftData

struct FASTERScaleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var viewModel = FASTERScaleViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch viewModel.currentPhase {
                case .mood:
                    FASTERMoodPromptView { score in
                        viewModel.selectMood(score)
                    }

                case .scale:
                    scalePhase

                case .results:
                    if let assessed = viewModel.assessedStage {
                        FASTERResultsView(
                            assessedStage: assessed,
                            selectedIndicators: viewModel.selectedIndicators,
                            journalInsight: $viewModel.journalInsight,
                            journalWarning: $viewModel.journalWarning,
                            journalFreeText: $viewModel.journalFreeText,
                            onSave: { saveCheckIn() }
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    // MARK: - Scale Phase

    private var scalePhase: some View {
        VStack(spacing: 20) {
            // Info header
            VStack(spacing: 4) {
                Text("What are you experiencing?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)
                Text("Tap a stage to expand it, then select any indicators that apply.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Accordion cards
            VStack(spacing: 10) {
                ForEach(FASTERStage.allCases) { stage in
                    FASTERStageCardView(
                        stage: stage,
                        isExpanded: viewModel.isExpanded(stage: stage),
                        selectedCount: viewModel.selectedCount(for: stage),
                        isIndicatorSelected: { viewModel.isIndicatorSelected(stage: stage, indicator: $0) },
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.toggleExpanded(stage: stage)
                            }
                        },
                        onToggleIndicator: { indicator in
                            viewModel.toggleIndicator(stage: stage, indicator: indicator)
                        }
                    )
                }
            }
            .padding(.horizontal)

            // Submit button
            RRButton("Complete Check-In", icon: "checkmark.circle") {
                viewModel.submit()
            }
            .opacity(viewModel.canSubmit ? 1 : 0.4)
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal)
        }
    }

    // MARK: - Persistence

    private func saveCheckIn() {
        guard let assessed = viewModel.assessedStage else { return }
        let userId = users.first?.id ?? UUID()

        let entry = RRFASTEREntry(
            userId: userId,
            date: Date(),
            assessedStage: assessed.rawValue,
            moodScore: viewModel.moodScore ?? 3,
            selectedIndicators: viewModel.allSelectedIndicatorStrings,
            journalInsight: viewModel.journalInsight,
            journalWarning: viewModel.journalWarning,
            journalFreeText: viewModel.journalFreeText
        )
        modelContext.insert(entry)
        viewModel.reset()
    }
}

#Preview {
    NavigationStack {
        FASTERScaleView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTERScaleView.swift
git commit -m "feat(ios): rewrite FASTERScaleView as multi-phase check-in flow"
```

---

### Task 12: Rewrite FASTERScaleToolView as Read-Only Reference

**Files:**
- Rewrite: `ios/RegalRecovery/RegalRecovery/Views/Tools/FASTERScaleToolView.swift`

- [ ] **Step 1: Replace the entire file contents**

```swift
import SwiftUI
import SwiftData

struct FASTERScaleToolView: View {
    @Query(sort: \RRFASTEREntry.date, order: .reverse)
    private var entries: [RRFASTEREntry]

    @State private var expandedStage: FASTERStage?
    @State private var selectedEntry: RRFASTEREntry?

    private var last30Entries: [RRFASTEREntry] {
        Array(entries.prefix(30))
    }

    private var checkInsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        return entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Engagement counter
                if !entries.isEmpty {
                    RRCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(checkInsThisMonth)")
                                    .font(.system(.title, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.rrText)
                                Text("check-ins this month")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            Spacer()
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundStyle(Color.rrPrimary)
                        }
                    }
                    .padding(.horizontal)
                }

                // Stage reference cards
                RRSectionHeader(title: "The FASTER Scale")
                    .padding(.horizontal)

                VStack(spacing: 10) {
                    ForEach(FASTERStage.allCases) { stage in
                        stageReferenceCard(stage)
                    }
                }
                .padding(.horizontal)

                // History dots
                if !last30Entries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 12) {
                            RRSectionHeader(title: "Last 30 Days")

                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                                ForEach(last30Entries.reversed()) { entry in
                                    let stage = FASTERStage(rawValue: entry.assessedStage) ?? .restoration
                                    Button {
                                        selectedEntry = entry
                                    } label: {
                                        RRColorDot(stage.color, size: 20)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            // Legend
                            FlowLayout(spacing: 10) {
                                ForEach(FASTERStage.allCases) { stage in
                                    HStack(spacing: 4) {
                                        RRColorDot(stage.color, size: 8)
                                        Text(stage.letter)
                                            .font(RRFont.caption2)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .sheet(item: $selectedEntry) { entry in
            entryDetailSheet(entry)
        }
    }

    // MARK: - Stage Reference Card

    private func stageReferenceCard(_ stage: FASTERStage) -> some View {
        let isExpanded = expandedStage == stage

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedStage = isExpanded ? nil : stage
                }
            } label: {
                HStack(spacing: 14) {
                    Text(stage.letter)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(stage.color)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text(stage.subtitle)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    Text(stage.description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    FlowLayout(spacing: 8) {
                        ForEach(stage.indicators, id: \.self) { indicator in
                            Text(indicator)
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(stage.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(stage.color.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Entry Detail Sheet

    private func entryDetailSheet(_ entry: RRFASTEREntry) -> some View {
        let stage = FASTERStage(rawValue: entry.assessedStage) ?? .restoration

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Date and stage
                    HStack(spacing: 10) {
                        Text(stage.letter)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(stage.color)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.name)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }

                    // Mood
                    HStack(spacing: 6) {
                        Text("Mood:")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text("\(entry.moodScore)/5")
                            .font(RRFont.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.rrText)
                    }

                    // Indicators
                    let indicators = entry.selectedIndicators
                    if !indicators.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Indicators (\(indicators.count))")
                                .font(RRFont.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.rrTextSecondary)
                            FlowLayout(spacing: 6) {
                                ForEach(indicators, id: \.self) { indicator in
                                    Text(indicator)
                                        .font(RRFont.caption2)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.rrBackground)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Journal
                    if !entry.journalInsight.isEmpty {
                        journalField("Ah-ha", entry.journalInsight)
                    }
                    if !entry.journalWarning.isEmpty {
                        journalField("Uh-oh", entry.journalWarning)
                    }
                    if !entry.journalFreeText.isEmpty {
                        journalField("Notes", entry.journalFreeText)
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle("Check-In Detail")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    private func journalField(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary)
            Text(text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
        }
    }
}

extension RRFASTEREntry: @retroactive Identifiable {}

#Preview {
    NavigationStack {
        FASTERScaleToolView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Tools/FASTERScaleToolView.swift
git commit -m "feat(ios): rewrite FASTERScaleToolView as read-only reference with enhanced history"
```

---

### Task 13: Fix Compilation — Update References to Old Model

**Files:**
- Modify: any remaining files that reference the old `RRFASTEREntry.stage` field or old `FASTERStage` raw values

- [ ] **Step 1: Search for references to the old `.stage` property on `RRFASTEREntry`**

Run: `grep -rn '\.stage' ios/RegalRecovery/RegalRecovery/ --include='*.swift' | grep -i faster | grep -v assessedStage | grep -v 'FASTERStage'`

Fix any remaining references by replacing `.stage` with `.assessedStage`.

Common locations to check:
- Any view that queries `RRFASTEREntry` and reads `.stage`
- The `RRModelConfiguration` or container setup if it references FASTER models

- [ ] **Step 2: Search for old FASTERStage raw value assumptions**

Run: `grep -rn 'FASTERStage(rawValue:' ios/RegalRecovery/RegalRecovery/ --include='*.swift'`

Any code using `FASTERStage(rawValue: entry.stage)` must change to `FASTERStage(rawValue: entry.assessedStage)`. The default fallback should change from `.forgettingPriorities` to `.restoration`.

- [ ] **Step 3: Verify full build**

Run: `cd ios/RegalRecovery && xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add -A ios/RegalRecovery/
git commit -m "fix(ios): update all references from old stage field to assessedStage"
```
