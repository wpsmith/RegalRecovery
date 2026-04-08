// internal/domain/mood/labels.go
package mood

// RatingLabel maps a numeric rating (1-5) to its human-readable label.
var RatingLabel = map[int]string{
	1: "Crisis",
	2: "Struggling",
	3: "Okay",
	4: "Good",
	5: "Great",
}

// LabelForRating returns the human-readable label for a rating value.
// Returns empty string for invalid ratings.
func LabelForRating(rating int) string {
	return RatingLabel[rating]
}

// ValidEmotionLabels is the predefined set of emotion labels.
var ValidEmotionLabels = map[string]bool{
	// Positive cluster
	"Peaceful":  true,
	"Grateful":  true,
	"Hopeful":   true,
	"Confident": true,
	"Connected": true,
	// Anxious cluster
	"Anxious":     true,
	"Lonely":      true,
	"Angry":       true,
	"Ashamed":     true,
	"Overwhelmed": true,
	// Low cluster
	"Sad":        true,
	"Numb":       true,
	"Restless":   true,
	"Afraid":     true,
	"Frustrated": true,
}

// AllEmotionLabels returns all valid emotion labels as a slice.
func AllEmotionLabels() []string {
	labels := make([]string, 0, len(ValidEmotionLabels))
	for label := range ValidEmotionLabels {
		labels = append(labels, label)
	}
	return labels
}

// ValidSources is the set of valid entry sources.
var ValidSources = map[string]bool{
	"direct":        true,
	"widget":        true,
	"post-activity": true,
	"notification":  true,
}

// ColorCode maps a daily average mood rating to a calendar color code.
//
//	green:  4.0-5.0 (Great/Good)
//	yellow: 3.0-3.9 (Okay)
//	orange: 2.0-2.9 (Struggling)
//	red:    1.0-1.9 (Crisis)
//	gray:   no data
func ColorCode(avgRating float64) string {
	switch {
	case avgRating >= 4.0:
		return "green"
	case avgRating >= 3.0:
		return "yellow"
	case avgRating >= 2.0:
		return "orange"
	case avgRating >= 1.0:
		return "red"
	default:
		return "gray"
	}
}
