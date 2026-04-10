// internal/domain/threecircles/version_history_test.go
package threecircles

import (
	"testing"
	"time"
)

func TestListVersionSummaries_FR6_1_ReverseChronologicalOrder(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()

	versions := []VersionSnapshot{
		{
			VersionNumber: 1,
			ChangeType:    ChangeSetCommitted,
			ChangeNote:    "Initial commit",
			InnerCount:    1,
			MiddleCount:   2,
			OuterCount:    3,
			ChangedAt:     now.Add(-3 * time.Hour),
		},
		{
			VersionNumber: 2,
			ChangeType:    ChangeItemAdded,
			ChangeNote:    "Added new item",
			InnerCount:    2,
			MiddleCount:   2,
			OuterCount:    3,
			ChangedAt:     now.Add(-2 * time.Hour),
		},
		{
			VersionNumber: 3,
			ChangeType:    ChangeItemMoved,
			ChangeNote:    "Moved item",
			InnerCount:    1,
			MiddleCount:   3,
			OuterCount:    3,
			ChangedAt:     now.Add(-1 * time.Hour),
		},
	}

	summaries := ListVersionSummaries(versions)

	// Verify reverse chronological order.
	if len(summaries) != 3 {
		t.Fatalf("expected 3 summaries, got %d", len(summaries))
	}

	if summaries[0].VersionNumber != 3 {
		t.Errorf("expected first summary to be version 3, got %d", summaries[0].VersionNumber)
	}

	if summaries[1].VersionNumber != 2 {
		t.Errorf("expected second summary to be version 2, got %d", summaries[1].VersionNumber)
	}

	if summaries[2].VersionNumber != 1 {
		t.Errorf("expected third summary to be version 1, got %d", summaries[2].VersionNumber)
	}

	// Verify summary fields.
	if summaries[0].ChangeType != ChangeItemMoved {
		t.Errorf("expected changeType %v, got %v", ChangeItemMoved, summaries[0].ChangeType)
	}

	if summaries[0].ChangeNote != "Moved item" {
		t.Errorf("expected changeNote 'Moved item', got %s", summaries[0].ChangeNote)
	}

	if summaries[0].InnerCount != 1 {
		t.Errorf("expected innerCount 1, got %d", summaries[0].InnerCount)
	}

	if summaries[0].MiddleCount != 3 {
		t.Errorf("expected middleCount 3, got %d", summaries[0].MiddleCount)
	}

	if summaries[0].OuterCount != 3 {
		t.Errorf("expected outerCount 3, got %d", summaries[0].OuterCount)
	}

	// Verify timestamp format (ISO 8601).
	if summaries[0].ChangedAt == "" {
		t.Error("expected changedAt to be formatted")
	}
}

func TestListVersionSummaries_EmptyList(t *testing.T) {
	t.Parallel()

	versions := []VersionSnapshot{}
	summaries := ListVersionSummaries(versions)

	if len(summaries) != 0 {
		t.Errorf("expected empty summaries, got %d items", len(summaries))
	}
}

func TestGetVersion_FR6_2_GetSpecificVersion(t *testing.T) {
	t.Parallel()

	versions := []VersionSnapshot{
		{VersionNumber: 1, ChangeNote: "Version 1"},
		{VersionNumber: 2, ChangeNote: "Version 2"},
		{VersionNumber: 3, ChangeNote: "Version 3"},
	}

	tests := []struct {
		name       string
		number     int
		wantFound  bool
		wantNote   string
		wantErrMsg string
	}{
		{
			name:      "get version 2",
			number:    2,
			wantFound: true,
			wantNote:  "Version 2",
		},
		{
			name:      "get version 1",
			number:    1,
			wantFound: true,
			wantNote:  "Version 1",
		},
		{
			name:       "get non-existent version",
			number:     99,
			wantFound:  false,
			wantErrMsg: "version not found: version 99",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			version, err := GetVersion(versions, tt.number)

			if tt.wantFound {
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}

				if version.VersionNumber != tt.number {
					t.Errorf("expected version %d, got %d", tt.number, version.VersionNumber)
				}

				if version.ChangeNote != tt.wantNote {
					t.Errorf("expected changeNote %s, got %s", tt.wantNote, version.ChangeNote)
				}
			} else {
				if err == nil {
					t.Fatal("expected error, got nil")
				}

				if err.Error() != tt.wantErrMsg {
					t.Errorf("expected error message %s, got %s", tt.wantErrMsg, err.Error())
				}
			}
		})
	}
}

