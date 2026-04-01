// internal/repository/helpers.go
package repository

import (
	"fmt"
	"time"
)

// FormatPK constructs a partition key with the given entity type and ID.
func FormatPK(entityType, id string) string {
	return fmt.Sprintf("%s#%s", entityType, id)
}

// FormatSK constructs a sort key with the given entity type and identifier.
func FormatSK(entityType, identifier string) string {
	if identifier == "" {
		return entityType
	}
	return fmt.Sprintf("%s#%s", entityType, identifier)
}

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

// BuildActivitySK constructs a composite sort key for calendar activities.
// Format: ACTIVITY#{date}#{activityType}#{timestamp}
func BuildActivitySK(date, activityType, timestamp string) string {
	return fmt.Sprintf("ACTIVITY#%s#%s#%s", date, activityType, timestamp)
}

// ExtractDateFromActivitySK extracts the date from a calendar activity SK.
// Input: ACTIVITY#2026-03-28#CHECKIN#2026-03-28T21:00:00Z
// Output: 2026-03-28
func ExtractDateFromActivitySK(sk string) (string, error) {
	// Parse: ACTIVITY#YYYY-MM-DD#TYPE#TIMESTAMP
	var date string
	_, err := fmt.Sscanf(sk, "ACTIVITY#%10s#", &date)
	if err != nil {
		return "", fmt.Errorf("failed to extract date from SK %s: %w", sk, err)
	}
	return date, nil
}

// SetBaseItemDefaults sets default values for BaseItem fields on creation.
func SetBaseItemDefaults(item *BaseItem, entityType string) {
	now := NowISO8601()
	if item.CreatedAt == "" {
		item.CreatedAt = now
	}
	item.ModifiedAt = now
	if item.EntityType == "" {
		item.EntityType = entityType
	}
	if item.TenantID == "" {
		item.TenantID = "DEFAULT"
	}
}

// UpdateModifiedAt updates the ModifiedAt timestamp to now.
func UpdateModifiedAt(item *BaseItem) {
	item.ModifiedAt = NowISO8601()
}
