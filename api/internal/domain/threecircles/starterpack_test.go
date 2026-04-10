// internal/domain/threecircles/starterpack_test.go
package threecircles

import (
	"testing"
)

// TestStarterPack_TC_SP_001_ValidateInnerCircleCount verifies that
// starter packs must have 3-5 items in the inner circle.
//
// Acceptance Criterion TC-SP-001: Inner circle must have 3-5 items.
func TestStarterPack_TC_SP_001_ValidateInnerCircleCount(t *testing.T) {
	tests := []struct {
		name        string
		innerCount  int
		shouldError bool
	}{
		{"Too few (2)", 2, true},
		{"Valid (3)", 3, false},
		{"Valid (4)", 4, false},
		{"Valid (5)", 5, false},
		{"Too many (6)", 6, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Given - Starter pack with specific inner circle count
			pack := createValidStarterPack()
			pack.InnerCircle = make([]StarterPackItem, tt.innerCount)
			for i := 0; i < tt.innerCount; i++ {
				pack.InnerCircle[i] = StarterPackItem{
					BehaviorName: "Test behavior",
					Category:     "behavioral",
				}
			}

			// When - Validating the pack
			err := ValidateStarterPack(pack)

			// Then - Error matches expectation
			if tt.shouldError && err == nil {
				t.Errorf("expected error for %d inner circle items, got none", tt.innerCount)
			}
			if !tt.shouldError && err != nil {
				t.Errorf("expected no error for %d inner circle items, got: %v", tt.innerCount, err)
			}
		})
	}
}

// TestStarterPack_TC_SP_002_ValidateMiddleCircleCount verifies that
// starter packs must have 6-10 items in the middle circle.
//
// Acceptance Criterion TC-SP-002: Middle circle must have 6-10 items.
func TestStarterPack_TC_SP_002_ValidateMiddleCircleCount(t *testing.T) {
	tests := []struct {
		name        string
		middleCount int
		shouldError bool
	}{
		{"Too few (5)", 5, true},
		{"Valid (6)", 6, false},
		{"Valid (8)", 8, false},
		{"Valid (10)", 10, false},
		{"Too many (11)", 11, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Given - Starter pack with specific middle circle count
			pack := createValidStarterPack()
			pack.MiddleCircle = createMiddleCircleItems(tt.middleCount)

			// When - Validating the pack
			err := ValidateStarterPack(pack)

			// Then - Error matches expectation
			if tt.shouldError && err == nil {
				t.Errorf("expected error for %d middle circle items, got none", tt.middleCount)
			}
			if !tt.shouldError && err != nil {
				t.Errorf("expected no error for %d middle circle items, got: %v", tt.middleCount, err)
			}
		})
	}
}

// TestStarterPack_TC_SP_003_ValidateMiddleCategorySpan verifies that
// middle circle items must span required categories.
//
// Acceptance Criterion TC-SP-003: Middle circle must span behavioral, emotional, environmental, lifestyle.
func TestStarterPack_TC_SP_003_ValidateMiddleCategorySpan(t *testing.T) {
	// Given - Starter pack with all required categories
	pack := createValidStarterPack()

	// When - Validating the pack
	err := ValidateStarterPack(pack)

	// Then - No error
	if err != nil {
		t.Errorf("expected no error for valid category span, got: %v", err)
	}

	// Given - Pack missing a required category
	packMissing := createValidStarterPack()
	packMissing.MiddleCircle = []StarterPackItem{
		{BehaviorName: "B1", Category: "behavioral"},
		{BehaviorName: "B2", Category: "behavioral"},
		{BehaviorName: "E1", Category: "emotional"},
		{BehaviorName: "E2", Category: "emotional"},
		{BehaviorName: "Env1", Category: "environmental"},
		{BehaviorName: "Env2", Category: "environmental"},
		// Missing "lifestyle" category
	}

	// When - Validating the pack
	err = ValidateStarterPack(packMissing)

	// Then - Error
	if err != ErrMiddleCategorySpan {
		t.Errorf("expected ErrMiddleCategorySpan, got: %v", err)
	}
}