func TestGetLatestVersion_FR6_2_LatestKeyword(t *testing.T) {
	t.Parallel()

	t.Run("get latest from multiple versions", func(t *testing.T) {
		versions := []VersionSnapshot{
			{VersionNumber: 1, ChangeNote: "Version 1"},
			{VersionNumber: 3, ChangeNote: "Version 3"},
			{VersionNumber: 2, ChangeNote: "Version 2"},
		}

		latest, err := GetLatestVersion(versions)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if latest.VersionNumber != 3 {
			t.Errorf("expected version 3, got %d", latest.VersionNumber)
		}

		if latest.ChangeNote != "Version 3" {
			t.Errorf("expected changeNote 'Version 3', got %s", latest.ChangeNote)
		}
	})

	t.Run("empty version list", func(t *testing.T) {
		versions := []VersionSnapshot{}

		_, err := GetLatestVersion(versions)
		if err != ErrEmptyVersionList {
			t.Errorf("expected error %v, got %v", ErrEmptyVersionList, err)
		}
	})

	t.Run("single version", func(t *testing.T) {
		versions := []VersionSnapshot{
			{VersionNumber: 5, ChangeNote: "Only version"},
		}

		latest, err := GetLatestVersion(versions)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if latest.VersionNumber != 5 {
			t.Errorf("expected version 5, got %d", latest.VersionNumber)
		}
	})
}

func TestCompareVersions_FR6_3_DiffCalculation(t *testing.T) {
	t.Parallel()

	t.Run("items added", func(t *testing.T) {
		from := VersionSnapshot{
			VersionNumber: 1,
			Snapshot: CircleSet{
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Inner 1"},
				},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
		}

		to := VersionSnapshot{
			VersionNumber: 2,
			Snapshot: CircleSet{
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Inner 1"},
					{ItemID: "i2", BehaviorName: "Inner 2"},
				},
				MiddleCircle: []CircleItem{
					{ItemID: "m1", BehaviorName: "Middle 1"},
				},
				OuterCircle: []CircleItem{},
			},
		}

		diff := CompareVersions(from, to)

		if diff.FromVersion != 1 {
			t.Errorf("expected fromVersion 1, got %d", diff.FromVersion)
		}

		if diff.ToVersion != 2 {
			t.Errorf("expected toVersion 2, got %d", diff.ToVersion)
		}

		if len(diff.InnerAdded) != 1 || diff.InnerAdded[0].ItemID != "i2" {
			t.Errorf("expected 1 inner item added (i2), got %v", diff.InnerAdded)
		}

		if len(diff.MiddleAdded) != 1 || diff.MiddleAdded[0].ItemID != "m1" {
			t.Errorf("expected 1 middle item added (m1), got %v", diff.MiddleAdded)
		}

		if len(diff.ItemsMoved) != 0 {
			t.Errorf("expected no items moved, got %d", len(diff.ItemsMoved))
		}
	})

	t.Run("items removed", func(t *testing.T) {
		from := VersionSnapshot{
			VersionNumber: 1,
			Snapshot: CircleSet{
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Inner 1"},
					{ItemID: "i2", BehaviorName: "Inner 2"},
				},
				MiddleCircle: []CircleItem{
					{ItemID: "m1", BehaviorName: "Middle 1"},
				},
				OuterCircle: []CircleItem{},
			},
		}

		to := VersionSnapshot{
			VersionNumber: 2,
			Snapshot: CircleSet{
				InnerCircle:  []CircleItem{},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
		}

		diff := CompareVersions(from, to)

		if len(diff.InnerRemoved) != 2 {
			t.Errorf("expected 2 inner items removed, got %d", len(diff.InnerRemoved))
		}

		if len(diff.MiddleRemoved) != 1 {
			t.Errorf("expected 1 middle item removed, got %d", len(diff.MiddleRemoved))
		}
	})

	t.Run("items moved between circles", func(t *testing.T) {
		from := VersionSnapshot{
			VersionNumber: 1,
			Snapshot: CircleSet{
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Inner 1"},
				},
				MiddleCircle: []CircleItem{
					{ItemID: "m1", BehaviorName: "Middle 1"},
				},
				OuterCircle: []CircleItem{
					{ItemID: "o1", BehaviorName: "Outer 1"},
				},
			},
		}

		to := VersionSnapshot{
			VersionNumber: 2,
			Snapshot: CircleSet{
				InnerCircle: []CircleItem{
					{ItemID: "m1", BehaviorName: "Middle 1"}, // Moved from middle to inner
				},
				MiddleCircle: []CircleItem{
					{ItemID: "o1", BehaviorName: "Outer 1"}, // Moved from outer to middle
				},
				OuterCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Inner 1"}, // Moved from inner to outer
				},
			},
		}

		diff := CompareVersions(from, to)

		if len(diff.ItemsMoved) != 3 {
			t.Fatalf("expected 3 items moved, got %d", len(diff.ItemsMoved))
		}

		// Verify move from middle to inner.
		foundM1 := false
		for _, move := range diff.ItemsMoved {
			if move.ItemID == "m1" && move.FromCircle == CircleMiddle && move.ToCircle == CircleInner {
				foundM1 = true
			}
		}
		if !foundM1 {
			t.Error("expected m1 to move from middle to inner")
		}

		// Verify move from outer to middle.
		foundO1 := false
		for _, move := range diff.ItemsMoved {
			if move.ItemID == "o1" && move.FromCircle == CircleOuter && move.ToCircle == CircleMiddle {
				foundO1 = true
			}
		}
		if !foundO1 {
			t.Error("expected o1 to move from outer to middle")
		}

		// Verify move from inner to outer.
		foundI1 := false
		for _, move := range diff.ItemsMoved {
			if move.ItemID == "i1" && move.FromCircle == CircleInner && move.ToCircle == CircleOuter {
				foundI1 = true
			}
		}
		if !foundI1 {
			t.Error("expected i1 to move from inner to outer")
		}
	})

	t.Run("no changes", func(t *testing.T) {
		from := VersionSnapshot{
			VersionNumber: 1,
			Snapshot: CircleSet{
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Inner 1"},
				},
			},
		}

		to := VersionSnapshot{
			VersionNumber: 2,
			Snapshot: CircleSet{
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Inner 1"},
				},
			},
		}

		diff := CompareVersions(from, to)

		if len(diff.InnerAdded) != 0 {
			t.Errorf("expected no inner items added, got %d", len(diff.InnerAdded))
		}

		if len(diff.InnerRemoved) != 0 {
			t.Errorf("expected no inner items removed, got %d", len(diff.InnerRemoved))
		}

		if len(diff.ItemsMoved) != 0 {
			t.Errorf("expected no items moved, got %d", len(diff.ItemsMoved))
		}
	})
}

