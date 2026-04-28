# Gratitude List: Consolidated Acceptance Criteria

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft
**Traces to:** Gratitude_List_Activity.md, specs/01-07

---

## Naming Convention

All acceptance criteria follow the format `GL-{Domain}-AC{N}` where:
- **GL** = Gratitude List (feature prefix)
- **Domain** = DM (Data Model), ES (Entry Screen), HS (History Screen), TI (Trends & Insights), PR (Prompts), SH (Sharing), IN (Integrations)
- **AC{N}** = Sequential acceptance criterion number

Test names follow the format `TestGratitude_GL_{Domain}_AC{N}_{Description}`.

---

## 1. Data Model (GL-DM)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| GL-DM-AC1 | Each gratitude item supports text up to 300 characters; text exceeding 300 characters is rejected with a 422 error | P0 | `TestGratitude_GL_DM_AC1_ItemTextMaxLength` |
| GL-DM-AC2 | Items accept optional category tag from the predefined enum (faithGod, family, relationships, health, recovery, workCareer, natureBeauty, smallMoments, growthProgress, custom) plus a free-text custom value | P0 | `TestGratitude_GL_DM_AC2_CategoryTagOptions` |
| GL-DM-AC3 | Entry supports optional mood score in range 1-5 inclusive; values outside this range are rejected with 422 | P0 | `TestGratitude_GL_DM_AC3_MoodScoreRange` |
| GL-DM-AC4 | Entry supports optional photo attachment via S3 key reference | P1 | `TestGratitude_GL_DM_AC4_PhotoAttachment` |
| GL-DM-AC5 | Items are stored and returned ordered by their sortOrder field | P0 | `TestGratitude_GL_DM_AC5_ItemOrdering` |
| GL-DM-AC6 | Individual items can be favorited independently of the parent entry | P1 | `TestGratitude_GL_DM_AC6_ItemFavoriting` |
| GL-DM-AC7 | Entries are editable (PUT succeeds) within 24 hours of createdAt timestamp | P0 | `TestGratitude_GL_DM_AC7_EditWindow` |
| GL-DM-AC8 | Entries are read-only (PUT returns 403) after 24 hours from createdAt timestamp | P0 | `TestGratitude_GL_DM_AC8_ReadOnlyAfter24h` |
| GL-DM-AC9 | Multiple entries per day are saved independently, each with its own gratitudeId and timestamp | P0 | `TestGratitude_GL_DM_AC9_MultiplePerDay` |
| GL-DM-AC10 | CreatedAt timestamp is immutable and never modified on updates (FR2.7) | P0 | `TestGratitude_GL_DM_AC10_ImmutableCreatedAt` |
| GL-DM-AC11 | TenantId is present on all gratitude documents and enforced at the API layer | P0 | `TestGratitude_GL_DM_AC11_TenantIsolation` |

---

## 2. Entry Screen / Create API (GL-ES)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| GL-ES-AC1 | Entry requires minimum 1 non-empty item to save; an empty items array returns 422 | P0 | `TestGratitude_GL_ES_AC1_MinimumOneItem` |
| GL-ES-AC2 | Items have 300 character max; character counter shown in UI at 250+ characters | P0 | `TestGratitude_GL_ES_AC2_CharacterLimit` |
| GL-ES-AC3 | Unlimited items can be added per entry (no server-side max on items array length) | P0 | `TestGratitude_GL_ES_AC3_UnlimitedItems` |
| GL-ES-AC4 | Individual items are deletable before save (client-side); items removed from array before POST | P0 | `TestGratitude_GL_ES_AC4_DeleteBeforeSave` |
| GL-ES-AC5 | Optional category tag selectable per item from the GratitudeCategory enum | P1 | `TestGratitude_GL_ES_AC5_CategoryTag` |
| GL-ES-AC6 | Optional mood score 1-5 per entry; null/absent means no mood recorded | P1 | `TestGratitude_GL_ES_AC6_MoodScore` |
| GL-ES-AC7 | Gratitude prompt displayed on "Need a prompt?" tap; prompt returned from GET /activities/gratitude/prompts/daily | P1 | `TestGratitude_GL_ES_AC7_PromptDisplay` |
| GL-ES-AC8 | "Use this" inserts prompt text as a new item in the items array | P1 | `TestGratitude_GL_ES_AC8_PromptInsert` |
| GL-ES-AC9 | Successful save returns 201 with gratitudeId, currentStreak, and a warm message in meta | P0 | `TestGratitude_GL_ES_AC9_SaveConfirmation` |
| GL-ES-AC10 | After successful save, client clears form state (client-side responsibility) | P0 | `TestGratitude_GL_ES_AC10_ClearAfterSave` |
| GL-ES-AC11 | Entry editable within 24h via PUT; read-only after 24h returns 403 | P0 | `TestGratitude_GL_ES_AC11_EditWindow` |
| GL-ES-AC12 | Single photo attachable per entry via photoKey field | P1 | `TestGratitude_GL_ES_AC12_PhotoAttach` |
| GL-ES-AC13 | First-use onboarding text returned when user has zero prior entries (meta.isFirstEntry=true) | P1 | `TestGratitude_GL_ES_AC13_FirstUseText` |
| GL-ES-AC14 | Saving with 1 item is valid; response is identical in structure to multi-item entries | P0 | `TestGratitude_GL_ES_AC14_SingleItemValid` |
| GL-ES-AC15 | Opening the entry screen without saving records no data (no empty entry created on GET) | P0 | `TestGratitude_GL_ES_AC15_NoAbandonedTracking` |