// TestStarterPack_TC_SP_004_ValidateReviewersRequired verifies that
// both clinical and community reviewers are required.
//
// Acceptance Criterion TC-SP-004: Both reviewers required.
func TestStarterPack_TC_SP_004_ValidateReviewersRequired(t *testing.T) {
	tests := []struct {
		name              string
		clinicalReviewer  string
		communityReviewer string
		shouldError       bool
	}{
		{"Both present", "Dr. Smith", "John Doe", false},
		{"Missing clinical", "", "John Doe", true},
		{"Missing community", "Dr. Smith", "", true},
		{"Both missing", "", "", true},
		{"Clinical whitespace only", "   ", "John Doe", true},
		{"Community whitespace only", "Dr. Smith", "   ", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Given - Starter pack with specific reviewers
			pack := createValidStarterPack()
			pack.ClinicalReviewer = tt.clinicalReviewer
			pack.CommunityReviewer = tt.communityReviewer

			// When - Validating the pack
			err := ValidateStarterPack(pack)

			// Then - Error matches expectation
			if tt.shouldError && err != ErrMissingReviewers {
				t.Errorf("expected ErrMissingReviewers, got: %v", err)
			}
			if !tt.shouldError && err != nil {
				t.Errorf("expected no error, got: %v", err)
			}
		})
	}
}

// TestStarterPack_TC_SP_005_ApplyMergeMode verifies that merge mode
// adds pack items without replacing existing items.
//
// Acceptance Criterion TC-SP-005: Merge mode adds items, preserves existing.
func TestStarterPack_TC_SP_005_ApplyMergeMode(t *testing.T) {
	// Given - Existing circle set with items
	existingSet := ApplyCircleSet{
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Existing inner", Source: SourceUser},
		},
		MiddleCircle: []CircleItem{
			{ItemID: "m1", BehaviorName: "Existing middle", Source: SourceUser},
		},
		OuterCircle: []CircleItem{
			{ItemID: "o1", BehaviorName: "Existing outer", Source: SourceUser},
		},
	}

	// And - Valid starter pack
	pack := createValidStarterPack()

	// When - Applying pack in merge mode
	result, err := ApplyStarterPack(pack, existingSet, ApplicationModeMerge)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - Existing items preserved
	if len(result.InnerCircle) < 1 {
		t.Errorf("expected existing inner circle item to be preserved")
	}
	if result.InnerCircle[0].BehaviorName != "Existing inner" {
		t.Errorf("expected existing inner item preserved, got: %s", result.InnerCircle[0].BehaviorName)
	}

	// Then - Pack items added
	if len(result.InnerCircle) <= len(existingSet.InnerCircle) {
		t.Errorf("expected pack items to be added to inner circle")
	}

	// Then - New items tagged with starterPack source
	foundStarterPackItem := false
	for _, item := range result.InnerCircle {
		if item.Source == SourceStarterPack {
			foundStarterPackItem = true
			break
		}
	}
	if !foundStarterPackItem {
		t.Errorf("expected at least one item tagged with starterPack source")
	}
}

// TestStarterPack_TC_SP_006_ApplyReplaceMode verifies that replace mode
// clears existing items and populates with pack items.
//
// Acceptance Criterion TC-SP-006: Replace mode clears and populates.
func TestStarterPack_TC_SP_006_ApplyReplaceMode(t *testing.T) {
	// Given - Existing circle set with items
	existingSet := ApplyCircleSet{
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Existing inner", Source: SourceUser},
			{ItemID: "i2", BehaviorName: "Another inner", Source: SourceUser},
		},
		MiddleCircle: []CircleItem{
			{ItemID: "m1", BehaviorName: "Existing middle", Source: SourceUser},
		},
		OuterCircle: []CircleItem{
			{ItemID: "o1", BehaviorName: "Existing outer", Source: SourceUser},
		},
	}

	// And - Valid starter pack
	pack := createValidStarterPack()

	// When - Applying pack in replace mode
	result, err := ApplyStarterPack(pack, existingSet, ApplicationModeReplace)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - Existing items cleared
	for _, item := range result.InnerCircle {
		if item.Source == SourceUser {
			t.Errorf("expected all user items to be cleared, found: %s", item.BehaviorName)
		}
	}

	// Then - All items from pack
	if len(result.InnerCircle) != len(pack.InnerCircle) {
		t.Errorf("expected %d inner circle items, got %d", len(pack.InnerCircle), len(result.InnerCircle))
	}

	// Then - All items tagged with starterPack source
	for _, item := range result.InnerCircle {
		if item.Source != SourceStarterPack {
			t.Errorf("expected starterPack source, got: %s", item.Source)
		}
	}
}

