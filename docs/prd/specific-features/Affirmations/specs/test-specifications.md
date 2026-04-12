# Declarations of Truth (Affirmations) -- Test Specifications

**Version:** 2.0.0
**Date:** 2026-04-09
**Status:** Draft
**Acceptance Criteria Source:** `prd.md` (User Stories US-AFF-001 through US-AFF-092, NFR-AFF-001 through NFR-AFF-014)

All test names reference acceptance criteria from the PRD using the format `Test<Domain>_<AC_ID>_<Behavior>`.

---

## 1. Unit Tests (60-70%)

**Location:** `internal/domain/affirmation/*_test.go`

### 1.1 Pack Management Tests

```
TestPackManagement_AFF_US020_DefaultPacksAvailableToAllUsers
  Given a new user with no purchases
  When listing available packs
  Then default (free) packs are returned with isLocked=false

TestPackManagement_AFF_US020_PremiumPacksLockedByDefault
  Given a user with no purchases
  When listing all packs
  Then premium packs have isLocked=true and price visible

TestPackManagement_AFF_US020_CustomPackTypeDistinct
  Given a user with 2 custom packs
  When listing packs filtered by type=custom
  Then only custom packs returned with packType="custom"

TestPackManagement_AFF_US023_CustomPackGatedAtDay14
  Given a user with 10 days sober
  When attempting to create a custom pack
  Then returns validation error "custom packs require 14+ days in recovery"

TestPackManagement_AFF_US023_CustomPackAllowedAtDay14
  Given a user with exactly 14 days sober
  When creating a custom pack with valid data
  Then pack is created successfully

TestPackManagement_AFF_US023_MaxCustomPacksEnforced
  Given a user with 20 existing custom packs
  When attempting to create a 21st custom pack
  Then returns validation error "maximum 20 custom packs reached"

TestPackManagement_AFF_US023_MaxDeclarationsPerCustomPack
  Given a custom pack with 50 declarations
  When attempting to add a 51st declaration
  Then returns validation error "maximum 50 declarations per pack"

TestPackManagement_AFF_US023_PackNameMaxLength
  Given a pack name with 51 characters
  When creating a custom pack
  Then returns validation error pointing to /data/name

TestPackManagement_AFF_US023_PackNameAt50CharsAccepted
  Given a pack name with exactly 50 characters
  When creating a custom pack
  Then pack is created successfully

TestPackManagement_AFF_US024_CustomPackMixesCuratedAndCustom
  Given a custom pack
  When adding 2 curated declarations from owned packs and 1 custom-written declaration
  Then pack contains 3 declarations with correct sourceType on each

TestPackManagement_AFF_US026_PackRotationToggle
  Given 3 packs in user rotation
  When toggling pack 2 rotation to OFF
  Then activePackIds contains only packs 1 and 3

TestPackManagement_AFF_US026_AtLeastOnePackActive
  Given 1 pack in user rotation
  When toggling the last pack rotation to OFF
  Then returns validation error "at least one pack must be active"

TestPackManagement_AFF_US022_PremiumPackOwnershipValidation
  Given a user who has purchased pack "marriage-restoration"
  When requesting declarations from that pack
  Then all declarations returned with isLocked=false

TestPackManagement_AFF_NFR008_PurityHolinessDoubleGate_DaysInsufficient
  Given a user with 45 days sober and opt-in=true
  When requesting "Purity & Holiness" pack
  Then pack remains locked with message "available at 60+ days"

TestPackManagement_AFF_NFR008_PurityHolinessDoubleGate_NoOptIn
  Given a user with 90 days sober and opt-in=false
  When requesting "Purity & Holiness" pack
  Then pack remains locked with message "explicit opt-in required"

TestPackManagement_AFF_NFR008_PurityHolinessDoubleGate_BothMet
  Given a user with 90 days sober and opt-in=true
  When requesting "Purity & Holiness" pack
  Then pack is unlocked and all declarations accessible

TestPackManagement_AFF_US027_OnDemandSessionFromSpecificPack
  Given a user owns pack "armor-of-god"
  When starting an on-demand session with packId="armor-of-god"
  Then session draws declarations only from that pack
```

### 1.2 Level Engine Tests

```
TestLevelEngine_AFF_US001_Level1FromDay1
  Given a user with 1 day sober
  When computing available level
  Then maxLevel=1

TestLevelEngine_AFF_US001_Level2AtDay14
  Given a user with 14 days sober
  When computing available level
  Then maxLevel=2

TestLevelEngine_AFF_US001_Level3AtDay60
  Given a user with 60 days sober
  When computing available level
  Then maxLevel=3

TestLevelEngine_AFF_US001_Level4AtDay180
  Given a user with 180 days sober
  When computing available level
  Then maxLevel=4

TestLevelEngine_AFF_US001_Level2AtDay59
  Given a user with 59 days sober
  When computing available level
  Then maxLevel=2 (not yet 3)

TestLevelEngine_AFF_US001_Level3AtDay179
  Given a user with 179 days sober
  When computing available level
  Then maxLevel=3 (not yet 4)

TestLevelEngine_ManualDowngradeAlwaysAllowed
  Given a user at Level 3 with 90 days sober
  When manually setting level to 1
  Then level is set to 1 without error

TestLevelEngine_ManualUpgradeRequires30DaysAtCurrentLevel
  Given a user at Level 2 for 15 days
  When manually requesting upgrade to Level 3
  Then returns error "30 days at current level required for manual upgrade"

TestLevelEngine_ManualUpgradeAfter30DaysAtCurrentLevel
  Given a user at Level 2 for 31 days with 60+ days sober
  When manually requesting upgrade to Level 3
  Then level is set to 3

TestLevelEngine_AFF_US080_PostRelapseLocksToLevel1
  Given a user at Level 3 who reports a relapse
  When relapse event is processed
  Then level is locked to 1 with postRelapseLockedUntil set to now + 24 hours

TestLevelEngine_AFF_US082_PostRelapseWindowExpires
  Given a user with postRelapseLockedUntil 25 hours in the past
  When computing available level
  Then normal level calculation resumes based on days sober

TestLevelEngine_AFF_US082_PostRelapseWindowActive
  Given a user with postRelapseLockedUntil 12 hours in the future
  When computing available level
  Then level is locked to 1 regardless of days sober

TestLevelEngine_AFF_US011_SOSNeverAboveLevel2
  Given a user at Level 4 with 200 days sober
  When entering SOS mode
  Then session maxLevel capped at 2

TestLevelEngine_AFF_US001_8020ServingRatio
  Given a user at Level 2
  When generating 100 sessions of 5 declarations each (500 total)
  Then approximately 80% of declarations are Level 2 and 20% are Level 3 (one level up)
  And zero declarations are Level 4

TestLevelEngine_LevelChangeLogged
  Given a user at Level 2
  When level changes to Level 3 via automatic progression
  Then levelHistory entry appended with previousLevel=2, newLevel=3, trigger="automatic", timestamp
```

### 1.3 Content Selection Tests

