// internal/domain/personcheckin/settings_test.go
package personcheckin

import "testing"

func TestPersonCheckInSettings_DefaultSpouseInactivityAlert3Days(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	if settings.Spouse.InactivityAlertDays != 3 {
		t.Fatalf("expected 3, got %d", settings.Spouse.InactivityAlertDays)
	}
}

func TestPersonCheckInSettings_DefaultSponsorInactivityAlert5Days(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	if settings.Sponsor.InactivityAlertDays != 5 {
		t.Fatalf("expected 5, got %d", settings.Sponsor.InactivityAlertDays)
	}
}

func TestPersonCheckInSettings_DefaultCounselorInactivityAlert10Days(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	if settings.CounselorCoach.InactivityAlertDays != 10 {
		t.Fatalf("expected 10, got %d", settings.CounselorCoach.InactivityAlertDays)
	}
}

func TestPersonCheckInSettings_DefaultCounselorStreakFrequencyWeekly(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	if settings.CounselorCoach.StreakFrequency != StreakFrequencyWeekly {
		t.Fatalf("expected weekly, got %s", settings.CounselorCoach.StreakFrequency)
	}
}

func TestPersonCheckInSettings_UpdateInactivityThreshold(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	newDays := 7
	update := &UpdateSettingsRequest{
		Sponsor: &SubTypeSettingsUpdate{
			InactivityAlertDays: &newDays,
		},
	}

	ApplySettingsUpdate(settings, update)

	if settings.Sponsor.InactivityAlertDays != 7 {
		t.Fatalf("expected 7, got %d", settings.Sponsor.InactivityAlertDays)
	}
}

func TestPersonCheckInSettings_UpdateStreakFrequency(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	newFreq := StreakFrequencyXPerWeek
	update := &UpdateSettingsRequest{
		Sponsor: &SubTypeSettingsUpdate{
			StreakFrequency: &newFreq,
		},
	}

	changed := ApplySettingsUpdate(settings, update)

	if !changed {
		t.Fatal("expected streak frequency change to return true")
	}
	if settings.Sponsor.StreakFrequency != StreakFrequencyXPerWeek {
		t.Fatalf("expected x-per-week, got %s", settings.Sponsor.StreakFrequency)
	}
}

func TestPersonCheckInSettings_RejectsInvalidStreakFrequency(t *testing.T) {
	badFreq := StreakFrequency("bi-monthly")
	req := &UpdateSettingsRequest{
		Spouse: &SubTypeSettingsUpdate{
			StreakFrequency: &badFreq,
		},
	}

	err := ValidateSettingsUpdate(req)
	if err == nil {
		t.Fatal("expected error for invalid streak frequency")
	}
}

func TestPersonCheckInSettings_RejectsInactivityAlertDaysOutOfRange(t *testing.T) {
	tests := []struct {
		name string
		days int
	}{
		{"zero", 0},
		{"negative", -1},
		{"too_high", 31},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			req := &UpdateSettingsRequest{
				Spouse: &SubTypeSettingsUpdate{
					InactivityAlertDays: &tt.days,
				},
			}
			err := ValidateSettingsUpdate(req)
			if err == nil {
				t.Fatal("expected error for out-of-range inactivity alert days")
			}
		})
	}
}

func TestPersonCheckInSettings_SavesLastUsedMethodOnCheckIn(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")

	UpdateLastUsedMethod(settings, CheckInTypeSponsor, MethodVideoCall)

	if settings.Sponsor.LastUsedMethod == nil || *settings.Sponsor.LastUsedMethod != MethodVideoCall {
		t.Fatal("expected last used method to be video-call")
	}
}