// TestStarterPack_TC_SP_007_DuplicateDetection verifies that merge mode
// skips duplicate behavior names (case-insensitive).
//
// Acceptance Criterion TC-SP-007: Duplicates detected case-insensitively.
func TestStarterPack_TC_SP_007_DuplicateDetection(t *testing.T) {
	// Given - Existing set with a behavior (only in inner circle, empty middle/outer)
	existingSet := ApplyCircleSet{
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Viewing Pornography", Source: SourceUser},
		},
		MiddleCircle: []CircleItem{},
		OuterCircle:  []CircleItem{},
	}

	// And - Valid starter pack with duplicate in inner circle
	pack := createValidStarterPack()
	pack.InnerCircle = []StarterPackItem{
		{BehaviorName: "viewing pornography", Rationale: "Test", Category: "behavioral"}, // Duplicate
		{BehaviorName: "VIEWING PORNOGRAPHY", Rationale: "Test", Category: "behavioral"}, // Duplicate
		{BehaviorName: "Masturbation", Rationale: "Test", Category: "behavioral"},        // New
	}
	// Pack has valid middle and outer circles from createValidStarterPack()

	// When - Applying pack in merge mode
	result, err := ApplyStarterPack(pack, existingSet, ApplicationModeMerge)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - Duplicates skipped across all circles
	// Inner: 2 duplicates, 1 added
	// Middle: 0 duplicates (empty existing), all added
	// Outer: 0 duplicates (empty existing), all added
	middleCount := len(pack.MiddleCircle)
	outerCount := len(pack.OuterCircle)
	expectedSkipped := 2 // Only from inner circle
	expectedAdded := 1 + middleCount + outerCount

	if result.ItemsSkipped != expectedSkipped {
		t.Errorf("expected %d items skipped, got %d", expectedSkipped, result.ItemsSkipped)
	}
	if result.ItemsAdded != expectedAdded {
		t.Errorf("expected %d items added (1 inner + %d middle + %d outer), got %d",
			expectedAdded, middleCount, outerCount, result.ItemsAdded)
	}

	// Then - Only unique items in result
	if len(result.InnerCircle) != 2 {
		t.Errorf("expected 2 unique inner circle items, got %d", len(result.InnerCircle))
	}
}

// TestStarterPack_TC_SP_008_ItemSourceTagging verifies that all
// applied items are tagged with source=starterPack.
//
// Acceptance Criterion TC-SP-008: Applied items tagged with starterPack source.
func TestStarterPack_TC_SP_008_ItemSourceTagging(t *testing.T) {
	// Given - Empty circle set
	emptySet := ApplyCircleSet{}

	// And - Valid starter pack
	pack := createValidStarterPack()

	// When - Applying pack
	result, err := ApplyStarterPack(pack, emptySet, ApplicationModeMerge)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - All items tagged with starterPack source
	allItems := append(result.InnerCircle, result.MiddleCircle...)
	allItems = append(allItems, result.OuterCircle...)

	for _, item := range allItems {
		if item.Source != SourceStarterPack {
			t.Errorf("expected starterPack source for item %s, got: %s", item.BehaviorName, item.Source)
		}
	}
}

// TestStarterPack_TC_SP_009_InvalidPackRejected verifies that
// invalid starter packs are rejected during application.
//
// Acceptance Criterion TC-SP-009: Invalid packs rejected.
func TestStarterPack_TC_SP_009_InvalidPackRejected(t *testing.T) {
	// Given - Invalid starter pack (too few inner circle items)
	pack := createValidStarterPack()
	pack.InnerCircle = []StarterPackItem{
		{BehaviorName: "Only one", Category: "behavioral"},
	}

	// And - Empty circle set
	emptySet := ApplyCircleSet{}

	// When - Attempting to apply pack
	_, err := ApplyStarterPack(pack, emptySet, ApplicationModeMerge)

	// Then - Error returned
	if err == nil {
		t.Errorf("expected error for invalid pack, got none")
	}
}