```
TestContentSelection_AFF_US001_7DayNoRepeat
  Given a user who saw declaration D1 3 days ago
  When selecting declarations for today's session
  Then D1 is excluded from selection

TestContentSelection_AFF_US001_7DayRepeatAllowedAfterWindow
  Given a user who saw declaration D1 8 days ago
  When selecting declarations for today's session
  Then D1 is eligible for selection

TestContentSelection_AFF_US040_FavoritesPrioritized
  Given 3 favorited declarations and 50 non-favorited eligible declarations
  When selecting 5 declarations for a session
  Then favorited declarations appear with higher probability than non-favorited

TestContentSelection_AFF_US041_HiddenNeverSurfaced
  Given a user who has hidden declaration D5
  When selecting declarations across 100 sessions
  Then D5 never appears in any session

TestContentSelection_CategoryDistributionAcrossSession
  Given active packs containing declarations from 4 categories
  When selecting 5 declarations for a session
  Then no more than 2 declarations from the same category

TestContentSelection_CoreBeliefCoverage
  Given declarations mapped to 4 core beliefs (Carnes framework)
  When selecting declarations over 7 sessions
  Then all 4 core beliefs are represented at least once

TestContentSelection_AFF_US026_RotationRespectsActivePackIds
  Given 5 packs total but only 2 in activePackIds
  When selecting declarations for a session
  Then all declarations come from the 2 active packs only

TestContentSelection_AFF_US040_FavoritesBypassesRepeatWindow
  Given a favorited declaration D1 seen 2 days ago
  When selecting declarations for today's session
  Then D1 is eligible despite being within the 7-day window

TestContentSelection_AFF_US011_SOSDrawsFromSOSPackOnly
  Given a user with 5 active packs including the SOS pack
  When generating an SOS session
  Then all declarations come from the SOS pack

TestContentSelection_AFF_US001_Level1UserGetsOnlyLevel1
  Given a user at Level 1
  When selecting declarations
  Then all declarations are Level 1 (no 80/20 up-level for Level 1)

TestContentSelection_AFF_US001_Level4UserGetsLevel4Only
  Given a user at Level 4
  When selecting declarations
  Then all declarations are Level 4 (no Level 5 exists to serve in 20% slot)

TestContentSelection_InsufficientDeclarationsGracefulDegradation
  Given a pack with only 2 eligible declarations
  When requesting a 5-declaration session from that pack
  Then session contains 2 declarations without error
```

### 1.4 Morning Session Tests

```
TestMorningSession_AFF_US001_Returns3To5Declarations
  Given a user at Level 2 with active packs containing 100+ declarations
  When requesting a morning session
  Then session contains between 3 and 5 declarations at Level 2 (with 80/20 rule)

TestMorningSession_AFF_US001_IncludesIntentionPrompt
  Given a morning session
  When session payload is constructed
  Then intentionPrompt field is present with text "Today, empowered by the Spirit, I choose to ___"

TestMorningSession_AFF_US004_SkipWithoutPenalty
  Given a user who skips the morning session
  When checking progress metrics
  Then totalSessions is unchanged and no negative language is generated

TestMorningSession_AFF_US001_SessionCompletionRecorded
  Given a user completes a morning session
  When session completion is processed
  Then session record contains sessionType="morning", durationSeconds, declarationCount, completedAt

TestMorningSession_AFF_US005_IntentionStoredInJournal
  Given a user completes a morning session with intention text "be honest today"
  When session completion is processed
  Then a journal entry is created with source="affirmation_intention" and content="be honest today"

TestMorningSession_OpeningCenteringPhase
  Given a morning session payload
  When session is constructed
  Then openingPhase contains breathingDurationSeconds and centeringScripture

TestMorningSession_AFF_US032_ExpansionAndPrayerAvailablePerCard
  Given a morning session with 3 declarations
  When session payload is constructed
  Then each declaration includes scriptureRef, expansionText, and prayerText fields

TestMorningSession_AFF_US001_DeclarationsAtCorrectLevel
  Given a user at Level 3
  When requesting a morning session 100 times
  Then approximately 80% of declarations are Level 3 and 20% are Level 4
```

### 1.5 Evening Reflection Tests

```
TestEveningReflection_AFF_US002_Returns1Declaration
  Given a user at Level 2
  When requesting an evening session
  Then session contains exactly 1 declaration at Level 1 or Level 2

TestEveningReflection_AFF_US002_IncludesMorningIntention
  Given a user who completed a morning session with intention "be patient today"
  When requesting evening reflection
  Then morningIntentionRecall field contains "be patient today"

TestEveningReflection_AFF_US002_DayRatingRequired
  Given an evening session completion with no dayRating
  When validating the completion payload
  Then returns validation error "dayRating is required"

TestEveningReflection_AFF_US002_DayRatingRange
  Given dayRating values of 0 and 6
  When validating each
  Then both return validation error "dayRating must be between 1 and 5"

TestEveningReflection_AFF_US002_RatingFeedsMoodTrend
  Given an evening session completed with dayRating=3
  When session is processed
  Then mood trend system receives rating=3 for today's date

TestEveningReflection_AFF_US002_ReflectionTextOptional
  Given an evening session completion with no reflectionText
  When validating the completion payload
  Then validation passes

TestEveningReflection_CompassionateFraming
  Given an evening session payload
  When session is constructed
  Then no text contains "Did you stay sober" or "relapse" or "fail"
  And framing uses phrases like "How did today feel?"
```

### 1.6 SOS Mode Tests

```
TestSOSMode_AFF_US010_ResponseWithinTimeLimit
  Given a user triggers SOS mode
  When SOS session is requested
  Then response is generated within processing budget (logic under 100ms, network aside)

TestSOSMode_AFF_US010_MandatoryBreathingBeforeDeclarations
  Given an SOS session payload
  When session is constructed
  Then breathingExercise phase is present with pattern="4-7-8" and mandatory=true
  And declarations are sequenced after breathing phase

TestSOSMode_AFF_US011_Level1Or2Only
  Given a user at Level 4 with 200 days sober
  When generating SOS declarations
  Then all declarations are Level 1 or Level 2 only

TestSOSMode_AFF_NFR007_NeverLevel3Or4
  Given all SOS pack declarations
  When validating SOS pack content
  Then zero declarations have level > 2

TestSOSMode_AFF_US011_3DeclarationsFromSOSPack
  Given a user triggers SOS mode
  When SOS session is generated
  Then exactly 3 declarations are returned, all from the SOS pack

TestSOSMode_AFF_US013_PostSOSCheckIn10MinDelay
  Given a user completes an SOS session at time T
  When SOS completion is processed
  Then a scheduled notification is created for T + 10 minutes
  And notification text is "How are you doing? God is still with you."

TestSOSMode_AFF_US015_NeverAutoShared
  Given a user completes an SOS session without explicit share confirmation
  When checking partner-visible data
  Then SOS session is not present in partner sharing summary

TestSOSMode_AFF_US014_WorksOffline
  Given SOS pack declarations cached locally
  When generating an SOS session without network
  Then session is generated from local cache successfully

TestSOSMode_AFF_US012_ReachOutPrayOkayOptionsPresent
  Given an SOS session completion payload
  When constructing post-SOS options
  Then options include "Reach out to someone", "Pray with me", and "I'm okay"

TestSOSMode_AFF_US010_IncludesScriptureReference
  Given an SOS session
  When session opens
  Then Psalm 46:1 is displayed as the centering Scripture
```

### 1.7 Custom Declaration Tests

