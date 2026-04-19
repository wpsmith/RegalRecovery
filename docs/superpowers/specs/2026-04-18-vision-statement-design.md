# Vision Statement Feature — Design Spec

## Overview

A structured tool for users to articulate their personal recovery vision, core values, and the life they are working toward. Includes a guided wizard for creation, a hub screen for viewing/editing, a home screen card for daily visibility, and version history tracking.

Scope: P0 + P1 requirements from FRD-VSN. Deferred: P2 (auto-synthesize prompt responses, configurable review reminders, export as formatted text).

Single feature flag: `feature.vision` (already exists, default `false`).

## Architecture

Follows the Three Circles builder pattern: Observable ViewModel drives a multi-step wizard with draft persistence, separate view files per step, and SwiftData for persistent storage.

### File Structure

```
Views/Tools/Vision/
  VisionHubView.swift          — empty state + populated state + history access
  VisionWizardView.swift       — container: progress bar, step navigation, draft resume
  VisionPromptsStepView.swift  — one prompt per screen with skip/next
  VisionIdentityStepView.swift — "I am becoming..." input with character counter
  VisionValuesStepView.swift   — grid of value chips, tap to select, drag to reorder
  VisionScriptureStepView.swift— category filters, search, freeform entry
  VisionReviewStepView.swift   — full draft, inline editing, save button
  VisionHistoryView.swift      — timeline of previous versions

ViewModels/
  VisionWizardViewModel.swift  — step state, draft persistence, validation
  VisionHubViewModel.swift     — load current vision, version history queries

Views/Home/
  VisionCard.swift             — compact home screen card

Models/
  VisionTypes.swift            — WizardStep enum, curated values, scripture library
```

### Modified Files

- `RRModels.swift` — add `RRVisionStatement` model
- `RRModelConfiguration.allModels` — register `RRVisionStatement.self`
- `FeatureFlagStore.flagDefaults` — no changes needed; `feature.vision` already exists
- `ToolsView.swift` — add Vision Statement tool card (gated)
- `HomeView.swift` — add VisionCard after CommitmentsCard (gated)
- `MorningCommitmentView.swift` — add optional vision snippet (gated)

## Data Model

Added to `RRModels.swift`, following existing conventions:

```swift
@Model
final class RRVisionStatement {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var identityStatement: String          // "I am becoming..." (max 280 chars)
    var visionBody: String                 // Full vision text (max 2000 chars)
    var coreValues: [String]              // Ordered list, max 10
    var scriptureReference: String?        // e.g., "Proverbs 29:18"
    var scriptureText: String?            // The actual verse text
    var promptResponsesJSON: String?      // JSON-encoded [String: String] (promptIndex -> response)
    var version: Int                       // Auto-incrementing version number
    var isCurrent: Bool                   // Only one version is current
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        identityStatement: String,
        visionBody: String = "",
        coreValues: [String] = [],
        scriptureReference: String? = nil,
        scriptureText: String? = nil,
        promptResponsesJSON: String? = nil,
        version: Int = 1,
        isCurrent: Bool = true,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) { ... }
}
```

`promptResponsesJSON` uses the same JSON-string-in-property pattern as `RRFASTEREntry.selectedIndicatorsJSON` — a computed property decodes/encodes `[String: String]`.

## Wizard Flow

### Steps

```
.prompts(index: Int)  — 4 prompts, one per screen (index 0-3)
.identity             — "I am becoming..." statement
.values               — core values selection + ordering
.scripture            — scripture attachment
.review               — full draft, inline edit, save
```

Progress bar: "Step X of 8" (4 prompts + identity + values + scripture + review).

### Prompts

1. "What does your life look like one year from now if recovery goes well?"
2. "What kind of husband, father, or friend do you want to be?"
3. "What would you do with your time and energy if addiction no longer consumed it?"
4. "What does faithfulness to God look like in your daily life?"

Each: 500 char max, skippable, text field with character counter.

### VisionWizardViewModel

`@Observable` class managing:

- `currentStep` — drives the view switch
- `promptResponses: [Int: String]` — keyed by prompt index
- `identityStatement: String`, `visionBody: String`
- `selectedValues: [String]` — ordered, max 10
- `scriptureReference: String?`, `scriptureText: String?`
- `canProceed: Bool` — computed per step (prompts: always true; identity: non-empty required; values: at least 1; scripture: always true; review: identity required)
- `canGoBack: Bool`, `canSkip: Bool` — computed per step

