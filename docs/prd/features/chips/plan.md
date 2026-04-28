# Chips/Milestone System -- Multi-Agent Implementation Plan

**Version:** 1.0.0  
**Date:** 2026-04-27  
**Status:** Draft  
**Platform:** iOS-only (SwiftUI + SwiftData)

---

## Overview

This plan follows the project's spec-driven, test-first development approach. Each wave produces working, tested code that can be merged independently. Agents work in parallel where dependencies allow.

**Build order context:** Chips/Milestone System is a **Wave 1.5 (P0/P1 hybrid)** feature. It replaces the basic milestone system in `StreakViewModel` with a comprehensive, fellowship-aware, event-sourced tracker system. The PRD specifies 20+ fellowships with distinct chip traditions, parallel multi-addiction tracking, compassionate relapse flows, and privacy controls.

**Feature flag:** `feature.chips`

**Scope reduction for V1:** Full implementation supports SA, AA, NA, and Custom/Universal fellowships (the four most common in the app's target market), with architecture ready for the remaining 17 fellowships in a fast-follow release. This reduces V1 scope by ~60% while delivering complete functionality for 90% of users.

**Migration strategy:** New SwiftData models are created alongside existing `RRStreak`, `RRMilestone`, `RRRelapse` models. The old streak system remains functional behind a flag. Migration happens incrementally:
- New users after flag enabled → use chip system exclusively
- Existing users → opt-in migration flow with data preservation
- Both systems coexist until full migration complete (Wave 2)

---

## Prerequisites (Must Exist Before Starting)

| Dependency | Source | Status Check |
|-----------|--------|-------------|
| SwiftData models for tracking | Wave 1 | `RRAddiction`, `RRStreak`, `RRRelapse` exist in `RRModels.swift` |
| Feature flag system | Wave 0 (iOS) | `FeatureFlagService` evaluable, integrated with `ServiceContainer` |
| ServiceContainer singleton | Wave 1 | `@Observable` service container wired |
| Onboarding flow | Wave 1 | User can create addiction trackers |
| Theme system | Wave 1 | `Color+RR.swift`, `Typography.swift`, `ColorTheme.swift` exist |
| Notification permissions | Wave 1 | Local notification scheduling functional |
| SwiftUI navigation | Wave 1 | `NavigationStack` with `NavigationPath` in place |
| Biometric auth | Wave 1 | FaceID/TouchID lock functional (for privacy features) |
| Widget extension | Wave 1 (optional) | WidgetKit target exists (for generic widget mode) |

---

## Agent Assignments

### Agent A: Data Model & Types (Foundation)

**Role:** Define all SwiftData models, enums, and value types for the event-sourced chip system. This is the foundation -- all other agents depend on these types.

**Depends on:** None (starts immediately)

**Artifacts:**
- `Data/Models/RRChipModels.swift` -- New SwiftData models for chip system
- `Models/ChipTypes.swift` -- Non-SwiftData value types (fellowship profiles, chip shapes, enums)
- `Models/FellowshipProfiles.json` -- Bundled fellowship tradition data (SA, AA, NA, Custom)
- `Tests/Unit/ChipModelsTests.swift` -- Unit tests for computed properties and validation

**Steps:**

1. **Define core enums:**
   ```swift
   enum FellowshipType: String, Codable, CaseIterable {
       case aa, na, ca, cma, sa, saa, slaa, custom
       // V1: SA, AA, NA, Custom only; architecture ready for all 20+
   }

   enum ChipShape: String, Codable {
       case round          // Poker chip (AA)
       case dogTag         // Key tag with notch (NA, CA, PA)
       case medallion      // Bronze/silver coin (annuals)
       case keyChain       // Key ring (HA)
       case disc           // Aluminum disc (OA, ACA)
   }

   enum TrackerEventType: String, Codable {
       case start, reset, lapse, relapse, pause, resume, dateCorrection, stepCompleted
   }

   enum TrackerStatus: String, Codable {
       case active, paused, archived
   }

   enum ResetType: String, Codable {
       case lapse          // Brief slip, streak continues (opt-in)
       case relapse        // Sustained return, streak resets
       case userInitiated  // "I want to start over"
   }
   ```

2. **Define FellowshipProfile struct (loaded from JSON):**
   ```swift
   struct FellowshipProfile: Codable, Identifiable, Hashable {
       let id: FellowshipType
       let name: String
       let abstinenceDefinition: String?       // e.g., "All alcohol"
       let allowsCustomDefinition: Bool        // SA/SLAA/OA = true
       let chipTraditionExists: Bool           // FA/WA = false
       let supportsMonthlyChips: Bool          // GA/EA/CoDA = false
       let defaultShape: ChipShape
       let colorPalette: [MilestoneColorMap]
       let milestoneSchedule: MilestoneSchedule
       let symbolConfig: ChipSymbolConfig
       let edgeText: ChipEdgeText
       let disclosureText: String              // Tradition 6 disclaimer
   }

   struct MilestoneColorMap: Codable, Hashable {
       let days: Int
       let colorHex: String
       let name: String                        // e.g., "White", "Orange", "Glow"
   }

   struct MilestoneSchedule: Codable, Hashable {
       let baseMilestones: [Int]               // Standard: [1, 30, 60, 90, 180, 270, 365, 730, ...]
       let additionalMilestones: [Int]         // Fellowship-specific additions (e.g., NA 24hr, 90-day)
       let hiddenMilestones: [Int]             // Fellowship-specific removals (e.g., GA hides all monthly)
       let supportsCustomMilestones: Bool
       let supportsStepChips: Bool             // SLAA tradition
   }

   struct ChipSymbolConfig: Codable, Hashable {
       let symbolName: String?                 // SF Symbol name or custom asset
       let description: String                 // For VoiceOver
   }

   struct ChipEdgeText: Codable, Hashable {
       let front: String?                      // e.g., "To Thine Own Self Be True"
       let back: String?                       // e.g., "Serenity Prayer", "Just for Today"
   }
   ```

3. **Define SwiftData models:**
   ```swift
   @Model
   final class RRTracker {
       @Attribute(.unique) var id: UUID
       var userId: UUID
       var fellowshipType: FellowshipType
       var label: String                       // e.g., "Alcohol", "Pornography"
       var customAbstinenceDefinition: String? // User-defined (for SA/SLAA/OA/Custom)
       var status: TrackerStatus
       var createdAt: Date                     // Immutable
       var modifiedAt: Date
       var trackerTimezone: String             // IANA timezone
       var isPaused: Bool
       var pausedAt: Date?
       var isHidden: Bool                      // Per-tracker visibility
       var sortOrder: Int

       @Relationship(deleteRule: .cascade, inverse: \RRTrackerEvent.tracker)
       var events: [RRTrackerEvent] = []

       @Relationship(deleteRule: .cascade, inverse: \RRChipAward.tracker)
       var chipAwards: [RRChipAward] = []

       @Relationship(deleteRule: .cascade, inverse: \RRTrackerSharing.tracker)
       var sharingSettings: [RRTrackerSharing] = []

       // Computed properties (projection from event log)
       var currentStreakDays: Int {
           // Compute from events: time since most recent RESET/RELAPSE/START
       }

       var longestStreakDays: Int {
           // Compute from events: max streak across all attempts
       }

       var totalSoberDays: Int {
           // Sum all active days across all streaks
       }

       var currentStreakStartDate: Date? {
           // Most recent START/RESET/RELAPSE event
       }

       var totalRelapses: Int {
           // Count RELAPSE events
       }

       var totalLapses: Int {
           // Count LAPSE events
       }
   }

   @Model
   final class RRTrackerEvent {
       @Attribute(.unique) var id: UUID
       var trackerId: UUID
       var type: TrackerEventType
       var occurredAt: Date                    // UTC instant
       var localDate: Date                     // Date in tracker's timezone
       var localTimezone: String               // Snapshot at event time
       var note: String?                       // Encrypted free text
       var isPrivate: Bool
       var triggers: [String]                  // Trigger IDs or tags
       var resetType: ResetType?               // Only for RESET/RELAPSE/LAPSE
       var stepNumber: Int?                    // Only for STEP_COMPLETED
       var priorStartDate: Date?               // For DATE_CORRECTION events
       var recordedAt: Date                    // When logged (may differ from occurredAt)
       var createdAt: Date                     // Immutable

       var tracker: RRTracker?
   }

   @Model
   final class RRChipAward {
       @Attribute(.unique) var id: UUID
       var trackerId: UUID
       var milestoneKey: String                // e.g., "30_days", "1_year", "step_4"
       var milestoneDays: Int?                 // Nil for step chips
       var awardedAt: Date
       var earnedInStreakStartingAt: Date      // Immutable reference to streak start
       var fellowshipType: FellowshipType      // Snapshot at award time
       var chipShape: ChipShape
       var chipColorHex: String
       var chipColorName: String               // For VoiceOver
       var symbolName: String?
       var scripture: String?                  // Christian integration
       var journalPrompt: String?              // Post-milestone reflection
       var journalResponse: String?            // User's answer
       var isCustomMilestone: Bool
       var isStepChip: Bool
       var createdAt: Date                     // Immutable

       var tracker: RRTracker?
   }

   @Model
   final class RRTrackerSharing {
       @Attribute(.unique) var id: UUID
       var trackerId: UUID
       var partnerContactId: UUID?             // Nil = community/widget
       var visibleInWidget: Bool
       var visibleInNotifications: Bool
       var shareLevel: ShareLevel              // full, summary, countOnly
       var createdAt: Date
       var revokedAt: Date?

       var tracker: RRTracker?
   }

   enum ShareLevel: String, Codable {
       case full           // All details
       case summary        // Milestones + count, no events
       case countOnly      // Just days sober
   }
   ```

4. **Create FellowshipProfiles.json with V1 fellowships:**
   ```json
   {
     "fellowships": [
       {
         "id": "sa",
         "name": "Sexaholics Anonymous",
         "abstinenceDefinition": null,
         "allowsCustomDefinition": true,
         "chipTraditionExists": true,
         "supportsMonthlyCh ips": false,
         "defaultShape": "round",
         "colorPalette": [
           { "days": 0, "colorHex": "#FFFFFF", "name": "White (Desire)" },
           { "days": 30, "colorHex": "#FFD700", "name": "Gold" },
           { "days": 90, "colorHex": "#32CD32", "name": "Green" },
           { "days": 365, "colorHex": "#CD7F32", "name": "Bronze" }
         ],
         "milestoneSchedule": {
           "baseMilestones": [0, 30, 60, 90, 180, 270, 365],
           "additionalMilestones": [],
           "hiddenMilestones": [],
           "supportsCustomMilestones": true,
           "supportsStepChips": true
         },
         "symbolConfig": {
           "symbolName": "heart.circle.fill",
           "description": "Heart in circle"
         },
         "edgeText": {
           "front": "Progressive Victory Over Lust",
           "back": "SA — One Day at a Time"
         },
         "disclosureText": "Chip designs inspired by SA tradition. Not affiliated with or endorsed by Sexaholics Anonymous."
       },
       {
         "id": "aa",
         "name": "Alcoholics Anonymous",
         "abstinenceDefinition": "All alcoholic beverages",
         "allowsCustomDefinition": false,
         "chipTraditionExists": true,
         "supportsMonthlyCh ips": true,
         "defaultShape": "round",
         "colorPalette": [
           { "days": 0, "colorHex": "#FFFFFF", "name": "White" },
           { "days": 1, "colorHex": "#FFFFFF", "name": "White (24hr)" },
           { "days": 30, "colorHex": "#FF0000", "name": "Red" },
           { "days": 60, "colorHex": "#FFD700", "name": "Gold" },
           { "days": 90, "colorHex": "#00FF00", "name": "Green" },
           { "days": 180, "colorHex": "#0000FF", "name": "Blue" },
           { "days": 270, "colorHex": "#FFD700", "name": "Gold" },
           { "days": 365, "colorHex": "#CD7F32", "name": "Bronze" }
         ],
         "milestoneSchedule": {
           "baseMilestones": [0, 1, 30, 60, 90, 120, 150, 180, 210, 240, 270, 300, 330, 365],
           "additionalMilestones": [],
           "hiddenMilestones": [],
           "supportsCustomMilestones": true,
           "supportsStepChips": true
         },
         "symbolConfig": {
           "symbolName": "triangle.circle",
           "description": "Triangle in circle"
         },
         "edgeText": {
           "front": "To Thine Own Self Be True",
           "back": "Unity, Service, Recovery"
         },
         "disclosureText": "Chip designs inspired by AA tradition. Not affiliated with or endorsed by Alcoholics Anonymous."
       },
       {
         "id": "na",
         "name": "Narcotics Anonymous",
         "abstinenceDefinition": "All mind-altering substances",
         "allowsCustomDefinition": false,
         "chipTraditionExists": true,
         "supportsMonthlyCh ips": true,
         "defaultShape": "dogTag",
         "colorPalette": [
           { "days": 0, "colorHex": "#FFFFFF", "name": "White (Welcome)" },
           { "days": 1, "colorHex": "#FF6600", "name": "Orange (24hr)" },
           { "days": 30, "colorHex": "#FF6600", "name": "Orange" },
           { "days": 60, "colorHex": "#00FF00", "name": "Green" },
           { "days": 90, "colorHex": "#FF0000", "name": "Red" },
           { "days": 180, "colorHex": "#0000FF", "name": "Blue" },
           { "days": 270, "colorHex": "#FFFF00", "name": "Yellow" },
           { "days": 365, "colorHex": "#00FFFF", "name": "Glow (1 year)" },
           { "days": 545, "colorHex": "#808080", "name": "Gray (18 months)" },
           { "days": 730, "colorHex": "#000000", "name": "Black (2 years)" }
         ],
         "milestoneSchedule": {
           "baseMilestones": [0, 1, 30, 60, 90, 180, 270, 365, 545, 730],
           "additionalMilestones": [],
           "hiddenMilestones": [],
           "supportsCustomMilestones": true,
           "supportsStepChips": true
         },
         "symbolConfig": {
           "symbolName": "diamond.fill",
           "description": "Diamond"
         },
         "edgeText": {
           "front": "Just for Today",
           "back": "The Therapeutic Value of One Addict Helping Another is Without Parallel"
         },
         "disclosureText": "Chip designs inspired by NA tradition. Not affiliated with or endorsed by Narcotics Anonymous."
       },
       {
         "id": "custom",
         "name": "Custom/Universal",
         "abstinenceDefinition": null,
         "allowsCustomDefinition": true,
         "chipTraditionExists": true,
         "supportsMonthlyCh ips": true,
         "defaultShape": "round",
         "colorPalette": [
           { "days": 0, "colorHex": "#E0E0E0", "name": "Silver (Commitment)" },
           { "days": 1, "colorHex": "#90CAF9", "name": "Light Blue" },
           { "days": 7, "colorHex": "#81C784", "name": "Light Green" },
           { "days": 14, "colorHex": "#FFB74D", "name": "Orange" },
           { "days": 30, "colorHex": "#BA68C8", "name": "Purple" },
           { "days": 60, "colorHex": "#4FC3F7", "name": "Cyan" },
           { "days": 90, "colorHex": "#4CAF50", "name": "Green" },
           { "days": 180, "colorHex": "#FF9800", "name": "Amber" },
           { "days": 365, "colorHex": "#FFD700", "name": "Gold" }
         ],
         "milestoneSchedule": {
           "baseMilestones": [0, 1, 3, 7, 14, 30, 60, 90, 180, 270, 365, 730, 1095, 1825, 3650],
           "additionalMilestones": [],
           "hiddenMilestones": [],
           "supportsCustomMilestones": true,
           "supportsStepChips": false
         },
         "symbolConfig": {
           "symbolName": "star.fill",
           "description": "Star"
         },
         "edgeText": {
           "front": "One Day at a Time",
           "back": "Progress, Not Perfection"
         },
         "disclosureText": "Generic milestone design for any recovery journey."
       }
     ]
   }
   ```

5. **Define FellowshipProfileService to load and resolve profiles:**
   ```swift
   // Services/FellowshipProfileService.swift
   final class FellowshipProfileService {
       private let profiles: [FellowshipType: FellowshipProfile]

       init() {
           // Load from bundle JSON
       }

       func profile(for fellowship: FellowshipType) -> FellowshipProfile

       func milestonesForTracker(_ tracker: RRTracker) -> [Int]

       func chipColor(for days: Int, fellowship: FellowshipType) -> (hex: String, name: String)

       func chipShape(for days: Int, fellowship: FellowshipType) -> ChipShape
   }
   ```

6. **Write unit tests:**
   - FellowshipProfile loading from JSON
   - Milestone schedule computation (base + additions - removals)
   - Chip color resolution for each fellowship
   - Tracker computed properties (currentStreakDays from event log)
   - Event immutability (createdAt never changes)

**Verification gate:** `xcodebuild test -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16'` passes for `ChipModelsTests`. All fellowship profiles load successfully. Computed properties on `RRTracker` correctly project from event log.

---

### Agent B: Fellowship Tradition Engine

**Role:** Implement the business logic for milestone computation, chip award generation, and fellowship profile resolution. Pure functions with no I/O.

**Depends on:** Agent A (types and models must exist)

**Artifacts:**
- `Services/ChipEngine.swift` -- Core milestone computation and award logic
- `Services/ChipColorResolver.swift` -- Color/shape/symbol resolution per fellowship
- `Tests/Unit/ChipEngineTests.swift` -- Unit tests

**Steps:**

1. **Implement ChipEngine:**
   ```swift
   // Services/ChipEngine.swift
   @Observable
   final class ChipEngine {
       private let fellowshipService: FellowshipProfileService

       init(fellowshipService: FellowshipProfileService)

       // MARK: - Milestone Computation

       /// Compute all milestones for a tracker given its current event log.
       func computeMilestonesForTracker(_ tracker: RRTracker) -> [Int]

       /// Determine next milestone days for a given current streak.
       func nextMilestone(for currentDays: Int, tracker: RRTracker) -> Int?

       /// Check if a milestone should be awarded given the event log.
       func shouldAwardChip(for milestone: Int, tracker: RRTracker, existingAwards: [RRChipAward]) -> Bool

       // MARK: - Chip Award Generation

       /// Generate a new ChipAward for a milestone.
       func createChipAward(
           for milestoneDays: Int,
           tracker: RRTracker,
           awardedAt: Date,
           scripture: String?
       ) -> RRChipAward

       /// Generate a step-completion chip.
       func createStepChip(
           for stepNumber: Int,
           tracker: RRTracker,
           awardedAt: Date
       ) -> RRChipAward

       // MARK: - Retroactive Chip Population

       /// For mid-recovery installs: generate all past chips retroactively.
       func generateRetroactiveChips(
           for tracker: RRTracker,
           startDate: Date
       ) -> [RRChipAward]

       // MARK: - Scripture Assignment

       /// Assign scripture to a milestone (Christian integration).
       func scripture(for days: Int) -> String
   }
   ```

2. **Implement ChipColorResolver:**
   ```swift
   // Services/ChipColorResolver.swift
   struct ChipColorResolver {
       let fellowshipService: FellowshipProfileService

       /// Resolve chip color for a given milestone in a fellowship.
       func color(for days: Int, fellowship: FellowshipType) -> (hex: String, name: String)

       /// Resolve chip shape for a given milestone in a fellowship.
       func shape(for days: Int, fellowship: FellowshipType) -> ChipShape

       /// Resolve symbol for a given milestone in a fellowship.
       func symbol(for days: Int, fellowship: FellowshipType) -> ChipSymbolConfig
   }
   ```

3. **Implement milestone logic:**
   - Base milestone set: `[0, 1, 3, 7, 14, 30, 60, 90, 180, 270, 365, 730, 1095, 1825, 3650]`
   - Per-fellowship additions (e.g., NA: 24hr key tag)
   - Per-fellowship removals (e.g., GA: hide all monthly, show only annuals)
   - Annual milestones after year 2: continue yearly
   - Custom milestones: user-defined days, stored separately

4. **Implement retroactive chip population:**
   - When user sets a start date in the past (mid-recovery install), generate all earned chips
   - Respect fellowship milestone schedule
   - Assign appropriate colors, shapes, scriptures
   - Mark as `earnedInStreakStartingAt` with the actual start date

5. **Implement scripture assignment (Christian integration):**
   - Reuse existing `StreakViewModel.milestoneScripture(for:)` mapping
   - Extend with additional milestones as needed
   - Fallback: generic verse for unknown milestones

6. **Write unit tests:**
   - Milestone computation for each fellowship (SA, AA, NA, Custom)
   - Next milestone calculation
   - Chip award generation with correct colors/shapes
   - Retroactive chip population for past start dates
   - Step chip generation (SLAA tradition)
   - Scripture assignment

**Verification gate:** `ChipEngineTests` passes with 100% coverage on milestone computation and award generation. All four V1 fellowships tested.

---

### Agent C: Event-Sourced Tracker Logic

**Role:** Implement the event-sourced tracker state machine: streak calculation from immutable event log, reset flows (lapse/relapse/user-initiated), grace period, timezone handling, null days.

**Depends on:** Agent A (models), Agent B (milestone engine)

**Artifacts:**
- `Services/TrackerEngine.swift` -- Event log projection and state machine
- `Services/TrackerResetService.swift` -- Reset/relapse flow logic
- `Services/TrackerTimezoneService.swift` -- Timezone-aware day boundary logic
- `Tests/Unit/TrackerEngineTests.swift` -- Unit tests
- `Tests/Unit/TrackerResetServiceTests.swift` -- Unit tests

**Steps:**

1. **Implement TrackerEngine:**
   ```swift
   // Services/TrackerEngine.swift
   @Observable
   final class TrackerEngine {
       // MARK: - Projection from Event Log

       /// Compute current streak days from event log.
       func computeCurrentStreak(for tracker: RRTracker) -> Int

       /// Compute longest streak ever from event log.
       func computeLongestStreak(for tracker: RRTracker) -> Int

       /// Compute total sober days (sum across all streaks).
       func computeTotalSoberDays(for tracker: RRTracker) -> Int

       /// Find the current streak start date (most recent START/RESET/RELAPSE).
       func currentStreakStartDate(for tracker: RRTracker) -> Date?

       /// Count total relapses.
       func countRelapses(for tracker: RRTracker) -> Int

       /// Count total lapses.
       func countLapses(for tracker: RRTracker) -> Int

       // MARK: - Event Creation

       /// Create a START event (tracker initialization).
       func createStartEvent(
           for tracker: RRTracker,
           occurredAt: Date,
           note: String?
       ) -> RRTrackerEvent

       /// Create a DATE_CORRECTION event (user edits start date).
       func createDateCorrectionEvent(
           for tracker: RRTracker,
           newStartDate: Date,
           occurredAt: Date,
           note: String?
       ) -> RRTrackerEvent

       /// Create a PAUSE event.
       func createPauseEvent(for tracker: RRTracker, occurredAt: Date) -> RRTrackerEvent

       /// Create a RESUME event.
       func createResumeEvent(for tracker: RRTracker, occurredAt: Date) -> RRTrackerEvent

       /// Create a STEP_COMPLETED event.
       func createStepCompletedEvent(
           for tracker: RRTracker,
           stepNumber: Int,
           occurredAt: Date
       ) -> RRTrackerEvent
   }
   ```

2. **Implement TrackerResetService (compassionate reset flow):**
   ```swift
   // Services/TrackerResetService.swift
   @Observable
   final class TrackerResetService {
       // MARK: - Reset Flow

       /// Create a LAPSE event (brief slip, streak continues by default).
       func createLapseEvent(
           for tracker: RRTracker,
           occurredAt: Date,
           note: String?,
           triggers: [String],
           userForcesReset: Bool
       ) -> RRTrackerEvent

       /// Create a RELAPSE event (sustained return, streak resets).
       func createRelapseEvent(
           for tracker: RRTracker,
           occurredAt: Date,
           note: String?,
           triggers: [String]
       ) -> RRTrackerEvent

       /// Create a RESET event (user-initiated restart).
       func createResetEvent(
           for tracker: RRTracker,
           occurredAt: Date,
           note: String?
       ) -> RRTrackerEvent

       // MARK: - Undo

       /// Undo the most recent reset event (60-second window).
       func undoResetEvent(for tracker: RRTracker) throws -> Bool

       // MARK: - Validation

       /// Validate that the undo window is still open (60 seconds).
       func canUndoReset(for tracker: RRTracker) -> Bool
   }
   ```

3. **Implement TrackerTimezoneService:**
   ```swift
   // Services/TrackerTimezoneService.swift
   struct TrackerTimezoneService {
       /// Compute day boundary in tracker's timezone.
       func dayBoundary(for date: Date, timezone: TimeZone) -> Date

       /// Detect timezone change and prompt user.
       func detectTimezoneChange(tracker: RRTracker, deviceTimezone: TimeZone) -> Bool

       /// Convert UTC instant to local date in tracker's timezone.
       func localDate(for instant: Date, timezone: TimeZone) -> Date

       /// Check if grace period is active (6 hours past midnight).
       func isInGracePeriod(occurredAt: Date, timezone: TimeZone) -> Bool

       /// Handle DST transitions (23-hour and 25-hour days both count as 1 day).
       func normalizedDayCount(from start: Date, to end: Date, timezone: TimeZone) -> Int
   }
   ```

4. **Implement streak calculation logic:**
   - Sort events by `occurredAt` ascending
   - Find most recent START, RESET, or RELAPSE event
   - Compute days from that event to now, respecting tracker's timezone
   - Handle paused periods: subtract paused duration from streak
   - Handle lapses: if user didn't force reset, lapse doesn't affect streak
   - Longest streak: iterate all streak segments, find max
   - Total sober days: sum all segments (excluding paused periods)

5. **Implement reset flows (compassionate language):**
   - LAPSE: default = streak continues, optional user override to reset
   - RELAPSE: streak resets to 0, prior chips preserved
   - RESET: user-initiated, identical effect to RELAPSE but different framing
   - All reset events: store triggers, note, timestamp
   - Undo window: 60 seconds, delete event if undone within window

6. **Implement grace period:**
   - 6 hours past local midnight: commitment can be logged late without losing the day
   - If user logs a commitment at 2 AM, it counts for yesterday

7. **Implement timezone handling:**
   - Tracker stores its own timezone (IANA string)
   - On device timezone change: prompt user to keep old TZ or switch
   - Never silently change day boundary
   - DST transitions: 23-hour day = 1 day, 25-hour day = 1 day

8. **Implement null day mechanic (for FA/WA/custom definitions):**
   - User can mark a day "not applicable" (e.g., illness, surgery)
   - Null day doesn't count toward streak or break it
   - Null days stored as events with type `NULL_DAY` (add to enum)

9. **Write unit tests:**
   - Streak calculation from various event sequences
   - Longest streak calculation
   - Total sober days calculation
   - Lapse vs. relapse vs. reset flows
   - Undo within 60 seconds (success) and after (failure)
   - Grace period logic
   - Timezone boundary calculation
   - DST transition handling
   - Paused tracker (streak frozen)
   - Date correction (retroactive start date change)

**Verification gate:** `TrackerEngineTests` and `TrackerResetServiceTests` pass with 100% coverage. All reset flows tested with compassionate copy validation.

---

### Agent D: Chip Visual Components

**Role:** Build SwiftUI views for chip rendering: shapes, colors, front/back flip animation, glow effects, gallery view, active counter view, detail view. Full VoiceOver support and Dynamic Type.

**Depends on:** Agent A (types), Agent B (color resolver)

**Artifacts:**
- `Views/Tools/Chips/ChipView.swift` -- Single chip render (round, dog-tag, medallion, etc.)
- `Views/Tools/Chips/ChipGalleryView.swift` -- Cabinet/gallery of earned chips
- `Views/Tools/Chips/ChipCounterView.swift` -- Large active chip + days counter
- `Views/Tools/Chips/ChipDetailView.swift` -- Chip detail with flip animation, journal, share
- `Views/Tools/Chips/ChipShapeView.swift` -- Custom shapes (round, dog-tag, medallion, key-chain, disc)
- `Theme/ChipColorPalette.swift` -- Color extensions for chips
- `Tests/Unit/ChipViewTests.swift` -- SwiftUI preview tests

**Steps:**

1. **Implement ChipShapeView (custom shapes):**
   ```swift
   // Views/Tools/Chips/ChipShapeView.swift
   struct ChipShapeView: View {
       let shape: ChipShape
       let colorHex: String
       let symbolName: String?
       let edgeText: String?
       let showFront: Bool

       var body: some View {
           switch shape {
           case .round:
               RoundChipShape(colorHex: colorHex, symbolName: symbolName, edgeText: edgeText, showFront: showFront)
           case .dogTag:
               DogTagShape(colorHex: colorHex, symbolName: symbolName, edgeText: edgeText, showFront: showFront)
           case .medallion:
               MedallionShape(colorHex: colorHex, symbolName: symbolName, edgeText: edgeText, showFront: showFront)
           case .keyChain:
               KeyChainShape(colorHex: colorHex, symbolName: symbolName, edgeText: edgeText, showFront: showFront)
           case .disc:
               DiscShape(colorHex: colorHex, symbolName: symbolName, edgeText: edgeText, showFront: showFront)
           }
       }
   }

   struct RoundChipShape: View {
       // Poker chip with concentric rings, center symbol, edge text
   }

   struct DogTagShape: View {
       // Rectangle with rounded corners, notch at top, key ring
   }

   struct MedallionShape: View {
       // Circle with textured edge (medallion style)
   }

   struct KeyChainShape: View {
       // Small rectangle with key ring attachment
   }

   struct DiscShape: View {
       // Simple aluminum disc, minimal decoration
   }
   ```

2. **Implement ChipView (single chip):**
   ```swift
   // Views/Tools/Chips/ChipView.swift
   struct ChipView: View {
       let chipAward: RRChipAward
       let showFront: Bool
       let size: ChipSize

       enum ChipSize {
           case small, medium, large
           var diameter: CGFloat {
               switch self {
               case .small: return 60
               case .medium: return 100
               case .large: return 200
               }
           }
       }

       var body: some View {
           ChipShapeView(
               shape: chipAward.chipShape,
               colorHex: chipAward.chipColorHex,
               symbolName: chipAward.symbolName,
               edgeText: showFront ? frontText : backText,
               showFront: showFront
           )
           .frame(width: size.diameter, height: size.diameter)
           .accessibilityLabel(chipAccessibilityLabel)
           .accessibilityAddTraits(.isButton)
       }

       private var chipAccessibilityLabel: String {
           "Chip: \(chipAward.milestoneDays ?? 0) days, \(chipAward.fellowshipType.rawValue), earned \(chipAward.awardedAt.formatted(date: .long, time: .omitted)), \(chipAward.chipColorName)"
       }
   }
   ```

3. **Implement ChipGalleryView (collected chips):**
   ```swift
   // Views/Tools/Chips/ChipGalleryView.swift
   struct ChipGalleryView: View {
       let tracker: RRTracker
       @State private var selectedChip: RRChipAward?

       var body: some View {
           ScrollView {
               LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                   ForEach(tracker.chipAwards.sorted(by: { $0.awardedAt < $1.awardedAt })) { chip in
                       ChipView(chipAward: chip, showFront: true, size: .medium)
                           .onTapGesture {
                               selectedChip = chip
                           }
                   }
               }
               .padding()
           }
           .navigationTitle("Chips Earned")
           .sheet(item: $selectedChip) { chip in
               ChipDetailView(chipAward: chip, tracker: tracker)
           }
       }
   }
   ```

4. **Implement ChipCounterView (active chip + days):**
   ```swift
   // Views/Tools/Chips/ChipCounterView.swift
   struct ChipCounterView: View {
       let tracker: RRTracker
       let chipEngine: ChipEngine

       var body: some View {
           VStack(spacing: 24) {
               // Large chip
               if let currentChip = latestChip {
                   ChipView(chipAward: currentChip, showFront: true, size: .large)
                       .shadow(radius: 10)
               }

               // Days counter
               Text("\(tracker.currentStreakDays)")
                   .font(.system(size: 72, weight: .bold, design: .rounded))
                   .foregroundColor(.rrPrimary)
                   .accessibilityLabel("\(tracker.currentStreakDays) days sober")

               Text("days")
                   .font(.title2)
                   .foregroundColor(.rrTextSecondary)

               // Next milestone
               if let nextMilestone = chipEngine.nextMilestone(for: tracker.currentStreakDays, tracker: tracker) {
                   Text("Next chip: \(nextMilestone) days")
                       .font(.subheadline)
                       .foregroundColor(.rrTextSecondary)
               }
           }
           .padding()
       }

       private var latestChip: RRChipAward? {
           tracker.chipAwards
               .filter { !$0.isStepChip }
               .sorted(by: { $0.awardedAt > $1.awardedAt })
               .first
       }
   }
   ```

5. **Implement ChipDetailView (flip animation, journal, share):**
   ```swift
   // Views/Tools/Chips/ChipDetailView.swift
   struct ChipDetailView: View {
       let chipAward: RRChipAward
       let tracker: RRTracker
       @State private var showFront = true
       @State private var journalResponse: String
       @State private var showShareSheet = false

       init(chipAward: RRChipAward, tracker: RRTracker) {
           self.chipAward = chipAward
           self.tracker = tracker
           _journalResponse = State(initialValue: chipAward.journalResponse ?? "")
       }

       var body: some View {
           ScrollView {
               VStack(spacing: 24) {
                   // Chip with flip animation
                   ChipView(chipAward: chipAward, showFront: showFront, size: .large)
                       .rotation3DEffect(.degrees(showFront ? 0 : 180), axis: (x: 0, y: 1, z: 0))
                       .onTapGesture {
                           withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                               showFront.toggle()
                           }
                       }

                   // Milestone info
                   VStack(spacing: 8) {
                       Text("\(chipAward.milestoneDays ?? 0) Days")
                           .font(.title)
                           .fontWeight(.bold)

                       Text("Earned \(chipAward.awardedAt.formatted(date: .long, time: .omitted))")
                           .font(.subheadline)
                           .foregroundColor(.rrTextSecondary)
                   }

                   // Scripture
                   if let scripture = chipAward.scripture {
                       VStack(alignment: .leading, spacing: 8) {
                           Text("Scripture")
                               .font(.headline)
                           Text(scripture)
                               .font(.body)
                               .foregroundColor(.rrTextSecondary)
                               .multilineTextAlignment(.leading)
                       }
                       .padding()
                       .background(Color.rrSurface)
                       .cornerRadius(12)
                   }

                   // Journal reflection
                   if let prompt = chipAward.journalPrompt {
                       VStack(alignment: .leading, spacing: 8) {
                           Text(prompt)
                               .font(.headline)
                           TextEditor(text: $journalResponse)
                               .frame(minHeight: 100)
                               .padding(8)
                               .background(Color.rrSurface)
                               .cornerRadius(8)
                       }
                       .padding()
                   }

                   // Share button
                   Button(action: { showShareSheet = true }) {
                       Label("Share Milestone", systemImage: "square.and.arrow.up")
                           .frame(maxWidth: .infinity)
                           .padding()
                           .background(Color.rrPrimary)
                           .foregroundColor(.white)
                           .cornerRadius(12)
                   }
                   .padding(.horizontal)
               }
               .padding()
           }
           .navigationTitle("Chip Detail")
           .sheet(isPresented: $showShareSheet) {
               ChipShareSheet(chipAward: chipAward, tracker: tracker)
           }
       }
   }
   ```

6. **Implement glow effect (NA 1-year chip):**
   - For NA 1-year chip (365 days), add animated luminosity in dark mode
   - Subtle pulsing glow effect using `.shadow` with animation
   - Respects `prefers-reduced-motion`

7. **Implement accessibility:**
   - Every chip has VoiceOver label: "Chip: [days] days, [fellowship], earned [date], [color name]"
   - Color is never the sole indicator (always paired with text/label)
   - Supports Dynamic Type up to AX5 (largest accessibility size)
   - Reduced-motion: static chip reveal, no flip animation

8. **Write SwiftUI preview tests:**
   - Preview each chip shape (round, dog-tag, medallion, key-chain, disc)
   - Preview each fellowship's color palette
   - Preview gallery view with multiple chips
   - Preview counter view with active chip
   - Preview detail view with journal prompt

**Verification gate:** `xcodebuild test` passes for chip view tests. Previews render correctly in Xcode. VoiceOver labels validated. Dynamic Type tested at AX5.

---

### Agent E: Reset/Relapse Flow UI

**Role:** Build the compassionate reset confirmation modal, abstinence definition surfacing, undo toast, What-the-Hell guard, trigger-tagging UI.

**Depends on:** Agent C (reset service), Agent A (types)

**Artifacts:**
- `Views/Tools/Chips/ResetConfirmationView.swift` -- Three-option reset modal
- `Views/Tools/Chips/ResetUndoToast.swift` -- 60-second undo toast
- `Views/Tools/Chips/TriggerTaggingView.swift` -- Post-reset trigger tagging
- `Tests/Unit/ResetFlowTests.swift` -- UI logic tests

**Steps:**

1. **Implement ResetConfirmationView (compassionate modal):**
   ```swift
   // Views/Tools/Chips/ResetConfirmationView.swift
   struct ResetConfirmationView: View {
       let tracker: RRTracker
       let onConfirm: (ResetType, String?, [String]) -> Void
       let onCancel: () -> Void

       @State private var selectedType: ResetType?
       @State private var note: String = ""
       @State private var selectedTriggers: Set<String> = []
       @State private var showStep2 = false

       var body: some View {
           VStack(spacing: 24) {
               // Step 1: What happened?
               if !showStep2 {
                   VStack(spacing: 16) {
                       Image(systemName: "heart.fill")
                           .font(.system(size: 48))
                           .foregroundColor(.rrPrimary)

                       Text("What happened? Take your time.")
                           .font(.title2)
                           .fontWeight(.semibold)

                       VStack(spacing: 12) {
                           ResetOptionButton(
                               title: "A single slip (lapse)",
                               description: "One moment. My streak continues unless I choose otherwise.",
                               isSelected: selectedType == .lapse
                           ) {
                               selectedType = .lapse
                               showStep2 = true
                           }

                           ResetOptionButton(
                               title: "A longer return (relapse)",
                               description: "A sustained period. I'm ready to start over.",
                               isSelected: selectedType == .relapse
                           ) {
                               selectedType = .relapse
                               showStep2 = true
                           }

                           ResetOptionButton(
                               title: "I want to reset on my own terms",
                               description: "I'm choosing to restart my counter.",
                               isSelected: selectedType == .userInitiated
                           ) {
                               selectedType = .userInitiated
                               showStep2 = true
                           }
                       }

                       Button("Cancel — Go back") {
                           onCancel()
                       }
                       .foregroundColor(.rrTextSecondary)
                   }
               }

               // Step 2: Confirmation + abstinence definition
               if showStep2, let resetType = selectedType {
                   VStack(spacing: 16) {
                       // Surface user's abstinence definition
                       if let definition = tracker.customAbstinenceDefinition {
                           VStack(alignment: .leading, spacing: 8) {
                               Text("Your definition:")
                                   .font(.headline)
                               Text(definition)
                                   .font(.body)
                                   .foregroundColor(.rrTextSecondary)
                                   .padding()
                                   .background(Color.rrSurface)
                                   .cornerRadius(8)
                           }
                       }

                       // What-the-Hell guard (for lapses)
                       if resetType == .lapse {
                           Text("One slip is not a relapse. Many people in recovery have lapses on the way to long-term sobriety. Your streak continues unless you tell us otherwise.")
                               .font(.body)
                               .foregroundColor(.rrTextSecondary)
                               .multilineTextAlignment(.center)
                               .padding()
                               .background(Color.yellow.opacity(0.1))
                               .cornerRadius(8)
                       }

                       // Consequences
                       if resetType == .relapse || resetType == .userInitiated {
                           Text("This will start your streak over. Your previous \(tracker.currentStreakDays) days and your \(tracker.chipAwards.count) chips are kept in your history forever. Are you sure?")
                               .font(.body)
                               .multilineTextAlignment(.center)
                               .padding()
                       }

                       // Note (optional)
                       TextField("Note (optional, private)", text: $note, axis: .vertical)
                           .textFieldStyle(.roundedBorder)
                           .lineLimit(3...6)

                       // Confirm buttons
                       HStack(spacing: 16) {
                           Button("Not yet") {
                               showStep2 = false
                               selectedType = nil
                           }
                           .buttonStyle(.bordered)

                           Button(resetType == .lapse ? "Log lapse" : "Start over") {
                               onConfirm(resetType, note.isEmpty ? nil : note, Array(selectedTriggers))
                           }
                           .buttonStyle(.borderedProminent)
                       }
                   }
               }
           }
           .padding()
       }
   }

   struct ResetOptionButton: View {
       let title: String
       let description: String
       let isSelected: Bool
       let action: () -> Void

       var body: some View {
           Button(action: action) {
               VStack(alignment: .leading, spacing: 4) {
                   Text(title)
                       .font(.headline)
                       .foregroundColor(.primary)
                   Text(description)
                       .font(.caption)
                       .foregroundColor(.secondary)
               }
               .frame(maxWidth: .infinity, alignment: .leading)
               .padding()
               .background(isSelected ? Color.rrPrimary.opacity(0.1) : Color.rrSurface)
               .cornerRadius(12)
               .overlay(
                   RoundedRectangle(cornerRadius: 12)
                       .stroke(isSelected ? Color.rrPrimary : Color.clear, lineWidth: 2)
               )
           }
       }
   }
   ```

2. **Implement ResetUndoToast (60-second undo window):**
   ```swift
   // Views/Tools/Chips/ResetUndoToast.swift
   struct ResetUndoToast: View {
       let resetType: ResetType
       let onUndo: () -> Void
       @State private var remainingSeconds: Int = 60

       var body: some View {
           HStack {
               Text("\(resetType == .lapse ? "Lapse" : "Reset") logged. Undo?")
                   .font(.subheadline)
                   .foregroundColor(.white)

               Spacer()

               Button("Undo") {
                   onUndo()
               }
               .foregroundColor(.yellow)
               .fontWeight(.semibold)

               Text("\(remainingSeconds)s")
                   .font(.caption)
                   .foregroundColor(.white.opacity(0.7))
           }
           .padding()
           .background(Color.black.opacity(0.8))
           .cornerRadius(12)
           .shadow(radius: 10)
           .padding()
           .onAppear {
               startCountdown()
           }
       }

       private func startCountdown() {
           Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
               if remainingSeconds > 0 {
                   remainingSeconds -= 1
               } else {
                   timer.invalidate()
               }
           }
       }
   }
   ```

3. **Implement TriggerTaggingView (post-reset optional):**
   ```swift
   // Views/Tools/Chips/TriggerTaggingView.swift
   struct TriggerTaggingView: View {
       @Binding var selectedTriggers: Set<String>
       let availableTriggers: [String] = [
           "Stress", "Loneliness", "Boredom", "Anger", "Anxiety",
           "Fatigue", "Social pressure", "Tempting location", "Specific person",
           "Success/celebration", "Failure/disappointment", "Physical pain"
       ]

       var body: some View {
           VStack(alignment: .leading, spacing: 12) {
               Text("What was happening? (optional, private)")
                   .font(.headline)

               FlowLayout(spacing: 8) {
                   ForEach(availableTriggers, id: \.self) { trigger in
                       TriggerTag(
                           label: trigger,
                           isSelected: selectedTriggers.contains(trigger)
                       ) {
                           if selectedTriggers.contains(trigger) {
                               selectedTriggers.remove(trigger)
                           } else {
                               selectedTriggers.insert(trigger)
                           }
                       }
                   }
               }
           }
       }
   }

   struct TriggerTag: View {
       let label: String
       let isSelected: Bool
       let action: () -> Void

       var body: some View {
           Button(action: action) {
               Text(label)
                   .font(.subheadline)
                   .padding(.horizontal, 12)
                   .padding(.vertical, 6)
                   .background(isSelected ? Color.rrPrimary : Color.rrSurface)
                   .foregroundColor(isSelected ? .white : .primary)
                   .cornerRadius(16)
           }
       }
   }

   struct FlowLayout: Layout {
       var spacing: CGFloat

       func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
           // Flow layout implementation
       }

       func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
           // Flow layout implementation
       }
   }
   ```

4. **Validate compassionate language:**
   - Review all copy against SAMHSA/ISSUP guidelines
   - Banned: "fail," "ruined," "back to square one," "broke your streak," "you lost"
   - Approved: "starting over," "today is new," "your history is preserved," "we're still here"
   - What-the-Hell guard: explicit statement that one slip ≠ relapse

5. **Write UI tests:**
   - Reset flow: lapse, relapse, user-initiated paths
   - Abstinence definition surfacing
   - Undo within 60 seconds (success)
   - Undo after 60 seconds (failure)
   - Trigger tagging (optional)

**Verification gate:** `xcodebuild test` passes for reset flow tests. Compassionate language validated. Undo toast functional.

---

### Agent F: Notifications

**Role:** Implement local notification scheduling for milestones, daily commitment, pre-milestone anticipation, end-of-day reflection. 3/day cap, quiet hours, post-relapse 24hr pause, no PHI in payloads.

**Depends on:** Agent A (types), Agent C (tracker engine)

**Artifacts:**
- `Services/ChipNotificationService.swift` -- Notification scheduling and management
- `Services/NotificationRateLimiter.swift` -- 3/day cap logic
- `Tests/Unit/ChipNotificationServiceTests.swift` -- Unit tests

**Steps:**

1. **Implement ChipNotificationService:**
   ```swift
   // Services/ChipNotificationService.swift
   import UserNotifications

   @Observable
   final class ChipNotificationService {
       private let rateLimiter: NotificationRateLimiter
       private let trackerEngine: TrackerEngine

       init(rateLimiter: NotificationRateLimiter, trackerEngine: TrackerEngine)

       // MARK: - Scheduling

       /// Schedule daily commitment prompt (default 8 AM local).
       func scheduleDailyCommitment(for tracker: RRTracker, at hour: Int) async throws

       /// Schedule pre-milestone anticipation (1 day before major chip).
       func schedulePreMilestoneNotification(for tracker: RRTracker, milestone: Int) async throws

       /// Schedule milestone-day celebration (on the day chip is awarded).
       func scheduleMilestoneNotification(for tracker: RRTracker, milestone: Int) async throws

       /// Schedule end-of-day reflection (optional, off by default).
       func scheduleEndOfDayReflection(for tracker: RRTracker, at hour: Int) async throws

       // MARK: - Management

       /// Cancel all notifications for a tracker.
       func cancelAllNotifications(for tracker: RRTracker) async

       /// Pause notifications for 24 hours (post-relapse).
       func pauseNotifications(for tracker: RRTracker, duration: TimeInterval) async

       /// Cancel pause and resume notifications.
       func resumeNotifications(for tracker: RRTracker) async

       // MARK: - Rate Limiting

       /// Check if notification can be sent (3/day cap).
       func canSendNotification() async -> Bool
   }
   ```

2. **Implement NotificationRateLimiter:**
   ```swift
   // Services/NotificationRateLimiter.swift
   @Observable
   final class NotificationRateLimiter {
       private var sentNotifications: [Date] = []
       private let maxPerDay: Int = 3

       /// Check if another notification can be sent today.
       func canSend() -> Bool {
           let today = Calendar.current.startOfDay(for: Date())
           let todayNotifications = sentNotifications.filter {
               Calendar.current.isDate($0, inSameDayAs: today)
           }
           return todayNotifications.count < maxPerDay
       }

       /// Record a sent notification.
       func recordSent() {
           sentNotifications.append(Date())
           cleanupOldEntries()
       }

       private func cleanupOldEntries() {
           let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
           sentNotifications.removeAll { $0 < twoDaysAgo }
       }
   }
   ```

3. **Implement notification copy (no PHI in payloads):**
   - Daily commitment: "Take today's commitment chip. One day at a time."
   - Pre-milestone (1 day before): "Tomorrow is your [X]-day chip. We see you."
   - Milestone day: "Your [X]-day chip is ready. Tap to receive it."
   - End-of-day: "Want to log how today went?"
   - All lock-screen text: generic, no addiction name, no days count
   - Content fetched only after app unlock

4. **Implement quiet hours:**
   - User-configurable quiet hours (default 10 PM – 8 AM local)
   - Notifications scheduled outside quiet hours
   - System DND respected at OS level

5. **Implement post-relapse 24hr pause:**
   - After RELAPSE or RESET event, pause all milestone/streak notifications for 24 hours
   - One supportive check-in fires next morning: "Yesterday was hard. Today is new. Whenever you're ready."

6. **Implement 3/day cap:**
   - Hard cap of 3 push notifications per day per user
   - Excludes user-initiated foreground alerts (e.g., undo toast)
   - Priority: milestone > daily commitment > end-of-day

7. **Write unit tests:**
   - Daily commitment scheduling
   - Pre-milestone notification (1 day before)
   - Milestone-day notification
   - Rate limiter (3/day cap enforcement)
   - Post-relapse 24hr pause
   - Quiet hours enforcement
   - No PHI in notification payloads

**Verification gate:** `xcodebuild test` passes for notification service tests. Notifications scheduled correctly in simulator. 3/day cap enforced. No PHI in payloads verified.

---

### Agent G: Celebration UX

**Role:** Implement three-tier haptic/animation escalation, confetti, sound (off by default), journaling reflection prompt, reduced-motion fallbacks.

**Depends on:** Agent D (chip views), Agent A (chip awards)

**Artifacts:**
- `Views/Tools/Chips/MilestoneCelebrationView.swift` -- Celebration modal
- `Services/HapticFeedbackService.swift` -- Haptic feedback manager
- `Theme/CelebrationAnimations.swift` -- Confetti and celebration animations
- `Tests/Unit/CelebrationUXTests.swift` -- UI tests

**Steps:**

1. **Implement three-tier celebration escalation:**
   - **Tier 1 (small):** Days 1, 7, 30 — Subtle haptic (`.success`), brief animation (fade in + scale), no confetti
   - **Tier 2 (medium):** Days 90, 180, 270 — Medium haptic (`.impact(.medium)`), confetti, optional sound
   - **Tier 3 (ceremonial):** Days 365, 730, 1095+, 1825, 3650 — Strong haptic (`.impact(.heavy)`), extended animation, confetti burst, journaling prompt, share invitation

2. **Implement MilestoneCelebrationView:**
   ```swift
   // Views/Tools/Chips/MilestoneCelebrationView.swift
   struct MilestoneCelebrationView: View {
       let chipAward: RRChipAward
       let tier: CelebrationTier
       @State private var showConfetti = false
       @State private var showJournalPrompt = false
       @Environment(\.dismiss) private var dismiss
       @Environment(\.accessibilityReduceMotion) private var reduceMotion

       enum CelebrationTier {
           case small, medium, ceremonial
       }

       var body: some View {
           ZStack {
               // Background
               Color.black.opacity(0.3)
                   .ignoresSafeArea()

               // Chip + message
               VStack(spacing: 24) {
                   if !reduceMotion {
                       ChipView(chipAward: chipAward, showFront: true, size: .large)
                           .scaleEffect(showConfetti ? 1.0 : 0.5)
                           .opacity(showConfetti ? 1.0 : 0.0)
                           .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showConfetti)
                   } else {
                       ChipView(chipAward: chipAward, showFront: true, size: .large)
                   }

                   Text("You earned a chip!")
                       .font(.title)
                       .fontWeight(.bold)
                       .foregroundColor(.white)

                   Text("\(chipAward.milestoneDays ?? 0) Days")
                       .font(.system(size: 48, weight: .bold, design: .rounded))
                       .foregroundColor(.rrPrimary)

                   if let scripture = chipAward.scripture {
                       Text(scripture)
                           .font(.body)
                           .foregroundColor(.white.opacity(0.9))
                           .multilineTextAlignment(.center)
                           .padding(.horizontal)
                   }

                   Button("Continue") {
                       if tier == .ceremonial {
                           showJournalPrompt = true
                       } else {
                           dismiss()
                       }
                   }
                   .buttonStyle(.borderedProminent)
               }
               .padding()

               // Confetti
               if showConfetti && !reduceMotion {
                   ConfettiView()
                       .ignoresSafeArea()
                       .allowsHitTesting(false)
               }
           }
           .onAppear {
               performCelebration()
           }
           .sheet(isPresented: $showJournalPrompt) {
               JournalingPromptView(chipAward: chipAward)
           }
       }

       private func performCelebration() {
           // Haptic feedback
           HapticFeedbackService.shared.celebrate(tier: tier)

           // Animation
           if !reduceMotion {
               withAnimation(.easeOut(duration: 0.5)) {
                   showConfetti = true
               }
           }

           // Sound (off by default, user-configurable)
           if tier == .medium || tier == .ceremonial {
               // Play celebration sound if enabled
           }
       }
   }
   ```

3. **Implement HapticFeedbackService:**
   ```swift
   // Services/HapticFeedbackService.swift
   import UIKit

   final class HapticFeedbackService {
       static let shared = HapticFeedbackService()

       private init() {}

       func celebrate(tier: MilestoneCelebrationView.CelebrationTier) {
           switch tier {
           case .small:
               let generator = UINotificationFeedbackGenerator()
               generator.notificationOccurred(.success)
           case .medium:
               let generator = UIImpactFeedbackGenerator(style: .medium)
               generator.impactOccurred()
           case .ceremonial:
               let generator = UIImpactFeedbackGenerator(style: .heavy)
               generator.impactOccurred()
               DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                   generator.impactOccurred()
               }
           }
       }
   }
   ```

4. **Implement ConfettiView:**
   ```swift
   // Theme/CelebrationAnimations.swift
   struct ConfettiView: View {
       @State private var confettiPieces: [ConfettiPiece] = []

       struct ConfettiPiece: Identifiable {
           let id = UUID()
           let color: Color
           let x: CGFloat
           let y: CGFloat
           let rotation: Double
       }

       var body: some View {
           GeometryReader { geometry in
               ZStack {
                   ForEach(confettiPieces) { piece in
                       Circle()
                           .fill(piece.color)
                           .frame(width: 10, height: 10)
                           .position(x: piece.x, y: piece.y)
                           .rotationEffect(.degrees(piece.rotation))
                   }
               }
               .onAppear {
                   generateConfetti(in: geometry.size)
               }
           }
       }

       private func generateConfetti(in size: CGSize) {
           let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple]
           for _ in 0..<50 {
               let piece = ConfettiPiece(
                   color: colors.randomElement()!,
                   x: CGFloat.random(in: 0...size.width),
                   y: CGFloat.random(in: -100...size.height),
                   rotation: Double.random(in: 0...360)
               )
               confettiPieces.append(piece)
           }

           // Animate falling
           withAnimation(.easeOut(duration: 3)) {
               confettiPieces = confettiPieces.map {
                   ConfettiPiece(
                       color: $0.color,
                       x: $0.x + CGFloat.random(in: -50...50),
                       y: size.height + 100,
                       rotation: $0.rotation + 360
                   )
               }
           }
       }
   }
   ```

5. **Implement JournalingPromptView (post-milestone reflection):**
   ```swift
   // Views/Tools/Chips/JournalingPromptView.swift
   struct JournalingPromptView: View {
       let chipAward: RRChipAward
       @State private var response: String = ""
       @Environment(\.dismiss) private var dismiss

       var body: some View {
           NavigationStack {
               VStack(spacing: 24) {
                   Text(chipAward.journalPrompt ?? "What helped you get to \(chipAward.milestoneDays ?? 0) days?")
                       .font(.title2)
                       .fontWeight(.semibold)
                       .multilineTextAlignment(.center)
                       .padding()

                   TextEditor(text: $response)
                       .frame(minHeight: 200)
                       .padding()
                       .background(Color.rrSurface)
                       .cornerRadius(12)

                   Text("This will be saved privately and can be reviewed later.")
                       .font(.caption)
                       .foregroundColor(.rrTextSecondary)

                   Spacer()

                   HStack(spacing: 16) {
                       Button("Skip") {
                           dismiss()
                       }
                       .buttonStyle(.bordered)

                       Button("Save") {
                           // Save response to chipAward.journalResponse
                           dismiss()
                       }
                       .buttonStyle(.borderedProminent)
                   }
               }
               .padding()
               .navigationTitle("Reflection")
               .navigationBarTitleDisplayMode(.inline)
           }
       }
   }
   ```

6. **Implement reduced-motion fallback:**
   - Check `@Environment(\.accessibilityReduceMotion)`
   - If true: static chip reveal, no confetti, no flip animation, no scale effects

7. **Write UI tests:**
   - Tier 1 celebration (small milestones)
   - Tier 2 celebration (medium milestones, confetti)
   - Tier 3 celebration (ceremonial, journaling prompt)
   - Reduced-motion fallback
   - Haptic feedback triggered

**Verification gate:** `xcodebuild test` passes for celebration UX tests. Confetti animates correctly. Reduced-motion fallback functional. Haptic feedback verified.

---

### Agent H: Privacy & Widget

**Role:** Implement per-tracker visibility settings, stealth alternate app icon, quick-blur gesture, generic widget mode (WidgetKit), biometric lock integration.

**Depends on:** Agent A (types), Agent F (notifications — for visibility control)

**Artifacts:**
- `Views/Settings/ChipPrivacySettingsView.swift` -- Per-tracker privacy controls
- `Services/PrivacyService.swift` -- Privacy state management
- `Services/StealthIconService.swift` -- Alternate app icon management
- `ChipsWidget/ChipsWidget.swift` -- WidgetKit extension
- `Tests/Unit/PrivacyServiceTests.swift` -- Unit tests

**Steps:**

1. **Implement ChipPrivacySettingsView (per-tracker visibility):**
   ```swift
   // Views/Settings/ChipPrivacySettingsView.swift
   struct ChipPrivacySettingsView: View {
       let tracker: RRTracker
       @State private var visibleInWidget: Bool
       @State private var visibleInNotifications: Bool
       @State private var shareLevel: ShareLevel

       var body: some View {
           Form {
               Section("Widget Visibility") {
                   Toggle("Show in widget", isOn: $visibleInWidget)
                   Toggle("Show in notifications", isOn: $visibleInNotifications)
               }

               Section("Shared Data") {
                   Picker("Share level", selection: $shareLevel) {
                       Text("Full details").tag(ShareLevel.full)
                       Text("Summary only").tag(ShareLevel.summary)
                       Text("Count only").tag(ShareLevel.countOnly)
                   }
               }

               Section("Generic Widget Mode") {
                   Toggle("Hide addiction name in widget", isOn: $hideLabel)
                   Text("The widget will show the streak count and a generic icon.")
                       .font(.caption)
                       .foregroundColor(.rrTextSecondary)
               }
           }
           .navigationTitle("Privacy Settings")
       }
   }
   ```

2. **Implement StealthIconService (alternate app icon):**
   ```swift
   // Services/StealthIconService.swift
   import UIKit

   final class StealthIconService {
       static let shared = StealthIconService()

       private init() {}

       enum AlternateIcon: String, CaseIterable {
           case `default` = "AppIcon"
           case calendar = "AppIcon-Calendar"
           case notes = "AppIcon-Notes"
           case weather = "AppIcon-Weather"

           var displayName: String {
               switch self {
               case .default: return "Regal Recovery"
               case .calendar: return "Calendar"
               case .notes: return "Notes"
               case .weather: return "Weather"
               }
           }
       }

       func setAlternateIcon(_ icon: AlternateIcon) async throws {
           guard UIApplication.shared.supportsAlternateIcons else {
               throw StealthIconError.notSupported
           }

           let iconName = icon == .default ? nil : icon.rawValue
           try await UIApplication.shared.setAlternateIconName(iconName)
       }

       func currentIcon() -> AlternateIcon {
           guard let iconName = UIApplication.shared.alternateIconName else {
               return .default
           }
           return AlternateIcon(rawValue: iconName) ?? .default
       }
   }

   enum StealthIconError: Error {
       case notSupported
   }
   ```

3. **Implement QuickBlurView (long-press gesture):**
   ```swift
   // Views/Shared/QuickBlurView.swift
   struct QuickBlurView<Content: View>: View {
       let content: Content
       @State private var isBlurred = false

       init(@ViewBuilder content: () -> Content) {
           self.content = content()
       }

       var body: some View {
           content
               .blur(radius: isBlurred ? 20 : 0)
               .onLongPressGesture(minimumDuration: 0.5) {
                   withAnimation {
                       isBlurred.toggle()
                   }
               }
               .onTapGesture {
                   if isBlurred {
                       withAnimation {
                           isBlurred = false
                       }
                   }
               }
       }
   }
   ```

4. **Implement ChipsWidget (WidgetKit):**
   ```swift
   // ChipsWidget/ChipsWidget.swift
   import WidgetKit
   import SwiftUI

   struct ChipsWidget: Widget {
       let kind: String = "ChipsWidget"

       var body: some WidgetConfiguration {
           StaticConfiguration(kind: kind, provider: ChipsProvider()) { entry in
               ChipsWidgetEntryView(entry: entry)
           }
           .configurationDisplayName("Streak Counter")
           .description("Track your sobriety streak.")
           .supportedFamilies([.systemSmall, .systemMedium])
       }
   }

   struct ChipsProvider: TimelineProvider {
       func placeholder(in context: Context) -> ChipsEntry {
           ChipsEntry(date: Date(), days: 0, label: "Recovery", colorHex: "#3B82F6")
       }

       func getSnapshot(in context: Context, completion: @escaping (ChipsEntry) -> Void) {
           // Fetch latest tracker data from SwiftData
           let entry = ChipsEntry(date: Date(), days: 42, label: "Alcohol", colorHex: "#3B82F6")
           completion(entry)
       }

       func getTimeline(in context: Context, completion: @escaping (Timeline<ChipsEntry>) -> Void) {
           // Fetch latest tracker data from SwiftData
           let entry = ChipsEntry(date: Date(), days: 42, label: "Alcohol", colorHex: "#3B82F6")
           let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(3600)))
           completion(timeline)
       }
   }

   struct ChipsEntry: TimelineEntry {
       let date: Date
       let days: Int
       let label: String
       let colorHex: String
   }

   struct ChipsWidgetEntryView: View {
       var entry: ChipsProvider.Entry

       var body: some View {
           VStack(spacing: 8) {
               Text("\(entry.days)")
                   .font(.system(size: 48, weight: .bold, design: .rounded))
                   .foregroundColor(Color(hex: entry.colorHex))

               Text("days")
                   .font(.caption)
                   .foregroundColor(.secondary)

               // Generic mode: hide label
               if !UserDefaults.standard.bool(forKey: "hideWidgetLabel") {
                   Text(entry.label)
                       .font(.caption2)
                       .foregroundColor(.secondary)
               }
           }
           .containerBackground(.background, for: .widget)
       }
   }
   ```

5. **Implement biometric lock integration:**
   - Reuse existing `BiometricAuthService` from Wave 1
   - Lock chip views when biometric lock is enabled
   - Unlock on successful authentication
   - Per-tracker lock settings (opt-in)

6. **Write unit tests:**
   - Alternate app icon switching
   - Quick-blur gesture (blur/unblur)
   - Widget data refresh (timeline)
   - Generic widget mode (label hidden)
   - Per-tracker visibility settings

**Verification gate:** `xcodebuild test` passes for privacy service tests. Alternate app icons functional. Widget renders correctly in simulator. Generic mode hides addiction name.

---

### Agent I: Sharing & Accountability

**Role:** Implement share image generation (metadata-stripped), aesthetic templates, per-tracker partner permission matrix, bidirectional consent flow, instant revocation.

**Depends on:** Agent A (types), Agent D (chip views)

**Artifacts:**
- `Services/ChipShareService.swift` -- Share image generation
- `Views/Tools/Chips/ChipShareSheet.swift` -- Share sheet UI
- `Views/Tools/Chips/AccountabilityPartnerView.swift` -- Partner permission matrix
- `Tests/Unit/ChipShareServiceTests.swift` -- Unit tests

**Steps:**

1. **Implement ChipShareService (image generation):**
   ```swift
   // Services/ChipShareService.swift
   import UIKit

   final class ChipShareService {
       /// Generate a share image for a chip award (metadata-stripped).
       func generateShareImage(
           for chipAward: RRChipAward,
           tracker: RRTracker,
           template: ShareTemplate
       ) -> UIImage

       /// Strip all metadata from image (no GPS, no device ID).
       func stripMetadata(from image: UIImage) -> UIImage

       enum ShareTemplate {
           case minimal       // Just chip + days
           case scripture     // Chip + days + scripture
           case celebration   // Chip + days + confetti background
       }
   }
   ```

2. **Implement ChipShareSheet (share UI):**
   ```swift
   // Views/Tools/Chips/ChipShareSheet.swift
   struct ChipShareSheet: View {
       let chipAward: RRChipAward
       let tracker: RRTracker
       @State private var selectedTemplate: ChipShareService.ShareTemplate = .minimal
       @State private var shareImage: UIImage?

       var body: some View {
           NavigationStack {
               VStack(spacing: 24) {
                   // Template picker
                   Picker("Template", selection: $selectedTemplate) {
                       Text("Minimal").tag(ChipShareService.ShareTemplate.minimal)
                       Text("With Scripture").tag(ChipShareService.ShareTemplate.scripture)
                       Text("Celebration").tag(ChipShareService.ShareTemplate.celebration)
                   }
                   .pickerStyle(.segmented)
                   .padding()

                   // Preview
                   if let shareImage {
                       Image(uiImage: shareImage)
                           .resizable()
                           .scaledToFit()
                           .frame(maxHeight: 400)
                           .cornerRadius(12)
                           .shadow(radius: 10)
                   }

                   Spacer()

                   // Share button
                   ShareLink(item: Image(uiImage: shareImage ?? UIImage()), preview: SharePreview("Milestone", image: Image(uiImage: shareImage ?? UIImage()))) {
                       Label("Share Image", systemImage: "square.and.arrow.up")
                           .frame(maxWidth: .infinity)
                           .padding()
                           .background(Color.rrPrimary)
                           .foregroundColor(.white)
                           .cornerRadius(12)
                   }
                   .padding()
               }
               .navigationTitle("Share Milestone")
               .navigationBarTitleDisplayMode(.inline)
               .task {
                   generateImage()
               }
               .onChange(of: selectedTemplate) { _, _ in
                   generateImage()
               }
           }
       }

       private func generateImage() {
           let service = ChipShareService()
           shareImage = service.generateShareImage(for: chipAward, tracker: tracker, template: selectedTemplate)
       }
   }
   ```

3. **Implement AccountabilityPartnerView (permission matrix):**
   ```swift
   // Views/Tools/Chips/AccountabilityPartnerView.swift
   struct AccountabilityPartnerView: View {
       let tracker: RRTracker
       @State private var partners: [AccountabilityPartner] = []

       var body: some View {
           Form {
               Section("Accountability Partners") {
                   ForEach(partners) { partner in
                       PartnerRow(partner: partner, tracker: tracker)
                   }

                   Button("Add Partner") {
                       // Add partner flow
                   }
               }

               Section {
                   Text("Partners can only see what you allow. You can revoke access instantly at any time.")
                       .font(.caption)
                       .foregroundColor(.rrTextSecondary)
               }
           }
           .navigationTitle("Sharing")
       }
   }

   struct PartnerRow: View {
       let partner: AccountabilityPartner
       let tracker: RRTracker

       var body: some View {
           DisclosureGroup {
               PartnerPermissionMatrix(partner: partner, tracker: tracker)
           } label: {
               HStack {
                   Text(partner.name)
                       .font(.headline)
                   Spacer()
                   Text(partner.status.rawValue.capitalized)
                       .font(.caption)
                       .foregroundColor(.rrTextSecondary)
               }
           }
       }
   }

   struct PartnerPermissionMatrix: View {
       let partner: AccountabilityPartner
       let tracker: RRTracker

       var body: some View {
           VStack(spacing: 12) {
               PermissionToggle(label: "See streak count", isOn: .constant(true))
               PermissionToggle(label: "See milestones", isOn: .constant(true))
               PermissionToggle(label: "See relapses", isOn: .constant(false))
               PermissionToggle(label: "See journal entries", isOn: .constant(false))

               Button("Revoke Access", role: .destructive) {
                   // Revoke partner access
               }
               .frame(maxWidth: .infinity)
               .padding()
               .background(Color.red.opacity(0.1))
               .foregroundColor(.red)
               .cornerRadius(8)
           }
       }
   }

   struct PermissionToggle: View {
       let label: String
       @Binding var isOn: Bool

       var body: some View {
           Toggle(label, isOn: $isOn)
       }
   }

   struct AccountabilityPartner: Identifiable {
       let id: UUID
       let name: String
       let status: PartnerStatus

       enum PartnerStatus: String {
           case invited, accepted, revoked
       }
   }
   ```

4. **Implement bidirectional consent flow:**
   - Partner A invites Partner B
   - Partner B accepts (bidirectional consent)
   - Both must consent to share data
   - Either can revoke instantly (no grace period)

5. **Write unit tests:**
   - Share image generation (all templates)
   - Metadata stripping validation
   - Partner permission matrix
   - Consent flow (invite → accept → revoke)

**Verification gate:** `xcodebuild test` passes for share service tests. Share images generated correctly. Metadata stripped. Partner permissions functional.

---

### Agent J: Integration & E2E Testing

**Role:** Wire everything together: view models orchestrating all services, navigation between chip views, feature flag gating, seed data updates, full-flow testing.

**Depends on:** All other agents (A-I must be complete)

**Artifacts:**
- `ViewModels/ChipViewModel.swift` -- Main view model orchestrating chip system
- `ViewModels/TrackerViewModel.swift` -- View model for tracker management
- `Views/Tools/Chips/ChipsRootView.swift` -- Root navigation for chip system
- `Tests/Unit/ChipViewModelTests.swift` -- View model unit tests
- `Tests/Integration/ChipsE2ETests.swift` -- E2E flow tests

**Steps:**

1. **Implement ChipViewModel:**
   ```swift
   // ViewModels/ChipViewModel.swift
   @Observable
   final class ChipViewModel {
       private let chipEngine: ChipEngine
       private let trackerEngine: TrackerEngine
       private let resetService: TrackerResetService
       private let notificationService: ChipNotificationService
       private let shareService: ChipShareService
       private let modelContext: ModelContext

       var trackers: [RRTracker] = []
       var selectedTracker: RRTracker?
       var isLoading = false
       var error: String?

       init(
           chipEngine: ChipEngine,
           trackerEngine: TrackerEngine,
           resetService: TrackerResetService,
           notificationService: ChipNotificationService,
           shareService: ChipShareService,
           modelContext: ModelContext
       )

       // MARK: - Loading

       func loadTrackers() async
       func loadChipsForTracker(_ tracker: RRTracker) async

       // MARK: - Tracker Management

       func createTracker(
           fellowshipType: FellowshipType,
           label: String,
           startDate: Date,
           customAbstinenceDefinition: String?
       ) async throws

       func deleteTracker(_ tracker: RRTracker) async throws

       // MARK: - Reset Flow

       func logLapse(
           for tracker: RRTracker,
           note: String?,
           triggers: [String],
           forceReset: Bool
       ) async throws

       func logRelapse(
           for tracker: RRTracker,
           note: String?,
           triggers: [String]
       ) async throws

       func undoReset(for tracker: RRTracker) async throws

       // MARK: - Milestone Award

       func checkAndAwardMilestones(for tracker: RRTracker) async throws
       func showCelebration(for chipAward: RRChipAward) -> Bool

       // MARK: - Sharing

       func generateShareImage(for chipAward: RRChipAward, template: ChipShareService.ShareTemplate) -> UIImage
   }
   ```

2. **Implement TrackerViewModel:**
   ```swift
   // ViewModels/TrackerViewModel.swift
   @Observable
   final class TrackerViewModel {
       private let trackerEngine: TrackerEngine
       private let modelContext: ModelContext

       var tracker: RRTracker
       var currentStreakDays: Int = 0
       var longestStreakDays: Int = 0
       var totalSoberDays: Int = 0
       var isLoading = false

       init(tracker: RRTracker, trackerEngine: TrackerEngine, modelContext: ModelContext)

       func load() async
       func updateStreak() async
   }
   ```

3. **Implement ChipsRootView (navigation):**
   ```swift
   // Views/Tools/Chips/ChipsRootView.swift
   struct ChipsRootView: View {
       @State private var viewModel: ChipViewModel
       @State private var selectedTracker: RRTracker?
       @State private var showCreateTracker = false

       var body: some View {
           NavigationStack {
               List {
                   ForEach(viewModel.trackers) { tracker in
                       NavigationLink(value: tracker) {
                           TrackerRow(tracker: tracker)
                       }
                   }

                   Button("Add Tracker") {
                       showCreateTracker = true
                   }
               }
               .navigationTitle("Recovery Trackers")
               .navigationDestination(for: RRTracker.self) { tracker in
                   TrackerDetailView(tracker: tracker, viewModel: viewModel)
               }
               .sheet(isPresented: $showCreateTracker) {
                   CreateTrackerView(viewModel: viewModel)
               }
               .task {
                   await viewModel.loadTrackers()
               }
           }
       }
   }

   struct TrackerRow: View {
       let tracker: RRTracker

       var body: some View {
           HStack {
               // Chip icon
               Circle()
                   .fill(Color(hex: tracker.chipAwards.last?.chipColorHex ?? "#3B82F6"))
                   .frame(width: 40, height: 40)

               VStack(alignment: .leading) {
                   Text(tracker.label)
                       .font(.headline)
                   Text("\(tracker.currentStreakDays) days")
                       .font(.subheadline)
                       .foregroundColor(.rrTextSecondary)
               }

               Spacer()

               Image(systemName: "chevron.right")
                   .foregroundColor(.rrTextSecondary)
           }
       }
   }

   struct TrackerDetailView: View {
       let tracker: RRTracker
       @State private var viewModel: ChipViewModel

       var body: some View {
           ScrollView {
               VStack(spacing: 24) {
                   ChipCounterView(tracker: tracker, chipEngine: viewModel.chipEngine)
                   ChipGalleryView(tracker: tracker)

                   Button("Log Relapse") {
                       // Show reset confirmation
                   }
                   .buttonStyle(.bordered)
               }
           }
           .navigationTitle(tracker.label)
       }
   }
   ```

4. **Integrate with ServiceContainer:**
   - Add `ChipEngine`, `TrackerEngine`, `ChipNotificationService`, etc. to `ServiceContainer`
   - Wire up dependencies
   - Feature flag gate: `feature.chips` → if disabled, hide chip views

5. **Seed data updates:**
   - Add sample trackers to seed data
   - Pre-populate chips for demo users
   - Include all four V1 fellowships (SA, AA, NA, Custom)

6. **Write E2E tests:**
   - Full flow: create tracker → set start date → earn chips retroactively → log lapse → undo → log relapse → view gallery → share chip
   - Multi-tracker flow: create AA tracker, create NA tracker, verify independent streaks
   - Reset flow: lapse (streak continues) vs. relapse (streak resets)
   - Celebration UX: verify three-tier escalation
   - Notification flow: verify milestone notification fires (simulator)
   - Privacy flow: hide tracker in widget, verify widget updates
   - Sharing flow: generate share image, verify metadata stripped

7. **Feature flag validation:**
   - Flag enabled: chip views visible
   - Flag disabled: chip views hidden, fallback to old streak system

8. **Write view model unit tests:**
   - ChipViewModel: loadTrackers, createTracker, logLapse, logRelapse, undoReset
   - TrackerViewModel: load, updateStreak
   - Mock all service dependencies

**Verification gate:** `xcodebuild test` passes for all unit tests and E2E tests. Full chip system functional. Feature flag gating works. Seed data populated.

---

## Execution Timeline

```
Week 1:
  Agent A: Data Model & Types                              [3 days]
  Agent B: Fellowship Tradition Engine                     [2 days, starts after Agent A day 2]
  Agent H: Privacy & Widget (parallel, needs types only)   [3 days]

Week 2:
  Agent C: Event-Sourced Tracker Logic                     [3 days, depends on A+B]
  Agent D: Chip Visual Components                          [3 days, depends on A+B]
  Agent F: Notifications                                   [2 days, depends on A+C]

Week 3:
  Agent E: Reset/Relapse Flow UI                           [2 days, depends on C+A]
  Agent G: Celebration UX                                  [2 days, depends on D+A]
  Agent I: Sharing & Accountability                        [2 days, depends on A+D]

Week 4:
  Agent J: Integration & E2E Testing                       [3 days, depends on all]
  All: Bug fixes, coverage gaps, review                    [2 days]
```

**Total: 4 weeks with parallel workstreams**

---

## Dependency Graph

```
Agent A (Data Model & Types)
  |
  +---> Agent B (Fellowship Tradition Engine)
  |       |
  |       +---> Agent C (Event-Sourced Tracker Logic)
  |       |       |
  |       |       +---> Agent E (Reset/Relapse Flow UI)
  |       |       |       |
  |       |       |       +---> Agent J (Integration & E2E)
  |       |       |
  |       |       +---> Agent F (Notifications) -----> Agent J
  |       |
  |       +---> Agent D (Chip Visual Components)
  |               |
  |               +---> Agent G (Celebration UX) -----> Agent J
  |               |
  |               +---> Agent I (Sharing & Accountability) -----> Agent J
  |
  +---> Agent H (Privacy & Widget) -----> Agent J
```

---

## Verification Gates Summary

| Gate | Command | Criteria | When |
|------|---------|----------|------|
| G1: Models compile | `xcodebuild build` | Zero errors | After Agent A |
| G2: Model tests GREEN | `xcodebuild test -only-testing:ChipModelsTests` | 100% pass | After Agent A |
| G3: Engine tests GREEN | `xcodebuild test -only-testing:ChipEngineTests` | 100% pass, full fellowship coverage | After Agent B |
| G4: Tracker tests GREEN | `xcodebuild test -only-testing:TrackerEngineTests` | 100% pass, reset flows validated | After Agent C |
| G5: Chip view tests GREEN | `xcodebuild test -only-testing:ChipViewTests` | All shapes render, VoiceOver labels correct | After Agent D |
| G6: Reset flow tests GREEN | `xcodebuild test -only-testing:ResetFlowTests` | Compassionate copy validated | After Agent E |
| G7: Notification tests GREEN | `xcodebuild test -only-testing:ChipNotificationServiceTests` | 3/day cap enforced, no PHI | After Agent F |
| G8: Celebration tests GREEN | `xcodebuild test -only-testing:CelebrationUXTests` | Three tiers work, reduced-motion fallback | After Agent G |
| G9: Privacy tests GREEN | `xcodebuild test -only-testing:PrivacyServiceTests` | Stealth icon works, widget generic mode | After Agent H |
| G10: Share tests GREEN | `xcodebuild test -only-testing:ChipShareServiceTests` | Metadata stripped, templates generate | After Agent I |
| G11: E2E tests GREEN | `xcodebuild test -only-testing:ChipsE2ETests` | Full flows pass | After Agent J |
| G12: Feature flag works | Manual test | Chip views hidden when flag disabled | After Agent J |
| G13: Build success | `xcodebuild build` | Zero errors, zero warnings | Before merge |

---

## PR Strategy

Following the project's <400 line PR target, this feature should be split into stacked PRs:

1. **PR 1: PRD + Acceptance Criteria** — This implementation plan + PRD
2. **PR 2: Data Models & Types** — Agent A output (`RRChipModels.swift`, `ChipTypes.swift`, JSON)
3. **PR 3: Fellowship Tradition Engine** — Agent B output (`ChipEngine.swift`, `ChipColorResolver.swift`)
4. **PR 4: Event-Sourced Tracker Logic** — Agent C output (`TrackerEngine.swift`, `TrackerResetService.swift`)
5. **PR 5: Chip Visual Components** — Agent D output (all chip views + shapes)
6. **PR 6: Reset/Relapse Flow UI** — Agent E output (confirmation modal, undo toast, trigger tagging)
7. **PR 7: Notifications** — Agent F output (`ChipNotificationService.swift`)
8. **PR 8: Celebration UX** — Agent G output (celebration modal, confetti, haptics, journaling)
9. **PR 9: Privacy & Widget** — Agent H output (privacy settings, stealth icon, widget)
10. **PR 10: Sharing & Accountability** — Agent I output (share service, partner permissions)
11. **PR 11: Integration & E2E** — Agent J output (view models, navigation, E2E tests)

Each PR is independently reviewable and mergeable. Feature flag keeps everything hidden until the full stack is deployed.

---

## Migration Strategy (Existing Users)

For users with existing data in `RRStreak`, `RRMilestone`, `RRRelapse` models:

1. **Coexistence period (Wave 1.5 → Wave 2):**
   - Both systems coexist
   - New users get chip system by default
   - Existing users see in-app prompt: "Upgrade to new chip system?"

2. **Migration flow:**
   - User opts in via settings or prompt
   - Create `RRTracker` from existing `RRAddiction`
   - Generate START event with `sobrietyDate` as `occurredAt`
   - Generate RELAPSE events from `RRRelapse` records
   - Retroactively generate `RRChipAward` records from `RRMilestone`
   - Preserve `createdAt` timestamps
   - Mark old models as archived (soft delete)

3. **Rollback:**
   - User can roll back to old system within 30 days
   - Both systems preserved during coexistence period

4. **Full cutover (Wave 2 end):**
   - After 90% migration rate, old system deprecated
   - Final migration for remaining users (forced, with notice)

---

## Success Criteria

The chip system is ready for production when:

1. All 11 verification gates pass (G1-G11)
2. All four V1 fellowships (SA, AA, NA, Custom) render correctly with authentic-feeling chips
3. Day 0 commitment chip awarded immediately on tracker creation
4. Lapse vs. relapse distinction presented with compassionate copy
5. 60-second undo window functional
6. All prior chips preserved across resets in gallery (grouped by streak attempt)
7. Event log projection accurately computes current streak, longest streak, total sober days
8. App functions fully offline (no network required for core flows)
9. Biometric lock, stealth icon, and per-tracker privacy all functional
10. Notifications cap at 3/day with no PHI in payloads
11. Screen reader users can identify every chip without seeing color (VoiceOver labels complete)
12. Dynamic Type tested at AX5 (largest accessibility size) with no clipping
13. Reduced-motion users see static fallbacks (no confetti, no flip animations)
14. Feature flag gating works: chip views hidden when `feature.chips` disabled
15. Share images generated with metadata stripped
16. Retroactive chip population works for mid-recovery installs
17. Timezone handling: explicit prompt on device TZ change, never silent
18. Grace period (6 hours past midnight) functional
19. DST transitions handled (23-hour and 25-hour days both count as 1 day)
20. Widget renders correctly with generic mode (addiction name hidden)

---

## Notes

- **iOS 17+ required:** SwiftData, Observation framework, WidgetKit with `.containerBackground` all require iOS 17 minimum deployment target.
- **No backend changes:** All data is local/on-device. No API, no server push, no cloud sync (unless user opts in to existing sync system).
- **Christian integration:** Scripture assignment per milestone continues the app's faith-based approach.
- **Compassionate design:** Every reset flow reviewed against SAMHSA/ISSUP language guidance. No banned phrases ("fail," "broke," "ruined").
- **Parallel trackers:** Each addiction is a first-class tracker with its own fellowship profile. No cross-contamination.
- **Event-sourced:** Immutable event log is the source of truth. Streaks are projections, never mutable counters.
- **Fast-follow:** Remaining 16 fellowships (CA, CMA, MA, HA, PA, NicA, GA, OA, DA, EA, FA, WA, CoDA, ACA, Al-Anon, SLAA) added in Wave 2.5 with zero architecture changes.

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Scope creep (20+ fellowships) | High | High | V1 limits to 4 fellowships; architecture ready for all 20+ |
| Event log performance (10+ years of events) | Medium | Medium | Index on `trackerId` + `occurredAt`; cache computed values |
| Timezone edge cases | High | Medium | Comprehensive test coverage for DST, midnight boundary, retroactive dates |
| SwiftData migration complexity | Medium | High | Coexistence period with rollback; phased migration over 90 days |
| Notification permission denial | High | Low | All notifications are enhancements, not requirements; app fully functional without |
| Reduced-motion accessibility | Medium | Medium | Static fallbacks for all animations; test with accessibility settings |
| Widget refresh budget (iOS limitation) | Low | Low | Cache computed values; respect WidgetKit ~40 reloads/day limit |

---

## Open Questions

1. **Should step chips be gated behind a separate feature flag?** (Step-completion chips are SLAA tradition, not universal)
2. **Should null-day mechanic be V1 or fast-follow?** (Required for FA/WA, but low user count)
3. **Should we support multiple trackers for the same addiction?** (e.g., "Alcohol (attempt 1)" and "Alcohol (attempt 2)" both visible)
4. **What's the UX for timezone change while paused?** (Tracker paused for 6 months, user moves timezones, resumes — which TZ applies?)
5. **Should custom milestones be additive or override fellowship milestones?** (User in AA adds 100-day custom chip — does it appear alongside AA's standard 90-day chip?)

**Recommendation:** Defer questions 1, 2, 3 to fast-follow. Resolve questions 4, 5 during Agent C implementation.

---

## Conclusion

The Chips/Milestone System is the most architecturally ambitious feature in Regal Recovery to date. It requires event-sourced data modeling, multi-fellowship tradition profiles, compassionate UX for relapse flows, privacy-first design, and accessibility compliance — all without any backend changes. The defining technical decision is treating each addiction as an independent, event-sourced tracker themed by a swappable fellowship profile. The defining product decision is that safety valves around relapse (lapse/relapse distinction, immutable history, undo window, What-the-Hell guard) are core flows, not optional features. This multi-agent plan breaks the work into 10 agents with clear dependencies, stacked PRs <400 lines each, and 11 verification gates. V1 ships with SA, AA, NA, and Custom fellowships; the remaining 16 follow with zero architecture changes. Total timeline: 4 weeks with parallel workstreams. Success criteria: authentic-feeling chips, compassionate reset flows, offline-first operation, full accessibility, and zero banned language.
