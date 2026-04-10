// internal/domain/threecircles/set.go
package threecircles

import (
	"strings"
	"time"
)

// NewCircleSet creates a new circle set with validation.
func NewCircleSet(userID, tenantID string, req CreateCircleSetRequest) (*CircleSet, error) {
	// Validate name.
	name := strings.TrimSpace(req.Name)
	if name == "" {
		return nil, ErrSetNameEmpty
	}
	if len(name) > 100 {
		return nil, ErrSetNameTooLong
	}

	// Validate recovery area.
	if !req.RecoveryArea.IsValid() {
		return nil, ErrInvalidRecoveryArea
	}

	// Validate framework preference if provided.
	if req.FrameworkPreference != nil && !req.FrameworkPreference.IsValid() {
		return nil, ErrInvalidFramework
	}

	now := time.Now().UTC()
	status := StatusDraft
	var committedAt *time.Time

	if req.CommitImmediately {
		status = StatusActive
		committedAt = &now
	}

	set := &CircleSet{
		UserID:              userID,
		TenantID:            tenantID,
		Name:                name,
		RecoveryArea:        req.RecoveryArea,
		FrameworkPreference: req.FrameworkPreference,
		Status:              status,
		InnerCircle:         []CircleItem{},
		MiddleCircle:        []CircleItem{},
		OuterCircle:         []CircleItem{},
		CurrentVersion:      1,
		CommittedAt:         committedAt,
		CreatedAt:           now,
		ModifiedAt:          now,
	}

	return set, nil
}

// UpdateSetName updates the name of a circle set.
func (cs *CircleSet) UpdateSetName(newName string) error {
	name := strings.TrimSpace(newName)
	if name == "" {
		return ErrSetNameEmpty
	}
	if len(name) > 100 {
		return ErrSetNameTooLong
	}

	cs.Name = name
	cs.ModifiedAt = time.Now().UTC()
	return nil
}

// UpdateFrameworkPreference updates the framework preference.
func (cs *CircleSet) UpdateFrameworkPreference(framework *FrameworkPreference) error {
	if framework != nil && !framework.IsValid() {
		return ErrInvalidFramework
	}

	cs.FrameworkPreference = framework
	cs.ModifiedAt = time.Now().UTC()
	return nil
}

// CanCommit checks if a circle set can be committed (transitioned to active status).
func (cs *CircleSet) CanCommit() error {
	if cs.Status == StatusActive {
		return ErrCannotCommitActive
	}
	if cs.Status == StatusArchived {
		return ErrCannotCommitArchived
	}
	if len(cs.InnerCircle) == 0 {
		return ErrInnerCircleEmpty
	}
	return nil
}

// Commit transitions a draft circle set to active status.
// Returns error if the set cannot be committed.
func (cs *CircleSet) Commit() error {
	if err := cs.CanCommit(); err != nil {
		return err
	}

	now := time.Now().UTC()
	cs.Status = StatusActive
	cs.CommittedAt = &now
	cs.ModifiedAt = now
	cs.CurrentVersion++

	return nil
}

// Archive soft-deletes a circle set by moving it to archived status.
func (cs *CircleSet) Archive() {
	cs.Status = StatusArchived
	cs.ModifiedAt = time.Now().UTC()
}

// GetCircle returns the items for a specific circle type.
func (cs *CircleSet) GetCircle(circleType CircleType) ([]CircleItem, error) {
	switch circleType {
	case CircleTypeInner:
		return cs.InnerCircle, nil
	case CircleTypeMiddle:
		return cs.MiddleCircle, nil
	case CircleTypeOuter:
		return cs.OuterCircle, nil
	default:
		return nil, ErrInvalidCircleType
	}
}

// SetCircle replaces the items for a specific circle type.
func (cs *CircleSet) SetCircle(circleType CircleType, items []CircleItem) error {
	// Validate capacity.
	switch circleType {
	case CircleTypeInner:
		if len(items) > 20 {
			return ErrInnerCircleFull
		}
		cs.InnerCircle = items
	case CircleTypeMiddle:
		if len(items) > 50 {
			return ErrMiddleCircleFull
		}
		cs.MiddleCircle = items
	case CircleTypeOuter:
		if len(items) > 50 {
			return ErrOuterCircleFull
		}
		cs.OuterCircle = items
	default:
		return ErrInvalidCircleType
	}

	cs.ModifiedAt = time.Now().UTC()
	return nil
}

// GetAllItems returns all items across all circles with their circle type.
func (cs *CircleSet) GetAllItems() map[string]CircleType {
	items := make(map[string]CircleType)

	for _, item := range cs.InnerCircle {
		items[item.ItemID] = CircleTypeInner
	}
	for _, item := range cs.MiddleCircle {
		items[item.ItemID] = CircleTypeMiddle
	}
	for _, item := range cs.OuterCircle {
		items[item.ItemID] = CircleTypeOuter
	}

	return items
}

// IncrementVersion increments the version number and updates modified timestamp.
func (cs *CircleSet) IncrementVersion() {
	cs.CurrentVersion++
	cs.ModifiedAt = time.Now().UTC()
}

// CountItems returns the total count of items across all circles.
func (cs *CircleSet) CountItems() (inner, middle, outer int) {
	return len(cs.InnerCircle), len(cs.MiddleCircle), len(cs.OuterCircle)
}
