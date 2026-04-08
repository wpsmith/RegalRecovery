// internal/domain/mood/alerts.go
package mood

import "time"

const (
	// SustainedLowMoodThreshold is the average rating at or below which a day is considered "low."
	SustainedLowMoodThreshold = 2.0

	// SustainedLowMoodDays is the number of consecutive low-mood days to trigger an alert.
	SustainedLowMoodDays = 3

	// CrisisRating is the rating value that triggers a crisis alert.
	CrisisRating = 1
)

// AlertStatus holds the current mood alert evaluation.
type AlertStatus struct {
	SustainedLowMood      bool          `json:"sustainedLowMood"`
	ConsecutiveLowDays    int           `json:"consecutiveLowDays"`
	LastCrisisEntry       *CrisisEntry  `json:"lastCrisisEntry"`
	AlertSharedWithNetwork bool         `json:"alertSharedWithNetwork"`
}

// CrisisEntry holds a reference to the most recent crisis mood entry.
type CrisisEntry struct {
	MoodID    string    `json:"moodId"`
	Timestamp time.Time `json:"timestamp"`
}

// EvaluateSustainedLowMood checks if daily averages indicate sustained low mood.
// dailyAverages should be ordered from most recent to oldest.
// Returns the count of consecutive low days (from most recent backwards)
// and whether the sustained low mood threshold is met.
func EvaluateSustainedLowMood(dailyAverages []float64) (int, bool) {
	consecutiveLow := 0
	for _, avg := range dailyAverages {
		if avg <= SustainedLowMoodThreshold {
			consecutiveLow++
		} else {
			break
		}
	}
	return consecutiveLow, consecutiveLow >= SustainedLowMoodDays
}

// IsCrisisEntry returns true if the rating indicates a crisis.
func IsCrisisEntry(rating int) bool {
	return rating == CrisisRating
}

// ShouldShareAlert determines whether a sustained low mood alert should be shared
// with the support network based on user preferences.
func ShouldShareAlert(sustainedLowMood bool, sharingEnabled bool) bool {
	return sustainedLowMood && sharingEnabled
}