```
TestCustomDeclaration_AFF_US023_Day14GateEnforced
  Given a user with 10 days sober
  When attempting to write a custom declaration
  Then returns validation error "custom declarations require 14+ days in recovery"

TestCustomDeclaration_AFF_US023_Day14Allowed
  Given a user with 14 days sober
  When writing a valid custom declaration
  Then declaration is created successfully

TestCustomDeclaration_AFF_US025_Max280Characters
  Given a declaration text with 281 characters
  When creating a custom declaration
  Then returns validation error "maximum 280 characters"

TestCustomDeclaration_AFF_US025_280CharsAccepted
  Given a declaration text with exactly 280 characters
  When creating a custom declaration
  Then declaration is created successfully

TestCustomDeclaration_AFF_US025_PresentTenseGuidance
  Given a custom declaration creation request
  When constructing the guidance response
  Then guidance includes "present tense" and "positive framing" recommendations

TestCustomDeclaration_AFF_US025_ScriptureReferenceOptional
  Given a custom declaration with no scriptureRef
  When validating
  Then validation passes with scriptureRef=null

TestCustomDeclaration_AFF_US025_ScriptureReferenceAccepted
  Given a custom declaration with scriptureRef="Philippians 4:13"
  When creating
  Then declaration stores scriptureRef correctly

TestCustomDeclaration_IncludeInRotationToggle
  Given a custom declaration with includeInRotation=true
  When selecting declarations for daily session
  Then custom declaration is eligible for selection

TestCustomDeclaration_ExcludeFromRotation
  Given a custom declaration with includeInRotation=false
  When selecting declarations for daily session
  Then custom declaration is never selected

TestCustomDeclaration_NotReviewedDisclosure
  Given a custom declaration creation request
  When constructing the creation response
  Then response includes disclosureText indicating custom content is not reviewed by staff

TestCustomDeclaration_AFF_NFR002_ImmutableCreatedAt
  Given an existing custom declaration created at time T
  When updating the declaration with a new createdAt value
  Then returns error "createdAt is immutable" and original timestamp preserved

TestCustomDeclaration_AFF_US024_AddCuratedFromOwnedPacks
  Given a user who owns pack "identity-in-christ"
  When adding curated declaration D1 from "identity-in-christ" to custom pack
  Then D1 appears in custom pack with sourceType="curated" and sourcePackId="identity-in-christ"
```

### 1.8 Audio Recording Tests

```
TestAudioRecording_AFF_US050_Max60Seconds
  Given an audio recording with duration 61 seconds
  When validating audio metadata
  Then returns validation error "maximum 60 seconds"

TestAudioRecording_AFF_US050_60SecondsAccepted
  Given an audio recording with duration exactly 60 seconds
  When validating audio metadata
  Then validation passes

TestAudioRecording_AFF_US050_FormatM4AAAC64kbps
  Given audio metadata for a recording
  When validating format
  Then format must be "m4a", codec "aac", bitrate 64000

TestAudioRecording_AFF_US053_5BackgroundMusicOptions
  Given the background music enum
  Then exactly 5 options exist: worship_piano, nature, hymns_instrumental, atmospheric, silence

TestAudioRecording_AFF_US053_BackgroundVolumeDefault40
  Given an audio recording with no backgroundVolume specified
  When applying defaults
  Then backgroundVolumePercent defaults to 40

TestAudioRecording_AFF_US052_LocalOnlyStorageDefault
  Given an audio recording with no cloudSync preference
  When applying defaults
  Then storageMode defaults to "local_only"

TestAudioRecording_AFF_US052_CloudSyncRequiresExplicitOptIn
  Given a user with cloudSync=false in settings
  When attempting to sync audio to cloud
  Then sync is rejected with "cloud sync requires explicit opt-in"

TestAudioRecording_AFF_US051_HeadphoneDisconnectPause
  Given an active audio playback session
  When headphone route change event fires
  Then pause command is issued with target latency < 100ms
```

### 1.9 Progress Tests -- Cumulative Only

```
TestProgress_AFF_US060_TotalSessionsIncrements
  Given a user with totalSessions=24
  When a session is completed
  Then totalSessions=25

TestProgress_AFF_US060_TotalDeclarationsIncrements
  Given a user with totalDeclarations=100 who completes a session with 5 declarations
  When session is processed
  Then totalDeclarations=105

TestProgress_AFF_US060_PacksExploredCount
  Given a user who has used declarations from 3 different packs
  When checking progress
  Then packsExplored=3

TestProgress_AFF_US060_FavoritesCount
  Given a user with 12 favorited declarations
  When checking progress
  Then favoritesCount=12

TestProgress_AFF_US060_CustomCreatedCount
  Given a user who has written 8 custom declarations
  When checking progress
  Then customCreatedCount=8

TestProgress_AFF_US061_30DayHeatMap
  Given sessions on 18 of the last 30 days with varying counts
  When generating the heat map
  Then 30 entries returned, each with date and sessionCount
  And no entry contains negative or judgmental metadata

TestProgress_AFF_US061_HeatMapNoEmptyDayCallouts
  Given a heat map with 12 days having 0 sessions
  When rendering heat map data
  Then zero-session days have sessionCount=0 only (no "missed" or "gap" labels)

TestProgress_AFF_US062_MilestoneAt1stSession
  Given a user completes their 1st session
  When processing milestone check
  Then milestone event fired with milestoneType="session_count" and count=1

TestProgress_AFF_US062_MilestoneAt10th25th50th100th250th
  Given totalSessions reaching each of [10, 25, 50, 100, 250]
  When processing milestone check for each threshold
  Then milestone event fired for each with correct count

TestProgress_AFF_US062_MilestoneFirstCustom
  Given a user creates their first custom declaration
  When processing milestone check
  Then milestone event fired with milestoneType="first_custom"

TestProgress_AFF_US062_MilestoneFirstAudio
  Given a user records their first audio declaration
  When processing milestone check
  Then milestone event fired with milestoneType="first_audio"

TestProgress_AFF_US062_MilestoneFirstSOS
  Given a user completes their first SOS session
  When processing milestone check
  Then milestone event fired with milestoneType="first_sos"

TestProgress_AFF_US062_MilestoneFirstPurchase
  Given a user purchases their first premium pack
  When processing milestone check
  Then milestone event fired with milestoneType="first_purchase"

TestProgress_AFF_US062_GrowthMindsetMessageFraming
  Given any milestone achievement message
  When constructing the message
  Then text does not contain "amazing", "perfect", "incredible", or superlatives
  And text uses growth-oriented language ("Your commitment is growing", "Another step forward")

TestProgress_AFF_US063_ReEngagement3Day
  Given a user with no sessions in 3 days
  When checking re-engagement eligibility
  Then prompt generated with gapDays=3 and message="Ready when you are."

TestProgress_AFF_US063_ReEngagement7Day
  Given a user with no sessions in 7 days
  When checking re-engagement eligibility
  Then prompt generated with gapDays=7 and message="Coming back is courage."

TestProgress_AFF_US063_ReEngagement14Day
  Given a user with no sessions in 14+ days
  When checking re-engagement eligibility
  Then prompt generated with gapDays=14 and message includes reconnect with partner or pastor suggestion

TestProgress_AFF_US063_NeverShameBasedGapLanguage
  Given re-engagement prompts for gaps of 3, 7, and 14 days
  When constructing each prompt
  Then zero prompts contain "missed", "failed", "behind", "lost", "broke", or "streak"

TestProgress_AFF_NFR004_NoBrokenStreakAnywhere
  Given the entire affirmation domain codebase
  When scanning all string constants and message templates
  Then zero occurrences of "streak", "broken streak", "days in a row", or "consecutive days"
```

### 1.10 Clinical Safeguard Tests -- 100% Coverage Required

