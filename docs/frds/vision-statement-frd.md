# Feature Requirements Document: Vision Statement

## FRD-VSN — Personal Recovery Vision & Values Declaration Tool

---

## 1. Overview

The Vision Statement feature provides users with a structured tool to articulate their personal recovery vision, core values, and the life they are working toward. In recovery, especially from sexual addiction, shame and hopelessness can obscure any sense of a future worth building. This tool helps users externalize their "why" -- the aspirational identity and life that motivates daily discipline.

A recovery vision statement answers: "What kind of man am I becoming?" It bridges the gap between daily sobriety mechanics and the deeper transformation that recovery makes possible. Rooted in Proverbs 29:18 ("Where there is no vision, the people perish"), this feature grounds spiritual aspiration in concrete, revisitable language.

### Why It Matters
- **Purpose anchoring**: On difficult days, a personal vision statement reconnects users to their deeper motivation beyond streak counting
- **Identity reframing**: Shifts focus from "I am an addict" to "I am a man becoming..."
- **Therapeutic alignment**: Many CSAT (Certified Sex Addiction Therapist) programs include vision/values work as foundational
- **Celebrate Recovery integration**: Step 2 ("Came to believe...") and Step 3 ("Made a decision...") naturally lead to vision articulation
- **Relapse prevention**: A vivid, personally meaningful vision of the future is a protective factor against relapse

---

## 2. User Stories

| ID | Story |
|----|-------|
| US-VSN-001 | As a recovering person, I want to write a personal recovery vision statement so that I can articulate the life I am working toward. |
| US-VSN-002 | As a recovering person, I want guided prompts to help me write my vision so that I do not stare at a blank page. |
| US-VSN-003 | As a recovering person, I want to identify and prioritize my core recovery values so that my daily decisions align with what matters most. |
| US-VSN-004 | As a recovering person, I want to revisit and revise my vision over time so that it grows with my recovery. |
| US-VSN-005 | As a recovering person, I want to see my vision statement easily from my home screen so that it serves as a daily anchor. |
| US-VSN-006 | As a recovering person, I want to attach a key scripture to my vision so that my spiritual foundation is visible. |
| US-VSN-007 | As a recovering person, I want to share my vision with my accountability partner or counselor so that they can support my growth. |
| US-VSN-008 | As a recovering person, I want version history of my vision so that I can see how my thinking has evolved over time. |

---

## 3. Functional Requirements

### 3.1 Vision Statement Composition

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-VSN-001 | The system shall provide a guided wizard for first-time vision creation with 4-6 reflection prompts. | P0 |
| FR-VSN-002 | The system shall allow freeform text entry for the vision statement body (max 2,000 characters). | P0 |
| FR-VSN-003 | The system shall provide a curated list of recovery-relevant values (e.g., honesty, integrity, humility, courage, faithfulness, service, patience, gratitude, vulnerability, discipline) for the user to select from. | P0 |
| FR-VSN-004 | The system shall allow the user to add custom values not in the curated list. | P1 |
| FR-VSN-005 | The system shall allow the user to rank their top 5 values in priority order. | P1 |
| FR-VSN-006 | The system shall allow the user to attach one primary scripture reference to their vision. | P0 |
| FR-VSN-007 | The system shall provide a library of suggested scriptures categorized by theme (identity, hope, transformation, strength, freedom, faithfulness). | P1 |
| FR-VSN-008 | The system shall allow the user to write a short "I am becoming..." identity statement (max 280 characters). | P0 |

### 3.2 Guided Prompts

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-VSN-010 | The guided wizard shall include prompts such as: "What does your life look like one year from now if recovery goes well?", "What kind of husband/father/friend do you want to be?", "What would you do with your time and energy if addiction no longer consumed it?", "What does faithfulness to God look like in your daily life?" | P0 |
| FR-VSN-011 | Each prompt shall allow a text response of up to 500 characters. | P0 |
| FR-VSN-012 | The system shall synthesize prompt responses into a draft vision statement the user can edit. | P2 |
| FR-VSN-013 | The user shall be able to skip the wizard and write freely at any time. | P0 |

