// internal/domain/postmortem/faster_mapping.go
package postmortem

import "strings"

// fasterKeywordMap maps keywords/phrases to FASTER stages for suggestion generation.
var fasterKeywordMap = map[string]string{
	"skipping meetings":     FASTERStageForgettingPriority,
	"skipped meetings":      FASTERStageForgettingPriority,
	"forgot commitments":    FASTERStageForgettingPriority,
	"skipped prayer":        FASTERStageForgettingPriority,
	"skipped devotional":    FASTERStageForgettingPriority,
	"stopped journaling":    FASTERStageForgettingPriority,
	"neglecting recovery":   FASTERStageForgettingPriority,
	"forgot my commitment":  FASTERStageForgettingPriority,
	"skipped commitment":    FASTERStageForgettingPriority,
	"worried":               FASTERStageAnxiety,
	"anxious":               FASTERStageAnxiety,
	"nervous":               FASTERStageAnxiety,
	"restless":              FASTERStageAnxiety,
	"couldn't sleep":        FASTERStageAnxiety,
	"racing thoughts":       FASTERStageAnxiety,
	"panic":                 FASTERStageAnxiety,
	"rushing":               FASTERStageSpeedingUp,
	"overcommitted":         FASTERStageSpeedingUp,
	"too busy":              FASTERStageSpeedingUp,
	"working too much":      FASTERStageSpeedingUp,
	"no time":               FASTERStageSpeedingUp,
	"can't slow down":       FASTERStageSpeedingUp,
	"frustrated":            FASTERStageTickedOff,
	"angry":                 FASTERStageTickedOff,
	"resentful":             FASTERStageTickedOff,
	"irritated":             FASTERStageTickedOff,
	"bitter":                FASTERStageTickedOff,
	"annoyed":               FASTERStageTickedOff,
	"exhausted":             FASTERStageExhausted,
	"burned out":            FASTERStageExhausted,
	"overwhelmed":           FASTERStageExhausted,
	"numb":                  FASTERStageExhausted,
	"given up":              FASTERStageExhausted,
	"don't care anymore":    FASTERStageExhausted,
	"I deserve this":        FASTERStageExhausted,
	"entitled":              FASTERStageExhausted,
}

// SuggestFASTERStages analyzes walkthrough text and returns suggested FASTER stage assignments.
// Each suggestion includes the timeOfDay and suggested stage based on keyword matching.
func SuggestFASTERStages(analysis *PostMortemAnalysis) []FasterMappingEntry {
	var suggestions []FasterMappingEntry
	seen := make(map[string]bool)

	// Scan time blocks for keywords.
	if analysis.Sections.ThroughoutTheDay != nil {
		for _, tb := range analysis.Sections.ThroughoutTheDay.TimeBlocks {
			text := strings.ToLower(tb.Thoughts + " " + tb.Feelings + " " + tb.Activity)
			for keyword, stage := range fasterKeywordMap {
				if strings.Contains(text, keyword) {
					key := tb.StartTime + ":" + stage
					if !seen[key] {
						suggestions = append(suggestions, FasterMappingEntry{
							TimeOfDay: tb.StartTime,
							Stage:     stage,
						})
						seen[key] = true
					}
				}
			}
			// Also check warningSigns for direct stage references.
			for _, ws := range tb.WarningSigns {
				if ValidFASTERStages[ws] {
					key := tb.StartTime + ":" + ws
					if !seen[key] {
						suggestions = append(suggestions, FasterMappingEntry{
							TimeOfDay: tb.StartTime,
							Stage:     ws,
						})
						seen[key] = true
					}
				}
			}
		}
	}

	// Scan day before and morning text.
	if analysis.Sections.DayBefore != nil {
		text := strings.ToLower(analysis.Sections.DayBefore.Text)
		for keyword, stage := range fasterKeywordMap {
			if strings.Contains(text, keyword) {
				key := "dayBefore:" + stage
				if !seen[key] {
					suggestions = append(suggestions, FasterMappingEntry{
						TimeOfDay: "dayBefore",
						Stage:     stage,
					})
					seen[key] = true
				}
			}
		}
	}

	return suggestions
}
