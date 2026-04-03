# FASTER Scale Check-In Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete Standard tier FASTER Scale Check-In flow (PRD S-01 through S-09): mood prompt → indicator accordion → thermometer results with adaptive content → structured journaling → persist to SwiftData.

**Architecture:** A `FASTERCheckInFlowView` container manages a 3-step state machine (`.mood` → `.indicators` → `.results`). Each step is a focused SwiftUI view. A single `FASTERCheckInViewModel` holds all state (mood score, selected indicators, assessed stage, journal text) and handles persistence via the existing SwiftData `RRFASTEREntry` model (expanded with new fields).

**Tech Stack:** Swift/SwiftUI, SwiftData, iOS 17+

**PRD Coverage:**
- S-01: Mood prompt (FASTERMoodPromptView — update to transition instead of dismiss)
- S-02: 7 accordion cards (Restoration + F/A/S/T/E/R)
- S-03: 5-8 toggleable indicator chips per stage
- S-04: Multi-stage indicator selection
- S-05: Assessed position = lowest stage with selection
- S-06: Thermometer gradient visualization
- S-07: Stage-adaptive content
- S-08: Structured journaling (Ah-ha / Uh-oh / free-text)
- S-09: Persist with timestamp, indicators, stage, journal

---

## File Map

### New Files

| File | Responsibility |
|------|---------------|
| `Views/Activities/FASTER/FASTERCheckInFlowView.swift` | State machine container: mood → indicators → results |
| `Views/Activities/FASTER/FASTERIndicatorSelectionView.swift` | 7 accordion cards with toggleable indicator chips |
| `Views/Activities/FASTER/FASTERThermometerView.swift` | Vertical gradient bar showing assessed position |
| `ViewModels/FASTERCheckInViewModel.swift` | Manages check-in state, assessment logic, persistence |

### Modified Files

| File | Changes |
|------|---------|
| `Models/Types.swift` | Add `restoration` case to FASTERStage, add `indicators` and `adaptiveContent` computed properties |
| `Data/Models/RRModels.swift` | Add `moodScore`, `selectedIndicatorsJSON`, `journalInsight`, `journalWarning`, `journalFreeText` to RRFASTEREntry |
| `Views/Activities/FASTER/FASTERMoodPromptView.swift` | Change `onSelect: (Int) -> Void` — no structural change needed, caller handles transition |
| `Views/Activities/FASTER/FASTERResultsView.swift` | Rewrite to use real types (FASTERThermometerView, adaptiveContent, FASTERCheckInViewModel) |
| `Models/MockData.swift` | Update `fasterHistory` to include new FASTEREntry fields |
| `Views/Today/TodayView.swift` | Replace `showFASTERMood` + `FASTERMoodPromptView` with `FASTERCheckInFlowView` |
| `Views/Home/QuickActionsRow.swift` | Replace `FASTERMoodPromptView` with `FASTERCheckInFlowView` |
| `RegalRecovery.xcodeproj/project.pbxproj` | Add new files to Xcode project |

---

