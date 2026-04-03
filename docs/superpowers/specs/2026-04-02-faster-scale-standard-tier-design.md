# FASTER Scale Check-In — Standard Tier Design

**Date:** 2026-04-02
**Scope:** Standard tier core check-in flow (S-01 through S-11 from PRD)
**Deferred:** Notifications (S-12), partner sharing (S-13/S-14), SOS (S-15), encryption specifics (S-16), data deletion (S-17), all Premium+ features

---

## 1. Data Model

### 1.1 Behavioral Indicator Catalog

A static data source mapping each stage to canonical behavioral indicators from the FASTER Scale framework. Used by the UI for chip rendering and by the assessment engine for stage calculation.

**Restoration:**
- No active secrets
- Keeping commitments
- Honest relationships
- Attending meetings
- Processing pain openly
- Growing in connection

**F — Forgetting Priorities:**
- Skipping meetings
- Isolating
- Keeping small secrets
- Sarcasm and cynicism
- Overconfidence
- Procrastinating
- Losing interest in growth
- Entertainment as escape

**A — Anxiety:**
- Vague worry or dread
- Negative self-talk replaying
- Sleep problems
- Perfectionism
- Judging others harshly
- People-pleasing
- Flirting for reassurance
- Unrealistic to-do lists

**S — Speeding Up:**
- Workaholic behavior
- Can't relax or sit still
- Skipping meals
- Excessive caffeine
- Over-exercising
- Racing thoughts at night
- Overspending
- Constant device use

**T — Ticked Off:**
- Resentment and bitterness
- Black-and-white thinking
- Blaming everyone else
- Defensiveness
- Road rage
- Self-pity
- Silent treatment
- Intimidation

**E — Exhausted:**
- Emotional numbness
- Hopelessness
- Spontaneous crying
- Intense cravings
- Survival mode
- Missing work or obligations
- Confusion and poor decisions
- Thoughts of self-harm

**R — Relapse:**
- Acting out on addictive behavior
- Breaking sobriety commitment

### 1.2 FASTERStage Enum (Swift)

Add `restoration` case. Shift raw values so restoration = 0, F = 1, A = 2, S = 3, T = 4, E = 5, R = 6.

New computed properties per case:
- `name: String` — stage name
- `letter: String` — display letter (Restoration uses "✦")
- `subtitle: String` — short tagline
- `description: String` — 2-3 sentence summary for accordion card body
- `color: Color` — updated palette matching HTML content
- `indicators: [String]` — canonical behavioral indicators for the stage

Color palette:
| Stage | Hex | SwiftUI mapping |
|-------|-----|-----------------|
| Restoration | #2D6A4F | Custom color |
| F | #7B9E3D | Custom color |
| A | #C9A227 | Custom color |
| S | #D4802A | Custom color |
| T | #C95D2E | Custom color |
| E | #A63D40 | Custom color |
| R | #6B2737 | Custom color |

### 1.3 RRFASTEREntry SwiftData Model

Expand from current fields (`id, userId, date, stage, createdAt, modifiedAt`) to:

| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Primary key (unchanged) |
| userId | UUID | Owner (unchanged) |
| date | Date | Check-in date (unchanged) |
| assessedStage | Int | Computed lowest stage with selection (replaces `stage`) |
| moodScore | Int | Opening mood prompt value (1-5) |
| selectedIndicators | [String] | All toggled indicator strings, stored as JSON-encoded array |
| journalInsight | String | "Ah-ha" field, max 1000 chars |
| journalWarning | String | "Uh-oh" field, max 1000 chars |
| journalFreeText | String | Optional free-text, max 1000 chars |
| createdAt | Date | (unchanged) |
| modifiedAt | Date | (unchanged) |

Migration: existing entries with only a `stage` value and no indicators are treated as legacy manual assessments. The `stage` field is renamed to `assessedStage`.

### 1.4 FASTERData Backend Type (Go)

Expand from current (`Stage, Description, Notes`) to:

```go
type FASTERData struct {
    Stage              string              `json:"stage"`              // "restoration", "F", "A", "S", "T", "E", "R"
    SelectedIndicators map[string][]string `json:"selectedIndicators"` // stage key → selected indicator strings
    MoodScore          int                 `json:"moodScore"`          // 1-5
    JournalInsight     string              `json:"journalInsight"`     // "Ah-ha"
    JournalWarning     string              `json:"journalWarning"`     // "Uh-oh"
    JournalFreeText    string              `json:"journalFreeText"`    // optional free-text
}
```

---

## 2. Check-In Flow & UI

### 2.1 Flow Sequence

1. **Mood prompt** — "How are you doing right now?" with 5 selectable icons spanning great → struggling. One tap advances to the scale.
2. **FASTER Scale accordion** — Seven expandable cards: Restoration at top, then F→A→S→T→E→R descending.
3. **Submit** — "Complete Check-In" button, disabled until at least one indicator is toggled.
4. **Results screen** — Thermometer visualization → stage-adaptive content → structured journal → save.

### 2.2 Accordion Cards

Each card displays:
- **Collapsed:** Stage letter badge (colored), stage name, subtitle, selected indicator count badge
- **Expanded:** Stage description paragraph + indicator chips as toggleable pills

Behavior:
- Tapping header toggles open/close
- Multiple cards can be open simultaneously
- Chips toggle on/off with visible state change (outlined vs. filled with stage color)
- Selections persist within the session until submission

### 2.3 Thermometer Visualization

Vertical bar (~200pt tall) with seven segments colored per stage. A marker dot shows the assessed position. Stage labels along the side. Restoration (green) at top, Relapse (dark maroon) at bottom.

### 2.4 Assessment Logic

Assessed stage = the lowest (most severe) stage in which at least one indicator is selected. If only Restoration indicators are selected, user is in Restoration. Stages stack cumulatively per FASTER Scale rules.

