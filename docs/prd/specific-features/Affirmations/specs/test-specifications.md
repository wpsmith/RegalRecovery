# Affirmations Experience -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Acceptance Criteria Source:** `docs/prd/specific-features/Affirmations/affirmations.md`

---

## Naming Convention

Test names follow the project convention: `Test{Domain}_{AC_ID}_{Description}`

All acceptance criteria IDs use the prefix `AFF_AC` for Affirmations feature requirements and `AFF_NFR` for non-functional requirements.

---

## Test Personas

| Persona | Sobriety | Level | Track | Special Conditions | Sessions |
|---------|----------|-------|-------|--------------------|----------|
| Alex | 45 days | 2 | Standard | Active SOS user | 32 |
| Marcus | 7 days | 1 | Faith-Based | Post-relapse within 24h | 4 |
| Diego | 200 days | 4 | Standard | Healthy sexuality enabled | 150 |

### Persona Details

**Alex** -- Mid-early recovery. 45 days sober, Level 2 unlocked at Day 14. Standard (secular) track. Frequently uses SOS mode during urge moments. Has 12 favorites, 3 hidden affirmations. No custom affirmations yet. Evening mood ratings averaging 3.2/5 over last 7 sessions.

**Marcus** -- Early recovery, post-relapse. 7 days since sobriety reset. Faith-based track. Reported relapse 18 hours ago, triggering 24-hour post-relapse window. Level locked to 1. Has completed 4 total sessions. No audio recordings. Mood declining over last 3 sessions.

**Diego** -- Established recovery. 200 days sober, Level 4 fully unlocked. Standard track with healthy sexuality category explicitly enabled at Day 85. 150 total sessions completed. 8 custom affirmations, 5 audio recordings. Consistently high mood ratings (4.2/5 average).

---

## Coverage Requirements

| Module | Target | Rationale |
|--------|--------|-----------|
| `internal/domain/affirmation/level_engine.go` | 100% | Critical path: level progression determines clinical safety of content served |
| `internal/domain/affirmation/content_selection.go` | 90% | Core content delivery with repeat prevention and category distribution |
| `internal/domain/affirmation/session.go` | 85% | Morning/evening session orchestration |
| `internal/domain/affirmation/sos.go` | 100% | Critical path: SOS mode is highest-stakes clinical delivery context |
| `internal/domain/affirmation/custom.go` | 90% | Custom affirmation validation and rotation |
| `internal/domain/affirmation/audio.go` | 100% | Critical path: privacy (auto-pause on headphone disconnect) |
| `internal/domain/affirmation/progress.go` | 100% | Critical path: cumulative-not-streak logic; shame prevention |
| `internal/domain/affirmation/safeguards.go` | 100% | Critical path: clinical escalation triggers, crisis routing |
| `internal/domain/affirmation/privacy.go` | 100% | Critical path: notification text, sharing restrictions, local-first storage |
| `internal/handler/affirmation_handler.go` | 80% | HTTP handler tests |
| `internal/repository/affirmation_repo.go` | 75% | Covered by integration tests |
| **Overall affirmations module** | **>= 85%** | Above project 80% minimum |

---

## 1. Unit Tests (60-70% of test budget)

### 1.1 Level Engine Tests

**Location:** `internal/domain/affirmation/level_engine_test.go`

```
TestAffirmation_AFF_AC_001_LevelOneAvailableFromDayOne
  Given a new user with sobrietyDays = 1
  When the level engine computes the available level
  Then Level 1 is available and set as the active level

TestAffirmation_AFF_AC_002_LevelTwoUnlocksAtDay14
  Given a user with sobrietyDays = 14 and no relapse in the last 24 hours
  When the level engine computes available levels
  Then Level 2 is unlocked and available for selection

TestAffirmation_AFF_AC_002_LevelTwoUnlocksAtDay14_BelowThreshold
  Given a user with sobrietyDays = 13
  When the level engine computes available levels
  Then Level 2 remains locked; only Level 1 is available

TestAffirmation_AFF_AC_003_LevelThreeUnlocksAtDay60
  Given a user with sobrietyDays = 60 and consistent engagement
  When the level engine computes available levels
  Then Level 3 is unlocked (Permission + Process + Tempered Identity)

TestAffirmation_AFF_AC_003_LevelThreeUnlocksAtDay60_BelowThreshold
  Given a user with sobrietyDays = 59
  When the level engine computes available levels
  Then Level 3 remains locked; Levels 1 and 2 available

TestAffirmation_AFF_AC_004_LevelFourUnlocksAtDay180
  Given a user with sobrietyDays = 180
  When the level engine computes available levels
  Then Level 4 is unlocked (Full Identity affirmations available)

TestAffirmation_AFF_AC_004_LevelFourUnlocksAtDay180_BelowThreshold
  Given a user with sobrietyDays = 179
  When the level engine computes available levels
  Then Level 4 remains locked; Levels 1-3 available

TestAffirmation_AFF_AC_005_ManualDowngradeAlwaysAllowed
  Given a user (Diego) currently at Level 4 with sobrietyDays = 200
  When the user requests a downgrade to Level 1
  Then the level is set to Level 1 immediately with no cooldown restriction

TestAffirmation_AFF_AC_005_ManualDowngradeAlwaysAllowed_AnyLevel
  Given a user at Level 3 (table-driven: target levels 1, 2)
  When the user requests a downgrade to any lower level
  Then the downgrade succeeds immediately for each target level

TestAffirmation_AFF_AC_006_ManualUpgradeRequires30DaysAtCurrentLevel
  Given a user at Level 2 for 30 days with Level 3 unlocked (sobrietyDays >= 60)
  When the user requests a manual upgrade to Level 3
  Then the upgrade is granted

TestAffirmation_AFF_AC_006_ManualUpgradeRequires30DaysAtCurrentLevel_TooEarly
  Given a user at Level 2 for 15 days with Level 3 unlocked
  When the user requests a manual upgrade to Level 3
  Then the upgrade is denied with message indicating days remaining

TestAffirmation_AFF_AC_006_ManualUpgradeRequires30DaysAtCurrentLevel_LevelLocked
  Given a user at Level 1 for 30 days but sobrietyDays = 10 (Level 2 not yet unlocked)
  When the user requests a manual upgrade to Level 2
  Then the upgrade is denied because the target level is not yet unlocked

TestAffirmation_AFF_AC_007_PostRelapseLocksToLevelOne
  Given a user (Marcus) who reported a relapse 18 hours ago with previous Level = 2
  When the level engine computes the active level
  Then the active level is forced to Level 1 regardless of sobriety days or previous level

TestAffirmation_AFF_AC_008_PostRelapseWindowIs24Hours
  Given a user who reported a relapse exactly 24 hours and 1 minute ago
  When the level engine computes the active level
  Then the post-relapse lock is released; level returns to the level matching current sobriety days

TestAffirmation_AFF_AC_008_PostRelapseWindowIs24Hours_StillActive
  Given a user who reported a relapse 23 hours and 59 minutes ago
  When the level engine computes the active level
  Then the post-relapse lock is still active; level remains Level 1

TestAffirmation_AFF_AC_009_LevelServingRatio80_20
  Given a user at Level 2 with a pool of Level 2 and Level 3 affirmations
  When 100 affirmations are selected by the content engine (statistical test)
  Then approximately 80 are Level 2 (current) and 20 are Level 3 (one level above)
  And the ratio falls within acceptable bounds (75-85 / 15-25 with p < 0.05)

TestAffirmation_AFF_AC_009_LevelServingRatio80_20_AtMaxLevel
  Given a user at Level 4 (the highest level)
  When affirmations are selected by the content engine
  Then 100% are Level 4 (no level above exists to draw from)

TestAffirmation_AFF_AC_010_SOSNeverAboveLevelTwo
  Given a user (Diego) at Level 4 with sobrietyDays = 200
  When SOS mode is triggered and affirmations are selected
  Then all returned affirmations are Level 1 or Level 2 only; never Level 3 or 4
```

