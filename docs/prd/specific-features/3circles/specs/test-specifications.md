# Three Circles -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Acceptance Criteria Source:** `specs/acceptance-criteria.md` (TC-CS-001 through TC-NFR-024)
**Feature Flag:** `feature.3circles`

All test names reference acceptance criteria using the format `TestThreeCircles_{AC_ID}_{Behavior}`.

---

## 1. Unit Tests (60-70%)

**Location:** `api/internal/domain/threecircles/*_test.go`

### 1.1 Circle Set Management Tests

```
TestThreeCircles_TC_CS_001_CreateCircleSet
  Given a valid name, recoveryArea, and frameworkPreference
  When creating a circle set
  Then set is created with status=draft, versionNumber=1, and all fields populated

TestThreeCircles_TC_CS_002_DefaultDraftStatus
  Given a create request with no explicit status
  When creating a circle set
  Then status defaults to "draft"

TestThreeCircles_TC_CS_004_MultipleSetsAllowed
  Given a user with 2 existing circle sets
  When creating a third circle set for a different recovery area
  Then set is created successfully (no limit on set count)

TestThreeCircles_TC_CS_005_IndependentCircles
  Given a user with 2 circle sets for different recovery areas
  When adding an item to set A's inner circle
  Then set B's inner circle is unchanged

TestThreeCircles_TC_CS_015_CommitDraftToActive
  Given a draft circle set with at least 1 inner circle item
  When committing the set
  Then status transitions to "active" and committedAt is set

TestThreeCircles_TC_CS_016_CommitFailsZeroInner
  Given a draft circle set with zero inner circle items
  When attempting to commit
  Then returns validation error "inner circle requires at least one behavior to commit"

TestThreeCircles_TC_CS_018_CommitIdempotent
  Given an already active circle set
  When committing again
  Then operation succeeds (no error, updates committedAt)

TestThreeCircles_TC_CS_019_ImmutableCreatedAt
  Given a circle set created at T1
  When updating the set at T2
  Then createdAt remains T1, modifiedAt updates to T2

TestThreeCircles_TC_CS_021_NameMaxLength
  Given a set name with 101 characters
  When creating a circle set
  Then returns validation error pointing to /name

TestThreeCircles_TC_CS_022_InvalidRecoveryArea
  Given an invalid recoveryArea value "invalid-area"
  When creating a circle set
  Then returns validation error pointing to /recoveryArea

TestThreeCircles_TC_CS_013_SoftDelete
  Given an active circle set
  When deleting the set
  Then status becomes "archived" and set is not returned in default list queries

TestThreeCircles_TC_CS_025_TenantIsolation
  Given two users in different tenants with circle sets
  When user A queries circle sets
  Then only user A's sets within user A's tenant are returned
```

### 1.2 Circle Item Management Tests

```
TestThreeCircles_TC_CI_001_AddItem
  Given a circle set
  When adding an item with circle=inner, behaviorName="Viewing pornography"
  Then item is created with auto-generated itemId matching pattern 3c_item_{alphanumeric}

TestThreeCircles_TC_CI_002_AddItemCreatesVersion
  Given a circle set at version 3
  When adding an item
  Then version increments to 4 and a version snapshot is created

TestThreeCircles_TC_CI_003_BehaviorNameRequired
  Given a create item request with no behaviorName
  When posting to add item
  Then returns 422 validation error pointing to /behaviorName

TestThreeCircles_TC_CI_004_BehaviorNameMaxLength
  Given a behaviorName with 201 characters
  When adding an item
  Then returns 422 validation error pointing to /behaviorName

TestThreeCircles_TC_CI_005_EmptyBehaviorName
  Given a behaviorName of ""
  When adding an item
  Then returns 422 validation error

TestThreeCircles_TC_CI_009_UncertainFlag
  Given an item with flags.uncertain=true
  When retrieving the item
  Then uncertain flag is true and item is marked for sponsor review

TestThreeCircles_TC_CI_010_SourceEnum
  Given an item with source="invalid"
  When adding an item
  Then returns 422 validation error

TestThreeCircles_TC_CI_011_UpdateItem
  Given an existing item with behaviorName="Old name"
  When updating to behaviorName="New name"
  Then item is updated and version snapshot created with changeType=itemUpdated

TestThreeCircles_TC_CI_012_UpdateDoesNotMoveCircle
  Given an inner circle item
  When updating its behaviorName
  Then item remains in inner circle (circle field unchanged)

TestThreeCircles_TC_CI_014_MoveItem
  Given an inner circle item
  When moving to targetCircle=middle with changeNote
  Then item's circle changes to middle and version snapshot records changeType=itemMoved

TestThreeCircles_TC_CI_015_MoveRequiresTargetCircle
  Given a move request with no targetCircle
  When posting to move
  Then returns 422 validation error

TestThreeCircles_TC_CI_017_MoveSameCircleNoOp
  Given an inner circle item
  When moving to targetCircle=inner
  Then returns 200 but no version snapshot is created

TestThreeCircles_TC_CI_018_InnerCircleMax20
  Given a circle set with 20 inner circle items
  When adding a 21st inner circle item
  Then returns 422 "inner circle maximum of 20 items reached"

TestThreeCircles_TC_CI_019_MiddleCircleMax50
  Given a circle set with 50 middle circle items
  When adding a 51st middle circle item
  Then returns 422 "middle circle maximum of 50 items reached"

TestThreeCircles_TC_CI_020_OuterCircleMax50
  Given a circle set with 50 outer circle items
  When adding a 51st outer circle item
  Then returns 422 "outer circle maximum of 50 items reached"

TestThreeCircles_TC_CI_021_ItemCreatedAtImmutable
  Given an item created at T1
  When updating the item at T2
  Then item.createdAt remains T1, item.modifiedAt updates to T2

TestThreeCircles_TC_CI_024_UserScopedItems
  Given user A's circle set with items
  When user B attempts to access those items
  Then returns 404 (not found, not 403)
```

