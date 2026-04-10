// internal/domain/threecircles/item.go
package threecircles

import (
	"strings"
	"time"
)

// NewCircleItem creates a new circle item with validation.
func NewCircleItem(itemID string, req CreateCircleItemRequest) (*CircleItem, error) {
	// Validate circle type.
	if !req.Circle.IsValid() {
		return nil, ErrInvalidCircleType
	}

	// Validate behavior name.
	behaviorName := strings.TrimSpace(req.BehaviorName)
	if behaviorName == "" {
		return nil, ErrBehaviorNameEmpty
	}
	if len(behaviorName) > 200 {
		return nil, ErrBehaviorNameTooLong
	}

	// Validate notes length.
	if len(req.Notes) > 1000 {
		return nil, ErrNotesTooLong
	}

	// Validate specificity detail length.
	if len(req.SpecificityDetail) > 500 {
		return nil, ErrSpecificityDetailTooLong
	}

	// Validate category length.
	if len(req.Category) > 50 {
		return nil, ErrCategoryTooLong
	}

	// Validate source.
	if !req.Source.IsValid() {
		return nil, ErrInvalidSource
	}

	now := time.Now().UTC()
	item := &CircleItem{
		ItemID:            itemID,
		BehaviorName:      behaviorName,
		Notes:             strings.TrimSpace(req.Notes),
		SpecificityDetail: strings.TrimSpace(req.SpecificityDetail),
		Category:          strings.TrimSpace(req.Category),
		Source:            req.Source,
		SourceTemplateID:  strings.TrimSpace(req.SourceTemplateID),
		Uncertain:         req.Uncertain,
		SortOrder:         0, // Will be set by AddItem
		CreatedAt:         now,
		ModifiedAt:        now,
	}

	return item, nil
}

// UpdateItem updates an existing circle item with validation.
func (ci *CircleItem) UpdateItem(req UpdateCircleItemRequest) error {
	// Update behavior name if provided.
	if req.BehaviorName != "" {
		behaviorName := strings.TrimSpace(req.BehaviorName)
		if behaviorName == "" {
			return ErrBehaviorNameEmpty
		}
		if len(behaviorName) > 200 {
			return ErrBehaviorNameTooLong
		}
		ci.BehaviorName = behaviorName
	}

	// Update notes if provided (even if empty, to allow clearing).
	if len(req.Notes) > 1000 {
		return ErrNotesTooLong
	}
	ci.Notes = strings.TrimSpace(req.Notes)

	// Update specificity detail if provided.
	if len(req.SpecificityDetail) > 500 {
		return ErrSpecificityDetailTooLong
	}
	ci.SpecificityDetail = strings.TrimSpace(req.SpecificityDetail)

	// Update category if provided.
	if len(req.Category) > 50 {
		return ErrCategoryTooLong
	}
	ci.Category = strings.TrimSpace(req.Category)

	// Update uncertain flag if provided.
	if req.Uncertain != nil {
		ci.Uncertain = *req.Uncertain
	}

	ci.ModifiedAt = time.Now().UTC()
	return nil
}

// AddItem adds a new item to the specified circle with capacity validation.
func (cs *CircleSet) AddItem(circleType CircleType, item *CircleItem) error {
	// Validate capacity before adding.
	switch circleType {
	case CircleTypeInner:
		if len(cs.InnerCircle) >= 20 {
			return ErrInnerCircleFull
		}
		item.SortOrder = len(cs.InnerCircle)
		cs.InnerCircle = append(cs.InnerCircle, *item)
	case CircleTypeMiddle:
		if len(cs.MiddleCircle) >= 50 {
			return ErrMiddleCircleFull
		}
		item.SortOrder = len(cs.MiddleCircle)
		cs.MiddleCircle = append(cs.MiddleCircle, *item)
	case CircleTypeOuter:
		if len(cs.OuterCircle) >= 50 {
			return ErrOuterCircleFull
		}
		item.SortOrder = len(cs.OuterCircle)
		cs.OuterCircle = append(cs.OuterCircle, *item)
	default:
		return ErrInvalidCircleType
	}

	cs.ModifiedAt = time.Now().UTC()
	return nil
}

// UpdateItemInCircle updates an existing item within a circle set.
func (cs *CircleSet) UpdateItemInCircle(itemID string, req UpdateCircleItemRequest) (*CircleItem, error) {
	// Search in inner circle.
	for i := range cs.InnerCircle {
		if cs.InnerCircle[i].ItemID == itemID {
			if err := cs.InnerCircle[i].UpdateItem(req); err != nil {
				return nil, err
			}
			cs.ModifiedAt = time.Now().UTC()
			return &cs.InnerCircle[i], nil
		}
	}

	// Search in middle circle.
	for i := range cs.MiddleCircle {
		if cs.MiddleCircle[i].ItemID == itemID {
			if err := cs.MiddleCircle[i].UpdateItem(req); err != nil {
				return nil, err
			}
			cs.ModifiedAt = time.Now().UTC()
			return &cs.MiddleCircle[i], nil
		}
	}

	// Search in outer circle.
	for i := range cs.OuterCircle {
		if cs.OuterCircle[i].ItemID == itemID {
			if err := cs.OuterCircle[i].UpdateItem(req); err != nil {
				return nil, err
			}
			cs.ModifiedAt = time.Now().UTC()
			return &cs.OuterCircle[i], nil
		}
	}

	return nil, ErrItemNotFound
}

