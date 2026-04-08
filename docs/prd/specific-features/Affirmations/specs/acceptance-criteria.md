# Affirmations: Consolidated Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-08
**Status:** Draft
**Traces to:** PRD 02-feature-specifications.md (ACTIVITY: Christian Affirmations), content/affirmations/

---

## Naming Convention

All acceptance criteria follow the format `AFF-{Domain}-AC{N}` where:
- **AFF** = Affirmations (feature prefix)
- **Domain** = DM (Data Model), DL (Delivery & Display), CU (Custom Creation), RO (Rotation & Selection), LV (Levels & Progression), AU (Audio), FA (Favorites), IN (Integrations)
- **AC{N}** = Sequential acceptance criterion number

Test names follow the format `TestAffirmation_AFF_{Domain}_AC{N}_{Description}`.

---

## 1. Data Model (AFF-DM)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-DM-AC1 | Each affirmation contains: statement (present tense, first person), scriptureReference, optional scriptureText, optional expansion, optional prayer, category, level | P0 | `TestAffirmation_AFF_DM_AC1_AffirmationStructure` |
| AFF-DM-AC2 | Statement max length 500 characters; text exceeding 500 characters is rejected with 422 | P0 | `TestAffirmation_AFF_DM_AC2_StatementMaxLength` |
| AFF-DM-AC3 | Category must be from enum: identity, strength, recovery, purity, freedom, surrender, courage, hope, family, healthySexuality | P0 | `TestAffirmation_AFF_DM_AC3_CategoryEnum` |
| AFF-DM-AC4 | Level must be 1, 2, or 3; values outside this range rejected with 422 | P0 | `TestAffirmation_AFF_DM_AC4_LevelRange` |
| AFF-DM-AC5 | Affirmation IDs follow pattern `aff_{alphanumeric}`; custom affirmation IDs follow `caff_{alphanumeric}` | P0 | `TestAffirmation_AFF_DM_AC5_IdPattern` |
| AFF-DM-AC6 | CreatedAt timestamp is immutable on system affirmations and custom affirmations (FR2.7) | P0 | `TestAffirmation_AFF_DM_AC6_ImmutableCreatedAt` |
| AFF-DM-AC7 | TenantId is present on all affirmation documents and enforced at API layer; system packs use TenantId=SYSTEM | P0 | `TestAffirmation_AFF_DM_AC7_TenantIsolation` |
| AFF-DM-AC8 | healthySexuality category is OFF by default; requires 60+ days sobriety AND explicit user opt-in to display | P0 | `TestAffirmation_AFF_DM_AC8_HealthySexualityGating` |
| AFF-DM-AC9 | Affirmation packs contain packId, name, description, tier (free/premium), affirmationCount, and categories | P0 | `TestAffirmation_AFF_DM_AC9_PackStructure` |
| AFF-DM-AC10 | Premium packs are unlocked forever when purchased (not subscription-gated) | P0 | `TestAffirmation_AFF_DM_AC10_PermanentUnlock` |

---

## 2. Delivery & Display (AFF-DL)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-DL-AC1 | Daily affirmation is deterministic per user per day (same userId + same date = same affirmation) | P0 | `TestAffirmation_AFF_DL_AC1_DeterministicDaily` |
| AFF-DL-AC2 | Daily affirmation is selected from user's owned packs only | P0 | `TestAffirmation_AFF_DL_AC2_OwnedPacksOnly` |
| AFF-DL-AC3 | Push notification delivers affirmation at user-configured time; default 7:00 AM local time | P1 | `TestAffirmation_AFF_DL_AC3_PushDelivery` |
| AFF-DL-AC4 | Affirmation display includes: statement, scripture reference, scripture text in user's preferred Bible version | P0 | `TestAffirmation_AFF_DL_AC4_DisplayFields` |
| AFF-DL-AC5 | "Read More" expands to show optional expansion text and prayer | P1 | `TestAffirmation_AFF_DL_AC5_ExpandedView` |
| AFF-DL-AC6 | Affirmation accessible on-demand via browse/search; not limited to daily delivery | P0 | `TestAffirmation_AFF_DL_AC6_OnDemandAccess` |
| AFF-DL-AC7 | Post-urge-log affirmation delivery: contextual affirmation relevant to trigger category shown after urge log completion | P1 | `TestAffirmation_AFF_DL_AC7_PostUrgeDelivery` |
| AFF-DL-AC8 | Morning commitment confirmation screen includes today's affirmation | P1 | `TestAffirmation_AFF_DL_AC8_MorningFlowIntegration` |
| AFF-DL-AC9 | Affirmation display uses dark mode gradient background with softer typography when dark mode is active | P2 | `TestAffirmation_AFF_DL_AC9_DarkModeDisplay` |

---

