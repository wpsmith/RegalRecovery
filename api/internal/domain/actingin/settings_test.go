// internal/domain/actingin/settings_test.go
package actingin

import "testing"

// TestSettings_AC_AIB_010_DailyFrequency verifies that setting daily frequency
// with a time saves correctly.
//
// AC-AIB-010: Daily frequency with reminder time at 9:00 PM.
func TestSettings_AC_AIB_010_DailyFrequency(t *testing.T) {
	settings := DefaultSettings("user_001")
	freq := FrequencyDaily
	reminderTime := "21:00"

	req := &UpdateSettingsRequest{
		Frequency:    &freq,
		ReminderTime: &reminderTime,
	}

	_, err := ApplySettingsUpdate(settings, req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if settings.Frequency != FrequencyDaily {
		t.Errorf("expected daily frequency, got %s", settings.Frequency)
	}
	if settings.ReminderTime != "21:00" {
		t.Errorf("expected reminder time 21:00, got %s", settings.ReminderTime)
	}
}

// TestSettings_AC_AIB_011_WeeklyFrequency verifies that setting weekly frequency
// with a day saves correctly.
//
// AC-AIB-011: Weekly frequency with Sunday as check-in day.
func TestSettings_AC_AIB_011_WeeklyFrequency(t *testing.T) {
	settings := DefaultSettings("user_001")
	freq := FrequencyWeekly
	day := WeekdaySunday

	req := &UpdateSettingsRequest{
		Frequency:   &freq,
		ReminderDay: &day,
	}

	_, err := ApplySettingsUpdate(settings, req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if settings.Frequency != FrequencyWeekly {
		t.Errorf("expected weekly frequency, got %s", settings.Frequency)
	}
	if settings.ReminderDay != WeekdaySunday {
		t.Errorf("expected Sunday, got %s", settings.ReminderDay)
	}
}

// TestSettings_InvalidReminderTime_Rejected verifies that invalid time format
// returns a validation error.
func TestSettings_InvalidReminderTime_Rejected(t *testing.T) {
	settings := DefaultSettings("user_001")
	badTime := "25:00"

	req := &UpdateSettingsRequest{
		ReminderTime: &badTime,
	}

	_, err := ApplySettingsUpdate(settings, req)
	if err == nil {
		t.Fatal("expected validation error for invalid time format")
	}
	if err != ErrInvalidReminderTime {
		t.Errorf("expected ErrInvalidReminderTime, got %v", err)
	}
}

// TestSettings_DefaultValues verifies that new settings default to daily, 21:00, Sunday.
func TestSettings_DefaultValues(t *testing.T) {
	settings := DefaultSettings("user_001")

	if settings.Frequency != FrequencyDaily {
		t.Errorf("expected default frequency 'daily', got %s", settings.Frequency)
	}
	if settings.ReminderTime != "21:00" {
		t.Errorf("expected default reminder time '21:00', got %s", settings.ReminderTime)
	}
	if settings.ReminderDay != WeekdaySunday {
		t.Errorf("expected default reminder day 'sunday', got %s", settings.ReminderDay)
	}
	if settings.FirstUseCompleted {
		t.Error("expected firstUseCompleted to default to false")
	}
}

// TestSettings_FrequencyChangeDetected verifies that ApplySettingsUpdate returns
// frequencyChanged=true when the frequency changes.
func TestSettings_FrequencyChangeDetected(t *testing.T) {
	settings := DefaultSettings("user_001")
	freq := FrequencyWeekly

	req := &UpdateSettingsRequest{
		Frequency: &freq,
	}

	changed, err := ApplySettingsUpdate(settings, req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !changed {
		t.Error("expected frequencyChanged=true")
	}
}

// TestSettings_NoFrequencyChange verifies that ApplySettingsUpdate returns
// frequencyChanged=false when frequency stays the same.
func TestSettings_NoFrequencyChange(t *testing.T) {
	settings := DefaultSettings("user_001")
	freq := FrequencyDaily

	req := &UpdateSettingsRequest{
		Frequency: &freq,
	}

	changed, err := ApplySettingsUpdate(settings, req)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if changed {
		t.Error("expected frequencyChanged=false when frequency is the same")
	}
}

// TestSettings_InvalidFrequency_Rejected verifies that an invalid frequency
// value returns a validation error.
func TestSettings_InvalidFrequency_Rejected(t *testing.T) {
	settings := DefaultSettings("user_001")
	bad := Frequency("biweekly")

	req := &UpdateSettingsRequest{
		Frequency: &bad,
	}

	_, err := ApplySettingsUpdate(settings, req)
	if err == nil {
		t.Fatal("expected validation error for invalid frequency")
	}
	if err != ErrInvalidFrequency {
		t.Errorf("expected ErrInvalidFrequency, got %v", err)
	}
}

// TestSettings_ValidateSettings verifies full settings validation.
func TestSettings_ValidateSettings(t *testing.T) {
	s := DefaultSettings("user_001")
	err := ValidateSettings(s)
	if err != nil {
		t.Fatalf("default settings should be valid: %v", err)
	}

	s.ReminderTime = "bad"
	err = ValidateSettings(s)
	if err != ErrInvalidReminderTime {
		t.Errorf("expected ErrInvalidReminderTime, got %v", err)
	}
}
