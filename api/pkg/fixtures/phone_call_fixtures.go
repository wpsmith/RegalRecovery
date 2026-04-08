// pkg/fixtures/phone_call_fixtures.go
package fixtures

import (
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/phonecalls"
)

// PhoneCallTestData holds test data for phone call scenarios.
type PhoneCallTestData struct {
	PersonaName              string
	Calls                    []phonecalls.PhoneCall
	SavedContacts            []phonecalls.SavedContact
	ExpectedStreakDays       int
	ExpectedIsolationWarning bool
}

// AlexPhoneCallScenario represents a user with regular call activity.
var AlexPhoneCallScenario = PhoneCallTestData{
	PersonaName: "Alex",
	Calls: []phonecalls.PhoneCall{
		{
			CallID:      "pc_alex_001",
			UserID:      "u_alex",
			TenantID:    "DEFAULT",
			Direction:   phonecalls.DirectionMade,
			ContactType: phonecalls.ContactTypeSponsor,
			Connected:   true,
			DurationMinutes: intPtr(15),
			ContactName: strPtr("Mike S."),
			Timestamp:   time.Now().Add(-1 * time.Hour),
			CreatedAt:   time.Now().Add(-1 * time.Hour),
			ModifiedAt:  time.Now().Add(-1 * time.Hour),
		},
		{
			CallID:      "pc_alex_002",
			UserID:      "u_alex",
			TenantID:    "DEFAULT",
			Direction:   phonecalls.DirectionMade,
			ContactType: phonecalls.ContactTypeAccountabilityPartner,
			Connected:   true,
			DurationMinutes: intPtr(10),
			ContactName: strPtr("James R."),
			Timestamp:   time.Now().Add(-25 * time.Hour),
			CreatedAt:   time.Now().Add(-25 * time.Hour),
			ModifiedAt:  time.Now().Add(-25 * time.Hour),
		},
		{
			CallID:      "pc_alex_003",
			UserID:      "u_alex",
			TenantID:    "DEFAULT",
			Direction:   phonecalls.DirectionReceived,
			ContactType: phonecalls.ContactTypeCounselor,
			Connected:   true,
			DurationMinutes: intPtr(30),
			Timestamp:   time.Now().Add(-49 * time.Hour),
			CreatedAt:   time.Now().Add(-49 * time.Hour),
			ModifiedAt:  time.Now().Add(-49 * time.Hour),
		},
	},
	SavedContacts: []phonecalls.SavedContact{
		{
			SavedContactID: "sc_alex_001",
			UserID:         "u_alex",
			TenantID:       "DEFAULT",
			ContactName:    "Mike S.",
			ContactType:    phonecalls.ContactTypeSponsor,
			PhoneNumber:    strPtr("+15551234567"),
			HasPhoneNumber: true,
		},
		{
			SavedContactID: "sc_alex_002",
			UserID:         "u_alex",
			TenantID:       "DEFAULT",
			ContactName:    "James R.",
			ContactType:    phonecalls.ContactTypeAccountabilityPartner,
			PhoneNumber:    strPtr("+15559876543"),
			HasPhoneNumber: true,
		},
	},
	ExpectedStreakDays:       3,
	ExpectedIsolationWarning: false,
}

// MarcusIsolationScenario represents a user with no recent call activity.
var MarcusIsolationScenario = PhoneCallTestData{
	PersonaName:              "Marcus",
	Calls:                    []phonecalls.PhoneCall{},
	SavedContacts:            []phonecalls.SavedContact{},
	ExpectedStreakDays:       0,
	ExpectedIsolationWarning: true,
}

// DiegoHighVolumeScenario represents a user with consistently high call volume.
var DiegoHighVolumeScenario = PhoneCallTestData{
	PersonaName:              "Diego",
	Calls:                    generateDailyCallsForDays(90),
	ExpectedStreakDays:       90,
	ExpectedIsolationWarning: false,
	SavedContacts: []phonecalls.SavedContact{
		{
			SavedContactID: "sc_diego_001",
			UserID:         "u_diego",
			TenantID:       "DEFAULT",
			ContactName:    "Carlos M.",
			ContactType:    phonecalls.ContactTypeSponsor,
			PhoneNumber:    strPtr("+525551234567"),
			HasPhoneNumber: true,
		},
	},
}

// generateDailyCallsForDays creates 1-3 calls per day for the given number of days.
func generateDailyCallsForDays(days int) []phonecalls.PhoneCall {
	calls := make([]phonecalls.PhoneCall, 0, days*2)
	now := time.Now().UTC()

	contactTypes := []phonecalls.ContactType{
		phonecalls.ContactTypeSponsor,
		phonecalls.ContactTypeAccountabilityPartner,
		phonecalls.ContactTypeCounselor,
	}

	for i := 0; i < days; i++ {
		dayStart := now.AddDate(0, 0, -i).Truncate(24 * time.Hour).Add(10 * time.Hour)
		callsPerDay := (i % 3) + 1 // 1, 2, or 3 calls per day

		for j := 0; j < callsPerDay; j++ {
			callTime := dayStart.Add(time.Duration(j*3) * time.Hour)
			ct := contactTypes[(i+j)%len(contactTypes)]

			calls = append(calls, phonecalls.PhoneCall{
				CallID:          fmt.Sprintf("pc_diego_%d_%d", i, j),
				UserID:          "u_diego",
				TenantID:        "DEFAULT",
				Direction:       phonecalls.DirectionMade,
				ContactType:     ct,
				Connected:       (i+j)%5 != 0, // 80% connected
				DurationMinutes: intPtr(10 + (i % 20)),
				Timestamp:       callTime,
				CreatedAt:       callTime,
				ModifiedAt:      callTime,
			})
		}
	}

	return calls
}

func strPtr(s string) *string { return &s }
func intPtr(i int) *int       { return &i }
