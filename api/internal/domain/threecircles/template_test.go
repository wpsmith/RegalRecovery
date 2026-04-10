// internal/domain/threecircles/template_test.go
package threecircles

import (
	"testing"
)

// TestTemplate_TC_TP_001_FilterByRecoveryArea verifies that templates
// can be filtered by recovery area.
//
// Acceptance Criterion TC-TP-001: Templates filterable by recovery area.
func TestTemplate_TC_TP_001_FilterByRecoveryArea(t *testing.T) {
	// Given - Templates for multiple recovery areas
	templates := []Template{
		{
			ID:           "t1",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleInner,
			BehaviorName: "Viewing pornography",
			IsActive:     true,
		},
		{
			ID:           "t2",
			RecoveryArea: RecoveryAreaAlcohol,
			Circle:       CircleInner,
			BehaviorName: "Using alcohol",
			IsActive:     true,
		},
		{
			ID:           "t3",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleMiddle,
			BehaviorName: "Late night browsing",
			IsActive:     true,
		},
	}

	// When - Filtering by sex-pornography recovery area
	req := FilterTemplatesRequest{
		RecoveryArea: RecoveryAreaSexPornography,
	}
	result := FilterTemplates(templates, req)

	// Then - Only sex-pornography templates returned
	if len(result) != 2 {
		t.Errorf("expected 2 sex-pornography templates, got %d", len(result))
	}
	for _, tmpl := range result {
		if tmpl.RecoveryArea != RecoveryAreaSexPornography {
			t.Errorf("expected sex-pornography recovery area, got %s", tmpl.RecoveryArea)
		}
	}
}

// TestTemplate_TC_TP_002_FilterByCircle verifies that templates
// can be filtered by circle type.
//
// Acceptance Criterion TC-TP-002: Templates filterable by circle.
func TestTemplate_TC_TP_002_FilterByCircle(t *testing.T) {
	// Given - Templates for multiple circles
	templates := []Template{
		{
			ID:           "t1",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleInner,
			BehaviorName: "Viewing pornography",
			IsActive:     true,
		},
		{
			ID:           "t2",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleMiddle,
			BehaviorName: "Late night browsing",
			IsActive:     true,
		},
		{
			ID:           "t3",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleOuter,
			BehaviorName: "Daily check-in",
			IsActive:     true,
		},
	}

	// When - Filtering by inner circle
	innerCircle := CircleInner
	req := FilterTemplatesRequest{
		RecoveryArea: RecoveryAreaSexPornography,
		Circle:       &innerCircle,
	}
	result := FilterTemplates(templates, req)

	// Then - Only inner circle templates returned
	if len(result) != 1 {
		t.Errorf("expected 1 inner circle template, got %d", len(result))
	}
	if result[0].Circle != CircleInner {
		t.Errorf("expected inner circle, got %s", result[0].Circle)
	}
}

// TestTemplate_TC_TP_003_FilterByFramework verifies that templates
// can be filtered by framework preference.
//
// Acceptance Criterion TC-TP-003: Templates filterable by framework.
func TestTemplate_TC_TP_003_FilterByFramework(t *testing.T) {
	// Given - Templates with different framework variants
	frameworkSA := FrameworkSAA
	frameworkCelebrate := FrameworkCoDA

	templates := []Template{
		{
			ID:               "t1",
			RecoveryArea:     RecoveryAreaSexPornography,
			Circle:           CircleInner,
			BehaviorName:     "Sexual acting out",
			FrameworkVariant: &frameworkSA,
			IsActive:         true,
		},
		{
			ID:               "t2",
			RecoveryArea:     RecoveryAreaSexPornography,
			Circle:           CircleInner,
			BehaviorName:     "Viewing pornography",
			FrameworkVariant: &frameworkCelebrate,
			IsActive:         true,
		},
		{
			ID:               "t3",
			RecoveryArea:     RecoveryAreaSexPornography,
			Circle:           CircleInner,
			BehaviorName:     "Using explicit content",
			FrameworkVariant: nil, // Universal
			IsActive:         true,
		},
	}

	// When - Filtering by SA framework
	req := FilterTemplatesRequest{
		RecoveryArea: RecoveryAreaSexPornography,
		Framework:    &frameworkSA,
	}
	result := FilterTemplates(templates, req)

	// Then - SA templates and universal templates returned
	if len(result) != 2 {
		t.Errorf("expected 2 templates (SA + universal), got %d", len(result))
	}

	saCount := 0
	universalCount := 0
	for _, tmpl := range result {
		if tmpl.FrameworkVariant == nil {
			universalCount++
		} else if *tmpl.FrameworkVariant == FrameworkSAA {
			saCount++
		}
	}

	if saCount != 1 {
		t.Errorf("expected 1 SA template, got %d", saCount)
	}
	if universalCount != 1 {
		t.Errorf("expected 1 universal template, got %d", universalCount)
	}
}

