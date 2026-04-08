// internal/domain/exercise/widget_test.go
package exercise

import (
	"testing"
)

func TestWidget_FR_EX_5_1_ExercisedToday_ReturnsTrue(t *testing.T) {
	todayLogs := []ExerciseLog{
		{DurationMinutes: 30, ActivityType: ActivityTypeRunning},
	}
	streak := ExerciseStreak{CurrentDays: 5}

	widget := AssembleWidgetData(todayLogs, streak, nil)
	if !widget.ExercisedToday {
		t.Error("expected exercisedToday=true when logs exist")
	}
	if widget.TodayActiveMinutes != 30 {
		t.Errorf("expected 30 today active minutes, got %d", widget.TodayActiveMinutes)
	}
	if widget.TodaySessions != 1 {
		t.Errorf("expected 1 session, got %d", widget.TodaySessions)
	}
}

func TestWidget_FR_EX_5_1_NotExercisedToday_ReturnsFalse(t *testing.T) {
	streak := ExerciseStreak{CurrentDays: 0}

	widget := AssembleWidgetData(nil, streak, nil)
	if widget.ExercisedToday {
		t.Error("expected exercisedToday=false when no logs")
	}
	if widget.TodayActiveMinutes != 0 {
		t.Errorf("expected 0 today active minutes, got %d", widget.TodayActiveMinutes)
	}
}

func TestWidget_FR_EX_5_1_StreakIncluded_MatchesStreakCalculation(t *testing.T) {
	streak := ExerciseStreak{CurrentDays: 12}

	widget := AssembleWidgetData(nil, streak, nil)
	if widget.Streak.CurrentDays != 12 {
		t.Errorf("expected streak of 12, got %d", widget.Streak.CurrentDays)
	}
}

func TestWidget_FR_EX_5_1_WeeklyGoalIncluded_WhenGoalSet(t *testing.T) {
	minutes := 150
	goalProgress := &GoalProgress{
		TargetActiveMinutes:  &minutes,
		CurrentActiveMinutes: 120,
		ProgressPercent:      80.0,
		IsGoalMet:            false,
	}

	widget := AssembleWidgetData(nil, ExerciseStreak{}, goalProgress)
	if widget.WeeklyGoal == nil {
		t.Fatal("expected non-nil weekly goal")
	}
	if widget.WeeklyGoal.TargetActiveMinutes != 150 {
		t.Errorf("expected target 150, got %d", widget.WeeklyGoal.TargetActiveMinutes)
	}
	if widget.WeeklyGoal.CurrentActiveMinutes != 120 {
		t.Errorf("expected current 120, got %d", widget.WeeklyGoal.CurrentActiveMinutes)
	}
	if widget.WeeklyGoal.ProgressPercent != 80.0 {
		t.Errorf("expected 80.0%%, got %.1f%%", widget.WeeklyGoal.ProgressPercent)
	}
}

func TestWidget_FR_EX_5_1_WeeklyGoalNull_WhenNoGoalSet(t *testing.T) {
	widget := AssembleWidgetData(nil, ExerciseStreak{}, nil)
	if widget.WeeklyGoal != nil {
		t.Error("expected nil weekly goal when no goal configured")
	}
}