### 1.3 Version History Tests

```
TestThreeCircles_TC_VH_001_VersionAutoIncrement
  Given a set at version 1
  When adding item (version 2), then updating item (version 3), then deleting item (version 4)
  Then versions increment sequentially: 1, 2, 3, 4

TestThreeCircles_TC_VH_007_RestoreVersion
  Given a set with 5 versions, currently at version 5
  When restoring to version 2
  Then circles match version 2's snapshot and a new version 6 is created

TestThreeCircles_TC_VH_008_RestoreCreatesNewVersion
  Given a set at version 5
  When restoring to version 3
  Then version 6 exists with changeType=setRestored and changeNote includes "Restored from v3"

TestThreeCircles_TC_VH_010_RestoreDraftBecomesActive
  Given a draft circle set at version 3
  When restoring to version 1
  Then set status becomes active

TestThreeCircles_TC_VH_011_VersionsImmutable
  Given a version document
  When attempting to update it
  Then update is rejected (versions are append-only)

TestThreeCircles_TC_VH_012_ChangeTypeAccurate
  Given various operations
  When adding item -> changeType=itemAdded
  When updating item -> changeType=itemUpdated
  When deleting item -> changeType=itemDeleted
  When moving item -> changeType=itemMoved
  When committing set -> changeType=setCommitted
  When restoring version -> changeType=setRestored
  When applying starter pack -> changeType=starterPackApplied
  When bulk replacing via PUT -> changeType=bulkReplace
  Then each version has the correct changeType

TestThreeCircles_TC_VH_013_ChangedItemsList
  Given an item with itemId "3c_item_x1"
  When updating that item
  Then version.changedItems contains ["3c_item_x1"]

TestThreeCircles_TC_VH_015_VersionCreatedAtImmutable
  Given a version document
  When querying that version
  Then createdAt equals changedAt and is immutable
```

### 1.4 Template Tests

```
TestThreeCircles_TC_TP_001_RecoveryAreaRequired
  Given a template list request without recoveryArea
  When calling GET /templates
  Then returns 422 "recoveryArea is required"

TestThreeCircles_TC_TP_005_UniversalTemplates
  Given templates with null frameworkVariant and some with frameworkVariant="SAA"
  When listing templates without framework filter
  Then all templates returned (universal + all framework variants)

TestThreeCircles_TC_TP_008_NoAutoPopulate
  Given a user browsing templates
  When templates are loaded
  Then no items are automatically added to the user's circles

TestThreeCircles_TC_TP_010_InactiveExcluded
  Given 10 templates where 2 have active=false
  When listing templates
  Then only 8 templates returned

TestThreeCircles_TC_TP_011_AllRecoveryAreas
  Given the template library
  When listing templates for each of the 10 recovery areas
  Then each area returns at least 1 template per circle (inner, middle, outer)
```

### 1.5 Starter Pack Tests

```
TestThreeCircles_TC_SP_005_InnerCircle3to5
  Given all starter packs in the system
  When validating each pack
  Then every pack has 3-5 inner circle items

TestThreeCircles_TC_SP_006_MiddleCircle6to10
  Given all starter packs in the system
  When validating each pack
  Then every pack has 6-10 middle circle items covering behavioral, emotional, environmental, and lifestyle categories

TestThreeCircles_TC_SP_007_OuterCircleSEEDS
  Given all starter packs in the system
  When validating each pack
  Then outer circle items span at least 3 SEEDS categories (social, education, exercise, diet, sleep)

TestThreeCircles_TC_SP_008_ApplyStarterPack
  Given an empty draft circle set and a starter pack with 4 inner, 8 middle, 5 outer items
  When applying the starter pack
  Then set contains 4 inner, 8 middle, 5 outer items, all with source=starterPack

TestThreeCircles_TC_SP_009_ApplyReplace
  Given a set with 2 existing inner items and a starter pack
  When applying with mergeStrategy=replace
  Then existing items are removed and only starter pack items remain

TestThreeCircles_TC_SP_010_ApplyMerge
  Given a set with 2 existing inner items and a starter pack with 4 inner items
  When applying with mergeStrategy=merge (default)
  Then set has 6 inner items (2 existing + 4 from pack)

TestThreeCircles_TC_SP_011_MergeNoDuplicates
  Given a set with item "Viewing pornography" and a starter pack also containing "Viewing pornography"
  When applying with mergeStrategy=merge
  Then "Viewing pornography" appears only once in inner circle

TestThreeCircles_TC_SP_012_SourceTagged
  Given a starter pack applied to a set
  When viewing the items
  Then all items from the pack have source=starterPack

TestThreeCircles_TC_SP_014_RemainsDraftAfterApply
  Given a draft circle set
  When applying a starter pack
  Then set status remains "draft" (not auto-committed)

TestThreeCircles_TC_SP_016_ReviewerFieldsPresent
  Given all starter packs
  When validating each pack
  Then clinicalReviewer and communityReviewer are both non-empty strings

TestThreeCircles_TC_SP_017_AllVariantsExist
  Given the 10 supported recovery areas
  When checking starter pack availability
  Then each area has at least secular, faith-based, and lgbtq-affirming variants
```

