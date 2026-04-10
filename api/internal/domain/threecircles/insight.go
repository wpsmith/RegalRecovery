// internal/domain/threecircles/insight.go
package threecircles

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

const (
	// MinDataDaysForInsights is the minimum number of days required for insight generation (14).
	MinDataDaysForInsights = 14

	// MaxInsightsReturned is the maximum number of insights to return (top 3).
	MaxInsightsReturned = 3

	// MinConfidenceThreshold is the minimum confidence score for an insight to be returned (0.6).
	MinConfidenceThreshold = 0.6
)

// InsightEngine generates pattern insights from Three Circles data.
type InsightEngine struct{}

// NewInsightEngine creates a new InsightEngine instance.
func NewInsightEngine() *InsightEngine {
	return &InsightEngine{}
}

// GenerateInsights analyzes timeline entries and generates actionable insights.
// Requires minimum 14 days of data.
func (ie *InsightEngine) GenerateInsights(
	ctx context.Context,
	entries []TimelineEntry,
	currentTime time.Time,
) ([]PatternInsight, error) {
	if len(entries) < MinDataDaysForInsights {
		return nil, ErrInsufficientData
	}

	insights := make([]PatternInsight, 0)

	// Calculate data window
	dataWindowStart, dataWindowEnd := ie.calculateDataWindow(entries)

	// Generate day-of-week insights
	dayOfWeekInsights := ie.generateDayOfWeekInsights(entries, dataWindowStart, dataWindowEnd)
	insights = append(insights, dayOfWeekInsights...)

	// Generate time-of-day insights (if timestamp data available)
	timeOfDayInsights := ie.generateTimeOfDayInsights(entries, dataWindowStart, dataWindowEnd)
	insights = append(insights, timeOfDayInsights...)

	// Generate mood correlation insights
	moodInsights := ie.generateMoodInsights(entries, dataWindowStart, dataWindowEnd)
	insights = append(insights, moodInsights...)

	// Generate urge intensity correlation insights
	urgeInsights := ie.generateUrgeInsights(entries, dataWindowStart, dataWindowEnd)
	insights = append(insights, urgeInsights...)

	// Filter by confidence threshold and apply shaming filter
	filteredInsights := ie.filterInsights(insights)

	// Return top N insights sorted by confidence
	return ie.selectTopInsights(filteredInsights, MaxInsightsReturned), nil
}

// calculateDataWindow determines the start and end dates from the entries.
func (ie *InsightEngine) calculateDataWindow(entries []TimelineEntry) (string, string) {
	if len(entries) == 0 {
		return "", ""
	}

	sorted := sortEntriesByDate(entries, false) // Oldest first
	return sorted[0].Date, sorted[len(sorted)-1].Date
}

// generateDayOfWeekInsights detects patterns by day of week.
func (ie *InsightEngine) generateDayOfWeekInsights(entries []TimelineEntry, dataWindowStart, dataWindowEnd string) []PatternInsight {
	insights := make([]PatternInsight, 0)

	// Count middle/inner circle days by day of week
	dayOfWeekCounts := make(map[time.Weekday]int)
	totalCountsByDay := make(map[time.Weekday]int)

	for _, entry := range entries {
		date, err := time.Parse("2006-01-02", entry.Date)
		if err != nil {
			continue
		}

		weekday := date.Weekday()
		totalCountsByDay[weekday]++

		if entry.DominantCircle == CircleMiddle || entry.DominantCircle == CircleInner {
			dayOfWeekCounts[weekday]++
		}
	}

	// Find days with significantly higher middle/inner contact
	for weekday, count := range dayOfWeekCounts {
		total := totalCountsByDay[weekday]
		if total < 2 {
			continue // Not enough data for this day
		}

		rate := float64(count) / float64(total)
		if rate >= 0.5 { // 50% or more
			confidence := ie.calculateConfidence(count, total)

			insight := PatternInsight{
				ID:               uuid.New().String(),
				InsightType:      InsightDayOfWeek,
				Description:      fmt.Sprintf("You tend to contact your middle or inner circle more on %ss.", weekday.String()),
				ActionSuggestion: fmt.Sprintf("Consider adding extra accountability or protective activities on %ss.", weekday.String()),
				Confidence:       confidence,
				DataWindowStart:  dataWindowStart,
				DataWindowEnd:    dataWindowEnd,
				Dismissed:        false,
			}

			insights = append(insights, insight)
		}
	}

	return insights
}

// generateTimeOfDayInsights detects patterns by time of day (placeholder).
// This would require timestamp data from check-ins.
func (ie *InsightEngine) generateTimeOfDayInsights(entries []TimelineEntry, dataWindowStart, dataWindowEnd string) []PatternInsight {
	// Placeholder: In a real implementation, this would analyze check-in timestamps
	// to detect morning vs. evening patterns.
	return []PatternInsight{}
}

