// internal/domain/threecircles/set_test.go
package threecircles

import (
	"testing"
	"time"
)

func TestNewCircleSet(t *testing.T) {
	tests := []struct {
		name      string
		userID    string
		tenantID  string
		req       CreateCircleSetRequest
		wantErr   error
		checkFunc func(*testing.T, *CircleSet)
	}{
		{
			name:     "valid draft set",
			userID:   "user123",
			tenantID: "tenant456",
			req: CreateCircleSetRequest{
				Name:              "My Recovery Plan",
				RecoveryArea:      RecoveryAreaSexPornography,
				CommitImmediately: false,
			},
			wantErr: nil,
			checkFunc: func(t *testing.T, cs *CircleSet) {
				if cs.Status != StatusDraft {
					t.Errorf("expected status draft, got %v", cs.Status)
				}
				if cs.CommittedAt != nil {
					t.Error("expected committedAt to be nil for draft")
				}
				if cs.CurrentVersion != 1 {
					t.Errorf("expected version 1, got %d", cs.CurrentVersion)
				}
			},
		},
		{
			name:     "valid active set with immediate commit",
			userID:   "user123",
			tenantID: "tenant456",
			req: CreateCircleSetRequest{
				Name:              "Active Plan",
				RecoveryArea:      RecoveryAreaAlcohol,
				CommitImmediately: true,
			},
			wantErr: nil,
			checkFunc: func(t *testing.T, cs *CircleSet) {
				if cs.Status != StatusActive {
					t.Errorf("expected status active, got %v", cs.Status)
				}
				if cs.CommittedAt == nil {
					t.Error("expected committedAt to be set for active set")
				}
			},
		},
		{
			name:     "empty name",
			userID:   "user123",
			tenantID: "tenant456",
			req: CreateCircleSetRequest{
				Name:         "",
				RecoveryArea: RecoveryAreaSexPornography,
			},
			wantErr: ErrSetNameEmpty,
		},
		{
			name:     "name too long",
			userID:   "user123",
			tenantID: "tenant456",
			req: CreateCircleSetRequest{
				Name:         string(make([]byte, 101)),
				RecoveryArea: RecoveryAreaSexPornography,
			},
			wantErr: ErrSetNameTooLong,
		},
		{
			name:     "invalid recovery area",
			userID:   "user123",
			tenantID: "tenant456",
			req: CreateCircleSetRequest{
				Name:         "Test",
				RecoveryArea: "invalid",
			},
			wantErr: ErrInvalidRecoveryArea,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cs, err := NewCircleSet(tt.userID, tt.tenantID, tt.req)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if cs.UserID != tt.userID {
				t.Errorf("expected userID %s, got %s", tt.userID, cs.UserID)
			}

			if cs.TenantID != tt.tenantID {
				t.Errorf("expected tenantID %s, got %s", tt.tenantID, cs.TenantID)
			}

			if cs.RecoveryArea != tt.req.RecoveryArea {
				t.Errorf("expected recovery area %v, got %v", tt.req.RecoveryArea, cs.RecoveryArea)
			}

			if tt.checkFunc != nil {
				tt.checkFunc(t, cs)
			}
		})
	}
}

func TestCircleSet_UpdateSetName(t *testing.T) {
	tests := []struct {
		name    string
		initial string
		newName string
		wantErr error
	}{
		{
			name:    "valid update",
			initial: "Old Name",
			newName: "New Name",
			wantErr: nil,
		},
		{
			name:    "empty name",
			initial: "Old Name",
			newName: "",
			wantErr: ErrSetNameEmpty,
		},
		{
			name:    "name too long",
			initial: "Old Name",
			newName: string(make([]byte, 101)),
			wantErr: ErrSetNameTooLong,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cs := &CircleSet{Name: tt.initial, ModifiedAt: time.Now().Add(-1 * time.Hour)}
			oldModified := cs.ModifiedAt

			err := cs.UpdateSetName(tt.newName)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if cs.Name != tt.newName {
				t.Errorf("expected name %s, got %s", tt.newName, cs.Name)
			}

			if !cs.ModifiedAt.After(oldModified) {
				t.Error("expected ModifiedAt to be updated")
			}
		})
	}
}

func TestCircleSet_CanCommit(t *testing.T) {
	tests := []struct {
		name    string
		setup   func() *CircleSet
		wantErr error
	}{
		{
			name: "valid draft with inner items",
			setup: func() *CircleSet {
				return &CircleSet{
					Status: StatusDraft,
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
				}
			},
			wantErr: nil,
		},
		{
			name: "already active",
			setup: func() *CircleSet {
				return &CircleSet{
					Status: StatusActive,
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
				}
			},
			wantErr: ErrCannotCommitActive,
		},
		{
			name: "archived",
			setup: func() *CircleSet {
				return &CircleSet{
					Status: StatusArchived,
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
				}
			},
			wantErr: ErrCannotCommitArchived,
		},
		{
			name: "empty inner circle",
			setup: func() *CircleSet {
				return &CircleSet{
					Status:      StatusDraft,
					InnerCircle: []CircleItem{},
				}
			},
			wantErr: ErrInnerCircleEmpty,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cs := tt.setup()
			err := cs.CanCommit()

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
		})
	}
}