---

## 3. History & Browse (GL-HS)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| GL-HS-AC1 | List endpoint returns entries in reverse chronological order by default | P0 | `TestGratitude_GL_HS_AC1_ReverseChronological` |
| GL-HS-AC2 | Entry response includes date, item count, first 2 items as preview (truncated to 100 chars each) | P0 | `TestGratitude_GL_HS_AC2_EntryCardPreview` |
| GL-HS-AC3 | Category tags included in list response for each entry | P1 | `TestGratitude_GL_HS_AC3_CategoryTagsVisible` |
| GL-HS-AC4 | Calendar endpoint returns array of dates with entry indicators for a given month | P1 | `TestGratitude_GL_HS_AC4_CalendarIndicators` |
| GL-HS-AC5 | Calendar date tap resolves to list of entries for that specific date | P1 | `TestGratitude_GL_HS_AC5_CalendarNavigation` |
| GL-HS-AC6 | Full-text search across all gratitude item text fields returns matching entries with highlighted items | P1 | `TestGratitude_GL_HS_AC6_SearchResults` |
| GL-HS-AC7 | Filters by category, date range, hasPhoto, and moodScore are combinable with AND logic | P1 | `TestGratitude_GL_HS_AC7_FilterCombination` |
| GL-HS-AC8 | Favorites endpoint returns all individually favorited items across all entries | P1 | `TestGratitude_GL_HS_AC8_FavoritesTab` |
| GL-HS-AC9 | PATCH item favorite toggle updates isFavorite on a specific item within an entry | P1 | `TestGratitude_GL_HS_AC9_FavoriteToggle` |
| GL-HS-AC10 | Detail view returns full entry; edit action available only when within 24h of createdAt | P0 | `TestGratitude_GL_HS_AC10_EditButtonVisibility` |

---

## 4. Trends & Insights (GL-TI)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| GL-TI-AC1 | Current streak counts consecutive calendar days (user timezone) with >= 1 gratitude entry | P0 | `TestGratitude_GL_TI_AC1_CurrentStreak` |
| GL-TI-AC2 | Longest streak tracks all-time best consecutive days | P0 | `TestGratitude_GL_TI_AC2_LongestStreak` |
| GL-TI-AC3 | Total days counts lifetime unique calendar days with at least one entry | P0 | `TestGratitude_GL_TI_AC3_TotalDays` |
| GL-TI-AC4 | Multiple entries on the same calendar day count as 1 day for streak purposes | P0 | `TestGratitude_GL_TI_AC4_MultipleEntriesSameDay` |
| GL-TI-AC5 | Category breakdown returns distribution percentages for selected period (30d, 90d, allTime) | P1 | `TestGratitude_GL_TI_AC5_CategoryBreakdown` |
| GL-TI-AC6 | Shift tracking compares current 30-day category distribution vs previous 30-day; only shown with >= 10 entries per period | P2 | `TestGratitude_GL_TI_AC6_ShiftTracking` |
| GL-TI-AC7 | Volume trend returns average items per entry for the selected period | P1 | `TestGratitude_GL_TI_AC7_AvgItemsPerEntry` |
| GL-TI-AC8 | Check-in score correlation insight requires >= 14 days of each type (gratitude days and non-gratitude days) before display | P2 | `TestGratitude_GL_TI_AC8_CheckInCorrelation` |
| GL-TI-AC9 | Inactivity warning triggered after user-configured threshold days (default: 3) with no gratitude entries | P1 | `TestGratitude_GL_TI_AC9_InactivityWarning` |
| GL-TI-AC10 | Evening commitment review responses do NOT count toward the gratitude streak | P0 | `TestGratitude_GL_TI_AC10_EveningReviewExcluded` |

---

## 5. Prompts (GL-PR)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| GL-PR-AC1 | 50+ prompts available in the bundled prompt library | P0 | `TestGratitude_GL_PR_AC1_PromptCount` |
| GL-PR-AC2 | Daily prompt is deterministic per user per day (same userId + same date = same prompt) | P0 | `TestGratitude_GL_PR_AC2_DeterministicDaily` |
| GL-PR-AC3 | "Different prompt" cycles to the next prompt in sequence (wraps around) | P1 | `TestGratitude_GL_PR_AC3_CyclePrompt` |
| GL-PR-AC4 | "Use this" records promptUsed on the entry and inserts prompt text as a new item | P1 | `TestGratitude_GL_PR_AC4_InsertAsItem` |
| GL-PR-AC5 | Each prompt is tagged with exactly one GratitudeCategory | P0 | `TestGratitude_GL_PR_AC5_PromptCategories` |
| GL-PR-AC6 | Prompts are distributed across all categories (minimum 3 per category) | P0 | `TestGratitude_GL_PR_AC6_CategoryDistribution` |

