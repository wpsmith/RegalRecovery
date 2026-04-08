// internal/domain/actingin/behavior_config.go
package actingin

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

var (
	// ErrBehaviorNotFound indicates the behavior does not exist.
	ErrBehaviorNotFound = errors.New("behavior not found")

	// ErrCannotEditDefault indicates a default behavior cannot be edited.
	ErrCannotEditDefault = errors.New("cannot edit a default behavior")

	// ErrCannotDeleteDefault indicates a default behavior cannot be deleted.
	ErrCannotDeleteDefault = errors.New("cannot delete a default behavior")

	// ErrNameTooLong indicates the behavior name exceeds the maximum length.
	ErrNameTooLong = errors.New("behavior name must be 100 characters or fewer")

	// ErrNameEmpty indicates the behavior name is empty.
	ErrNameEmpty = errors.New("behavior name is required")

	// ErrDescriptionTooLong indicates the description exceeds the maximum length.
	ErrDescriptionTooLong = errors.New("behavior description must be 500 characters or fewer")
)

const (
	// MaxBehaviorNameLength is the maximum length for a behavior name.
	MaxBehaviorNameLength = 100

	// MaxBehaviorDescriptionLength is the maximum length for a behavior description.
	MaxBehaviorDescriptionLength = 500
)

// NewBehaviorConfig creates a new BehaviorConfig with all 15 defaults enabled.
func NewBehaviorConfig(userID string) *BehaviorConfig {
	now := time.Now().UTC()
	defaults := make(map[string]DefaultState, len(DefaultBehaviors))
	for _, b := range DefaultBehaviors {
		defaults[b.BehaviorID] = DefaultState{
			Enabled:   true,
			SortOrder: b.SortOrder,
		}
	}
	return &BehaviorConfig{
		UserID:          userID,
		Defaults:        defaults,
		CustomBehaviors: []CustomBehavior{},
		CreatedAt:       now,
		ModifiedAt:      now,
	}
}

// GetAllBehaviors returns a combined list of default and custom behaviors,
// sorted by sortOrder.
func (bc *BehaviorConfig) GetAllBehaviors() []Behavior {
	behaviors := make([]Behavior, 0, len(bc.Defaults)+len(bc.CustomBehaviors))

	for _, def := range DefaultBehaviors {
		state, ok := bc.Defaults[def.BehaviorID]
		if !ok {
			state = DefaultState{Enabled: true, SortOrder: def.SortOrder}
		}
		behaviors = append(behaviors, Behavior{
			BehaviorID:  def.BehaviorID,
			Name:        def.Name,
			Description: def.Description,
			IsDefault:   true,
			Enabled:     state.Enabled,
			SortOrder:   state.SortOrder,
		})
	}

	for _, cb := range bc.CustomBehaviors {
		behaviors = append(behaviors, Behavior{
			BehaviorID:  cb.BehaviorID,
			Name:        cb.Name,
			Description: cb.Description,
			IsDefault:   false,
			Enabled:     cb.Enabled,
			SortOrder:   cb.SortOrder,
		})
	}

	return behaviors
}

// GetEnabledBehaviors returns only enabled behaviors (defaults + custom), sorted by sortOrder.
func (bc *BehaviorConfig) GetEnabledBehaviors() []Behavior {
	all := bc.GetAllBehaviors()
	enabled := make([]Behavior, 0, len(all))
	for _, b := range all {
		if b.Enabled {
			enabled = append(enabled, b)
		}
	}
	return enabled
}

// GetEnabledBehaviorIDs returns a set of enabled behavior IDs for O(1) lookup.
func (bc *BehaviorConfig) GetEnabledBehaviorIDs() map[string]bool {
	enabled := bc.GetEnabledBehaviors()
	ids := make(map[string]bool, len(enabled))
	for _, b := range enabled {
		ids[b.BehaviorID] = true
	}
	return ids
}

// ToggleBehavior enables or disables a behavior by ID. Works for both default and custom.
func (bc *BehaviorConfig) ToggleBehavior(behaviorID string, enabled bool) (*Behavior, error) {
	// Check defaults first.
	if state, ok := bc.Defaults[behaviorID]; ok {
		state.Enabled = enabled
		bc.Defaults[behaviorID] = state
		bc.ModifiedAt = time.Now().UTC()

		def := DefaultBehaviorMap[behaviorID]
		return &Behavior{
			BehaviorID:  def.BehaviorID,
			Name:        def.Name,
			Description: def.Description,
			IsDefault:   true,
			Enabled:     enabled,
			SortOrder:   state.SortOrder,
		}, nil
	}

	// Check custom behaviors.
	for i, cb := range bc.CustomBehaviors {
		if cb.BehaviorID == behaviorID {
			bc.CustomBehaviors[i].Enabled = enabled
			bc.ModifiedAt = time.Now().UTC()
			return &Behavior{
				BehaviorID:  cb.BehaviorID,
				Name:        cb.Name,
				Description: cb.Description,
				IsDefault:   false,
				Enabled:     enabled,
				SortOrder:   cb.SortOrder,
			}, nil
		}
	}

	return nil, ErrBehaviorNotFound
}