## 3. Custom Creation (AFF-CU)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-CU-AC1 | User can create custom affirmation with: statement (required), scriptureReference (optional), category (required), schedule (required: daily/weekdays/weekends/custom) | P0 | `TestAffirmation_AFF_CU_AC1_CreateCustom` |
| AFF-CU-AC2 | Custom affirmation statement must be present tense and first person; validated client-side with guidance message (not server-rejected) | P1 | `TestAffirmation_AFF_CU_AC2_TenseGuidance` |
| AFF-CU-AC3 | Custom affirmation is included in the rotation based on selected schedule | P0 | `TestAffirmation_AFF_CU_AC3_RotationInclusion` |
| AFF-CU-AC4 | Custom affirmation is editable and deletable at any time (no edit window restriction) | P0 | `TestAffirmation_AFF_CU_AC4_EditDelete` |
| AFF-CU-AC5 | Maximum 50 custom affirmations per user; exceeding returns 422 | P1 | `TestAffirmation_AFF_CU_AC5_MaxCustomLimit` |
| AFF-CU-AC6 | Custom affirmations are scoped to the creating user; not visible to other users or support network | P0 | `TestAffirmation_AFF_CU_AC6_UserScoped` |

---

## 4. Rotation & Selection (AFF-RO)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-RO-AC1 | Individually Chosen mode: user manually selects specific affirmation for today | P0 | `TestAffirmation_AFF_RO_AC1_IndividuallyChosen` |
| AFF-RO-AC2 | Random Automatic mode: system selects from owned packs weighted by rotation logic | P0 | `TestAffirmation_AFF_RO_AC2_RandomAutomatic` |
| AFF-RO-AC3 | Package Mode (Permanent): cycles through a single pack sequentially | P1 | `TestAffirmation_AFF_RO_AC3_PermanentPackage` |
| AFF-RO-AC4 | Package Mode (Day-of-Week): assigns specific affirmation to each day of week | P1 | `TestAffirmation_AFF_RO_AC4_DayOfWeekPackage` |
| AFF-RO-AC5 | Rotation weighting in Random Automatic mode: triggers 40%, favorites 30%, under-served categories 20%, random 10% | P0 | `TestAffirmation_AFF_RO_AC5_RotationWeighting` |
| AFF-RO-AC6 | Contextual trigger override: post-urge-log always selects trigger-relevant affirmation regardless of current mode | P0 | `TestAffirmation_AFF_RO_AC6_TriggerOverride` |
| AFF-RO-AC7 | No affirmation is repeated until all affirmations in the active set have been shown (within a rotation cycle) | P1 | `TestAffirmation_AFF_RO_AC7_NoDuplicatesInCycle` |

---

## 5. Levels & Progression (AFF-LV)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-LV-AC1 | Level 1 affirmations focus on identity, worth, and basic hope; available to all users from day 0 | P0 | `TestAffirmation_AFF_LV_AC1_Level1Access` |
| AFF-LV-AC2 | Level 2 affirmations focus on growth, accountability, and deeper recovery; unlocked at 30+ days sobriety | P0 | `TestAffirmation_AFF_LV_AC2_Level2Unlock` |
| AFF-LV-AC3 | Level 3 affirmations focus on leadership, giving back, and healthy sexuality; unlocked at 90+ days sobriety | P0 | `TestAffirmation_AFF_LV_AC3_Level3Unlock` |
| AFF-LV-AC4 | Post-relapse: only Level 1 affirmations shown for first 24 hours after sobriety reset | P0 | `TestAffirmation_AFF_LV_AC4_PostRelapseLevel1Only` |
| AFF-LV-AC5 | SOS mode: affirmation selection never exceeds Level 2 regardless of sobriety days | P0 | `TestAffirmation_AFF_LV_AC5_SOSModeMaxLevel2` |
| AFF-LV-AC6 | Level unlocks use cumulative days, NOT streak-based (clinical requirement: no gamification of sobriety) | P0 | `TestAffirmation_AFF_LV_AC6_CumulativeNotStreak` |
| AFF-LV-AC7 | Healthy Sexuality category (within Level 3) requires explicit opt-in beyond 60+ days AND the opt-in is revocable | P0 | `TestAffirmation_AFF_LV_AC7_HealthySexualityOptIn` |

---

## 6. Audio (AFF-AU)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-AU-AC1 | Affirmations support TTS (text-to-speech) audio playback | P1 | `TestAffirmation_AFF_AU_AC1_TTSPlayback` |
| AFF-AU-AC2 | Audio auto-pauses on headphone disconnect (non-negotiable safety requirement) | P0 | `TestAffirmation_AFF_AU_AC2_HeadphoneDisconnectPause` |
| AFF-AU-AC3 | Audio playback controls: play/pause, restart, speed (0.75x, 1x, 1.25x, 1.5x) | P1 | `TestAffirmation_AFF_AU_AC3_PlaybackControls` |
| AFF-AU-AC4 | Audio works offline using on-device TTS engine | P0 | `TestAffirmation_AFF_AU_AC4_OfflineTTS` |