**Draft persistence:** JSON in UserDefaults under `"vision.wizard.draft"`. Auto-save on every step transition. Resume alert on reopen. Clear on successful save.

**Editing mode:** When editing an existing vision, the wizard opens pre-populated with current values. `editingVisionId: UUID?` tracks this.

### Save Logic

1. If editing: set current version's `isCurrent = false`, create new `RRVisionStatement` with `version = previous + 1`, `isCurrent = true`
2. If first vision: create with `version = 1`, `isCurrent = true`
3. Clear draft from UserDefaults
4. Dismiss wizard

## Vision Hub Screen

Accessible from Tools tab. NavigationStack-based.

### Empty State

- SF Symbol `eye.fill` (48pt, `rrPrimary`)
- Headline: "Your recovery needs a destination"
- Subtext: "A vision statement answers: What kind of man am I becoming?"
- Footer caption: "Your vision is not a promise you are making. It is a direction you are facing."
- `RRButton("Create My Vision", icon: "plus")` — presents wizard

### Populated State

- `RRCard` with identity statement as header (title weight)
- Vision body (body font, secondary color, line-limited with "Read more" expansion)
- Core values as colored capsule chips in `FlowLayout`
- Scripture reference + text (italic caption)
- "Last updated X days ago" indicator
- Navigation bar: "Edit" (opens pre-populated wizard), "History" (pushes VisionHistoryView)

### Version History

- Vertical timeline with date headers
- Each row: version number, date, first 100 characters of identity statement
- Tap expands full vision text in a detail sheet

## Values Selection

### Curated Values

Honesty, Integrity, Humility, Courage, Faithfulness, Service, Patience, Gratitude, Vulnerability, Discipline, Compassion, Self-Control, Perseverance, Wisdom, Gentleness

### UX

- `FlowLayout` grid of capsule chips (filled = selected, outlined = unselected)
- Selected values appear in reorderable list below showing priority order
- Drag handles for reordering (P1: top 5 ranking)
- "Add Custom Value" button — inline text field
- Max 10 selected; at limit, unselected chips dimmed with message

## Scripture Library

### Data

Static data in `VisionTypes.swift`, ~20-25 verses organized by category:

```swift
enum ScriptureCategory: String, CaseIterable {
    case identity, hope, transformation, strength, freedom, faithfulness
}

struct ScriptureEntry {
    let reference: String
    let text: String
    let category: ScriptureCategory
}
```

### UX

- Category filter chips (horizontal scroll)
- Filtered list of suggested verses — tap to select
- Search field filtering by reference or text
- "Or enter your own" freeform section: reference + verse text fields
- Optional — can skip entirely

## Home Screen Card

`VisionCard` in `Views/Home/VisionCard.swift`:

- Compact `RRCard` with subtle `rrPrimary` border (1pt, 0.3 opacity)
- Identity statement in headline font
- Scripture reference in caption, secondary color
- Tap navigates to VisionHubView
- Shown only when `feature.vision` enabled AND user has current vision

Placement in HomeView: after CommitmentsCard, before QuickActionsRow.

## Morning Commitment Integration (P1)

In `MorningCommitmentView`, after commitment completes:

- Optional "Your Vision" snippet: identity statement in small card
- "Tap to read full vision" link
- Gated behind `feature.vision` + user has current vision

## Feature Flag

Single flag: `feature.vision` (already in `FeatureFlagStore.flagDefaults`, default `false`).

Gates: Tools card, Home card, Morning Commitment snippet, all Vision views.

## Edge Cases

| Scenario | Handling |
|----------|----------|
| Empty vision body | Identity statement required to save; vision body can be empty |
| Character limits | Visible counter on all text fields; enforce max in ViewModel |
| Wizard abandonment | Auto-save draft to UserDefaults; resume on reopen |
| Editing existing | Pre-populate wizard; save creates new version |
| Values at cap (10) | Dim unselected chips, show message |
| Scripture not in library | Freeform entry always available |
| No vision yet (home card) | Card not rendered |
| Draft from previous session | Resume alert with "Resume" / "Start Fresh" options |
| Delete vision | Allow full deletion with confirmation dialog; removes all versions |
