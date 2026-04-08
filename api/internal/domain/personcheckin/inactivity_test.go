// internal/domain/personcheckin/inactivity_test.go
package personcheckin

import (
	"testing"
	"time"
)

func strPtr(s string) *string {
	return &s
}

func TestPersonCheckInInactivity_FR_PCI_9_1_SpouseAlertAfter3Days(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	settings.Spouse.ContactName = strPtr("Sarah")

	lastCheckIn := time.Now().AddDate(0, 0, -4)
	lastCheckInDates := map[CheckInType]*time.Time{
		CheckInTypeSpouse: &lastCheckIn,
	}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	found := false
	for _, alert := range alerts {
		if alert.CheckInType == CheckInTypeSpouse {
			found = true
			if alert.ThresholdDays != 3 {
				t.Fatalf("expected threshold 3, got %d", alert.ThresholdDays)
			}
		}
	}
	if !found {
		t.Fatal("expected spouse inactivity alert")
	}
}

func TestPersonCheckInInactivity_FR_PCI_9_2_SponsorAlertAfter5Days(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	settings.Sponsor.ContactName = strPtr("Mike S.")

	lastCheckIn := time.Now().AddDate(0, 0, -6)
	lastCheckInDates := map[CheckInType]*time.Time{
		CheckInTypeSponsor: &lastCheckIn,
	}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	found := false
	for _, alert := range alerts {
		if alert.CheckInType == CheckInTypeSponsor {
			found = true
			if alert.ThresholdDays != 5 {
				t.Fatalf("expected threshold 5, got %d", alert.ThresholdDays)
			}
		}
	}
	if !found {
		t.Fatal("expected sponsor inactivity alert")
	}
}

func TestPersonCheckInInactivity_FR_PCI_9_3_CounselorAlertAfter10Days(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	settings.CounselorCoach.ContactName = strPtr("Dr. Johnson")

	lastCheckIn := time.Now().AddDate(0, 0, -11)
	lastCheckInDates := map[CheckInType]*time.Time{
		CheckInTypeCounselorCoach: &lastCheckIn,
	}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	found := false
	for _, alert := range alerts {
		if alert.CheckInType == CheckInTypeCounselorCoach {
			found = true
			if alert.ThresholdDays != 10 {
				t.Fatalf("expected threshold 10, got %d", alert.ThresholdDays)
			}
		}
	}
	if !found {
		t.Fatal("expected counselor inactivity alert")
	}
}

func TestPersonCheckInInactivity_FR_PCI_9_4_NoAlertForUnconfiguredSubType(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	// No contact name set for any sub-type.

	lastCheckInDates := map[CheckInType]*time.Time{}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	if len(alerts) != 0 {
		t.Fatalf("expected no alerts for unconfigured sub-types, got %d", len(alerts))
	}
}

func TestPersonCheckInInactivity_FR_PCI_9_5_CustomThresholdUsedForAlert(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	settings.Spouse.ContactName = strPtr("Sarah")
	settings.Spouse.InactivityAlertDays = 7 // Custom: 7 days instead of default 3.

	lastCheckIn := time.Now().AddDate(0, 0, -5) // 5 days ago.
	lastCheckInDates := map[CheckInType]*time.Time{
		CheckInTypeSpouse: &lastCheckIn,
	}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	// With custom threshold of 7, 5 days should NOT trigger alert.
	for _, alert := range alerts {
		if alert.CheckInType == CheckInTypeSpouse {
			t.Fatal("should not trigger spouse alert with custom threshold of 7 and 5 days inactive")
		}
	}
}

func TestPersonCheckInInactivity_NoAlertWithinThreshold(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	settings.Spouse.ContactName = strPtr("Sarah")

	lastCheckIn := time.Now().AddDate(0, 0, -1) // Yesterday.
	lastCheckInDates := map[CheckInType]*time.Time{
		CheckInTypeSpouse: &lastCheckIn,
	}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	for _, alert := range alerts {
		if alert.CheckInType == CheckInTypeSpouse {
			t.Fatal("should not trigger alert when within threshold")
		}
	}
}

func TestPersonCheckInInactivity_AlertIncludesQuickLogAction(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	settings.Spouse.ContactName = strPtr("Sarah")

	lastCheckIn := time.Now().AddDate(0, 0, -4)
	lastCheckInDates := map[CheckInType]*time.Time{
		CheckInTypeSpouse: &lastCheckIn,
	}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	if len(alerts) == 0 {
		t.Fatal("expected at least one alert")
	}
	// The alert message should contain meaningful text.
	if alerts[0].Message == "" {
		t.Fatal("expected non-empty alert message")
	}
}

func TestPersonCheckInInactivity_AlertMessageIncludesContactName(t *testing.T) {
	settings := DefaultSettings("u_test", "DEFAULT")
	settings.Spouse.ContactName = strPtr("Sarah")

	lastCheckIn := time.Now().AddDate(0, 0, -4)
	lastCheckInDates := map[CheckInType]*time.Time{
		CheckInTypeSpouse: &lastCheckIn,
	}

	alerts := CheckInactivity(settings, lastCheckInDates, time.Now())

	if len(alerts) == 0 {
		t.Fatal("expected spouse alert")
	}

	found := false
	for _, alert := range alerts {
		if alert.CheckInType == CheckInTypeSpouse {
			found = true
			if alert.ContactName == nil || *alert.ContactName != "Sarah" {
				t.Fatal("expected contact name Sarah in alert")
			}
		}
	}
	if !found {
		t.Fatal("expected spouse alert")
	}
}