// TestStarterPack_TC_SP_010_FilterByRecoveryArea verifies that
// starter packs can be filtered by recovery area.
//
// Acceptance Criterion TC-SP-010: Filter by recovery area.
func TestStarterPack_TC_SP_010_FilterByRecoveryArea(t *testing.T) {
	// Given - Starter packs for multiple recovery areas
	packs := []StarterPack{
		createStarterPackForArea(RecoveryAreaSexPornography, VariantSecular),
		createStarterPackForArea(RecoveryAreaAlcohol, VariantSecular),
		createStarterPackForArea(RecoveryAreaSexPornography, VariantFaithBased),
	}

	// When - Filtering by porn recovery area
	req := FilterStarterPacksRequest{
		RecoveryArea: RecoveryAreaSexPornography,
	}
	result := FilterStarterPacks(packs, req)

	// Then - Only porn packs returned
	if len(result) != 2 {
		t.Errorf("expected 2 porn packs, got %d", len(result))
	}
	for _, pack := range result {
		if pack.RecoveryArea != RecoveryAreaSexPornography {
			t.Errorf("expected porn recovery area, got %s", pack.RecoveryArea)
		}
	}
}

// TestStarterPack_TC_SP_011_FilterByVariant verifies that
// starter packs can be filtered by variant.
//
// Acceptance Criterion TC-SP-011: Filter by variant.
func TestStarterPack_TC_SP_011_FilterByVariant(t *testing.T) {
	// Given - Starter packs with different variants
	packs := []StarterPack{
		createStarterPackForAreaAndVariant(RecoveryAreaSexPornography, VariantSecular),
		createStarterPackForAreaAndVariant(RecoveryAreaSexPornography, VariantFaithBased),
		createStarterPackForAreaAndVariant(RecoveryAreaSexPornography, VariantLGBTQAffirming),
	}

	// When - Filtering by faith-based variant
	variant := VariantFaithBased
	req := FilterStarterPacksRequest{
		RecoveryArea: RecoveryAreaSexPornography,
		Variant:      &variant,
	}
	result := FilterStarterPacks(packs, req)

	// Then - Only faith-based pack returned
	if len(result) != 1 {
		t.Errorf("expected 1 faith-based pack, got %d", len(result))
	}
	if result[0].Variant != VariantFaithBased {
		t.Errorf("expected faith-based variant, got %s", result[0].Variant)
	}
}

// TestStarterPack_TC_SP_012_InactivePacksExcluded verifies that
// inactive packs are excluded from filter results.
//
// Acceptance Criterion TC-SP-012: Inactive packs excluded.
func TestStarterPack_TC_SP_012_InactivePacksExcluded(t *testing.T) {
	// Given - Mix of active and inactive packs
	packs := []StarterPack{
		createStarterPackForArea(RecoveryAreaSexPornography, VariantSecular),
	}
	packs[0].IsActive = true
	inactivePack := createStarterPackForArea(RecoveryAreaSexPornography, VariantSecular)
	inactivePack.IsActive = false
	packs = append(packs, inactivePack)

	// When - Filtering
	req := FilterStarterPacksRequest{
		RecoveryArea: RecoveryAreaSexPornography,
	}
	result := FilterStarterPacks(packs, req)

	// Then - Only active pack returned
	if len(result) != 1 {
		t.Errorf("expected 1 active pack, got %d", len(result))
	}
	if !result[0].IsActive {
		t.Errorf("expected active pack, got inactive")
	}
}

// TestStarterPack_TC_SP_013_VariantValidation verifies that
// starter pack variant enum has valid values.
//
// Acceptance Criterion TC-SP-013: Variant validation works.
func TestStarterPack_TC_SP_013_VariantValidation(t *testing.T) {
	// Given/When/Then - Valid variants
	validVariants := []StarterPackVariant{VariantSecular, VariantFaithBased, VariantLGBTQAffirming}

	for _, variant := range validVariants {
		if !variant.IsValid() {
			t.Errorf("expected %s to be valid", variant)
		}
	}

	// Invalid variant
	invalid := StarterPackVariant("invalid")
	if invalid.IsValid() {
		t.Errorf("expected invalid variant to be invalid")
	}
}

