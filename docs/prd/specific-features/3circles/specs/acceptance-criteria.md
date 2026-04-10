# Three Circles -- Consolidated Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Traces to:** `prd.md` (PRD 1, PRD 2, PRD 3), `specs/openapi.yaml`, `specs/mongodb-schema.md`
**Feature Flag:** `feature.3circles`
**Error Code Prefix:** `rr:0x000B`

---

## Naming Convention

All acceptance criteria follow the format `TC-{Domain}-{N}` where:
- **TC** = Three Circles (feature prefix)
- **Domain** = CS (Circle Sets), CI (Circle Items), VH (Version History), TP (Templates), SP (Starter Packs), OB (Onboarding), SR (Sponsor Review), PV (Pattern Visualization), DA (Drift Alerts), IN (Insights), QR (Quarterly Review), GR (Guardrails)
- **{N}** = Sequential number within domain

Test names follow the format `TestThreeCircles_{AC_ID}_{Description}`.

---

## 1. Circle Sets (TC-CS)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-CS-001 | A user can create a circle set with a name (max 100 chars), recovery area (required, from RecoveryArea enum), and optional framework preference | P0 | `TestThreeCircles_TC_CS_001_CreateCircleSet` |
| TC-CS-002 | A new circle set defaults to `draft` status unless explicitly set to `active` | P0 | `TestThreeCircles_TC_CS_002_DefaultDraftStatus` |
| TC-CS-003 | Creating a circle set returns 201 with Location header pointing to the new set | P0 | `TestThreeCircles_TC_CS_003_CreateReturns201WithLocation` |
| TC-CS-004 | A user can have multiple circle sets (co-occurring recovery areas) | P0 | `TestThreeCircles_TC_CS_004_MultipleSetsAllowed` |
| TC-CS-005 | Each circle set has independent inner, middle, and outer circles | P0 | `TestThreeCircles_TC_CS_005_IndependentCircles` |
| TC-CS-006 | GET `/sets` returns all sets for the authenticated user with cursor-based pagination | P0 | `TestThreeCircles_TC_CS_006_ListSetsWithPagination` |
| TC-CS-007 | GET `/sets` supports filtering by `status` (draft/active/archived) | P0 | `TestThreeCircles_TC_CS_007_FilterByStatus` |
| TC-CS-008 | GET `/sets` supports filtering by `recoveryArea` | P0 | `TestThreeCircles_TC_CS_008_FilterByRecoveryArea` |
| TC-CS-009 | GET `/sets/{setId}` returns full set detail including items, version history summary (last 5), and sponsor comment count | P0 | `TestThreeCircles_TC_CS_009_GetSetDetail` |
| TC-CS-010 | PUT `/sets/{setId}` replaces the entire circle set (all three circles required) and creates a version snapshot | P0 | `TestThreeCircles_TC_CS_010_FullReplace` |
| TC-CS-011 | PATCH `/sets/{setId}` updates specific fields (name, framework) via JSON Merge Patch without creating a version if circles unchanged | P0 | `TestThreeCircles_TC_CS_011_PartialUpdateNoVersion` |
| TC-CS-012 | PATCH `/sets/{setId}` creates a version snapshot when circle contents change | P0 | `TestThreeCircles_TC_CS_012_PartialUpdateWithVersion` |
| TC-CS-013 | DELETE `/sets/{setId}` soft-deletes (sets status to `archived`) and returns 204 | P0 | `TestThreeCircles_TC_CS_013_SoftDelete` |
| TC-CS-014 | Archived sets retain version history and are not visible in default list (status filter required) | P0 | `TestThreeCircles_TC_CS_014_ArchivedRetainHistory` |
| TC-CS-015 | POST `/sets/{setId}/commit` transitions a draft set to active; returns 200 | P0 | `TestThreeCircles_TC_CS_015_CommitDraftToActive` |
| TC-CS-016 | Commit fails (422) if inner circle has zero items | P0 | `TestThreeCircles_TC_CS_016_CommitFailsZeroInner` |
| TC-CS-017 | Commit accepts an optional `changeNote` (max 500 chars) | P1 | `TestThreeCircles_TC_CS_017_CommitWithChangeNote` |
| TC-CS-018 | A set that is already active can be committed again (no-op or updates committedAt) | P1 | `TestThreeCircles_TC_CS_018_CommitIdempotent` |
| TC-CS-019 | `createdAt` on circle set is immutable and never modified on update (FR2.7) | P0 | `TestThreeCircles_TC_CS_019_ImmutableCreatedAt` |
| TC-CS-020 | `modifiedAt` updates on every write operation | P0 | `TestThreeCircles_TC_CS_020_ModifiedAtUpdates` |
| TC-CS-021 | Set name exceeding 100 chars returns 422 with source pointer `/name` | P0 | `TestThreeCircles_TC_CS_021_NameMaxLength` |
| TC-CS-022 | Invalid `recoveryArea` enum value returns 422 with source pointer `/recoveryArea` | P0 | `TestThreeCircles_TC_CS_022_InvalidRecoveryArea` |
| TC-CS-023 | Response envelope follows `{ data, links, meta }` format per Siemens REST API Guidelines | P0 | `TestThreeCircles_TC_CS_023_ResponseEnvelope` |
| TC-CS-024 | Error responses follow `{ errors: [...] }` format with `rr:0x000B` prefix codes | P0 | `TestThreeCircles_TC_CS_024_ErrorEnvelope` |
| TC-CS-025 | Each set carries `tenantId`; all queries enforce tenant isolation | P0 | `TestThreeCircles_TC_CS_025_TenantIsolation` |

---

