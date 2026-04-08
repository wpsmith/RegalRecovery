// internal/domain/meetings/summary_test.go
package meetings

import (
	"testing"
	"time"
)

// TestAttendanceSummary_FR_MTG_3_5_WeeklyCount verifies that weekly summary
// returns correct total count and date range covering Monday-Sunday.
//
// Acceptance Criterion (FR-MTG-3.5): totalCount matches, date range covers the week.
func TestAttendanceSummary_FR_MTG_3_5_WeeklyCount(t *testing.T) {
	// Reference date: Wednesday, March 25, 2026
	refDate := time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange(PeriodWeek, refDate)

	// The week should be Mon Mar 23 - Sun Mar 29
	expectedStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)
	expectedEnd := time.Date(2026, 3, 29, 0, 0, 0, 0, time.UTC)

	if !start.Equal(expectedStart) {
		t.Errorf("expected week start %s, got %s", expectedStart.Format("2006-01-02"), start.Format("2006-01-02"))
	}
	if !end.Equal(expectedEnd) {
		t.Errorf("expected week end %s, got %s", expectedEnd.Format("2006-01-02"), end.Format("2006-01-02"))
	}

	// Create 3 meetings within the week.
	meetings := []*MeetingLog{
		{Timestamp: time.Date(2026, 3, 23, 19, 0, 0, 0, time.UTC), MeetingType: MeetingTypeSA, Status: MeetingStatusAttended},
		{Timestamp: time.Date(2026, 3, 25, 12, 0, 0, 0, time.UTC), MeetingType: MeetingTypeTherapy, Status: MeetingStatusAttended},
		{Timestamp: time.Date(2026, 3, 27, 18, 0, 0, 0, time.UTC), MeetingType: MeetingTypeCR, Status: MeetingStatusAttended},
	}

	summary := CalculateAttendanceSummary(meetings, PeriodWeek, start, end)

	if summary.TotalCount != 3 {
		t.Errorf("expected totalCount 3, got %d", summary.TotalCount)
	}
	if summary.Period != PeriodWeek {
		t.Errorf("expected period 'week', got '%s'", summary.Period)
	}
}

