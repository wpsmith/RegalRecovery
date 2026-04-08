// internal/domain/exercise/goals.go
package exercise

import (
	"math"
	"time"
)

// ValidateGoal validates that at least one of targetActiveMinutes or targetSessions is set.
func ValidateGoal(goal ExerciseGoal) error {
	if goal.TargetActiveMinutes == nil && goal.TargetSessions == nil {
		return ErrGoalEmpty
	}
	if goal.TargetActiveMinutes != nil && (*goal.TargetActiveMinutes < 1 || *goal.TargetActiveMinutes > 10080) {
		return ErrInvalidInput
	}
	if goal.TargetSessions != nil && (*goal.TargetSessions < 1 || *goal.TargetSessions > 50) {
		return ErrInvalidInput
	}
	return nil
}

// CalculateGoalProgress computes the progress toward a weekly goal given
// the current week's exercise logs and the goal configuration.
func CalculateGoalProgress(goal ExerciseGoal, logs []ExerciseLog, weekStart time.Time) GoalProgress {
	currentMinutes := 0
	currentSessions := 0

	for _, log := range logs {
		currentMinutes += log.DurationMinutes
		currentSessions++
	}

	// Calculate progress percent as the higher of minutes% or sessions%.
	var progressPercent float64

	if goal.TargetActiveMinutes != nil && *goal.TargetActiveMinutes > 0 {
		minutesPercent := float64(currentMinutes) / float64(*goal.TargetActiveMinutes) * 100.0
		progressPercent = minutesPercent
	}

	if goal.TargetSessions != nil && *goal.TargetSessions > 0 {
		sessionsPercent := float64(currentSessions) / float64(*goal.TargetSessions) * 100.0
		if sessionsPercent > progressPercent {
			progressPercent = sessionsPercent
		}
	}

	// Round to one decimal place.
	progressPercent = math.Round(progressPercent*10) / 10

	isGoalMet := false
	if goal.TargetActiveMinutes != nil && currentMinutes >= *goal.TargetActiveMinutes {
		isGoalMet = true
	}
	if goal.TargetSessions != nil && currentSessions >= *goal.TargetSessions {
		isGoalMet = true
	}
	// If both targets are set, goal is met when either is met (per "higher of" logic).

	return GoalProgress{
		TargetActiveMinutes:  goal.TargetActiveMinutes,
		TargetSessions:       goal.TargetSessions,
		CurrentActiveMinutes: currentMinutes,
		CurrentSessions:      currentSessions,
		ProgressPercent:      progressPercent,
		WeekStartDate:        weekStart.Format("2006-01-02"),
		IsGoalMet:            isGoalMet,
	}
}

// WeekStartDate returns the Monday of the week containing the given date.
func WeekStartDate(date time.Time) time.Time {
	weekday := date.Weekday()
	if weekday == time.Sunday {
		weekday = 7
	}
	daysFromMonday := int(weekday) - int(time.Monday)
	return time.Date(date.Year(), date.Month(), date.Day()-daysFromMonday, 0, 0, 0, 0, date.Location())
}
