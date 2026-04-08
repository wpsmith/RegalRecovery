// internal/domain/nutrition/settings_test.go
package nutrition

import "testing"

// TestSettings_FR_NUT_10_1_HydrationGoalSetting verifies hydration goal can be changed.
func TestSettings_FR_NUT_10_1_HydrationGoalSetting(t *testing.T) {
	settings := DefaultNutritionSettings("u_test")

	patch := map[string]interface{}{
		"hydration": map[string]interface{}{
			"dailyTargetServings": float64(12),
		},
	}
	applySettingsPatch(settings, patch)

	if settings.Hydration.DailyTargetServings != 12 {
		t.Errorf("expected dailyTargetServings=12, got %d", settings.Hydration.DailyTargetServings)
	}
	// Other hydration settings should be preserved.
	if settings.Hydration.ServingSizeOz != 8 {
		t.Errorf("expected servingSizeOz=8 (unchanged), got %f", settings.Hydration.ServingSizeOz)
	}
}

// TestSettings_FR_NUT_10_2_ServingSizeSetting verifies serving size can be changed.
func TestSettings_FR_NUT_10_2_ServingSizeSetting(t *testing.T) {
	settings := DefaultNutritionSettings("u_test")

	patch := map[string]interface{}{
		"hydration": map[string]interface{}{
			"servingSizeOz": float64(16),
		},
	}
	applySettingsPatch(settings, patch)

	if settings.Hydration.ServingSizeOz != 16 {
		t.Errorf("expected servingSizeOz=16, got %f", settings.Hydration.ServingSizeOz)
	}
}

// TestSettings_FR_NUT_10_3_MealReminderSettings verifies meal reminder configuration.
func TestSettings_FR_NUT_10_3_MealReminderSettings(t *testing.T) {
	settings := DefaultNutritionSettings("u_test")

	patch := map[string]interface{}{
		"mealReminders": map[string]interface{}{
			"breakfast": map[string]interface{}{
				"enabled": true,
				"time":    "08:00",
			},
		},
	}
	applySettingsPatch(settings, patch)

	if !settings.MealReminders.Breakfast.Enabled {
		t.Error("expected breakfast reminder enabled")
	}
	if settings.MealReminders.Breakfast.Time != "08:00" {
		t.Errorf("expected time 08:00, got %s", settings.MealReminders.Breakfast.Time)
	}
	// Lunch and dinner should be unchanged.
	if settings.MealReminders.Lunch.Enabled {
		t.Error("expected lunch reminder still disabled")
	}
}

// TestSettings_FR_NUT_10_4_HydrationReminderInterval verifies hydration reminder interval.
func TestSettings_FR_NUT_10_4_HydrationReminderInterval(t *testing.T) {
	settings := DefaultNutritionSettings("u_test")

	patch := map[string]interface{}{
		"hydrationReminders": map[string]interface{}{
			"enabled":       true,
			"intervalHours": float64(2),
		},
	}
	applySettingsPatch(settings, patch)

	if !settings.HydrationReminders.Enabled {
		t.Error("expected hydration reminders enabled")
	}
	if settings.HydrationReminders.IntervalHours != 2 {
		t.Errorf("expected interval 2, got %d", settings.HydrationReminders.IntervalHours)
	}
}

// TestSettings_FR_NUT_10_5_MissedMealNudge verifies missed meal nudge configuration.
func TestSettings_FR_NUT_10_5_MissedMealNudge(t *testing.T) {
	settings := DefaultNutritionSettings("u_test")

	patch := map[string]interface{}{
		"missedMealNudge": map[string]interface{}{
			"enabled":   true,
			"nudgeTime": "14:00",
		},
	}
	applySettingsPatch(settings, patch)

	if !settings.MissedMealNudge.Enabled {
		t.Error("expected missed meal nudge enabled")
	}
	if settings.MissedMealNudge.NudgeTime != "14:00" {
		t.Errorf("expected nudge time 14:00, got %s", settings.MissedMealNudge.NudgeTime)
	}
}

// TestSettings_FR_NUT_10_6_InsightPreferences verifies insight preferences for ED-sensitive users.
func TestSettings_FR_NUT_10_6_InsightPreferences(t *testing.T) {
	settings := DefaultNutritionSettings("u_test")

	// All should be enabled by default.
	if !settings.InsightPreferences.MealConsistencyEnabled {
		t.Error("expected mealConsistencyEnabled default true")
	}
	if !settings.InsightPreferences.EmotionalEatingEnabled {
		t.Error("expected emotionalEatingEnabled default true")
	}

	// Disable specific insight types.
	patch := map[string]interface{}{
		"insightPreferences": map[string]interface{}{
			"emotionalEatingEnabled": false,
			"crossDomainEnabled":     false,
		},
	}
	applySettingsPatch(settings, patch)

	if settings.InsightPreferences.EmotionalEatingEnabled {
		t.Error("expected emotionalEatingEnabled=false after patch")
	}
	if settings.InsightPreferences.CrossDomainEnabled {
		t.Error("expected crossDomainEnabled=false after patch")
	}
	// Unchanged fields should still be true.
	if !settings.InsightPreferences.MealConsistencyEnabled {
		t.Error("expected mealConsistencyEnabled still true")
	}
	if !settings.InsightPreferences.MindfulnessEnabled {
		t.Error("expected mindfulnessEnabled still true")
	}
}

// TestSettings_DefaultValues verifies all default values match the spec.
func TestSettings_DefaultValues(t *testing.T) {
	s := DefaultNutritionSettings("u_test")

	// Hydration defaults.
	if s.Hydration.ServingSizeOz != 8 {
		t.Errorf("expected default servingSizeOz=8, got %f", s.Hydration.ServingSizeOz)
	}
	if s.Hydration.DailyTargetServings != 8 {
		t.Errorf("expected default dailyTargetServings=8, got %d", s.Hydration.DailyTargetServings)
	}

	// Meal reminders default off.
	if s.MealReminders.Breakfast.Enabled || s.MealReminders.Lunch.Enabled || s.MealReminders.Dinner.Enabled {
		t.Error("expected all meal reminders disabled by default")
	}

	// Hydration reminders default off.
	if s.HydrationReminders.Enabled {
		t.Error("expected hydration reminders disabled by default")
	}

	// Missed meal nudge default off.
	if s.MissedMealNudge.Enabled {
		t.Error("expected missed meal nudge disabled by default")
	}
}