## 2. Circle Items (TC-CI)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-CI-001 | POST `/sets/{setId}/items` adds an item to a specified circle (inner/middle/outer) and returns 201 with Location | P0 | `TestThreeCircles_TC_CI_001_AddItem` |
| TC-CI-002 | Adding an item creates a version snapshot | P0 | `TestThreeCircles_TC_CI_002_AddItemCreatesVersion` |
| TC-CI-003 | `behaviorName` is required (min 1 char, max 200 chars) | P0 | `TestThreeCircles_TC_CI_003_BehaviorNameRequired` |
| TC-CI-004 | `behaviorName` exceeding 200 chars returns 422 with source pointer `/behaviorName` | P0 | `TestThreeCircles_TC_CI_004_BehaviorNameMaxLength` |
| TC-CI-005 | Empty `behaviorName` returns 422 | P0 | `TestThreeCircles_TC_CI_005_EmptyBehaviorName` |
| TC-CI-006 | `notes` field is optional, max 1000 chars | P1 | `TestThreeCircles_TC_CI_006_NotesOptional` |
| TC-CI-007 | `specificityDetail` field is optional, max 500 chars | P1 | `TestThreeCircles_TC_CI_007_SpecificityOptional` |
| TC-CI-008 | `category` field is optional, max 50 chars | P1 | `TestThreeCircles_TC_CI_008_CategoryOptional` |
| TC-CI-009 | `flags.uncertain` boolean defaults to false; when true, item is flagged for sponsor review | P1 | `TestThreeCircles_TC_CI_009_UncertainFlag` |
| TC-CI-010 | `source` enum must be `user`, `template`, or `starterPack` | P0 | `TestThreeCircles_TC_CI_010_SourceEnum` |
| TC-CI-011 | PUT `/sets/{setId}/items/{itemId}` updates item fields and creates a version snapshot | P0 | `TestThreeCircles_TC_CI_011_UpdateItem` |
| TC-CI-012 | Update does not change which circle the item belongs to (use move endpoint) | P0 | `TestThreeCircles_TC_CI_012_UpdateDoesNotMoveCircle` |
| TC-CI-013 | DELETE `/sets/{setId}/items/{itemId}` removes item and creates version snapshot; returns 204 | P0 | `TestThreeCircles_TC_CI_013_DeleteItem` |
| TC-CI-014 | POST `/sets/{setId}/items/{itemId}/move` moves an item to a target circle and creates version snapshot | P0 | `TestThreeCircles_TC_CI_014_MoveItem` |
| TC-CI-015 | Move requires `targetCircle` (inner/middle/outer); invalid value returns 422 | P0 | `TestThreeCircles_TC_CI_015_MoveRequiresTargetCircle` |
| TC-CI-016 | Move accepts optional `changeNote` (max 500 chars) | P1 | `TestThreeCircles_TC_CI_016_MoveWithChangeNote` |
| TC-CI-017 | Moving to the same circle the item is already in is a no-op (200, no version created) | P1 | `TestThreeCircles_TC_CI_017_MoveSameCircleNoOp` |
| TC-CI-018 | Inner circle items max out at 20; adding the 21st returns 422 | P0 | `TestThreeCircles_TC_CI_018_InnerCircleMax20` |
| TC-CI-019 | Middle circle items max out at 50; adding the 51st returns 422 | P0 | `TestThreeCircles_TC_CI_019_MiddleCircleMax50` |
| TC-CI-020 | Outer circle items max out at 50; adding the 51st returns 422 | P0 | `TestThreeCircles_TC_CI_020_OuterCircleMax50` |
| TC-CI-021 | `createdAt` on individual items is immutable (FR2.7) | P0 | `TestThreeCircles_TC_CI_021_ItemCreatedAtImmutable` |
| TC-CI-022 | `itemId` is auto-generated with pattern `3c_item_{alphanumeric}` | P0 | `TestThreeCircles_TC_CI_022_ItemIdPattern` |
| TC-CI-023 | Getting a non-existent item returns 404 | P0 | `TestThreeCircles_TC_CI_023_NonExistentItem404` |
| TC-CI-024 | Items from different users are not accessible (user scoping enforced) | P0 | `TestThreeCircles_TC_CI_024_UserScopedItems` |

---

## 3. Version History (TC-VH)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-VH-001 | Every change to circle contents creates a new version with incrementing `versionNumber` | P0 | `TestThreeCircles_TC_VH_001_VersionAutoIncrement` |
| TC-VH-002 | GET `/sets/{setId}/versions` returns version list in reverse chronological order with cursor pagination | P0 | `TestThreeCircles_TC_VH_002_ListVersions` |
| TC-VH-003 | Each version entry includes `versionNumber`, `changedAt`, `changeNote`, `innerCount`, `middleCount`, `outerCount` | P0 | `TestThreeCircles_TC_VH_003_VersionListFields` |
| TC-VH-004 | GET `/sets/{setId}/versions/{versionId}` returns full snapshot of circles at that version | P0 | `TestThreeCircles_TC_VH_004_GetVersionSnapshot` |
| TC-VH-005 | `versionId` accepts format `vN` (e.g., `v3`) or `latest` | P0 | `TestThreeCircles_TC_VH_005_VersionIdFormat` |
| TC-VH-006 | Getting a non-existent version returns 404 | P0 | `TestThreeCircles_TC_VH_006_NonExistentVersion404` |
| TC-VH-007 | POST `/sets/{setId}/versions/{versionId}/restore` restores circles to a previous version | P0 | `TestThreeCircles_TC_VH_007_RestoreVersion` |
| TC-VH-008 | Restore creates a new version (does not rewind history) | P0 | `TestThreeCircles_TC_VH_008_RestoreCreatesNewVersion` |
| TC-VH-009 | Restore accepts optional `changeNote` | P1 | `TestThreeCircles_TC_VH_009_RestoreWithChangeNote` |
| TC-VH-010 | Restore of a draft set transitions it to active status | P1 | `TestThreeCircles_TC_VH_010_RestoreDraftBecomesActive` |
| TC-VH-011 | Version documents are immutable (append-only; never updated or deleted) | P0 | `TestThreeCircles_TC_VH_011_VersionsImmutable` |
| TC-VH-012 | Version `changeType` correctly reflects the operation: `itemAdded`, `itemUpdated`, `itemDeleted`, `itemMoved`, `setCommitted`, `setRestored`, `starterPackApplied`, `bulkReplace`, `reviewChange` | P0 | `TestThreeCircles_TC_VH_012_ChangeTypeAccurate` |
| TC-VH-013 | Version `changedItems` array lists the specific item IDs affected | P1 | `TestThreeCircles_TC_VH_013_ChangedItemsList` |
| TC-VH-014 | Users can compare any two versions side by side (both version snapshots retrievable) | P1 | `TestThreeCircles_TC_VH_014_VersionComparison` |
| TC-VH-015 | `createdAt` on version documents is immutable (FR2.7) | P0 | `TestThreeCircles_TC_VH_015_VersionCreatedAtImmutable` |

