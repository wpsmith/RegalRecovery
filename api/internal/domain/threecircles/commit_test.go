// internal/domain/threecircles/commit_test.go
package threecircles

import (
	"testing"
)

func TestValidateCommitRequest(t *testing.T) {
	tests := []struct {
		name    string
		req     CommitCircleSetRequest
		wantErr error
	}{
		{
			name: "valid request",
			req: CommitCircleSetRequest{
				ChangeNote: "Reviewed with sponsor",
			},
			wantErr: nil,
		},
		{
			name: "empty change note is valid",
			req: CommitCircleSetRequest{
				ChangeNote: "",
			},
			wantErr: nil,
		},
		{
			name: "change note too long",
			req: CommitCircleSetRequest{
				ChangeNote: string(make([]byte, 501)),
			},
			wantErr: ErrChangeNoteTooLong,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateCommitRequest(tt.req)

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

func TestCommitSet(t *testing.T) {
	tests := []struct {
		name              string
		setup             func() *CircleSet
		req               CommitCircleSetRequest
		wantErr           error
		wantVersionCreate bool
	}{
		{
			name: "valid commit",
			setup: func() *CircleSet {
				return &CircleSet{
					Status: StatusDraft,
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
					CurrentVersion: 1,
				}
			},
			req: CommitCircleSetRequest{
				ChangeNote: "Initial commit",
			},
			wantErr:           nil,
			wantVersionCreate: true,
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
			req: CommitCircleSetRequest{
				ChangeNote: "Try to commit",
			},
			wantErr:           ErrCannotCommitActive,
			wantVersionCreate: false,
		},
		{
			name: "empty inner circle",
			setup: func() *CircleSet {
				return &CircleSet{
					Status:      StatusDraft,
					InnerCircle: []CircleItem{},
				}
			},
			req: CommitCircleSetRequest{
				ChangeNote: "Try to commit",
			},
			wantErr:           ErrInnerCircleEmpty,
			wantVersionCreate: false,
		},
		{
			name: "change note too long",
			setup: func() *CircleSet {
				return &CircleSet{
					Status: StatusDraft,
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
				}
			},
			req: CommitCircleSetRequest{
				ChangeNote: string(make([]byte, 501)),
			},
			wantErr:           ErrChangeNoteTooLong,
			wantVersionCreate: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			set := tt.setup()
			oldVersion := set.CurrentVersion

			shouldCreateVersion, err := CommitSet(set, tt.req)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if shouldCreateVersion != tt.wantVersionCreate {
				t.Errorf("expected shouldCreateVersion %v, got %v", tt.wantVersionCreate, shouldCreateVersion)
			}

			if shouldCreateVersion {
				if set.Status != StatusActive {
					t.Errorf("expected status active, got %v", set.Status)
				}
				if set.CurrentVersion != oldVersion+1 {
					t.Errorf("expected version %d, got %d", oldVersion+1, set.CurrentVersion)
				}
			}
		})
	}
}

func TestValidateReplaceRequest(t *testing.T) {
	tests := []struct {
		name    string
		req     ReplaceCircleSetRequest
		wantErr error
	}{
		{
			name: "valid replace",
			req: ReplaceCircleSetRequest{
				Name: "Updated Plan",
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "Test", Source: SourceUser},
				},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
			wantErr: nil,
		},
		{
			name: "empty name",
			req: ReplaceCircleSetRequest{
				Name:         "",
				InnerCircle:  []CircleItem{},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
			wantErr: ErrSetNameEmpty,
		},
		{
			name: "name too long",
			req: ReplaceCircleSetRequest{
				Name:         string(make([]byte, 101)),
				InnerCircle:  []CircleItem{},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
			wantErr: ErrSetNameTooLong,
		},
		{
			name: "inner circle too full",
			req: ReplaceCircleSetRequest{
				Name:         "Test",
				InnerCircle:  make([]CircleItem, 21),
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
			wantErr: ErrInnerCircleFull,
		},
		{
			name: "middle circle too full",
			req: ReplaceCircleSetRequest{
				Name:         "Test",
				InnerCircle:  []CircleItem{},
				MiddleCircle: make([]CircleItem, 51),
				OuterCircle:  []CircleItem{},
			},
			wantErr: ErrMiddleCircleFull,
		},
		{
			name: "outer circle too full",
			req: ReplaceCircleSetRequest{
				Name:         "Test",
				InnerCircle:  []CircleItem{},
				MiddleCircle: []CircleItem{},
				OuterCircle:  make([]CircleItem, 51),
			},
			wantErr: ErrOuterCircleFull,
		},
		{
			name: "change note too long",
			req: ReplaceCircleSetRequest{
				Name:         "Test",
				InnerCircle:  []CircleItem{},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
				ChangeNote:   string(make([]byte, 501)),
			},
			wantErr: ErrChangeNoteTooLong,
		},
		{
			name: "invalid item behavior name",
			req: ReplaceCircleSetRequest{
				Name: "Test",
				InnerCircle: []CircleItem{
					{ItemID: "i1", BehaviorName: "", Source: SourceUser},
				},
				MiddleCircle: []CircleItem{},
				OuterCircle:  []CircleItem{},
			},
			wantErr: ErrBehaviorNameEmpty,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateReplaceRequest(tt.req)

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

func TestReplaceSet(t *testing.T) {
	t.Run("successful replace with changes", func(t *testing.T) {
		set := &CircleSet{
			Name: "Old Name",
			InnerCircle: []CircleItem{
				{ItemID: "i1", BehaviorName: "Old Behavior", Source: SourceUser},
			},
			MiddleCircle: []CircleItem{
				{ItemID: "m1", BehaviorName: "Middle Item", Source: SourceUser},
			},
			OuterCircle:    []CircleItem{},
			CurrentVersion: 1,
		}

		req := ReplaceCircleSetRequest{
			Name: "New Name",
			InnerCircle: []CircleItem{
				{ItemID: "i1", BehaviorName: "Updated Behavior", Source: SourceUser},
				{ItemID: "i2", BehaviorName: "New Item", Source: SourceUser},
			},
			MiddleCircle: []CircleItem{},
			OuterCircle:  []CircleItem{},
			ChangeNote:   "Major revision",
		}

		changedItems, err := ReplaceSet(set, req)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if set.Name != "New Name" {
			t.Errorf("expected name New Name, got %s", set.Name)
		}

		if len(set.InnerCircle) != 2 {
			t.Errorf("expected 2 inner items, got %d", len(set.InnerCircle))
		}

		if len(set.MiddleCircle) != 0 {
			t.Errorf("expected 0 middle items, got %d", len(set.MiddleCircle))
		}

		if set.CurrentVersion != 2 {
			t.Errorf("expected version 2, got %d", set.CurrentVersion)
		}

		// Should track changed items.
		if len(changedItems) == 0 {
			t.Error("expected changed items to be tracked")
		}
	})

	t.Run("replace with invalid request", func(t *testing.T) {
		set := &CircleSet{
			Name:           "Old Name",
			CurrentVersion: 1,
		}

		req := ReplaceCircleSetRequest{
			Name: "", // Invalid
		}

		_, err := ReplaceSet(set, req)
		if err != ErrSetNameEmpty {
			t.Errorf("expected ErrSetNameEmpty, got %v", err)
		}
	})
}

func TestItemChanged(t *testing.T) {
	tests := []struct {
		name string
		old  CircleItem
		new  CircleItem
		want bool
	}{
		{
			name: "no change",
			old: CircleItem{
				BehaviorName: "Test",
				Notes:        "Notes",
			},
			new: CircleItem{
				BehaviorName: "Test",
				Notes:        "Notes",
			},
			want: false,
		},
		{
			name: "behavior name changed",
			old: CircleItem{
				BehaviorName: "Old",
			},
			new: CircleItem{
				BehaviorName: "New",
			},
			want: true,
		},
		{
			name: "notes changed",
			old: CircleItem{
				BehaviorName: "Test",
				Notes:        "Old Notes",
			},
			new: CircleItem{
				BehaviorName: "Test",
				Notes:        "New Notes",
			},
			want: true,
		},
		{
			name: "uncertain flag changed",
			old: CircleItem{
				BehaviorName: "Test",
				Uncertain:    false,
			},
			new: CircleItem{
				BehaviorName: "Test",
				Uncertain:    true,
			},
			want: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := itemChanged(tt.old, tt.new)
			if got != tt.want {
				t.Errorf("expected %v, got %v", tt.want, got)
			}
		})
	}
}
