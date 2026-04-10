// internal/domain/threecircles/item_test.go
package threecircles

import (
	"testing"
)

func TestNewCircleItem(t *testing.T) {
	tests := []struct {
		name      string
		itemID    string
		req       CreateCircleItemRequest
		wantErr   error
		checkFunc func(*testing.T, *CircleItem)
	}{
		{
			name:   "valid item",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:       CircleTypeInner,
				BehaviorName: "Viewing pornography",
				Notes:        "This is my bottom line",
				Source:       SourceUser,
			},
			wantErr: nil,
			checkFunc: func(t *testing.T, item *CircleItem) {
				if item.ItemID != "item123" {
					t.Errorf("expected itemID item123, got %s", item.ItemID)
				}
				if item.BehaviorName != "Viewing pornography" {
					t.Errorf("unexpected behavior name: %s", item.BehaviorName)
				}
			},
		},
		{
			name:   "empty behavior name",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:       CircleTypeInner,
				BehaviorName: "",
				Source:       SourceUser,
			},
			wantErr: ErrBehaviorNameEmpty,
		},
		{
			name:   "behavior name too long",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:       CircleTypeInner,
				BehaviorName: string(make([]byte, 201)),
				Source:       SourceUser,
			},
			wantErr: ErrBehaviorNameTooLong,
		},
		{
			name:   "notes too long",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:       CircleTypeInner,
				BehaviorName: "Test",
				Notes:        string(make([]byte, 1001)),
				Source:       SourceUser,
			},
			wantErr: ErrNotesTooLong,
		},
		{
			name:   "specificity detail too long",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:            CircleTypeInner,
				BehaviorName:      "Test",
				SpecificityDetail: string(make([]byte, 501)),
				Source:            SourceUser,
			},
			wantErr: ErrSpecificityDetailTooLong,
		},
		{
			name:   "category too long",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:       CircleTypeInner,
				BehaviorName: "Test",
				Category:     string(make([]byte, 51)),
				Source:       SourceUser,
			},
			wantErr: ErrCategoryTooLong,
		},
		{
			name:   "invalid circle type",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:       "invalid",
				BehaviorName: "Test",
				Source:       SourceUser,
			},
			wantErr: ErrInvalidCircleType,
		},
		{
			name:   "invalid source",
			itemID: "item123",
			req: CreateCircleItemRequest{
				Circle:       CircleTypeInner,
				BehaviorName: "Test",
				Source:       "invalid",
			},
			wantErr: ErrInvalidSource,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			item, err := NewCircleItem(tt.itemID, tt.req)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if tt.checkFunc != nil {
				tt.checkFunc(t, item)
			}
		})
	}
}

func TestCircleItem_UpdateItem(t *testing.T) {
	tests := []struct {
		name    string
		item    CircleItem
		req     UpdateCircleItemRequest
		wantErr error
	}{
		{
			name: "update behavior name",
			item: CircleItem{BehaviorName: "Old Name"},
			req: UpdateCircleItemRequest{
				BehaviorName: "New Name",
			},
			wantErr: nil,
		},
		{
			name: "empty behavior name with spaces",
			item: CircleItem{BehaviorName: "Old Name"},
			req: UpdateCircleItemRequest{
				BehaviorName: "   ",
			},
			wantErr: ErrBehaviorNameEmpty,
		},
		{
			name: "behavior name too long",
			item: CircleItem{BehaviorName: "Old Name"},
			req: UpdateCircleItemRequest{
				BehaviorName: string(make([]byte, 201)),
			},
			wantErr: ErrBehaviorNameTooLong,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			oldModified := tt.item.ModifiedAt
			err := tt.item.UpdateItem(tt.req)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if tt.req.BehaviorName != "" && tt.item.BehaviorName != tt.req.BehaviorName {
				t.Errorf("expected behavior name %s, got %s", tt.req.BehaviorName, tt.item.BehaviorName)
			}

			if !tt.item.ModifiedAt.After(oldModified) && !tt.item.ModifiedAt.Equal(oldModified) {
				t.Error("expected ModifiedAt to be updated")
			}
		})
	}
}