---

## 4. Templates (TC-TP)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-TP-001 | GET `/templates` requires `recoveryArea` query parameter; missing returns 422 | P0 | `TestThreeCircles_TC_TP_001_RecoveryAreaRequired` |
| TC-TP-002 | Templates are returned organized by circle (inner/middle/outer) when `circle` filter is specified | P0 | `TestThreeCircles_TC_TP_002_FilterByCircle` |
| TC-TP-003 | Each template includes `templateId`, `behaviorName`, `rationale`, `specificityGuidance`, and `category` | P0 | `TestThreeCircles_TC_TP_003_TemplateFields` |
| TC-TP-004 | Templates are filterable by `framework` query parameter for framework-specific variants | P1 | `TestThreeCircles_TC_TP_004_FrameworkFilter` |
| TC-TP-005 | Templates with null `frameworkVariant` are returned for all frameworks (universal templates) | P1 | `TestThreeCircles_TC_TP_005_UniversalTemplates` |
| TC-TP-006 | GET `/templates/{templateId}` returns full template detail with rationale | P0 | `TestThreeCircles_TC_TP_006_TemplateDetail` |
| TC-TP-007 | Templates are versioned independently of the API (version field present) | P1 | `TestThreeCircles_TC_TP_007_TemplateVersioned` |
| TC-TP-008 | Templates never auto-populate user circles without explicit user action | P0 | `TestThreeCircles_TC_TP_008_NoAutoPopulate` |
| TC-TP-009 | Templates are clearly marked as suggestions (rationale field provides "why") | P0 | `TestThreeCircles_TC_TP_009_RationaleSuggestion` |
| TC-TP-010 | Inactive templates (active=false) are not returned in list responses | P0 | `TestThreeCircles_TC_TP_010_InactiveExcluded` |
| TC-TP-011 | Templates exist for all 10 supported recovery areas | P0 | `TestThreeCircles_TC_TP_011_AllRecoveryAreas` |
| TC-TP-012 | Templates are sorted by `sortOrder` within each recovery area + circle group | P1 | `TestThreeCircles_TC_TP_012_SortOrder` |

---

## 5. Starter Packs (TC-SP)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-SP-001 | GET `/starter-packs` requires `recoveryArea` parameter; missing returns 422 | P0 | `TestThreeCircles_TC_SP_001_RecoveryAreaRequired` |
| TC-SP-002 | Starter packs support `variant` filter: `secular`, `faith-based`, `lgbtq-affirming` (default: `secular`) | P0 | `TestThreeCircles_TC_SP_002_VariantFilter` |
| TC-SP-003 | List response includes `packId`, `name`, `description`, `variant`, and `itemCounts` (inner/middle/outer) | P0 | `TestThreeCircles_TC_SP_003_ListResponseFields` |
| TC-SP-004 | GET `/starter-packs/{packId}` returns full pack with all items and rationales per item | P0 | `TestThreeCircles_TC_SP_004_PackDetail` |
| TC-SP-005 | Each starter pack inner circle has 3-5 items | P0 | `TestThreeCircles_TC_SP_005_InnerCircle3to5` |
| TC-SP-006 | Each starter pack middle circle has 6-10 items covering behavioral, emotional, environmental, and lifestyle categories | P0 | `TestThreeCircles_TC_SP_006_MiddleCircle6to10` |
| TC-SP-007 | Each starter pack outer circle is SEEDS-based (social, education, exercise, diet, sleep categories represented) | P0 | `TestThreeCircles_TC_SP_007_OuterCircleSEEDS` |
| TC-SP-008 | POST `/sets/{setId}/apply-starter-pack` populates a circle set with starter pack items | P0 | `TestThreeCircles_TC_SP_008_ApplyStarterPack` |
| TC-SP-009 | Apply with `mergeStrategy=replace` clears existing items before applying | P0 | `TestThreeCircles_TC_SP_009_ApplyReplace` |
| TC-SP-010 | Apply with `mergeStrategy=merge` (default) adds pack items without removing existing items | P0 | `TestThreeCircles_TC_SP_010_ApplyMerge` |
| TC-SP-011 | Merge does not create duplicates (items with matching `behaviorName` are skipped) | P0 | `TestThreeCircles_TC_SP_011_MergeNoDuplicates` |
| TC-SP-012 | All items from starter pack are tagged with `source=starterPack` | P0 | `TestThreeCircles_TC_SP_012_SourceTagged` |
| TC-SP-013 | Applying a starter pack creates a version snapshot | P0 | `TestThreeCircles_TC_SP_013_ApplyCreatesVersion` |
| TC-SP-014 | Set remains in `draft` status after starter pack application (requires explicit commit) | P0 | `TestThreeCircles_TC_SP_014_RemainsDraftAfterApply` |
| TC-SP-015 | `starterPackId` is recorded on the circle set for 14-day check-in scheduling | P1 | `TestThreeCircles_TC_SP_015_PackIdRecorded` |
| TC-SP-016 | Each starter pack has both `clinicalReviewer` and `communityReviewer` fields populated | P0 | `TestThreeCircles_TC_SP_016_ReviewerFieldsPresent` |
| TC-SP-017 | Starter packs exist for each recovery area in at least secular, faith-based, and LGBTQ+-affirming variants | P0 | `TestThreeCircles_TC_SP_017_AllVariantsExist` |
| TC-SP-018 | Applying a non-existent pack ID returns 422 | P0 | `TestThreeCircles_TC_SP_018_InvalidPackId422` |
| TC-SP-019 | Response includes `links.apply` for each starter pack pointing to the apply endpoint | P1 | `TestThreeCircles_TC_SP_019_ApplyLink` |