// generateMoodInsights detects correlations between mood and circle contact.
func (ie *InsightEngine) generateMoodInsights(entries []TimelineEntry, dataWindowStart, dataWindowEnd string) []PatternInsight {
	insights := make([]PatternInsight, 0)

	// Calculate average mood for middle/inner circle days vs. outer circle days
	middleInnerMoodSum := 0
	middleInnerMoodCount := 0
	outerMoodSum := 0
	outerMoodCount := 0

	for _, entry := range entries {
		if entry.MoodScore == 0 {
			continue // No mood data
		}

		if entry.DominantCircle == CircleMiddle || entry.DominantCircle == CircleInner {
			middleInnerMoodSum += entry.MoodScore
			middleInnerMoodCount++
		} else if entry.DominantCircle == CircleOuter {
			outerMoodSum += entry.MoodScore
			outerMoodCount++
		}
	}

	if middleInnerMoodCount >= 3 && outerMoodCount >= 3 {
		avgMiddleInnerMood := float64(middleInnerMoodSum) / float64(middleInnerMoodCount)
		avgOuterMood := float64(outerMoodSum) / float64(outerMoodCount)

		// Detect if low mood correlates with middle/inner circle contact
		if avgMiddleInnerMood < avgOuterMood-1.5 {
			confidence := ie.calculateConfidence(middleInnerMoodCount, middleInnerMoodCount+outerMoodCount)

			insight := PatternInsight{
				ID:               uuid.New().String(),
				InsightType:      InsightProtective,
				Description:      "Lower mood scores tend to occur on days you contact your middle or inner circle.",
				ActionSuggestion: "When you notice your mood dropping, that might be a signal to review your Three Circles and reach out to support.",
				Confidence:       confidence,
				DataWindowStart:  dataWindowStart,
				DataWindowEnd:    dataWindowEnd,
				Dismissed:        false,
			}

			insights = append(insights, insight)
		}
	}

	return insights
}

// generateUrgeInsights detects correlations between urge intensity and circle contact.
func (ie *InsightEngine) generateUrgeInsights(entries []TimelineEntry, dataWindowStart, dataWindowEnd string) []PatternInsight {
	insights := make([]PatternInsight, 0)

	// Calculate average urge intensity for middle/inner circle days vs. outer circle days
	middleInnerUrgeSum := 0
	middleInnerUrgeCount := 0
	outerUrgeSum := 0
	outerUrgeCount := 0

	for _, entry := range entries {
		if entry.UrgeIntensity == 0 {
			continue // No urge data
		}

		if entry.DominantCircle == CircleMiddle || entry.DominantCircle == CircleInner {
			middleInnerUrgeSum += entry.UrgeIntensity
			middleInnerUrgeCount++
		} else if entry.DominantCircle == CircleOuter {
			outerUrgeSum += entry.UrgeIntensity
			outerUrgeCount++
		}
	}

	if middleInnerUrgeCount >= 3 && outerUrgeCount >= 3 {
		avgMiddleInnerUrge := float64(middleInnerUrgeSum) / float64(middleInnerUrgeCount)
		avgOuterUrge := float64(outerUrgeSum) / float64(outerUrgeCount)

		// Detect if high urge intensity correlates with middle/inner circle contact
		if avgMiddleInnerUrge > avgOuterUrge+1.5 {
			confidence := ie.calculateConfidence(middleInnerUrgeCount, middleInnerUrgeCount+outerUrgeCount)

			insight := PatternInsight{
				ID:               uuid.New().String(),
				InsightType:      InsightTrigger,
				Description:      "Higher urge intensity tends to occur on days you contact your middle or inner circle.",
				ActionSuggestion: "When urges spike, consider reviewing your relapse prevention plan and calling an accountability partner.",
				Confidence:       confidence,
				DataWindowStart:  dataWindowStart,
				DataWindowEnd:    dataWindowEnd,
				Dismissed:        false,
			}

			insights = append(insights, insight)
		}
	}

	return insights
}

// calculateConfidence computes a confidence score based on sample size and rate.
func (ie *InsightEngine) calculateConfidence(observedCount, totalCount int) float64 {
	if totalCount == 0 {
		return 0.0
	}

	// Simple confidence calculation based on sample size
	// More observations = higher confidence
	baseLine := 0.6
	sampleBonus := float64(observedCount) / float64(MinDataDaysForInsights*2) * 0.3

	confidence := baseLine + sampleBonus
	if confidence > 1.0 {
		confidence = 1.0
	}

	return confidence
}

// filterInsights removes insights below confidence threshold and applies shaming filter.
func (ie *InsightEngine) filterInsights(insights []PatternInsight) []PatternInsight {
	filtered := make([]PatternInsight, 0)

	for _, insight := range insights {
		// Check confidence threshold
		if insight.Confidence < MinConfidenceThreshold {
			continue
		}

		// Apply shaming filter (reject insights with personal names/relationships)
		// In a real implementation, this would use NLP to detect personal references
		// For now, we assume descriptions are generated without personal identifiers

		filtered = append(filtered, insight)
	}

	return filtered
}

// selectTopInsights returns the top N insights sorted by confidence.
func (ie *InsightEngine) selectTopInsights(insights []PatternInsight, topN int) []PatternInsight {
	if len(insights) <= topN {
		return insights
	}

	// Simple bubble sort by confidence descending
	sorted := make([]PatternInsight, len(insights))
	copy(sorted, insights)

	for i := 0; i < len(sorted)-1; i++ {
		for j := i + 1; j < len(sorted); j++ {
			if sorted[i].Confidence < sorted[j].Confidence {
				sorted[i], sorted[j] = sorted[j], sorted[i]
			}
		}
	}

	return sorted[:topN]
}
