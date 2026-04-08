# Meetings Attended -- Test Specifications

**Feature:** Meetings Attended Activity
**Priority:** P1 (Wave 2)
**Feature Flag:** `activity.meetings`

---

## 1. Unit Tests (70%)

Location: `internal/domain/meetings/*_test.go`

### 1.1 Meeting Log Creation

```
TestMeetingLog_FR_MTG_1_1_CreateWithRequiredFieldsOnly
  Given: timestamp and meetingType provided
  When: meeting log is created
  Then: meetingId generated, status defaults to "attended", optional fields null

TestMeetingLog_FR_MTG_1_2_ValidMeetingTypes
  Given: each valid meeting type (SA, CR, AA, therapy, group-counseling, church, custom)
  When: meeting log is created with that type
  Then: creation succeeds for all valid types

TestMeetingLog_FR_MTG_1_2_InvalidMeetingType_Rejected
  Given: an invalid meeting type ("SAA", "NA", "invalid")
  When: meeting log creation is attempted
  Then: validation error returned (SAA is explicitly excluded)

TestMeetingLog_FR_MTG_1_3_CustomTypeRequiresLabel
  Given: meetingType is "custom" and customTypeLabel is empty
  When: meeting log creation is attempted
  Then: validation error returned requiring customTypeLabel

TestMeetingLog_FR_MTG_1_3_CustomTypeWithLabel
  Given: meetingType is "custom" and customTypeLabel is "Men's Group"
  When: meeting log is created
  Then: both meetingType and customTypeLabel are stored

TestMeetingLog_FR_MTG_1_3_CustomTypeLabelMaxLength
  Given: customTypeLabel exceeds 100 characters
  When: meeting log creation is attempted
  Then: validation error returned

TestMeetingLog_FR_MTG_1_4_AllOptionalFields
  Given: all optional fields provided (name, location, durationMinutes, notes)
  When: meeting log is created
  Then: all fields stored and returned on retrieval

TestMeetingLog_FR_MTG_1_4_NotesMaxLength
  Given: notes exceed 2000 characters
  When: meeting log creation is attempted
  Then: validation error returned

TestMeetingLog_FR_MTG_1_4_NameMaxLength
  Given: name exceeds 200 characters
  When: meeting log creation is attempted
  Then: validation error returned

TestMeetingLog_FR_MTG_1_4_DurationMinutesNonNegative
  Given: durationMinutes is -1
  When: meeting log creation is attempted
  Then: validation error returned

TestMeetingLog_FR_MTG_1_5_TimestampImmutable
  Given: an existing meeting log with timestamp "2026-03-28T19:00:00Z"
  When: update is attempted with a different timestamp
  Then: update is rejected with 422, timestamp unchanged

TestMeetingLog_FR_MTG_1_6_MultipleMeetingsSameDay
  Given: a meeting already logged for 2026-03-28
  When: another meeting is logged for 2026-03-28 at a different time
  Then: both meetings are stored with unique meetingIds
```

### 1.2 Saved Meetings

```
TestSavedMeeting_FR_MTG_2_1_CreateWithRequiredFields
  Given: name and meetingType provided
  When: saved meeting is created
  Then: savedMeetingId generated, isActive defaults to true

TestSavedMeeting_FR_MTG_2_1_CreateWithSchedule
  Given: name, meetingType, and schedule (dayOfWeek, time, timeZone) provided
  When: saved meeting is created
  Then: schedule stored correctly, can be used for reminder scheduling

TestSavedMeeting_FR_MTG_2_2_OneTapLogging
  Given: a saved meeting with id "sm_11111" exists with type SA, name, and location
  When: a meeting log is created with savedMeetingId "sm_11111" and only a timestamp
  Then: meeting log is created with type, name, and location pre-filled from the template

TestSavedMeeting_FR_MTG_2_2_OneTapLoggingOverridesAllowed
  Given: a saved meeting template exists
  When: a meeting log is created with savedMeetingId and explicit overrides for name and notes
  Then: the overridden fields take precedence over template defaults

TestSavedMeeting_FR_MTG_2_3_ListSavedMeetings_SortedByName
  Given: user has saved meetings "Zion Church", "AA Downtown", "Tuesday Night"
  When: saved meetings list is requested
  Then: returned in alphabetical order: "AA Downtown", "Tuesday Night", "Zion Church"

TestSavedMeeting_FR_MTG_2_3_ListSavedMeetings_ExcludesInactive
  Given: user has 3 active and 1 soft-deleted saved meeting
  When: saved meetings list is requested
  Then: only the 3 active saved meetings are returned

TestSavedMeeting_FR_MTG_2_4_UpdateDoesNotAffectPastLogs
  Given: meeting logs exist referencing saved meeting "sm_11111" with name "Old Name"
  When: saved meeting "sm_11111" name is updated to "New Name"
  Then: previously logged meetings still show "Old Name"

TestSavedMeeting_FR_MTG_2_5_DeleteSoftDeletes
  Given: a saved meeting "sm_11111" exists
  When: it is deleted
  Then: isActive is set to false, document still exists in database

TestSavedMeeting_FR_MTG_2_5_DeletedSavedMeetingNotInList
  Given: a saved meeting is soft-deleted
  When: saved meetings list is requested
  Then: the deleted meeting is not included

TestSavedMeeting_FR_MTG_2_1_InvalidReminderMinutes
  Given: reminderMinutesBefore is set to 45 (not in [15, 30, 60])
  When: saved meeting creation is attempted
  Then: validation error returned
```

