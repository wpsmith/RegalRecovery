// internal/domain/nutrition/settings_merge.go
package nutrition

// applySettingsPatch applies a JSON Merge Patch (RFC 7396) to NutritionSettings.
// Only provided fields are updated; omitted fields are left unchanged.
func applySettingsPatch(settings *NutritionSettings, patch map[string]interface{}) {
	if hydration, ok := patch["hydration"].(map[string]interface{}); ok {
		if v, ok := hydration["servingSizeOz"].(float64); ok {
			settings.Hydration.ServingSizeOz = v
		}
		if v, ok := hydration["dailyTargetServings"].(float64); ok {
			settings.Hydration.DailyTargetServings = int(v)
		}
	}

	if reminders, ok := patch["mealReminders"].(map[string]interface{}); ok {
		if bk, ok := reminders["breakfast"].(map[string]interface{}); ok {
			applyReminderPatch(&settings.MealReminders.Breakfast, bk)
		}
		if ln, ok := reminders["lunch"].(map[string]interface{}); ok {
			applyReminderPatch(&settings.MealReminders.Lunch, ln)
		}
		if dn, ok := reminders["dinner"].(map[string]interface{}); ok {
			applyReminderPatch(&settings.MealReminders.Dinner, dn)
		}
	}

	if hr, ok := patch["hydrationReminders"].(map[string]interface{}); ok {
		if v, ok := hr["enabled"].(bool); ok {
			settings.HydrationReminders.Enabled = v
		}
		if v, ok := hr["intervalHours"].(float64); ok {
			settings.HydrationReminders.IntervalHours = int(v)
		}
	}

	if nudge, ok := patch["missedMealNudge"].(map[string]interface{}); ok {
		if v, ok := nudge["enabled"].(bool); ok {
			settings.MissedMealNudge.Enabled = v
		}
		if v, ok := nudge["nudgeTime"].(string); ok {
			settings.MissedMealNudge.NudgeTime = v
		}
	}

	if prefs, ok := patch["insightPreferences"].(map[string]interface{}); ok {
		if v, ok := prefs["mealConsistencyEnabled"].(bool); ok {
			settings.InsightPreferences.MealConsistencyEnabled = v
		}
		if v, ok := prefs["emotionalEatingEnabled"].(bool); ok {
			settings.InsightPreferences.EmotionalEatingEnabled = v
		}
		if v, ok := prefs["mindfulnessEnabled"].(bool); ok {
			settings.InsightPreferences.MindfulnessEnabled = v
		}
		if v, ok := prefs["crossDomainEnabled"].(bool); ok {
			settings.InsightPreferences.CrossDomainEnabled = v
		}
	}
}

func applyReminderPatch(setting *MealReminderSetting, patch map[string]interface{}) {
	if v, ok := patch["enabled"].(bool); ok {
		setting.Enabled = v
	}
	if v, ok := patch["time"].(string); ok {
		setting.Time = v
	}
}
