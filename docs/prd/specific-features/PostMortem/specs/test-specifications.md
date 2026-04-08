# Post-Mortem Analysis -- Test Specifications

**Version:** 1.0.0
**Date:** 2026-04-07
**Status:** Draft

---

## Naming Convention

Test names follow the project convention: `Test<Component>_<AC-Reference>_<Behavior>`

All acceptance criteria IDs reference `docs/prd/specific-features/PostMortem/specs/acceptance-criteria.md`.

---

## 1. Unit Tests (60-70% of test budget)

### 1.1 Domain Logic: Post-Mortem Creation

```
TestPostMortem_PM_AC1_1_SixSectionStructure
  Given a new post-mortem request
  When all six sections are provided
  Then the analysis is created with sections: dayBefore, morning, throughoutTheDay, buildUp, actingOut, immediatelyAfter

TestPostMortem_PM_AC1_2_DayBeforeSection_MoodRatingRange
  Given a dayBefore section with moodRating
  When moodRating is outside 1-10
  Then validation fails with error

TestPostMortem_PM_AC1_2_DayBeforeSection_AcceptsFreeText
  Given a dayBefore section with text
  When text is within 5000 char limit
  Then section is accepted

TestPostMortem_PM_AC1_2_DayBeforeSection_RejectsExcessiveText
  Given a dayBefore section with text exceeding 5000 chars
  When validated
  Then validation fails with max length error

TestPostMortem_PM_AC1_3_MorningSection_AutoPopulatedData
  Given a morning section with autoPopulated data
  When the section loads
  Then autoPopulated fields (morningCommitmentCompleted, moodRating, affirmationViewed) are included

TestPostMortem_PM_AC1_4_ThroughoutTheDay_TimeBlockValidation
  Given a throughoutTheDay section with time blocks
  When time blocks use valid periods (morning, midday, afternoon, evening)
  Then all blocks are accepted

TestPostMortem_PM_AC1_4_ThroughoutTheDay_InvalidPeriodRejected
  Given a throughoutTheDay section with an invalid period name
  When validated
  Then validation fails

TestPostMortem_PM_AC1_5_WarningSignTagging
  Given a time block with warningSigns
  When warningSigns include valid FASTER stages and PCI behaviors
  Then they are accepted and stored

TestPostMortem_PM_AC1_6_BuildUp_DecisionPointStructure
  Given a buildUp section with decision points
  When each decision point has timeOfDay, couldHaveDone, and insteadDid
  Then the decision points are valid

TestPostMortem_PM_AC1_6_BuildUp_TriggerCategories
  Given a buildUp section with triggers
  When trigger categories are from the valid set (emotional, environmental, relational, physical, digital, spiritual)
  Then they are accepted

TestPostMortem_PM_AC1_6_BuildUp_InvalidTriggerCategoryRejected
  Given a buildUp section with an unknown trigger category
  When validated
  Then validation fails

TestPostMortem_PM_AC1_7_ActingOut_DurationMinutesPositive
  Given an actingOut section with durationMinutes
  When durationMinutes is 0 or negative
  Then validation fails

TestPostMortem_PM_AC1_7_ActingOut_CompassionateToneRequired
  Given an actingOut section
  When the section structure is validated
  Then no field labels contain shame-based language

TestPostMortem_PM_AC1_8_ImmediatelyAfter_FeelingsWheelIntegration
  Given an immediatelyAfter section
  When feelings and feelingsWheelSelections are provided
  Then both arrays are stored

TestPostMortem_PM_AC1_9_RelapseIdOptional
  Given a post-mortem creation request without relapseId
  When eventType is "near-miss"
  Then the post-mortem is created successfully

TestPostMortem_PM_AC1_9_RelapseIdLinked
  Given a post-mortem creation request with relapseId
  When eventType is "relapse"
  Then the post-mortem is linked to the relapse record
```

### 1.2 Domain Logic: Draft Management

```
TestPostMortem_PM_AC2_1_AutoSaveDraft
  Given a post-mortem with only partial sections completed
  When saved
  Then status is "draft" and completedAt is null

TestPostMortem_PM_AC2_3_DraftToCompleteTransition
  Given a draft post-mortem with all sections and action plan completed
  When submitted
  Then status transitions to "complete" and completedAt is set

TestPostMortem_PM_AC2_3_IncompleteCannotBeCompleted
  Given a draft post-mortem missing required sections
  When completion is attempted
  Then validation fails with error listing missing sections
```

### 1.3 Domain Logic: Trigger Analysis