---

## 6. Sharing (GL-SH)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| GL-SH-AC1 | Individual gratitude items are shareable as plain text | P1 | `TestGratitude_GL_SH_AC1_ShareItem` |
| GL-SH-AC2 | Full entry shareable as combined text (all items concatenated) | P1 | `TestGratitude_GL_SH_AC2_ShareEntry` |
| GL-SH-AC3 | Shared content excludes moodScore, category tags, and photoKey -- only gratitude text and date | P0 | `TestGratitude_GL_SH_AC3_PrivacyFilter` |
| GL-SH-AC4 | Copy to clipboard produces plain text with one item per line | P1 | `TestGratitude_GL_SH_AC4_Clipboard` |
| GL-SH-AC5 | Styled graphic includes gratitude text, date, optional scripture, and "Regal Recovery" watermark | P2 | `TestGratitude_GL_SH_AC5_StyledGraphic` |
| GL-SH-AC6 | Share via in-app messaging to support network contacts respects community permissions | P1 | `TestGratitude_GL_SH_AC6_ShareSheet` |

---

## 7. Integrations (GL-IN)

| ID | Criterion | Priority | Test Reference |
|----|-----------|----------|----------------|
| GL-IN-AC1 | Evening review displays "You already captured X gratitude items today" when entries exist for the current day | P1 | `TestGratitude_GL_IN_AC1_EveningReviewCrossRef` |
| GL-IN-AC2 | Evening review gratitude prompt response does NOT create a gratitude entry or advance the gratitude streak | P0 | `TestGratitude_GL_IN_AC2_EveningReviewExcluded` |
| GL-IN-AC3 | Dashboard widget returns today's gratitude status (completed/notCompleted), current streak, and one random past item | P1 | `TestGratitude_GL_IN_AC3_DashboardWidget` |
| GL-IN-AC4 | Dashboard widget tap navigates to entry screen (if not done) or history screen (if done) | P1 | `TestGratitude_GL_IN_AC4_WidgetNavigation` |
| GL-IN-AC5 | Completing a gratitude entry feeds into daily recovery plan scoring and auto-checks matching goal | P1 | `TestGratitude_GL_IN_AC5_PlanScoring` |
| GL-IN-AC6 | Streak milestone notifications fire at correct thresholds: 7, 14, 30, 60, 90, 180, 365 days | P1 | `TestGratitude_GL_IN_AC6_StreakNotifications` |
| GL-IN-AC7 | Missed entry nudge respects user-configured inactivity threshold (default 3 days) and notification toggle | P1 | `TestGratitude_GL_IN_AC7_MissedNudge` |
| GL-IN-AC8 | Community permissions respected: spouse/counselor see gratitude text if permission granted; sponsor/AP do NOT see by default | P0 | `TestGratitude_GL_IN_AC8_CommunityPermissions` |
| GL-IN-AC9 | Gratitude entry creates a CALENDAR_ACTIVITY dual-write with activityType=GRATITUDE | P0 | `TestGratitude_GL_IN_AC9_CalendarActivity` |
| GL-IN-AC10 | Feature flag `activity.gratitude` controls all gratitude endpoints; disabled flag returns 404 | P0 | `TestGratitude_GL_IN_AC10_FeatureFlag` |

---

## Cross-Cutting Concerns

| ID | Criterion | Priority | Domain |
|----|-----------|----------|--------|
| GL-CC-AC1 | All gratitude endpoints require Bearer auth; missing/invalid token returns 401 | P0 | Auth |
| GL-CC-AC2 | All error responses follow the `{ "errors": [...] }` envelope with `rr:0x` error codes | P0 | Error handling |
| GL-CC-AC3 | All successful responses follow the `{ "data": ..., "links": {...}, "meta": {...} }` envelope | P0 | Response format |
| GL-CC-AC4 | Cursor-based pagination on list endpoints with `cursor` and `limit` query params | P0 | Pagination |
| GL-CC-AC5 | Offline entries sync on reconnection without data loss (union merge for entries, LWW for edits) | P0 | Offline-first |
| GL-CC-AC6 | Correlation ID (X-Correlation-Id) present on all responses for distributed tracing | P0 | Observability |

---

## Acceptance Criteria Summary

| Domain | Total ACs | P0 | P1 | P2 |
|--------|-----------|----|----|-----|
| Data Model (DM) | 11 | 9 | 2 | 0 |
| Entry Screen (ES) | 15 | 8 | 7 | 0 |
| History (HS) | 10 | 3 | 7 | 0 |
| Trends (TI) | 10 | 4 | 4 | 2 |
| Prompts (PR) | 6 | 4 | 2 | 0 |
| Sharing (SH) | 6 | 1 | 4 | 1 |
| Integrations (IN) | 10 | 4 | 6 | 0 |
| Cross-Cutting (CC) | 6 | 6 | 0 | 0 |
| **Total** | **74** | **39** | **32** | **3** |