### 1.6 Onboarding Flow Tests

```
TestThreeCircles_TC_OB_002_DefaultGuidedMode
  Given a start onboarding request with no mode specified
  When starting the flow
  Then mode defaults to "guided"

TestThreeCircles_TC_OB_004_EmotionalScoreRange
  Given emotionalCheckinScore=6
  When starting onboarding
  Then returns 422 validation error

TestThreeCircles_TC_OB_007_ModeSwitchPreservesProgress
  Given an onboarding flow in guided mode with 3 inner circle items drafted
  When switching mode to express
  Then the 3 inner circle items are preserved and mode updates to express

TestThreeCircles_TC_OB_011_OneActiveFlowPerArea
  Given an active (incomplete) onboarding flow for sex-pornography
  When attempting to start another flow for sex-pornography
  Then returns 422 "active flow already exists for this recovery area"

TestThreeCircles_TC_OB_014_CommitNowActive
  Given a completed onboarding flow with commitOption=commitNow
  When completing the flow
  Then circle set is created with status=active

TestThreeCircles_TC_OB_015_DraftOption
  Given a completed onboarding flow with commitOption=draft
  When completing the flow
  Then circle set is created with status=draft

TestThreeCircles_TC_OB_016_DraftWithSponsorShare
  Given commitOption=draft and generateSponsorShare=true
  When completing the flow
  Then response includes sponsorShareLink and sponsorShareCode

TestThreeCircles_TC_OB_019_CompleteFailsZeroInner
  Given an onboarding flow with zero inner circle items and commitOption=commitNow
  When completing
  Then returns 422 "inner circle requires at least one behavior to commit"

TestThreeCircles_TC_OB_022_DoubleCompleteRejected
  Given an already-completed onboarding flow
  When attempting to complete again
  Then returns 422 "flow already completed"

TestThreeCircles_TC_OB_023_GuidedSequence
  Given guided mode
  When following the flow
  Then steps enforce order: recoveryArea -> framework -> innerCircle -> outerCircle -> middleCircle -> review

TestThreeCircles_TC_OB_025_StarterPackMode
  Given starterPack mode with a selected pack
  When progressing through the flow
  Then starter pack is applied and user enters review/edit state
```

### 1.7 Guardrail Tests

```
TestThreeCircles_TC_GR_001_VagueDefinitionAdvisory
  Given an item with behaviorName "Be better" (2 words)
  When adding the item
  Then item is saved AND response meta.guardrails includes specificity advisory

TestThreeCircles_TC_GR_002_VagueKeywordAdvisory
  Given an item with behaviorName "Stop being bad"
  When adding the item
  Then item is saved AND response meta.guardrails includes vague keyword advisory

TestThreeCircles_TC_GR_003_AdvisoriesNonBlocking
  Given an item triggering guardrail advisories
  When adding the item
  Then returns 201 (not 422) with item saved

TestThreeCircles_TC_GR_004_InnerCircleOverloadNudge
  Given a circle set with 8 inner circle items
  When adding a 9th inner circle item
  Then item is saved AND response meta.guardrails includes overload advisory

TestThreeCircles_TC_GR_005_OverloadSoftVsHard
  Given a circle set with 20 inner circle items (at hard limit)
  When adding a 21st item
  Then returns 422 (hard block, not advisory)

TestThreeCircles_TC_GR_006_MiddleCircleDepthNudge
  Given a circle set with 2 middle circle items
  When committing the set
  Then commit succeeds AND response meta.guardrails includes middle circle depth advisory

TestThreeCircles_TC_GR_007_IsolationNudge
  Given a circle set with no sponsor shares
  When committing
  Then commit succeeds AND response meta.guardrails includes isolation advisory

TestThreeCircles_TC_GR_010_GuardrailsInMeta
  Given any guardrail trigger condition
  When the operation completes
  Then meta.guardrails is an array of advisory objects with type, message, suggestion

TestThreeCircles_TC_GR_011_GuardrailAdvisoryFormat
  Given a guardrail advisory
  When inspecting the advisory object
  Then it contains type (string), message (string), and optional suggestion (string)

TestThreeCircles_TC_GR_012_TraumaInformedLanguage
  Given all guardrail advisory messages
  When checking content
  Then no message contains "failure", "clean", "dirty", "weakness", "addict", "should", "must"
```

