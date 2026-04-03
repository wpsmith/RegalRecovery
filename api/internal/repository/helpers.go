// internal/repository/helpers.go
package repository

import (
	"time"
)

// FormatTimestamp formats a time.Time as an ISO 8601 string (RFC3339).
func FormatTimestamp(t time.Time) string {
	return t.UTC().Format(time.RFC3339)
}

// NowISO8601 returns the current time as an ISO 8601 string (RFC3339).
func NowISO8601() string {
	return time.Now().UTC().Format(time.RFC3339)
}

// ParseISO8601 parses an ISO 8601 timestamp string.
func ParseISO8601(s string) (time.Time, error) {
	return time.Parse(time.RFC3339, s)
}

// NowUTC returns the current time in UTC.
func NowUTC() time.Time {
	return time.Now().UTC()
}

// SetBaseDocumentDefaults sets default values for BaseDocument fields on creation.
func SetBaseDocumentDefaults(doc *BaseDocument) {
	now := NowUTC()
	if doc.CreatedAt.IsZero() {
		doc.CreatedAt = now
	}
	doc.ModifiedAt = now
	if doc.TenantID == "" {
		doc.TenantID = "DEFAULT"
	}
}

// UpdateModified updates the ModifiedAt timestamp to now.
func UpdateModified(doc *BaseDocument) {
	doc.ModifiedAt = NowUTC()
}