### 1.3 Meeting Log Updates

```
TestMeetingLogUpdate_FR_MTG_4_1_UpdateAllowedFields
  Given: an existing meeting log
  When: PATCH with name, location, durationMinutes, notes
  Then: all fields updated, modifiedAt refreshed, timestamp unchanged

TestMeetingLogUpdate_FR_MTG_4_1_TimestampInPatchRejected
  Given: an existing meeting log
  When: PATCH request includes a timestamp field
  Then: 422 error returned, meeting unchanged

TestMeetingLogUpdate_FR_MTG_4_2_MarkAsCanceled
  Given: an existing meeting log with status "attended"
  When: PATCH with status "canceled"
  Then: status updated to "canceled", document preserved

TestMeetingLogUpdate_FR_MTG_4_2_CanceledPreservesDocument
  Given: a meeting marked as canceled
  When: meeting list is retrieved
  Then: canceled meeting appears in the list with status "canceled"
```

### 1.4 Attendance Summary

```
TestAttendanceSummary_FR_MTG_3_5_WeeklyCount
  Given: user has 3 meetings in the current week
  When: summary is requested with period "week"
  Then: totalCount is 3, date range covers Monday-Sunday of the week

TestAttendanceSummary_FR_MTG_3_5_MonthlyByType
  Given: user has 8 SA, 3 therapy, and 1 church meeting in March
  When: summary is requested with period "month" and date "2026-03-15"
  Then: totalCount is 12, byType shows correct breakdown

TestAttendanceSummary_FR_MTG_3_5_ExcludesCanceled
  Given: user has 10 attended and 2 canceled meetings in a month
  When: summary is requested
  Then: totalCount is 10, canceledCount is 2

TestAttendanceSummary_FR_MTG_3_5_EmptyPeriod
  Given: user has no meetings in the requested period
  When: summary is requested
  Then: totalCount is 0, byType is empty object
```

### 1.5 Feature Flag Gating

```
TestMeetingLog_NFR_MTG_5_FlagDisabled_Returns404
  Given: feature flag "activity.meetings" is disabled
  When: any meeting endpoint is called
  Then: 404 Not Found returned (fail closed)

TestMeetingLog_NFR_MTG_5_FlagEnabled_EndpointsAccessible
  Given: feature flag "activity.meetings" is enabled
  When: meeting endpoints are called
  Then: endpoints respond normally
```

### 1.6 Permission Checks

```
TestMeetingLog_FR_MTG_5_3_SponsorWithPermission_CanView
  Given: sponsor has been granted "meetings" permission for the user
  When: sponsor requests the user's meeting logs
  Then: meeting logs are returned (notes included based on permission level)

TestMeetingLog_FR_MTG_5_3_SponsorWithoutPermission_Gets404
  Given: sponsor has NOT been granted "meetings" permission
  When: sponsor requests the user's meeting logs
  Then: 404 Not Found (existence not disclosed)

TestMeetingLog_FR_MTG_5_3_NoDefaultAccessForAnyone
  Given: a sponsor/counselor/coach exists but no explicit permission granted
  When: they attempt to view meeting data
  Then: 404 returned (opt-in model, fail closed)
```

