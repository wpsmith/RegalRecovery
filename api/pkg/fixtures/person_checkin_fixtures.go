// pkg/fixtures/person_checkin_fixtures.go
package fixtures

import (
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/personcheckin"
)

// PersonCheckInFixtures contains test fixture data for person check-ins.
type PersonCheckInFixtures struct {
	SpouseCheckIns    []personcheckin.PersonCheckIn
	SponsorCheckIns   []personcheckin.PersonCheckIn
	CounselorCheckIns []personcheckin.PersonCheckIn
}

// AlexPersonCheckIns contains fixtures for Alex: married, has sponsor, has counselor.
var AlexPersonCheckIns = PersonCheckInFixtures{
	SpouseCheckIns:    generateDailyCheckIns(personcheckin.CheckInTypeSpouse, "Emily", 30, personcheckin.MethodInPerson, "u_alex"),
	SponsorCheckIns:   generateDailyCheckIns(personcheckin.CheckInTypeSponsor, "Mike S.", 30, personcheckin.MethodPhoneCall, "u_alex"),
	CounselorCheckIns: generateWeeklyCheckIns(personcheckin.CheckInTypeCounselorCoach, "Dr. Johnson", 12, personcheckin.MethodInPerson, "u_alex"),
}

// MarcusPersonCheckIns contains fixtures for Marcus: no spouse, no sponsor, only counselor.
var MarcusPersonCheckIns = PersonCheckInFixtures{
	SpouseCheckIns:    nil,
	SponsorCheckIns:   nil,
	CounselorCheckIns: generateWeeklyCheckIns(personcheckin.CheckInTypeCounselorCoach, "Dr. Williams", 8, personcheckin.MethodVideoCall, "u_marcus"),
}

// DiegoPersonCheckIns contains fixtures for Diego: married, has sponsor, no counselor.
var DiegoPersonCheckIns = PersonCheckInFixtures{
	SpouseCheckIns:    generateDailyCheckIns(personcheckin.CheckInTypeSpouse, "Maria", 14, personcheckin.MethodInPerson, "u_diego"),
	SponsorCheckIns:   generateDailyCheckIns(personcheckin.CheckInTypeSponsor, "Carlos", 14, personcheckin.MethodPhoneCall, "u_diego"),
	CounselorCheckIns: nil,
}

func generateDailyCheckIns(checkInType personcheckin.CheckInType, contactName string, days int, method personcheckin.Method, userID string) []personcheckin.PersonCheckIn {
	var checkIns []personcheckin.PersonCheckIn
	now := time.Now()

	for i := days; i >= 1; i-- {
		ts := now.AddDate(0, 0, -i)
		rating := 3 + (i % 3) // Varies between 3-5.
		checkIns = append(checkIns, personcheckin.PersonCheckIn{
			CheckInID:   fmt.Sprintf("pci_%s_%d", string(checkInType)[:2], i),
			UserID:      userID,
			TenantID:    "DEFAULT",
			CheckInType: checkInType,
			Method:      method,
			Timestamp:   ts,
			ContactName: &contactName,
			QualityRating: &rating,
			TopicsDiscussed: []personcheckin.Topic{
				personcheckin.TopicAccountability,
			},
			CreatedAt:  ts,
			ModifiedAt: ts,
		})
	}

	return checkIns
}

func generateWeeklyCheckIns(checkInType personcheckin.CheckInType, contactName string, weeks int, method personcheckin.Method, userID string) []personcheckin.PersonCheckIn {
	var checkIns []personcheckin.PersonCheckIn
	now := time.Now()

	for i := weeks; i >= 1; i-- {
		ts := now.AddDate(0, 0, -i*7)
		rating := 4
		checkIns = append(checkIns, personcheckin.PersonCheckIn{
			CheckInID:   fmt.Sprintf("pci_%s_%d", string(checkInType)[:2], i),
			UserID:      userID,
			TenantID:    "DEFAULT",
			CheckInType: checkInType,
			Method:      method,
			Timestamp:   ts,
			ContactName: &contactName,
			QualityRating: &rating,
			TopicsDiscussed: []personcheckin.Topic{
				personcheckin.TopicSobrietyRecovery,
				personcheckin.TopicStepWork,
			},
			CreatedAt:  ts,
			ModifiedAt: ts,
		})
	}

	return checkIns
}