// DeleteItem removes an item from the circle set by item ID.
func (cs *CircleSet) DeleteItem(itemID string) error {
	// Try to delete from inner circle.
	for i, item := range cs.InnerCircle {
		if item.ItemID == itemID {
			cs.InnerCircle = append(cs.InnerCircle[:i], cs.InnerCircle[i+1:]...)
			cs.reorderCircle(CircleTypeInner)
			cs.ModifiedAt = time.Now().UTC()
			return nil
		}
	}

	// Try to delete from middle circle.
	for i, item := range cs.MiddleCircle {
		if item.ItemID == itemID {
			cs.MiddleCircle = append(cs.MiddleCircle[:i], cs.MiddleCircle[i+1:]...)
			cs.reorderCircle(CircleTypeMiddle)
			cs.ModifiedAt = time.Now().UTC()
			return nil
		}
	}

	// Try to delete from outer circle.
	for i, item := range cs.OuterCircle {
		if item.ItemID == itemID {
			cs.OuterCircle = append(cs.OuterCircle[:i], cs.OuterCircle[i+1:]...)
			cs.reorderCircle(CircleTypeOuter)
			cs.ModifiedAt = time.Now().UTC()
			return nil
		}
	}

	return ErrItemNotFound
}

// MoveItem moves an item from one circle to another.
func (cs *CircleSet) MoveItem(itemID string, targetCircle CircleType) (CircleType, error) {
	// Validate target circle.
	if !targetCircle.IsValid() {
		return "", ErrInvalidCircleType
	}

	// Find the item and its current circle.
	var sourceCircle CircleType
	var itemToMove *CircleItem

	// Search in inner circle.
	for i := range cs.InnerCircle {
		if cs.InnerCircle[i].ItemID == itemID {
			sourceCircle = CircleTypeInner
			itemToMove = &cs.InnerCircle[i]
			break
		}
	}

	// Search in middle circle if not found.
	if itemToMove == nil {
		for i := range cs.MiddleCircle {
			if cs.MiddleCircle[i].ItemID == itemID {
				sourceCircle = CircleTypeMiddle
				itemToMove = &cs.MiddleCircle[i]
				break
			}
		}
	}

	// Search in outer circle if not found.
	if itemToMove == nil {
		for i := range cs.OuterCircle {
			if cs.OuterCircle[i].ItemID == itemID {
				sourceCircle = CircleTypeOuter
				itemToMove = &cs.OuterCircle[i]
				break
			}
		}
	}

	if itemToMove == nil {
		return "", ErrItemNotFound
	}

	// Check if already in target circle.
	if sourceCircle == targetCircle {
		return sourceCircle, ErrSameCircleMove
	}

	// Validate target circle capacity.
	switch targetCircle {
	case CircleTypeInner:
		if len(cs.InnerCircle) >= 20 {
			return sourceCircle, ErrInnerCircleFull
		}
	case CircleTypeMiddle:
		if len(cs.MiddleCircle) >= 50 {
			return sourceCircle, ErrMiddleCircleFull
		}
	case CircleTypeOuter:
		if len(cs.OuterCircle) >= 50 {
			return sourceCircle, ErrOuterCircleFull
		}
	}

	// Create a copy of the item with updated modification time.
	movedItem := *itemToMove
	movedItem.ModifiedAt = time.Now().UTC()

	// Delete from source circle.
	if err := cs.DeleteItem(itemID); err != nil {
		return sourceCircle, err
	}

	// Add to target circle.
	if err := cs.AddItem(targetCircle, &movedItem); err != nil {
		return sourceCircle, err
	}

	return sourceCircle, nil
}

// FindItem finds an item by ID and returns it along with its circle type.
func (cs *CircleSet) FindItem(itemID string) (*CircleItem, CircleType, error) {
	// Search in inner circle.
	for i := range cs.InnerCircle {
		if cs.InnerCircle[i].ItemID == itemID {
			return &cs.InnerCircle[i], CircleTypeInner, nil
		}
	}

	// Search in middle circle.
	for i := range cs.MiddleCircle {
		if cs.MiddleCircle[i].ItemID == itemID {
			return &cs.MiddleCircle[i], CircleTypeMiddle, nil
		}
	}

	// Search in outer circle.
	for i := range cs.OuterCircle {
		if cs.OuterCircle[i].ItemID == itemID {
			return &cs.OuterCircle[i], CircleTypeOuter, nil
		}
	}

	return nil, "", ErrItemNotFound
}

// reorderCircle resets the SortOrder for items in a specific circle after deletion.
func (cs *CircleSet) reorderCircle(circleType CircleType) {
	switch circleType {
	case CircleTypeInner:
		for i := range cs.InnerCircle {
			cs.InnerCircle[i].SortOrder = i
		}
	case CircleTypeMiddle:
		for i := range cs.MiddleCircle {
			cs.MiddleCircle[i].SortOrder = i
		}
	case CircleTypeOuter:
		for i := range cs.OuterCircle {
			cs.OuterCircle[i].SortOrder = i
		}
	}
}