---

## 2. Integration Tests (20%)

Location: `test/integration/meetings/`

### 2.1 Repository Layer

```
TestMeetingRepository_CreateAndRetrieve_MongoDB
  Given: MongoDB connection to test database
  When: meeting log is created and retrieved by meetingId
  Then: all fields round-trip correctly including timestamps

TestMeetingRepository_ListByDateRange_MongoDB
  Given: 10 meeting logs spanning March 2026
  When: queried with startDate=2026-03-10 and endDate=2026-03-20
  Then: only meetings within range returned, ordered by timestamp desc

TestMeetingRepository_ListByType_MongoDB
  Given: meetings of types SA, therapy, and church
  When: filtered by meetingType=SA
  Then: only SA meetings returned

TestMeetingRepository_CursorPagination_MongoDB
  Given: 75 meeting logs
  When: first page requested with limit=50
  Then: 50 results returned with nextCursor; second page returns remaining 25 with null nextCursor

TestMeetingRepository_Delete_RemovesMeetingAndCalendarActivity
  Given: a meeting log and its calendar activity dual-write entry
  When: meeting is deleted
  Then: both documents removed from MongoDB

TestSavedMeetingRepository_CreateAndList_MongoDB
  Given: 3 saved meetings created
  When: list is requested
  Then: all 3 returned sorted by name

TestSavedMeetingRepository_SoftDelete_MongoDB
  Given: a saved meeting is soft-deleted
  When: direct document lookup performed
  Then: document exists with isActive=false

TestMeetingRepository_CalendarDualWrite_MongoDB
  Given: a meeting log is created
  When: calendar activities queried for the same day
  Then: MEETING calendar activity exists with correct summary
```

### 2.2 Handler Layer (HTTP)

```
TestMeetingHandler_POST_201_CreatesAndReturnsLocation
  Given: valid CreateMeetingLogRequest JSON
  When: POST /v1/activities/meetings
  Then: 201 Created, Location header set, response body matches spec

TestMeetingHandler_POST_400_MalformedJSON
  Given: invalid JSON body
  When: POST /v1/activities/meetings
  Then: 400 Bad Request with error envelope

TestMeetingHandler_POST_422_MissingRequiredField
  Given: request body missing meetingType
  When: POST /v1/activities/meetings
  Then: 422 Unprocessable Entity with source pointer

TestMeetingHandler_GET_200_ListWithPagination
  Given: meeting logs exist for the user
  When: GET /v1/activities/meetings?limit=10
  Then: 200 OK with paginated response, links.next set if more results

TestMeetingHandler_GET_200_FilterByTypeAndDateRange
  Given: meetings of various types and dates
  When: GET /v1/activities/meetings?meetingType=SA&startDate=2026-03-01&endDate=2026-03-31
  Then: 200 OK with only matching meetings

TestMeetingHandler_GET_meetingId_404_NotFound
  Given: meetingId does not exist
  When: GET /v1/activities/meetings/mt_nonexistent
  Then: 404 Not Found

TestMeetingHandler_PATCH_422_TimestampImmutable
  Given: existing meeting log
  When: PATCH /v1/activities/meetings/mt_33333 with timestamp field
  Then: 422 error with detail "timestamp is immutable"

TestMeetingHandler_DELETE_204
  Given: existing meeting log
  When: DELETE /v1/activities/meetings/mt_33333
  Then: 204 No Content, subsequent GET returns 404

TestMeetingHandler_SummaryEndpoint_200
  Given: meeting logs for the month
  When: GET /v1/activities/meetings/summary?period=month&date=2026-03-15
  Then: 200 OK with attendance summary
```

### 2.3 Event Publishing

```
TestMeetingCreated_PublishesCommitmentEvent
  Given: meeting log created for user with "attend 3 meetings/week" commitment
  When: SQS message queue is checked
  Then: commitment progress event published with meetingId and userId

TestMeetingCreated_PublishesCalendarActivityEvent
  Given: meeting log created
  When: calendar activity collection is queried
  Then: dual-write entry exists with activityType MEETING
```

---

## 3. End-to-End Tests (10%)

Location: `test/e2e/meetings/`

### 3.1 Full User Flow