// TestStarterPack_TC_SP_014_ApplicationModeValidation verifies that
// application mode enum has valid values.
//
// Acceptance Criterion TC-SP-014: Application mode validation works.
func TestStarterPack_TC_SP_014_ApplicationModeValidation(t *testing.T) {
	// Given/When/Then - Valid modes
	validModes := []ApplicationMode{ApplicationModeMerge, ApplicationModeReplace}

	for _, mode := range validModes {
		if !mode.IsValid() {
			t.Errorf("expected %s to be valid", mode)
		}
	}

	// Invalid mode
	invalid := ApplicationMode("invalid")
	if invalid.IsValid() {
		t.Errorf("expected invalid mode to be invalid")
	}
}

// TestStarterPack_TC_SP_015_RationalePreserved verifies that
// rationale from pack items is preserved in notes field.
//
// Acceptance Criterion TC-SP-015: Rationale copied to notes.
func TestStarterPack_TC_SP_015_RationalePreserved(t *testing.T) {
	// Given - Starter pack with rationale
	pack := createValidStarterPack()
	pack.InnerCircle[0].Rationale = "This is the rationale for this behavior"

	// And - Empty circle set
	emptySet := ApplyCircleSet{}

	// When - Applying pack
	result, err := ApplyStarterPack(pack, emptySet, ApplicationModeMerge)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - Rationale preserved in notes
	if result.InnerCircle[0].Notes != pack.InnerCircle[0].Rationale {
		t.Errorf("expected rationale in notes, got: %s", result.InnerCircle[0].Notes)
	}
}

// TestStarterPack_TC_SP_016_CategoryPreserved verifies that
// category from pack items is preserved.
//
// Acceptance Criterion TC-SP-016: Category preserved.
func TestStarterPack_TC_SP_016_CategoryPreserved(t *testing.T) {
	// Given - Starter pack with categories
	pack := createValidStarterPack()
	expectedCategory := "behavioral"
	pack.InnerCircle[0].Category = expectedCategory

	// And - Empty circle set
	emptySet := ApplyCircleSet{}

	// When - Applying pack
	result, err := ApplyStarterPack(pack, emptySet, ApplicationModeMerge)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - Category preserved
	if result.InnerCircle[0].Category != expectedCategory {
		t.Errorf("expected category %s, got: %s", expectedCategory, result.InnerCircle[0].Category)
	}
}

// TestStarterPack_TC_SP_017_ApplicationMetrics verifies that
// application result includes correct metrics.
//
// Acceptance Criterion TC-SP-017: Application metrics accurate.
func TestStarterPack_TC_SP_017_ApplicationMetrics(t *testing.T) {
	// Given - Existing set with one duplicate item
	existingSet := ApplyCircleSet{
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Duplicate Behavior", Source: SourceUser},
		},
	}

	// And - Starter pack with duplicate and new items
	pack := createValidStarterPack()
	pack.InnerCircle = []StarterPackItem{
		{BehaviorName: "Duplicate Behavior", Category: "behavioral"},
		{BehaviorName: "New Behavior 1", Category: "behavioral"},
		{BehaviorName: "New Behavior 2", Category: "behavioral"},
	}

	// When - Applying pack in merge mode
	result, err := ApplyStarterPack(pack, existingSet, ApplicationModeMerge)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - Metrics correct (includes all circles)
	// Skipped: 1 from inner (Duplicate Behavior)
	// Added: 2 from inner (New Behavior 1, New Behavior 2) + 7 from middle + 2 from outer
	middleCount := len(pack.MiddleCircle)
	outerCount := len(pack.OuterCircle)
	expectedAdded := 2 + middleCount + outerCount

	if result.ItemsSkipped != 1 {
		t.Errorf("expected 1 skipped, got %d", result.ItemsSkipped)
	}
	if result.ItemsAdded != expectedAdded {
		t.Errorf("expected %d added (2 inner + %d middle + %d outer), got %d", expectedAdded, middleCount, outerCount, result.ItemsAdded)
	}
}