// TestAttendanceSummary_FR_MTG_3_5_MonthlyByType verifies that monthly summary
// returns correct breakdown by meeting type.
//
// Acceptance Criterion (FR-MTG-3.5): totalCount correct, byType shows breakdown.
func TestAttendanceSummary_FR_MTG_3_5_MonthlyByType(t *testing.T) {
	refDate := time.Date(2026, 3, 15, 0, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange(PeriodMonth, refDate)

	meetings := make([]*MeetingLog, 0, 12)
	// 8 SA meetings
	for i := 0; i < 8; i++ {
		meetings = append(meetings, &MeetingLog{
			Timestamp:   time.Date(2026, 3, i+1, 19, 0, 0, 0, time.UTC),
			MeetingType: MeetingTypeSA,
			Status:      MeetingStatusAttended,
		})
	}
	// 3 therapy meetings
	for i := 0; i < 3; i++ {
		meetings = append(meetings, &MeetingLog{
			Timestamp:   time.Date(2026, 3, i+10, 14, 0, 0, 0, time.UTC),
			MeetingType: MeetingTypeTherapy,
			Status:      MeetingStatusAttended,
		})
	}
	// 1 church meeting
	meetings = append(meetings, &MeetingLog{
		Timestamp:   time.Date(2026, 3, 15, 10, 0, 0, 0, time.UTC),
		MeetingType: MeetingTypeChurch,
		Status:      MeetingStatusAttended,
	})

	summary := CalculateAttendanceSummary(meetings, PeriodMonth, start, end)

	if summary.TotalCount != 12 {
		t.Errorf("expected totalCount 12, got %d", summary.TotalCount)
	}
	if summary.ByType["SA"] != 8 {
		t.Errorf("expected 8 SA meetings, got %d", summary.ByType["SA"])
	}
	if summary.ByType["therapy"] != 3 {
		t.Errorf("expected 3 therapy meetings, got %d", summary.ByType["therapy"])
	}
	if summary.ByType["church"] != 1 {
		t.Errorf("expected 1 church meeting, got %d", summary.ByType["church"])
	}
}

// TestAttendanceSummary_FR_MTG_3_5_ExcludesCanceled verifies that canceled meetings
// are counted separately and not included in totalCount.
//
// Acceptance Criterion (FR-MTG-3.5): canceledCount separate from totalCount.
func TestAttendanceSummary_FR_MTG_3_5_ExcludesCanceled(t *testing.T) {
	refDate := time.Date(2026, 3, 15, 0, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange(PeriodMonth, refDate)

	meetings := make([]*MeetingLog, 0, 12)
	// 10 attended
	for i := 0; i < 10; i++ {
		meetings = append(meetings, &MeetingLog{
			Timestamp:   time.Date(2026, 3, i+1, 19, 0, 0, 0, time.UTC),
			MeetingType: MeetingTypeSA,
			Status:      MeetingStatusAttended,
		})
	}
	// 2 canceled
	for i := 0; i < 2; i++ {
		meetings = append(meetings, &MeetingLog{
			Timestamp:   time.Date(2026, 3, i+15, 19, 0, 0, 0, time.UTC),
			MeetingType: MeetingTypeSA,
			Status:      MeetingStatusCanceled,
		})
	}

	summary := CalculateAttendanceSummary(meetings, PeriodMonth, start, end)

	if summary.TotalCount != 10 {
		t.Errorf("expected totalCount 10 (excluding canceled), got %d", summary.TotalCount)
	}
	if summary.CanceledCount != 2 {
		t.Errorf("expected canceledCount 2, got %d", summary.CanceledCount)
	}
}

// TestAttendanceSummary_FR_MTG_3_5_EmptyPeriod verifies that an empty period returns
// zero counts and an empty byType map.
func TestAttendanceSummary_FR_MTG_3_5_EmptyPeriod(t *testing.T) {
	refDate := time.Date(2026, 3, 15, 0, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange(PeriodMonth, refDate)

	summary := CalculateAttendanceSummary(nil, PeriodMonth, start, end)

	if summary.TotalCount != 0 {
		t.Errorf("expected totalCount 0, got %d", summary.TotalCount)
	}
	if summary.CanceledCount != 0 {
		t.Errorf("expected canceledCount 0, got %d", summary.CanceledCount)
	}
	if len(summary.ByType) != 0 {
		t.Errorf("expected empty byType map, got %v", summary.ByType)
	}
}

// TestPeriodDateRange_MonthRange verifies month period date range calculation.
func TestPeriodDateRange_MonthRange(t *testing.T) {
	refDate := time.Date(2026, 3, 15, 0, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange(PeriodMonth, refDate)

	expectedStart := time.Date(2026, 3, 1, 0, 0, 0, 0, time.UTC)
	expectedEnd := time.Date(2026, 3, 31, 0, 0, 0, 0, time.UTC)

	if !start.Equal(expectedStart) {
		t.Errorf("expected month start %s, got %s", expectedStart.Format("2006-01-02"), start.Format("2006-01-02"))
	}
	if !end.Equal(expectedEnd) {
		t.Errorf("expected month end %s, got %s", expectedEnd.Format("2006-01-02"), end.Format("2006-01-02"))
	}
}

// TestPeriodDateRange_QuarterRange verifies quarter period date range calculation.
func TestPeriodDateRange_QuarterRange(t *testing.T) {
	refDate := time.Date(2026, 5, 10, 0, 0, 0, 0, time.UTC) // Q2
	start, end := PeriodDateRange(PeriodQuarter, refDate)

	expectedStart := time.Date(2026, 4, 1, 0, 0, 0, 0, time.UTC)
	expectedEnd := time.Date(2026, 6, 30, 0, 0, 0, 0, time.UTC)

	if !start.Equal(expectedStart) {
		t.Errorf("expected quarter start %s, got %s", expectedStart.Format("2006-01-02"), start.Format("2006-01-02"))
	}
	if !end.Equal(expectedEnd) {
		t.Errorf("expected quarter end %s, got %s", expectedEnd.Format("2006-01-02"), end.Format("2006-01-02"))
	}
}

// TestPeriodDateRange_YearRange verifies year period date range calculation.
func TestPeriodDateRange_YearRange(t *testing.T) {
	refDate := time.Date(2026, 7, 1, 0, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange(PeriodYear, refDate)

	expectedStart := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	expectedEnd := time.Date(2026, 12, 31, 0, 0, 0, 0, time.UTC)

	if !start.Equal(expectedStart) {
		t.Errorf("expected year start %s, got %s", expectedStart.Format("2006-01-02"), start.Format("2006-01-02"))
	}
	if !end.Equal(expectedEnd) {
		t.Errorf("expected year end %s, got %s", expectedEnd.Format("2006-01-02"), end.Format("2006-01-02"))
	}
}

// TestPeriodDateRange_WeekWithSunday verifies week calculation when ref date is Sunday.
func TestPeriodDateRange_WeekWithSunday(t *testing.T) {
	// Sunday, March 29, 2026
	refDate := time.Date(2026, 3, 29, 12, 0, 0, 0, time.UTC)
	start, end := PeriodDateRange(PeriodWeek, refDate)

	expectedStart := time.Date(2026, 3, 23, 0, 0, 0, 0, time.UTC)
	expectedEnd := time.Date(2026, 3, 29, 0, 0, 0, 0, time.UTC)

	if !start.Equal(expectedStart) {
		t.Errorf("expected week start (Sunday ref) %s, got %s", expectedStart.Format("2006-01-02"), start.Format("2006-01-02"))
	}
	if !end.Equal(expectedEnd) {
		t.Errorf("expected week end (Sunday ref) %s, got %s", expectedEnd.Format("2006-01-02"), end.Format("2006-01-02"))
	}
}
