// internal/domain/exercise/favorites.go
package exercise

// ValidateFavorite validates a favorite before creation.
func ValidateFavorite(fav ExerciseFavorite) error {
	if !ValidActivityTypes[fav.ActivityType] {
		return ErrInvalidActivityType
	}
	if fav.ActivityType == ActivityTypeOther {
		if fav.CustomTypeLabel == nil || *fav.CustomTypeLabel == "" {
			return ErrCustomLabelRequired
		}
	}
	if fav.CustomTypeLabel != nil && len(*fav.CustomTypeLabel) > MaxCustomLabelLength {
		return ErrCustomLabelTooLong
	}
	if fav.DefaultDurationMinutes < 1 || fav.DefaultDurationMinutes > MaxDuration {
		return ErrInvalidDuration
	}
	if fav.DefaultIntensity != nil && !ValidIntensityLevels[*fav.DefaultIntensity] {
		return ErrInvalidIntensity
	}
	return nil
}

// CanAddFavorite checks if the user can add another favorite (max 5).
func CanAddFavorite(currentCount int) error {
	if currentCount >= MaxFavorites {
		return ErrMaxFavoritesReached
	}
	return nil
}

// ShouldPromoteCustomType checks whether a custom type has been used enough
// times to trigger a "save as favorite" prompt.
func ShouldPromoteCustomType(customTypeUseCount int) bool {
	return customTypeUseCount >= 3
}

// BuildLogFromFavorite creates a CreateExerciseLogRequest from a favorite's defaults.
func BuildLogFromFavorite(fav ExerciseFavorite) CreateExerciseLogRequest {
	return CreateExerciseLogRequest{
		ActivityType:    fav.ActivityType,
		CustomTypeLabel: fav.CustomTypeLabel,
		DurationMinutes: fav.DefaultDurationMinutes,
		Intensity:       fav.DefaultIntensity,
		Source:          SourceManual,
	}
}
