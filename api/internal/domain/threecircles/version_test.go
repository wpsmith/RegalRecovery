// internal/domain/threecircles/version_test.go
package threecircles

import (
	"testing"
	"time"
)

func TestCreateVersionSnapshot(t *testing.T) {
	now := time.Now().UTC()
	set := &CircleSet{
		ID:       "set123",
		UserID:   "user456",
		TenantID: "tenant789",
		Name:     "Test Set",
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Inner Item"},
		},
		MiddleCircle: []CircleItem{
			{ItemID: "m1", BehaviorName: "Middle Item"},
		},
		OuterCircle: []CircleItem{
			{ItemID: "o1", BehaviorName: "Outer Item"},
			{ItemID: "o2", BehaviorName: "Outer Item 2"},
		},
		CurrentVersion: 5,
		CreatedAt:      now,
		ModifiedAt:     now,
	}

	tests := []struct {
		name         string
		changeType   ChangeType
		changeNote   string
		changedItems []string
		wantErr      error
	}{
		{
			name:         "valid snapshot",
			changeType:   ChangeItemAdded,
			changeNote:   "Added new item",
			changedItems: []string{"i2"},
			wantErr:      nil,
		},
		{
			name:         "invalid change type",
			changeType:   "invalid",
			changeNote:   "Test",
			changedItems: nil,
			wantErr:      ErrInvalidChangeType,
		},
		{
			name:         "change note too long",
			changeType:   ChangeItemAdded,
			changeNote:   string(make([]byte, 501)),
			changedItems: nil,
			wantErr:      ErrChangeNoteTooLong,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			snapshot, err := CreateVersionSnapshot(set, tt.changeType, tt.changeNote, tt.changedItems)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			// Validate snapshot fields.
			if snapshot.VersionNumber != set.CurrentVersion {
				t.Errorf("expected version %d, got %d", set.CurrentVersion, snapshot.VersionNumber)
			}

			if snapshot.SetID != set.ID {
				t.Errorf("expected setID %s, got %s", set.ID, snapshot.SetID)
			}

			if snapshot.UserID != set.UserID {
				t.Errorf("expected userID %s, got %s", set.UserID, snapshot.UserID)
			}

			if snapshot.ChangeType != tt.changeType {
				t.Errorf("expected changeType %v, got %v", tt.changeType, snapshot.ChangeType)
			}

			if snapshot.ChangeNote != tt.changeNote {
				t.Errorf("expected changeNote %s, got %s", tt.changeNote, snapshot.ChangeNote)
			}

			if snapshot.InnerCount != 1 {
				t.Errorf("expected innerCount 1, got %d", snapshot.InnerCount)
			}

			if snapshot.MiddleCount != 1 {
				t.Errorf("expected middleCount 1, got %d", snapshot.MiddleCount)
			}

			if snapshot.OuterCount != 2 {
				t.Errorf("expected outerCount 2, got %d", snapshot.OuterCount)
			}

			// Verify deep copy.
			if &snapshot.Snapshot.InnerCircle == &set.InnerCircle {
				t.Error("expected InnerCircle to be a copy, not a reference")
			}
		})
	}
}

func TestCreateSnapshotForItemAdded(t *testing.T) {
	t.Run("create snapshot for item addition", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
			InnerCircle: []CircleItem{
				{ItemID: "i1", BehaviorName: "Test"},
			},
		}

		snapshot, err := CreateSnapshotForItemAdded(set, "i1", "Added first item")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeItemAdded {
			t.Errorf("expected changeType %v, got %v", ChangeItemAdded, snapshot.ChangeType)
		}

		if len(snapshot.ChangedItems) != 1 || snapshot.ChangedItems[0] != "i1" {
			t.Errorf("expected changedItems [i1], got %v", snapshot.ChangedItems)
		}
	})
}

func TestCreateSnapshotForItemUpdated(t *testing.T) {
	t.Run("create snapshot for item update", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		snapshot, err := CreateSnapshotForItemUpdated(set, "i1", "Updated item")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeItemUpdated {
			t.Errorf("expected changeType %v, got %v", ChangeItemUpdated, snapshot.ChangeType)
		}
	})
}

func TestCreateSnapshotForItemDeleted(t *testing.T) {
	t.Run("create snapshot for item deletion", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		snapshot, err := CreateSnapshotForItemDeleted(set, "i1", "Deleted item")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeItemDeleted {
			t.Errorf("expected changeType %v, got %v", ChangeItemDeleted, snapshot.ChangeType)
		}
	})
}

func TestCreateSnapshotForItemMoved(t *testing.T) {
	t.Run("create snapshot for item move with note", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		snapshot, err := CreateSnapshotForItemMoved(set, "i1", CircleTypeInner, CircleTypeMiddle, "Custom note")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeItemMoved {
			t.Errorf("expected changeType %v, got %v", ChangeItemMoved, snapshot.ChangeType)
		}

		if snapshot.ChangeNote != "Custom note" {
			t.Errorf("expected custom note, got %s", snapshot.ChangeNote)
		}
	})

	t.Run("create snapshot for item move with default note", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		snapshot, err := CreateSnapshotForItemMoved(set, "i1", CircleTypeInner, CircleTypeMiddle, "")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeNote == "" {
			t.Error("expected default change note to be generated")
		}
	})
}

