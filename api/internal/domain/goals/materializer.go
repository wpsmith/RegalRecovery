// internal/domain/goals/materializer.go
package goals

import (
	"fmt"
	"sort"
	"time"
)

// MaterializeInstances generates goal instances for a given date from goal definitions.
// AC-GC-5: Recurrence rules determine which goals appear on which days.
func MaterializeInstances(goals []WeeklyDailyGoal, date string, userID, tenantID string) []GoalInstance {
	parsedDate, err := time.Parse("2006-01-02", date)
	if err != nil {
		return nil
	}

	dayOfWeek := DayOfWeekFromTime(parsedDate.Weekday())
	var instances []GoalInstance

	for _, goal := range goals {
		if !goal.IsActive {
			continue
		}

		if !shouldMaterialize(goal, dayOfWeek) {
			continue
		}

		instance := GoalInstance{
			GoalInstanceID: generateInstanceID(),
			GoalID:         strPtr(goal.GoalID),
			UserID:         userID,
			TenantID:       tenantID,
			Date:           date,
			Text:           goal.Text,
			Dynamics:       goal.Dynamics,
			Scope:          goal.Scope,
			Priority:       goal.Priority,
			Status:         StatusPending,
			CompletedAt:    nil,
			Source:         nil,
			SourceID:       nil,
			CarriedFrom:    nil,
			Notes:          goal.Notes,
			CreatedAt:      time.Now().UTC(),
			ModifiedAt:     time.Now().UTC(),
		}

		if goal.Scope == ScopeWeekly && goal.DayOfWeek != nil {
			instance.DueDay = goal.DayOfWeek
		}

		instances = append(instances, instance)
	}

	return instances
}

// MaterializeAutoPopulated creates goal instances from commitments/activities.
// AC-AP-1: Auto-populate from active commitments.
// AC-AP-2: Auto-populate from configured activities.
func MaterializeAutoPopulated(sources []AutoPopulateSource, date string, userID, tenantID string) []GoalInstance {
	var instances []GoalInstance

	for _, src := range sources {
		source := src.Source
		instance := GoalInstance{
			GoalInstanceID: generateInstanceID(),
			GoalID:         nil,
			UserID:         userID,
			TenantID:       tenantID,
			Date:           date,
			Text:           src.Text,
			Dynamics:       src.Dynamics,
			Scope:          ScopeDaily,
			Priority:       PriorityMedium,
			Status:         StatusPending,
			CompletedAt:    nil,
			Source:         &source,
			SourceID:       strPtr(src.SourceID),
			CarriedFrom:    nil,
			Notes:          nil,
			CreatedAt:      time.Now().UTC(),
			ModifiedAt:     time.Now().UTC(),
		}
		instances = append(instances, instance)
	}

	return instances
}

// AutoPopulateSource describes a source for auto-populating goals.
type AutoPopulateSource struct {
	Source   GoalSource
	SourceID string
	Text     string
	Dynamics []Dynamic
}

// shouldMaterialize determines whether a goal should generate an instance on a given day.
func shouldMaterialize(goal WeeklyDailyGoal, dayOfWeek DayOfWeek) bool {
	switch goal.Recurrence {
	case RecurrenceOneTime:
		// One-time goals only materialize once; caller handles dedup.
		return true
	case RecurrenceDaily:
		return true
	case RecurrenceSpecificDays:
		for _, d := range goal.DaysOfWeek {
			if d == dayOfWeek {
				return true
			}
		}
		return false
	case RecurrenceWeekly:
		if goal.DayOfWeek != nil && *goal.DayOfWeek == dayOfWeek {
			return true
		}
		return false
	default:
		return false
	}
}

// SortInstancesByPriority sorts goal instances by priority (high first),
// then by creation time for ties (AC-GC-6).
func SortInstancesByPriority(instances []GoalInstance) {
	sort.SliceStable(instances, func(i, j int) bool {
		ri := PriorityRank(instances[i].Priority)
		rj := PriorityRank(instances[j].Priority)
		if ri != rj {
			return ri < rj
		}
		return instances[i].CreatedAt.Before(instances[j].CreatedAt)
	})
}

// GroupByDynamic groups goal instances by their dynamic tags.
// A goal tagged with multiple dynamics appears in each group (AC-GC-8).
func GroupByDynamic(instances []GoalInstance) map[Dynamic][]GoalInstance {
	grouped := make(map[Dynamic][]GoalInstance)
	for _, inst := range instances {
		for _, d := range inst.Dynamics {
			grouped[d] = append(grouped[d], inst)
		}
	}
	// Sort each group by priority.
	for d := range grouped {
		SortInstancesByPriority(grouped[d])
	}
	return grouped
}

// generateInstanceID creates a new goal instance ID with the gi_ prefix.
func generateInstanceID() string {
	return fmt.Sprintf("gi_%d", time.Now().UnixNano())
}

// generateGoalID creates a new goal definition ID with the wdg_ prefix.
func generateGoalID() string {
	return fmt.Sprintf("wdg_%d", time.Now().UnixNano())
}

// generateReviewID creates a new review ID with the gr_ prefix.
func generateReviewID() string {
	return fmt.Sprintf("gr_%d", time.Now().UnixNano())
}

func strPtr(s string) *string {
	return &s
}