// TestStarterPack_TC_SP_018_ReplaceMetrics verifies that
// replace mode returns correct metrics.
//
// Acceptance Criterion TC-SP-018: Replace metrics accurate.
func TestStarterPack_TC_SP_018_ReplaceMetrics(t *testing.T) {
	// Given - Existing set
	existingSet := ApplyCircleSet{
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Old Item", Source: SourceUser},
		},
	}

	// And - Valid starter pack
	pack := createValidStarterPack()

	// When - Applying pack in replace mode
	result, err := ApplyStarterPack(pack, existingSet, ApplicationModeReplace)

	// Then - No error
	if err != nil {
		t.Fatalf("expected no error, got: %v", err)
	}

	// Then - ItemsReplaced includes all circles
	expectedReplaced := len(pack.InnerCircle) + len(pack.MiddleCircle) + len(pack.OuterCircle)
	if result.ItemsReplaced != expectedReplaced {
		t.Errorf("expected %d items replaced, got %d", expectedReplaced, result.ItemsReplaced)
	}
	if result.ItemsAdded != 0 {
		t.Errorf("expected 0 items added in replace mode, got %d", result.ItemsAdded)
	}
	if result.ItemsSkipped != 0 {
		t.Errorf("expected 0 items skipped in replace mode, got %d", result.ItemsSkipped)
	}
}

// TestStarterPack_TC_SP_019_InvalidModeRejected verifies that
// invalid application modes are rejected.
//
// Acceptance Criterion TC-SP-019: Invalid mode rejected.
func TestStarterPack_TC_SP_019_InvalidModeRejected(t *testing.T) {
	// Given - Valid pack and set
	pack := createValidStarterPack()
	emptySet := ApplyCircleSet{}

	// And - Invalid application mode
	invalidMode := ApplicationMode("invalid")

	// When - Attempting to apply with invalid mode
	_, err := ApplyStarterPack(pack, emptySet, invalidMode)

	// Then - Error returned
	if err != ErrInvalidApplicationMode {
		t.Errorf("expected ErrInvalidApplicationMode, got: %v", err)
	}
}

// Helper functions

func createValidStarterPack() StarterPack {
	return StarterPack{
		ID:           "pack1",
		Name:         "Test Pack",
		Description:  "Test description",
		RecoveryArea: RecoveryAreaSexPornography,
		Variant:      VariantSecular,
		InnerCircle: []StarterPackItem{
			{BehaviorName: "Inner 1", Rationale: "Rationale 1", Category: "behavioral"},
			{BehaviorName: "Inner 2", Rationale: "Rationale 2", Category: "behavioral"},
			{BehaviorName: "Inner 3", Rationale: "Rationale 3", Category: "behavioral"},
		},
		MiddleCircle: []StarterPackItem{
			{BehaviorName: "Middle 1", Rationale: "Rationale", Category: "behavioral"},
			{BehaviorName: "Middle 2", Rationale: "Rationale", Category: "behavioral"},
			{BehaviorName: "Middle 3", Rationale: "Rationale", Category: "emotional"},
			{BehaviorName: "Middle 4", Rationale: "Rationale", Category: "emotional"},
			{BehaviorName: "Middle 5", Rationale: "Rationale", Category: "environmental"},
			{BehaviorName: "Middle 6", Rationale: "Rationale", Category: "environmental"},
			{BehaviorName: "Middle 7", Rationale: "Rationale", Category: "lifestyle"},
		},
		OuterCircle: []StarterPackItem{
			{BehaviorName: "Outer 1", Rationale: "Rationale", Category: "spiritual"},
			{BehaviorName: "Outer 2", Rationale: "Rationale", Category: "emotional"},
		},
		ClinicalReviewer:  "Dr. Smith",
		CommunityReviewer: "John Doe",
		Version:           1,
		IsActive:          true,
	}
}

func createMiddleCircleItems(count int) []StarterPackItem {
	// Ensure we have all required categories represented
	categories := []string{"behavioral", "emotional", "environmental", "lifestyle"}
	items := make([]StarterPackItem, count)

	for i := 0; i < count; i++ {
		items[i] = StarterPackItem{
			BehaviorName: "Middle item",
			Category:     categories[i%len(categories)],
		}
	}

	return items
}

func createStarterPackForArea(area RecoveryArea, variant StarterPackVariant) StarterPack {
	pack := createValidStarterPack()
	pack.RecoveryArea = area
	pack.Variant = variant
	return pack
}

func createStarterPackForAreaAndVariant(area RecoveryArea, variant StarterPackVariant) StarterPack {
	pack := createValidStarterPack()
	pack.RecoveryArea = area
	pack.Variant = variant
	return pack
}
