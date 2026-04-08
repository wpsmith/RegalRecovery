// internal/domain/meetings/summary.go
package meetings

import (
	"context"
	"fmt"
	"time"
)

// SummaryService handles attendance summary business logic.
type SummaryService struct {
	repo MeetingRepository
}

// NewSummaryService creates a new SummaryService.
func NewSummaryService(repo MeetingRepository) *SummaryService {
	return &SummaryService{repo: repo}
}

// CalculateSummary computes attendance statistics for a given period.
func (s *SummaryService) CalculateSummary(ctx context.Context, userID string, period SummaryPeriod, refDate time.Time) (*AttendanceSummary, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	if !IsValidSummaryPeriod(period) {
		return nil, fmt.Errorf("invalid period '%s': %w", period, ErrInvalidInput)
	}

	start, end := PeriodDateRange(period, refDate)

	meetings, err := s.repo.GetMeetingsInRange(ctx, userID, start, end)
	if err != nil {
		return nil, fmt.Errorf("retrieving meetings for summary: %w", err)
	}

	return CalculateAttendanceSummary(meetings, period, start, end), nil
}

// CalculateAttendanceSummary computes an AttendanceSummary from a slice of meeting logs.
// This is a pure function suitable for unit testing.
func CalculateAttendanceSummary(meetings []*MeetingLog, period SummaryPeriod, start, end time.Time) *AttendanceSummary {
	summary := &AttendanceSummary{
		Period:    period,
		StartDate: start.Format("2006-01-02"),
		EndDate:   end.Format("2006-01-02"),
		ByType:    make(map[string]int),
	}

	for _, m := range meetings {
		if m.Status == MeetingStatusCanceled {
			summary.CanceledCount++
			continue
		}
		summary.TotalCount++
		summary.ByType[string(m.MeetingType)]++
	}

	return summary
}

// PeriodDateRange returns the start and end dates for a summary period
// relative to a reference date.
func PeriodDateRange(period SummaryPeriod, refDate time.Time) (start, end time.Time) {
	refDate = refDate.UTC()
	y, m, d := refDate.Date()

	switch period {
	case PeriodWeek:
		// ISO week: Monday through Sunday containing refDate.
		weekday := refDate.Weekday()
		if weekday == time.Sunday {
			weekday = 7
		}
		daysFromMonday := int(weekday) - 1
		start = time.Date(y, m, d-daysFromMonday, 0, 0, 0, 0, time.UTC)
		end = start.AddDate(0, 0, 6)

	case PeriodMonth:
		start = time.Date(y, m, 1, 0, 0, 0, 0, time.UTC)
		end = start.AddDate(0, 1, -1)

	case PeriodQuarter:
		quarterStart := ((int(m) - 1) / 3) * 3
		start = time.Date(y, time.Month(quarterStart+1), 1, 0, 0, 0, 0, time.UTC)
		end = start.AddDate(0, 3, -1)

	case PeriodYear:
		start = time.Date(y, 1, 1, 0, 0, 0, 0, time.UTC)
		end = time.Date(y, 12, 31, 0, 0, 0, 0, time.UTC)
	}

	return start, end
}