### 2.5 Stage-Adaptive Content

Static content displayed as a card after the thermometer:

| Stage | Content |
|-------|---------|
| Restoration | Encouragement message + suggested maintenance activity |
| F | Priority-review checklist (meetings, partner contact, commitments) |
| A | Guided breathing prompt (5-4-3-2-1 grounding exercise) |
| S | Slow-down challenge ("Take 10 minutes to do nothing") |
| T | Feeling Wheel reference + anger-management prompt |
| E | Strong prompt to contact accountability partner + crisis resource text |
| R | Crisis support info (988 Lifeline) + Recovery Action Plan prompt |

### 2.6 Structured Journal

Three text fields displayed after adaptive content:
- "Ah-ha (insight)" — labeled field, 1000 char limit
- "Uh-oh (warning sign)" — labeled field, 1000 char limit
- "Anything else?" — optional free-text, 1000 char limit

All optional. User can save check-in without journaling.

### 2.7 View Architecture

| View | Purpose |
|------|---------|
| `FASTERScaleView` | Full check-in flow (mood → accordion → results) |
| `FASTERScaleToolView` | Read-only reference: stage descriptions + history grid + engagement count |
| `FASTERMoodPromptView` | 5-icon mood entry screen (extracted subview) |
| `FASTERStageCardView` | Single expandable accordion card with indicator chips (extracted subview) |
| `FASTERThermometerView` | Vertical gradient bar visualization (extracted subview) |
| `FASTERResultsView` | Thermometer + adaptive content + journal (extracted subview) |
| `FASTERIndicatorChip` | Single toggleable pill (extracted subview) |

### 2.8 ViewModel

`FASTERScaleViewModel` becomes the check-in orchestrator:

**State:**
- `moodScore: Int?`
- `selectedIndicators: [FASTERStage: Set<String>]`
- `currentPhase: CheckInPhase` (enum: `.mood`, `.scale`, `.results`)
- `journalInsight: String`
- `journalWarning: String`
- `journalFreeText: String`

**Computed:**
- `assessedStage: FASTERStage` — lowest stage with any selection, or `.restoration` if only restoration indicators

**Actions:**
- `selectMood(_: Int)`
- `toggleIndicator(stage: FASTERStage, indicator: String)`
- `submit()` — transitions to results phase
- `save()` — persists full check-in to SwiftData

---

## 3. Stage Content & History

### 3.1 Enriched Stage Descriptions

Condensed from the HTML educational content for mobile display:

| Stage | Subtitle | Description |
|-------|----------|-------------|
| Restoration | The starting line | You're being honest, staying connected, keeping your commitments, and dealing with problems as they come up. No current secrets. This is where recovery lives — not perfection, but presence. |
| F | The quiet drift | The most subtle stage. You start drifting from the things that keep you healthy — skipping a meeting, losing touch with your partner, spending more time scrolling than connecting. Overconfidence is the hallmark. |
| A | The background noise gets louder | A growing sense of unease moves in. Old negative thoughts replay. Your brain picks up on the drift and tags it as danger. Sleep gets worse, you become more judgmental, and current stresses start feeling catastrophic. |
| S | Running from the pain you won't name | You can't outrun anxiety, but you're going to try. Relentless busyness — staying so occupied you never sit with your feelings. Deceptive because culture rewards it. Underneath is someone terrified to slow down. |
| T | Anger takes the wheel | Anger has become your primary coping mechanism. It works temporarily — provides adrenaline, makes you feel powerful, gives you someone to blame. Black-and-white thinking, keeping score, defensiveness, self-pity. |
| E | The crash | The adrenaline from anger has run out. Heavy fog — depression, hopelessness, emotional numbness. Cravings become overwhelming because your brain is desperately searching for anything that feels normal. This is the danger zone. |
| R | The cycle restarts | The behavior returns. And immediately, the shame arrives. The cruelest part: shame drives isolation, which restarts the entire FASTER descent. Relapse is not the end of recovery — it is information. |

### 3.2 History Enhancement

- 30-day dot grid colored by assessed stage (7-color palette)
- Tapping a dot shows popover: date, mood score, assessed stage, indicator count, journal preview
- Cumulative engagement counter: "X check-ins this month" (no streak counters, per S-11)

### 3.3 Three Rules (Informational)

Accessible from a help/info icon in the check-in flow. Displayed on first use:
1. You can only go down, never back up — must "get off" the scale by addressing the underlying issue
2. Stages stack — you carry all the ones above you
3. No stages can be skipped — sequence is always the same, only speed varies

---

## 4. Files Modified

### Backend (Go)
- `api/internal/domain/activities/types.go` — expand `FASTERData` struct

### Frontend (Swift)
- `ios/.../Models/Types.swift` — rebuild `FASTERStage` enum with restoration, indicators, descriptions, colors
- `ios/.../Data/Models/RRModels.swift` — expand `RRFASTEREntry` with indicators, mood, journal fields
- `ios/.../ViewModels/FASTERScaleViewModel.swift` — full rewrite as check-in orchestrator
- `ios/.../Views/Activities/FASTERScaleView.swift` — full rewrite as multi-phase check-in flow
- `ios/.../Views/Tools/FASTERScaleToolView.swift` — update to read-only reference with enhanced history
- New files:
  - `ios/.../Views/Activities/FASTER/FASTERMoodPromptView.swift`
  - `ios/.../Views/Activities/FASTER/FASTERStageCardView.swift`
  - `ios/.../Views/Activities/FASTER/FASTERThermometerView.swift`
  - `ios/.../Views/Activities/FASTER/FASTERResultsView.swift`
  - `ios/.../Views/Activities/FASTER/FASTERIndicatorChip.swift`
