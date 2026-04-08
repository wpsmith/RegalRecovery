// internal/domain/postmortem/insights.go
package postmortem

import (
	"math"
	"sort"
	"strings"
)

// MinAnalysesForInsights is the minimum number of completed analyses needed for insights.
const MinAnalysesForInsights = 2

// ComputeInsights computes cross-analysis pattern insights from multiple post-mortems.
func ComputeInsights(analyses []*PostMortemAnalysis) *PostMortemInsights {
	insights := &PostMortemInsights{
		TotalAnalyses: len(analyses),
	}

	if len(analyses) < MinAnalysesForInsights {
		return insights
	}

	insights.CommonTriggers = computeCommonTriggers(analyses)
	insights.CommonFasterStageAtBreak = computeCommonFasterStageAtBreak(analyses)
	insights.CommonTimeOfDay = computeCommonTimeOfDay(analyses)
	insights.RecurringDecisionPoints = computeRecurringDecisionPoints(analyses)
	insights.DeepTriggerPatterns = computeDeepTriggerPatterns(analyses)

	return insights
}

// computeCommonTriggers ranks triggers by frequency across all analyses.
func computeCommonTriggers(analyses []*PostMortemAnalysis) []TriggerFrequency {
	counts := make(map[string]int)
	total := len(analyses)

	for _, a := range analyses {
		// Use triggerSummary for category-level counting (deduplicated per analysis).
		seen := make(map[string]bool)
		for _, cat := range a.TriggerSummary {
			if !seen[cat] {
				counts[cat]++
				seen[cat] = true
			}
		}
		// Also count from trigger details if triggerSummary is empty.
		if len(a.TriggerSummary) == 0 {
			for _, td := range a.TriggerDetails {
				if !seen[td.Category] {
					counts[td.Category]++
					seen[td.Category] = true
				}
			}
		}
	}

	var result []TriggerFrequency
	for cat, count := range counts {
		result = append(result, TriggerFrequency{
			Category:   cat,
			Frequency:  count,
			Percentage: roundPercent(float64(count) / float64(total) * 100),
		})
	}

	// Sort by frequency descending.
	sort.Slice(result, func(i, j int) bool {
		return result[i].Frequency > result[j].Frequency
	})

	return result
}

// computeCommonFasterStageAtBreak finds the most frequent FASTER stage
// at the last point before relapse (the "point of no return").
func computeCommonFasterStageAtBreak(analyses []*PostMortemAnalysis) *StageFrequency {
	counts := make(map[string]int)
	total := 0

	for _, a := range analyses {
		if len(a.FasterMapping) < 2 {
			continue
		}
		// The stage before the last entry (which is typically "relapse").
		lastIdx := len(a.FasterMapping) - 1
		if a.FasterMapping[lastIdx].Stage == FASTERStageRelapse && lastIdx > 0 {
			stage := a.FasterMapping[lastIdx-1].Stage
			counts[stage]++
			total++
		} else {
			// If last isn't relapse, take the last entry.
			stage := a.FasterMapping[lastIdx].Stage
			counts[stage]++
			total++
		}
	}

	if total == 0 {
		return nil
	}

	var maxStage string
	var maxCount int
	for stage, count := range counts {
		if count > maxCount {
			maxStage = stage
			maxCount = count
		}
	}

	return &StageFrequency{
		Stage:      maxStage,
		Frequency:  maxCount,
		Percentage: roundPercent(float64(maxCount) / float64(total) * 100),
	}
}

// computeCommonTimeOfDay finds the most common time of day for acting out.
func computeCommonTimeOfDay(analyses []*PostMortemAnalysis) *TimeOfDayFrequency {
	counts := make(map[string]int)
	total := 0

	for _, a := range analyses {
		if a.Sections.ActingOut == nil {
			continue
		}
		// Determine period from linked time blocks or from the timestamp.
		period := determinePeriod(a)
		if period != "" {
			counts[period]++
			total++
		}
	}

	if total == 0 {
		return nil
	}

	var maxPeriod string
	var maxCount int
	for period, count := range counts {
		if count > maxCount {
			maxPeriod = period
			maxCount = count
		}
	}

	return &TimeOfDayFrequency{
		Period:     maxPeriod,
		Frequency:  maxCount,
		Percentage: roundPercent(float64(maxCount) / float64(total) * 100),
	}
}

