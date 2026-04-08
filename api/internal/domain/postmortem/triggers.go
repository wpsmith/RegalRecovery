// internal/domain/postmortem/triggers.go
package postmortem

// ExtractTriggerSummary builds the triggerSummary (list of unique categories)
// from the triggerDetails array.
func ExtractTriggerSummary(details []TriggerDetail) []string {
	seen := make(map[string]bool)
	var categories []string
	for _, d := range details {
		if !seen[d.Category] {
			categories = append(categories, d.Category)
			seen[d.Category] = true
		}
	}
	return categories
}

// ValidateTriggerExploration validates a three-layer trigger exploration.
// Surface is required; underlying and coreWound are optional (partial exploration OK per PM-AC4.2).
func ValidateTriggerExploration(trigger TriggerDetail) error {
	if err := ValidateTriggerCategory(trigger.Category); err != nil {
		return err
	}
	// Surface is required.
	if trigger.Surface == "" {
		return ErrInvalidTriggerCategory // reuse error for simplicity
	}
	// Underlying and CoreWound are optional.
	return nil
}

// MatchTriggerPattern checks if a trigger matches a pattern from a previous post-mortem.
// Returns true if the category and surface match (case-insensitive).
func MatchTriggerPattern(current, previous TriggerDetail) bool {
	if current.Category != previous.Category {
		return false
	}
	return normalizeTheme(current.Surface) == normalizeTheme(previous.Surface)
}

// FindMatchingTriggers finds triggers in a new post-mortem that match those in previous analyses.
func FindMatchingTriggers(current []TriggerDetail, previousAnalyses []*PostMortemAnalysis) map[string][]string {
	// Returns map of trigger surface -> list of dates where it appeared.
	matches := make(map[string][]string)

	for _, td := range current {
		normalizedSurface := normalizeTheme(td.Surface)
		for _, prev := range previousAnalyses {
			for _, ptd := range prev.TriggerDetails {
				if MatchTriggerPattern(td, ptd) {
					date := prev.Timestamp.Format("2006-01-02")
					matches[normalizedSurface] = append(matches[normalizedSurface], date)
					break // Only count once per analysis.
				}
			}
		}
	}

	return matches
}
