// internal/domain/threecircles/version.go
package threecircles

import (
	"time"
)

// CreateVersionSnapshot creates a new version snapshot from a circle set.
func CreateVersionSnapshot(
	set *CircleSet,
	changeType ChangeType,
	changeNote string,
	changedItems []string,
) (*VersionSnapshot, error) {
	// Validate change type.
	if !changeType.IsValid() {
		return nil, ErrInvalidChangeType
	}

	// Validate change note length.
	if len(changeNote) > 500 {
		return nil, ErrChangeNoteTooLong
	}

	// Create a deep copy of the circle set for the snapshot.
	snapshotSet := *set

	// Copy slices to avoid shared references.
	snapshotSet.InnerCircle = make([]CircleItem, len(set.InnerCircle))
	copy(snapshotSet.InnerCircle, set.InnerCircle)

	snapshotSet.MiddleCircle = make([]CircleItem, len(set.MiddleCircle))
	copy(snapshotSet.MiddleCircle, set.MiddleCircle)

	snapshotSet.OuterCircle = make([]CircleItem, len(set.OuterCircle))
	copy(snapshotSet.OuterCircle, set.OuterCircle)

	// Get counts.
	innerCount := len(set.InnerCircle)
	middleCount := len(set.MiddleCircle)
	outerCount := len(set.OuterCircle)

	// Create version snapshot.
	snapshot := &VersionSnapshot{
		VersionNumber: set.CurrentVersion,
		SetID:         set.ID,
		UserID:        set.UserID,
		Snapshot:      snapshotSet,
		ChangeNote:    changeNote,
		ChangeType:    changeType,
		ChangedItems:  changedItems,
		InnerCount:    innerCount,
		MiddleCount:   middleCount,
		OuterCount:    outerCount,
		ChangedAt:     time.Now().UTC(),
	}

	return snapshot, nil
}

// CreateSnapshotForItemAdded creates a version snapshot for an item addition.
func CreateSnapshotForItemAdded(set *CircleSet, itemID string, changeNote string) (*VersionSnapshot, error) {
	return CreateVersionSnapshot(set, ChangeItemAdded, changeNote, []string{itemID})
}

// CreateSnapshotForItemUpdated creates a version snapshot for an item update.
func CreateSnapshotForItemUpdated(set *CircleSet, itemID string, changeNote string) (*VersionSnapshot, error) {
	return CreateVersionSnapshot(set, ChangeItemUpdated, changeNote, []string{itemID})
}

// CreateSnapshotForItemDeleted creates a version snapshot for an item deletion.
func CreateSnapshotForItemDeleted(set *CircleSet, itemID string, changeNote string) (*VersionSnapshot, error) {
	return CreateVersionSnapshot(set, ChangeItemDeleted, changeNote, []string{itemID})
}

// CreateSnapshotForItemMoved creates a version snapshot for an item move.
func CreateSnapshotForItemMoved(set *CircleSet, itemID string, sourceCircle, targetCircle CircleType, changeNote string) (*VersionSnapshot, error) {
	if changeNote == "" {
		changeNote = "Moved from " + string(sourceCircle) + " to " + string(targetCircle)
	}
	return CreateVersionSnapshot(set, ChangeItemMoved, changeNote, []string{itemID})
}

// CreateSnapshotForCommit creates a version snapshot for set commitment.
func CreateSnapshotForCommit(set *CircleSet, changeNote string) (*VersionSnapshot, error) {
	return CreateVersionSnapshot(set, ChangeSetCommitted, changeNote, nil)
}

// CreateSnapshotForBulkReplace creates a version snapshot for a full circle set replacement.
func CreateSnapshotForBulkReplace(set *CircleSet, changedItems []string, changeNote string) (*VersionSnapshot, error) {
	return CreateVersionSnapshot(set, ChangeBulkReplace, changeNote, changedItems)
}

// CreateSnapshotForRestore creates a version snapshot when restoring from an older version.
func CreateSnapshotForRestore(set *CircleSet, restoredFromVersion int, changeNote string) (*VersionSnapshot, error) {
	if changeNote == "" {
		changeNote = "Restored from version " + string(rune(restoredFromVersion+'0'))
	}
	return CreateVersionSnapshot(set, ChangeSetRestored, changeNote, nil)
}

// CreateSnapshotForStarterPack creates a version snapshot when a starter pack is applied.
func CreateSnapshotForStarterPack(set *CircleSet, packID string, changeNote string) (*VersionSnapshot, error) {
	if changeNote == "" {
		changeNote = "Applied starter pack: " + packID
	}
	return CreateVersionSnapshot(set, ChangeStarterPackApplied, changeNote, nil)
}

// CreateSnapshotForReview creates a version snapshot for quarterly review changes.
func CreateSnapshotForReview(set *CircleSet, changedItems []string, changeNote string) (*VersionSnapshot, error) {
	return CreateVersionSnapshot(set, ChangeReviewChange, changeNote, changedItems)
}

// RestoreFromSnapshot restores a circle set from a version snapshot.
// Returns a new circle set with the restored state.
func RestoreFromSnapshot(currentSet *CircleSet, snapshot *VersionSnapshot) *CircleSet {
	// Create a new set based on the snapshot.
	restored := snapshot.Snapshot

	// Preserve immutable fields from current set.
	restored.ID = currentSet.ID
	restored.UserID = currentSet.UserID
	restored.TenantID = currentSet.TenantID
	restored.CreatedAt = currentSet.CreatedAt

	// Update mutable tracking fields.
	restored.CurrentVersion = currentSet.CurrentVersion + 1
	restored.ModifiedAt = time.Now().UTC()

	// Keep the current status (don't restore status from snapshot).
	restored.Status = currentSet.Status

	return &restored
}
