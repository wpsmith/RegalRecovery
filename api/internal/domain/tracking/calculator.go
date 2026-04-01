// internal/domain/tracking/calculator.go
package tracking

import (
	"time"
)

// Milestone thresholds in days.
var milestoneThresholds = []int{
	1, 3, 7, 14, 21, 30, 60, 90, 120, 180, 270, 365, 540, 730, 1095, 1460, 1825, 2555, 3650,
}

// Milestone labels.
var milestoneLabels = map[int]string{
	1:    "1 Day",
	3:    "3 Days",
	7:    "1 Week",
	14:   "2 Weeks",
	21:   "3 Weeks",
	30:   "1 Month",
	60:   "2 Months",
	90:   "3 Months",
	120:  "4 Months",
	180:  "6 Months",
	270:  "9 Months",
	365:  "1 Year",
	540:  "18 Months",
	730:  "2 Years",
	1095: "3 Years",
	1460: "4 Years",
	1825: "5 Years",
	2555: "7 Years",
	3650: "10 Years",
}

// Milestone scriptures for encouragement.
var milestoneScriptures = map[int]string{
	1:    "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here! - 2 Corinthians 5:17",
	3:    "The Lord is faithful, and he will strengthen you and protect you from the evil one. - 2 Thessalonians 3:3",
	7:    "I can do all this through him who gives me strength. - Philippians 4:13",
	14:   "The Lord himself goes before you and will be with you; he will never leave you nor forsake you. - Deuteronomy 31:8",
	21:   "But those who hope in the Lord will renew their strength. - Isaiah 40:31",
	30:   "Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds. - James 1:2",
	60:   "No temptation has overtaken you except what is common to mankind. And God is faithful. - 1 Corinthians 10:13",
	90:   "Being confident of this, that he who began a good work in you will carry it on to completion. - Philippians 1:6",
	120:  "Therefore, my dear brothers and sisters, stand firm. Let nothing move you. - 1 Corinthians 15:58",
	180:  "The one who is in you is greater than the one who is in the world. - 1 John 4:4",
	270:  "Do not conform to the pattern of this world, but be transformed by the renewing of your mind. - Romans 12:2",
	365:  "His divine power has given us everything we need for a godly life. - 2 Peter 1:3",
	540:  "I have fought the good fight, I have finished the race, I have kept the faith. - 2 Timothy 4:7",
	730:  "The Lord is my strength and my shield; my heart trusts in him, and he helps me. - Psalm 28:7",
	1095: "Therefore we do not lose heart. Though outwardly we are wasting away, yet inwardly we are being renewed day by day. - 2 Corinthians 4:16",
	1460: "And we know that in all things God works for the good of those who love him. - Romans 8:28",
	1825: "He has made everything beautiful in its time. - Ecclesiastes 3:11",
	2555: "Great is his faithfulness; his mercies begin afresh each morning. - Lamentations 3:23",
	3650: "Well done, good and faithful servant! You have been faithful with a few things; I will put you in charge of many things. - Matthew 25:23",
}

// CalculateStreakDays calculates the number of sober days between sobriety start date and now.
func CalculateStreakDays(sobrietyDate time.Time, now time.Time) int {
	// Normalize both times to start of day in the same location.
	start := time.Date(sobrietyDate.Year(), sobrietyDate.Month(), sobrietyDate.Day(), 0, 0, 0, 0, sobrietyDate.Location())
	end := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())

	// Calculate the difference in days.
	duration := end.Sub(start)
	days := int(duration.Hours() / 24)

	// If the streak started today, it's day 0 (not yet a full day).
	// Otherwise, the number of complete days.
	if days < 0 {
		return 0
	}

	return days
}

// NextMilestone returns the next milestone threshold after the current days count.
// Returns 0 if there are no more milestones.
func NextMilestone(currentDays int) int {
	for _, threshold := range milestoneThresholds {
		if threshold > currentDays {
			return threshold
		}
	}
	return 0
}

// MilestoneLabel returns the label for a milestone threshold.
func MilestoneLabel(days int) string {
	if label, exists := milestoneLabels[days]; exists {
		return label
	}
	return ""
}

// MilestoneScripture returns the scripture for a milestone threshold.
func MilestoneScripture(days int) string {
	if scripture, exists := milestoneScriptures[days]; exists {
		return scripture
	}
	return ""
}

// IsMilestone checks if a given day count is a milestone.
func IsMilestone(days int) bool {
	for _, threshold := range milestoneThresholds {
		if threshold == days {
			return true
		}
	}
	return false
}

// GetAllMilestones returns all milestone thresholds.
func GetAllMilestones() []int {
	result := make([]int, len(milestoneThresholds))
	copy(result, milestoneThresholds)
	return result
}

// CalculateSoberDaysInRange calculates the number of sober days in a date range
// based on relapse history.
func CalculateSoberDaysInRange(startDate, endDate time.Time, relapses []time.Time) int {
	// Normalize dates to start of day.
	start := time.Date(startDate.Year(), startDate.Month(), startDate.Day(), 0, 0, 0, 0, startDate.Location())
	end := time.Date(endDate.Year(), endDate.Month(), endDate.Day(), 0, 0, 0, 0, endDate.Location())

	totalDays := int(end.Sub(start).Hours()/24) + 1
	relapseDays := 0

	// Count days with relapses.
	for _, relapse := range relapses {
		relapseDay := time.Date(relapse.Year(), relapse.Month(), relapse.Day(), 0, 0, 0, 0, relapse.Location())
		if (relapseDay.Equal(start) || relapseDay.After(start)) && (relapseDay.Equal(end) || relapseDay.Before(end)) {
			relapseDays++
		}
	}

	soberDays := totalDays - relapseDays
	if soberDays < 0 {
		return 0
	}

	return soberDays
}