### 1.8 Sponsor Review Tests

```
TestThreeCircles_TC_SR_001_GenerateShareCode
  Given a circle set
  When generating a share
  Then shareCode matches pattern ^[A-Z0-9]{8}$ and shareLink is a valid URL

TestThreeCircles_TC_SR_002_ExpiresInOptions
  Given expiresIn="24h"
  When generating a share
  Then expiresAt is approximately 24 hours from now

TestThreeCircles_TC_SR_007_ExpiredShare410
  Given a share with expiresAt in the past
  When accessing via share code
  Then returns 410 Gone

TestThreeCircles_TC_SR_010_CommentFields
  Given a comment with text exceeding 1000 chars
  When posting the comment
  Then returns 422 validation error

TestThreeCircles_TC_SR_013_ViewOnlyNoComment
  Given a share with permissions=[view] (no comment)
  When attempting to add a comment
  Then returns 403

TestThreeCircles_TC_SR_019_ShareCodeUnique
  Given 1000 generated share codes
  When checking for duplicates
  Then all codes are unique
```

### 1.9 Pattern Analysis Tests

```
TestThreeCircles_TC_PV_006_SummaryStats
  Given 30 days of timeline data: 20 outer, 6 middle, 2 inner, 2 no-checkin
  When requesting timeline for 30d period
  Then summary shows outerDays=20, middleDays=6, innerDays=2, noCheckinDays=2

TestThreeCircles_TC_PV_008_NoCheckinCalculation
  Given a 30-day period with 25 check-in entries
  When computing summary
  Then noCheckinDays = 30 - 25 = 5

TestThreeCircles_TC_DA_002_ThresholdTrigger
  Given 3 middle circle days in the last 7 days
  When drift detection runs
  Then a drift alert is generated

TestThreeCircles_TC_DA_003_BelowThresholdNoAlert
  Given 2 middle circle days in the last 7 days
  When drift detection runs
  Then no drift alert is generated

TestThreeCircles_TC_DA_004_OneTimePerEpisode
  Given a drift alert already exists for a 7-day window
  When a 4th middle circle day occurs in the same window
  Then no additional alert is created

TestThreeCircles_TC_IN_002_MinimumDataThreshold
  Given a user with 13 days of check-in data
  When requesting insights
  Then returns empty data array with meta.minimumDataDays=14

TestThreeCircles_TC_IN_009_NoShamingCorrelations
  Given insight generation with various correlation data
  When generating insights
  Then no insight text contains personal names, relationship references, or language that could induce shame

TestThreeCircles_TC_IN_018_DeterministicCalculations
  Given the same input data set
  When running pattern analysis twice
  Then identical insights are produced
```

---

## 2. Integration Tests (20%)

**Location:** `api/test/integration/threecircles/`

### 2.1 Circle Set Repository Tests

```
TestThreeCircles_Integration_TC_CS_006_ListSetsWithPagination
  Given a user with 15 circle sets
  When listing with limit=5
  Then returns 5 sets with a cursor for the next page
  When using the cursor for page 2
  Then returns the next 5 sets

TestThreeCircles_Integration_TC_CS_007_FilterByStatus
  Given a user with 2 draft, 3 active, and 1 archived set
  When listing with status=active
  Then returns exactly 3 sets

TestThreeCircles_Integration_TC_CS_009_GetSetDetail
  Given a circle set with 3 inner, 5 middle, 8 outer items and 2 sponsor comments
  When getting set detail
  Then response includes all items, last 5 version summaries, and sponsorCommentCount=2

TestThreeCircles_Integration_TC_CS_010_FullReplace
  Given a circle set with 3 inner items
  When PUT replaces with 2 inner, 4 middle, 6 outer items
  Then set now has 2 inner, 4 middle, 6 outer and a new version exists

TestThreeCircles_Integration_TC_CS_011_PartialUpdateNoVersion
  Given a circle set at version 5
  When PATCH updates only the name
  Then version remains 5 (no snapshot created)
```

### 2.2 Version History Repository Tests

```
TestThreeCircles_Integration_TC_VH_002_ListVersions
  Given a set with 10 versions
  When listing versions with limit=5
  Then returns 5 versions in reverse chronological order with cursor

TestThreeCircles_Integration_TC_VH_004_GetVersionSnapshot
  Given a set at version 5 where version 3 had 2 inner, 3 middle, 4 outer items
  When getting version v3
  Then snapshot contains exactly those items

TestThreeCircles_Integration_TC_VH_007_RestoreVersion
  Given a set at version 5, version 2 had 1 inner, 2 middle, 3 outer
  When restoring to v2
  Then current circles match v2 snapshot and version 6 created with changeType=setRestored
```

### 2.3 Onboarding Repository Tests