## Task 1: Extend FASTERStage with Restoration, Indicators, and Adaptive Content

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Models/Types.swift:166-212`

- [ ] **Step 1: Add `restoration` case and update all switch statements**

In `Types.swift`, change the `FASTERStage` enum. The `restoration` case uses rawValue -1 so existing F/A/S/T/E/R rawValues (0-5) are unchanged and stored data is backward-compatible.

```swift
enum FASTERStage: Int, CaseIterable, Identifiable {
    case restoration = -1
    case forgettingPriorities = 0
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
        case .restoration: return "R+"
        default: return String(name.prefix(1))
        }
    }

    var description: String {
        switch self {
        case .restoration: return "Living in healthy patterns, maintaining recovery priorities, connected to support network."
        case .forgettingPriorities: return "Losing focus on recovery priorities, skipping routines, drifting from commitments."
        case .anxiety: return "Worry, restlessness, difficulty concentrating, feeling overwhelmed by daily pressures."
        case .speedingUp: return "Taking on too much, staying busy to avoid feelings, rushing through the day."
        case .tickedOff: return "Irritability, resentment, blaming others, feeling entitled or self-righteous."
        case .exhausted: return "Physical and emotional depletion, isolation, feeling hopeless or burned out."
        case .relapse: return "Acting out on addictive behaviors, breaking sobriety commitment."
        }
    }

    var color: Color {
        switch self {
        case .restoration: return Color(red: 0.176, green: 0.416, blue: 0.310)
        case .forgettingPriorities: return .rrSuccess
        case .anxiety: return .yellow
        case .speedingUp: return .orange
        case .tickedOff: return .orange
        case .exhausted: return .rrDestructive
        case .relapse: return .rrDestructive
        }
    }
}
```

- [ ] **Step 2: Add `indicators` computed property**

Add this computed property to `FASTERStage` (after `color`). These are the canonical Michael Dye behavioral markers, 5-8 per stage:

```swift
    /// Canonical behavioral indicators from the FASTER Scale framework (Michael Dye).
    var indicators: [String] {
        switch self {
        case .restoration:
            return [
                "Attending meetings regularly",
                "Maintaining daily devotional",
                "Honest with accountability partner",
                "Keeping commitments",
                "Healthy sleep schedule",
                "Exercising regularly",
                "Connected to support network",
            ]
        case .forgettingPriorities:
            return [
                "Isolating from others",
                "Keeping minor secrets",
                "Sarcastic or cynical attitude",
                "Procrastinating on recovery work",
                "Breaking small commitments",
                "Overconfidence in recovery",
                "Preoccupied with entertainment",
                "Skipping meetings or quiet time",
            ]
        case .anxiety:
            return [
                "Sleep problems or insomnia",
                "Vague worry or dread",
                "Difficulty concentrating",
                "Nervous energy or fidgeting",
                "Avoiding specific people or places",
                "Increased caffeine or sugar intake",
                "Obsessing over things I can't control",
            ]
        case .speedingUp:
            return [
                "Taking on too many tasks",
                "Staying constantly busy",
                "Difficulty sitting still",
                "Rushing through conversations",
                "Skipping meals or self-care",
                "Working excessive hours",
                "Saying yes to everything",
                "Neglecting relationships",
            ]
        case .tickedOff:
            return [
                "Irritable over small things",
                "Resentment toward someone",
                "Blaming others for problems",
                "Feeling entitled or self-righteous",
                "Road rage or short temper",
                "Keeping score in relationships",
                "Sarcasm that cuts",
            ]
        case .exhausted:
            return [
                "Physically drained constantly",
                "Emotionally numb or flat",
                "Withdrawing from everyone",
                "Feeling hopeless about recovery",
                "Can't see a way forward",
                "Fantasizing about acting out",
                "Stopped caring about consequences",
            ]
        case .relapse:
            return [
                "Acted out on addictive behavior",
                "Broke sobriety commitment",
                "Lying to cover up behavior",
                "Bingeing or escalating behavior",
                "Planning next opportunity to act out",
                "Complete disconnect from support",
            ]
        }
    }
```

- [ ] **Step 3: Add `adaptiveContent` computed property**

Add after `indicators`. This provides stage-matched guidance per PRD S-07:

```swift
    /// Stage-appropriate adaptive content (PRD S-07).
    var adaptiveContent: (title: String, body: String) {
        switch self {
        case .restoration:
            return (
                "You're in Restoration",
                "Keep up the great work. Stay connected to your support network, maintain your routines, and remember — consistency is what got you here. Consider encouraging someone else in their recovery today."
            )
        case .forgettingPriorities:
            return (
                "Priority Check",
                "You may be drifting from your recovery foundations. Review your commitments: Are you attending meetings? Keeping your quiet time? Being honest with your accountability partner? Small course corrections now prevent bigger problems later."
            )
        case .anxiety:
            return (
                "Grounding Exercise",
                "Anxiety is a signal, not a sentence. Try the 5-4-3-2-1 technique: notice 5 things you see, 4 you can touch, 3 you hear, 2 you smell, 1 you taste. Then take three slow breaths. You don't have to figure everything out right now."
            )
        case .speedingUp:
            return (
                "Slow Down Challenge",
                "Busyness is a way of avoiding what's underneath. Your challenge: take 10 minutes right now to do absolutely nothing. No phone, no tasks. Just be still. What feelings come up when you stop?"
            )
        case .tickedOff:
            return (
                "Name the Feeling",
                "Anger often masks hurt, fear, or shame. Before reacting, ask: What am I really feeling beneath the irritation? Who am I really angry at? Consider reaching out to your accountability partner to talk it through."
            )
        case .exhausted:
            return (
                "You Need Support Right Now",
                "You're in a critical place. This is not the time to isolate. Please reach out to your accountability partner, sponsor, or counselor today — not tomorrow. You don't have to have the words; just make the call."
            )
        case .relapse:
            return (
                "You Are Not Beyond Recovery",
                "A relapse is not the end of your story. Right now, the most important thing is to be honest with someone safe. Contact your accountability partner or sponsor. If you're in crisis, use the SOS button. Grace is real, and so is your next step forward."
            )
        }
    }