---

## 6. Onboarding (TC-OB)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-OB-001 | POST `/onboarding/start` creates a new onboarding flow and returns 201 | P0 | `TestThreeCircles_TC_OB_001_StartOnboarding` |
| TC-OB-002 | Flow defaults to `guided` mode if not specified | P0 | `TestThreeCircles_TC_OB_002_DefaultGuidedMode` |
| TC-OB-003 | Flow supports three modes: `guided`, `starterPack`, `express` | P0 | `TestThreeCircles_TC_OB_003_ThreeModes` |
| TC-OB-004 | `emotionalCheckinScore` accepts 1-5; values outside range return 422 | P0 | `TestThreeCircles_TC_OB_004_EmotionalScoreRange` |
| TC-OB-005 | `emotionalCheckinScore` is optional (skippable) | P1 | `TestThreeCircles_TC_OB_005_EmotionalScoreOptional` |
| TC-OB-006 | PATCH `/onboarding/{flowId}` updates flow progress (currentStep, recoveryArea, framework, mode, progress) | P0 | `TestThreeCircles_TC_OB_006_UpdateProgress` |
| TC-OB-007 | Mode can be switched mid-flow without losing existing progress | P0 | `TestThreeCircles_TC_OB_007_ModeSwitchPreservesProgress` |
| TC-OB-008 | `currentStep` must follow the enum: `recoveryArea`, `framework`, `innerCircle`, `outerCircle`, `middleCircle`, `review` | P0 | `TestThreeCircles_TC_OB_008_ValidSteps` |
| TC-OB-009 | Progress auto-saves on every PATCH (exit and resume supported) | P0 | `TestThreeCircles_TC_OB_009_AutoSaveProgress` |
| TC-OB-010 | A user can resume an incomplete flow (find active flow, restore state) | P0 | `TestThreeCircles_TC_OB_010_ResumeIncompleteFlow` |
| TC-OB-011 | Only one active (non-completed) flow per user per recovery area | P0 | `TestThreeCircles_TC_OB_011_OneActiveFlowPerArea` |
| TC-OB-012 | POST `/onboarding/{flowId}/complete` finalizes onboarding and creates the circle set | P0 | `TestThreeCircles_TC_OB_012_CompleteOnboarding` |
| TC-OB-013 | Complete requires `commitOption`: `commitNow`, `draft`, `draftNoShare` | P0 | `TestThreeCircles_TC_OB_013_CommitOptionRequired` |
| TC-OB-014 | `commitNow` creates an active circle set | P0 | `TestThreeCircles_TC_OB_014_CommitNowActive` |
| TC-OB-015 | `draft` creates a draft circle set | P0 | `TestThreeCircles_TC_OB_015_DraftOption` |
| TC-OB-016 | `draft` with `generateSponsorShare=true` creates share link and code in response | P0 | `TestThreeCircles_TC_OB_016_DraftWithSponsorShare` |
| TC-OB-017 | `draftNoShare` creates a draft circle set without share link | P0 | `TestThreeCircles_TC_OB_017_DraftNoShareOption` |
| TC-OB-018 | Complete returns 201 with the created circle set and optional share link/code | P0 | `TestThreeCircles_TC_OB_018_CompleteResponse201` |
| TC-OB-019 | Completing a flow with zero inner circle items and `commitNow` returns 422 | P0 | `TestThreeCircles_TC_OB_019_CompleteFailsZeroInner` |
| TC-OB-020 | `createdAt` on onboarding flow is immutable (FR2.7) | P0 | `TestThreeCircles_TC_OB_020_FlowCreatedAtImmutable` |
| TC-OB-021 | Getting a non-existent flow returns 404 | P0 | `TestThreeCircles_TC_OB_021_NonExistentFlow404` |
| TC-OB-022 | Completing an already-completed flow returns 422 | P0 | `TestThreeCircles_TC_OB_022_DoubleCompleteRejected` |
| TC-OB-023 | Guided mode follows creation sequence: inner -> outer -> middle | P0 | `TestThreeCircles_TC_OB_023_GuidedSequence` |
| TC-OB-024 | Express mode allows steps to be completed in any order | P1 | `TestThreeCircles_TC_OB_024_ExpressFlexibleOrder` |
| TC-OB-025 | StarterPack mode applies a starter pack and enters review state | P0 | `TestThreeCircles_TC_OB_025_StarterPackMode` |

---