// determinePeriod infers the time period of acting out from available data.
func determinePeriod(a *PostMortemAnalysis) string {
	// Check FASTER mapping for the relapse entry.
	for _, fm := range a.FasterMapping {
		if fm.Stage == FASTERStageRelapse {
			return timeToPeriod(fm.TimeOfDay)
		}
	}
	// Fall back to the event timestamp hour.
	hour := a.Timestamp.Hour()
	switch {
	case hour >= 5 && hour < 12:
		return TimePeriodMorning
	case hour >= 12 && hour < 14:
		return TimePeriodMidday
	case hour >= 14 && hour < 18:
		return TimePeriodAfternoon
	default:
		return TimePeriodEvening
	}
}

// timeToPeriod converts an HH:MM time string to a period.
func timeToPeriod(timeOfDay string) string {
	if len(timeOfDay) < 2 {
		return TimePeriodEvening
	}
	hour := 0
	for _, c := range timeOfDay[:2] {
		if c >= '0' && c <= '9' {
			hour = hour*10 + int(c-'0')
		}
	}
	switch {
	case hour >= 5 && hour < 12:
		return TimePeriodMorning
	case hour >= 12 && hour < 14:
		return TimePeriodMidday
	case hour >= 14 && hour < 18:
		return TimePeriodAfternoon
	default:
		return TimePeriodEvening
	}
}

// computeRecurringDecisionPoints identifies recurring themes in missed decision points.
func computeRecurringDecisionPoints(analyses []*PostMortemAnalysis) []DecisionPointTheme {
	// Group by normalized "could have done" text for theme extraction.
	themes := make(map[string]int)

	for _, a := range analyses {
		if a.Sections.BuildUp == nil {
			continue
		}
		for _, dp := range a.Sections.BuildUp.DecisionPoints {
			theme := normalizeTheme(dp.CouldHaveDone)
			if theme != "" {
				themes[theme]++
			}
		}
	}

	var result []DecisionPointTheme
	for theme, count := range themes {
		if count >= 2 { // Only surface themes that recur.
			result = append(result, DecisionPointTheme{
				Theme:     theme,
				Frequency: count,
			})
		}
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Frequency > result[j].Frequency
	})

	return result
}

// normalizeTheme normalizes a decision point theme for comparison.
func normalizeTheme(text string) string {
	text = strings.TrimSpace(strings.ToLower(text))
	// Remove common prefixes.
	prefixes := []string{"i could have ", "could have ", "should have "}
	for _, p := range prefixes {
		text = strings.TrimPrefix(text, p)
	}
	return text
}

// computeDeepTriggerPatterns finds recurring three-layer trigger chains.
func computeDeepTriggerPatterns(analyses []*PostMortemAnalysis) []TriggerDetail {
	type triggerKey struct {
		surface    string
		underlying string
		coreWound  string
	}
	counts := make(map[triggerKey]TriggerDetail)
	freq := make(map[triggerKey]int)

	for _, a := range analyses {
		for _, td := range a.TriggerDetails {
			if td.Underlying == nil && td.CoreWound == nil {
				continue // Only count deep explorations.
			}
			u := ""
			if td.Underlying != nil {
				u = *td.Underlying
			}
			c := ""
			if td.CoreWound != nil {
				c = *td.CoreWound
			}
			key := triggerKey{
				surface:    strings.ToLower(td.Surface),
				underlying: strings.ToLower(u),
				coreWound:  strings.ToLower(c),
			}
			counts[key] = td
			freq[key]++
		}
	}

	var result []TriggerDetail
	for key, count := range freq {
		if count >= 2 {
			result = append(result, counts[key])
		}
	}

	return result
}

// roundPercent rounds a percentage to one decimal place.
func roundPercent(p float64) float64 {
	return math.Round(p*10) / 10
}
