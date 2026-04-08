// internal/domain/mood/validation.go
package mood

import (
	"errors"
	"fmt"
	"time"
)

var (
	// ErrInvalidInput indicates general invalid input.
	ErrInvalidInput = errors.New("invalid input")

	// ErrInvalidRating indicates the rating is outside the valid range.
	ErrInvalidRating = errors.New("rating must be between 1 and 5")

	// ErrInvalidEmotionLabel indicates an emotion label is not in the predefined list.
	ErrInvalidEmotionLabel = errors.New("invalid emotion label")

	// ErrContextNoteTooLong indicates the context note exceeds the max length.
	ErrContextNoteTooLong = errors.New("contextNote must be 200 characters or fewer")

	// ErrInvalidSource indicates the source is not valid.
	ErrInvalidSource = errors.New("invalid source")

	// ErrEntryLocked indicates the entry is older than 24 hours and cannot be edited.
	ErrEntryLocked = errors.New("this mood entry is older than 24 hours and can no longer be edited")

	// ErrEntryPermanent indicates the entry is older than 24 hours and cannot be deleted.
	ErrEntryPermanent = errors.New("this mood entry is older than 24 hours and cannot be deleted")

	// ErrEntryNotFound indicates the mood entry was not found.
	ErrEntryNotFound = errors.New("mood entry not found")
)

const (
	// MinRating is the minimum mood rating value.
	MinRating = 1

	// MaxRating is the maximum mood rating value.
	MaxRating = 5

	// MaxContextNoteLength is the maximum number of characters for a context note.
	MaxContextNoteLength = 200

	// EditDeleteWindowHours is the number of hours within which an entry can be edited or deleted.
	EditDeleteWindowHours = 24
)

// ValidateRating checks that a rating is in the valid range [1, 5].
func ValidateRating(rating int) error {
	if rating < MinRating || rating > MaxRating {
		return fmt.Errorf("%w", ErrInvalidRating)
	}
	return nil
}

// ValidateEmotionLabels checks that all emotion labels are in the predefined list.
func ValidateEmotionLabels(labels []string) error {
	for _, label := range labels {
		if !ValidEmotionLabels[label] {
			return fmt.Errorf("invalid emotion label: %s: %w", label, ErrInvalidEmotionLabel)
		}
	}
	return nil
}

// ValidateContextNote checks that a context note does not exceed the max length.
func ValidateContextNote(note string) error {
	if len([]rune(note)) > MaxContextNoteLength {
		return fmt.Errorf("%w", ErrContextNoteTooLong)
	}
	return nil
}

// ValidateSource checks that a source is in the valid set.
func ValidateSource(source string) error {
	if !ValidSources[source] {
		return fmt.Errorf("invalid source: %s: %w", source, ErrInvalidSource)
	}
	return nil
}

// CheckEditWindow returns ErrEntryLocked if the entry is older than 24 hours.
func CheckEditWindow(createdAt, now time.Time) error {
	cutoff := createdAt.Add(EditDeleteWindowHours * time.Hour)
	if now.After(cutoff) {
		return ErrEntryLocked
	}
	return nil
}

// CheckDeleteWindow returns ErrEntryPermanent if the entry is older than 24 hours.
func CheckDeleteWindow(createdAt, now time.Time) error {
	cutoff := createdAt.Add(EditDeleteWindowHours * time.Hour)
	if now.After(cutoff) {
		return ErrEntryPermanent
	}
	return nil
}
