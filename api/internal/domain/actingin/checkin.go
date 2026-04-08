// internal/domain/actingin/checkin.go
package actingin

import (
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
)

var (
	// ErrInvalidBehaviorID indicates the behavior ID is not in the user's enabled list.
	ErrInvalidBehaviorID = errors.New("behavior ID is not in the enabled list")

	// ErrDisabledBehaviorID indicates the behavior ID is disabled.
	ErrDisabledBehaviorID = errors.New("behavior ID is disabled")

	// ErrInvalidTrigger indicates the trigger value is not in the valid enum.
	ErrInvalidTrigger = errors.New("invalid trigger value")

	// ErrInvalidRelationshipTag indicates the relationship tag is not in the valid enum.
	ErrInvalidRelationshipTag = errors.New("invalid relationship tag value")

	// ErrContextNoteTooLong indicates the context note exceeds the maximum length.
	ErrContextNoteTooLong = errors.New("context note must be 500 characters or fewer")

	// ErrTimestampImmutable indicates an attempt to modify an immutable timestamp.
	ErrTimestampImmutable = errors.New("check-in timestamp is immutable once set (FR2.7)")
)

const (
	// MaxContextNoteLength is the maximum length for a context note.
	MaxContextNoteLength = 500
)

// ValidateCheckInRequest validates a check-in request against the user's behavior config.
func ValidateCheckInRequest(req *CreateCheckInRequest, config *BehaviorConfig) error {
	enabledIDs := config.GetEnabledBehaviorIDs()

	for _, b := range req.Behaviors {
		// Verify behavior is in the user's enabled list.
		if !enabledIDs[b.BehaviorID] {
			// Check if it exists but is disabled.
			allBehaviors := config.GetAllBehaviors()
			found := false
			for _, ab := range allBehaviors {
				if ab.BehaviorID == b.BehaviorID {
					found = true
					break
				}
			}
			if found {
				return fmt.Errorf("%w: %s", ErrDisabledBehaviorID, b.BehaviorID)
			}
			return fmt.Errorf("%w: %s", ErrInvalidBehaviorID, b.BehaviorID)
		}

		// Validate context note length.
		if len(b.ContextNote) > MaxContextNoteLength {
			return fmt.Errorf("%w for behavior %s", ErrContextNoteTooLong, b.BehaviorID)
		}

		// Validate trigger if provided.
		if b.Trigger != "" && !ValidTriggers[b.Trigger] {
			return fmt.Errorf("%w: %s", ErrInvalidTrigger, b.Trigger)
		}

		// Validate relationship tag if provided.
		if b.RelationshipTag != "" && !ValidRelationshipTags[b.RelationshipTag] {
			return fmt.Errorf("%w: %s", ErrInvalidRelationshipTag, b.RelationshipTag)
		}
	}

	return nil
}

// CreateCheckIn builds a new CheckIn from a validated request.
// The config is used to resolve behavior names.
// streakCount is the current consecutive check-in count.
func CreateCheckIn(req *CreateCheckInRequest, config *BehaviorConfig, streakCount int) *CheckIn {
	now := time.Now().UTC()
	checkInID := fmt.Sprintf("aic_%s", uuid.New().String()[:8])

	behaviors := make([]CheckedBehavior, 0, len(req.Behaviors))
	triggerSet := make(map[Trigger]bool)
	relationshipSet := make(map[RelationshipTag]bool)

	for _, b := range req.Behaviors {
		name := config.BehaviorName(b.BehaviorID)
		behaviors = append(behaviors, CheckedBehavior{
			BehaviorID:      b.BehaviorID,
			BehaviorName:    name,
			ContextNote:     b.ContextNote,
			Trigger:         b.Trigger,
			RelationshipTag: b.RelationshipTag,
		})
		if b.Trigger != "" {
			triggerSet[b.Trigger] = true
		}
		if b.RelationshipTag != "" {
			relationshipSet[b.RelationshipTag] = true
		}
	}

	triggers := make([]Trigger, 0, len(triggerSet))
	for t := range triggerSet {
		triggers = append(triggers, t)
	}
	relationships := make([]RelationshipTag, 0, len(relationshipSet))
	for r := range relationshipSet {
		relationships = append(relationships, r)
	}

	message := SelectMessage(len(behaviors), streakCount)

	return &CheckIn{
		CheckInID:           checkInID,
		UserID:              config.UserID,
		Timestamp:           req.Timestamp,
		BehaviorCount:       len(behaviors),
		Behaviors:           behaviors,
		Triggers:            triggers,
		RelationshipTags:    relationships,
		ConsecutiveCheckIns: streakCount + 1,
		Message:             message,
		CreatedAt:           now,
		ModifiedAt:          now,
	}
}

// SelectMessage returns the appropriate compassionate message for the check-in.
// Zero behaviors get a celebration message. One or more behaviors get a rotating
// message based on the streak count for variety.
func SelectMessage(behaviorCount, streakCount int) string {
	if behaviorCount == 0 {
		return MessageZeroBehaviors
	}
	// Rotate through messages based on streak count.
	idx := streakCount % len(RotatingMessages)
	return RotatingMessages[idx]
}