### 1.2 Content Selection Tests

**Location:** `internal/domain/affirmation/content_selection_test.go`

```
TestAffirmation_AFF_AC_011_NoRepeatWithin7DaysUnlessFavorite
  Given a user who was served affirmation "aff_042" 3 days ago and "aff_042" is NOT a favorite
  When the content selector builds the next session
  Then "aff_042" is excluded from the candidate pool

TestAffirmation_AFF_AC_011_NoRepeatWithin7DaysUnlessFavorite_FavoriteAllowed
  Given a user who was served affirmation "aff_042" 3 days ago and "aff_042" IS a favorite
  When the content selector builds the next session
  Then "aff_042" is eligible for selection

TestAffirmation_AFF_AC_011_NoRepeatWithin7DaysUnlessFavorite_After7Days
  Given a user who was served affirmation "aff_042" 8 days ago and "aff_042" is NOT a favorite
  When the content selector builds the next session
  Then "aff_042" is eligible for selection (7-day window expired)

TestAffirmation_AFF_AC_012_FavoritesGetPriority
  Given a user with 5 favorites and a pool of 200 affirmations at their level
  When the content selector builds a 3-affirmation morning session
  Then favorites are weighted higher in the selection probability than non-favorites

TestAffirmation_AFF_AC_013_HiddenNeverSurfaced
  Given a user who has hidden affirmation "aff_099"
  When the content selector builds any session (morning, evening, SOS)
  Then "aff_099" is never included in the candidate pool

TestAffirmation_AFF_AC_013_HiddenNeverSurfaced_AcrossAllModes
  Given a user who has hidden affirmations ["aff_099", "aff_150", "aff_201"]
  When sessions are built for morning, evening, and SOS modes (table-driven)
  Then none of the hidden affirmations appear in any session type

TestAffirmation_AFF_AC_014_HealthySexualityRequires60DaysAndOptIn
  Given a user (Diego) with sobrietyDays = 200 and healthySexualityEnabled = true
  When the content selector builds the candidate pool
  Then affirmations with category "healthySexuality" are included

TestAffirmation_AFF_AC_014_HealthySexualityRequires60DaysAndOptIn_NotEnoughDays
  Given a user with sobrietyDays = 45 and healthySexualityEnabled = true
  When the content selector builds the candidate pool
  Then affirmations with category "healthySexuality" are excluded

TestAffirmation_AFF_AC_015_HealthySexualityDefaultOff
  Given a new user who has not modified healthySexuality settings
  When the default user settings are loaded
  Then healthySexualityEnabled = false

TestAffirmation_AFF_AC_015_HealthySexualityDefaultOff_ExcludedFromPool
  Given a user (Alex) with sobrietyDays = 45 and healthySexualityEnabled = false (default)
  When the content selector builds the candidate pool
  Then affirmations with category "healthySexuality" are excluded regardless of sobriety days

TestAffirmation_AFF_AC_016_FaithBasedTrackFiltering
  Given a user (Marcus) with track = "faithBased"
  When the content selector builds the candidate pool
  Then only affirmations tagged with track "faithBased" or track "both" are included
  And affirmations tagged with track "standard" only are excluded

TestAffirmation_AFF_AC_016_FaithBasedTrackFiltering_StandardTrack
  Given a user (Alex) with track = "standard"
  When the content selector builds the candidate pool
  Then only affirmations tagged with track "standard" or track "both" are included
  And affirmations tagged with track "faithBased" only are excluded

TestAffirmation_AFF_AC_017_CategoryDistribution
  Given a user at Level 2 with access to categories: selfWorth, shameResilience, healthyRelationships, connectionHelp, emotionalRegulation, purposeMeaning, integrityHonesty, dailyStrength
  When 30 session selections are made over 10 days
  Then at least 5 of the 8 accessible categories appear (category variety enforced)

TestAffirmation_AFF_AC_018_CoreBeliefCoverage
  Given the full affirmation library at Level 2
  When affirmations are grouped by coreBeliefAddressed
  Then all four Carnes core beliefs are represented: "badUnworthyPerson", "noOneLoveMe", "needsNeverMet", "sexMostImportant"
```

### 1.3 Morning Session Tests

**Location:** `internal/domain/affirmation/morning_session_test.go`

```
TestAffirmation_AFF_AC_021_MorningReturnsThreeAffirmations
  Given an authenticated user (Alex) requesting a morning session
  When the morning session is generated
  Then exactly 3 affirmations are returned in sequential order

TestAffirmation_AFF_AC_022_MorningIncludesIntentionPrompt
  Given a morning session response
  When the session payload is inspected
  Then it includes an intentionPrompt field with the sentence stem "Today I choose to..."

TestAffirmation_AFF_AC_023_MorningSkipNoStreak
  Given a user who skips the morning session
  When the skip is recorded
  Then no streak counter is decremented or displayed
  And the skip is logged internally with timestamp and reason (if provided)
  And progress metrics (totalSessions, totalPracticed) remain unchanged

TestAffirmation_AFF_AC_024_MorningSessionCompletionRecorded
  Given a user completes all 3 affirmation cards and submits an intention
  When the session completion is recorded
  Then totalSessions increments by 1
  And totalPracticed increments by 3
  And a calendarActivity record is created for the current date

TestAffirmation_AFF_AC_025_IntentionStoredInJournal
  Given a user submits intention text "practice patience with my wife"
  When the morning session is completed
  Then the intention is stored in the journal system with source = "affirmationMorning"
  And the intention is retrievable for the evening reflection session
```

### 1.4 Evening Reflection Tests

**Location:** `internal/domain/affirmation/evening_session_test.go`