```
TestClinicalSafeguard_WorseningMood3Sessions
  Given evening ratings of [3, 2, 1] over 3 consecutive sessions
  When processing the 3rd declining rating
  Then clinical prompt triggered with type="worsening_mood" and consecutiveDeclines=3

TestClinicalSafeguard_WorseningMood_StableDoesNotTrigger
  Given evening ratings of [3, 3, 3] over 3 sessions
  When processing ratings
  Then no clinical prompt triggered (stable, not declining)

TestClinicalSafeguard_AFF_US080_PostRelapseLevel1Only
  Given a user in post-relapse window
  When requesting any session type (morning, evening, on-demand)
  Then all declarations are Level 1 only

TestClinicalSafeguard_AFF_US081_PostRelapseCompassionateMessage
  Given a user who just reported a relapse
  When constructing the Today screen card
  Then card contains "Coming back is not failure. Coming back is repentance, and God honors repentance."
  And card includes Lamentations 3:22-23 reference

TestClinicalSafeguard_AFF_US080_PostRelapseAppendsMercyVerse
  Given a user in post-relapse window completing a session
  When constructing the session
  Then final declaration includes "God's mercies are new every morning. (Lam 3:22-23)"

TestClinicalSafeguard_AFF_US082_24HRelapseWindowAutoExpires
  Given a user with relapseLockedUntil = 24 hours ago
  When computing level
  Then normal level calculation applies and postRelapseLock is cleared

TestClinicalSafeguard_CrisisLanguageBypassesAffirmations
  Given a user input containing crisis language ("suicide", "kill myself", "end it all")
  When processing the input
  Then affirmation flow is interrupted and crisis routing is triggered

TestClinicalSafeguard_CrisisRoutingIncludesAllResources
  Given a crisis routing event is triggered
  When constructing crisis resources
  Then resources include Crisis Text Line (741741), SAMHSA (1-800-662-4357), and 988 Lifeline
  And direct dial/text links are functional

TestClinicalSafeguard_AFF_US042_5HidesTriggersTherapeuticPrompt
  Given a user who has hidden 5 declarations in the rolling 30-day window
  When the 5th hide is processed
  Then therapeutic prompt is generated encouraging connection with counselor

TestClinicalSafeguard_AFF_US042_3HidesTriggersHolySpiritPrompt
  Given a user who has hidden 3 declarations in the rolling 30-day window
  When the 3rd hide is processed
  Then prompt displayed: "Sometimes the truths we resist most are the ones the Holy Spirit is highlighting for healing."
  And prompt shown at most once per week

TestClinicalSafeguard_HiddenCountTracksForClinicalDashboard
  Given a user hides 7 declarations across 30 days
  When querying clinical dashboard data (with user consent)
  Then hiddenCount30Day=7 and hiddenByCoreBelief breakdown is available
```

### 1.11 Privacy Tests -- 100% Coverage Required

```
TestPrivacy_AFF_US091_GenericNotificationTextOnly
  Given a morning notification is constructed
  When checking notification content
  Then title and body contain no recovery-specific language
  And no mention of "addiction", "recovery", "sobriety", "relapse", or "affirmation"

TestPrivacy_AFF_US091_EveningNotificationGeneric
  Given an evening notification is constructed
  When checking notification content
  Then text is generic (e.g., "A moment to close your day.")

TestPrivacy_AFF_US051_AudioAutoPauseOnHeadphoneDisconnect
  Given an active audio playback
  When AVAudioSession route-change event fires (headphones removed)
  Then playback pauses within 100ms
  And no audio output to device speaker

TestPrivacy_AFF_US091_WidgetGeneralScriptureOnly
  Given today's widget content
  When constructing widget payload
  Then content is general Scripture only
  And no recovery-specific language, app name, or feature name visible

TestPrivacy_AFF_US070_SessionCountOnlySharedToPartners
  Given a user with a connected accountability partner
  When partner requests sharing summary
  Then only sessionCountThisWeek is returned
  And no declaration text, custom content, hidden declarations, or audio data

TestPrivacy_AFF_US052_LocalFirstAudioStorage
  Given a new audio recording with default settings
  When recording is saved
  Then file is stored on-device only
  And no cloud upload is initiated

TestPrivacy_BillingDescriptorGeneric
  Given a premium pack purchase transaction
  When constructing purchase metadata
  Then billing descriptor contains no recovery-specific language

TestPrivacy_NoRecoveryLanguageInExternalText
  Given all notification templates, widget templates, and billing descriptors
  When scanning for recovery-specific terms
  Then zero occurrences of "addiction", "recovery", "sober", "relapse", "sexual", "SA", or "Celebrate Recovery"

TestPrivacy_AFF_US015_SOSNeverAutoShared
  Given a completed SOS session without explicit share confirmation
  When partner queries user data
  Then SOS session is not visible

TestPrivacy_AFF_US052_AudioNeverSharedWithPartners
  Given a user with audio recordings and a connected accountability partner
  When partner requests sharing summary
  Then no audio metadata or files are included
```

### 1.12 Feature Flag & NFR Tests

```
TestFeatureFlag_AFF_NFR001_DisabledReturns404
  Given feature flag activity.affirmations is disabled
  When any affirmation endpoint is called
  Then returns 404 Not Found

TestFeatureFlag_AFF_NFR001_FailClosedBehavior
  Given feature flag system is unavailable
  When any affirmation endpoint is called
  Then returns 404 Not Found (fail closed)

TestNFR_AFF_NFR002_ImmutableTimestamps
  Given an existing session record created at time T
  When update includes createdAt field
  Then returns error "createdAt is immutable" and timestamp unchanged

TestNFR_AFF_NFR003_CalendarDualWriteOnSessionComplete
  Given a user completes any affirmation session (morning, evening, sos, on-demand)
  When session completion is processed
  Then a calendarActivities entry is created with activityType="declarations"

TestNFR_TenantIsolationEnforced
  Given user A in tenant T1 and user B in tenant T2
  When user A queries affirmation data
  Then only tenant T1 data is returned
  And user B's data is never accessible
```

### 1.13 Purchase Tests

```
TestPurchase_AFF_US022_PremiumPackStoresReceipt
  Given a successful App Store purchase of pack "armor-of-god"
  When purchase is processed
  Then receipt is stored with packId, transactionId, purchaseDate, and platform

TestPurchase_AFF_US022_PurchaseRestoredAcrossDevices
  Given a user who purchased pack "armor-of-god" on device A
  When restoring purchases on device B
  Then pack "armor-of-god" is unlocked on device B

TestPurchase_AFF_US024_OwnedPackDeclarationsAvailableForCustom
  Given a user who owns pack "marriage-restoration"
  When browsing declarations to add to a custom pack
  Then all declarations from "marriage-restoration" are available for curation

TestPurchase_AFF_US021_NonOwnedPremiumShowsPreviewOnly
  Given a user who has NOT purchased pack "marriage-restoration"
  When requesting pack details
  Then only 3 preview declarations are visible
  And remaining declarations are marked isLocked=true

TestPurchase_BundlePurchaseUnlocksAllPacks
  Given a bundle containing packs A, B, and C
  When bundle purchase is processed
  Then all 3 packs are unlocked and all declarations accessible

TestPurchase_AFF_US022_NoSubscriptionGating
  Given a premium pack purchase
  When validating purchase type
  Then purchaseType="one_time" (never "subscription")

TestPurchase_ReceiptServerSideValidation
  Given a purchase receipt from the client
  When validating receipt
  Then server-side validation is performed against App Store / Play Store
  And invalid receipts are rejected with error

TestPurchase_InvalidReceiptRejected
  Given a tampered or expired purchase receipt
  When validating receipt
  Then returns error "invalid purchase receipt" with code rr:0x000A0010
```

