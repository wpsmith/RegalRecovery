# Post-Mortem Analysis -- Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Source:** `docs/prd/specific-features/PostMortem/Post_Mortem_Analysis_Activity.md`

---

## Naming Convention

Each acceptance criterion has a unique ID: `PM-AC{section}.{number}` where section maps to a functional area.

---

## 1. Guided Walkthrough (PM-AC1)

### PM-AC1.1 -- Six-Section Walkthrough Structure

**Given** a user initiates a post-mortem analysis,
**When** they begin the walkthrough,
**Then** the system presents six sequential sections: (1) The Day Before, (2) Morning, (3) Throughout the Day, (4) The Build-Up, (5) The Acting Out, (6) Immediately After.

### PM-AC1.2 -- Section: The Day Before

**Given** a user is in the "The Day Before" section,
**When** they complete the section,
**Then** the system accepts free-text input (max 5000 chars) and an optional mood rating (integer 1-10), capturing emotional/spiritual state, recovery practice adherence, and unresolved conflicts.

### PM-AC1.3 -- Section: Morning with Auto-Population

**Given** a user is in the "Morning" section and has recovery data for the relevant date,
**When** the section loads,
**Then** the system auto-populates available data: morning commitment completion status, mood rating, and affirmation viewed status. The user can edit or supplement this data with free-text.

### PM-AC1.4 -- Section: Throughout the Day with Time Blocks

**Given** a user is in the "Throughout the Day" section,
**When** they enter data,
**Then** the system provides guided time-block prompts (morning, midday, afternoon, evening) where each block captures: activity, location, company, thoughts, and feelings. The user may also enter free-form hour-by-hour entries.

### PM-AC1.5 -- Section: Throughout the Day Warning Sign Identification

**Given** a user is entering data for a time block,
**When** they describe events,
**Then** the system allows tagging warning signs from FASTER Scale stages, PCI behaviors, and acting-in behaviors for each time block.

### PM-AC1.6 -- Section: The Build-Up with Decision Points

**Given** a user is in "The Build-Up" section,
**When** they complete the section,
**Then** the system captures: when they first noticed something was off, accumulated triggers (from the standard trigger categories: Emotional, Environmental, Relational, Physical, Digital, Spiritual), what they did or didn't do in response, moments they considered reaching out but didn't (with reasons), and structured decision points in the format "At this moment, I could have _____ but instead I _____".

### PM-AC1.7 -- Section: The Acting Out

**Given** a user is in "The Acting Out" section,
**When** they complete it,
**Then** the system captures: free-text description of what happened, which addiction was involved (auto-linked to relapse log if one exists), and episode duration in minutes. All prompts use compassionate, non-judgmental tone.

### PM-AC1.8 -- Section: Immediately After with Feelings Wheel

**Given** a user is in "Immediately After" section,
**When** they complete it,
**Then** the system captures: emotional state (via Feelings Wheel integration), what the user did next, whether they reached out to anyone (boolean + optional contact reference), and what they wish they had done differently.

### PM-AC1.9 -- Relapse Link Optional

**Given** a user creates a post-mortem,
**When** they provide a `relapseId`,
**Then** the post-mortem is linked to the relapse record. **When** they omit the `relapseId`,
**Then** the post-mortem is still created as a standalone analysis (e.g., for near-miss events).

---

## 2. Auto-Save and Draft Resumption (PM-AC2)

### PM-AC2.1 -- Auto-Save Progress

**Given** a user is partway through a post-mortem walkthrough,
**When** they leave the app or navigate away,
**Then** the system auto-saves all completed sections and partial input in the current section as a draft with status `draft`.

### PM-AC2.2 -- Resume Draft

**Given** a user has an incomplete post-mortem draft,
**When** they return to the post-mortem feature,
**Then** the system prompts them to resume where they left off, restoring all previously saved section data.

### PM-AC2.3 -- Draft to Complete Transition

**Given** a user completes all six sections and the action plan,
**When** they submit the post-mortem,
**Then** the status transitions from `draft` to `complete` and the `completedAt` timestamp is set. The analysis is now visible to shared contacts (if sharing is enabled).

---

## 3. Visual Timeline (PM-AC3)

### PM-AC3.1 -- Timeline Generation

**Given** a completed post-mortem analysis,
**When** the user views the timeline,
**Then** the system displays an interactive 24-hour timeline with each of the six sections mapped to time segments, events/emotions/decisions plotted as data points, and FASTER Scale stages overlaid as color-coded bands (green through red).

### PM-AC3.2 -- Trigger Accumulation Visualization

**Given** a completed post-mortem with trigger data,
**When** the user views the timeline,
**Then** triggers are shown as stacking indicators on the timeline, visually representing accumulation over time.

### PM-AC3.3 -- Decision Point Interaction

**Given** the timeline displays decision points,
**When** the user taps a decision point icon,
**Then** the system shows the user's reflection on what they could have done differently at that moment.