func TestRestoreVersion_FR6_4_RestoreLogic(t *testing.T) {
	t.Parallel()

	now := time.Now().UTC()

	t.Run("restore version replaces current circles", func(t *testing.T) {
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
				{ItemID: "i_current", BehaviorName: "Current Inner"},
			},
			MiddleCircle: []CircleItem{},
			OuterCircle:  []CircleItem{},
		}

		targetSnapshot := VersionSnapshot{
			VersionNumber: 3,
			Snapshot: CircleSet{
				Name: "Old Name",
				InnerCircle: []CircleItem{
					{ItemID: "i_old", BehaviorName: "Old Inner"},
				},
				MiddleCircle: []CircleItem{
					{ItemID: "m_old", BehaviorName: "Old Middle"},
				},
				OuterCircle: []CircleItem{
					{ItemID: "o_old", BehaviorName: "Old Outer"},
				},
			},
		}

		restored, snapshot, err := RestoreVersion(currentSet, targetSnapshot, "Restoring to version 3")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Verify circles were replaced.
		if len(restored.InnerCircle) != 1 || restored.InnerCircle[0].ItemID != "i_old" {
			t.Error("expected inner circle to be restored from target version")
		}

		if len(restored.MiddleCircle) != 1 || restored.MiddleCircle[0].ItemID != "m_old" {
			t.Error("expected middle circle to be restored from target version")
		}

		if len(restored.OuterCircle) != 1 || restored.OuterCircle[0].ItemID != "o_old" {
			t.Error("expected outer circle to be restored from target version")
		}

		// Verify name was restored.
		if restored.Name != "Old Name" {
			t.Errorf("expected name 'Old Name', got %s", restored.Name)
		}

		// Verify new version was created (not rewound).
		if restored.CurrentVersion != 6 {
			t.Errorf("expected version 6 (incremented), got %d", restored.CurrentVersion)
		}

		// Verify snapshot was created.
		if snapshot.ChangeType != ChangeSetRestored {
			t.Errorf("expected changeType %v, got %v", ChangeSetRestored, snapshot.ChangeType)
		}

		if snapshot.ChangeNote != "Restoring to version 3" {
			t.Errorf("expected custom changeNote, got %s", snapshot.ChangeNote)
		}

		if snapshot.VersionNumber != 6 {
			t.Errorf("expected snapshot version 6, got %d", snapshot.VersionNumber)
		}
	})

	t.Run("restore draft set becomes active", func(t *testing.T) {
		currentSet := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			TenantID:       "tenant789",
			Name:           "Draft Set",
			Status:         StatusDraft,
			CurrentVersion: 2,
			CreatedAt:      now,
			ModifiedAt:     now,
			InnerCircle:    []CircleItem{},
		}

		targetSnapshot := VersionSnapshot{
			VersionNumber: 1,
			Snapshot: CircleSet{
				Name: "Previous Version",
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Item 1"},
				},
			},
		}

		restored, _, err := RestoreVersion(currentSet, targetSnapshot, "Restoring draft")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Verify status changed to active.
		if restored.Status != StatusActive {
			t.Errorf("expected status %v, got %v", StatusActive, restored.Status)
		}
	})

	t.Run("restore active set remains active", func(t *testing.T) {
		currentSet := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			TenantID:       "tenant789",
			Name:           "Active Set",
			Status:         StatusActive,
			CurrentVersion: 5,
			CreatedAt:      now,
			ModifiedAt:     now,
			InnerCircle:    []CircleItem{},
		}

		targetSnapshot := VersionSnapshot{
			VersionNumber: 3,
			Snapshot: CircleSet{
				Name:        "Old Version",
				InnerCircle: []CircleItem{},
			},
		}

		restored, _, err := RestoreVersion(currentSet, targetSnapshot, "")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Verify status remains active.
		if restored.Status != StatusActive {
			t.Errorf("expected status %v, got %v", StatusActive, restored.Status)
		}
	})

	t.Run("restore with empty change note", func(t *testing.T) {
		currentSet := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			TenantID:       "tenant789",
			Status:         StatusActive,
			CurrentVersion: 5,
			CreatedAt:      now,
			ModifiedAt:     now,
		}

		targetSnapshot := VersionSnapshot{
			VersionNumber: 3,
			Snapshot:      CircleSet{Name: "Old"},
		}

		_, snapshot, err := RestoreVersion(currentSet, targetSnapshot, "")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Verify default note was generated.
		if snapshot.ChangeNote == "" {
			t.Error("expected default change note to be generated")
		}
	})

	t.Run("restore with change note too long", func(t *testing.T) {
		currentSet := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			TenantID:       "tenant789",
			Status:         StatusActive,
			CurrentVersion: 5,
			CreatedAt:      now,
			ModifiedAt:     now,
		}

		targetSnapshot := VersionSnapshot{
			VersionNumber: 3,
			Snapshot:      CircleSet{},
		}

		longNote := string(make([]byte, 501))

		_, _, err := RestoreVersion(currentSet, targetSnapshot, longNote)
		if err != ErrChangeNoteTooLong {
			t.Errorf("expected error %v, got %v", ErrChangeNoteTooLong, err)
		}
	})

	t.Run("restore preserves immutable fields", func(t *testing.T) {
		originalCreatedAt := now.Add(-60 * 24 * time.Hour)
		currentSet := &CircleSet{
			ID:             "set123",
			UserID:         "user456",
			TenantID:       "tenant789",
			Name:           "Current",
			Status:         StatusActive,
			CurrentVersion: 10,
			CreatedAt:      originalCreatedAt,
			ModifiedAt:     now,
		}

		targetSnapshot := VersionSnapshot{
			VersionNumber: 5,
			Snapshot: CircleSet{
				ID:        "different_id",     // Should be ignored
				UserID:    "different_user",   // Should be ignored
				TenantID:  "different_tenant", // Should be ignored
				Name:      "Old Name",
				CreatedAt: now, // Should be ignored
			},
		}

		restored, _, err := RestoreVersion(currentSet, targetSnapshot, "Restore test")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		// Verify immutable fields are preserved from current set.
		if restored.ID != currentSet.ID {
			t.Errorf("expected ID %s, got %s", currentSet.ID, restored.ID)
		}

		if restored.UserID != currentSet.UserID {
			t.Errorf("expected UserID %s, got %s", currentSet.UserID, restored.UserID)
		}

		if restored.TenantID != currentSet.TenantID {
			t.Errorf("expected TenantID %s, got %s", currentSet.TenantID, restored.TenantID)
		}

		if restored.CreatedAt != originalCreatedAt {
			t.Error("expected CreatedAt to be preserved from current set")
		}

		// Verify mutable field was restored.
		if restored.Name != "Old Name" {
			t.Errorf("expected Name 'Old Name', got %s", restored.Name)
		}
	})
}

func TestMakeItemMap(t *testing.T) {
	t.Parallel()

	t.Run("create item map", func(t *testing.T) {
		items := []CircleItem{
			{ItemID: "i1", BehaviorName: "Item 1"},
			{ItemID: "i2", BehaviorName: "Item 2"},
			{ItemID: "i3", BehaviorName: "Item 3"},
		}

		m := makeItemMap(items)

		if len(m) != 3 {
			t.Fatalf("expected map size 3, got %d", len(m))
		}

		if item, ok := m["i1"]; !ok || item.BehaviorName != "Item 1" {
			t.Error("expected item i1 to be in map")
		}

		if item, ok := m["i2"]; !ok || item.BehaviorName != "Item 2" {
			t.Error("expected item i2 to be in map")
		}

		if item, ok := m["i3"]; !ok || item.BehaviorName != "Item 3" {
			t.Error("expected item i3 to be in map")
		}
	})

	t.Run("empty items list", func(t *testing.T) {
		items := []CircleItem{}
		m := makeItemMap(items)

		if len(m) != 0 {
			t.Errorf("expected empty map, got size %d", len(m))
		}
	})
}
