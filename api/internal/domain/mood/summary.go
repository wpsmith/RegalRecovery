// internal/domain/mood/summary.go
package mood

// DailySummary holds aggregated mood data for a single day.
type DailySummary struct {
	Date          string  `json:"date"`
	AverageRating float64 `json:"averageRating"`
	ColorCode     string  `json:"colorCode"`
	EntryCount    int     `json:"entryCount"`
	HighestRating int     `json:"highestRating"`
	LowestRating  int     `json:"lowestRating"`
}

// MoodDaySummary holds today's summary statistics.
type MoodDaySummary struct {
	AverageRating float64 `json:"averageRating"`
	AverageLabel  string  `json:"averageLabel"`
	HighestRating int     `json:"highestRating"`
	LowestRating  int     `json:"lowestRating"`
	EntryCount    int     `json:"entryCount"`
}

// YesterdayComparison holds comparison data with yesterday.
type YesterdayComparison struct {
	AverageRating  float64 `json:"averageRating"`
	TimeOfDayRating *int   `json:"timeOfDayRating"`
	TimeOfDayLabel  *string `json:"timeOfDayLabel"`
}

// ComputeDailySummary computes a daily summary from a set of mood entries.
// Returns nil summary if entries is empty.
func ComputeDailySummary(date string, entries []MoodEntry) *DailySummary {
	if len(entries) == 0 {
		return &DailySummary{
			Date:      date,
			ColorCode: "gray",
		}
	}

	sum := 0
	highest := entries[0].Rating
	lowest := entries[0].Rating

	for _, e := range entries {
		sum += e.Rating
		if e.Rating > highest {
			highest = e.Rating
		}
		if e.Rating < lowest {
			lowest = e.Rating
		}
	}

	avg := float64(sum) / float64(len(entries))

	return &DailySummary{
		Date:          date,
		AverageRating: avg,
		ColorCode:     ColorCode(avg),
		EntryCount:    len(entries),
		HighestRating: highest,
		LowestRating:  lowest,
	}
}

// ComputeTodaySummary computes today's summary including the average label.
// Returns nil if there are no entries.
func ComputeTodaySummary(entries []MoodEntry) *MoodDaySummary {
	if len(entries) == 0 {
		return nil
	}

	sum := 0
	highest := entries[0].Rating
	lowest := entries[0].Rating

	for _, e := range entries {
		sum += e.Rating
		if e.Rating > highest {
			highest = e.Rating
		}
		if e.Rating < lowest {
			lowest = e.Rating
		}
	}

	avg := float64(sum) / float64(len(entries))

	// Map average to the nearest label
	avgLabel := labelForAverage(avg)

	return &MoodDaySummary{
		AverageRating: avg,
		AverageLabel:  avgLabel,
		HighestRating: highest,
		LowestRating:  lowest,
		EntryCount:    len(entries),
	}
}

// labelForAverage maps a float average to the nearest rating label.
func labelForAverage(avg float64) string {
	switch {
	case avg >= 4.5:
		return "Great"
	case avg >= 3.5:
		return "Good"
	case avg >= 2.5:
		return "Okay"
	case avg >= 1.5:
		return "Struggling"
	default:
		return "Crisis"
	}
}