```
TestThreeCircles_Integration_TC_OB_009_AutoSaveProgress
  Given an onboarding flow at step innerCircle with 3 items drafted
  When updating to step outerCircle with 2 outer items
  Then flow shows currentStep=outerCircle and progress includes both inner and outer items

TestThreeCircles_Integration_TC_OB_010_ResumeIncompleteFlow
  Given a user who started onboarding, progressed to middleCircle, then disconnected
  When querying for active flows
  Then flow is found with all saved progress intact

TestThreeCircles_Integration_TC_OB_012_CompleteOnboarding
  Given a completed onboarding flow with 3 inner, 5 middle, 8 outer items
  When completing with commitOption=commitNow
  Then circle set exists with status=active, 3 inner, 5 middle, 8 outer items, version 1
```

### 2.4 Sponsor Review Repository Tests

```
TestThreeCircles_Integration_TC_SR_005_PublicViewNoAuth
  Given a shared circle set with shareCode
  When GET /share/{shareCode} with no auth header
  Then returns 200 with circle items

TestThreeCircles_Integration_TC_SR_009_CommentNoAuth
  Given a shared circle set with comment permission
  When POST /share/{shareCode}/comments with no auth header
  Then comment is created successfully

TestThreeCircles_Integration_TC_SR_014_OwnerViewComments
  Given 5 sponsor comments on a circle set
  When the owner GET /sets/{setId}/comments
  Then returns all 5 comments with pagination
```

### 2.5 Pattern Timeline Repository Tests

```
TestThreeCircles_Integration_TC_PV_002_PeriodOptions
  Given 365 days of timeline data
  When requesting period=7d, then 30d, then 90d, then 1y, then all
  Then each period returns the correct date range

TestThreeCircles_Integration_TC_PV_003_CustomDateRange
  Given timeline data from 2026-01-01 to 2026-12-31
  When requesting startDate=2026-03-01, endDate=2026-03-31
  Then returns only March entries

TestThreeCircles_Integration_AP_TC_22_TimelineQuery
  Given 30 days of timeline data for a set
  When querying { userId, setId, date: { $gte: 30daysAgo } }
  Then returns exactly the correct timeline entries sorted by date

TestThreeCircles_Integration_AP_TC_23_CircleCountAggregation
  Given 30 timeline entries: 20 outer, 7 middle, 3 inner
  When running circle count aggregation
  Then returns { outer: 20, middle: 7, inner: 3 }

TestThreeCircles_Integration_AP_TC_25_DriftDetectionQuery
  Given timeline entries with middle circle on 3 of the last 7 days
  When running drift detection query
  Then count returns 3 (triggers drift alert)
```

### 2.6 Insight and Drift Alert Repository Tests

```
TestThreeCircles_Integration_TC_IN_010_DismissInsight
  Given an active insight
  When dismissing the insight
  Then insight.dismissed=true and dismissedAt is set
  When querying active insights
  Then dismissed insight is excluded

TestThreeCircles_Integration_TC_DA_007_DismissAlert
  Given an active drift alert
  When dismissing the alert
  Then alert.dismissed=true and returns 204
  When querying active alerts
  Then dismissed alert is excluded
```

### 2.7 Quarterly Review Repository Tests

```
TestThreeCircles_Integration_TC_QR_001_ListReviews
  Given 3 completed and 1 incomplete reviews for a set
  When listing reviews
  Then returns 4 reviews with meta.nextReviewDue from the most recent completed review

TestThreeCircles_Integration_TC_QR_008_CompleteReview
  Given an incomplete review with reflections and changesApplied
  When completing the review
  Then review.completed=true, completedAt set, nextReviewDue set to 90 days out
  And parent set's lastReviewedAt and nextReviewDue are updated
```

### 2.8 Cache Integration Tests

```
TestThreeCircles_Integration_Cache_SetDetail
  Given a cached circle set detail
  When adding an item to the set
  Then cache is invalidated and next read returns fresh data

TestThreeCircles_Integration_Cache_TemplateList
  Given cached templates for sex-pornography/inner
  When templates are unchanged for 1 hour
  Then cache still serves (TTL-based)

TestThreeCircles_Integration_Cache_TimelineData
  Given cached timeline data
  When a new check-in adds a timeline entry
  Then cache is invalidated and next read includes the new entry

TestThreeCircles_Integration_Cache_GracefulDegradation
  Given Valkey is unavailable
  When requesting any data
  Then falls through to MongoDB without error
```

---

## 3. Contract Tests

**Location:** `api/test/contract/threecircles/`

### 3.1 OpenAPI Spec Conformance