### 3.3 Revision & History

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-VSN-020 | The system shall store each saved version of the vision statement with a timestamp. | P0 |
| FR-VSN-021 | The system shall allow the user to view previous versions in a timeline. | P1 |
| FR-VSN-022 | The system shall display a "Last updated X days ago" indicator to encourage periodic review. | P1 |
| FR-VSN-023 | The system shall prompt the user to review their vision at configurable intervals (default: every 30 days). | P2 |

### 3.4 Visibility & Integration

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-VSN-030 | The "I am becoming..." statement shall be displayable as a card on the Home screen. | P0 |
| FR-VSN-031 | The full vision statement shall be accessible from the Tools section. | P0 |
| FR-VSN-032 | The vision statement shall be viewable during the Morning Commitment flow as optional inspiration. | P1 |
| FR-VSN-033 | The system shall allow the user to export their vision statement as formatted text (for sharing with a counselor). | P2 |

---

## 4. Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-VSN-001 | Vision statement text shall be stored only on-device until the user explicitly enables sync. |
| NFR-VSN-002 | Vision data shall be encrypted at rest using SwiftData encryption. |
| NFR-VSN-003 | The vision composition flow shall be fully accessible via VoiceOver with all prompts readable. |
| NFR-VSN-004 | The vision card shall render within 100ms on the Home screen. |
| NFR-VSN-005 | The feature shall support Dynamic Type for all text elements. |
| NFR-VSN-006 | Vision statement content shall never be included in analytics or telemetry. |

---

## 5. UI/UX Specifications

### 5.1 Vision Hub Screen (Tools > Vision Statement)

- **Empty state**: Warm illustration with "Your recovery needs a destination" message and "Create My Vision" CTA button
- **Populated state**: Full vision statement displayed as a styled card with the "I am becoming..." statement as a prominent header, core values as colored chips below, scripture reference at the bottom, and an "Edit" button
- **Version history**: Accessible via a "History" icon in the navigation bar, showing a vertical timeline of edits with date and first 100 characters of each version

### 5.2 Vision Creation Wizard

- **Step 1 — Prompts**: One prompt per screen with a text field, progress bar showing step X of N, "Skip" and "Next" buttons
- **Step 2 — Identity Statement**: "I am becoming..." input with character counter, sample statements shown as inspiration chips
- **Step 3 — Values Selection**: Grid of value chips; tap to select, long-press for definition; drag to reorder top 5
- **Step 4 — Scripture**: Search field with category filters; suggested verses shown; option to type a custom reference
- **Step 5 — Review & Refine**: Full draft shown; all sections editable inline; "Save Vision" button

### 5.3 Home Screen Card

- Compact card showing the "I am becoming..." statement and primary scripture
- Tap to expand to full vision statement
- Subtle glow or accent border in the app's primary color

### 5.4 Navigation

- Accessible from: Tools tab, Home screen card, Morning Commitment (optional link)
- Back navigation preserves draft state

---

## 6. Data Model

```swift
// MARK: - SwiftData Models

@Model
final class RRVisionStatement {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var identityStatement: String          // "I am becoming..." (max 280 chars)
    var visionBody: String                  // Full vision text (max 2000 chars)
    var coreValues: [String]               // Ordered list, max 10
    var scriptureReference: String?         // e.g., "Proverbs 29:18"
    var scriptureText: String?             // The actual verse text
    var promptResponses: [String: String]  // promptId -> response text
    var version: Int                        // Auto-incrementing version number
    var createdAt: Date
    var modifiedAt: Date
    var isCurrent: Bool                    // Only one version is current
    var syncStatus: SyncStatus
    
    init(userId: UUID, identityStatement: String, visionBody: String) {
        self.id = UUID()
        self.userId = userId
        self.identityStatement = identityStatement
        self.visionBody = visionBody
        self.coreValues = []
        self.version = 1
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isCurrent = true
        self.syncStatus = .pending
    }
}
```

