// internal/domain/personcheckin/inactivity.go
package personcheckin

import (
	"fmt"
	"time"
)

// CheckInactivity evaluates whether any sub-type has exceeded its inactivity threshold.
// Returns a list of alerts for sub-types that have been inactive too long.
func CheckInactivity(settings *PersonCheckInSettings, lastCheckInDates map[CheckInType]*time.Time, now time.Time) []InactivityAlert {
	var alerts []InactivityAlert

	subTypes := []struct {
		checkInType CheckInType
		settings    SubTypeSettings
	}{
		{CheckInTypeSpouse, settings.Spouse},
		{CheckInTypeSponsor, settings.Sponsor},
		{CheckInTypeCounselorCoach, settings.CounselorCoach},
	}

	for _, st := range subTypes {
		alert := checkSubTypeInactivity(st.checkInType, st.settings, lastCheckInDates[st.checkInType], now)
		if alert != nil {
			alerts = append(alerts, *alert)
		}
	}

	return alerts
}

// checkSubTypeInactivity checks a single sub-type for inactivity.
func checkSubTypeInactivity(checkInType CheckInType, settings SubTypeSettings, lastCheckIn *time.Time, now time.Time) *InactivityAlert {
	// FR-PCI-9.4: No alert for unconfigured sub-type (no contact name set).
	if settings.ContactName == nil || *settings.ContactName == "" {
		return nil
	}

	threshold := settings.InactivityAlertDays
	if threshold <= 0 {
		return nil
	}

	// Calculate days since last check-in.
	var daysSince int
	if lastCheckIn == nil {
		// Never checked in — consider the user as inactive from the beginning.
		// Use a large number so we always alert.
		daysSince = threshold + 1
	} else {
		daysSince = daysBetween(*lastCheckIn, now)
	}

	if daysSince < threshold {
		return nil
	}

	message := generateInactivityMessage(checkInType, settings.ContactName, daysSince)

	return &InactivityAlert{
		CheckInType:          checkInType,
		ContactName:          settings.ContactName,
		DaysSinceLastCheckIn: daysSince,
		ThresholdDays:        threshold,
		Message:              message,
	}
}

// generateInactivityMessage creates a compassionate inactivity alert message.
func generateInactivityMessage(checkInType CheckInType, contactName *string, days int) string {
	name := "your support person"
	if contactName != nil && *contactName != "" {
		name = *contactName
	}

	switch checkInType {
	case CheckInTypeSpouse:
		return fmt.Sprintf("It's been %d days since you checked in with %s. How are things between you?", days, name)
	case CheckInTypeSponsor:
		return fmt.Sprintf("You haven't connected with your sponsor in %d days. Recovery works best when you stay connected.", days)
	case CheckInTypeCounselorCoach:
		return fmt.Sprintf("Consider reaching out to %s between sessions. You don't have to wait for your next appointment.", name)
	default:
		return fmt.Sprintf("It's been %d days since you checked in with %s.", days, name)
	}
}

// daysBetween calculates the number of complete days between two times.
func daysBetween(start, end time.Time) int {
	startDay := time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, start.Location())
	endDay := time.Date(end.Year(), end.Month(), end.Day(), 0, 0, 0, 0, end.Location())

	days := int(endDay.Sub(startDay).Hours() / 24)
	if days < 0 {
		return 0
	}
	return days
}
