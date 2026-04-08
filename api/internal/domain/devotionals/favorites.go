// internal/domain/devotionals/favorites.go
package devotionals

import (
	"context"
	"fmt"
	"time"
)

// FavoritesService manages devotional favorites.
type FavoritesService struct {
	favoriteRepo DevotionalFavoriteRepository
	contentRepo  DevotionalContentRepository
}

// NewFavoritesService creates a new FavoritesService.
func NewFavoritesService(favoriteRepo DevotionalFavoriteRepository, contentRepo DevotionalContentRepository) *FavoritesService {
	return &FavoritesService{
		favoriteRepo: favoriteRepo,
		contentRepo:  contentRepo,
	}
}

// AddFavorite adds a devotional to the user's favorites.
// Idempotent: adding a devotional that is already favorited is a no-op.
func (s *FavoritesService) AddFavorite(ctx context.Context, userID, devotionalID string) error {
	if userID == "" || devotionalID == "" {
		return fmt.Errorf("userID and devotionalID are required: %w", ErrInvalidInput)
	}

	// Verify devotional exists
	content, err := s.contentRepo.GetByID(ctx, devotionalID)
	if err != nil {
		return fmt.Errorf("looking up devotional: %w", err)
	}
	if content == nil {
		return ErrDevotionalNotFound
	}

	now := time.Now().UTC()
	doc := &FavoriteDoc{
		PK:                 fmt.Sprintf("USER#%s", userID),
		SK:                 fmt.Sprintf("DEVFAV#%s", devotionalID),
		EntityType:         "DEVOTIONAL_FAVORITE",
		TenantID:           "DEFAULT",
		CreatedAt:          now,
		ModifiedAt:         now,
		DevotionalID:       devotionalID,
		DevotionalTitle:    content.Title,
		ScriptureReference: content.ScriptureReference,
		Topic:              content.Topic,
	}

	return s.favoriteRepo.Add(ctx, userID, doc)
}

// RemoveFavorite removes a devotional from the user's favorites.
func (s *FavoritesService) RemoveFavorite(ctx context.Context, userID, devotionalID string) error {
	if userID == "" || devotionalID == "" {
		return fmt.Errorf("userID and devotionalID are required: %w", ErrInvalidInput)
	}
	return s.favoriteRepo.Remove(ctx, userID, devotionalID)
}

// ListFavorites retrieves the user's favorite devotionals.
func (s *FavoritesService) ListFavorites(ctx context.Context, userID, cursor string, limit int) ([]FavoriteDoc, string, error) {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	return s.favoriteRepo.List(ctx, userID, cursor, limit)
}

// IsFavorite checks if a devotional is in the user's favorites.
func (s *FavoritesService) IsFavorite(ctx context.Context, userID, devotionalID string) (bool, error) {
	return s.favoriteRepo.IsFavorite(ctx, userID, devotionalID)
}
