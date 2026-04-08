// internal/domain/affirmation/favorites.go
package affirmation

import "fmt"

// FavoriteRepository defines the interface for favorite affirmation storage.
type FavoriteRepository interface {
	Add(userID, affirmationID, packID string) error
	Remove(userID, affirmationID string) error
	List(userID string) ([]string, error) // returns affirmation IDs
	IsFavorite(userID, affirmationID string) (bool, error)
}

// FavoriteService manages affirmation favorites.
type FavoriteService struct {
	repo FavoriteRepository
}

// NewFavoriteService creates a new FavoriteService.
func NewFavoriteService(repo FavoriteRepository) *FavoriteService {
	return &FavoriteService{repo: repo}
}

// AddFavorite adds an affirmation to the user's favorites.
// Works for both system (aff_*) and custom (caff_*) affirmations.
func (s *FavoriteService) AddFavorite(userID, affirmationID, packID string) error {
	if !ValidateAnyID(affirmationID) {
		return fmt.Errorf("invalid affirmation ID format: %s", affirmationID)
	}
	return s.repo.Add(userID, affirmationID, packID)
}

// RemoveFavorite removes an affirmation from the user's favorites.
func (s *FavoriteService) RemoveFavorite(userID, affirmationID string) error {
	if !ValidateAnyID(affirmationID) {
		return fmt.Errorf("invalid affirmation ID format: %s", affirmationID)
	}
	return s.repo.Remove(userID, affirmationID)
}

// ListFavorites returns all favorited affirmation IDs for a user.
func (s *FavoriteService) ListFavorites(userID string) ([]string, error) {
	return s.repo.List(userID)
}

// IsFavorite checks if a specific affirmation is favorited by the user.
func (s *FavoriteService) IsFavorite(userID, affirmationID string) (bool, error) {
	return s.repo.IsFavorite(userID, affirmationID)
}