```
TestThreeCircles_Contract_ListCircleSets_200
  Given an authenticated user with circle sets
  When GET /tools/three-circles/sets
  Then response matches CircleSetListResponse schema

TestThreeCircles_Contract_CreateCircleSet_201
  Given a valid CreateCircleSetRequest
  When POST /tools/three-circles/sets
  Then response matches CircleSetResponse schema with 201 status

TestThreeCircles_Contract_GetCircleSetDetail_200
  Given an existing set
  When GET /tools/three-circles/sets/{setId}
  Then response matches CircleSetDetailResponse schema

TestThreeCircles_Contract_ReplaceCircleSet_200
  Given a valid ReplaceCircleSetRequest
  When PUT /tools/three-circles/sets/{setId}
  Then response matches CircleSetResponse schema

TestThreeCircles_Contract_UpdateCircleSet_200
  Given a valid JSON Merge Patch body
  When PATCH /tools/three-circles/sets/{setId}
  Then response matches CircleSetResponse schema

TestThreeCircles_Contract_DeleteCircleSet_204
  Given an existing set
  When DELETE /tools/three-circles/sets/{setId}
  Then returns 204 with no body

TestThreeCircles_Contract_CommitCircleSet_200
  Given a draft set with items
  When POST /tools/three-circles/sets/{setId}/commit
  Then response matches CircleSetResponse schema with status=active

TestThreeCircles_Contract_AddCircleItem_201
  Given a valid CreateCircleItemRequest
  When POST /tools/three-circles/sets/{setId}/items
  Then response matches CircleItemResponse schema with 201 status

TestThreeCircles_Contract_UpdateCircleItem_200
  Given a valid UpdateCircleItemRequest
  When PUT /tools/three-circles/sets/{setId}/items/{itemId}
  Then response matches CircleItemResponse schema

TestThreeCircles_Contract_DeleteCircleItem_204
  Given an existing item
  When DELETE /tools/three-circles/sets/{setId}/items/{itemId}
  Then returns 204

TestThreeCircles_Contract_MoveCircleItem_200
  Given a valid move request with targetCircle
  When POST /tools/three-circles/sets/{setId}/items/{itemId}/move
  Then response matches CircleItemResponse schema with updated circle

TestThreeCircles_Contract_ListVersions_200
  Given a set with versions
  When GET /tools/three-circles/sets/{setId}/versions
  Then response matches VersionListResponse schema

TestThreeCircles_Contract_GetVersion_200
  Given a specific version
  When GET /tools/three-circles/sets/{setId}/versions/v3
  Then response matches CircleSetVersionResponse schema

TestThreeCircles_Contract_RestoreVersion_200
  Given a previous version
  When POST /tools/three-circles/sets/{setId}/versions/v2/restore
  Then response matches CircleSetResponse schema

TestThreeCircles_Contract_ListTemplates_200
  Given recoveryArea=sex-pornography
  When GET /tools/three-circles/templates?recoveryArea=sex-pornography
  Then response matches TemplateListResponse schema

TestThreeCircles_Contract_GetTemplate_200
  Given a templateId
  When GET /tools/three-circles/templates/{templateId}
  Then response matches TemplateResponse schema

TestThreeCircles_Contract_ListStarterPacks_200
  Given recoveryArea=sex-pornography
  When GET /tools/three-circles/starter-packs?recoveryArea=sex-pornography
  Then response matches StarterPackListResponse schema

TestThreeCircles_Contract_GetStarterPack_200
  Given a packId
  When GET /tools/three-circles/starter-packs/{packId}
  Then response matches StarterPackResponse schema

TestThreeCircles_Contract_ApplyStarterPack_200
  Given a valid apply request
  When POST /tools/three-circles/sets/{setId}/apply-starter-pack
  Then response matches CircleSetResponse schema

TestThreeCircles_Contract_StartOnboarding_201
  Given a valid start request
  When POST /tools/three-circles/onboarding/start
  Then response matches OnboardingFlowResponse schema with 201

TestThreeCircles_Contract_UpdateOnboarding_200
  Given a valid PATCH body
  When PATCH /tools/three-circles/onboarding/{flowId}
  Then response matches OnboardingFlowResponse schema

TestThreeCircles_Contract_CompleteOnboarding_201
  Given a valid complete request
  When POST /tools/three-circles/onboarding/{flowId}/complete
  Then response includes circleSet and optional sponsorShareLink

TestThreeCircles_Contract_ShareCircleSet_201
  Given a share request
  When POST /tools/three-circles/sets/{setId}/share
  Then response includes shareCode, shareLink, expiresAt, permissions

TestThreeCircles_Contract_ViewSharedCircleSet_200
  Given a valid share code
  When GET /tools/three-circles/share/{shareCode}
  Then response includes circle items and meta.readOnly=true

TestThreeCircles_Contract_AddSponsorComment_201
  Given a valid comment
  When POST /tools/three-circles/share/{shareCode}/comments
  Then response matches SponsorCommentResponse schema

TestThreeCircles_Contract_GetComments_200
  Given a set with comments
  When GET /tools/three-circles/sets/{setId}/comments
  Then response matches CommentListResponse schema

TestThreeCircles_Contract_GetTimeline_200
  Given timeline data
  When GET /tools/three-circles/patterns/timeline?setId={setId}
  Then response matches TimelineResponse schema

TestThreeCircles_Contract_GetInsights_200
  Given sufficient data
  When GET /tools/three-circles/patterns/insights?setId={setId}
  Then response matches InsightListResponse schema

TestThreeCircles_Contract_GetSummary_200
  Given a valid request
  When GET /tools/three-circles/patterns/summary?setId={setId}&period=month
  Then response matches SummaryResponse schema

TestThreeCircles_Contract_GetDriftAlerts_200
  Given drift alert data
  When GET /tools/three-circles/patterns/drift-alerts?setId={setId}
  Then response matches DriftAlertListResponse schema

TestThreeCircles_Contract_DismissDriftAlert_204
  Given an active alert
  When POST /tools/three-circles/patterns/drift-alerts/{alertId}/dismiss
  Then returns 204

TestThreeCircles_Contract_ListReviews_200
  Given review data
  When GET /tools/three-circles/reviews?setId={setId}
  Then response matches ReviewListResponse schema

TestThreeCircles_Contract_StartReview_201
  Given a valid setId
  When POST /tools/three-circles/reviews
  Then response matches ReviewResponse schema with 201

TestThreeCircles_Contract_UpdateReview_200
  Given a valid PATCH body
  When PATCH /tools/three-circles/reviews/{reviewId}
  Then response matches ReviewResponse schema

TestThreeCircles_Contract_CompleteReview_200
  Given a valid complete request
  When POST /tools/three-circles/reviews/{reviewId}/complete
  Then response matches ReviewResponse schema with completed=true
```

