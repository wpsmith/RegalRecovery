// internal/domain/threecircles/starterpack.go
package threecircles

import (
	"errors"
	"strings"
)

// Sentinel errors for starter packs.
var (
	ErrStarterPackNotFound     = errors.New("starter pack not found")
	ErrInsufficientInnerItems  = errors.New("starter pack inner circle must have 3-5 items")
	ErrInsufficientMiddleItems = errors.New("starter pack middle circle must have 6-10 items")
	ErrMiddleCategorySpan      = errors.New("starter pack middle circle must span behavioral, emotional, environmental, and lifestyle categories")
	ErrMissingReviewers        = errors.New("starter pack must have both clinical and community reviewers")
	ErrInvalidVariant          = errors.New("invalid starter pack variant")
	ErrInvalidApplicationMode  = errors.New("invalid application mode")
)

// StarterPackVariant represents content variants for different audiences.
type StarterPackVariant string

const (
	VariantSecular        StarterPackVariant = "secular"
	VariantFaithBased     StarterPackVariant = "faithBased"
	VariantLGBTQAffirming StarterPackVariant = "lgbtqAffirming"
)

// IsValid returns true if the variant is recognized.
func (v StarterPackVariant) IsValid() bool {
	return v == VariantSecular || v == VariantFaithBased || v == VariantLGBTQAffirming
}

// ApplicationMode determines how a starter pack is applied to a circle set.
type ApplicationMode string

const (
	ApplicationModeReplace ApplicationMode = "replace" // Clear existing items, populate with pack
	ApplicationModeMerge   ApplicationMode = "merge"   // Add pack items, skip duplicates (default)
)

// IsValid returns true if the application mode is recognized.
func (a ApplicationMode) IsValid() bool {
	return a == ApplicationModeReplace || a == ApplicationModeMerge
}

// StarterPackItem represents a single behavior in a starter pack.
type StarterPackItem struct {
	BehaviorName string `json:"behaviorName"`
	Rationale    string `json:"rationale"`
	Category     string `json:"category"` // Behavioral, emotional, environmental, lifestyle, etc.
}

// StarterPack represents a curated set of behaviors for a specific recovery area.
// Each pack must be reviewed by both a clinical (CSAT) and community reviewer.
type StarterPack struct {
	ID                string             `json:"packId"`
	Name              string             `json:"name"`
	Description       string             `json:"description"`
	RecoveryArea      RecoveryArea       `json:"recoveryArea"`
	Variant           StarterPackVariant `json:"variant"`
	InnerCircle       []StarterPackItem  `json:"innerCircle"`
	MiddleCircle      []StarterPackItem  `json:"middleCircle"`
	OuterCircle       []StarterPackItem  `json:"outerCircle"`
	ClinicalReviewer  string             `json:"clinicalReviewer"`  // CSAT name
	CommunityReviewer string             `json:"communityReviewer"` // Recovery community member name
	Version           int                `json:"version"`
	IsActive          bool               `json:"isActive"`
}

// ApplyCircleSet represents a simplified circle set for application logic.
// We use a separate type from the full CircleSet to avoid circular dependencies
// and keep application logic focused.
type ApplyCircleSet struct {
	InnerCircle  []CircleItem `json:"innerCircle"`
	MiddleCircle []CircleItem `json:"middleCircle"`
	OuterCircle  []CircleItem `json:"outerCircle"`
}

// ApplicationResult holds the result of applying a starter pack.
type ApplicationResult struct {
	InnerCircle   []CircleItem `json:"innerCircle"`
	MiddleCircle  []CircleItem `json:"middleCircle"`
	OuterCircle   []CircleItem `json:"outerCircle"`
	ItemsAdded    int          `json:"itemsAdded"`
	ItemsSkipped  int          `json:"itemsSkipped"`
	ItemsReplaced int          `json:"itemsReplaced"`
}

// ValidateStarterPack validates a starter pack according to the requirements:
// - Inner circle: 3-5 items
// - Middle circle: 6-10 items spanning behavioral, emotional, environmental, lifestyle categories
// - Outer circle: SEEDS categories represented
// - Both clinical and community reviewers required
func ValidateStarterPack(pack StarterPack) error {
	// Check reviewers
	if strings.TrimSpace(pack.ClinicalReviewer) == "" || strings.TrimSpace(pack.CommunityReviewer) == "" {
		return ErrMissingReviewers
	}

	// Validate inner circle count
	innerCount := len(pack.InnerCircle)
	if innerCount < 3 || innerCount > 5 {
		return ErrInsufficientInnerItems
	}

	// Validate middle circle count
	middleCount := len(pack.MiddleCircle)
	if middleCount < 6 || middleCount > 10 {
		return ErrInsufficientMiddleItems
	}

	// Validate middle circle category span
	if !hasRequiredCategorySpan(pack.MiddleCircle) {
		return ErrMiddleCategorySpan
	}

	// Note: SEEDS validation for outer circle could be added here
	// For now, we assume outer circle is validated during content creation

	return nil
}