func TestCircleSet_AddItem(t *testing.T) {
	tests := []struct {
		name       string
		setup      func() *CircleSet
		circleType CircleType
		item       *CircleItem
		wantErr    error
	}{
		{
			name: "add to inner circle",
			setup: func() *CircleSet {
				return &CircleSet{InnerCircle: []CircleItem{}}
			},
			circleType: CircleTypeInner,
			item: &CircleItem{
				ItemID:       "item1",
				BehaviorName: "Test",
			},
			wantErr: nil,
		},
		{
			name: "add to full inner circle",
			setup: func() *CircleSet {
				items := make([]CircleItem, 20)
				for i := range items {
					items[i] = CircleItem{ItemID: "i" + string(rune(i))}
				}
				return &CircleSet{InnerCircle: items}
			},
			circleType: CircleTypeInner,
			item: &CircleItem{
				ItemID:       "item21",
				BehaviorName: "Test",
			},
			wantErr: ErrInnerCircleFull,
		},
		{
			name: "add to full middle circle",
			setup: func() *CircleSet {
				items := make([]CircleItem, 50)
				for i := range items {
					items[i] = CircleItem{ItemID: "m" + string(rune(i))}
				}
				return &CircleSet{MiddleCircle: items}
			},
			circleType: CircleTypeMiddle,
			item: &CircleItem{
				ItemID:       "item51",
				BehaviorName: "Test",
			},
			wantErr: ErrMiddleCircleFull,
		},
		{
			name: "add to full outer circle",
			setup: func() *CircleSet {
				items := make([]CircleItem, 50)
				for i := range items {
					items[i] = CircleItem{ItemID: "o" + string(rune(i))}
				}
				return &CircleSet{OuterCircle: items}
			},
			circleType: CircleTypeOuter,
			item: &CircleItem{
				ItemID:       "item51",
				BehaviorName: "Test",
			},
			wantErr: ErrOuterCircleFull,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cs := tt.setup()
			oldModified := cs.ModifiedAt

			err := cs.AddItem(tt.circleType, tt.item)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if !cs.ModifiedAt.After(oldModified) && !cs.ModifiedAt.IsZero() {
				t.Error("expected ModifiedAt to be updated")
			}
		})
	}
}

func TestCircleSet_UpdateItemInCircle(t *testing.T) {
	t.Run("update existing item", func(t *testing.T) {
		cs := &CircleSet{
			InnerCircle: []CircleItem{
				{ItemID: "item1", BehaviorName: "Old Name"},
			},
		}

		req := UpdateCircleItemRequest{
			BehaviorName: "New Name",
		}

		item, err := cs.UpdateItemInCircle("item1", req)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if item.BehaviorName != "New Name" {
			t.Errorf("expected behavior name New Name, got %s", item.BehaviorName)
		}
	})

	t.Run("item not found", func(t *testing.T) {
		cs := &CircleSet{
			InnerCircle: []CircleItem{},
		}

		req := UpdateCircleItemRequest{
			BehaviorName: "New Name",
		}

		_, err := cs.UpdateItemInCircle("nonexistent", req)
		if err != ErrItemNotFound {
			t.Errorf("expected ErrItemNotFound, got %v", err)
		}
	})
}

func TestCircleSet_DeleteItem(t *testing.T) {
	t.Run("delete from inner circle", func(t *testing.T) {
		cs := &CircleSet{
			InnerCircle: []CircleItem{
				{ItemID: "item1", BehaviorName: "Test1"},
				{ItemID: "item2", BehaviorName: "Test2"},
			},
		}

		err := cs.DeleteItem("item1")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(cs.InnerCircle) != 1 {
			t.Errorf("expected 1 item, got %d", len(cs.InnerCircle))
		}

		if cs.InnerCircle[0].ItemID != "item2" {
			t.Errorf("expected item2 to remain, got %s", cs.InnerCircle[0].ItemID)
		}

		// Check sort order was updated.
		if cs.InnerCircle[0].SortOrder != 0 {
			t.Errorf("expected sort order 0, got %d", cs.InnerCircle[0].SortOrder)
		}
	})

	t.Run("item not found", func(t *testing.T) {
		cs := &CircleSet{
			InnerCircle: []CircleItem{},
		}

		err := cs.DeleteItem("nonexistent")
		if err != ErrItemNotFound {
			t.Errorf("expected ErrItemNotFound, got %v", err)
		}
	})
}

