// internal/domain/prayer/session.go
package prayer

import (
	"fmt"
	"time"
)

const (
	maxNotesLength     = 1000
	maxBackdateDays    = 7
	notesEditWindowHrs = 24
	maxDurationMinutes = 1440
	ephemeralTTLDays   = 30
)

// ValidateCreateSession validates a CreatePrayerSessionRequest.
// Returns nil if valid, or the first validation error encountered.
func ValidateCreateSession(req *CreatePrayerSessionRequest, now time.Time) error {
	// PR-AC1.2: Prayer type enum validation.
	if !ValidPrayerTypes[req.PrayerType] {
		return ErrInvalidPrayerType
	}

	// PR-AC1.4: Notes character limit.
	if req.Notes != nil && len(*req.Notes) > maxNotesLength {
		return ErrNotesExceedLimit
	}

	// Duration range validation.
	if req.DurationMinutes != nil {
		if *req.DurationMinutes < 0 || *req.DurationMinutes > maxDurationMinutes {
			return ErrDurationOutOfRange
		}
	}

	// PR-AC1.7, PR-AC1.8: Mood range validation (1-5).
	if req.MoodBefore != nil {
		if *req.MoodBefore < 1 || *req.MoodBefore > 5 {
			return ErrMoodOutOfRange
		}
	}
	if req.MoodAfter != nil {
		if *req.MoodAfter < 1 || *req.MoodAfter > 5 {
			return ErrMoodOutOfRange
		}
	}

	// Reject future timestamps.
	if req.Timestamp.After(now) {
		return ErrFutureTimestamp
	}

	// PR-AC1.9: Backdating validation -- max 7 days.
	maxBackdate := now.AddDate(0, 0, -maxBackdateDays)
	if req.Timestamp.Before(maxBackdate) {
		return ErrBackdatingTooFar
	}

	return nil
}

// ValidateUpdateSession validates an UpdatePrayerSessionRequest against the existing session.
// Returns nil if valid, or the first validation error encountered.
func ValidateUpdateSession(req *UpdatePrayerSessionRequest, existing *PrayerSession, now time.Time) error {
	// PR-AC1.10: Timestamp immutability (FR2.7).
	if req.Timestamp != nil {
		return ErrTimestampImmutable
	}

	// PR-AC1.2: Prayer type enum validation (if updating).
	if req.PrayerType != nil && !ValidPrayerTypes[*req.PrayerType] {
		return ErrInvalidPrayerType
	}

	// PR-AC1.4: Notes character limit.
	if req.Notes != nil && len(*req.Notes) > maxNotesLength {
		return ErrNotesExceedLimit
	}

	// Duration range validation.
	if req.DurationMinutes != nil {
		if *req.DurationMinutes < 0 || *req.DurationMinutes > maxDurationMinutes {
			return ErrDurationOutOfRange
		}
	}

	// PR-AC1.7, PR-AC1.8: Mood range validation.
	if req.MoodBefore != nil {
		if *req.MoodBefore < 1 || *req.MoodBefore > 5 {
			return ErrMoodOutOfRange
		}
	}
	if req.MoodAfter != nil {
		if *req.MoodAfter < 1 || *req.MoodAfter > 5 {
			return ErrMoodOutOfRange
		}
	}

	// PR-AC1.13: Notes edit window -- 24 hours after creation.
	if req.Notes != nil && now.After(existing.NotesEditableUntil) {
		return ErrNotesReadOnly
	}

	return nil
}

// NewPrayerSession creates a new PrayerSession from a validated request.
// Assigns a new ID, sets immutable timestamps, and calculates the notes edit window.
func NewPrayerSession(id string, userID string, req *CreatePrayerSessionRequest, now time.Time) *PrayerSession {
	return &PrayerSession{
		PrayerID:           id,
		UserID:             userID,
		Timestamp:          req.Timestamp,
		PrayerType:         req.PrayerType,
		DurationMinutes:    req.DurationMinutes,
		Notes:              req.Notes,
		LinkedPrayerID:     req.LinkedPrayerID,
		MoodBefore:         req.MoodBefore,
		MoodAfter:          req.MoodAfter,
		IsEphemeral:        req.IsEphemeral,
		NotesEditableUntil: now.Add(notesEditWindowHrs * time.Hour),
		CreatedAt:          now,
		ModifiedAt:         now,
	}
}

// ApplyUpdate applies an UpdatePrayerSessionRequest to an existing PrayerSession.
// Only non-nil fields are updated. Returns the updated session.
func ApplyUpdate(session *PrayerSession, req *UpdatePrayerSessionRequest, now time.Time) *PrayerSession {
	if req.PrayerType != nil {
		session.PrayerType = *req.PrayerType
	}
	if req.DurationMinutes != nil {
		session.DurationMinutes = req.DurationMinutes
	}
	if req.Notes != nil {
		session.Notes = req.Notes
	}
	if req.LinkedPrayerID != nil {
		session.LinkedPrayerID = req.LinkedPrayerID
	}
	if req.MoodBefore != nil {
		session.MoodBefore = req.MoodBefore
	}
	if req.MoodAfter != nil {
		session.MoodAfter = req.MoodAfter
	}
	session.ModifiedAt = now
	return session
}

// EphemeralDeleteAt returns the TTL expiration time for ephemeral sessions.
func EphemeralDeleteAt(createdAt time.Time) time.Time {
	return createdAt.AddDate(0, 0, ephemeralTTLDays)
}

// DefaultQuickLogRequest creates a quick log request with default values (PR-AC1.11).
// Quick log defaults to prayerType=personal, timestamp=now, all other fields null.
func DefaultQuickLogRequest(now time.Time) *CreatePrayerSessionRequest {
	return &CreatePrayerSessionRequest{
		Timestamp:  now,
		PrayerType: PrayerTypePersonal,
	}
}

// SelfLink generates the self link for a prayer session.
func SelfLink(baseURL, prayerID string) string {
	return fmt.Sprintf("%s/v1/activities/prayer/%s", baseURL, prayerID)
}