```

- [ ] **Step 4: Verify the build compiles**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' build 2>&1 | tail -5`

Expected: Build may fail due to missing `restoration` cases in other switch statements. Fix any exhaustive switch errors in `FASTERScaleView.swift`, `FASTERScaleToolView.swift`, `FASTERScaleViewModel.swift`, `HomeView.swift`, `SeedData.swift`, or `MockData.swift` by adding the `.restoration` case appropriately. In `FASTERScaleViewModel.zoneLabel`, restoration maps to `"Green"`. In views that iterate `FASTERStage.allCases`, restoration will appear automatically.

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Models/Types.swift
# Also add any files fixed for exhaustive switch
git commit -m "feat(ios): add restoration case, indicators, and adaptiveContent to FASTERStage"
```

---

## Task 2: Expand RRFASTEREntry SwiftData Model

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift:541-568`

- [ ] **Step 1: Add new fields to RRFASTEREntry**

Replace the existing `RRFASTEREntry` class (lines 541-568) with:

```swift
// MARK: - FASTER Entry

@Model
final class RRFASTEREntry {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var date: Date
    var stage: Int  // -1 to 5 mapping to FASTERStage
    var moodScore: Int  // 1-5 from mood prompt
    var selectedIndicatorsJSON: String  // JSON-encoded [String: [String]] (stage name → indicator labels)
    var journalInsight: String?  // "Ah-ha" field
    var journalWarning: String?  // "Uh-oh" field
    var journalFreeText: String?  // Optional free-text
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        date: Date,
        stage: Int,
        moodScore: Int = 3,
        selectedIndicatorsJSON: String = "{}",
        journalInsight: String? = nil,
        journalWarning: String? = nil,
        journalFreeText: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.stage = stage
        self.moodScore = moodScore
        self.selectedIndicatorsJSON = selectedIndicatorsJSON
        self.journalInsight = journalInsight
        self.journalWarning = journalWarning
        self.journalFreeText = journalFreeText
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
```

Note: SwiftData handles lightweight migrations automatically for new optional/defaulted properties. No explicit migration needed.

- [ ] **Step 2: Update SeedData to use new fields**

In `SeedData.swift`, update `seedFASTER` (around line 395) — the existing seed calls will still compile because new params have defaults, so no change is strictly required, but you can add richer seed data if desired. Leave as-is for now.

- [ ] **Step 3: Update MockData FASTEREntry struct**

In `Models/Types.swift`, expand the `FASTEREntry` struct to match:

```swift
struct FASTEREntry: Identifiable {
    let id = UUID()
    let date: Date
    let stage: FASTERStage
    let moodScore: Int
    let selectedIndicators: [FASTERStage: Set<String>]

    init(date: Date, stage: FASTERStage, moodScore: Int = 3, selectedIndicators: [FASTERStage: Set<String>] = [:]) {
        self.date = date
        self.stage = stage
        self.moodScore = moodScore
        self.selectedIndicators = selectedIndicators
    }
}
```

- [ ] **Step 4: Update MockData.fasterHistory**

In `MockData.swift`, update the `fasterHistory` builder to use the new init (defaults handle it, so just verify it compiles):