// CreateCustomBehavior adds a new custom behavior to the configuration.
func (bc *BehaviorConfig) CreateCustomBehavior(name, description string) (*Behavior, error) {
	if err := validateBehaviorName(name); err != nil {
		return nil, err
	}
	if err := validateBehaviorDescription(description); err != nil {
		return nil, err
	}

	nextSortOrder := len(DefaultBehaviors) + len(bc.CustomBehaviors) + 1
	behaviorID := fmt.Sprintf("beh_custom_%s", strings.ReplaceAll(uuid.New().String(), "-", "")[:12])
	now := time.Now().UTC()

	cb := CustomBehavior{
		BehaviorID:  behaviorID,
		Name:        name,
		Description: description,
		Enabled:     true,
		SortOrder:   nextSortOrder,
		CreatedAt:   now,
	}

	bc.CustomBehaviors = append(bc.CustomBehaviors, cb)
	bc.ModifiedAt = now

	return &Behavior{
		BehaviorID:  cb.BehaviorID,
		Name:        cb.Name,
		Description: cb.Description,
		IsDefault:   false,
		Enabled:     cb.Enabled,
		SortOrder:   cb.SortOrder,
	}, nil
}

// UpdateCustomBehavior updates the name and/or description of a custom behavior.
func (bc *BehaviorConfig) UpdateCustomBehavior(behaviorID string, name *string, description *string) (*Behavior, error) {
	// Reject attempts to edit default behaviors.
	if _, ok := DefaultBehaviorMap[behaviorID]; ok {
		return nil, ErrCannotEditDefault
	}

	for i, cb := range bc.CustomBehaviors {
		if cb.BehaviorID == behaviorID {
			if name != nil {
				if err := validateBehaviorName(*name); err != nil {
					return nil, err
				}
				bc.CustomBehaviors[i].Name = *name
			}
			if description != nil {
				if err := validateBehaviorDescription(*description); err != nil {
					return nil, err
				}
				bc.CustomBehaviors[i].Description = *description
			}
			bc.ModifiedAt = time.Now().UTC()

			updated := bc.CustomBehaviors[i]
			return &Behavior{
				BehaviorID:  updated.BehaviorID,
				Name:        updated.Name,
				Description: updated.Description,
				IsDefault:   false,
				Enabled:     updated.Enabled,
				SortOrder:   updated.SortOrder,
			}, nil
		}
	}

	return nil, ErrBehaviorNotFound
}

// DeleteCustomBehavior removes a custom behavior from the configuration.
// Historical check-in data referencing this behavior is preserved.
func (bc *BehaviorConfig) DeleteCustomBehavior(behaviorID string) error {
	// Reject attempts to delete default behaviors.
	if _, ok := DefaultBehaviorMap[behaviorID]; ok {
		return ErrCannotDeleteDefault
	}

	for i, cb := range bc.CustomBehaviors {
		if cb.BehaviorID == behaviorID {
			bc.CustomBehaviors = append(bc.CustomBehaviors[:i], bc.CustomBehaviors[i+1:]...)
			bc.ModifiedAt = time.Now().UTC()
			return nil
		}
	}

	return ErrBehaviorNotFound
}

// BehaviorName returns the display name for a behavior ID.
// Looks up defaults first, then custom behaviors.
func (bc *BehaviorConfig) BehaviorName(behaviorID string) string {
	if def, ok := DefaultBehaviorMap[behaviorID]; ok {
		return def.Name
	}
	for _, cb := range bc.CustomBehaviors {
		if cb.BehaviorID == behaviorID {
			return cb.Name
		}
	}
	return ""
}

func validateBehaviorName(name string) error {
	trimmed := strings.TrimSpace(name)
	if trimmed == "" {
		return ErrNameEmpty
	}
	if len(trimmed) > MaxBehaviorNameLength {
		return ErrNameTooLong
	}
	return nil
}

func validateBehaviorDescription(description string) error {
	if len(description) > MaxBehaviorDescriptionLength {
		return ErrDescriptionTooLong
	}
	return nil
}
