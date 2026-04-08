// internal/domain/prayer/personal.go
package prayer

import "time"

const maxTitleLength = 100

// ValidateCreatePersonalPrayer validates a CreatePersonalPrayerRequest.
func ValidateCreatePersonalPrayer(req *CreatePersonalPrayerRequest) error {
	// PR-AC3.1: Title is required.
	if req.Title == "" {
		return ErrTitleRequired
	}

	// PR-AC3.1: Body is required.
	if req.Body == "" {
		return ErrBodyRequired
	}

	// PR-AC3.2: Title length validation (max 100 chars).
	if len(req.Title) > maxTitleLength {
		return ErrTitleExceedsLimit
	}

	return nil
}

// ValidateUpdatePersonalPrayer validates an UpdatePersonalPrayerRequest.
func ValidateUpdatePersonalPrayer(req *UpdatePersonalPrayerRequest) error {
	// PR-AC3.2: Title length validation (if updating).
	if req.Title != nil && len(*req.Title) > maxTitleLength {
		return ErrTitleExceedsLimit
	}

	// Title cannot be set to empty string.
	if req.Title != nil && *req.Title == "" {
		return ErrTitleRequired
	}

	// Body cannot be set to empty string.
	if req.Body != nil && *req.Body == "" {
		return ErrBodyRequired
	}

	return nil
}

// NewPersonalPrayer creates a new PersonalPrayer from a validated request.
func NewPersonalPrayer(id string, userID string, req *CreatePersonalPrayerRequest, sortOrder int, now time.Time) *PersonalPrayer {
	return &PersonalPrayer{
		ID:                 id,
		UserID:             userID,
		Title:              req.Title,
		Body:               req.Body,
		TopicTags:          req.TopicTags,
		ScriptureReference: req.ScriptureReference,
		IsFavorite:         false,
		SortOrder:          sortOrder,
		CreatedAt:          now,
		ModifiedAt:         now,
	}
}

// ApplyPersonalPrayerUpdate applies an UpdatePersonalPrayerRequest to an existing PersonalPrayer.
func ApplyPersonalPrayerUpdate(prayer *PersonalPrayer, req *UpdatePersonalPrayerRequest, now time.Time) *PersonalPrayer {
	if req.Title != nil {
		prayer.Title = *req.Title
	}
	if req.Body != nil {
		prayer.Body = *req.Body
	}
	if req.TopicTags != nil {
		prayer.TopicTags = req.TopicTags
	}
	if req.ScriptureReference != nil {
		prayer.ScriptureReference = req.ScriptureReference
	}
	prayer.ModifiedAt = now
	return prayer
}

// DeletedPrayerTitle is the sentinel title shown when a linked personal prayer has been deleted (PR-AC3.5).
const DeletedPrayerTitle = "[Deleted Prayer]"