```swift
static let fasterHistory: [FASTEREntry] = {
    var entries: [FASTEREntry] = []
    let stages: [FASTERStage] = [.forgettingPriorities, .forgettingPriorities, .forgettingPriorities, .forgettingPriorities, .anxiety, .forgettingPriorities, .forgettingPriorities]
    for i in 0..<30 {
        let stage = stages[i % stages.count]
        entries.append(FASTEREntry(
            date: daysAgo(29 - i),
            stage: stage
        ))
    }
    return entries
}()
```

No change needed — the new `init` defaults handle it.

- [ ] **Step 5: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' build 2>&1 | tail -5`

Expected: **BUILD SUCCEEDED**

- [ ] **Step 6: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift ios/RegalRecovery/RegalRecovery/Models/Types.swift
git commit -m "feat(ios): expand RRFASTEREntry with mood, indicators, and journal fields"
```

---

## Task 3: Create FASTERCheckInViewModel

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/FASTERCheckInViewModel.swift`

- [ ] **Step 1: Create the ViewModel**

```swift
import Foundation
import SwiftUI
import SwiftData

enum FASTERCheckInStep {
    case mood
    case indicators
    case results
}

@Observable
class FASTERCheckInViewModel {

    // MARK: - Flow State

    var currentStep: FASTERCheckInStep = .mood

    // MARK: - Mood (S-01)

    var moodScore: Int = 0  // 1-5, 0 = not yet selected

    // MARK: - Indicators (S-02, S-03, S-04)

    /// Selected indicators keyed by stage. Each value is a Set of indicator label strings.
    var selectedIndicators: [FASTERStage: Set<String>] = [:]

    // MARK: - Assessment (S-05)

    /// The assessed stage: the most severe (highest rawValue) stage with at least one indicator selected.
    /// Returns `.restoration` if no indicators are selected outside Restoration.
    var assessedStage: FASTERStage {
        // Find the most severe stage (highest rawValue) with at least one non-Restoration selection
        let activeStages = selectedIndicators
            .filter { $0.key != .restoration && !$0.value.isEmpty }
            .map(\.key)

        if activeStages.isEmpty {
            return .restoration
        }

        return activeStages.max(by: { $0.rawValue < $1.rawValue }) ?? .restoration
    }

    // MARK: - Journal (S-08)

    var journalInsight: String = ""
    var journalWarning: String = ""
    var journalFreeText: String = ""

    // MARK: - Indicator Helpers

    func isSelected(stage: FASTERStage, indicator: String) -> Bool {
        selectedIndicators[stage]?.contains(indicator) ?? false
    }

    func toggleIndicator(stage: FASTERStage, indicator: String) {
        if selectedIndicators[stage] == nil {
            selectedIndicators[stage] = []
        }
        if selectedIndicators[stage]!.contains(indicator) {
            selectedIndicators[stage]!.remove(indicator)
            if selectedIndicators[stage]!.isEmpty {
                selectedIndicators[stage] = nil
            }
        } else {
            selectedIndicators[stage]!.insert(indicator)
        }
    }

    func selectedCount(for stage: FASTERStage) -> Int {
        selectedIndicators[stage]?.count ?? 0
    }

    // MARK: - Flow Navigation

    func selectMood(_ score: Int) {
        moodScore = score
        currentStep = .indicators
    }

    func finishIndicators() {
        currentStep = .results
    }

    func goBackToIndicators() {
        currentStep = .indicators
    }

    // MARK: - Persistence (S-09)

    func save(context: ModelContext, userId: UUID) {
        // Encode selectedIndicators as JSON
        let encodable: [String: [String]] = selectedIndicators.reduce(into: [:]) { result, pair in
            result[pair.key.name] = Array(pair.value).sorted()
        }
        let json = (try? JSONEncoder().encode(encodable)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"

        let entry = RRFASTEREntry(
            userId: userId,
            date: Date(),
            stage: assessedStage.rawValue,
            moodScore: moodScore,
            selectedIndicatorsJSON: json,
            journalInsight: journalInsight.isEmpty ? nil : journalInsight,
            journalWarning: journalWarning.isEmpty ? nil : journalWarning,
            journalFreeText: journalFreeText.isEmpty ? nil : journalFreeText
        )
        context.insert(entry)
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' build 2>&1 | tail -5`