## 7. Sponsor Review (TC-SR)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-SR-001 | POST `/sets/{setId}/share` generates an 8-character alphanumeric share code and URL | P0 | `TestThreeCircles_TC_SR_001_GenerateShareCode` |
| TC-SR-002 | Share supports `expiresIn` options: `24h`, `7d`, `never` (default: `7d`) | P0 | `TestThreeCircles_TC_SR_002_ExpiresInOptions` |
| TC-SR-003 | Share supports `permissions` array: `view`, `comment` (default: `[view, comment]`) | P0 | `TestThreeCircles_TC_SR_003_PermissionsOptions` |
| TC-SR-004 | Share returns 201 with share code, share link, expiration, and permissions | P0 | `TestThreeCircles_TC_SR_004_ShareResponse` |
| TC-SR-005 | GET `/share/{shareCode}` is a public endpoint (no auth required) | P0 | `TestThreeCircles_TC_SR_005_PublicViewNoAuth` |
| TC-SR-006 | Public share view returns circle items with notes and context but no user identity | P0 | `TestThreeCircles_TC_SR_006_ShareViewContents` |
| TC-SR-007 | Expired share returns 410 Gone | P0 | `TestThreeCircles_TC_SR_007_ExpiredShare410` |
| TC-SR-008 | Invalid or non-existent share code returns 404 | P0 | `TestThreeCircles_TC_SR_008_InvalidShareCode404` |
| TC-SR-009 | POST `/share/{shareCode}/comments` is a public endpoint (no auth required) | P0 | `TestThreeCircles_TC_SR_009_CommentNoAuth` |
| TC-SR-010 | Comment requires `itemId` and `text` (max 1000 chars); `commenterName` is optional (max 100 chars) | P0 | `TestThreeCircles_TC_SR_010_CommentFields` |
| TC-SR-011 | Comment on non-existent `itemId` returns 422 | P0 | `TestThreeCircles_TC_SR_011_InvalidItemId422` |
| TC-SR-012 | Comment text exceeding 1000 chars returns 422 | P0 | `TestThreeCircles_TC_SR_012_CommentTextMaxLength` |
| TC-SR-013 | Commenting on a view-only share (no comment permission) returns 403 | P0 | `TestThreeCircles_TC_SR_013_ViewOnlyNoComment` |
| TC-SR-014 | GET `/sets/{setId}/comments` returns all comments for the set (owner only, auth required) | P0 | `TestThreeCircles_TC_SR_014_OwnerViewComments` |
| TC-SR-015 | Comments include `commentId`, `itemId`, `text`, `commenterName`, `createdAt` | P0 | `TestThreeCircles_TC_SR_015_CommentResponseFields` |
| TC-SR-016 | Comments are returned with cursor-based pagination | P1 | `TestThreeCircles_TC_SR_016_CommentPagination` |
| TC-SR-017 | Unread comment count is included in set detail response (`sponsorCommentCount`) | P1 | `TestThreeCircles_TC_SR_017_UnreadCommentCount` |
| TC-SR-018 | Multiple active shares per set are allowed | P1 | `TestThreeCircles_TC_SR_018_MultipleSharesPerSet` |
| TC-SR-019 | Share code is globally unique | P0 | `TestThreeCircles_TC_SR_019_ShareCodeUnique` |
| TC-SR-020 | Sponsor does not need an account to view shared circles or leave comments | P0 | `TestThreeCircles_TC_SR_020_NoAccountRequired` |

---

## 8. Pattern Visualization (TC-PV)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-PV-001 | GET `/patterns/timeline` requires `setId` parameter; missing returns 422 | P0 | `TestThreeCircles_TC_PV_001_SetIdRequired` |
| TC-PV-002 | Timeline supports `period` enum: `7d`, `30d` (default), `90d`, `1y`, `all` | P0 | `TestThreeCircles_TC_PV_002_PeriodOptions` |
| TC-PV-003 | Timeline supports custom date range via `startDate` and `endDate` (overrides `period`) | P1 | `TestThreeCircles_TC_PV_003_CustomDateRange` |
| TC-PV-004 | Each timeline entry includes `date`, `circle` (inner/middle/outer), and optional `checkinDetails` (mood, urgeIntensity, notes) | P0 | `TestThreeCircles_TC_PV_004_TimelineEntryFields` |
| TC-PV-005 | Days with no check-in are represented as gaps (not present in entries array) | P0 | `TestThreeCircles_TC_PV_005_NoCheckinGaps` |
| TC-PV-006 | Summary stats include `outerDays`, `middleDays`, `innerDays`, `noCheckinDays`, `currentConsecutiveOuterDays` | P0 | `TestThreeCircles_TC_PV_006_SummaryStats` |
| TC-PV-007 | `currentConsecutiveOuterDays` is shown as context, not as a primary streak counter | P0 | `TestThreeCircles_TC_PV_007_OuterDaysNotStreak` |
| TC-PV-008 | `noCheckinDays` is calculated as total days in period minus (outer + middle + inner) | P0 | `TestThreeCircles_TC_PV_008_NoCheckinCalculation` |
| TC-PV-009 | No-check-in days are shown neutrally (not as "missed") | P0 | `TestThreeCircles_TC_PV_009_NeutralNoCheckin` |
| TC-PV-010 | GET `/patterns/summary` requires `setId` and `period` (week/month) | P0 | `TestThreeCircles_TC_PV_010_SummaryRequired` |
| TC-PV-011 | Summary includes circle distribution, top 3 insights, mood trend, and framing message | P0 | `TestThreeCircles_TC_PV_011_SummaryContents` |
| TC-PV-012 | Framing message uses descriptive language, never percentages or grading | P0 | `TestThreeCircles_TC_PV_012_DescriptiveFraming` |
| TC-PV-013 | Mood trend enum: `improving`, `stable`, `declining`, `insufficient-data` | P1 | `TestThreeCircles_TC_PV_013_MoodTrendEnum` |
| TC-PV-014 | When a day is logged as inner circle, visualization shows context (days before and after) | P1 | `TestThreeCircles_TC_PV_014_SlipInContext` |
| TC-PV-015 | Timeline renders within 500ms on median devices (NFR) | P1 | `TestThreeCircles_TC_PV_015_RenderPerformance` |
| TC-PV-016 | All pattern analysis data is user-scoped; no cross-user visibility | P0 | `TestThreeCircles_TC_PV_016_UserScopedPatterns` |
| TC-PV-017 | Pattern data works fully offline (cached timeline) | P1 | `TestThreeCircles_TC_PV_017_OfflinePatterns` |

