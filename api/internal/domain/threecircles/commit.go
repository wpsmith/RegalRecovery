// internal/domain/threecircles/commit.go
package threecircles

import (
	"strings"
)

// ValidateCommitRequest validates a commit request.
func ValidateCommitRequest(req CommitCircleSetRequest) error {
	if len(req.ChangeNote) > 500 {
		return ErrChangeNoteTooLong
	}
	return nil
}

// CommitSet commits a draft circle set to active status with validation.
// Returns true if a version snapshot should be created.
func CommitSet(set *CircleSet, req CommitCircleSetRequest) (bool, error) {
	// Validate request.
	if err := ValidateCommitRequest(req); err != nil {
		return false, err
	}

	// Validate that set can be committed.
	if err := set.CanCommit(); err != nil {
		return false, err
	}

	// Commit the set.
	if err := set.Commit(); err != nil {
		return false, err
	}

	// Version snapshot should be created for commit transitions.
	return true, nil
}

// ValidateReplaceRequest validates a full replace request.
func ValidateReplaceRequest(req ReplaceCircleSetRequest) error {
	// Validate name.
	name := strings.TrimSpace(req.Name)
	if name == "" {
		return ErrSetNameEmpty
	}
	if len(name) > 100 {
		return ErrSetNameTooLong
	}

	// Validate change note.
	if len(req.ChangeNote) > 500 {
		return ErrChangeNoteTooLong
	}

	// Validate circle capacities.
	if len(req.InnerCircle) > 20 {
		return ErrInnerCircleFull
	}
	if len(req.MiddleCircle) > 50 {
		return ErrMiddleCircleFull
	}
	if len(req.OuterCircle) > 50 {
		return ErrOuterCircleFull
	}

	// Validate each item in inner circle.
	for _, item := range req.InnerCircle {
		if err := validateCircleItemFields(item); err != nil {
			return err
		}
	}

	// Validate each item in middle circle.
	for _, item := range req.MiddleCircle {
		if err := validateCircleItemFields(item); err != nil {
			return err
		}
	}

	// Validate each item in outer circle.
	for _, item := range req.OuterCircle {
		if err := validateCircleItemFields(item); err != nil {
			return err
		}
	}

	return nil
}

// ReplaceSet performs a full replacement of a circle set's circles.
// Returns the list of changed item IDs and whether this creates a new version.
func ReplaceSet(set *CircleSet, req ReplaceCircleSetRequest) ([]string, error) {
	// Validate request.
	if err := ValidateReplaceRequest(req); err != nil {
		return nil, err
	}

	// Track changed items.
	changedItems := []string{}

	// Build a map of existing items for comparison.
	existingItems := make(map[string]CircleItem)
	for _, item := range set.InnerCircle {
		existingItems[item.ItemID] = item
	}
	for _, item := range set.MiddleCircle {
		existingItems[item.ItemID] = item
	}
	for _, item := range set.OuterCircle {
		existingItems[item.ItemID] = item
	}

	// Build a map of new items.
	newItems := make(map[string]bool)
	for _, item := range req.InnerCircle {
		newItems[item.ItemID] = true
	}
	for _, item := range req.MiddleCircle {
		newItems[item.ItemID] = true
	}
	for _, item := range req.OuterCircle {
		newItems[item.ItemID] = true
	}

	// Find deleted items.
	for itemID := range existingItems {
		if !newItems[itemID] {
			changedItems = append(changedItems, itemID)
		}
	}

	// Find new or modified items.
	for _, item := range req.InnerCircle {
		if old, exists := existingItems[item.ItemID]; !exists || itemChanged(old, item) {
			changedItems = append(changedItems, item.ItemID)
		}
	}
	for _, item := range req.MiddleCircle {
		if old, exists := existingItems[item.ItemID]; !exists || itemChanged(old, item) {
			changedItems = append(changedItems, item.ItemID)
		}
	}
	for _, item := range req.OuterCircle {
		if old, exists := existingItems[item.ItemID]; !exists || itemChanged(old, item) {
			changedItems = append(changedItems, item.ItemID)
		}
	}

	// Apply the replacement.
	set.Name = strings.TrimSpace(req.Name)
	set.InnerCircle = req.InnerCircle
	set.MiddleCircle = req.MiddleCircle
	set.OuterCircle = req.OuterCircle
	set.IncrementVersion()

	return changedItems, nil
}

// validateCircleItemFields validates the fields of a circle item.
func validateCircleItemFields(item CircleItem) error {
	behaviorName := strings.TrimSpace(item.BehaviorName)
	if behaviorName == "" {
		return ErrBehaviorNameEmpty
	}
	if len(behaviorName) > 200 {
		return ErrBehaviorNameTooLong
	}

	if len(item.Notes) > 1000 {
		return ErrNotesTooLong
	}

	if len(item.SpecificityDetail) > 500 {
		return ErrSpecificityDetailTooLong
	}

	if len(item.Category) > 50 {
		return ErrCategoryTooLong
	}

	if !item.Source.IsValid() {
		return ErrInvalidSource
	}

	return nil
}

// itemChanged compares two circle items to determine if they differ.
func itemChanged(old, new CircleItem) bool {
	return old.BehaviorName != new.BehaviorName ||
		old.Notes != new.Notes ||
		old.SpecificityDetail != new.SpecificityDetail ||
		old.Category != new.Category ||
		old.Uncertain != new.Uncertain
}