Note: This file needs to be added to the Xcode project. It will be added in Task 7 (integration). For now, just create the file.

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/FASTERCheckInViewModel.swift
git commit -m "feat(ios): add FASTERCheckInViewModel with assessment logic and persistence"
```

---

## Task 4: Create FASTERIndicatorSelectionView

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERIndicatorSelectionView.swift`

This view implements PRD S-02 (accordion cards), S-03 (toggleable chips), S-04 (multi-stage selection).

- [ ] **Step 1: Create the indicator selection view**

```swift
import SwiftUI

struct FASTERIndicatorSelectionView: View {
    @Bindable var viewModel: FASTERCheckInViewModel
    @State private var expandedStage: FASTERStage? = nil

    /// Stages ordered from Restoration (top) to Relapse (bottom) per PRD S-02.
    private let stageOrder: [FASTERStage] = [
        .restoration,
        .forgettingPriorities,
        .anxiety,
        .speedingUp,
        .tickedOff,
        .exhausted,
        .relapse,
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What are you experiencing?")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                Text("Tap each section to review indicators. Toggle any that apply.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 12)

            // Accordion
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(stageOrder) { stage in
                        stageCard(stage)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100) // Space for button
            }

            // Submit button
            VStack {
                RRButton("See My Results", icon: "arrow.right") {
                    viewModel.finishIndicators()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(
                Color.rrBackground
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(Color.rrBackground)
    }

    // MARK: - Stage Accordion Card

    @ViewBuilder
    private func stageCard(_ stage: FASTERStage) -> some View {
        let isExpanded = expandedStage == stage
        let count = viewModel.selectedCount(for: stage)

        VStack(spacing: 0) {
            // Header row (always visible)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedStage = isExpanded ? nil : stage
                }
            } label: {
                HStack(spacing: 12) {
                    Text(stage.letter)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(count > 0 ? .white : stage.color)
                        .frame(width: 36, height: 36)
                        .background(count > 0 ? stage.color : stage.color.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(stage.name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text(stage.description)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(isExpanded ? nil : 1)
                    }

                    Spacer()

                    if count > 0 {
                        Text("\(count)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(stage.color)
                            .clipShape(Circle())
                    }

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .padding(12)
            }
            .buttonStyle(.plain)

            // Expandable indicator chips
            if isExpanded {
                FlowLayout(spacing: 8) {
                    ForEach(stage.indicators, id: \.self) { indicator in
                        indicatorChip(stage: stage, indicator: indicator)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(count > 0 ? stage.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }

    // MARK: - Indicator Chip

    private func indicatorChip(stage: FASTERStage, indicator: String) -> some View {
        let selected = viewModel.isSelected(stage: stage, indicator: indicator)

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                viewModel.toggleIndicator(stage: stage, indicator: indicator)
            }
        } label: {
            Text(indicator)
                .font(RRFont.caption)
                .fontWeight(selected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(selected ? .white : Color.rrText)
                .background(selected ? stage.color : stage.color.opacity(0.1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(indicator), \(selected ? "selected" : "not selected")")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

#Preview {
    FASTERIndicatorSelectionView(viewModel: FASTERCheckInViewModel())
        .background(Color.rrBackground)
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERIndicatorSelectionView.swift
git commit -m "feat(ios): add FASTERIndicatorSelectionView with accordion and toggleable chips"
```

---

## Task 5: Create FASTERThermometerView

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERThermometerView.swift`

This implements PRD S-06: a vertical gradient bar showing the user's assessed position.

- [ ] **Step 1: Create the thermometer view**

```swift
import SwiftUI

struct FASTERThermometerView: View {
    let assessedStage: FASTERStage
    let selectedIndicators: [FASTERStage: Set<String>]