```
TestPostMortem_PM_AC4_1_QuickSelectTriggers
  Given trigger categories
  When validating against allowed categories
  Then only (emotional, environmental, relational, physical, digital, spiritual) are accepted

TestPostMortem_PM_AC4_2_DeepTriggerExploration
  Given a trigger with three layers (surface, underlying, coreWound)
  When all three layers are provided
  Then the full trigger chain is stored

TestPostMortem_PM_AC4_2_DeepTriggerExploration_PartialLayers
  Given a trigger with only surface layer
  When underlying and coreWound are null
  Then the trigger is still accepted (partial exploration is OK)
```

### 1.4 Domain Logic: FASTER Scale Mapping

```
TestPostMortem_PM_AC5_1_StageMapping
  Given FASTER mapping entries
  When each entry has a valid stage (forgetting-priorities, anxiety, speeding-up, ticked-off, exhausted, relapse)
  Then the mapping is accepted

TestPostMortem_PM_AC5_1_InvalidStageRejected
  Given a FASTER mapping with an invalid stage name
  When validated
  Then validation fails

TestPostMortem_PM_AC5_2_PrePopulatedSuggestions
  Given walkthrough text mentioning "skipping meetings"
  When suggestions are generated
  Then "forgetting-priorities" is suggested as a FASTER stage
```

### 1.5 Domain Logic: Action Plan

```
TestPostMortem_PM_AC6_1_StructuredActionItem
  Given an action item with timelinePoint, action, and category
  When category is one of (spiritual, relational, emotional, physical, practical)
  Then the item is accepted

TestPostMortem_PM_AC6_1_InvalidCategoryRejected
  Given an action item with an invalid category
  When validated
  Then validation fails

TestPostMortem_PM_AC6_2_MinimumOneActionItem
  Given a post-mortem being completed
  When actionPlan has 0 items
  Then completion fails with error

TestPostMortem_PM_AC6_2_MaximumTenActionItems
  Given a post-mortem with 11 action items
  When validated
  Then validation fails with max items error

TestPostMortem_PM_AC6_3_ConvertToCommitment
  Given an action item in a completed post-mortem
  When converted to a commitment
  Then the commitment is created with sourcePostMortemId set
```

### 1.6 Domain Logic: Sharing

```
TestPostMortem_PM_AC7_1_OptInSharing
  Given a completed post-mortem
  When sharing is configured for specific contacts
  Then the sharing.sharedWith array is populated per-contact

TestPostMortem_PM_AC7_2_FullVsSummaryShare
  Given a sharing configuration
  When shareType is "full" or "summary"
  Then the value is accepted

TestPostMortem_PM_AC7_2_InvalidShareTypeRejected
  Given a sharing configuration with shareType "invalid"
  When validated
  Then validation fails

TestPostMortem_PM_AC7_5_PermissionCheckOnAccess
  Given a contact without post-mortem read permission
  When they request access to a shared post-mortem
  Then access is denied (returns 404, not 403)

TestPostMortem_PM_AC7_5_PermissionCheckGranted
  Given a contact with post-mortem read permission
  When they request access to a post-mortem shared with them
  Then access is granted and the analysis is returned
```

### 1.7 Domain Logic: Pattern Analysis

```
TestPostMortem_PM_AC8_3_CommonTriggers
  Given 3 completed post-mortems with overlapping triggers
  When cross-analysis is computed
  Then triggers are ranked by frequency across all analyses

TestPostMortem_PM_AC8_4_FasterStageAtPointOfNoReturn
  Given 3 completed post-mortems with FASTER mapping
  When cross-analysis is computed
  Then the most frequent stage at the last entry before relapse is identified

TestPostMortem_PM_AC8_5_CommonTimeOfDay
  Given 3 completed post-mortems with actingOut sections
  When cross-analysis is computed
  Then the most common time block for acting out is identified

TestPostMortem_PM_AC8_6_RecurringDecisionPoints
  Given 3 completed post-mortems with decision points
  When cross-analysis is computed
  Then recurring themes in decision points are surfaced
```

### 1.8 Domain Logic: Edge Cases

```
TestPostMortem_PM_AC11_2_CombinedEventType
  Given a post-mortem with eventType "combined"
  When relapseId is null (covers multiple events)
  Then the post-mortem is valid

TestPostMortem_PM_AC11_4_NearMissEventType
  Given a post-mortem with eventType "near-miss"
  When relapseId is null
  Then the post-mortem is valid

TestPostMortem_PM_AC11_4_NearMissWithRelapseIdRejected
  Given a post-mortem with eventType "near-miss" AND a relapseId
  When validated
  Then validation fails (near-miss cannot have relapse link)
```

