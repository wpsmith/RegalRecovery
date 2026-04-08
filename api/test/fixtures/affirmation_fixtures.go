// test/fixtures/affirmation_fixtures.go
package fixtures

import (
	"github.com/regalrecovery/api/internal/domain/affirmation"
)

// AlexAffirmationContext is the test context for Alex (long-term recovery, 270 cumulative days).
var AlexAffirmationContext = AffirmationTestContext{
	UserID:                "u_alex",
	CumulativeDays:        270,
	MaxLevel:              3,
	OwnedPacks:            []string{"pack_basic_affirmations", "pack_premium_strength"},
	Favorites:             []string{"aff_001", "aff_015", "aff_042"},
	HealthySexualityOptIn: true,
	RotationMode:          affirmation.ModeRandomAutomatic,
	Language:              "en",
}

// MarcusAffirmationContext is the test context for Marcus (early recovery, 15 cumulative days).
var MarcusAffirmationContext = AffirmationTestContext{
	UserID:                "u_marcus",
	CumulativeDays:        15,
	MaxLevel:              1,
	OwnedPacks:            []string{"pack_basic_affirmations"},
	Favorites:             []string{"aff_003"},
	HealthySexualityOptIn: false,
	RotationMode:          affirmation.ModeRandomAutomatic,
	Language:              "en",
}

// DiegoAffirmationContext is the test context for Diego (30 cumulative days, Spanish).
var DiegoAffirmationContext = AffirmationTestContext{
	UserID:                "u_diego",
	CumulativeDays:        30,
	MaxLevel:              2,
	OwnedPacks:            []string{"pack_basic_affirmations_es"},
	Favorites:             []string{},
	HealthySexualityOptIn: false,
	RotationMode:          affirmation.ModePermanentPackage,
	Language:              "es",
}

// AffirmationTestContext holds all test data needed for affirmation tests.
type AffirmationTestContext struct {
	UserID                string
	CumulativeDays        int
	MaxLevel              int
	OwnedPacks            []string
	Favorites             []string
	HealthySexualityOptIn bool
	RotationMode          affirmation.SelectionMode
	Language              string
}

// CustomAffirmationFixture creates a test custom affirmation.
func CustomAffirmationFixture(id, statement, category, schedule string) affirmation.CustomAffirmation {
	return affirmation.CustomAffirmation{
		Affirmation: affirmation.Affirmation{
			AffirmationID: id,
			Statement:     statement,
			Category:      affirmation.AffirmationCategory(category),
			Level:         1,
			IsCustom:      true,
			Language:      "en",
		},
		Schedule: affirmation.Schedule(schedule),
		IsActive: true,
	}
}

// AlexCustomAffirmations returns custom affirmations for Alex.
func AlexCustomAffirmations() []affirmation.CustomAffirmation {
	return []affirmation.CustomAffirmation{
		CustomAffirmationFixture("caff_alex_001", "My wife's trust is being rebuilt one honest day at a time.", "family", "daily"),
	}
}

// DiegoCustomAffirmations returns custom affirmations for Diego.
func DiegoCustomAffirmations() []affirmation.CustomAffirmation {
	return []affirmation.CustomAffirmation{
		CustomAffirmationFixture("caff_diego_001", "Mi familia merece lo mejor de mi.", "family", "daily"),
	}
}