---

## 2. Integration Tests (20-30%)

**Location:** `test/integration/affirmation/`

### 2.1 Session Repository

```
TestAffirmationSessionRepo_CreateAndRetrieveMorningSession
  Given a valid morning session record
  When created via repository and retrieved by sessionId
  Then all fields intact including userId, sessionType, declarations, durationSeconds, completedAt

TestAffirmationSessionRepo_CreateAndRetrieveEveningSession
  Given a valid evening session with dayRating and morningIntentionRecall
  When created and retrieved
  Then dayRating, reflectionText, and morningIntentionRecall are correct

TestAffirmationSessionRepo_CreateAndRetrieveSOSSession
  Given a valid SOS session with breathingCompleted and postSOSChoice
  When created and retrieved
  Then all SOS-specific fields present

TestAffirmationSessionRepo_ListByDateRange
  Given 20 sessions across March
  When querying startDate=2026-03-10 endDate=2026-03-20
  Then only sessions within range returned

TestAffirmationSessionRepo_CursorPagination
  Given 60 sessions
  When requesting limit=20
  Then first page returns 20 with nextCursor, subsequent pages paginate correctly
```

### 2.2 Pack & Library Repository

```
TestAffirmationLibraryRepo_ListDefaultPacks
  Given seeded default packs in affirmationsLibrary
  When listing packs with type=default
  Then all free packs returned with declaration counts

TestAffirmationLibraryRepo_ListPremiumPacks
  Given seeded premium packs in affirmationsLibrary
  When listing packs with type=premium
  Then premium packs returned with price and isLocked status

TestAffirmationLibraryRepo_GetPackDeclarations
  Given pack "identity-in-christ" with 30 declarations
  When fetching declarations for that pack
  Then 30 declarations returned with level, category, scriptureRef, coreBeliefId
```

### 2.3 Pack Purchase + Unlock Flow

```
TestAffirmationPurchaseRepo_PurchaseAndUnlock
  Given a user purchases pack "marriage-restoration"
  When purchase receipt is stored and pack status queried
  Then pack isLocked=false and all declarations accessible

TestAffirmationPurchaseRepo_RestorePurchases
  Given stored purchase receipts for packs A and B
  When restore is called
  Then both packs return isLocked=false
```

### 2.4 Session Completion with Calendar Dual-Write

```
TestAffirmationIntegration_SessionCompletionDualWrite
  Given a user completes a morning session
  When session is persisted
  Then affirmationSessions document exists
  And calendarActivities document exists with activityType="declarations" and matching timestamp
```

### 2.5 Level Engine with Real MongoDB

```
TestAffirmationLevelRepo_LevelProgression
  Given a user starts at Level 1
  When sobriety days progress through [1, 14, 60, 180]
  Then level history entries are created for each transition
  And current level matches expected at each threshold

TestAffirmationLevelRepo_PostRelapseLockAndExpiry
  Given a user at Level 3 who reports relapse
  When relapse is processed and then 24 hours elapse
  Then level locked to 1 during window and resumes after window
```

### 2.6 Favorites Repository

```
TestAffirmationFavoritesRepo_FavoriteAndUnfavorite
  Given a declaration from an owned pack
  When favorited then unfavorited
  Then favorite created then removed from collection

TestAffirmationFavoritesRepo_ListFavoritesCrossPack
  Given 3 favorites from pack A and 2 from pack B
  When listing all favorites
  Then 5 favorites returned grouped by sourcePackId

TestAffirmationFavoritesRepo_DuplicateFavoriteReturns409
  Given an already-favorited declaration
  When favorited again
  Then returns 409 Conflict
```

### 2.7 Hidden Repository

```
TestAffirmationHiddenRepo_HideAndUnhide
  Given a declaration
  When hidden then unhidden
  Then hidden record created then removed

TestAffirmationHiddenRepo_Rolling30DayCount
  Given 10 hides across 45 days (7 within last 30 days)
  When querying 30-day hidden count
  Then hiddenCount30Day=7
```

### 2.8 Custom Pack Repository

```
TestAffirmationCustomRepo_CreatePackWithMixedDeclarations
  Given a custom pack with 2 curated and 3 custom-written declarations
  When created and retrieved
  Then pack contains 5 declarations with correct sourceTypes

TestAffirmationCustomRepo_UpdatePackName
  Given an existing custom pack named "Morning Armor"
  When updating name to "Battle Armor"
  Then name is updated and createdAt is unchanged

TestAffirmationCustomRepo_DeletePackRemovesDeclarations
  Given a custom pack with 5 declarations
  When pack is deleted
  Then pack and all its declarations are removed from collection
```

### 2.9 Audio Metadata Repository

```
TestAffirmationAudioRepo_CreateAndRetrieveMetadata
  Given an audio recording metadata record
  When created and retrieved
  Then all fields intact including declarationId, durationSeconds, backgroundMusic, storageMode

TestAffirmationAudioRepo_ListByUser
  Given 5 audio recordings for a user
  When listing audio metadata
  Then 5 records returned sorted by createdAt descending
```

### 2.10 Settings Repository

```
TestAffirmationSettingsRepo_CreateAndRetrieve
  Given default settings for a new user
  When created and retrieved
  Then morningTime="07:00", eveningTime="21:00", activePackIds populated

TestAffirmationSettingsRepo_UpdatePartial
  Given existing settings
  When patching morningTime to "06:30"
  Then morningTime="06:30" and all other fields unchanged
```

### 2.11 Progress Tracking Across Sessions

```
TestAffirmationProgressRepo_CumulativeCountsAccurate
  Given a user completes 5 morning sessions (3 declarations each) over 5 days
  When querying progress
  Then totalSessions=5, totalDeclarations=15

TestAffirmationProgressRepo_MilestonesFiredCorrectly
  Given a user reaching 10th session
  When session is processed
  Then milestone record exists with milestoneType="session_count" and count=10
```

---

## 3. End-to-End Tests (5-10%)

**Location:** `test/e2e/affirmation/`

### 3.1 Full Morning Session Flow (Alex, Day 45)

```
TestAffirmationE2E_MorningSession_Alex
  Given authenticated user Alex at Day 45, Level 2, with 3 active packs
  When GET /activities/affirmations/session/morning
  Then 200 returned with 3-5 declarations at Level 2 (80/20 rule)
  And session includes openingPhase, intentionPrompt, and declarations with scriptureRef
  When POST /activities/affirmations/session/morning with completionPayload (durationSeconds, intentionText)
  Then 201 returned with sessionId
  And GET /activities/affirmations/progress shows totalSessions incremented
  And calendarActivities contains new entry with activityType="declarations"
```

### 3.2 Evening Reflection Flow (Sarah, Day 90)

```
TestAffirmationE2E_EveningReflection_Sarah
  Given authenticated user Sarah at Day 90, Level 2-3, completed morning session with intention
  When GET /activities/affirmations/session/evening
  Then 200 returned with 1 declaration (Level 1-2) and morningIntentionRecall
  When POST /activities/affirmations/session/evening with dayRating=4, reflectionText="Felt peaceful"
  Then 201 returned
  And mood trend system receives rating=4
```