```
TestAffirmation_AFF_AC_036_EveningReturnsOneAffirmationPlusMorningIntention
  Given a user (Alex) who completed a morning session with intention "practice patience"
  When the evening reflection session is generated
  Then it returns exactly 1 affirmation and the morning intention text

TestAffirmation_AFF_AC_036_EveningReturnsOneAffirmationPlusMorningIntention_NoMorning
  Given a user who did NOT complete a morning session today
  When the evening reflection session is generated
  Then it returns 1 affirmation and intentionText = null (no morning intention to surface)

TestAffirmation_AFF_AC_037_EveningDayRating1to5
  Given an evening reflection submission with dayRating values 1, 2, 3, 4, 5 (table-driven)
  When the submission is validated
  Then all ratings pass validation

TestAffirmation_AFF_AC_037_EveningDayRating1to5_Invalid
  Given an evening reflection submission with dayRating values 0, 6, -1, 100 (table-driven)
  When the submission is validated
  Then all return validation error "day rating must be between 1 and 5"

TestAffirmation_AFF_AC_038_EveningDayRatingFeedsMoodChart
  Given a user submits an evening reflection with dayRating = 4
  When the submission is processed
  Then a mood data point is published with value = 4, source = "affirmationEvening", timestamp = now

TestAffirmation_AFF_AC_039_EveningReflectionOptional
  Given a user who completes only the dayRating but leaves reflectionText empty
  When the submission is processed
  Then the submission succeeds with reflectionText = null
  And the session counts as completed

TestAffirmation_AFF_AC_040_EveningCompassionateFraming
  Given an evening reflection session response
  When the prompt text is inspected
  Then it uses compassionate, non-evaluative language (e.g., "How did today feel?")
  And it does NOT contain sobriety-checking language (e.g., "Did you stay sober?")
```

### 1.5 SOS Mode Tests

**Location:** `internal/domain/affirmation/sos_test.go`

```
TestAffirmation_AFF_AC_049_SOSReturnsLevel1Or2Only
  Given a user (Diego) at Level 4 with sobrietyDays = 200
  When SOS mode is activated and affirmations are selected
  Then all returned affirmations have level <= 2
  And affirmations are from the "sosCrisis" category

TestAffirmation_AFF_AC_050_SOSIncludesBreathingExercise
  Given a user triggers SOS mode
  When the initial SOS response is generated
  Then the response includes a breathingExercise field with type = "4-7-8"
  And the breathing exercise includes inhale, hold, and exhale durations in seconds

TestAffirmation_AFF_AC_051_SOSPostCheckIn10MinDelay
  Given a user completes an SOS session at timestamp T
  When the post-SOS check-in is scheduled
  Then the check-in notification is scheduled for T + 10 minutes
  And the notification text is compassionate: "Checking in -- how are you feeling?"

TestAffirmation_AFF_AC_052_SOSPrivacyNeverAutoShared
  Given a user activates SOS mode
  When the SOS session is recorded
  Then no data is shared with accountability partners automatically
  And sharing requires explicit user confirmation after the breathing exercise

TestAffirmation_AFF_AC_053_SOSImmediateResponse
  Given a user triggers SOS mode
  When the SOS response is generated
  Then the response time is under 500ms (content from local cache)
  And at least 1 Level 1 or Level 2 affirmation is returned immediately

TestAffirmation_AFF_AC_054_SOSAfterBreathingTwoMoreAffirmations
  Given a user has completed the breathing exercise portion of SOS mode
  When the post-breathing continuation is requested
  Then exactly 2 additional affirmations are returned (Level 1 or 2 only)

TestAffirmation_AFF_AC_055_SOSReachOutButtonPresent
  Given a user is in the post-breathing phase of SOS mode
  When the continuation response is inspected
  Then it includes a reachOutAction with type = "accountabilityPartner"
  And the action label is "Reach out to your accountability partner"
```

### 1.6 Custom Affirmation Tests

**Location:** `internal/domain/affirmation/custom_test.go`

```
TestAffirmation_AFF_AC_066_CustomRequiresDay14
  Given a user with sobrietyDays = 14
  When the user attempts to create a custom affirmation
  Then the creation is allowed

TestAffirmation_AFF_AC_066_CustomRequiresDay14_TooEarly
  Given a user (Marcus) with sobrietyDays = 7
  When the user attempts to create a custom affirmation
  Then the creation is denied with message "Custom affirmations available after 14 days of recovery"

TestAffirmation_AFF_AC_067_CustomPresentTenseValidation
  Given a custom affirmation text "I am worthy of trust" (present tense)
  When the text is validated
  Then validation passes

TestAffirmation_AFF_AC_067_CustomPresentTenseValidation_FutureTense
  Given a custom affirmation text "I will be worthy of trust" (future tense)
  When the text is validated
  Then a guidance suggestion is returned: "Try rephrasing in the present tense -- 'I am' instead of 'I will be'"

TestAffirmation_AFF_AC_068_CustomPositiveFramingGuidance
  Given a custom affirmation text "I am free from shame" (positive framing, acceptable)
  When the text is validated
  Then validation passes

TestAffirmation_AFF_AC_068_CustomPositiveFramingGuidance_Negation
  Given a custom affirmation text "I am not addicted" (negation framing)
  When the text is validated
  Then a guidance suggestion is returned recommending positive reframing

TestAffirmation_AFF_AC_069_CustomNotReviewedDisclosure
  Given a custom affirmation creation flow
  When the creation screen is loaded
  Then a disclosure message is present: "Your own words carry extra power. Make sure this feels true to you -- even partially -- right now."

TestAffirmation_AFF_AC_070_CustomIncludeInRotationToggle
  Given a user creates a custom affirmation with includeInRotation = true
  When the custom affirmation is saved
  Then it appears in the daily session candidate pool alongside curated affirmations

TestAffirmation_AFF_AC_070_CustomIncludeInRotationToggle_ExcludeFromRotation
  Given a user creates a custom affirmation with includeInRotation = false
  When the content selector builds a morning session
  Then the custom affirmation does not appear in the candidate pool
  And it remains accessible in the user's custom affirmation library

TestAffirmation_AFF_AC_071_CustomMaxLength
  Given a custom affirmation text of exactly 500 characters
  When the text is validated
  Then validation passes

TestAffirmation_AFF_AC_071_CustomMaxLength_Exceeds
  Given a custom affirmation text of 501 characters
  When the text is validated
  Then validation fails with error "custom affirmation exceeds 500 character maximum"

TestAffirmation_AFF_AC_072_CustomNoNegation
  Given a custom affirmation text "I am not broken" (contains negation "not")
  When the text is validated
  Then a guidance suggestion is returned: "Try reframing without negation -- for example, 'I am whole' instead of 'I am not broken'"

TestAffirmation_AFF_AC_072_CustomNoNegation_AcceptableNegation
  Given a custom affirmation text "I am free from the chains of my past" (no direct negation)
  When the text is validated
  Then validation passes (no negation detected)
```

### 1.7 Audio Recording Tests

**Location:** `internal/domain/affirmation/audio_test.go`