---

## 9. Drift Alerts (TC-DA)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-DA-001 | GET `/patterns/drift-alerts` requires `setId` parameter | P0 | `TestThreeCircles_TC_DA_001_SetIdRequired` |
| TC-DA-002 | Drift alert is generated when 3+ middle circle days occur in a 7-day window | P0 | `TestThreeCircles_TC_DA_002_ThresholdTrigger` |
| TC-DA-003 | 2 middle circle days in 7 days does NOT trigger an alert | P0 | `TestThreeCircles_TC_DA_003_BelowThresholdNoAlert` |
| TC-DA-004 | Alert is one-time per drift episode (not repeated daily during the same window) | P0 | `TestThreeCircles_TC_DA_004_OneTimePerEpisode` |
| TC-DA-005 | Alert `message` uses gentle, non-punitive copy | P0 | `TestThreeCircles_TC_DA_005_GentleCopy` |
| TC-DA-006 | Alerts support `status` filter: `active`, `dismissed`, `all` (default: `active`) | P0 | `TestThreeCircles_TC_DA_006_StatusFilter` |
| TC-DA-007 | POST `/patterns/drift-alerts/{alertId}/dismiss` marks alert as dismissed; returns 204 | P0 | `TestThreeCircles_TC_DA_007_DismissAlert` |
| TC-DA-008 | Dismissed alerts do not reappear for the same drift episode | P0 | `TestThreeCircles_TC_DA_008_DismissedStayDismissed` |
| TC-DA-009 | Alert includes `windowStart`, `windowEnd`, `middleCircleDays`, `middleCircleDates` | P0 | `TestThreeCircles_TC_DA_009_AlertFields` |
| TC-DA-010 | A new drift episode (new 7-day window) can trigger a new alert even if previous was dismissed | P1 | `TestThreeCircles_TC_DA_010_NewEpisodeNewAlert` |
| TC-DA-011 | Dismissing a non-existent alert returns 404 | P0 | `TestThreeCircles_TC_DA_011_NonExistentAlert404` |
| TC-DA-012 | Drift alerts are fully dismissible and never block app use | P0 | `TestThreeCircles_TC_DA_012_NeverBlocking` |

---

## 10. Insights (TC-IN)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-IN-001 | GET `/patterns/insights` requires `setId` parameter | P0 | `TestThreeCircles_TC_IN_001_SetIdRequired` |
| TC-IN-002 | Insights are only generated when user has 14+ days of check-in data | P0 | `TestThreeCircles_TC_IN_002_MinimumDataThreshold` |
| TC-IN-003 | With fewer than 14 days of data, insights endpoint returns empty data array with `meta.minimumDataDays=14` | P0 | `TestThreeCircles_TC_IN_003_InsufficientDataEmpty` |
| TC-IN-004 | Insights support `category` filter: `dayOfWeek`, `time`, `trigger`, `protective`, `sleep`, `seeds` | P1 | `TestThreeCircles_TC_IN_004_CategoryFilter` |
| TC-IN-005 | Each insight includes `insightId`, `type`, `description`, `confidence`, `actionSuggestion`, `dataPoints`, `detectedAt` | P0 | `TestThreeCircles_TC_IN_005_InsightFields` |
| TC-IN-006 | `confidence` is one of: `low`, `medium`, `high` | P0 | `TestThreeCircles_TC_IN_006_ConfidenceEnum` |
| TC-IN-007 | Every insight includes a constructive `actionSuggestion` | P0 | `TestThreeCircles_TC_IN_007_ActionSuggestionPresent` |
| TC-IN-008 | Insights are framed as observations, not predictions | P0 | `TestThreeCircles_TC_IN_008_ObservationsNotPredictions` |
| TC-IN-009 | Insights never surface shaming correlations (e.g., "You slip after talking to your mother") | P0 | `TestThreeCircles_TC_IN_009_NoShamingCorrelations` |
| TC-IN-010 | Users can dismiss individual insights | P0 | `TestThreeCircles_TC_IN_010_DismissInsight` |
| TC-IN-011 | Dismissed insights are not returned in active insight queries | P0 | `TestThreeCircles_TC_IN_011_DismissedExcluded` |
| TC-IN-012 | Insights refresh weekly | P1 | `TestThreeCircles_TC_IN_012_WeeklyRefresh` |
| TC-IN-013 | Day-of-week pattern insight: detects when middle circle contact clusters on specific days | P1 | `TestThreeCircles_TC_IN_013_DayOfWeekPattern` |
| TC-IN-014 | Trigger correlation insight: detects mood/SEEDS correlations with circle movement | P1 | `TestThreeCircles_TC_IN_014_TriggerCorrelation` |
| TC-IN-015 | Protective correlation insight: detects behaviors (sponsor calls, exercise) associated with outer circle days | P1 | `TestThreeCircles_TC_IN_015_ProtectiveCorrelation` |
| TC-IN-016 | Sleep correlation insight: detects sleep deprivation preceding urge spikes | P2 | `TestThreeCircles_TC_IN_016_SleepCorrelation` |
| TC-IN-017 | `dataPoints` accurately reflects the number of days analyzed | P0 | `TestThreeCircles_TC_IN_017_DataPointsAccurate` |
| TC-IN-018 | All correlation calculations are deterministic and reproducible | P0 | `TestThreeCircles_TC_IN_018_DeterministicCalculations` |