### 3.3 SOS Mode Flow (Marcus, Day 7 Post-Relapse)

```
TestAffirmationE2E_SOSMode_Marcus
  Given authenticated user Marcus at Day 7, post-relapse within 24h window
  When POST /activities/affirmations/sos
  Then 200 returned with breathingExercise (mandatory) and 3 Level 1 declarations from SOS pack
  When POST /activities/affirmations/sos/{sosId}/complete with breathingCompleted=true, postSOSChoice="reach_out"
  Then 201 returned
  And SOS session not visible in partner sharing summary
  And post-SOS check-in notification scheduled for 10 minutes
```

### 3.4 Custom Pack Creation Flow (Diego, Day 200)

```
TestAffirmationE2E_CustomPackCreation_Diego
  Given authenticated user Diego at Day 200, Level 4, owns 3 premium packs
  When POST /activities/affirmations/custom with name="Morning Armor", declarations=[2 curated, 1 custom-written]
  Then 201 returned with packId and 3 declarations
  When PATCH /activities/affirmations/settings with activePackIds including new pack
  Then 200 returned
  When GET /activities/affirmations/session/morning
  Then session may include declarations from "Morning Armor"
```

### 3.5 Premium Pack Purchase + Session Flow

```
TestAffirmationE2E_PremiumPurchaseAndSession
  Given authenticated user with no premium packs
  When GET /activities/affirmations/library/{packId} for premium pack
  Then 200 returned with 3 preview declarations and isLocked=true for remaining
  When POST /activities/affirmations/library/{packId}/purchase with receipt
  Then 200 returned with pack unlocked
  When GET /activities/affirmations/library/{packId}
  Then all declarations returned with isLocked=false
  When starting on-demand session from purchased pack
  Then session draws only from that pack
```

### 3.6 Post-Relapse Re-Entry Flow

```
TestAffirmationE2E_PostRelapseReEntry
  Given authenticated user who reports sobriety reset
  When GET /activities/affirmations/level
  Then currentLevel=1, postRelapseLockedUntil is set, isPostRelapse=true
  When GET /activities/affirmations/session/morning
  Then all declarations are Level 1 only
  And session includes compassionate grounding message with Lamentations 3:22-23
  Given 25 hours elapse (simulated)
  When GET /activities/affirmations/level
  Then postRelapseLockedUntil is null and normal level calculation applies
```

### 3.7 Re-Engagement After 7-Day Gap

```
TestAffirmationE2E_ReEngagement7DayGap
  Given authenticated user with last session 7 days ago
  When GET /activities/affirmations/progress
  Then reEngagementPrompt present with gapDays=7 and message="Coming back is courage."
  When POST /activities/affirmations/session/morning (after re-engagement)
  Then session completes normally
  And reEngagementPrompt is cleared
  And analytics event affirmation.reEngagement.accepted is logged
```

---

## 4. Contract Tests

**Location:** `test/contract/affirmation/`

### 4.1 OpenAPI Spec Validation (All 27+ Endpoints)

```
TestAffirmationContract_MorningSessionGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/session/morning
  When validating response against spec
  Then all fields present with correct types, enums, and constraints

TestAffirmationContract_MorningSessionPOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/session/morning
  When validating request and response against spec
  Then required fields enforced, all enums validated

TestAffirmationContract_EveningSessionGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/session/evening
  When validating response against spec
  Then all fields present with correct types

TestAffirmationContract_EveningSessionPOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/session/evening
  When validating request and response against spec
  Then dayRating enum (1-5), reflectionText optional

TestAffirmationContract_SOSPOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/sos
  When validating response against spec
  Then breathingExercise, declarations, and postSOSOptions present

TestAffirmationContract_SOSCompletePOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/sos/{sosId}/complete
  When validating request and response against spec
  Then breathingCompleted, postSOSChoice validated

TestAffirmationContract_LibraryGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/library
  When validating response against spec
  Then packs array with packType enum, isLocked, price, declarationCount

TestAffirmationContract_LibraryDetailGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/library/{affirmationId}
  When validating response against spec
  Then declaration fields including level, scriptureRef, coreBeliefId

TestAffirmationContract_FavoritesGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/favorites
  When validating response against spec
  Then array of favorited declarations with sourcePackId

TestAffirmationContract_FavoritesPOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/favorites
  When validating request against spec
  Then affirmationId required

TestAffirmationContract_FavoritesDELETE_MatchesSpec
  Given OpenAPI spec for DELETE /activities/affirmations/favorites/{id}
  When validating response
  Then 204 No Content

TestAffirmationContract_HiddenGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/hidden
  When validating response against spec
  Then array of hidden declarations with hiddenAt timestamp

TestAffirmationContract_HiddenPOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/hidden
  When validating request against spec
  Then affirmationId required

TestAffirmationContract_HiddenDELETE_MatchesSpec
  Given OpenAPI spec for DELETE /activities/affirmations/hidden/{id}
  When validating response
  Then 204 No Content

TestAffirmationContract_CustomGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/custom
  When validating response against spec
  Then array of custom packs with declarations array

TestAffirmationContract_CustomPOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/custom
  When validating request against spec
  Then name (max 50), declarations array with sourceType enum

TestAffirmationContract_CustomPATCH_MatchesSpec
  Given OpenAPI spec for PATCH /activities/affirmations/custom/{id}
  When validating request against spec
  Then partial update fields validated

TestAffirmationContract_CustomDELETE_MatchesSpec
  Given OpenAPI spec for DELETE /activities/affirmations/custom/{id}
  When validating response
  Then 204 No Content

TestAffirmationContract_AudioGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/{id}/audio
  When validating response against spec
  Then audio metadata fields including durationSeconds, backgroundMusic enum, storageMode

TestAffirmationContract_AudioPOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/{id}/audio
  When validating request against spec
  Then durationSeconds, format, backgroundMusic validated

TestAffirmationContract_AudioDELETE_MatchesSpec
  Given OpenAPI spec for DELETE /activities/affirmations/{id}/audio
  When validating response
  Then 204 No Content

TestAffirmationContract_ProgressGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/progress
  When validating response against spec
  Then totalSessions, totalDeclarations, packsExplored, heatMap, milestones present

TestAffirmationContract_SettingsGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/settings
  When validating response against spec
  Then morningTime, eveningTime, activePackIds, backgroundPreference, audioPreference

TestAffirmationContract_SettingsPATCH_MatchesSpec
  Given OpenAPI spec for PATCH /activities/affirmations/settings
  When validating request against spec
  Then partial update fields validated

TestAffirmationContract_LevelGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/level
  When validating response against spec
  Then currentLevel, maxLevel, daysAtCurrentLevel, postRelapseLockedUntil, levelHistory

TestAffirmationContract_LevelOverridePOST_MatchesSpec
  Given OpenAPI spec for POST /activities/affirmations/level/override
  When validating request against spec
  Then targetLevel required, direction enum (up/down)

TestAffirmationContract_SharingSummaryGET_MatchesSpec
  Given OpenAPI spec for GET /activities/affirmations/sharing/summary
  When validating response against spec
  Then sessionCountThisWeek only (no content fields)
```

### 4.2 Request/Response Schema Validation