```
TestAffirmation_AFF_AC_079_AudioMaxDuration60Seconds
  Given an audio recording with duration = 60 seconds
  When the recording metadata is validated
  Then validation passes

TestAffirmation_AFF_AC_079_AudioMaxDuration60Seconds_Exceeds
  Given an audio recording with duration = 61 seconds
  When the recording metadata is validated
  Then validation fails with error "recording exceeds 60-second maximum"

TestAffirmation_AFF_AC_080_AudioFormatM4A
  Given an audio recording with format = "m4a" and encoding = "aac" and bitrate >= 64000
  When the recording metadata is validated
  Then validation passes

TestAffirmation_AFF_AC_080_AudioFormatM4A_InvalidFormat
  Given an audio recording with format = "mp3"
  When the recording metadata is validated
  Then validation fails with error "audio must be in .m4a format (AAC encoding)"

TestAffirmation_AFF_AC_081_AudioBackgroundMusic5Options
  Given the available background music options
  When the options are enumerated
  Then exactly 5 preset options are returned (nature sounds, soft tones, etc.)

TestAffirmation_AFF_AC_081_AudioBackgroundMusic5Options_InvalidOption
  Given a recording request with backgroundMusic = "heavy_metal"
  When the metadata is validated
  Then validation fails with error "invalid background music option"

TestAffirmation_AFF_AC_082_AudioBackgroundVolumeDefault60Percent
  Given a new audio recording with no backgroundVolume specified
  When the recording defaults are applied
  Then backgroundVolume = 0.60 (60% relative to voice)

TestAffirmation_AFF_AC_082_AudioBackgroundVolumeDefault60Percent_CustomVolume
  Given a recording request with backgroundVolume = 0.30
  When the metadata is validated
  Then backgroundVolume = 0.30 (user-adjusted value preserved)

TestAffirmation_AFF_AC_083_AudioLocalStorageDefault
  Given a new audio recording saved by the user
  When the storage location is determined
  Then storageLocation = "local" (on-device only)
  And cloudSyncEnabled = false by default
```

### 1.8 Progress Tests (CRITICAL: cumulative, not streak)

**Location:** `internal/domain/affirmation/progress_test.go`

```
TestAffirmation_AFF_AC_096_ProgressIsCumulativeNotStreak
  Given a user who completed sessions on days 1, 2, 3, then missed days 4-6, then completed day 7
  When progress metrics are computed
  Then totalSessions = 4 (cumulative count)
  And no "streak broken" event is emitted
  And no consecutive-day counter is exposed in the response

TestAffirmation_AFF_AC_097_TotalSessionsIncrements
  Given a user (Alex) with totalSessions = 32
  When the user completes a morning session
  Then totalSessions = 33

TestAffirmation_AFF_AC_097_TotalSessionsIncrements_Evening
  Given a user with totalSessions = 33
  When the user completes an evening session
  Then totalSessions = 34 (each session type counts independently)

TestAffirmation_AFF_AC_098_TotalPracticedIncrements
  Given a user with totalPracticed = 96 (32 sessions x 3 affirmations average)
  When the user completes a morning session with 3 affirmations
  Then totalPracticed = 99

TestAffirmation_AFF_AC_098_TotalPracticedIncrements_SOSSession
  Given a user with totalPracticed = 99
  When the user completes an SOS session (1 initial + 2 post-breathing = 3 affirmations)
  Then totalPracticed = 102

TestAffirmation_AFF_AC_099_ConsistencyHeatMap30Days
  Given a user with sessions on 20 of the last 30 days
  When the consistency heat map data is requested for the last 30 days
  Then 20 dates have non-zero session counts
  And 10 dates have zero session counts
  And no empty-day callouts or shame language is included in the response

TestAffirmation_AFF_AC_100_MilestoneFirstSession
  Given a user (Marcus) completing their very first affirmation session
  When the session is recorded and milestones are checked
  Then milestone "firstSession" is triggered with message using growth-mindset framing

TestAffirmation_AFF_AC_101_Milestone10thSession
  Given a user with totalSessions = 9
  When the user completes session number 10
  Then milestone "10thSession" is triggered

TestAffirmation_AFF_AC_101_Milestone10thSession_NotTriggeredAt9
  Given a user with totalSessions = 8
  When the user completes session number 9
  Then no milestone is triggered

TestAffirmation_AFF_AC_102_MilestoneFirstCustom
  Given a user who creates their first custom affirmation
  When the custom affirmation is saved
  Then milestone "firstCustom" is triggered

TestAffirmation_AFF_AC_103_MilestoneFirstAudio
  Given a user who saves their first audio recording
  When the recording metadata is persisted
  Then milestone "firstAudio" is triggered

TestAffirmation_AFF_AC_104_MilestoneFirstSOS
  Given a user completing their first SOS affirmation session
  When the SOS session is recorded
  Then milestone "firstSOS" is triggered with message "Coming back in a hard moment is courage."

TestAffirmation_AFF_AC_105_ReEngagement3DayGap
  Given a user whose last session was 3 days ago
  When the re-engagement check runs
  Then a gentle prompt is generated: "Ready when you are. Here is one affirmation for right now."
  And the prompt offers a single affirmation card (not a full session)

TestAffirmation_AFF_AC_106_ReEngagement7DayGap
  Given a user whose last session was 7 days ago
  When the re-engagement check runs
  Then a message is generated: "Coming back is an act of courage. No catching up needed."
  And an option to restart with a fresh Level 1 session is offered

TestAffirmation_AFF_AC_107_ReEngagement14DayGap
  Given a user whose last session was 14 days ago
  When the re-engagement check runs
  Then an optional prompt to reconnect with accountability partner or therapist is generated
  And no shame-based language is included

TestAffirmation_AFF_AC_108_NeverShameBasedGapNotification
  Given any re-engagement prompt for gaps of 3, 7, and 14 days (table-driven)
  When the notification text is inspected
  Then it does NOT contain: "missed", "broke", "failed", "disappointed", "streak"
  And it does NOT reference the number of days missed
```

### 1.9 Clinical Safeguard Tests (100% coverage required)

**Location:** `internal/domain/affirmation/safeguards_test.go`

```
TestAffirmation_AFF_AC_116_WorseningMood3Sessions
  Given a user (Marcus) with evening dayRatings of [2, 2, 1] over the last 3 consecutive sessions
  When the clinical safeguard check runs after the 3rd declining session
  Then a therapist/sponsor connection prompt is surfaced
  And the prompt is non-intrusive and dismissable

TestAffirmation_AFF_AC_116_WorseningMood3Sessions_NotTriggeredAt2
  Given a user with evening dayRatings of [2, 1] over the last 2 sessions
  When the clinical safeguard check runs
  Then no therapist prompt is surfaced (threshold not met)

TestAffirmation_AFF_AC_117_PostRelapseLevel1Only
  Given a user (Marcus) who reported a relapse 18 hours ago
  When any affirmation session (morning, evening, SOS) is generated
  Then all affirmations served are Level 1 only
  And no Level 2, 3, or 4 affirmations appear in the session

TestAffirmation_AFF_AC_118_PostRelapseCompassionateMessage
  Given a user in the post-relapse 24-hour window
  When the session response is generated
  Then a compassionate grounding message is appended
  And the message does NOT contain failure/shame language
  And the message acknowledges the user's presence ("You are here. That matters.")

TestAffirmation_AFF_AC_119_CrisisLanguageBypassAffirmations
  Given a mood check-in containing crisis-level indicators (dayRating = 1 on two consecutive evenings)
  When the session flow evaluates the check-in
  Then the affirmation session is bypassed entirely
  And the user is routed directly to crisis resources

TestAffirmation_AFF_AC_120_PersistentRejection5Hides
  Given a user who hides 5 affirmations within a single session
  When the 5th hide action is recorded
  Then a clinical flag is set for self-review
  And an optional prompt is offered: "Would you like to connect with a therapist about what you're experiencing?"

TestAffirmation_AFF_AC_120_PersistentRejection5Hides_NotTriggeredAt4
  Given a user who hides 4 affirmations in a single session
  When the 4th hide action is recorded
  Then no clinical flag is set (threshold is 5)

TestAffirmation_AFF_AC_121_CrisisRoutingResources
  Given a crisis routing trigger (from AFF_AC_119 or mood-based detection)
  When crisis resources are presented
  Then the response includes: Crisis Text Line (text HOME to 741741), SAMHSA Helpline (1-800-662-4357)
  And an option to contact the user's designated therapist or sponsor directly

TestAffirmation_AFF_AC_122_HiddenAffirmationInsightAt3
  Given a user who has hidden a cumulative total of 3 affirmations
  When the hidden count threshold check runs
  Then a non-intrusive insight prompt is offered: "Sometimes the affirmations that feel most wrong point to where healing is needed."
  And the prompt is dismissible
  And the prompt appears at most once per week
```