func TestCircleSet_Commit(t *testing.T) {
	t.Run("successful commit", func(t *testing.T) {
		cs := &CircleSet{
			Status:         StatusDraft,
			CurrentVersion: 1,
			InnerCircle: []CircleItem{
				{ItemID: "item1", BehaviorName: "Test"},
			},
			ModifiedAt: time.Now().Add(-1 * time.Hour),
		}

		oldVersion := cs.CurrentVersion
		oldModified := cs.ModifiedAt

		err := cs.Commit()
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if cs.Status != StatusActive {
			t.Errorf("expected status active, got %v", cs.Status)
		}

		if cs.CommittedAt == nil {
			t.Error("expected committedAt to be set")
		}

		if cs.CurrentVersion != oldVersion+1 {
			t.Errorf("expected version %d, got %d", oldVersion+1, cs.CurrentVersion)
		}

		if !cs.ModifiedAt.After(oldModified) {
			t.Error("expected ModifiedAt to be updated")
		}
	})
}

func TestCircleSet_Archive(t *testing.T) {
	t.Run("archive set", func(t *testing.T) {
		cs := &CircleSet{
			Status:     StatusActive,
			ModifiedAt: time.Now().Add(-1 * time.Hour),
		}

		oldModified := cs.ModifiedAt
		cs.Archive()

		if cs.Status != StatusArchived {
			t.Errorf("expected status archived, got %v", cs.Status)
		}

		if !cs.ModifiedAt.After(oldModified) {
			t.Error("expected ModifiedAt to be updated")
		}
	})
}

func TestCircleSet_GetCircle(t *testing.T) {
	inner := []CircleItem{{ItemID: "i1"}}
	middle := []CircleItem{{ItemID: "m1"}}
	outer := []CircleItem{{ItemID: "o1"}}

	cs := &CircleSet{
		InnerCircle:  inner,
		MiddleCircle: middle,
		OuterCircle:  outer,
	}

	tests := []struct {
		name       string
		circleType CircleType
		wantLen    int
		wantErr    error
	}{
		{
			name:       "get inner circle",
			circleType: CircleTypeInner,
			wantLen:    1,
			wantErr:    nil,
		},
		{
			name:       "get middle circle",
			circleType: CircleTypeMiddle,
			wantLen:    1,
			wantErr:    nil,
		},
		{
			name:       "get outer circle",
			circleType: CircleTypeOuter,
			wantLen:    1,
			wantErr:    nil,
		},
		{
			name:       "invalid circle type",
			circleType: "invalid",
			wantLen:    0,
			wantErr:    ErrInvalidCircleType,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			items, err := cs.GetCircle(tt.circleType)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if len(items) != tt.wantLen {
				t.Errorf("expected %d items, got %d", tt.wantLen, len(items))
			}
		})
	}
}

func TestCircleSet_GetAllItems(t *testing.T) {
	t.Run("get all items with circle types", func(t *testing.T) {
		cs := &CircleSet{
			InnerCircle:  []CircleItem{{ItemID: "i1"}, {ItemID: "i2"}},
			MiddleCircle: []CircleItem{{ItemID: "m1"}},
			OuterCircle:  []CircleItem{{ItemID: "o1"}, {ItemID: "o2"}, {ItemID: "o3"}},
		}

		items := cs.GetAllItems()

		if len(items) != 6 {
			t.Errorf("expected 6 items, got %d", len(items))
		}

		if items["i1"] != CircleTypeInner {
			t.Errorf("expected i1 to be in inner circle")
		}

		if items["m1"] != CircleTypeMiddle {
			t.Errorf("expected m1 to be in middle circle")
		}

		if items["o1"] != CircleTypeOuter {
			t.Errorf("expected o1 to be in outer circle")
		}
	})
}

func TestCircleSet_CountItems(t *testing.T) {
	t.Run("count items in all circles", func(t *testing.T) {
		cs := &CircleSet{
			InnerCircle:  []CircleItem{{ItemID: "i1"}, {ItemID: "i2"}},
			MiddleCircle: []CircleItem{{ItemID: "m1"}},
			OuterCircle:  []CircleItem{{ItemID: "o1"}, {ItemID: "o2"}, {ItemID: "o3"}},
		}

		inner, middle, outer := cs.CountItems()

		if inner != 2 {
			t.Errorf("expected 2 inner items, got %d", inner)
		}
		if middle != 1 {
			t.Errorf("expected 1 middle item, got %d", middle)
		}
		if outer != 3 {
			t.Errorf("expected 3 outer items, got %d", outer)
		}
	})
}
