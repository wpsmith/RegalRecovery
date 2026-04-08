// internal/domain/personcheckin/settings.go
package personcheckin

import "time"

// DefaultSettings returns the default settings for a new user.
func DefaultSettings(userID, tenantID string) *PersonCheckInSettings {
	now := time.Now()
	return &PersonCheckInSettings{
		UserID:   userID,
		TenantID: tenantID,
		Spouse: SubTypeSettings{
			StreakFrequency:     StreakFrequencyDaily,
			InactivityAlertDays: 3,
			ReminderEnabled:     false,
		},
		Sponsor: SubTypeSettings{
			StreakFrequency:     StreakFrequencyDaily,
			InactivityAlertDays: 5,
			ReminderEnabled:     false,
		},
		CounselorCoach: SubTypeSettings{
			StreakFrequency:     StreakFrequencyWeekly,
			InactivityAlertDays: 10,
			ReminderEnabled:     false,
		},
		CreatedAt:  now,
		ModifiedAt: now,
	}
}

// ApplySettingsUpdate merges partial updates into existing settings.
// Returns true if streak frequency changed for any sub-type (triggering recalculation).
func ApplySettingsUpdate(settings *PersonCheckInSettings, update *UpdateSettingsRequest) bool {
	streakFrequencyChanged := false

	if update.Spouse != nil {
		if applySubTypeUpdate(&settings.Spouse, update.Spouse) {
			streakFrequencyChanged = true
		}
	}

	if update.Sponsor != nil {
		if applySubTypeUpdate(&settings.Sponsor, update.Sponsor) {
			streakFrequencyChanged = true
		}
	}

	if update.CounselorCoach != nil {
		if applySubTypeUpdate(&settings.CounselorCoach, update.CounselorCoach) {
			streakFrequencyChanged = true
		}
	}

	settings.ModifiedAt = time.Now()
	return streakFrequencyChanged
}

// applySubTypeUpdate merges partial updates into a sub-type settings.
// Returns true if streak frequency was changed.
func applySubTypeUpdate(settings *SubTypeSettings, update *SubTypeSettingsUpdate) bool {
	freqChanged := false

	if update.ContactName != nil {
		settings.ContactName = update.ContactName
	}

	if update.StreakFrequency != nil && *update.StreakFrequency != settings.StreakFrequency {
		settings.StreakFrequency = *update.StreakFrequency
		freqChanged = true
	}

	if update.RequiredCountPerWeek != nil {
		settings.RequiredCountPerWeek = update.RequiredCountPerWeek
	}

	if update.InactivityAlertDays != nil {
		settings.InactivityAlertDays = *update.InactivityAlertDays
	}

	if update.ReminderEnabled != nil {
		settings.ReminderEnabled = *update.ReminderEnabled
	}

	if update.ReminderTime != nil {
		settings.ReminderTime = update.ReminderTime
	}

	if update.ReminderFrequency != nil {
		settings.ReminderFrequency = update.ReminderFrequency
	}

	return freqChanged
}

// GetSubTypeSettings returns the settings for a specific sub-type.
func GetSubTypeSettings(settings *PersonCheckInSettings, checkInType CheckInType) *SubTypeSettings {
	switch checkInType {
	case CheckInTypeSpouse:
		return &settings.Spouse
	case CheckInTypeSponsor:
		return &settings.Sponsor
	case CheckInTypeCounselorCoach:
		return &settings.CounselorCoach
	default:
		return nil
	}
}

// UpdateLastUsedMethod updates the last used method for a sub-type in settings.
func UpdateLastUsedMethod(settings *PersonCheckInSettings, checkInType CheckInType, method Method) {
	subSettings := GetSubTypeSettings(settings, checkInType)
	if subSettings != nil {
		subSettings.LastUsedMethod = &method
	}
}
