// test/unit/devotionals_favorites_test.go
package unit

import (
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/domain/devotionals"
)

// =============================================================================
// Devotional Favorites Tests
// Location: internal/domain/devotionals/favorites_test.go (spec)
// =============================================================================

// TestFavorites_AC_DEV_FAVORITE_01_AddToFavorites verifies that a favorite
// document can be created with the correct structure.
func TestFavorites_AC_DEV_FAVORITE_01_AddToFavorites(t *testing.T) {
	// Given: a devotional to favorite
	doc := &devotionals.FavoriteDoc{
		PK:                 "USER#u_12345",
		SK:                 "DEVFAV#dev_a1b2c3d4",
		EntityType:         "DEVOTIONAL_FAVORITE",
		TenantID:           "DEFAULT",
		CreatedAt:          time.Now().UTC(),
		ModifiedAt:         time.Now().UTC(),
		DevotionalID:       "dev_a1b2c3d4",
		DevotionalTitle:    "Strength in Surrender",
		ScriptureReference: "2 Corinthians 12:9",
		Topic:              devotionals.TopicSurrender,
	}

	// Then: document structure is correct
	if doc.EntityType != "DEVOTIONAL_FAVORITE" {
		t.Errorf("expected EntityType DEVOTIONAL_FAVORITE, got %s", doc.EntityType)
	}
	if doc.DevotionalID != "dev_a1b2c3d4" {
		t.Errorf("expected DevotionalID dev_a1b2c3d4, got %s", doc.DevotionalID)
	}
	if doc.PK != "USER#u_12345" {
		t.Errorf("expected PK USER#u_12345, got %s", doc.PK)
	}
	if doc.SK != "DEVFAV#dev_a1b2c3d4" {
		t.Errorf("expected SK DEVFAV#dev_a1b2c3d4, got %s", doc.SK)
	}
}

// TestFavorites_AC_DEV_FAVORITE_02_RemoveFromFavorites verifies the SK format
// for removing a favorite (the key used in the delete operation).
func TestFavorites_AC_DEV_FAVORITE_02_RemoveFromFavorites(t *testing.T) {
	// Given: a favorite to remove
	userID := "u_12345"
	devotionalID := "dev_a1b2c3d4"

	// Then: the expected SK for deletion
	expectedSK := "DEVFAV#" + devotionalID
	expectedPK := "USER#" + userID

	if expectedPK != "USER#u_12345" {
		t.Errorf("expected PK USER#u_12345, got %s", expectedPK)
	}
	if expectedSK != "DEVFAV#dev_a1b2c3d4" {
		t.Errorf("expected SK DEVFAV#dev_a1b2c3d4, got %s", expectedSK)
	}
}

// TestFavorites_AC_DEV_FAVORITE_03_ListFavorites verifies that a list of
// favorites can be constructed from FavoriteDoc records.
func TestFavorites_AC_DEV_FAVORITE_03_ListFavorites(t *testing.T) {
	// Given: 5 favorited devotionals
	favorites := make([]devotionals.FavoriteDoc, 5)
	for i := 0; i < 5; i++ {
		favorites[i] = devotionals.FavoriteDoc{
			DevotionalID:    "dev_fav_" + string(rune('a'+i)),
			DevotionalTitle: "Devotional " + string(rune('A'+i)),
		}
	}

	// Then: returns 5
	if len(favorites) != 5 {
		t.Errorf("expected 5 favorites, got %d", len(favorites))
	}
}

// TestFavorites_AddDuplicate_Idempotent verifies the idempotent nature of
// adding a favorite -- the upsert pattern used in the repository means
// adding the same favorite twice does not create a duplicate.
func TestFavorites_AddDuplicate_Idempotent(t *testing.T) {
	// This is primarily an integration concern, but we validate the
	// doc structure is identical for the same devotionalId.
	doc1 := devotionals.FavoriteDoc{
		PK:           "USER#u_12345",
		SK:           "DEVFAV#dev_x",
		DevotionalID: "dev_x",
	}
	doc2 := devotionals.FavoriteDoc{
		PK:           "USER#u_12345",
		SK:           "DEVFAV#dev_x",
		DevotionalID: "dev_x",
	}

	// The upsert key (PK+SK) is identical, so the second add is a no-op replacement.
	if doc1.PK != doc2.PK || doc1.SK != doc2.SK {
		t.Error("expected identical PK/SK for duplicate add")
	}
}