### 3.2 Error Response Conformance

```
TestThreeCircles_Contract_FeatureDisabled_404
  Given feature.3circles is disabled
  When calling any endpoint
  Then returns 404 matching ErrorResponse schema with code rr:0x000B0404

TestThreeCircles_Contract_Unauthorized_401
  Given no Bearer token
  When calling any authenticated endpoint
  Then returns 401 matching ErrorResponse schema with code rr:0x000B0401

TestThreeCircles_Contract_NotFound_404
  Given a non-existent setId
  When GET /tools/three-circles/sets/{setId}
  Then returns 404 matching ErrorResponse schema

TestThreeCircles_Contract_ValidationError_422
  Given invalid request body (empty behaviorName)
  When POST /tools/three-circles/sets/{setId}/items
  Then returns 422 matching ErrorResponse schema with source.pointer

TestThreeCircles_Contract_ExpiredShare_410
  Given an expired shareCode
  When GET /tools/three-circles/share/{shareCode}
  Then returns 410 matching ErrorResponse schema
```

---

## 4. E2E Tests (10%)

**Location:** `api/test/e2e/threecircles/`

### 4.1 Persona: Rachel (Day 5, Starter Pack)

```
TestThreeCircles_E2E_Rachel_StarterPackOnboarding
  Given Rachel is a new user (Day 5), sex-pornography recovery, no prior experience
  When she starts onboarding with emotionalCheckinScore=2 (low), mode=starterPack
  And selects recovery area sex-pornography
  And selects a secular starter pack
  And reviews the pack items (verifying 3-5 inner, 6-10 middle, SEEDS outer)
  And removes 1 irrelevant middle circle item
  And adds 1 custom inner circle item "Masturbation"
  And commits with commitOption=draft and generateSponsorShare=true
  Then circle set is created with status=draft
  And sponsor share link and code are generated
  And all starter pack items have source=starterPack
  And the custom item has source=user
  And starterPackId is recorded on the set
```

### 4.2 Persona: James (2yr SAA, Express Mode)

```
TestThreeCircles_E2E_James_ExpressMode
  Given James is an experienced user (2 years SAA), already has paper circles
  When he starts onboarding with mode=express
  And selects recovery area sex-pornography, framework SAA
  And rapidly adds 4 inner circle items from his paper worksheet
  And adds 12 middle circle items across behavioral, emotional, environmental categories
  And adds 8 outer circle items across SEEDS categories
  And commits with commitOption=commitNow
  Then circle set is created with status=active, committedAt set
  And version 1 exists
  And all items have source=user
  And calendar activity dual-write records the commit
```

### 4.3 Persona: Maria (6mo SLAA+codependency, Guided, Multi-Set)

```
TestThreeCircles_E2E_Maria_GuidedMultiSet
  Given Maria is 6 months into recovery, SLAA + codependency (2 recovery areas)
  When she starts onboarding with mode=guided for love-relationships area
  And completes the full guided flow with reflection prompts
  And accepts 3 template items for inner circle (source=template)
  And adds 2 custom middle circle items (source=user)
  And uses the outer circle SEEDS framework
  And commits with commitOption=commitNow
  Then first set (love-relationships) is created and active
  When she starts a second onboarding for a custom "other" recovery area (codependency)
  And builds a separate set
  Then she has 2 independent active circle sets
  And each set has independent items and version histories
```

### 4.4 Full Lifecycle: Edit, Version, Sponsor Review

```
TestThreeCircles_E2E_FullLifecycle
  Given an active circle set with 3 inner, 5 middle, 8 outer items at version 1
  When adding a middle circle item "Staying up late on phone"
  Then version increments to 2
  When moving an item from middle to inner circle with changeNote
  Then version increments to 3 and changeType=itemMoved
  When updating an item's specificityDetail
  Then version increments to 4
  When sharing with sponsor (expiresIn=7d, permissions=[view, comment])
  Then shareCode and shareLink are generated
  When sponsor views shared circles via public endpoint (no auth)
  Then sees all items with notes
  When sponsor adds a comment on an inner circle item
  Then comment is created and user sees sponsorCommentCount increment
  When user gets comments via authenticated endpoint
  Then sponsor comment is visible
  When restoring to version 2
  Then version 5 is created with changeType=setRestored and circles match v2 snapshot
  When comparing version 3 and version 5
  Then both full snapshots are retrievable
```