func TestCreateSnapshotForCommit(t *testing.T) {
	t.Run("create snapshot for commit", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		snapshot, err := CreateSnapshotForCommit(set, "Initial commit")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeSetCommitted {
			t.Errorf("expected changeType %v, got %v", ChangeSetCommitted, snapshot.ChangeType)
		}

		if snapshot.ChangeNote != "Initial commit" {
			t.Errorf("expected note 'Initial commit', got %s", snapshot.ChangeNote)
		}
	})
}

func TestCreateSnapshotForBulkReplace(t *testing.T) {
	t.Run("create snapshot for bulk replace", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		changedItems := []string{"i1", "i2", "m1"}
		snapshot, err := CreateSnapshotForBulkReplace(set, changedItems, "Bulk update")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeBulkReplace {
			t.Errorf("expected changeType %v, got %v", ChangeBulkReplace, snapshot.ChangeType)
		}

		if len(snapshot.ChangedItems) != 3 {
			t.Errorf("expected 3 changed items, got %d", len(snapshot.ChangedItems))
		}
	})
}

func TestCreateSnapshotForRestore(t *testing.T) {
	t.Run("create snapshot for restore with custom note", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 5,
		}

		snapshot, err := CreateSnapshotForRestore(set, 3, "Custom restore note")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeSetRestored {
			t.Errorf("expected changeType %v, got %v", ChangeSetRestored, snapshot.ChangeType)
		}

		if snapshot.ChangeNote != "Custom restore note" {
			t.Errorf("expected custom note, got %s", snapshot.ChangeNote)
		}
	})

	t.Run("create snapshot for restore with default note", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 5,
		}

		snapshot, err := CreateSnapshotForRestore(set, 3, "")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeNote == "" {
			t.Error("expected default note to be generated")
		}
	})
}

func TestCreateSnapshotForStarterPack(t *testing.T) {
	t.Run("create snapshot for starter pack", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		snapshot, err := CreateSnapshotForStarterPack(set, "pack123", "Applied pack")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeStarterPackApplied {
			t.Errorf("expected changeType %v, got %v", ChangeStarterPackApplied, snapshot.ChangeType)
		}
	})
}

func TestCreateSnapshotForReview(t *testing.T) {
	t.Run("create snapshot for review", func(t *testing.T) {
		set := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			CurrentVersion: 1,
		}

		changedItems := []string{"i1", "m2"}
		snapshot, err := CreateSnapshotForReview(set, changedItems, "Quarterly review changes")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if snapshot.ChangeType != ChangeReviewChange {
			t.Errorf("expected changeType %v, got %v", ChangeReviewChange, snapshot.ChangeType)
		}

		if len(snapshot.ChangedItems) != 2 {
			t.Errorf("expected 2 changed items, got %d", len(snapshot.ChangedItems))
		}
	})
}

func TestRestoreFromSnapshot(t *testing.T) {
	t.Run("restore from snapshot", func(t *testing.T) {
		now := time.Now().UTC()
		currentSet := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			TenantID:       "tenant789",
			Name:           "Current Name",
			Status:         StatusActive,
			CurrentVersion: 5,
			CreatedAt:      now.Add(-30 * 24 * time.Hour),
			ModifiedAt:     now,
			InnerCircle: []CircleItem{
				{ItemID: "i1", BehaviorName: "Current Item"},
			},
		}

		snapshotSet := CircleSet{
			Name: "Old Name",
			InnerCircle: []CircleItem{
				{ItemID: "i_old", BehaviorName: "Old Item"},
			},
			MiddleCircle: []CircleItem{
				{ItemID: "m_old", BehaviorName: "Old Middle Item"},
			},
			CurrentVersion: 3,
		}

		snapshot := &VersionSnapshot{
			VersionNumber: 3,
			Snapshot:      snapshotSet,
		}

		restored := RestoreFromSnapshot(currentSet, snapshot)

		// Verify immutable fields are preserved.
		if restored.ID != currentSet.ID {
			t.Errorf("expected ID %s, got %s", currentSet.ID, restored.ID)
		}

		if restored.UserID != currentSet.UserID {
			t.Errorf("expected UserID %s, got %s", currentSet.UserID, restored.UserID)
		}

		if restored.TenantID != currentSet.TenantID {
			t.Errorf("expected TenantID %s, got %s", currentSet.TenantID, restored.TenantID)
		}

		if restored.CreatedAt != currentSet.CreatedAt {
			t.Errorf("expected CreatedAt to be preserved")
		}

		// Verify status is preserved (not restored from snapshot).
		if restored.Status != currentSet.Status {
			t.Errorf("expected Status %v, got %v", currentSet.Status, restored.Status)
		}

		// Verify version incremented.
		if restored.CurrentVersion != currentSet.CurrentVersion+1 {
			t.Errorf("expected version %d, got %d", currentSet.CurrentVersion+1, restored.CurrentVersion)
		}

		// Verify snapshot data was applied.
		if restored.Name != "Old Name" {
			t.Errorf("expected restored name 'Old Name', got %s", restored.Name)
		}

		if len(restored.InnerCircle) != 1 || restored.InnerCircle[0].ItemID != "i_old" {
			t.Error("expected inner circle to be restored from snapshot")
		}

		if len(restored.MiddleCircle) != 1 {
			t.Errorf("expected 1 middle item, got %d", len(restored.MiddleCircle))
		}
	})
}
