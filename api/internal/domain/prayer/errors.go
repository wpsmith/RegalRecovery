// internal/domain/prayer/errors.go
package prayer

import "errors"

// Domain errors for the prayer activity.
var (
	// ErrInvalidPrayerType indicates prayerType is not in the allowed enum.
	// Maps to error code rr:0x00500001, HTTP 422.
	ErrInvalidPrayerType = errors.New("prayerType must be one of: personal, guided, group, scriptureBased, intercessory, listening")

	// ErrLinkedPrayerLocked indicates the linked prayer belongs to a premium pack the user has not purchased.
	// Maps to error code rr:0x00500002, HTTP 422.
	ErrLinkedPrayerLocked = errors.New("linked prayer belongs to a premium pack not owned by user")

	// ErrNotesExceedLimit indicates notes exceed the 1000-character limit.
	// HTTP 422, source pointer /data/notes.
	ErrNotesExceedLimit = errors.New("notes must not exceed 1000 characters")

	// ErrMoodOutOfRange indicates moodBefore or moodAfter is outside 1-5.
	// HTTP 422.
	ErrMoodOutOfRange = errors.New("mood must be between 1 and 5")

	// ErrBackdatingTooFar indicates the timestamp is more than 7 days in the past.
	// HTTP 422.
	ErrBackdatingTooFar = errors.New("timestamp cannot be more than 7 days in the past")

	// ErrTimestampImmutable indicates an attempt to modify the immutable timestamp field (FR2.7).
	// HTTP 422.
	ErrTimestampImmutable = errors.New("timestamp is immutable")

	// ErrNotesReadOnly indicates notes cannot be edited after the 24-hour window.
	// HTTP 422.
	ErrNotesReadOnly = errors.New("notes are read-only after 24 hours")

	// ErrTitleRequired indicates the personal prayer title is missing.
	// HTTP 422.
	ErrTitleRequired = errors.New("title is required")

	// ErrBodyRequired indicates the personal prayer body is missing.
	// HTTP 422.
	ErrBodyRequired = errors.New("body is required")

	// ErrTitleExceedsLimit indicates the title exceeds 100 characters.
	// HTTP 422.
	ErrTitleExceedsLimit = errors.New("title must not exceed 100 characters")

	// ErrPrayerNotFound indicates the prayer session or prayer was not found.
	// HTTP 404.
	ErrPrayerNotFound = errors.New("prayer not found")

	// ErrFavoriteAlreadyExists indicates the prayer is already favorited.
	// HTTP 409.
	ErrFavoriteAlreadyExists = errors.New("prayer already favorited")

	// ErrFavoriteNotFound indicates the favorite does not exist.
	// HTTP 404.
	ErrFavoriteNotFound = errors.New("favorite not found")

	// ErrFeatureDisabled indicates the activity.prayer feature flag is disabled or unavailable.
	// HTTP 404 (fail closed, hide existence).
	ErrFeatureDisabled = errors.New("feature not found")

	// ErrFutureTimestamp indicates the timestamp is in the future.
	// HTTP 422.
	ErrFutureTimestamp = errors.New("timestamp cannot be in the future")

	// ErrDurationOutOfRange indicates duration is outside 0-1440.
	// HTTP 422.
	ErrDurationOutOfRange = errors.New("durationMinutes must be between 0 and 1440")

	// ErrInvalidReorderIDs indicates the reorder list contains invalid IDs.
	// HTTP 422.
	ErrInvalidReorderIDs = errors.New("prayerIds list is invalid or contains unknown IDs")
)

// ErrorCode maps domain errors to application error codes in rr:0x format.
var ErrorCode = map[error]string{
	ErrInvalidPrayerType:  "rr:0x00500001",
	ErrLinkedPrayerLocked: "rr:0x00500002",
	ErrNotesExceedLimit:   "rr:0x00500003",
	ErrMoodOutOfRange:     "rr:0x00500004",
	ErrBackdatingTooFar:   "rr:0x00500005",
	ErrTimestampImmutable: "rr:0x00500006",
	ErrNotesReadOnly:      "rr:0x00500007",
	ErrTitleRequired:      "rr:0x00500008",
	ErrBodyRequired:       "rr:0x00500009",
	ErrTitleExceedsLimit:  "rr:0x0050000A",
	ErrDurationOutOfRange: "rr:0x0050000B",
	ErrFutureTimestamp:    "rr:0x0050000C",
	ErrInvalidReorderIDs:  "rr:0x0050000D",
}