### 1.10 Privacy Tests (100% coverage required)

**Location:** `internal/domain/affirmation/privacy_test.go`

```
TestAffirmation_AFF_AC_131_GenericNotificationTextOnly
  Given a morning session notification to be sent
  When the notification payload is constructed
  Then the title is generic (e.g., "Your daily moment is ready.")
  And the body does NOT contain: "affirmation", "recovery", "sobriety", "addiction"

TestAffirmation_AFF_AC_131_GenericNotificationTextOnly_Evening
  Given an evening reflection notification to be sent
  When the notification payload is constructed
  Then the title is generic (e.g., "A moment to close your day.")
  And the body does NOT contain recovery-specific language

TestAffirmation_AFF_AC_131_GenericNotificationTextOnly_ReEngagement
  Given a re-engagement notification for a 3-day gap
  When the notification payload is constructed
  Then the title is generic (e.g., "Ready when you are.")
  And the body does NOT contain recovery-specific language

TestAffirmation_AFF_AC_132_AudioAutoPauseHeadphoneDisconnect
  Given audio playback is active (own-voice recording or ambient background)
  When a headphone disconnect event (Bluetooth or wired) is detected
  Then audio playback pauses immediately (within 100ms)
  And playback does NOT auto-resume when headphones reconnect

TestAffirmation_AFF_AC_133_NeverShareContentToPartners
  Given a user with an accountability partner relationship
  When the partner requests the user's affirmation data
  Then no affirmation text content is included in the response
  And no custom affirmation text is included
  And no journal/intention text is included

TestAffirmation_AFF_AC_134_SharingSessionCountOnly
  Given a user with accountability partner data sharing enabled
  When the partner views the user's affirmation summary
  Then only the following are visible: sessionsCompletedThisWeek (count only)
  And the following are NOT visible: affirmation text, mood ratings, level, hidden count, custom affirmations

TestAffirmation_AFF_AC_134_SharingSessionCountOnly_TherapistView
  Given a user with therapist data sharing consent
  When the therapist views the user's affirmation dashboard
  Then the following are visible: practice consistency, hidden affirmation count, mood trend, level progression
  And actual affirmation text content is still NOT visible

TestAffirmation_AFF_AC_135_LocalFirstStorage
  Given a user's affirmation-related data (recordings, journal entries, mood ratings)
  When the storage location defaults are applied
  Then all sensitive data is stored on-device by default
  And cloud sync is disabled until explicit user opt-in
```

### 1.11 Feature Flag Tests

**Location:** `internal/domain/affirmation/feature_flag_test.go`

```
TestAffirmation_AFF_NFR_001_FeatureFlagDisabledReturns404
  Given the feature flag "activity.affirmations" is disabled
  When any affirmation endpoint is called (POST /activities/affirmations/sessions/morning, etc.)
  Then the response is 404 with error indicating feature not found

TestAffirmation_AFF_NFR_002_FeatureFlagFailClosed
  Given the feature flag service is unreachable or returns an error
  When any affirmation endpoint is called
  Then the affirmation feature is treated as disabled (fail closed)
  And the response is 404

TestAffirmation_AFF_NFR_003_ImmutableTimestamps
  Given an existing affirmation session record with createdAt = "2026-04-08T07:00:00Z"
  When an update request includes a different createdAt value
  Then createdAt remains "2026-04-08T07:00:00Z" (immutable)
  And only modifiedAt is updated to the current timestamp

TestAffirmation_AFF_NFR_004_CalendarDualWrite
  Given a user completes an affirmation session (morning or evening)
  When the session is persisted
  Then a calendarActivity document is also written with activityType = "AFFIRMATION"
  And the calendarActivity date matches the session date in the user's timezone
```

---

## 2. Integration Tests (20-30% of test budget)

### 2.1 Repository CRUD Tests

**Location:** `test/integration/affirmation/repository_test.go`

```
TestAffirmation_Repository_CreateAndRetrieveSession
  Given MongoDB container running
  When a morning session record is inserted
  Then findOne by userId and sessionId returns the exact record

TestAffirmation_Repository_ListSessionsReverseChronological
  Given 10 session records across different dates for user Alex
  When find() with sort by createdAt descending
  Then sessions are returned in reverse chronological order

TestAffirmation_Repository_UserSettingsPersistence
  Given a user updates their settings (track = "faithBased", healthySexualityEnabled = true)
  When settings are retrieved
  Then all updated values are persisted correctly

TestAffirmation_Repository_FavoriteToggle
  Given an affirmation "aff_042" that is not a favorite
  When toggleFavorite("aff_042", true) is called
  Then "aff_042" appears in the user's favorites list
  And toggling again removes it from favorites

TestAffirmation_Repository_HideAffirmation
  Given a user hides affirmation "aff_099"
  When the hidden list is queried
  Then "aff_099" is in the hidden set
  And subsequent content selection queries exclude "aff_099"

TestAffirmation_Repository_CustomAffirmationCRUD
  Given a user creates a custom affirmation with text "I choose honesty today"
  When the custom affirmation is retrieved, updated, and deleted in sequence
  Then each operation succeeds and returns correct data
```

### 2.2 Level Engine with Real MongoDB Data

**Location:** `test/integration/affirmation/level_engine_test.go`

```
TestAffirmation_Integration_LevelEngineWithSobrietyData
  Given Alex's sobriety record (45 days) in MongoDB
  When the level engine computes available levels from the real sobriety counter
  Then Level 2 is the active level and Levels 1-2 are available

TestAffirmation_Integration_LevelEnginePostRelapse
  Given Marcus's relapse record (18 hours ago) in MongoDB
  When the level engine queries the relapse timestamp and computes the active level
  Then Level 1 is forced as the active level

TestAffirmation_Integration_LevelChangeLogged
  Given Alex manually requests a downgrade from Level 2 to Level 1
  When the level change is persisted
  Then a levelChange audit record is stored with previousLevel=2, newLevel=1, reason="manual", timestamp
```