### 1.9 Domain Logic: Data Integrity

```
TestPostMortem_PM_AC13_1_ImmutableTimestamp
  Given an existing post-mortem
  When an update attempts to modify createdAt
  Then the update fails with "timestamp is immutable" error

TestPostMortem_PM_AC13_2_TenantIsolation
  Given a post-mortem belonging to tenant A
  When a user from tenant B queries for it
  Then no result is returned (404)
```

### 1.10 Domain Logic: Feature Flag

```
TestPostMortem_PM_AC12_1_FlagDisabled_Returns404
  Given the feature flag "activity.post-mortem" is disabled
  When any post-mortem endpoint is called
  Then 404 is returned

TestPostMortem_PM_AC12_2_FlagEnabled_AllowsAccess
  Given the feature flag "activity.post-mortem" is enabled
  When post-mortem endpoints are called
  Then normal functionality is available
```

### 1.11 Handler Tests

```
TestPostMortemHandler_Create_ValidRequest_Returns201
  Given a valid CreatePostMortemRequest
  When POST /activities/post-mortem is called
  Then HTTP 201 is returned with Location header and PostMortemResponse body

TestPostMortemHandler_Create_MissingSections_Returns422
  Given a request missing required sections
  When POST /activities/post-mortem is called
  Then HTTP 422 is returned with validation errors

TestPostMortemHandler_Create_InvalidEventType_Returns422
  Given a request with eventType "unknown"
  When POST /activities/post-mortem is called
  Then HTTP 422 is returned

TestPostMortemHandler_List_ReturnsPaginatedResults
  Given multiple post-mortems for a user
  When GET /activities/post-mortem?limit=10 is called
  Then paginated results with cursor are returned

TestPostMortemHandler_List_FilterByDateRange
  Given post-mortems across multiple dates
  When GET /activities/post-mortem?startDate=2026-03-01&endDate=2026-03-31 is called
  Then only post-mortems within the date range are returned

TestPostMortemHandler_List_FilterByAddictionId
  Given post-mortems for multiple addictions
  When GET /activities/post-mortem?addictionId=a_67890 is called
  Then only post-mortems for that addiction are returned

TestPostMortemHandler_Get_ById_Returns200
  Given an existing post-mortem
  When GET /activities/post-mortem/{analysisId} is called
  Then the full analysis is returned

TestPostMortemHandler_Get_NotFound_Returns404
  Given a nonexistent analysisId
  When GET /activities/post-mortem/{analysisId} is called
  Then HTTP 404 is returned

TestPostMortemHandler_Update_DraftSections_Returns200
  Given a draft post-mortem
  When PATCH /activities/post-mortem/{analysisId} is called with section updates
  Then the draft is updated and HTTP 200 is returned

TestPostMortemHandler_Update_CompletedPostMortem_ActionPlanOnly
  Given a completed post-mortem
  When PATCH attempts to modify sections (not action plan)
  Then HTTP 422 is returned (completed analyses are immutable except for action plan and sharing)

TestPostMortemHandler_Complete_Returns200
  Given a draft post-mortem with all required sections
  When POST /activities/post-mortem/{analysisId}/complete is called
  Then status transitions to "complete" and HTTP 200 is returned

TestPostMortemHandler_Complete_MissingSections_Returns422
  Given a draft with missing required sections
  When POST /activities/post-mortem/{analysisId}/complete is called
  Then HTTP 422 with missing section list is returned

TestPostMortemHandler_Share_Returns200
  Given a completed post-mortem
  When POST /activities/post-mortem/{analysisId}/share is called with contacts
  Then sharing is configured and HTTP 200 is returned

TestPostMortemHandler_Share_DraftNotAllowed_Returns422
  Given a draft post-mortem
  When POST /activities/post-mortem/{analysisId}/share is called
  Then HTTP 422 is returned (cannot share drafts)

TestPostMortemHandler_Insights_Returns200
  Given 3+ completed post-mortems
  When GET /activities/post-mortem/insights is called
  Then cross-analysis insights are returned

TestPostMortemHandler_Insights_InsufficientData_ReturnsEmpty
  Given fewer than 2 completed post-mortems
  When GET /activities/post-mortem/insights is called
  Then empty insights with a message explaining minimum data needed

TestPostMortemHandler_ConvertActionItem_Returns201
  Given a completed post-mortem with action items
  When POST /activities/post-mortem/{analysisId}/action-items/{actionId}/convert is called
  Then a commitment or goal is created and the action item is updated with the reference

TestPostMortemHandler_Export_ReturnsPDF
  Given a completed post-mortem
  When GET /activities/post-mortem/{analysisId}/export?format=pdf is called
  Then a PDF binary is returned with Content-Type application/pdf
```