---

## 4. Trigger Identification (PM-AC4)

### PM-AC4.1 -- Quick-Select Triggers

**Given** a user is identifying triggers,
**When** they select triggers,
**Then** the system provides quick-select chips using the same categories as Urge Logging: Emotional, Environmental, Relational, Physical, Digital, Spiritual.

### PM-AC4.2 -- Deep Trigger Exploration

**Given** a user has identified a surface-level trigger,
**When** they tap to explore deeper,
**Then** the system prompts a three-layer exploration: Surface Trigger -> Underlying Emotion -> Core Wound (e.g., Boredom -> Loneliness -> Fear of being unlovable).

### PM-AC4.3 -- Cross-Analysis Pattern Linking

**Given** a user has completed multiple post-mortems,
**When** they identify a trigger that appeared in a previous post-mortem,
**Then** the system surfaces: "This trigger also appeared in your post-mortem from [date]."

---

## 5. FASTER Scale Mapping (PM-AC5)

### PM-AC5.1 -- Stage Mapping to Timeline

**Given** a user has completed the walkthrough sections,
**When** they enter the FASTER Scale mapping phase,
**Then** the system allows the user to assign FASTER stages (Forgetting, Anxiety, Speeding, Ticked Off, Exhausted, Relapse) to each point/block on the timeline.

### PM-AC5.2 -- Pre-Populated Suggestions

**Given** the user's walkthrough text mentions keywords associated with FASTER stages (e.g., "skipping meetings" maps to Forgetting Priorities),
**When** the mapping phase loads,
**Then** the system pre-populates suggested stage assignments that the user can confirm or adjust.

### PM-AC5.3 -- FASTER Progression Visualization

**Given** the user has completed FASTER mapping,
**When** they view the result,
**Then** a clear visual shows how the FASTER progression unfolded across the day, with color-coded bands from green (Restoration) through red (Relapse).

---

## 6. Action Plan (PM-AC6)

### PM-AC6.1 -- Structured Action Items

**Given** a user is creating an action plan,
**When** they add action items,
**Then** each item follows the structured format: "At [point in timeline], I could have [alternative action]" and is tagged to a recovery category: spiritual, relational, emotional, physical, or practical.

### PM-AC6.2 -- Action Item Count

**Given** a user is creating an action plan,
**When** they add items,
**Then** the system enforces a minimum of 1 and maximum of 10 action items (recommended 3-5).

### PM-AC6.3 -- Convert to Commitments

**Given** a user has created action plan items,
**When** they choose to convert an item to a commitment or goal,
**Then** the system creates the corresponding commitment or daily/weekly goal entry in the app, linked back to the post-mortem.

### PM-AC6.4 -- Action Plan Persistence

**Given** a user has saved action plan items with a post-mortem,
**When** they view the post-mortem later,
**Then** the action plan is displayed alongside the analysis with its category tags and any linked commitments/goals.

---

## 7. Sharing and Visibility (PM-AC7)

### PM-AC7.1 -- Opt-In Sharing

**Given** a user has a completed post-mortem,
**When** they choose to share it,
**Then** they can select specific contacts (sponsor, counselor, coach) to share with on a per-analysis basis.

### PM-AC7.2 -- Full vs. Summary Sharing

**Given** a user is sharing a post-mortem,
**When** they configure sharing,
**Then** they can choose between sharing the full analysis or a summary-only version.

### PM-AC7.3 -- Support Network Dashboard

**Given** a support network member has been granted access to a post-mortem,
**When** they view their dashboard,
**Then** shared post-mortems appear in their view, subject to the existing permission system.

### PM-AC7.4 -- PDF Export

**Given** a user has a completed post-mortem,
**When** they request a PDF export,
**Then** the system generates a downloadable PDF of the full analysis suitable for therapy sessions or sponsor meetings.

### PM-AC7.5 -- Permission Check on Shared Access

**Given** a support contact attempts to view a shared post-mortem,
**When** the request is made,
**Then** the system verifies that the contact has an active `post-mortem:read` permission grant from the user. If not, return 404 (not 403) to hide data existence.

---

## 8. History and Pattern Analysis (PM-AC8)

### PM-AC8.1 -- History List

**Given** a user has saved post-mortems,
**When** they view their post-mortem history,
**Then** all saved analyses are listed in reverse chronological order with cursor-based pagination.

### PM-AC8.2 -- Filter by Addiction Type

**Given** a user has post-mortems for multiple addictions,
**When** they filter by addiction type,
**Then** only post-mortems linked to that addiction type are returned.

### PM-AC8.3 -- Cross-Analysis Insights: Common Triggers

**Given** a user has 2+ completed post-mortems,
**When** they view cross-analysis insights,
**Then** the system shows the most common triggers across all post-mortems, ranked by frequency.

### PM-AC8.4 -- Cross-Analysis Insights: FASTER Stage at Point of No Return

