// internal/domain/mood/entry.go
package mood

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

// MoodEntry represents a single mood rating entry.
type MoodEntry struct {
	MoodID         string    `json:"moodId"`
	UserID         string    `json:"userId"`
	TenantID       string    `json:"tenantId"`
	Rating         int       `json:"rating"`
	RatingLabel    string    `json:"ratingLabel"`
	EmotionLabels  []string  `json:"emotionLabels"`
	ContextNote    string    `json:"contextNote,omitempty"`
	Source         string    `json:"source"`
	DatePartition  string    `json:"datePartition"`
	CrisisPrompted bool      `json:"crisisPrompted"`
	Timestamp      time.Time `json:"timestamp"`
	CreatedAt      time.Time `json:"createdAt"`
	ModifiedAt     time.Time `json:"modifiedAt"`
}

// CreateMoodEntryRequest holds input for creating a new mood entry.
type CreateMoodEntryRequest struct {
	Timestamp     time.Time `json:"timestamp"`
	Rating        int       `json:"rating"`
	EmotionLabels []string  `json:"emotionLabels,omitempty"`
	ContextNote   string    `json:"contextNote,omitempty"`
	Source        string    `json:"source,omitempty"`
}

// UpdateMoodEntryRequest holds input for updating an existing mood entry.
type UpdateMoodEntryRequest struct {
	Rating        *int     `json:"rating,omitempty"`
	EmotionLabels []string `json:"emotionLabels,omitempty"`
	ContextNote   *string  `json:"contextNote,omitempty"`
}

// NewMoodEntry creates a validated MoodEntry from a create request.
// Returns the entry with an auto-generated moodId, or a validation error.
func NewMoodEntry(userID, tenantID string, req CreateMoodEntryRequest) (*MoodEntry, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	if tenantID == "" {
		return nil, fmt.Errorf("tenant ID is required: %w", ErrInvalidInput)
	}

	if err := ValidateRating(req.Rating); err != nil {
		return nil, err
	}
	if err := ValidateEmotionLabels(req.EmotionLabels); err != nil {
		return nil, err
	}
	if err := ValidateContextNote(req.ContextNote); err != nil {
		return nil, err
	}

	source := req.Source
	if source == "" {
		source = "direct"
	}
	if err := ValidateSource(source); err != nil {
		return nil, err
	}

	timestamp := req.Timestamp
	if timestamp.IsZero() {
		timestamp = time.Now().UTC()
	}

	now := time.Now().UTC()
	moodID := "mood_" + uuid.New().String()[:8]

	entry := &MoodEntry{
		MoodID:         moodID,
		UserID:         userID,
		TenantID:       tenantID,
		Rating:         req.Rating,
		RatingLabel:    LabelForRating(req.Rating),
		EmotionLabels:  req.EmotionLabels,
		ContextNote:    req.ContextNote,
		Source:         source,
		DatePartition:  timestamp.Format("2006-01-02"),
		CrisisPrompted: req.Rating == 1,
		Timestamp:      timestamp,
		CreatedAt:      now,
		ModifiedAt:     now,
	}

	if entry.EmotionLabels == nil {
		entry.EmotionLabels = []string{}
	}

	return entry, nil
}

// ApplyUpdate applies a partial update to the mood entry.
// Only fields present in the request are updated. Timestamp and createdAt are immutable.
// Returns ErrEntryLocked if the entry is older than 24 hours.
func (e *MoodEntry) ApplyUpdate(req UpdateMoodEntryRequest, now time.Time) error {
	if err := CheckEditWindow(e.CreatedAt, now); err != nil {
		return err
	}

	if req.Rating != nil {
		if err := ValidateRating(*req.Rating); err != nil {
			return err
		}
		e.Rating = *req.Rating
		e.RatingLabel = LabelForRating(*req.Rating)
		e.CrisisPrompted = *req.Rating == 1
	}

	if req.EmotionLabels != nil {
		if err := ValidateEmotionLabels(req.EmotionLabels); err != nil {
			return err
		}
		e.EmotionLabels = req.EmotionLabels
	}

	if req.ContextNote != nil {
		if err := ValidateContextNote(*req.ContextNote); err != nil {
			return err
		}
		e.ContextNote = *req.ContextNote
	}

	e.ModifiedAt = now
	return nil
}

// CanDelete checks if the entry can be deleted (within 24-hour window).
func (e *MoodEntry) CanDelete(now time.Time) error {
	return CheckDeleteWindow(e.CreatedAt, now)
}