---

## 2. Integration Tests (20-30% of test budget)

### 2.1 Repository Tests (MongoDB)

```
TestPostMortemRepository_Create_PersistsDocument
  Given a valid post-mortem domain object
  When saved to MongoDB
  Then the document is retrievable by analysisId with all fields intact

TestPostMortemRepository_List_ReturnsReverseChronological
  Given 5 post-mortems created at different times
  When listed with default sort
  Then results are in reverse chronological order

TestPostMortemRepository_List_CursorPagination
  Given 25 post-mortems
  When listed with limit=10
  Then 10 results are returned with a nextCursor, and using that cursor returns the next 10

TestPostMortemRepository_FindByRelapseId
  Given a post-mortem linked to relapseId "r_98765"
  When queried by relapseId
  Then the linked post-mortem is returned

TestPostMortemRepository_FindDrafts
  Given 3 draft and 2 complete post-mortems
  When queried with status="draft"
  Then only the 3 drafts are returned

TestPostMortemRepository_FilterByAddiction
  Given post-mortems for 2 different addictions
  When filtered by addictionId
  Then only matching post-mortems are returned

TestPostMortemRepository_FilterByDateRange
  Given post-mortems spanning 3 months
  When filtered by startDate and endDate
  Then only post-mortems within the range are returned

TestPostMortemRepository_Update_ModifiesDocument
  Given an existing draft post-mortem
  When sections are updated
  Then the document reflects the changes and modifiedAt is updated

TestPostMortemRepository_Update_PreservesImmutableFields
  Given an existing post-mortem
  When an update includes createdAt
  Then createdAt remains unchanged

TestPostMortemRepository_SharedPostMortemsForContact
  Given 2 post-mortems shared with contact "c_99999"
  When queried by contactId
  Then both shared post-mortems are returned

TestPostMortemRepository_TenantIsolation
  Given post-mortems in tenants A and B
  When tenant A queries
  Then only tenant A's post-mortems are returned
```

### 2.2 Calendar Activity Dual-Write

```
TestPostMortemRepository_CalendarDualWrite_OnComplete
  Given a post-mortem transitions from draft to complete
  When the completion is persisted
  Then a POSTMORTEM entry is written to the calendarActivities collection

TestPostMortemRepository_CalendarDualWrite_NotOnDraft
  Given a new draft post-mortem is created
  When persisted
  Then no calendarActivities entry is written
```

### 2.3 Event Processing

```
TestPostMortemEventHandler_RelapseEvent_TriggersReminder
  Given a relapse event is published to SQS
  When 24 hours pass without a post-mortem being created
  Then a gentle reminder notification is sent

TestPostMortemEventHandler_RelapseEvent_PostMortemCreated_NoReminder
  Given a relapse event is published and the user creates a post-mortem within 24 hours
  When the reminder check runs
  Then no reminder is sent

TestPostMortemEventHandler_CompletionEvent_UpdatesAnalytics
  Given a post-mortem is completed
  When the completion event is published
  Then the analytics service receives the post-mortem completion metric
```

### 2.4 Valkey Cache

```
TestPostMortemCache_InsightsAreCached
  Given insights have been computed for a user
  When insights are requested again within TTL
  Then cached insights are returned (no DB query)

TestPostMortemCache_InsightsInvalidatedOnNewPostMortem
  Given cached insights exist
  When a new post-mortem is completed
  Then the insights cache is invalidated
```

---

## 3. End-to-End Tests (5-10% of test budget)

### 3.1 Full Post-Mortem Flow