### 2.3 Session Completion with Calendar Dual-Write

**Location:** `test/integration/affirmation/session_completion_test.go`

```
TestAffirmation_Integration_MorningSessionDualWrite
  Given a user completes a morning session
  When the session is persisted
  Then both the affirmationSession document and the calendarActivity document exist in MongoDB
  And both share the same date and userId

TestAffirmation_Integration_EveningSessionMoodDualWrite
  Given a user completes an evening session with dayRating = 4
  When the session is persisted
  Then the affirmationSession document contains dayRating = 4
  And a mood tracking data point is published with value = 4 and source = "affirmationEvening"

TestAffirmation_Integration_SOSSessionRecording
  Given a user completes an SOS session
  When the session is persisted
  Then the affirmationSession document has sessionType = "sos"
  And a calendarActivity is created with activityType = "AFFIRMATION" and subType = "sos"
```

### 2.4 Audio Metadata CRUD

**Location:** `test/integration/affirmation/audio_test.go`

```
TestAffirmation_Integration_AudioMetadataCreateAndRetrieve
  Given a user saves an audio recording for affirmation "aff_042"
  When the audio metadata is inserted and then retrieved
  Then the metadata includes: affirmationId, duration, format, backgroundMusic, backgroundVolume, localFilePath

TestAffirmation_Integration_AudioMetadataListByUser
  Given Diego has 5 audio recordings stored
  When audio metadata is queried by userId
  Then all 5 records are returned with correct affirmation IDs
```

### 2.5 Settings Persistence

**Location:** `test/integration/affirmation/settings_test.go`

```
TestAffirmation_Integration_DefaultSettingsCreation
  Given a new user with no existing affirmation settings
  When settings are loaded with defaults
  Then track = "standard", healthySexualityEnabled = false, morningTime = default, eveningTime = "21:00", cloudSync = false

TestAffirmation_Integration_SettingsUpdate
  Given an existing user updates morningTime to "06:30" and track to "faithBased"
  When settings are retrieved after update
  Then morningTime = "06:30" and track = "faithBased"
```

### 2.6 Progress Tracking Across Sessions

**Location:** `test/integration/affirmation/progress_test.go`

```
TestAffirmation_Integration_CumulativeProgressAcrossSessions
  Given a user completes 3 morning sessions (3 affirmations each) and 2 evening sessions (1 each)
  When progress metrics are computed from the database
  Then totalSessions = 5 and totalPracticed = 11

TestAffirmation_Integration_MilestoneTriggering
  Given a user with totalSessions = 9 in the database
  When the user completes session 10
  Then the "10thSession" milestone is recorded in the milestones collection

TestAffirmation_Integration_HeatMapDataAggregation
  Given session records spanning 30 days with gaps
  When the heat map data is aggregated
  Then each date returns the correct session count and days with zero sessions return 0 (not null)
```

### 2.7 Cache Tests

**Location:** `test/integration/affirmation/cache_test.go`

```
TestAffirmation_Cache_ProgressCachedInValkey
  Given progress metrics computed and cached
  When GetProgress called within TTL
  Then returns cached value without hitting MongoDB

TestAffirmation_Cache_ProgressInvalidatedOnSessionComplete
  Given progress metrics cached in Valkey
  When a new session is completed
  Then cache key is invalidated; next GetProgress reads from MongoDB

TestAffirmation_Cache_SOSPoolCachedLocally
  Given the SOS affirmation pool is loaded
  When SOS mode is activated offline
  Then SOS affirmations are served from local cache without network access
```

---

## 3. E2E Tests (5-10% of test budget)

### 3.1 Full Morning Session Flow

**Location:** `test/e2e/affirmation/flow_test.go`

```
TestAffirmation_E2E_FullMorningSessionFlow_Alex
  Given authenticated user (persona: Alex, 45 days sober, Level 2, standard track)
  Steps:
    1. GET /activities/affirmations/sessions/morning -- request morning session
    2. Verify response contains exactly 3 affirmations, all Level 1 or 2
    3. Verify intentionPrompt field is present with sentence stem
    4. POST /activities/affirmations/sessions/morning/complete -- submit with intention text
    5. Verify totalSessions incremented by 1
    6. Verify totalPracticed incremented by 3
    7. GET /activities/affirmations/progress -- verify cumulative metrics updated
    8. GET /calendar/activities?date=today -- verify calendarActivity exists with type AFFIRMATION
    9. Verify intention text is retrievable for evening session
```

### 3.2 Full Evening Reflection Flow

**Location:** `test/e2e/affirmation/flow_test.go`

```
TestAffirmation_E2E_FullEveningReflectionFlow
  Given authenticated user (Alex) who completed a morning session today
  Steps:
    1. GET /activities/affirmations/sessions/evening -- request evening session
    2. Verify response contains 1 affirmation and the morning intention text
    3. POST /activities/affirmations/sessions/evening/complete -- submit dayRating=4 and optional reflection
    4. Verify totalSessions incremented
    5. GET /mood/data-points?source=affirmationEvening -- verify mood data point created with value 4
    6. GET /activities/affirmations/progress -- verify heat map includes today
```

### 3.3 SOS Mode Flow

**Location:** `test/e2e/affirmation/sos_flow_test.go`

```
TestAffirmation_E2E_SOSModeFlow
  Given authenticated user (Alex) in an active urge moment
  Steps:
    1. POST /activities/affirmations/sessions/sos -- trigger SOS mode
    2. Verify response time < 500ms
    3. Verify response contains 1 affirmation (Level 1 or 2 only) and breathingExercise (type 4-7-8)
    4. POST /activities/affirmations/sessions/sos/breathing-complete -- after breathing
    5. Verify response contains 2 additional affirmations (Level 1 or 2) and reachOutAction
    6. POST /activities/affirmations/sessions/sos/complete -- complete SOS session
    7. Verify totalSessions incremented
    8. Verify no data shared to accountability partners
    9. Verify post-SOS check-in notification scheduled for 10 minutes later
```

### 3.4 Custom Affirmation Creation Flow

**Location:** `test/e2e/affirmation/custom_flow_test.go`

```
TestAffirmation_E2E_CustomAffirmationCreation_Diego
  Given authenticated user (persona: Diego, 200 days sober, Level 4)
  Steps:
    1. POST /activities/affirmations/custom -- create with text "I choose integrity in all my relationships"
    2. Verify response includes customAffirmationId, includeInRotation, and disclosure text
    3. GET /activities/affirmations/custom -- verify custom affirmation appears in user's library
    4. PATCH /activities/affirmations/custom/{id} -- set includeInRotation = true
    5. GET /activities/affirmations/sessions/morning -- verify custom affirmation is eligible in session pool
    6. Verify milestone "firstCustom" triggered if this is Diego's first custom
```

### 3.5 Re-Engagement After Gap

**Location:** `test/e2e/affirmation/reengagement_flow_test.go`