---

## 11. Quarterly Reviews (TC-QR)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-QR-001 | GET `/reviews` requires `setId` parameter and returns review history with cursor pagination | P0 | `TestThreeCircles_TC_QR_001_ListReviews` |
| TC-QR-002 | Review list includes `meta.nextReviewDue` date for the set | P0 | `TestThreeCircles_TC_QR_002_NextReviewDueInMeta` |
| TC-QR-003 | POST `/reviews` creates a new review for a set; returns 201 | P0 | `TestThreeCircles_TC_QR_003_StartReview` |
| TC-QR-004 | Starting a review requires `setId` | P0 | `TestThreeCircles_TC_QR_004_SetIdRequired` |
| TC-QR-005 | PATCH `/reviews/{reviewId}` updates review progress (currentStep, reflections, changesApplied) | P0 | `TestThreeCircles_TC_QR_005_UpdateReview` |
| TC-QR-006 | `currentStep` must follow enum: `innerReview`, `outerReview`, `middleReview`, `finalReview` | P0 | `TestThreeCircles_TC_QR_006_ValidSteps` |
| TC-QR-007 | Review can be paused and resumed (progress persists) | P0 | `TestThreeCircles_TC_QR_007_PauseAndResume` |
| TC-QR-008 | POST `/reviews/{reviewId}/complete` finalizes the review | P0 | `TestThreeCircles_TC_QR_008_CompleteReview` |
| TC-QR-009 | Complete accepts optional `summary` (max 1000 chars) | P1 | `TestThreeCircles_TC_QR_009_CompleteSummary` |
| TC-QR-010 | Completing a review sets `nextReviewDue` to 90 days from completion | P0 | `TestThreeCircles_TC_QR_010_NextReviewDue90Days` |
| TC-QR-011 | Completing a review updates `lastReviewedAt` and `nextReviewDue` on the parent circle set | P0 | `TestThreeCircles_TC_QR_011_UpdatesParentSet` |
| TC-QR-012 | Every 90 days, users are prompted to review their circles (driven by `nextReviewDue`) | P0 | `TestThreeCircles_TC_QR_012_QuarterlyPrompt` |
| TC-QR-013 | Review prompts are fully skippable and do not block app use | P0 | `TestThreeCircles_TC_QR_013_SkippableNonBlocking` |
| TC-QR-014 | Changes made during review create version snapshots | P0 | `TestThreeCircles_TC_QR_014_ReviewChangesCreateVersions` |
| TC-QR-015 | Review walks through each circle with reflection prompts (inner, outer, middle, final) | P1 | `TestThreeCircles_TC_QR_015_WalkThroughSequence` |
| TC-QR-016 | Getting a non-existent review returns 404 | P0 | `TestThreeCircles_TC_QR_016_NonExistentReview404` |
| TC-QR-017 | Completing an already-completed review returns 422 | P0 | `TestThreeCircles_TC_QR_017_DoubleCompleteRejected` |

---

## 12. Guardrails & Validation (TC-GR)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-GR-001 | **Vague definition check:** Items with text under 5 words return a `guardrail` advisory in response metadata (non-blocking) | P0 | `TestThreeCircles_TC_GR_001_VagueDefinitionAdvisory` |
| TC-GR-002 | **Vague keyword check:** Items containing vague keywords ("be," "stop," "better," "good," "bad," "right") return specificity advisory | P0 | `TestThreeCircles_TC_GR_002_VagueKeywordAdvisory` |
| TC-GR-003 | Guardrail advisories are non-blocking (item is saved regardless) | P0 | `TestThreeCircles_TC_GR_003_AdvisoriesNonBlocking` |
| TC-GR-004 | **Overload nudge:** When inner circle exceeds 8 items, response includes overload advisory | P0 | `TestThreeCircles_TC_GR_004_InnerCircleOverloadNudge` |
| TC-GR-005 | Overload nudge at 8 items is advisory; hard limit is 20 items (422 at 21) | P0 | `TestThreeCircles_TC_GR_005_OverloadSoftVsHard` |
| TC-GR-006 | **Middle circle depth nudge:** When middle circle has fewer than 3 items at commit time, response includes depth advisory | P0 | `TestThreeCircles_TC_GR_006_MiddleCircleDepthNudge` |
| TC-GR-007 | **Isolation nudge:** When committing without sponsor review, response includes sharing advisory | P1 | `TestThreeCircles_TC_GR_007_IsolationNudge` |
| TC-GR-008 | Inner circle addition returns advisory about significance of the commitment (client-side confirmation guidance) | P1 | `TestThreeCircles_TC_GR_008_InnerAdditionAdvisory` |
| TC-GR-009 | Inner circle removal returns stronger advisory about the significance of removing a boundary | P1 | `TestThreeCircles_TC_GR_009_InnerRemovalAdvisory` |
| TC-GR-010 | Guardrail advisories are included in `meta.guardrails` array on relevant responses | P0 | `TestThreeCircles_TC_GR_010_GuardrailsInMeta` |
| TC-GR-011 | Each guardrail advisory includes `type`, `message`, and optional `suggestion` | P0 | `TestThreeCircles_TC_GR_011_GuardrailAdvisoryFormat` |
| TC-GR-012 | Guardrail language is trauma-informed: no "failure," "clean/dirty," "weakness," "addict" | P0 | `TestThreeCircles_TC_GR_012_TraumaInformedLanguage` |
| TC-GR-013 | **Save count check:** If user edits the same item more than 3 times in a session, response includes pacing advisory | P2 | `TestThreeCircles_TC_GR_013_PacingAdvisory` |
| TC-GR-014 | **Time check:** If onboarding flow exceeds 15 minutes, response includes break advisory | P2 | `TestThreeCircles_TC_GR_014_BreakAdvisory` |