```
TestPostMortem_E2E_CompleteRelapseFlow
  Given an authenticated user with a recent relapse
  1. POST /activities/post-mortem (create draft with dayBefore section)
  2. PATCH /activities/post-mortem/{id} (add morning section)
  3. PATCH /activities/post-mortem/{id} (add throughoutTheDay section)
  4. PATCH /activities/post-mortem/{id} (add buildUp section)
  5. PATCH /activities/post-mortem/{id} (add actingOut section)
  6. PATCH /activities/post-mortem/{id} (add immediatelyAfter section)
  7. PATCH /activities/post-mortem/{id} (add FASTER mapping)
  8. PATCH /activities/post-mortem/{id} (add action plan)
  9. POST /activities/post-mortem/{id}/complete
  Then status is "complete", completedAt is set, calendar activity is created

TestPostMortem_E2E_NearMissFlow
  Given an authenticated user who resisted an urge
  1. POST /activities/post-mortem (eventType: "near-miss", no relapseId)
  2. Complete all sections
  3. POST /activities/post-mortem/{id}/complete
  Then the near-miss analysis is saved and available in history

TestPostMortem_E2E_ShareWithSponsor
  Given a completed post-mortem and a sponsor with post-mortem permission
  1. POST /activities/post-mortem/{id}/share (contactId: sponsor, shareType: "full")
  2. Sponsor GETs /activities/post-mortem/{id} (as sponsor user)
  Then sponsor can view the full analysis

TestPostMortem_E2E_ShareDeniedWithoutPermission
  Given a completed post-mortem and a sponsor WITHOUT post-mortem permission
  1. POST /activities/post-mortem/{id}/share (contactId: sponsor)
  2. Sponsor GETs /activities/post-mortem/{id}
  Then 404 is returned (not 403)

TestPostMortem_E2E_ConvertActionItemToCommitment
  Given a completed post-mortem with action items
  1. POST /activities/post-mortem/{id}/action-items/{actionId}/convert (type: "commitment")
  2. GET /activities/commitments
  Then the new commitment exists with sourcePostMortemId reference

TestPostMortem_E2E_InsightsAfterMultiplePostMortems
  Given 3 completed post-mortems with overlapping triggers and FASTER data
  1. GET /activities/post-mortem/insights
  Then insights include commonTriggers, commonFasterStage, commonTimeOfDay, recurringDecisionPoints

TestPostMortem_E2E_OfflineSync
  Given a post-mortem created offline
  When the device reconnects and syncs
  Then the post-mortem appears in the server list with correct timestamps

TestPostMortem_E2E_FeatureFlagDisabled
  Given the "activity.post-mortem" flag is disabled
  When any post-mortem endpoint is called
  Then 404 is returned for all endpoints
```

---

## 4. Contract Tests

```
TestPostMortemContract_CreateRequest_MatchesOpenAPISchema
  Given the CreatePostMortemRequest schema from openapi.yaml
  When a Go CreatePostMortemRequest struct is serialized to JSON
  Then the JSON matches the OpenAPI schema exactly (field names, types, required fields)

TestPostMortemContract_PostMortemResponse_MatchesOpenAPISchema
  Given the PostMortemResponse schema from openapi.yaml
  When a Go PostMortemResponse struct is serialized to JSON
  Then the JSON matches the OpenAPI schema (camelCase fields, correct types, envelope structure)

TestPostMortemContract_ErrorResponse_MatchesOpenAPISchema
  Given an error condition
  When the handler returns an error
  Then the response matches the Siemens error envelope format with rr: error codes

TestPostMortemContract_PaginationResponse_MatchesOpenAPISchema
  Given a list endpoint response
  When paginated results are returned
  Then the response includes data array, links (self, next), and meta.page (nextCursor, limit)

TestPostMortemContract_InsightsResponse_MatchesOpenAPISchema
  Given the PostMortemInsightsResponse schema
  When insights are returned
  Then the response matches the schema
```

---

## 5. Persona Test Fixtures

### Alex (Long-term recovery, has sponsor, married)

```
Fixture: AlexPostMortemAfterRelapse
  - eventType: "relapse"
  - relapseId: linked to Alex's relapse record
  - Trigger pattern: evening vulnerability, digital, emotional
  - FASTER progression: full F-A-S-T-E-R over 12 hours
  - Action plan: 3 items focused on relational and practical changes

Fixture: AlexPostMortemNearMiss
  - eventType: "near-miss"
  - No relapseId
  - Trigger pattern: digital, physical (fatigue)
  - FASTER progression: F-A-S only (caught early)
  - Action plan: 2 items reinforcing what worked
```

### Marcus (No sponsor, evening vulnerability, 73-day streak)

```
Fixture: MarcusFirstPostMortem
  - eventType: "relapse"
  - No sponsor to share with
  - Trigger pattern: digital, emotional, isolation
  - FASTER progression: skipped stages (F directly to E-R)
  - Action plan: 4 items including finding a sponsor

Fixture: MarcusDraftPostMortem
  - status: "draft"
  - Only dayBefore and morning sections completed
  - Tests resume flow
```

### Diego (Spanish language, married, afternoon vulnerability)

```
Fixture: DiegoPostMortemCombined
  - eventType: "combined" (two relapses in a weekend)
  - Trigger pattern: relational, spiritual, physical
  - FASTER progression: afternoon-focused timeline
  - Action plan: 5 items spanning all categories
```
