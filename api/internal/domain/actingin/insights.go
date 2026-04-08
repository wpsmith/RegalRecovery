// internal/domain/actingin/insights.go
package actingin

import (
	"fmt"
	"math"
	"sort"
	"time"
)

// CalculateFrequencyInsights computes behavior frequency data for the given range.
func CalculateFrequencyInsights(checkIns []CheckIn, r InsightsRange) *FrequencyInsights {
	days := RangeToDays(r)
	now := time.Now().UTC()
	cutoff := now.AddDate(0, 0, -days)
	priorCutoff := cutoff.AddDate(0, 0, -days)

	// Split check-ins into current and prior periods.
	var current, prior []CheckIn
	for _, ci := range checkIns {
		if ci.Timestamp.After(cutoff) {
			current = append(current, ci)
		} else if ci.Timestamp.After(priorCutoff) {
			prior = append(prior, ci)
		}
	}

	// Count behavior occurrences in the current period.
	behaviorCounts := make(map[string]int)
	behaviorNames := make(map[string]string)
	totalBehaviors := 0

	for _, ci := range current {
		for _, b := range ci.Behaviors {
			behaviorCounts[b.BehaviorID]++
			behaviorNames[b.BehaviorID] = b.BehaviorName
			totalBehaviors++
		}
	}

	// Count behavior occurrences in the prior period.
	priorCounts := make(map[string]int)
	for _, ci := range prior {
		for _, b := range ci.Behaviors {
			priorCounts[b.BehaviorID]++
		}
	}

	totalCheckIns := len(current)
	behaviors := make([]BehaviorFrequency, 0, len(behaviorCounts))

	for id, count := range behaviorCounts {
		pct := 0.0
		if totalCheckIns > 0 {
			pct = math.Round(float64(count)/float64(totalCheckIns)*1000) / 10
		}

		trend := CalculateTrend(count, priorCounts[id])

		behaviors = append(behaviors, BehaviorFrequency{
			BehaviorID:           id,
			BehaviorName:         behaviorNames[id],
			Count:                count,
			Trend:                trend,
			PercentageOfCheckIns: pct,
		})
	}

	// Sort by frequency (most frequent first).
	sort.Slice(behaviors, func(i, j int) bool {
		return behaviors[i].Count > behaviors[j].Count
	})

	return &FrequencyInsights{
		Range:                r,
		Behaviors:            behaviors,
		TotalCheckIns:        totalCheckIns,
		TotalBehaviorsLogged: totalBehaviors,
	}
}

// CalculateTrend determines the trend direction by comparing current vs prior period counts.
func CalculateTrend(current, prior int) Trend {
	if prior == 0 && current == 0 {
		return TrendStable
	}
	if prior == 0 {
		return TrendIncreasing
	}
	ratio := float64(current) / float64(prior)
	if ratio > 1.15 {
		return TrendIncreasing
	}
	if ratio < 0.85 {
		return TrendDecreasing
	}
	return TrendStable
}

// CalculateTriggerInsights computes trigger analysis for the given range.
func CalculateTriggerInsights(checkIns []CheckIn, r InsightsRange) *TriggerInsights {
	days := RangeToDays(r)
	cutoff := time.Now().UTC().AddDate(0, 0, -days)

	triggerCounts := make(map[Trigger]int)
	triggerBehaviorMap := make(map[Trigger]map[string]int)
	behaviorNames := make(map[string]string)
	totalTriggers := 0

	for _, ci := range checkIns {
		if ci.Timestamp.Before(cutoff) {
			continue
		}
		for _, b := range ci.Behaviors {
			if b.Trigger == "" {
				continue
			}
			triggerCounts[b.Trigger]++
			totalTriggers++

			if triggerBehaviorMap[b.Trigger] == nil {
				triggerBehaviorMap[b.Trigger] = make(map[string]int)
			}
			triggerBehaviorMap[b.Trigger][b.BehaviorID]++
			behaviorNames[b.BehaviorID] = b.BehaviorName
		}
	}

	triggers := make([]TriggerInsight, 0, len(triggerCounts))
	for t, count := range triggerCounts {
		pct := 0.0
		if totalTriggers > 0 {
			pct = math.Round(float64(count)/float64(totalTriggers)*1000) / 10
		}
		triggers = append(triggers, TriggerInsight{
			Trigger:           t,
			Count:             count,
			PercentageOfTotal: pct,
		})
	}
	sort.Slice(triggers, func(i, j int) bool {
		return triggers[i].Count > triggers[j].Count
	})

	correlations := make([]TriggerBehaviorCorrelation, 0, len(triggerBehaviorMap))
	for t, behaviorMap := range triggerBehaviorMap {
		top := topBehaviors(behaviorMap, behaviorNames, 3)
		narrative := buildTriggerNarrative(t, top)
		correlations = append(correlations, TriggerBehaviorCorrelation{
			Trigger:      t,
			TopBehaviors: top,
			Narrative:    narrative,
		})
	}
	sort.Slice(correlations, func(i, j int) bool {
		return triggerCounts[correlations[i].Trigger] > triggerCounts[correlations[j].Trigger]
	})

	return &TriggerInsights{
		Range:        r,
		Triggers:     triggers,
		Correlations: correlations,
	}
}