```
TestAffirmationContract_AllResponses_FollowEnvelopePattern
  Given any successful affirmation API response
  When validating structure
  Then response contains { "data": ..., "links": {...}, "meta": {...} }

TestAffirmationContract_PaginatedResponses_UseCursorPagination
  Given paginated endpoints (library, favorites, hidden, custom, sessions)
  When validating pagination
  Then cursor and limit query params supported, nextCursor in response
```

### 4.3 Error Format Validation

```
TestAffirmationContract_ErrorFormat_MatchesSiemensGuidelines
  Given a 422 error response from any affirmation endpoint
  Then structure follows { "errors": [{ "id", "code", "status", "title", "detail", "correlationId" }] }

TestAffirmationContract_ErrorCodes_UseAffirmationPrefix
  Given error responses across affirmation endpoints
  Then all error codes follow pattern rr:0x000Axxxx (0x000A = affirmation domain)

TestAffirmationContract_404_WhenFeatureDisabled
  Given feature flag disabled
  When any endpoint called
  Then 404 returned with standard error envelope
```

### 4.4 Purchase Receipt Format

```
TestAffirmationContract_PurchaseReceipt_iOS_MatchesSpec
  Given a StoreKit 2 purchase receipt
  When validating against spec
  Then transactionId, productId, purchaseDate, environment fields present

TestAffirmationContract_PurchaseReceipt_Android_MatchesSpec
  Given a Google Play Billing receipt
  When validating against spec
  Then purchaseToken, orderId, productId, purchaseTime fields present
```

---

## 5. Mobile Client Tests

### 5.1 iOS (Swift)

**Location:** `ios/RegalRecovery/Tests/Unit/Affirmation/`

```
TestAffirmationiOS_CodableRoundtrip_PackModel
  Given a Pack JSON payload from the API
  When decoded to Pack model and re-encoded
  Then output matches input for all fields including packType, isLocked, price

TestAffirmationiOS_CodableRoundtrip_DeclarationModel
  Given a Declaration JSON payload
  When decoded to Declaration model and re-encoded
  Then output matches input for level, text, scriptureRef, coreBeliefId, expansionText, prayerText

TestAffirmationiOS_CodableRoundtrip_SessionModel
  Given morning, evening, SOS, and on-demand session payloads
  When each decoded and re-encoded
  Then all session-type-specific fields preserved

TestAffirmationiOS_CodableRoundtrip_ProgressModel
  Given a Progress JSON payload with heatMap and milestones
  When decoded and re-encoded
  Then totalSessions, totalDeclarations, heatMap entries, and milestone records match

TestAffirmationiOS_CodableRoundtrip_SettingsModel
  Given a Settings JSON payload
  When decoded and re-encoded
  Then morningTime, eveningTime, activePackIds, backgroundPreference, audioPreference match

TestAffirmationiOS_CodableRoundtrip_AudioMetadataModel
  Given an AudioMetadata JSON payload
  When decoded and re-encoded
  Then durationSeconds, format, backgroundMusic, storageMode match

TestAffirmationiOS_ViewModel_MorningSessionStateMachine
  Given AffirmationSessionViewModel in .idle state
  When loadMorningSession() called
  Then transitions to .loading → .loaded (with declarations) or .error
  When completeSession() called in .loaded state
  Then transitions to .completing → .completed

TestAffirmationiOS_ViewModel_EveningSessionStateMachine
  Given AffirmationSessionViewModel in .idle state
  When loadEveningSession() called
  Then transitions to .loading → .loaded (with 1 declaration + intention recall)
  When completeSession(dayRating: 4) called
  Then transitions to .completing → .completed

TestAffirmationiOS_ViewModel_SOSSessionStateMachine
  Given SOSViewModel in .idle state
  When triggerSOS() called
  Then transitions to .breathing → .declarations → .options
  And .breathing requires completion before advancing

TestAffirmationiOS_ViewModel_PackLibraryStateMachine
  Given PackLibraryViewModel in .idle state
  When loadPacks() called
  Then transitions to .loading → .loaded with packs grouped by type

TestAffirmationiOS_ViewModel_CustomPackStateMachine
  Given CustomPackViewModel in .idle state
  When createPack(name, declarations) called
  Then transitions to .creating → .created or .error (if Day 14 gate fails)

TestAffirmationiOS_AudioSessionManager_HeadphoneDisconnect
  Given an active AVAudioSession playing affirmation audio
  When routeChangeNotification fires with reason=oldDeviceUnavailable
  Then audio player pauses within 100ms
  And no audio output to device speaker

TestAffirmationiOS_AudioSessionManager_RecordingStart
  Given microphone permission granted
  When startRecording() called
  Then AVAudioRecorder begins with format m4a, codec aac, bitrate 64000

TestAffirmationiOS_AudioSessionManager_BackgroundMusicMix
  Given a recording with backgroundMusic=worship_piano at volume 40%
  When recording is mixed
  Then background track volume is 0.4 relative to voice track

TestAffirmationiOS_StoreKit2_PurchaseFlow
  Given a premium pack with StoreKit product ID
  When purchase() called
  Then StoreKit 2 Transaction.updates processed
  And verified transaction stored with receipt

TestAffirmationiOS_StoreKit2_RestorePurchases
  Given previously purchased packs
  When restorePurchases() called
  Then all owned packs unlocked from Transaction.currentEntitlements

TestAffirmationiOS_OfflineCache_SOSPackAlwaysCached
  Given affirmation data synced at least once
  When device goes offline
  Then SOS pack declarations are available from SwiftData cache

TestAffirmationiOS_OfflineCache_MorningSessionAvailable
  Given 30+ declarations cached in SwiftData
  When device goes offline and morning session requested
  Then session generated from local cache

TestAffirmationiOS_OfflineCache_CustomPacksAvailable
  Given custom packs stored in SwiftData
  When device goes offline
  Then custom packs and their declarations are accessible

TestAffirmationiOS_WidgetDataProvider_GenericScriptureOnly
  Given today's widget content generated
  When widget data provider constructs payload
  Then content is general Scripture with no recovery language or app branding
```

### 5.2 Android (Kotlin)

**Location:** `android/app/src/test/java/com/regalrecovery/affirmation/`

```
TestAffirmationAndroid_DataClass_PackSerialization
  Given a Pack JSON payload from the API
  When deserialized to Pack data class and re-serialized
  Then output matches input for all fields

TestAffirmationAndroid_DataClass_DeclarationSerialization
  Given a Declaration JSON payload
  When deserialized and re-serialized
  Then all fields preserved including level, scriptureRef, coreBeliefId

TestAffirmationAndroid_DataClass_SessionSerialization
  Given morning, evening, SOS, and on-demand session payloads
  When each deserialized and re-serialized
  Then all session-type-specific fields preserved

TestAffirmationAndroid_ViewModel_MorningSessionStateFlow
  Given AffirmationSessionViewModel with initial UiState.Idle
  When loadMorningSession() called
  Then StateFlow emits Loading → Loaded(declarations) or Error

TestAffirmationAndroid_ViewModel_SOSSessionStateFlow
  Given SOSViewModel with initial UiState.Idle
  When triggerSOS() called
  Then StateFlow emits Breathing → Declarations → Options

TestAffirmationAndroid_AudioManager_HeadphoneDisconnect
  Given active MediaPlayer playing affirmation audio
  When ACTION_AUDIO_BECOMING_NOISY broadcast received
  Then MediaPlayer pauses immediately

TestAffirmationAndroid_PlayBilling_PurchaseFlow
  Given a premium pack with Play Store product ID
  When launchBillingFlow() and onPurchasesUpdated() called
  Then purchase acknowledged and receipt stored

TestAffirmationAndroid_PlayBilling_RestorePurchases
  Given previously purchased packs
  When queryPurchasesAsync() called
  Then all owned packs unlocked

TestAffirmationAndroid_OfflineCache_SOSPackCached
  Given affirmation data synced at least once
  When device goes offline
  Then SOS pack declarations available from Room database

TestAffirmationAndroid_OfflineCache_SessionGeneration
  Given 30+ declarations cached locally
  When device goes offline and morning session requested
  Then session generated from local cache
```