    /// Stages ordered top (safest) to bottom (most severe) for the thermometer.
    private let stageOrder: [FASTERStage] = [
        .restoration,
        .forgettingPriorities,
        .anxiety,
        .speedingUp,
        .tickedOff,
        .exhausted,
        .relapse,
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Gradient bar
            gradientBar
                .frame(width: 12)

            // Stage labels
            VStack(alignment: .leading, spacing: 0) {
                ForEach(stageOrder) { stage in
                    stageRow(stage)
                }
            }
        }
    }

    // MARK: - Gradient Bar

    private var gradientBar: some View {
        GeometryReader { geo in
            let segmentHeight = geo.size.height / CGFloat(stageOrder.count)

            ZStack(alignment: .top) {
                // Background gradient
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: stageOrder.map(\.color),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Position indicator
                let stageIndex = stageOrder.firstIndex(of: assessedStage) ?? 0
                let yOffset = CGFloat(stageIndex) * segmentHeight + segmentHeight / 2

                Circle()
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: assessedStage.color.opacity(0.5), radius: 4)
                    .overlay(
                        Circle()
                            .fill(assessedStage.color)
                            .frame(width: 10, height: 10)
                    )
                    .offset(y: yOffset - 9)
            }
        }
    }

    // MARK: - Stage Row

    private func stageRow(_ stage: FASTERStage) -> some View {
        let isAssessed = stage == assessedStage
        let count = selectedIndicators[stage]?.count ?? 0

        return HStack(spacing: 8) {
            Text(stage.letter)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isAssessed ? .white : stage.color)
                .frame(width: 28, height: 28)
                .background(isAssessed ? stage.color : stage.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 1) {
                Text(stage.name)
                    .font(isAssessed ? RRFont.headline : RRFont.caption)
                    .foregroundStyle(isAssessed ? Color.rrText : Color.rrTextSecondary)

                if count > 0 {
                    Text("\(count) indicator\(count == 1 ? "" : "s")")
                        .font(RRFont.caption2)
                        .foregroundStyle(stage.color)
                }
            }

            Spacer()

            if isAssessed {
                Image(systemName: "arrow.left")
                    .font(.caption)
                    .foregroundStyle(assessedStage.color)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(isAssessed ? assessedStage.color.opacity(0.08) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    RRCard {
        FASTERThermometerView(
            assessedStage: .anxiety,
            selectedIndicators: [
                .restoration: ["Attending meetings regularly"],
                .forgettingPriorities: ["Isolating from others"],
                .anxiety: ["Sleep problems or insomnia", "Vague worry or dread"],
            ]
        )
    }
    .padding()
    .background(Color.rrBackground)
}
```

- [ ] **Step 2: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERThermometerView.swift
git commit -m "feat(ios): add FASTERThermometerView gradient bar visualization"
```

---

## Task 6: Rewrite FASTERResultsView and Create FASTERCheckInFlowView

**Files:**
- Rewrite: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERResultsView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERCheckInFlowView.swift`

- [ ] **Step 1: Rewrite FASTERResultsView**

Replace the entire contents of `FASTERResultsView.swift` with:

```swift
import SwiftUI

struct FASTERResultsView: View {
    @Bindable var viewModel: FASTERCheckInViewModel
    let onSave: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Thermometer (S-06)
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        RRSectionHeader(title: "Your Assessment")
                        FASTERThermometerView(
                            assessedStage: viewModel.assessedStage,
                            selectedIndicators: viewModel.selectedIndicators
                        )
                    }
                }

                // Adaptive content (S-07)
                adaptiveContentCard

                // Journal (S-08)
                journalSection

                // Actions
                VStack(spacing: 12) {
                    RRButton("Save Check-In", icon: "checkmark.circle") {
                        onSave()
                    }

                    Button {
                        viewModel.goBackToIndicators()
                    } label: {
                        Text("Edit Selections")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.rrBackground)
    }

    // MARK: - Adaptive Content (S-07)

    private var adaptiveContentCard: some View {
        let content = viewModel.assessedStage.adaptiveContent
        return RRCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.assessedStage.color)
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

    // MARK: - Journal (S-08)

    private var journalSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 16) {
                RRSectionHeader(title: "Reflect")

                journalField(label: "Ah-ha (insight)", placeholder: "Something I noticed about myself today...", text: $viewModel.journalInsight)

                journalField(label: "Uh-oh (warning sign)", placeholder: "Something I need to watch out for...", text: $viewModel.journalWarning)

                journalField(label: "Anything else?", placeholder: "Optional — whatever is on your mind...", text: $viewModel.journalFreeText)
            }
        }
    }

    private func journalField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrTextSecondary)
            TextField(placeholder, text: text, axis: .vertical)
                .font(RRFont.body)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.rrBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .onChange(of: text.wrappedValue) { _, newValue in
                    if newValue.count > 1000 { text.wrappedValue = String(newValue.prefix(1000)) }
                }
        }
    }
}