// CalculateRelationshipInsights computes relationship impact data for the given range.
func CalculateRelationshipInsights(checkIns []CheckIn, r InsightsRange) *RelationshipInsights {
	days := RangeToDays(r)
	now := time.Now().UTC()
	cutoff := now.AddDate(0, 0, -days)
	priorCutoff := cutoff.AddDate(0, 0, -days)

	currentCounts := make(map[RelationshipTag]int)
	priorCounts := make(map[RelationshipTag]int)

	for _, ci := range checkIns {
		for _, b := range ci.Behaviors {
			if b.RelationshipTag == "" {
				continue
			}
			if ci.Timestamp.After(cutoff) {
				currentCounts[b.RelationshipTag]++
			} else if ci.Timestamp.After(priorCutoff) {
				priorCounts[b.RelationshipTag]++
			}
		}
	}

	relationships := make([]RelationshipInsight, 0, len(currentCounts))
	for tag, count := range currentCounts {
		trend := CalculateTrend(count, priorCounts[tag])
		narrative := buildRelationshipNarrative(tag, trend, count, priorCounts[tag])
		relationships = append(relationships, RelationshipInsight{
			RelationshipTag: tag,
			Count:           count,
			Trend:           trend,
			Narrative:       narrative,
		})
	}
	sort.Slice(relationships, func(i, j int) bool {
		return relationships[i].Count > relationships[j].Count
	})

	return &RelationshipInsights{
		Range:         r,
		Relationships: relationships,
	}
}

// CalculateHeatmap computes the day-of-week x hour-of-day heatmap.
func CalculateHeatmap(checkIns []CheckIn, r InsightsRange, timezone *time.Location) *HeatmapInsights {
	days := RangeToDays(r)
	cutoff := time.Now().UTC().AddDate(0, 0, -days)

	if timezone == nil {
		timezone = time.UTC
	}

	// Grid: 7 days x 24 hours.
	grid := [7][24]int{}
	maxCount := 0

	for _, ci := range checkIns {
		if ci.Timestamp.Before(cutoff) {
			continue
		}
		local := ci.Timestamp.In(timezone)
		dow := int(local.Weekday()) // 0=Sunday.
		hour := local.Hour()
		grid[dow][hour] += ci.BehaviorCount
		if grid[dow][hour] > maxCount {
			maxCount = grid[dow][hour]
		}
	}

	cells := make([]HeatmapCell, 0)
	for dow := 0; dow < 7; dow++ {
		for hour := 0; hour < 24; hour++ {
			count := grid[dow][hour]
			if count == 0 {
				continue
			}
			intensity := 0.0
			if maxCount > 0 {
				intensity = math.Round(float64(count)/float64(maxCount)*100) / 100
			}
			cells = append(cells, HeatmapCell{
				DayOfWeek: dow,
				HourOfDay: hour,
				Count:     count,
				Intensity: intensity,
			})
		}
	}

	return &HeatmapInsights{
		Range: r,
		Cells: cells,
	}
}

// --- Helper functions ---

func topBehaviors(behaviorMap map[string]int, names map[string]string, limit int) []BehaviorCountEntry {
	entries := make([]BehaviorCountEntry, 0, len(behaviorMap))
	for id, count := range behaviorMap {
		entries = append(entries, BehaviorCountEntry{
			BehaviorID:   id,
			BehaviorName: names[id],
			Count:        count,
		})
	}
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Count > entries[j].Count
	})
	if len(entries) > limit {
		entries = entries[:limit]
	}
	return entries
}

func buildTriggerNarrative(trigger Trigger, top []BehaviorCountEntry) string {
	if len(top) == 0 {
		return ""
	}
	names := make([]string, len(top))
	for i, b := range top {
		names[i] = b.BehaviorName
	}
	if len(names) == 1 {
		return fmt.Sprintf("When you're experiencing %s, you most often %s", trigger, names[0])
	}
	last := names[len(names)-1]
	rest := names[:len(names)-1]
	joined := ""
	for i, n := range rest {
		if i > 0 {
			joined += ", "
		}
		joined += n
	}
	return fmt.Sprintf("When you're experiencing %s, you most often %s or %s", trigger, joined, last)
}

func buildRelationshipNarrative(tag RelationshipTag, trend Trend, current, prior int) string {
	if trend == TrendDecreasing && prior > 0 {
		pctChange := math.Round(float64(prior-current) / float64(prior) * 100)
		return fmt.Sprintf("Acting-in behaviors affecting your %s decreased %.0f%% this period", tag, pctChange)
	}
	if trend == TrendIncreasing {
		return fmt.Sprintf("Acting-in behaviors affecting your %s have increased this period", tag)
	}
	return fmt.Sprintf("Acting-in behaviors affecting your %s are stable", tag)
}