// TestTemplate_TC_TP_004_UniversalTemplatesMatchAllFrameworks verifies
// that templates with nil FrameworkVariant (universal) match all framework filters.
//
// Acceptance Criterion TC-TP-004: Universal templates match all frameworks.
func TestTemplate_TC_TP_004_UniversalTemplatesMatchAllFrameworks(t *testing.T) {
	// Given - Universal template
	templates := []Template{
		{
			ID:               "t1",
			RecoveryArea:     RecoveryAreaSexPornography,
			Circle:           CircleInner,
			BehaviorName:     "Using explicit content",
			FrameworkVariant: nil, // Universal
			IsActive:         true,
		},
	}

	// When - Filtering by different frameworks
	frameworks := []FrameworkPreference{FrameworkSAA, FrameworkCoDA, FrameworkSLAA}

	for _, framework := range frameworks {
		req := FilterTemplatesRequest{
			RecoveryArea: RecoveryAreaSexPornography,
			Framework:    &framework,
		}
		result := FilterTemplates(templates, req)

		// Then - Universal template included in all results
		if len(result) != 1 {
			t.Errorf("expected 1 universal template for framework %s, got %d", framework, len(result))
		}
	}
}

// TestTemplate_TC_TP_005_InactiveTemplatesExcluded verifies that
// inactive templates are excluded from results.
//
// Acceptance Criterion TC-TP-005: Inactive templates excluded.
func TestTemplate_TC_TP_005_InactiveTemplatesExcluded(t *testing.T) {
	// Given - Mix of active and inactive templates
	templates := []Template{
		{
			ID:           "t1",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleInner,
			BehaviorName: "Active template",
			IsActive:     true,
		},
		{
			ID:           "t2",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleInner,
			BehaviorName: "Inactive template",
			IsActive:     false,
		},
	}

	// When - Filtering templates
	req := FilterTemplatesRequest{
		RecoveryArea: RecoveryAreaSexPornography,
	}
	result := FilterTemplates(templates, req)

	// Then - Only active template returned
	if len(result) != 1 {
		t.Errorf("expected 1 active template, got %d", len(result))
	}
	if !result[0].IsActive {
		t.Errorf("expected active template, got inactive")
	}
}

// TestTemplate_TC_TP_006_CombinedFilters verifies that multiple
// filters can be applied simultaneously.
//
// Acceptance Criterion TC-TP-006: Filters combine correctly.
func TestTemplate_TC_TP_006_CombinedFilters(t *testing.T) {
	// Given - Templates with various attributes
	frameworkSA := FrameworkSAA
	frameworkCelebrate := FrameworkCoDA

	templates := []Template{
		{
			ID:               "t1",
			RecoveryArea:     RecoveryAreaSexPornography,
			Circle:           CircleInner,
			BehaviorName:     "SA Inner",
			FrameworkVariant: &frameworkSA,
			IsActive:         true,
		},
		{
			ID:               "t2",
			RecoveryArea:     RecoveryAreaSexPornography,
			Circle:           CircleMiddle,
			BehaviorName:     "SA Middle",
			FrameworkVariant: &frameworkSA,
			IsActive:         true,
		},
		{
			ID:               "t3",
			RecoveryArea:     RecoveryAreaSexPornography,
			Circle:           CircleInner,
			BehaviorName:     "Celebrate Inner",
			FrameworkVariant: &frameworkCelebrate,
			IsActive:         true,
		},
		{
			ID:               "t4",
			RecoveryArea:     RecoveryAreaAlcohol,
			Circle:           CircleInner,
			BehaviorName:     "SA Inner (wrong area)",
			FrameworkVariant: &frameworkSA,
			IsActive:         true,
		},
	}

	// When - Filtering by recovery area, circle, and framework
	innerCircle := CircleInner
	req := FilterTemplatesRequest{
		RecoveryArea: RecoveryAreaSexPornography,
		Circle:       &innerCircle,
		Framework:    &frameworkSA,
	}
	result := FilterTemplates(templates, req)

	// Then - Only matching template returned
	if len(result) != 1 {
		t.Errorf("expected 1 template matching all filters, got %d", len(result))
	}
	if result[0].ID != "t1" {
		t.Errorf("expected template t1, got %s", result[0].ID)
	}
}

// TestTemplate_TC_TP_007_NoMatchReturnsEmpty verifies that
// filtering with no matches returns an empty slice.
//
// Acceptance Criterion TC-TP-007: No matches returns empty result.
func TestTemplate_TC_TP_007_NoMatchReturnsEmpty(t *testing.T) {
	// Given - Templates for one recovery area
	templates := []Template{
		{
			ID:           "t1",
			RecoveryArea: RecoveryAreaSexPornography,
			Circle:       CircleInner,
			BehaviorName: "Test",
			IsActive:     true,
		},
	}

	// When - Filtering by different recovery area
	req := FilterTemplatesRequest{
		RecoveryArea: RecoveryAreaGambling,
	}
	result := FilterTemplates(templates, req)

	// Then - Empty slice returned
	if len(result) != 0 {
		t.Errorf("expected empty result, got %d templates", len(result))
	}
}