```
TestAffirmation_E2E_ReEngagementAfterGap
  Given authenticated user whose last session was 7 days ago
  Steps:
    1. GET /activities/affirmations/re-engagement -- check re-engagement status
    2. Verify response includes compassionate message and option for fresh Level 1 session
    3. Verify message does NOT contain shame language ("missed", "broke", "streak")
    4. POST /activities/affirmations/sessions/morning -- resume practice
    5. Verify session generates normally with cumulative progress preserved
    6. GET /activities/affirmations/progress -- verify totalSessions continues from previous count
```

---

## 4. Contract Tests (validates against OpenAPI spec)

### 4.1 Request/Response Schema Validation

**Location:** `test/contract/affirmation_test.go`

All 27 affirmation endpoints validated against the OpenAPI specification.

```
TestAffirmation_Contract_MorningSession_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/sessions/morning
  Then response body validates against MorningSessionResponse schema in openapi.yaml

TestAffirmation_Contract_MorningSessionComplete_201_MatchesSpec
  Given a valid morning session completion request
  When POST /activities/affirmations/sessions/morning/complete
  Then response body validates against SessionCompletionResponse schema

TestAffirmation_Contract_EveningSession_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/sessions/evening
  Then response body validates against EveningSessionResponse schema

TestAffirmation_Contract_EveningSessionComplete_201_MatchesSpec
  Given a valid evening session completion request with dayRating
  When POST /activities/affirmations/sessions/evening/complete
  Then response body validates against SessionCompletionResponse schema

TestAffirmation_Contract_SOSSession_200_MatchesSpec
  Given an authenticated user triggering SOS
  When POST /activities/affirmations/sessions/sos
  Then response body validates against SOSSessionResponse schema

TestAffirmation_Contract_SOSBreathingComplete_200_MatchesSpec
  Given a valid post-breathing continuation request
  When POST /activities/affirmations/sessions/sos/breathing-complete
  Then response body validates against SOSContinuationResponse schema

TestAffirmation_Contract_SOSComplete_201_MatchesSpec
  Given a valid SOS session completion request
  When POST /activities/affirmations/sessions/sos/complete
  Then response body validates against SessionCompletionResponse schema

TestAffirmation_Contract_ListAffirmations_200_MatchesSpec
  Given valid query parameters (level, category, track)
  When GET /activities/affirmations?level=2&category=selfWorth
  Then response body validates against AffirmationListResponse schema

TestAffirmation_Contract_GetAffirmation_200_MatchesSpec
  Given a valid affirmationId
  When GET /activities/affirmations/{affirmationId}
  Then response validates against AffirmationResponse schema

TestAffirmation_Contract_ToggleFavorite_200_MatchesSpec
  Given a valid affirmationId
  When PATCH /activities/affirmations/{affirmationId}/favorite
  Then response validates against FavoriteToggleResponse schema

TestAffirmation_Contract_HideAffirmation_200_MatchesSpec
  Given a valid affirmationId
  When POST /activities/affirmations/{affirmationId}/hide
  Then response validates against HideAffirmationResponse schema

TestAffirmation_Contract_ListFavorites_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/favorites
  Then response validates against AffirmationListResponse schema

TestAffirmation_Contract_CreateCustom_201_MatchesSpec
  Given a valid custom affirmation request body
  When POST /activities/affirmations/custom
  Then response validates against CustomAffirmationResponse schema

TestAffirmation_Contract_ListCustom_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/custom
  Then response validates against CustomAffirmationListResponse schema

TestAffirmation_Contract_UpdateCustom_200_MatchesSpec
  Given a valid custom affirmation update request
  When PATCH /activities/affirmations/custom/{customId}
  Then response validates against CustomAffirmationResponse schema

TestAffirmation_Contract_DeleteCustom_204_MatchesSpec
  Given a valid customId
  When DELETE /activities/affirmations/custom/{customId}
  Then response is 204 with no body

TestAffirmation_Contract_CreateAudioRecording_201_MatchesSpec
  Given a valid audio metadata request
  When POST /activities/affirmations/{affirmationId}/audio
  Then response validates against AudioRecordingResponse schema

TestAffirmation_Contract_ListAudioRecordings_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/audio
  Then response validates against AudioRecordingListResponse schema

TestAffirmation_Contract_DeleteAudioRecording_204_MatchesSpec
  Given a valid audioId
  When DELETE /activities/affirmations/audio/{audioId}
  Then response is 204 with no body

TestAffirmation_Contract_GetProgress_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/progress
  Then response validates against AffirmationProgressResponse schema

TestAffirmation_Contract_GetHeatMap_200_MatchesSpec
  Given valid date range parameters
  When GET /activities/affirmations/progress/heatmap?days=30
  Then response validates against HeatMapResponse schema

TestAffirmation_Contract_GetMilestones_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/milestones
  Then response validates against MilestonesResponse schema

TestAffirmation_Contract_GetSettings_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/settings
  Then response validates against AffirmationSettingsResponse schema

TestAffirmation_Contract_UpdateSettings_200_MatchesSpec
  Given a valid settings update request
  When PATCH /activities/affirmations/settings
  Then response validates against AffirmationSettingsResponse schema

TestAffirmation_Contract_GetReEngagement_200_MatchesSpec
  Given an authenticated user with a session gap
  When GET /activities/affirmations/re-engagement
  Then response validates against ReEngagementResponse schema

TestAffirmation_Contract_GetLevel_200_MatchesSpec
  Given an authenticated user
  When GET /activities/affirmations/level
  Then response validates against LevelResponse schema

TestAffirmation_Contract_UpdateLevel_200_MatchesSpec
  Given a valid level change request
  When PATCH /activities/affirmations/level
  Then response validates against LevelResponse schema
```

### 4.2 Error Format Validation

```
TestAffirmation_Contract_ErrorFormat_401_Unauthenticated
  Given a request without Authorization header
  When any affirmation endpoint is called
  Then response is 401 with body matching ErrorResponse schema: { "errors": [{ "code": "rr:0x...", "status": 401, "title": "...", "detail": "..." }] }

TestAffirmation_Contract_ErrorFormat_422_ValidationFailure
  Given an invalid request body (e.g., dayRating = 7)
  When POST /activities/affirmations/sessions/evening/complete
  Then response is 422 with body matching ErrorResponse schema

TestAffirmation_Contract_ErrorFormat_404_FeatureDisabled
  Given feature flag "activity.affirmations" disabled
  When any affirmation endpoint is called
  Then response is 404 with body matching ErrorResponse schema

TestAffirmation_Contract_ResponseEnvelope
  Given any successful affirmation response
  When the response body is inspected
  Then it follows the envelope format: { "data": ..., "links": {...}, "meta": {...} }
```

---

## 5. Mobile Client Tests

### 5.1 iOS Swift Tests

**Location:** `ios/RegalRecovery/Tests/Affirmations/`

