// internal/domain/affirmations/progress.go
package affirmations

// AffirmationProgress represents cumulative affirmation progress.
// CRITICAL: Progress is CUMULATIVE only. NO streak tracking.
type AffirmationProgress struct {
	TotalSessions     int `json:"totalSessions"`     // Cumulative total sessions (all time)
	TotalAffirmations int `json:"totalAffirmations"` // Cumulative affirmations viewed (all time)
	TotalCustom       int `json:"totalCustom"`       // Cumulative custom affirmations created
	TotalAudio        int `json:"totalAudio"`        // Cumulative audio recordings saved
	TotalSOSSessions  int `json:"totalSosSessions"`  // Cumulative SOS sessions completed
	// NOTE: Deliberately NO streak fields. Progress is cumulative, not streak-based.
}

// Milestone represents an achievement milestone.
type Milestone struct {
	Type        string `json:"type"`        // e.g., "1_sessions", "10_sessions", "first_custom"
	Description string `json:"description"` // Human-readable milestone description
	Achieved    bool   `json:"achieved"`
}

// CalculateProgress computes cumulative progress from all completed sessions.
// NEVER calculates streaks. Progress is cumulative only.
func CalculateProgress(
	sessions []SessionCompletion,
	customCount int,
	audioCount int,
	sosCount int,
) AffirmationProgress {
	totalSessions := 0
	totalAffirmations := 0

	for _, session := range sessions {
		if !session.WasSkipped {
			totalSessions++
			totalAffirmations += session.AffirmationCount
		}
	}

	return AffirmationProgress{
		TotalSessions:     totalSessions,
		TotalAffirmations: totalAffirmations,
		TotalCustom:       customCount,
		TotalAudio:        audioCount,
		TotalSOSSessions:  sosCount,
	}
}

// DetectMilestone detects if a milestone has been reached.
// Milestones: 1, 10, 25, 50, 100, 250 sessions; first custom; first audio; first SOS.
// Priority: Special milestones (custom, audio, SOS) before session count milestones.
func DetectMilestone(
	progress AffirmationProgress,
	sessions []SessionCompletion,
	customCount int,
	audioCount int,
	sosCount int,
) *Milestone {
	// First custom affirmation (highest priority)
	if customCount == 1 {
		return &Milestone{
			Type:        "first_custom",
			Description: "Created your first custom affirmation",
			Achieved:    true,
		}
	}

	// First audio recording
	if audioCount == 1 {
		return &Milestone{
			Type:        "first_audio",
			Description: "Saved your first audio affirmation",
			Achieved:    true,
		}
	}

	// First SOS session
	if sosCount == 1 {
		return &Milestone{
			Type:        "first_sos",
			Description: "Completed your first SOS session",
			Achieved:    true,
		}
	}

	// Session count milestones (lower priority)
	sessionMilestones := []int{1, 10, 25, 50, 100, 250}
	for _, threshold := range sessionMilestones {
		if progress.TotalSessions == threshold {
			return &Milestone{
				Type:        sessionMilestoneType(threshold),
				Description: sessionMilestoneDescription(threshold),
				Achieved:    true,
			}
		}
	}

	return nil
}

// sessionMilestoneType returns the milestone type string for session count.
func sessionMilestoneType(count int) string {
	switch count {
	case 1:
		return "1_sessions"
	case 10:
		return "10_sessions"
	case 25:
		return "25_sessions"
	case 50:
		return "50_sessions"
	case 100:
		return "100_sessions"
	case 250:
		return "250_sessions"
	default:
		return ""
	}
}

// sessionMilestoneDescription returns the human-readable description for session count milestone.
func sessionMilestoneDescription(count int) string {
	switch count {
	case 1:
		return "Completed your first affirmation session"
	case 10:
		return "10 affirmation sessions completed"
	case 25:
		return "25 affirmation sessions completed"
	case 50:
		return "50 affirmation sessions completed"
	case 100:
		return "100 affirmation sessions completed"
	case 250:
		return "250 affirmation sessions completed"
	default:
		return ""
	}
}
