// internal/domain/nutrition/settings.go
package nutrition

import (
	"context"
	"fmt"
	"time"
)

// SettingsRepository defines the interface for nutrition settings data access.
type SettingsRepository interface {
	GetSettings(ctx context.Context, userID string) (*NutritionSettings, error)
	UpsertSettings(ctx context.Context, settings *NutritionSettings) error
}

// SettingsService handles nutrition settings business logic.
type SettingsService struct {
	repo SettingsRepository
}

// NewSettingsService creates a new SettingsService.
func NewSettingsService(repo SettingsRepository) *SettingsService {
	return &SettingsService{repo: repo}
}

// GetSettings retrieves the user's nutrition settings, creating defaults if none exist.
func (s *SettingsService) GetSettings(ctx context.Context, userID string) (*NutritionSettings, error) {
	settings, err := s.repo.GetSettings(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("getting settings: %w", err)
	}
	if settings == nil {
		settings = DefaultNutritionSettings(userID)
		if err := s.repo.UpsertSettings(ctx, settings); err != nil {
			return nil, fmt.Errorf("creating default settings: %w", err)
		}
	}
	return settings, nil
}

// UpdateSettings applies a JSON Merge Patch to the user's settings.
func (s *SettingsService) UpdateSettings(ctx context.Context, userID string, patch map[string]interface{}) (*NutritionSettings, error) {
	settings, err := s.GetSettings(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Apply the patch to settings.
	applySettingsPatch(settings, patch)
	settings.ModifiedAt = time.Now().UTC()

	if err := s.repo.UpsertSettings(ctx, settings); err != nil {
		return nil, fmt.Errorf("updating settings: %w", err)
	}

	return settings, nil
}

// DefaultNutritionSettings returns a new NutritionSettings with all defaults.
// FR-NUT-3.4: Default serving size is 8 oz.
// FR-NUT-3.6: Default daily target is 8 servings.
// FR-NUT-15.1: Meal reminders default off.
// FR-NUT-15.2: Hydration reminders default off.
func DefaultNutritionSettings(userID string) *NutritionSettings {
	now := time.Now().UTC()
	s := &NutritionSettings{
		UserID:     userID,
		CreatedAt:  now,
		ModifiedAt: now,
	}

	s.Hydration.ServingSizeOz = DefaultServingSizeOz
	s.Hydration.DailyTargetServings = DefaultDailyTargetServings

	s.MealReminders.Breakfast = MealReminderSetting{Enabled: false, Time: "08:00"}
	s.MealReminders.Lunch = MealReminderSetting{Enabled: false, Time: "12:00"}
	s.MealReminders.Dinner = MealReminderSetting{Enabled: false, Time: "18:00"}

	s.HydrationReminders.Enabled = false
	s.HydrationReminders.IntervalHours = 2

	s.MissedMealNudge.Enabled = false
	s.MissedMealNudge.NudgeTime = "14:00"

	s.InsightPreferences.MealConsistencyEnabled = true
	s.InsightPreferences.EmotionalEatingEnabled = true
	s.InsightPreferences.MindfulnessEnabled = true
	s.InsightPreferences.CrossDomainEnabled = true

	return s
}