```
TestMeeting_E2E_CreateSavedMeeting_LogFromTemplate_ViewHistory
  Given: authenticated user on staging
  When:
    1. POST /v1/activities/meetings/saved (create saved meeting)
    2. POST /v1/activities/meetings (log from saved template)
    3. GET /v1/activities/meetings (view history)
    4. GET /v1/activities/meetings/summary?period=week
  Then:
    - Saved meeting created (201)
    - Meeting logged with template pre-fill (201)
    - Meeting appears in history list
    - Summary shows 1 meeting for the week

TestMeeting_E2E_SponsorViewsAttendance_WithPermission
  Given: user has granted sponsor "meetings" permission
  When:
    1. User logs 3 meetings this week
    2. Sponsor requests user's meeting logs
  Then: sponsor sees all 3 meetings

TestMeeting_E2E_SponsorViewsAttendance_WithoutPermission
  Given: user has NOT granted sponsor "meetings" permission
  When: sponsor requests user's meeting logs
  Then: 404 Not Found (opt-in model)

TestMeeting_E2E_CalendarIntegration
  Given: user has meetings, check-ins, and urge logs on the same day
  When: GET /v1/tracking/calendar?date=2026-03-28
  Then: all activities appear in calendar view including the meeting

TestMeeting_E2E_MeetingCanceled_CommitmentStreak
  Given: user has "attend 3 meetings/week" commitment and 2 attended, 1 canceled
  When: commitment status is checked
  Then: commitment progress reflects user's cancelation preference setting
```

### 3.2 Contract Tests

```
TestMeeting_Contract_CreateMeetingLog_MatchesOpenAPISpec
  Validates: POST /v1/activities/meetings request/response against openapi.yaml schema

TestMeeting_Contract_ListMeetingLogs_MatchesOpenAPISpec
  Validates: GET /v1/activities/meetings response against openapi.yaml schema

TestMeeting_Contract_GetMeetingLog_MatchesOpenAPISpec
  Validates: GET /v1/activities/meetings/{meetingId} response against openapi.yaml schema

TestMeeting_Contract_UpdateMeetingLog_MatchesOpenAPISpec
  Validates: PATCH /v1/activities/meetings/{meetingId} request/response against openapi.yaml schema

TestMeeting_Contract_AttendanceSummary_MatchesOpenAPISpec
  Validates: GET /v1/activities/meetings/summary response against openapi.yaml schema

TestMeeting_Contract_SavedMeetings_MatchesOpenAPISpec
  Validates: all /v1/activities/meetings/saved endpoints against openapi.yaml schema

TestMeeting_Contract_ErrorResponses_FollowSiemensFormat
  Validates: all error responses include id, code, status, title, detail, correlationId
```

---

## 4. Mobile-Specific Tests

### 4.1 Android (Kotlin)

```
TestMeetingApiClient_CreateMeetingLog_SerializesCorrectly
  Validates Kotlin request/response types match OpenAPI schema

TestMeetingOfflineQueue_MeetingsSyncInChronologicalOrder
  Given: 3 meetings logged offline
  When: connectivity restored
  Then: meetings synced in timestamp order

TestMeetingScreen_QuickLogFromSavedMeeting_OneTouch
  Given: user has a saved meeting
  When: they tap the saved meeting
  Then: meeting logged with only timestamp confirmation needed
```

### 4.2 iOS (Swift)

```
TestMeetingApiClient_CreateMeetingLog_SerializesCorrectly
  Validates Swift request/response types match OpenAPI schema

TestMeetingOfflineQueue_MeetingsSyncInChronologicalOrder
  Given: 3 meetings logged offline
  When: connectivity restored
  Then: meetings synced in timestamp order

TestMeetingScreen_QuickLogFromSavedMeeting_OneTouch
  Given: user has a saved meeting
  When: they tap the saved meeting
  Then: meeting logged with only timestamp confirmation needed
```

---

## 5. Coverage Requirements

| Scope | Target |
|-------|--------|
| Domain logic (`internal/domain/meetings/`) | 90% line coverage |
| Handler (`internal/handler/meetings/`) | 75% line coverage |
| Repository (`internal/repository/meetings/`) | 80% line coverage |
| Timestamp immutability enforcement | 100% branch coverage |
| Permission checking for meetings | 100% branch coverage |
| Feature flag gating | 100% branch coverage |
