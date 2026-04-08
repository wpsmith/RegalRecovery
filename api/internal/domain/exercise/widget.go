// internal/domain/exercise/widget.go
package exercise

import "time"

// AssembleWidgetData builds the widget data from today's exercises, streak, and optional goal.
func AssembleWidgetData(todayLogs []ExerciseLog, streak ExerciseStreak, goal *GoalProgress) WidgetData {
	todayMinutes := 0
	todaySessions := len(todayLogs)

	for _, log := range todayLogs {
		todayMinutes += log.DurationMinutes
	}

	widget := WidgetData{
		ExercisedToday:     todaySessions > 0,
		TodayActiveMinutes: todayMinutes,
		TodaySessions:      todaySessions,
		Streak: StreakSummary{
			CurrentDays: streak.CurrentDays,
		},
	}

	if goal != nil {
		widget.WeeklyGoal = &WeeklyGoalSummary{
			TargetActiveMinutes:  derefInt(goal.TargetActiveMinutes, 0),
			CurrentActiveMinutes: goal.CurrentActiveMinutes,
			ProgressPercent:      goal.ProgressPercent,
			IsGoalMet:            goal.IsGoalMet,
		}
	}

	return widget
}

// TodayDateRange returns the start and end of today in the given timezone.
func TodayDateRange(now time.Time, tz *time.Location) (start, end time.Time) {
	if tz == nil {
		tz = time.UTC
	}
	local := now.In(tz)
	start = time.Date(local.Year(), local.Month(), local.Day(), 0, 0, 0, 0, tz)
	end = start.Add(24*time.Hour - time.Nanosecond)
	return start, end
}

func derefInt(p *int, defaultVal int) int {
	if p == nil {
		return defaultVal
	}
	return *p
}