#Preview {
    let vm = FASTERCheckInViewModel()
    vm.selectedIndicators = [
        .forgettingPriorities: ["Isolating from others"],
        .anxiety: ["Sleep problems or insomnia", "Vague worry or dread"],
    ]
    return FASTERResultsView(viewModel: vm, onSave: {})
}
```

- [ ] **Step 2: Create FASTERCheckInFlowView**

```swift
import SwiftUI
import SwiftData

struct FASTERCheckInFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var viewModel = FASTERCheckInViewModel()

    var body: some View {
        Group {
            switch viewModel.currentStep {
            case .mood:
                FASTERMoodPromptView { score in
                    viewModel.selectMood(score)
                }
            case .indicators:
                FASTERIndicatorSelectionView(viewModel: viewModel)
            case .results:
                FASTERResultsView(viewModel: viewModel) {
                    saveAndDismiss()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    private func saveAndDismiss() {
        let userId = users.first?.id ?? UUID()
        viewModel.save(context: modelContext, userId: userId)
        dismiss()
    }
}

#Preview {
    FASTERCheckInFlowView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 3: Make FASTERCheckInStep conform to Equatable**

In `FASTERCheckInViewModel.swift`, ensure the enum has Equatable conformance (it does by default as a simple enum, but verify `.animation` works).

- [ ] **Step 4: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERResultsView.swift
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERCheckInFlowView.swift
git commit -m "feat(ios): add FASTERCheckInFlowView state machine and rewrite FASTERResultsView"
```

---

## Task 7: Integration — Xcode Project, TodayView, QuickActionsRow, Build

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery.xcodeproj/project.pbxproj`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Today/TodayView.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Home/QuickActionsRow.swift`

- [ ] **Step 1: Add new files to Xcode project**

Four new files need to be added to the Xcode project (the FASTER group `50000301` already exists under Activities):

1. `FASTERCheckInFlowView.swift`
2. `FASTERIndicatorSelectionView.swift`
3. `FASTERThermometerView.swift`
4. `FASTERCheckInViewModel.swift`

For each file, add three entries to `project.pbxproj`:
- A `PBXBuildFile` entry (ID prefix `10000`)
- A `PBXFileReference` entry (ID prefix `20000`)
- Add the file ref to the appropriate group's children
- Add the build file to the Sources build phase

Use the next available IDs. The current highest IDs are approximately:
- Build files: `10000311`
- File refs: `20000311`
- Groups: `50000301`

New IDs to use:
- `10000400` / `20000400` — `FASTERCheckInFlowView.swift` (goes in FASTER group `50000301`)
- `10000401` / `20000401` — `FASTERIndicatorSelectionView.swift` (goes in FASTER group `50000301`)
- `10000402` / `20000402` — `FASTERThermometerView.swift` (goes in FASTER group `50000301`)
- `10000403` / `20000403` — `FASTERCheckInViewModel.swift` (goes in ViewModels group `50000030`)

Add `PBXBuildFile` entries after the last existing entry in that section:
```
10000400 /* FASTERCheckInFlowView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 20000400 /* FASTERCheckInFlowView.swift */; };
10000401 /* FASTERIndicatorSelectionView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 20000401 /* FASTERIndicatorSelectionView.swift */; };
10000402 /* FASTERThermometerView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 20000402 /* FASTERThermometerView.swift */; };
10000403 /* FASTERCheckInViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = 20000403 /* FASTERCheckInViewModel.swift */; };
```

Add `PBXFileReference` entries:
```
20000400 /* FASTERCheckInFlowView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FASTERCheckInFlowView.swift; sourceTree = "<group>"; };
20000401 /* FASTERIndicatorSelectionView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FASTERIndicatorSelectionView.swift; sourceTree = "<group>"; };
20000402 /* FASTERThermometerView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FASTERThermometerView.swift; sourceTree = "<group>"; };
20000403 /* FASTERCheckInViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FASTERCheckInViewModel.swift; sourceTree = "<group>"; };
```

Add `20000400`, `20000401`, `20000402` to FASTER group (`50000301`) children.
Add `20000403` to ViewModels group (`50000030`) children.
Add `10000400`, `10000401`, `10000402`, `10000403` to the Sources build phase.

Also add `FASTERResultsView.swift` back to the build (it was removed earlier). Use:
- `10000404` / the existing `20000119` file ref — but note: the file ref `20000119` was removed earlier. Re-add it:
```
20000119 /* FASTERResultsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FASTERResultsView.swift; sourceTree = "<group>"; };
10000404 /* FASTERResultsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = 20000119 /* FASTERResultsView.swift */; };
```
Add `20000119` to FASTER group children. Add `10000404` to Sources build phase.

- [ ] **Step 2: Update TodayView to use FASTERCheckInFlowView**

In `TodayView.swift`, the `showFASTERMood` state and `.fullScreenCover` should present `FASTERCheckInFlowView` instead of `FASTERMoodPromptView`:

Replace:
```swift
.fullScreenCover(isPresented: $showFASTERMood) {
    FASTERMoodPromptView { _ in
        showFASTERMood = false
    }
}
```

With:
```swift
.fullScreenCover(isPresented: $showFASTERMood) {
    FASTERCheckInFlowView()
}
```

Also remove the old standalone FASTER quick action card that navigates to `FASTERScaleView()` (around line 138):
```swift
quickActionCard(icon: "gauge.with.dots.needle.67percent", label: "FASTER", color: .orange) {
    FASTERScaleView()
}
```
Remove that block since the new FASTER quick action replaces it.

- [ ] **Step 3: Update QuickActionsRow to use FASTERCheckInFlowView**

In `QuickActionsRow.swift`, replace:
```swift
.fullScreenCover(isPresented: $showFASTER) {
    FASTERMoodPromptView { _ in
        showFASTER = false
    }
}
```

With:
```swift
.fullScreenCover(isPresented: $showFASTER) {
    FASTERCheckInFlowView()
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' build 2>&1 | tail -10`

Expected: **BUILD SUCCEEDED**

Fix any compilation errors. Common issues:
- Missing `import SwiftData` in views
- `@Bindable` requires iOS 17+ (already targeted)
- Exhaustive switch statements needing `.restoration` case

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery.xcodeproj/project.pbxproj
git add ios/RegalRecovery/RegalRecovery/Views/Today/TodayView.swift
git add ios/RegalRecovery/RegalRecovery/Views/Home/QuickActionsRow.swift
git commit -m "feat(ios): integrate FASTER check-in flow into TodayView and QuickActionsRow"
```

---

## Task 8: Final Build Verification and Cleanup

- [ ] **Step 1: Full clean build**

Run:
```bash
xcodebuild clean build -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.3.1' 2>&1 | tail -10
```

Expected: **BUILD SUCCEEDED**

- [ ] **Step 2: Verify the flow works end-to-end**

Manual verification checklist:
1. Launch app → Today tab → tap FASTER quick action → mood prompt appears
2. Select a mood → indicator accordion appears with 7 sections
3. Expand Anxiety → tap 2 chips → collapse → expand Forgetting Priorities → tap 1 chip
4. Tap "See My Results" → thermometer shows Anxiety as assessed stage
5. Adaptive content card shows "Grounding Exercise" content
6. Journal fields are editable
7. Tap "Save Check-In" → dismisses back to Today
8. Repeat from Home tab QuickActionsRow → same flow

- [ ] **Step 3: Commit any cleanup**

```bash
git add -A
git commit -m "fix(ios): FASTER check-in build fixes and cleanup"
```