**Given** a user has 2+ completed post-mortems with FASTER mapping,
**When** they view insights,
**Then** the system identifies the most frequent FASTER stage at the point of no return.

### PM-AC8.5 -- Cross-Analysis Insights: Time of Day

**Given** a user has 2+ completed post-mortems,
**When** they view insights,
**Then** the system shows the most common time of day for acting out.

### PM-AC8.6 -- Cross-Analysis Insights: Recurring Decision Points

**Given** a user has 2+ completed post-mortems with decision points,
**When** they view insights,
**Then** the system identifies recurring decision points where intervention was missed.

### PM-AC8.7 -- Linked Entities

**Given** a completed post-mortem,
**When** it references urge logs, FASTER Scale entries, or relapse records,
**Then** the post-mortem displays links to those related entities for navigation.

---

## 9. Compassionate Tone (PM-AC9)

### PM-AC9.1 -- Opening Message

**Given** a user initiates a new post-mortem,
**When** the walkthrough begins,
**Then** the system displays an opening message: "A relapse is painful, but it is also an opportunity to learn. This process will help you understand what happened so you can build a stronger foundation going forward."

### PM-AC9.2 -- Closing Message

**Given** a user completes and submits a post-mortem,
**When** the analysis is saved,
**Then** the system displays a closing message: "Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom."

### PM-AC9.3 -- No Shame-Based Language

**Given** any prompt, label, or system message within the post-mortem flow,
**When** displayed to the user,
**Then** no shame-based language is used. All messaging focuses on learning, growth, and grace.

---

## 10. Integration Points (PM-AC10)

### PM-AC10.1 -- Triggered from Relapse Log

**Given** a user has just logged a relapse,
**When** the relapse is saved,
**Then** the system prompts the user to begin a post-mortem analysis (opt-in, not forced).

### PM-AC10.2 -- Triggered from FASTER Scale Relapse Stage

**Given** a user completes a FASTER Scale entry and selects "R -- Relapse",
**When** the entry is saved,
**Then** the system prompts the user to begin a post-mortem analysis.

### PM-AC10.3 -- Analytics Feed

**Given** a user completes a post-mortem,
**When** the analytics dashboard is viewed,
**Then** post-mortem completion rate after relapses and trigger trends are included in the analytics data.

### PM-AC10.4 -- Action Plan to Goals/Commitments

**Given** an action plan item is converted to a commitment or goal,
**When** the commitment/goal is created,
**Then** it includes a `sourcePostMortemId` linking back to the originating post-mortem.

---

## 11. Edge Cases (PM-AC11)

### PM-AC11.1 -- Incomplete Post-Mortem Auto-Save

**Given** a user starts a post-mortem but does not finish,
**When** the session ends or they navigate away,
**Then** progress is auto-saved as a draft and the user is prompted to resume when they return to the feature.

### PM-AC11.2 -- Multiple Relapses

**Given** a user has multiple relapses in a short period,
**When** they create post-mortems,
**Then** each relapse can have its own post-mortem, or the user can create a combined analysis covering the full period (eventType = `combined`).

### PM-AC11.3 -- Skipped Post-Mortem Gentle Reminder

**Given** a user completes a relapse log but does not start a post-mortem within 24 hours,
**When** 24 hours have passed,
**Then** the system sends a gentle notification: "Taking a few minutes to reflect on what happened can strengthen your recovery. Would you like to complete a post-mortem?"

### PM-AC11.4 -- Near-Miss Post-Mortem

**Given** a user resisted an urge (near-miss),
**When** they choose to complete a post-mortem,
**Then** the system allows creating a post-mortem with `eventType: "near-miss"` without requiring a linked relapse.

### PM-AC11.5 -- Offline Support

**Given** a user is offline,
**When** they complete a post-mortem,
**Then** the full post-mortem flow works offline. Data syncs when connection is restored. Conflict resolution follows the union merge strategy.

---

## 12. Feature Flag (PM-AC12)

### PM-AC12.1 -- Flag Gating

**Given** the feature flag `activity.post-mortem` is disabled,
**When** a user attempts to access any post-mortem endpoint,
**Then** the system returns 404 (feature hidden) for all post-mortem API endpoints.

### PM-AC12.2 -- Flag Enabled

**Given** the feature flag `activity.post-mortem` is enabled for the user's tier/platform/tenant,
**When** the user accesses post-mortem endpoints,
**Then** all post-mortem functionality is available.

---

## 13. Data Integrity (PM-AC13)

### PM-AC13.1 -- Immutable Timestamp

**Given** a post-mortem is created with a timestamp,
**When** the user attempts to update the post-mortem,
**Then** the `createdAt` timestamp is immutable and cannot be modified.

### PM-AC13.2 -- Tenant Isolation

**Given** a post-mortem belongs to tenant A,
**When** a user from tenant B attempts to access it,
**Then** the system returns 404.