---

## 7. Favorites (AFF-FA)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-FA-AC1 | User can favorite/unfavorite any affirmation (system or custom) | P0 | `TestAffirmation_AFF_FA_AC1_ToggleFavorite` |
| AFF-FA-AC2 | Favorites list endpoint returns all favorited affirmations across all packs | P0 | `TestAffirmation_AFF_FA_AC2_FavoritesList` |
| AFF-FA-AC3 | Favorited affirmations receive 30% weighting boost in Random Automatic rotation | P0 | `TestAffirmation_AFF_FA_AC3_FavoriteWeighting` |
| AFF-FA-AC4 | Favorite status persists across devices via sync | P1 | `TestAffirmation_AFF_FA_AC4_CrossDeviceSync` |

---

## 8. Integrations (AFF-IN)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| AFF-IN-AC1 | Morning commitment confirmation screen displays today's affirmation | P1 | `TestAffirmation_AFF_IN_AC1_MorningCommitment` |
| AFF-IN-AC2 | Post-urge-log screen delivers contextual affirmation matching trigger category | P1 | `TestAffirmation_AFF_IN_AC2_PostUrgeLog` |
| AFF-IN-AC3 | "I'm Struggling Today" flow includes affirmation display | P1 | `TestAffirmation_AFF_IN_AC3_StrugglingFlow` |
| AFF-IN-AC4 | Dashboard widget shows today's affirmation text (truncated to 100 chars) with tap to expand | P1 | `TestAffirmation_AFF_IN_AC4_DashboardWidget` |
| AFF-IN-AC5 | Reading an affirmation creates a CALENDAR_ACTIVITY dual-write with activityType=AFFIRMATION | P0 | `TestAffirmation_AFF_IN_AC5_CalendarActivity` |
| AFF-IN-AC6 | Feature flag `activity.affirmations` controls all affirmation endpoints; disabled flag returns 404 | P0 | `TestAffirmation_AFF_IN_AC6_FeatureFlag` |
| AFF-IN-AC7 | Affirmation packs cached offline: current pack + favorites available without internet | P0 | `TestAffirmation_AFF_IN_AC7_OfflineCache` |
| AFF-IN-AC8 | Affirmation read tracking feeds into cumulative progress counter (total affirmations read lifetime) | P0 | `TestAffirmation_AFF_IN_AC8_CumulativeProgress` |
| AFF-IN-AC9 | Scripture references rendered in user's preferred Bible version from Profile settings | P0 | `TestAffirmation_AFF_IN_AC9_BibleVersionPreference` |
| AFF-IN-AC10 | Share affirmation as text or styled graphic; shared content includes statement, scripture, and "Regal Recovery" watermark | P1 | `TestAffirmation_AFF_IN_AC10_Sharing` |

---

## Cross-Cutting Concerns

| ID | Criterion | Priority | Domain |
|----|-----------|----------|--------|
| AFF-CC-AC1 | All affirmation endpoints require Bearer auth; missing/invalid token returns 401 | P0 | Auth |
| AFF-CC-AC2 | All error responses follow the `{ "errors": [...] }` envelope with `rr:0x000A` error codes | P0 | Error handling |
| AFF-CC-AC3 | All successful responses follow the `{ "data": ..., "links": {...}, "meta": {...} }` envelope | P0 | Response format |
| AFF-CC-AC4 | Cursor-based pagination on list endpoints with `cursor` and `limit` query params | P0 | Pagination |
| AFF-CC-AC5 | Offline affirmation reading works without internet; favorites sync on reconnection | P0 | Offline-first |
| AFF-CC-AC6 | Correlation ID (X-Correlation-Id) present on all responses for distributed tracing | P0 | Observability |

---

## Acceptance Criteria Summary

| Domain | Total ACs | P0 | P1 | P2 |
|--------|-----------|----|----|-----|
| Data Model (DM) | 10 | 10 | 0 | 0 |
| Delivery & Display (DL) | 9 | 4 | 4 | 1 |
| Custom Creation (CU) | 6 | 4 | 2 | 0 |
| Rotation & Selection (RO) | 7 | 4 | 3 | 0 |
| Levels & Progression (LV) | 7 | 7 | 0 | 0 |
| Audio (AU) | 4 | 2 | 2 | 0 |
| Favorites (FA) | 4 | 3 | 1 | 0 |
| Integrations (IN) | 10 | 5 | 5 | 0 |
| Cross-Cutting (CC) | 6 | 6 | 0 | 0 |
| **Total** | **63** | **45** | **17** | **1** |
