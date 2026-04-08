// internal/domain/nutrition/hydration_date.go
package nutrition

import "time"

// DateForTimezone returns the YYYY-MM-DD date string for the given time in the user's timezone.
// FR-NUT-3.8: Hydration date boundary is determined by user timezone.
func DateForTimezone(t time.Time, loc *time.Location) string {
	if loc == nil {
		loc = time.UTC
	}
	return t.In(loc).Format("2006-01-02")
}

// ParseDate parses a YYYY-MM-DD date string into a time.Time at midnight UTC.
func ParseDate(date string) (time.Time, error) {
	return time.Parse("2006-01-02", date)
}

// StartOfDay returns midnight in the given timezone for the given time.
func StartOfDay(t time.Time, loc *time.Location) time.Time {
	if loc == nil {
		loc = time.UTC
	}
	local := t.In(loc)
	return time.Date(local.Year(), local.Month(), local.Day(), 0, 0, 0, 0, loc)
}

// EndOfDay returns 23:59:59.999999999 in the given timezone for the given time.
func EndOfDay(t time.Time, loc *time.Location) time.Time {
	if loc == nil {
		loc = time.UTC
	}
	local := t.In(loc)
	return time.Date(local.Year(), local.Month(), local.Day(), 23, 59, 59, 999999999, loc)
}