### 4.5 Pattern Visualization Flow

```
TestThreeCircles_E2E_PatternVisualization
  Given a user with 30 days of check-in data (20 outer, 7 middle, 3 inner)
  When requesting 30d timeline
  Then timeline shows 30 entries with correct circle colors and summary stats
  And noCheckinDays = 0 (all 30 days checked in)
  When requesting pattern summary for month
  Then summary includes circle distribution, mood trend, and framing message
  And framing message uses descriptive language (no percentages)
  Given 14+ days of data with middle circle clustering on Fridays
  When requesting insights
  Then at least one dayOfWeek insight detects the Friday pattern
  And insight includes constructive actionSuggestion
  Given 3 middle circle days in the last 7 days
  When drift detection runs
  Then drift alert is generated with gentle message
  When user dismisses the alert
  Then alert is dismissed and won't reappear for this episode
```

### 4.6 Quarterly Review Flow

```
TestThreeCircles_E2E_QuarterlyReview
  Given an active circle set committed 90 days ago
  When checking nextReviewDue
  Then nextReviewDue is today or past
  When starting a quarterly review
  Then review is created with currentStep=innerReview
  When progressing through inner, outer, middle review with reflections
  And adding 1 new outer circle item during the review
  Then item is added and version snapshot created with changeType=reviewChange
  When completing the review with summary text
  Then review.completed=true, nextReviewDue set 90 days out
  And parent set's lastReviewedAt and nextReviewDue are updated
  And calendar activity dual-write records the review completion
```

### 4.7 Feature Flag Gating

```
TestThreeCircles_E2E_FeatureFlagDisabled
  Given feature.3circles is disabled for the user's tenant
  When calling GET /tools/three-circles/sets
  Then returns 404 with code rr:0x000B0404 and title "Feature Not Available"
  When calling POST /tools/three-circles/onboarding/start
  Then returns 404 with same error
  When calling GET /tools/three-circles/templates?recoveryArea=sex-pornography
  Then returns 404 with same error
  When calling GET /tools/three-circles/patterns/timeline?setId=any
  Then returns 404 with same error
```

### 4.8 Offline Resilience

```
TestThreeCircles_E2E_OfflineOnboarding
  Given a user starts onboarding while online
  And progresses to innerCircle step
  When device goes offline
  And user continues adding items and progressing through steps
  Then all progress is saved locally
  When device comes back online
  Then progress syncs to server without data loss

TestThreeCircles_E2E_OfflineCircleEdit
  Given a user with an active circle set cached locally
  When device goes offline
  And user adds an item, updates an item, and moves an item
  Then changes are queued locally
  When device comes back online
  Then changes sync and version history reflects all three changes
```

---

## 5. Test Personas

### Rachel (Day 5, Starter Pack)
- **Profile:** New to recovery, sex/pornography addiction, no prior 12-step experience
- **Emotional state:** Low (score 2), overwhelmed by the blank page
- **Onboarding mode:** Starter Pack (needs pre-built starting point)
- **Recovery area:** sex-pornography
- **Framework:** None selected
- **Expected behavior:** Accepts pack wholesale, removes 1-2 irrelevant items, adds 1 personal item, saves as draft for sponsor review

### James (2yr SAA, Express)
- **Profile:** 2 years in SAA, has detailed paper circles, experienced with recovery concepts
- **Emotional state:** Good (score 4), confident and ready
- **Onboarding mode:** Express (minimal friction, fast data entry)
- **Recovery area:** sex-pornography
- **Framework:** SAA
- **Expected behavior:** Enters all items manually, commits immediately, no templates needed

### Maria (6mo SLAA+codependency, Guided, Multi-Set)
- **Profile:** 6 months in recovery, love addiction + codependency (co-occurring), SLAA framework
- **Emotional state:** Okay (score 3)
- **Onboarding mode:** Guided (wants full explanations and reflection prompts)
- **Recovery area:** love-relationships + other (codependency)
- **Framework:** SLAA
- **Expected behavior:** Creates two independent circle sets, uses templates as suggestions, takes time with guided flow, uses sponsor review

---

## 6. Coverage Targets

| Layer | Target | Critical Paths (100%) |
|-------|--------|----------------------|
| Unit | >= 80% | Commit validation (zero-inner check), version auto-increment, guardrail detection, drift alert threshold (3/7), insight minimum data (14 days), share code uniqueness, merge strategy (duplicates), circle item limits (20/50/50) |
| Integration | >= 80% | All 32 access patterns, cursor pagination, cache invalidation, calendar dual-write |
| Contract | 100% of endpoints | All 36 endpoint contracts, all error responses, feature flag gating |
| E2E | All 3 persona journeys + lifecycle | Rachel starter pack, James express, Maria guided multi-set, full edit/version/share lifecycle, pattern visualization, quarterly review |