---

## 6. Coverage Requirements

| Module | Target Coverage |
|--------|----------------|
| Overall affirmation domain | >= 80% line coverage |
| Clinical safeguards (mood escalation, post-relapse, crisis routing, hide thresholds) | 100% line + branch |
| Privacy / audio safety (notifications, widget, headphone disconnect, sharing, storage) | 100% line + branch |
| Level engine (day thresholds, manual override, post-relapse lock, SOS cap, 80/20 ratio) | 100% line + branch |
| Progress -- cumulative-only logic (no streak, no shame language, milestones) | 100% line + branch |
| Pack purchase flow (receipt validation, unlock, restore, preview gating, bundle) | 100% line + branch |
| SOS mode (breathing gate, level cap, pack selection, post-SOS options, privacy) | 100% line + branch |
| Content selection algorithm | 90% line + branch |
| Session validation (morning, evening, custom, audio) | 90% line + branch |
| Feature flag gating | 100% line + branch |
| Tenant isolation | 100% line + branch |

---

## 7. Test Personas

| Persona | Profile | Recovery Stage | Day | Level | Key Test Scenarios |
|---------|---------|----------------|-----|-------|--------------------|
| **Alex** | 34, married, 45 days sober. Celebrate Recovery. Evangelical. Daily user. | Early-to-mid recovery | 45 | 2 | Morning session flow, SOS during commute, 80/20 level ratio, accountability partner sees session count only |
| **Marcus** | 28, single, 7 days sober. Post-relapse. Deep shame. New to recovery. | Early / post-relapse | 7 | 1 (locked) | Post-relapse Level 1 lock, 24h window expiry, compassionate grounding message, SOS mode, permission-level truths only |
| **Diego** | 42, married, 200 days sober. Small group leader. 3 premium packs purchased. | Established recovery | 200 | 4 | Custom pack creation (mixed curated + custom), premium pack purchase, on-demand session, Purity & Holiness double-gate |
| **Sarah** | 31, single, 90 days sober. SA attendee. Trauma history. | Mid recovery | 90 | 2-3 | Evening calming session, mood trend via day ratings, worsening mood clinical prompt, gentle content selection |
| **Pastor James** | Counselor/Sponsor. Oversees 5 recovery group members. | Support network role | N/A | N/A | Clinical dashboard with consent, hidden declaration count, mood trend, level progression view, session count sharing only |

---

## 8. Test Data Fixtures

### Persona Session Fixtures

```go
// pkg/fixtures/affirmation_fixtures.go

var AlexAffirmationHistory = []AffirmationSession{
    {SessionType: "morning", Level: 2, DeclarationCount: 4, DurationSeconds: 180, CompletedAt: daysAgo(0)},
    {SessionType: "evening", Level: 2, DayRating: ptr(4), DurationSeconds: 60, CompletedAt: daysAgo(0)},
    {SessionType: "morning", Level: 2, DeclarationCount: 3, DurationSeconds: 150, CompletedAt: daysAgo(1)},
    {SessionType: "sos", Level: 1, DeclarationCount: 3, DurationSeconds: 120, CompletedAt: daysAgo(3)},
    // ... 45 days of session history
}

var MarcusAffirmationHistory = []AffirmationSession{
    {SessionType: "sos", Level: 1, DeclarationCount: 3, DurationSeconds: 90, CompletedAt: daysAgo(0)},
    // Marcus is 7 days in, post-relapse. Minimal history, mostly SOS.
}

var DiegoAffirmationHistory = []AffirmationSession{
    {SessionType: "morning", Level: 4, DeclarationCount: 5, DurationSeconds: 300, CompletedAt: daysAgo(0)},
    {SessionType: "evening", Level: 4, DayRating: ptr(5), DurationSeconds: 120, CompletedAt: daysAgo(0)},
    // ... 200 days of consistent practice, including custom pack sessions
}

var SarahAffirmationHistory = []AffirmationSession{
    {SessionType: "evening", Level: 2, DayRating: ptr(3), DurationSeconds: 90, CompletedAt: daysAgo(0)},
    {SessionType: "evening", Level: 2, DayRating: ptr(2), DurationSeconds: 75, CompletedAt: daysAgo(1)},
    {SessionType: "evening", Level: 2, DayRating: ptr(2), DurationSeconds: 60, CompletedAt: daysAgo(2)},
    // Sarah's declining mood ratings trigger clinical prompt at 3 consecutive declines
}
```

### Pack & Declaration Fixtures

```go
var DefaultPacks = []Pack{
    {ID: "pack_identity", Name: "Identity in Christ", PackType: "default", Tier: "free", DeclarationCount: 30},
    {ID: "pack_shame_freedom", Name: "Freedom from Shame", PackType: "default", Tier: "free", DeclarationCount: 25},
    {ID: "pack_sos", Name: "SOS Grounding", PackType: "default", Tier: "free", DeclarationCount: 15},
    {ID: "pack_evening_rest", Name: "Evening Rest", PackType: "default", Tier: "free", DeclarationCount: 20},
}

var PremiumPacks = []Pack{
    {ID: "pack_marriage", Name: "Marriage Restoration", PackType: "premium", Tier: "premium", Price: 499, DeclarationCount: 30},
    {ID: "pack_armor", Name: "Armor of God", PackType: "premium", Tier: "premium", Price: 399, DeclarationCount: 20},
    {ID: "pack_purity", Name: "Purity & Holiness", PackType: "premium", Tier: "premium", Price: 499, DeclarationCount: 25,
        RequiresMinDays: 60, RequiresOptIn: true},
}

var SOSDeclarations = []Declaration{
    {ID: "decl_sos_001", Text: "God is your refuge right now. This moment will pass.", ScriptureRef: "Psalm 46:1", Level: 1, PackID: "pack_sos", CoreBeliefID: "cb_safety"},
    {ID: "decl_sos_002", Text: "You are not alone. The Spirit is interceding for you.", ScriptureRef: "Romans 8:26", Level: 1, PackID: "pack_sos", CoreBeliefID: "cb_worth"},
    {ID: "decl_sos_003", Text: "No temptation has overtaken you that is not common to man.", ScriptureRef: "1 Corinthians 10:13", Level: 2, PackID: "pack_sos", CoreBeliefID: "cb_power"},
    // ... 15 total SOS declarations, all Level 1-2
}
```

### Purchase Fixtures

```go
var DiegoPurchaseHistory = []PurchaseReceipt{
    {PackID: "pack_marriage", TransactionID: "txn_001", Platform: "ios", PurchaseDate: daysAgo(120)},
    {PackID: "pack_armor", TransactionID: "txn_002", Platform: "ios", PurchaseDate: daysAgo(90)},
    {PackID: "pack_purity", TransactionID: "txn_003", Platform: "ios", PurchaseDate: daysAgo(30)},
}
```
