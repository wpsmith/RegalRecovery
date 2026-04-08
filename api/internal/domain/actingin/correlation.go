// internal/domain/actingin/correlation.go
package actingin

import (
	"fmt"
	"time"
)

// PciDayData represents a single day of PCI data for correlation analysis.
type PciDayData struct {
	Date  time.Time
	Score int
}

// FasterEntry represents a single FASTER Scale assessment for correlation.
type FasterEntry struct {
	Date  time.Time
	Stage string // "restoration", "F", "A", "S", "T", "E", "R"
}

// PostMortemEntry represents a post-mortem analysis for correlation.
type PostMortemEntry struct {
	PostMortemID string
	RelapseDate  time.Time
	BuildUpStart time.Time
	BuildUpEnd   time.Time
}

// CalculatePciCorrelation computes the correlation between PCI scores and acting-in behavior counts.
// Returns correlationFound=false if no PCI data is available.
func CalculatePciCorrelation(checkIns []CheckIn, pciData []PciDayData, r InsightsRange) *PciCorrelation {
	if len(pciData) == 0 {
		return &PciCorrelation{
			CorrelationFound: false,
		}
	}

	days := RangeToDays(r)
	cutoff := time.Now().UTC().AddDate(0, 0, -days)

	// Build a map of date -> behavior count.
	behaviorsByDate := make(map[string]int)
	for _, ci := range checkIns {
		if ci.Timestamp.Before(cutoff) {
			continue
		}
		key := ci.Timestamp.Format("2006-01-02")
		behaviorsByDate[key] += ci.BehaviorCount
	}

	// Count days where elevated PCI coincides with higher acting-in.
	elevatedDays := 0
	pciThreshold := 5 // PCI score considered elevated.
	actingInThreshold := 2

	for _, pci := range pciData {
		if pci.Date.Before(cutoff) {
			continue
		}
		if pci.Score >= pciThreshold {
			key := pci.Date.Format("2006-01-02")
			if behaviorsByDate[key] >= actingInThreshold {
				elevatedDays++
			}
		}
	}

	if elevatedDays == 0 {
		return &PciCorrelation{
			CorrelationFound: false,
		}
	}

	narrative := fmt.Sprintf("On %d days, elevated PCI scores coincided with increased acting-in behaviors", elevatedDays)

	return &PciCorrelation{
		CorrelationFound: true,
		PciElevatedDays:  elevatedDays,
		Narrative:        narrative,
	}
}

// CalculateFasterCorrelation computes the correlation between FASTER Scale stages
// and acting-in behavior spikes.
func CalculateFasterCorrelation(checkIns []CheckIn, fasterData []FasterEntry, r InsightsRange) *FasterCorrelation {
	if len(fasterData) == 0 {
		return &FasterCorrelation{
			CorrelationFound: false,
		}
	}

	days := RangeToDays(r)
	cutoff := time.Now().UTC().AddDate(0, 0, -days)

	// Build a map of date -> acting-in count.
	actingInByDate := make(map[string]int)
	for _, ci := range checkIns {
		if ci.Timestamp.Before(cutoff) {
			continue
		}
		key := ci.Timestamp.Format("2006-01-02")
		actingInByDate[key] += ci.BehaviorCount
	}

	// Count acting-in behaviors per FASTER stage.
	stageCounts := make(map[string]int)
	for _, f := range fasterData {
		if f.Date.Before(cutoff) {
			continue
		}
		key := f.Date.Format("2006-01-02")
		if count, ok := actingInByDate[key]; ok {
			stageCounts[f.Stage] += count
		}
	}

	if len(stageCounts) == 0 {
		return &FasterCorrelation{
			CorrelationFound: false,
		}
	}

	breakdown := make([]FasterStageBreakdown, 0, len(stageCounts))
	for stage, count := range stageCounts {
		breakdown = append(breakdown, FasterStageBreakdown{
			Stage:         stage,
			ActingInCount: count,
		})
	}

	// Find the stage with the highest acting-in count.
	maxStage := ""
	maxCount := 0
	for _, b := range breakdown {
		if b.ActingInCount > maxCount {
			maxCount = b.ActingInCount
			maxStage = b.Stage
		}
	}

	narrative := fmt.Sprintf("Acting-in behaviors are most frequent during the %s stage of the FASTER Scale", maxStage)

	return &FasterCorrelation{
		CorrelationFound: true,
		StageBreakdown:   breakdown,
		Narrative:        narrative,
	}
}

// CalculatePostMortemPatterns identifies acting-in behaviors that occurred during
// the build-up phase of past relapses.
func CalculatePostMortemPatterns(checkIns []CheckIn, postMortems []PostMortemEntry) []PostMortemPattern {
	if len(postMortems) == 0 {
		return nil
	}

	patterns := make([]PostMortemPattern, 0, len(postMortems))

	for _, pm := range postMortems {
		behaviorSet := make(map[string]bool)
		for _, ci := range checkIns {
			if ci.Timestamp.After(pm.BuildUpStart) && ci.Timestamp.Before(pm.BuildUpEnd) {
				for _, b := range ci.Behaviors {
					behaviorSet[b.BehaviorName] = true
				}
			}
		}

		if len(behaviorSet) == 0 {
			continue
		}

		behaviors := make([]string, 0, len(behaviorSet))
		for name := range behaviorSet {
			behaviors = append(behaviors, name)
		}

		patterns = append(patterns, PostMortemPattern{
			PostMortemID:     pm.PostMortemID,
			RelapseDate:      pm.RelapseDate.Format("2006-01-02"),
			BuildUpBehaviors: behaviors,
		})
	}

	return patterns
}

// CalculateCrossToolInsights assembles all cross-tool correlations.
func CalculateCrossToolInsights(
	checkIns []CheckIn,
	pciData []PciDayData,
	fasterData []FasterEntry,
	postMortems []PostMortemEntry,
	r InsightsRange,
) *CrossToolInsights {
	return &CrossToolInsights{
		Range:              r,
		PciCorrelation:     *CalculatePciCorrelation(checkIns, pciData, r),
		FasterCorrelation:  *CalculateFasterCorrelation(checkIns, fasterData, r),
		PostMortemPatterns: CalculatePostMortemPatterns(checkIns, postMortems),
	}
}