---

## 7. Integration Points

| Integration | Description |
|-------------|-------------|
| **Home Screen** | "I am becoming..." card displayed in the daily overview section |
| **Morning Commitment** | Optional: display vision excerpt during commitment flow for motivation |
| **Evening Review** | Optional: "Did your actions today align with your vision?" reflection prompt |
| **Post-Mortem** | Reference vision statement as part of "What was I working toward?" reflection |
| **Relapse Prevention Plan** | Vision statement is referenced as a motivational anchor in the prevention plan |
| **Accountability Sharing** | Export-ready format for counselor/sponsor review |
| **Daily Score** | Reviewing/updating vision could count toward daily recovery score |
| **Notifications** | Periodic review reminders |

---

## 8. Offline Behavior

| Scenario | Behavior |
|----------|----------|
| No internet | Full functionality — vision creation, editing, and viewing work entirely offline |
| Draft saving | Auto-save draft every 30 seconds during editing |
| Sync on reconnect | Vision data syncs to backend when connectivity is restored |
| Conflict resolution | Latest-write-wins for vision statement; all versions preserved in history |

---

## 9. Feature Flag

| Key | Default | Description |
|-----|---------|-------------|
| `feature.vision-statement` | `false` | Master toggle for the Vision Statement feature |
| `feature.vision-statement.home-card` | `false` | Toggle for the Home screen vision card |
| `feature.vision-statement.morning-integration` | `false` | Toggle for Morning Commitment integration |

---

## 10. Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC-VSN-001 | Given a new user with no vision statement, when they navigate to Tools > Vision Statement, then they see the empty state with a "Create My Vision" button. |
| AC-VSN-002 | Given a user in the creation wizard, when they complete all prompt steps, then a draft vision statement is generated from their responses. |
| AC-VSN-003 | Given a user editing their vision, when they save, then the previous version is preserved in history and the new version becomes current. |
| AC-VSN-004 | Given a user with a vision statement, when they view the Home screen, then the "I am becoming..." card is displayed (if the home-card flag is enabled). |
| AC-VSN-005 | Given a user with no internet, when they create or edit their vision, then all changes are saved locally and queued for sync. |
| AC-VSN-006 | Given a user selecting core values, when they select more than 10, then the system prevents additional selections and shows a message. |
| AC-VSN-007 | Given a user viewing version history, when they tap a previous version, then the full text of that version is displayed with its timestamp. |
| AC-VSN-008 | Given a user in the wizard, when they tap "Skip" on any prompt, then they advance to the next step without that prompt being required. |
| AC-VSN-009 | Given a user who has not reviewed their vision in 30+ days, when a review reminder is enabled, then a notification prompts them to revisit. |
| AC-VSN-010 | Given a vision statement with a scripture reference, when the user views the full vision, then the scripture text is displayed alongside the reference. |

---

## 11. Edge Cases

| Scenario | Handling |
|----------|----------|
| **Empty vision body** | Require at minimum the "I am becoming..." statement (identity statement) to save; vision body can be empty initially |
| **Very long text input** | Enforce character limits with visible counter; truncate gracefully if data arrives from sync exceeding limits |
| **Wizard abandonment** | Auto-save partial progress as a draft; resume from where the user left off |
| **Multiple devices** | Sync latest version; if conflict, prefer the version with the most recent `modifiedAt` timestamp; preserve both in history |
| **Values list exhaustion** | If user selects all curated values, allow continued addition of custom values up to the 10-value cap |
| **Scripture not found** | Allow freeform scripture reference input even if not in the suggested library |
| **First day of recovery** | Prompts should be approachable for someone on Day 1; avoid language that assumes long-term recovery experience |
| **Vision feels aspirational vs. realistic** | Include a note: "Your vision is not a promise you are making. It is a direction you are facing." |
| **Emotional difficulty writing** | Provide a "Come back later" option; do not force completion; save progress automatically |
| **Deletion request** | Allow full deletion of vision statement (all versions) with confirmation dialog; respect data subject rights |
