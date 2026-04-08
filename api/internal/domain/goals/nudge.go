// internal/domain/goals/nudge.go
package goals

import "fmt"

// GenerateNudges detects dynamics with no goals and returns nudge messages (AC-DN-1).
// Respects nudge settings (AC-DN-3) and dismissed nudges (AC-DN-2).
func GenerateNudges(instances []GoalInstance, settings *GoalSettings, dismissedDynamics []string) []DynamicNudge {
	if settings != nil && !settings.NudgesEnabled {
		return nil
	}

	// Build sets for disabled and dismissed dynamics.
	disabledSet := make(map[Dynamic]bool)
	if settings != nil {
		for _, d := range settings.NudgesDisabledDynamics {
			disabledSet[d] = true
		}
	}
	dismissedSet := make(map[string]bool)
	for _, d := range dismissedDynamics {
		dismissedSet[d] = true
	}

	// Count goals per dynamic.
	dynamicCounts := make(map[Dynamic]int)
	for _, inst := range instances {
		if inst.Status == StatusDismissed {
			continue
		}
		for _, d := range inst.Dynamics {
			dynamicCounts[d]++
		}
	}

	var nudges []DynamicNudge
	for _, d := range AllDynamics {
		if dynamicCounts[d] > 0 {
			continue
		}
		if disabledSet[d] {
			continue
		}
		dismissed := dismissedSet[string(d)]
		if dismissed {
			continue
		}
		nudges = append(nudges, DynamicNudge{
			Dynamic:   d,
			Message:   fmt.Sprintf("You don't have any %s goals today. Would you like to add one?", d),
			Dismissed: false,
		})
	}

	return nudges
}