```
TestAffirmation_iOS_CodableRoundtrip_MorningSession
  Given a MorningSessionResponse JSON payload from the API
  When decoded to MorningSessionResponse struct and re-encoded
  Then the output JSON matches the input (lossless roundtrip)

TestAffirmation_iOS_CodableRoundtrip_EveningSession
  Given an EveningSessionResponse JSON payload
  When decoded to EveningSessionResponse struct and re-encoded
  Then the output JSON matches the input

TestAffirmation_iOS_CodableRoundtrip_SOSSession
  Given an SOSSessionResponse JSON payload
  When decoded to SOSSessionResponse struct and re-encoded
  Then the output JSON matches the input

TestAffirmation_iOS_CodableRoundtrip_CustomAffirmation
  Given a CustomAffirmationResponse JSON payload
  When decoded to CustomAffirmation struct and re-encoded
  Then the output JSON matches the input

TestAffirmation_iOS_CodableRoundtrip_Progress
  Given an AffirmationProgressResponse JSON payload
  When decoded to AffirmationProgress struct and re-encoded
  Then the output JSON matches the input

TestAffirmation_iOS_ViewModel_MorningSessionStates
  Given a MorningSessionViewModel
  When the session loads, progresses through 3 cards, and completes
  Then states transition: loading -> card1 -> card2 -> card3 -> intention -> completed

TestAffirmation_iOS_ViewModel_EveningSessionStates
  Given an EveningSessionViewModel
  When the session loads, displays affirmation + intention, and user submits rating
  Then states transition: loading -> reflection -> rating -> completed

TestAffirmation_iOS_ViewModel_SOSSessionStates
  Given an SOSSessionViewModel
  When SOS triggers, breathing completes, and additional affirmations display
  Then states transition: loading -> breathing -> postBreathing -> completed

TestAffirmation_iOS_ViewModel_SkipMorningSessionNoSideEffects
  Given a MorningSessionViewModel displaying card 1
  When the user taps skip
  Then no session completion event is emitted and progress metrics are unchanged

TestAffirmation_iOS_AudioSession_HeadphoneDisconnectPause
  Given audio playback of an own-voice recording via AVAudioSession
  When an AVAudioSession.routeChangeNotification fires with reason = .oldDeviceUnavailable
  Then the audio player pauses immediately
  And playback does not auto-resume

TestAffirmation_iOS_AudioSession_RecordingFlow
  Given the user selects an affirmation and chooses a background music option
  When the user taps record, speaks, and taps stop
  Then an .m4a file is saved locally with correct metadata (duration, format, backgroundMusic)

TestAffirmation_iOS_OfflineCache_SOSAvailable
  Given the device has no network connectivity
  When SOS mode is triggered
  Then affirmations are served from the local SwiftData cache
  And the breathing exercise displays without network dependency
```

### 5.2 Android Kotlin Tests

**Location:** `android/app/src/test/java/com/regalrecovery/affirmations/`

```
TestAffirmation_Android_DataClassSerialization_MorningSession
  Given a MorningSessionResponse JSON string
  When deserialized to MorningSessionResponse data class via kotlinx.serialization
  Then all fields are correctly mapped and re-serialization matches the input

TestAffirmation_Android_DataClassSerialization_EveningSession
  Given an EveningSessionResponse JSON string
  When deserialized to EveningSessionResponse data class
  Then all fields are correctly mapped

TestAffirmation_Android_DataClassSerialization_SOSSession
  Given an SOSSessionResponse JSON string
  When deserialized to SOSSessionResponse data class
  Then all fields are correctly mapped

TestAffirmation_Android_DataClassSerialization_CustomAffirmation
  Given a CustomAffirmationResponse JSON string
  When deserialized to CustomAffirmation data class
  Then all fields are correctly mapped

TestAffirmation_Android_DataClassSerialization_Progress
  Given an AffirmationProgressResponse JSON string
  When deserialized to AffirmationProgress data class
  Then all fields are correctly mapped including heatMap dates and milestone list

TestAffirmation_Android_ViewModel_MorningSessionStates
  Given a MorningSessionViewModel
  When the session loads, progresses through 3 cards, and completes
  Then StateFlow emits: Loading -> Card(1) -> Card(2) -> Card(3) -> Intention -> Completed

TestAffirmation_Android_ViewModel_EveningSessionStates
  Given an EveningSessionViewModel
  When the session loads, displays reflection, and user submits rating
  Then StateFlow emits: Loading -> Reflection -> Rating -> Completed

TestAffirmation_Android_ViewModel_SOSSessionStates
  Given an SOSSessionViewModel
  When SOS triggers and flows through breathing to completion
  Then StateFlow emits: Loading -> Breathing -> PostBreathing -> Completed

TestAffirmation_Android_AudioFocus_HeadphoneDisconnectPause
  Given audio playback active via AudioManager
  When AudioManager.OnAudioFocusChangeListener receives AUDIOFOCUS_LOSS
  Then the media player pauses immediately
  And playback does not auto-resume

TestAffirmation_Android_OfflineCache_SOSAvailable
  Given the device has no network connectivity
  When SOS mode is triggered
  Then affirmations are served from the local Room database cache
```

---

## 6. Test Data Fixtures

### Persona: Alex (mid-early recovery)

```go
var AlexAffirmationFixtures = struct {
    UserID        string
    SobrietyDays  int
    Level         int
    Track         string
    TotalSessions int
    TotalPracticed int
    Favorites     []string
    Hidden        []string
    CustomCount   int
    AudioCount    int
    MoodAvg       float64
}{
    UserID:        "u_alex_001",
    SobrietyDays:  45,
    Level:         2,
    Track:         "standard",
    TotalSessions: 32,
    TotalPracticed: 96,
    Favorites:     []string{"aff_012", "aff_034", "aff_056", "aff_078", "aff_091", "aff_103", "aff_115", "aff_127", "aff_139", "aff_151", "aff_163", "aff_175"},
    Hidden:        []string{"aff_099", "aff_150", "aff_201"},
    CustomCount:   0,
    AudioCount:    0,
    MoodAvg:       3.2,
}
```

### Persona: Marcus (early recovery, post-relapse)

```go
var MarcusAffirmationFixtures = struct {
    UserID           string
    SobrietyDays     int
    Level            int
    Track            string
    TotalSessions    int
    TotalPracticed   int
    RelapseTimestamp  time.Time
    PostRelapseActive bool
    RecentMoodRatings []int
}{
    UserID:           "u_marcus_001",
    SobrietyDays:     7,
    Level:            1,
    Track:            "faithBased",
    TotalSessions:    4,
    TotalPracticed:   12,
    RelapseTimestamp:  time.Now().Add(-18 * time.Hour),
    PostRelapseActive: true,
    RecentMoodRatings: []int{2, 2, 1}, // declining over last 3 sessions
}
```

### Persona: Diego (established recovery)

```go
var DiegoAffirmationFixtures = struct {
    UserID                  string
    SobrietyDays            int
    Level                   int
    Track                   string
    TotalSessions           int
    TotalPracticed          int
    HealthySexualityEnabled bool
    CustomCount             int
    AudioCount              int
    MoodAvg                 float64
}{
    UserID:                  "u_diego_001",
    SobrietyDays:            200,
    Level:                   4,
    Track:                   "standard",
    TotalSessions:           150,
    TotalPracticed:          450,
    HealthySexualityEnabled: true,
    CustomCount:             8,
    AudioCount:              5,
    MoodAvg:                 4.2,
}
```