func TestCircleSet_MoveItem(t *testing.T) {
	tests := []struct {
		name             string
		setup            func() *CircleSet
		itemID           string
		targetCircle     CircleType
		wantSourceCircle CircleType
		wantErr          error
	}{
		{
			name: "move from inner to middle",
			setup: func() *CircleSet {
				return &CircleSet{
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
					MiddleCircle: []CircleItem{},
				}
			},
			itemID:           "item1",
			targetCircle:     CircleTypeMiddle,
			wantSourceCircle: CircleTypeInner,
			wantErr:          nil,
		},
		{
			name: "move to same circle",
			setup: func() *CircleSet {
				return &CircleSet{
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
				}
			},
			itemID:           "item1",
			targetCircle:     CircleTypeInner,
			wantSourceCircle: CircleTypeInner,
			wantErr:          ErrSameCircleMove,
		},
		{
			name: "item not found",
			setup: func() *CircleSet {
				return &CircleSet{
					InnerCircle: []CircleItem{},
				}
			},
			itemID:       "nonexistent",
			targetCircle: CircleTypeMiddle,
			wantErr:      ErrItemNotFound,
		},
		{
			name: "target circle full",
			setup: func() *CircleSet {
				middleItems := make([]CircleItem, 50)
				for i := range middleItems {
					middleItems[i] = CircleItem{ItemID: "m" + string(rune(i))}
				}
				return &CircleSet{
					InnerCircle: []CircleItem{
						{ItemID: "item1", BehaviorName: "Test"},
					},
					MiddleCircle: middleItems,
				}
			},
			itemID:           "item1",
			targetCircle:     CircleTypeMiddle,
			wantSourceCircle: CircleTypeInner,
			wantErr:          ErrMiddleCircleFull,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cs := tt.setup()
			oldModified := cs.ModifiedAt

			sourceCircle, err := cs.MoveItem(tt.itemID, tt.targetCircle)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				if sourceCircle != tt.wantSourceCircle {
					t.Errorf("expected source circle %v, got %v", tt.wantSourceCircle, sourceCircle)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if sourceCircle != tt.wantSourceCircle {
				t.Errorf("expected source circle %v, got %v", tt.wantSourceCircle, sourceCircle)
			}

			// Verify item was moved.
			_, circle, err := cs.FindItem(tt.itemID)
			if err != nil {
				t.Fatalf("item not found after move: %v", err)
			}

			if circle != tt.targetCircle {
				t.Errorf("expected item in %v, found in %v", tt.targetCircle, circle)
			}

			if !cs.ModifiedAt.After(oldModified) && !cs.ModifiedAt.IsZero() {
				t.Error("expected ModifiedAt to be updated")
			}
		})
	}
}

func TestCircleSet_FindItem(t *testing.T) {
	cs := &CircleSet{
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Inner Item"},
		},
		MiddleCircle: []CircleItem{
			{ItemID: "m1", BehaviorName: "Middle Item"},
		},
		OuterCircle: []CircleItem{
			{ItemID: "o1", BehaviorName: "Outer Item"},
		},
	}

	tests := []struct {
		name       string
		itemID     string
		wantCircle CircleType
		wantErr    error
	}{
		{
			name:       "find in inner circle",
			itemID:     "i1",
			wantCircle: CircleTypeInner,
			wantErr:    nil,
		},
		{
			name:       "find in middle circle",
			itemID:     "m1",
			wantCircle: CircleTypeMiddle,
			wantErr:    nil,
		},
		{
			name:       "find in outer circle",
			itemID:     "o1",
			wantCircle: CircleTypeOuter,
			wantErr:    nil,
		},
		{
			name:    "item not found",
			itemID:  "nonexistent",
			wantErr: ErrItemNotFound,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			item, circle, err := cs.FindItem(tt.itemID)

			if tt.wantErr != nil {
				if err != tt.wantErr {
					t.Errorf("expected error %v, got %v", tt.wantErr, err)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}

			if item.ItemID != tt.itemID {
				t.Errorf("expected item ID %s, got %s", tt.itemID, item.ItemID)
			}

			if circle != tt.wantCircle {
				t.Errorf("expected circle %v, got %v", tt.wantCircle, circle)
			}
		})
	}
}