// TestTemplate_TC_TP_008_RecoveryAreaValidation verifies that
// recovery area enum has valid values.
//
// Acceptance Criterion TC-TP-008: Recovery area validation works.
func TestTemplate_TC_TP_008_RecoveryAreaValidation(t *testing.T) {
	// Given/When/Then - Valid recovery areas
	validAreas := []RecoveryArea{
		RecoveryAreaSexPornography,
		RecoveryAreaAlcohol,
		RecoveryAreaDrugs,
		RecoveryAreaGambling,
		RecoveryAreaFoodEating,
		RecoveryAreaInternetTechnology,
		RecoveryAreaWork,
		RecoveryAreaShoppingDebt,
		RecoveryAreaLoveRelationships,
		RecoveryAreaOther,
	}

	for _, area := range validAreas {
		if !area.IsValid() {
			t.Errorf("expected %s to be valid", area)
		}
	}

	// Invalid recovery area
	invalid := RecoveryArea("invalid")
	if invalid.IsValid() {
		t.Errorf("expected invalid recovery area to be invalid")
	}
}

// TestTemplate_TC_TP_009_CircleTypeValidation verifies that
// circle type enum has valid values.
//
// Acceptance Criterion TC-TP-009: Circle type validation works.
func TestTemplate_TC_TP_009_CircleTypeValidation(t *testing.T) {
	// Given/When/Then - Valid circle types
	validCircles := []CircleType{CircleInner, CircleMiddle, CircleOuter}

	for _, circle := range validCircles {
		if !circle.IsValid() {
			t.Errorf("expected %s to be valid", circle)
		}
	}

	// Invalid circle type
	invalid := CircleType("invalid")
	if invalid.IsValid() {
		t.Errorf("expected invalid circle type to be invalid")
	}
}

// TestTemplate_TC_TP_010_FrameworkPreferenceValidation verifies that
// framework preference enum has valid values.
//
// Acceptance Criterion TC-TP-010: Framework preference validation works.
func TestTemplate_TC_TP_010_FrameworkPreferenceValidation(t *testing.T) {
	// Given/When/Then - Valid framework preferences
	validFrameworks := []FrameworkPreference{
		FrameworkSAA,
		FrameworkSLAA,
		FrameworkAA,
		FrameworkNA,
		FrameworkSMART,
		FrameworkOA,
		FrameworkGA,
		FrameworkDA,
		FrameworkCoDA,
		FrameworkITAA,
		FrameworkWA,
		FrameworkOther,
		FrameworkNone,
	}

	for _, framework := range validFrameworks {
		if !framework.IsValid() {
			t.Errorf("expected %s to be valid", framework)
		}
	}

	// Invalid framework
	invalid := FrameworkPreference("invalid")
	if invalid.IsValid() {
		t.Errorf("expected invalid framework to be invalid")
	}
}

// TestTemplate_TC_TP_011_EmptyTemplateListReturnsEmpty verifies that
// filtering an empty list returns an empty result.
//
// Acceptance Criterion TC-TP-011: Empty input returns empty output.
func TestTemplate_TC_TP_011_EmptyTemplateListReturnsEmpty(t *testing.T) {
	// Given - Empty template list
	templates := []Template{}

	// When - Filtering
	req := FilterTemplatesRequest{
		RecoveryArea: RecoveryAreaSexPornography,
	}
	result := FilterTemplates(templates, req)

	// Then - Empty result
	if len(result) != 0 {
		t.Errorf("expected empty result, got %d templates", len(result))
	}
}

// TestTemplate_TC_TP_012_TemplateMetadataPresent verifies that
// templates include all required metadata fields.
//
// Acceptance Criterion TC-TP-012: Templates have complete metadata.
func TestTemplate_TC_TP_012_TemplateMetadataPresent(t *testing.T) {
	// Given - Template with full metadata
	template := Template{
		ID:                  "t1",
		RecoveryArea:        RecoveryAreaSexPornography,
		Circle:              CircleInner,
		BehaviorName:        "Viewing pornography",
		Rationale:           "This is a bottom-line behavior",
		SpecificityGuidance: "Be specific about types and contexts",
		Category:            "behavioral",
		FrameworkVariant:    nil,
		Version:             1,
		IsActive:            true,
	}

	// When/Then - All fields present
	if template.ID == "" {
		t.Errorf("expected ID to be present")
	}
	if template.BehaviorName == "" {
		t.Errorf("expected behavior name to be present")
	}
	if template.Rationale == "" {
		t.Errorf("expected rationale to be present")
	}
	if template.SpecificityGuidance == "" {
		t.Errorf("expected specificity guidance to be present")
	}
	if template.Category == "" {
		t.Errorf("expected category to be present")
	}
}
