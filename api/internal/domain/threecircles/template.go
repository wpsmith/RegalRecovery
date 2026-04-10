// internal/domain/threecircles/template.go
package threecircles

import (
	"errors"
)

// Sentinel errors for templates.
var (
	ErrTemplateNotFound = errors.New("template not found")
	ErrInvalidCircle    = errors.New("invalid circle type")
)

// RecoveryArea represents the primary recovery area for a circle set.
// Defined in types.go but documented here for templates context.
type RecoveryArea string

const (
	RecoveryAreaSexPornography     RecoveryArea = "sex-pornography"
	RecoveryAreaAlcohol            RecoveryArea = "alcohol"
	RecoveryAreaDrugs              RecoveryArea = "drugs"
	RecoveryAreaGambling           RecoveryArea = "gambling"
	RecoveryAreaFoodEating         RecoveryArea = "food-eating"
	RecoveryAreaInternetTechnology RecoveryArea = "internet-technology"
	RecoveryAreaWork               RecoveryArea = "work"
	RecoveryAreaShoppingDebt       RecoveryArea = "shopping-debt"
	RecoveryAreaLoveRelationships  RecoveryArea = "love-relationships"
	RecoveryAreaOther              RecoveryArea = "other"
)

// IsValid returns true if the recovery area is recognized.
func (r RecoveryArea) IsValid() bool {
	switch r {
	case RecoveryAreaSexPornography, RecoveryAreaAlcohol, RecoveryAreaDrugs,
		RecoveryAreaGambling, RecoveryAreaFoodEating, RecoveryAreaInternetTechnology,
		RecoveryAreaWork, RecoveryAreaShoppingDebt, RecoveryAreaLoveRelationships,
		RecoveryAreaOther:
		return true
	default:
		return false
	}
}

// FrameworkPreference represents optional recovery framework variants.
type FrameworkPreference string

const (
	FrameworkSAA   FrameworkPreference = "SAA"
	FrameworkSLAA  FrameworkPreference = "SLAA"
	FrameworkAA    FrameworkPreference = "AA"
	FrameworkNA    FrameworkPreference = "NA"
	FrameworkSMART FrameworkPreference = "SMART"
	FrameworkOA    FrameworkPreference = "OA"
	FrameworkGA    FrameworkPreference = "GA"
	FrameworkDA    FrameworkPreference = "DA"
	FrameworkCoDA  FrameworkPreference = "CoDA"
	FrameworkITAA  FrameworkPreference = "ITAA"
	FrameworkWA    FrameworkPreference = "WA"
	FrameworkOther FrameworkPreference = "other"
	FrameworkNone  FrameworkPreference = "none"
)

// IsValid returns true if the framework preference is recognized.
func (fp FrameworkPreference) IsValid() bool {
	switch fp {
	case FrameworkSAA, FrameworkSLAA, FrameworkAA, FrameworkNA, FrameworkSMART,
		FrameworkOA, FrameworkGA, FrameworkDA, FrameworkCoDA, FrameworkITAA,
		FrameworkWA, FrameworkOther, FrameworkNone:
		return true
	default:
		return false
	}
}

// Template represents a suggested behavior for a specific circle.
// Templates are reviewed by both clinical (CSAT) and community reviewers.
type Template struct {
	ID                  string               `json:"templateId"`
	RecoveryArea        RecoveryArea         `json:"recoveryArea"`
	Circle              CircleType           `json:"circle"`
	BehaviorName        string               `json:"behaviorName"`
	Rationale           string               `json:"rationale"`                  // Why this belongs in this circle
	SpecificityGuidance string               `json:"specificityGuidance"`        // How to make it specific
	Category            string               `json:"category"`                   // Behavioral, emotional, environmental, lifestyle, etc.
	FrameworkVariant    *FrameworkPreference `json:"frameworkVariant,omitempty"` // nil = universal
	Version             int                  `json:"version"`
	IsActive            bool                 `json:"isActive"`
}

// FilterTemplatesRequest represents filter criteria for templates.
type FilterTemplatesRequest struct {
	RecoveryArea RecoveryArea         `json:"recoveryArea"`
	Circle       *CircleType          `json:"circle,omitempty"`    // Filter by circle if specified
	Framework    *FrameworkPreference `json:"framework,omitempty"` // Filter by framework if specified
}

// FilterTemplates filters a slice of templates based on the given criteria.
// Returns templates matching the recovery area and optional circle/framework filters.
// Templates with nil FrameworkVariant (universal) are always included.
func FilterTemplates(templates []Template, req FilterTemplatesRequest) []Template {
	result := make([]Template, 0)

	for _, t := range templates {
		// Skip inactive templates
		if !t.IsActive {
			continue
		}

		// Recovery area must match
		if t.RecoveryArea != req.RecoveryArea {
			continue
		}

		// Circle filter (if specified)
		if req.Circle != nil && t.Circle != *req.Circle {
			continue
		}

		// Framework filter (if specified)
		// Universal templates (nil FrameworkVariant) always match
		if req.Framework != nil {
			// Universal templates match all frameworks
			if t.FrameworkVariant != nil {
				// Framework-specific template must match requested framework
				if *t.FrameworkVariant != *req.Framework {
					continue
				}
			}
		}

		result = append(result, t)
	}

	return result
}