---

## 13. Non-Functional Requirements (TC-NFR)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| TC-NFR-001 | All endpoints return 404 when `feature.3circles` is disabled (fail closed) | P0 | `TestThreeCircles_TC_NFR_001_FeatureFlagGating` |
| TC-NFR-002 | Feature flag 404 response uses error code `rr:0x000B0404` with title "Feature Not Available" | P0 | `TestThreeCircles_TC_NFR_002_FeatureFlagErrorCode` |
| TC-NFR-003 | All endpoints require Bearer JWT authentication except public share endpoints | P0 | `TestThreeCircles_TC_NFR_003_AuthRequired` |
| TC-NFR-004 | Missing or invalid JWT returns 401 with `rr:0x000B0401` | P0 | `TestThreeCircles_TC_NFR_004_InvalidAuth401` |
| TC-NFR-005 | All error responses include `correlationId` for distributed tracing | P0 | `TestThreeCircles_TC_NFR_005_CorrelationId` |
| TC-NFR-006 | All error codes follow `rr:0x000B{4 hex}` format | P0 | `TestThreeCircles_TC_NFR_006_ErrorCodeFormat` |
| TC-NFR-007 | 422 validation errors include `source.pointer` referencing the offending field | P0 | `TestThreeCircles_TC_NFR_007_ValidationSourcePointer` |
| TC-NFR-008 | `createdAt` timestamps are immutable on all entities (FR2.7) | P0 | `TestThreeCircles_TC_NFR_008_ImmutableTimestamps` |
| TC-NFR-009 | All user-scoped queries are scoped by `userId` and `tenantId` | P0 | `TestThreeCircles_TC_NFR_009_TenantUserScoping` |
| TC-NFR-010 | Onboarding median completion time: guided < 25 min, express < 8 min, starterPack < 15 min | P1 | `TestThreeCircles_TC_NFR_010_OnboardingTimeTargets` |
| TC-NFR-011 | All circle data stored locally first (offline-first); optional encrypted cloud sync | P0 | `TestThreeCircles_TC_NFR_011_OfflineFirst` |
| TC-NFR-012 | Builder works fully offline (template cache, progress save, draft creation) | P0 | `TestThreeCircles_TC_NFR_012_OfflineBuilder` |
| TC-NFR-013 | Template data is cacheable and updateable independently of app versions | P1 | `TestThreeCircles_TC_NFR_013_TemplateCaching` |
| TC-NFR-014 | Accessibility: screen reader compatible, high-contrast mode, adjustable text size | P1 | `TestThreeCircles_TC_NFR_014_Accessibility` |
| TC-NFR-015 | All copy passes trauma-informed language review (no "failure," "clean/dirty," "weakness," "addict") | P0 | `TestThreeCircles_TC_NFR_015_TraumaInformedLanguage` |
| TC-NFR-016 | Visualizations render within 500ms on median devices | P1 | `TestThreeCircles_TC_NFR_016_VisualizationPerformance` |
| TC-NFR-017 | All visualization color schemes are color-blind safe | P1 | `TestThreeCircles_TC_NFR_017_ColorBlindSafe` |
| TC-NFR-018 | No visualization shows data the user hasn't explicitly agreed to share | P0 | `TestThreeCircles_TC_NFR_018_NoImplicitSharing` |
| TC-NFR-019 | Cursor-based pagination on all list endpoints (cursor + limit, max 100 per page) | P0 | `TestThreeCircles_TC_NFR_019_CursorPagination` |
| TC-NFR-020 | JSON Merge Patch (RFC 7396) used for PATCH endpoints | P0 | `TestThreeCircles_TC_NFR_020_JsonMergePatch` |
| TC-NFR-021 | Calendar activity dual-write on circle set commit and quarterly review completion | P0 | `TestThreeCircles_TC_NFR_021_CalendarDualWrite` |
| TC-NFR-022 | Starter pack 14-day check-in prompt scheduled when user accepts a starter pack | P1 | `TestThreeCircles_TC_NFR_022_StarterPackCheckIn` |
| TC-NFR-023 | No notification or alert triggered to any other party without explicit user action | P0 | `TestThreeCircles_TC_NFR_023_NoAutoNotify` |
| TC-NFR-024 | All user-generated circle content is end-to-end encrypted if synced to cloud | P0 | `TestThreeCircles_TC_NFR_024_E2EEncryption` |

---

## Summary

| Section | Domain | Criteria Count |
|---------|--------|---------------|
| 1 | Circle Sets (TC-CS) | 25 |
| 2 | Circle Items (TC-CI) | 24 |
| 3 | Version History (TC-VH) | 15 |
| 4 | Templates (TC-TP) | 12 |
| 5 | Starter Packs (TC-SP) | 19 |
| 6 | Onboarding (TC-OB) | 25 |
| 7 | Sponsor Review (TC-SR) | 20 |
| 8 | Pattern Visualization (TC-PV) | 17 |
| 9 | Drift Alerts (TC-DA) | 12 |
| 10 | Insights (TC-IN) | 18 |
| 11 | Quarterly Reviews (TC-QR) | 17 |
| 12 | Guardrails (TC-GR) | 14 |
| 13 | Non-Functional (TC-NFR) | 24 |
| **Total** | | **242** |