// hasRequiredCategorySpan checks if middle circle items span the required categories.
// Required: behavioral, emotional, environmental, lifestyle.
func hasRequiredCategorySpan(items []StarterPackItem) bool {
	categories := make(map[string]bool)
	for _, item := range items {
		normalized := strings.ToLower(strings.TrimSpace(item.Category))
		categories[normalized] = true
	}

	required := []string{"behavioral", "emotional", "environmental", "lifestyle"}
	for _, req := range required {
		if !categories[req] {
			return false
		}
	}

	return true
}

// ApplyStarterPack applies a starter pack to a circle set using the specified mode.
// - Replace mode: clears existing items and populates with pack items
// - Merge mode: adds pack items, skipping duplicates (case-insensitive behaviorName match)
// All applied items are tagged with source=starterPack.
func ApplyStarterPack(pack StarterPack, set ApplyCircleSet, mode ApplicationMode) (ApplicationResult, error) {
	// Validate the starter pack first
	if err := ValidateStarterPack(pack); err != nil {
		return ApplicationResult{}, err
	}

	if !mode.IsValid() {
		return ApplicationResult{}, ErrInvalidApplicationMode
	}

	result := ApplicationResult{}

	if mode == ApplicationModeReplace {
		// Replace mode: clear and populate
		result.InnerCircle = convertItemsFromPack(pack.InnerCircle)
		result.MiddleCircle = convertItemsFromPack(pack.MiddleCircle)
		result.OuterCircle = convertItemsFromPack(pack.OuterCircle)
		result.ItemsReplaced = len(result.InnerCircle) + len(result.MiddleCircle) + len(result.OuterCircle)
	} else {
		// Merge mode: add pack items, skip duplicates
		innerAdded, innerSkipped := 0, 0
		result.InnerCircle, innerAdded, innerSkipped = mergeItems(set.InnerCircle, pack.InnerCircle)
		middleAdded, middleSkipped := 0, 0
		result.MiddleCircle, middleAdded, middleSkipped = mergeItems(set.MiddleCircle, pack.MiddleCircle)
		outerAdded, outerSkipped := 0, 0
		result.OuterCircle, outerAdded, outerSkipped = mergeItems(set.OuterCircle, pack.OuterCircle)

		result.ItemsAdded = innerAdded + middleAdded + outerAdded
		result.ItemsSkipped = innerSkipped + middleSkipped + outerSkipped
	}

	return result, nil
}

// convertItemsFromPack converts starter pack items to circle items.
func convertItemsFromPack(packItems []StarterPackItem) []CircleItem {
	items := make([]CircleItem, len(packItems))
	for i, packItem := range packItems {
		items[i] = CircleItem{
			ItemID:       "", // Will be generated by repository layer
			BehaviorName: packItem.BehaviorName,
			Notes:        packItem.Rationale,
			Category:     packItem.Category,
			Source:       SourceStarterPack,
			Uncertain:    false,
		}
	}
	return items
}

// mergeItems merges pack items into existing items, skipping duplicates.
// Duplicate detection is case-insensitive behaviorName matching.
func mergeItems(existing []CircleItem, packItems []StarterPackItem) ([]CircleItem, int, int) {
	result := make([]CircleItem, len(existing))
	copy(result, existing)

	added := 0
	skipped := 0

	for _, packItem := range packItems {
		if isDuplicate(result, packItem.BehaviorName) {
			skipped++
			continue
		}

		// Add the item
		result = append(result, CircleItem{
			ItemID:       "", // Will be generated by repository layer
			BehaviorName: packItem.BehaviorName,
			Notes:        packItem.Rationale,
			Category:     packItem.Category,
			Source:       SourceStarterPack,
			Uncertain:    false,
		})
		added++
	}

	return result, added, skipped
}

// isDuplicate checks if a behavior name already exists (case-insensitive).
func isDuplicate(items []CircleItem, behaviorName string) bool {
	normalized := strings.ToLower(strings.TrimSpace(behaviorName))
	for _, item := range items {
		if strings.ToLower(strings.TrimSpace(item.BehaviorName)) == normalized {
			return true
		}
	}
	return false
}

// FilterStarterPacksRequest represents filter criteria for starter packs.
type FilterStarterPacksRequest struct {
	RecoveryArea RecoveryArea        `json:"recoveryArea"`
	Variant      *StarterPackVariant `json:"variant,omitempty"` // Filter by variant if specified
}

// FilterStarterPacks filters a slice of starter packs based on the given criteria.
func FilterStarterPacks(packs []StarterPack, req FilterStarterPacksRequest) []StarterPack {
	result := make([]StarterPack, 0)

	for _, p := range packs {
		// Skip inactive packs
		if !p.IsActive {
			continue
		}

		// Recovery area must match
		if p.RecoveryArea != req.RecoveryArea {
			continue
		}

		// Variant filter (if specified)
		if req.Variant != nil && p.Variant != *req.Variant {
			continue
		}

		result = append(result, p)
	}

	return result
}
