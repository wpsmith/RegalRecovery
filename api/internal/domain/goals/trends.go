// internal/domain/goals/trends.go
package goals

import (
	"sort"
	"time"
)

// ComputeTrends calculates goal completion trends (AC-TI-1 through AC-TI-4).
func ComputeTrends(instances []GoalInstance, period string) *GoalTrends {
	// Group instances by date.
	dateInstances := make(map[string][]GoalInstance)
	for _, inst := range instances {
		dateInstances[inst.Date] = append(dateInstances[inst.Date], inst)
	}

	// Sort dates chronologically.
	var dates []string
	for d := range dateInstances {
		dates = append(dates, d)
	}
	sort.Strings(dates)

	// AC-TI-1: Daily completion rates.
	dailyRates := make([]DailyCompletionRate, 0, len(dates))
	for _, d := range dates {
		insts := dateInstances[d]
		total := len(insts)
		completed := 0
		for _, inst := range insts {
			if inst.Status == StatusCompleted {
				completed++
			}
		}
		rate := 0.0
		if total > 0 {
			rate = float64(completed) / float64(total) * 100
		}
		dailyRates = append(dailyRates, DailyCompletionRate{
			Date:           d,
			CompletionRate: rate,
			TotalGoals:     total,
			CompletedGoals: completed,
		})
	}

	// AC-TI-2: Per-dynamic trends.
	dynamicTrends := computeDynamicTrends(instances, dates)

	// AC-TI-3: Consistency score.
	consistencyScore := ComputeConsistencyScore(dateInstances)

	// AC-TI-4: Streaks.
	streaks := ComputeGoalStreaks(dailyRates)

	// Dynamic balance history (weekly).
	balanceHistory := computeDynamicBalanceHistory(instances)

	return &GoalTrends{
		Period:                period,
		DailyCompletionRates:  dailyRates,
		DynamicTrends:         dynamicTrends,
		ConsistencyScore:      consistencyScore,
		Streaks:               streaks,
		CorrelationInsights:   []CorrelationInsight{},
		DynamicBalanceHistory: balanceHistory,
	}
}

// ComputeConsistencyScore calculates the percentage of days with goals completed
// across 3 or more dynamics (AC-TI-3).
func ComputeConsistencyScore(dateInstances map[string][]GoalInstance) float64 {
	if len(dateInstances) == 0 {
		return 0
	}

	consistentDays := 0
	totalDays := len(dateInstances)

	for _, instances := range dateInstances {
		dynamicsCompleted := make(map[Dynamic]bool)
		for _, inst := range instances {
			if inst.Status == StatusCompleted {
				for _, d := range inst.Dynamics {
					dynamicsCompleted[d] = true
				}
			}
		}
		if len(dynamicsCompleted) >= 3 {
			consistentDays++
		}
	}

	return float64(consistentDays) / float64(totalDays) * 100
}

// ComputeGoalStreaks calculates consecutive day and week streaks (AC-TI-4).
func ComputeGoalStreaks(dailyRates []DailyCompletionRate) GoalStreaks {
	// All-goals-completed streak: consecutive days with 100% completion.
	allCompleted := computeAllGoalsStreak(dailyRates)

	// Weekly 80%+ streak: consecutive weeks with >= 80% completion.
	weeklyStreak := computeWeeklyEightyPercentStreak(dailyRates)

	return GoalStreaks{
		AllGoalsCompleted:   allCompleted,
		WeeklyEightyPercent: weeklyStreak,
	}
}

// computeAllGoalsStreak counts consecutive days with all goals completed
// (100% completion rate), scanning from the most recent day backward.
func computeAllGoalsStreak(dailyRates []DailyCompletionRate) int {
	if len(dailyRates) == 0 {
		return 0
	}

	streak := 0
	// Iterate backward from most recent.
	for i := len(dailyRates) - 1; i >= 0; i-- {
		if dailyRates[i].TotalGoals > 0 && dailyRates[i].CompletedGoals == dailyRates[i].TotalGoals {
			streak++
		} else {
			break
		}
	}
	return streak
}

// computeWeeklyEightyPercentStreak counts consecutive weeks with >= 80% completion.
func computeWeeklyEightyPercentStreak(dailyRates []DailyCompletionRate) int {
	if len(dailyRates) == 0 {
		return 0
	}

	// Group by ISO week.
	type weekData struct {
		total     int
		completed int
	}
	weeks := make(map[string]*weekData)
	var weekKeys []string

	for _, dr := range dailyRates {
		t, err := time.Parse("2006-01-02", dr.Date)
		if err != nil {
			continue
		}
		year, week := t.ISOWeek()
		key := time.Date(year, 1, 1, 0, 0, 0, 0, time.UTC).AddDate(0, 0, (week-1)*7).Format("2006-01-02")
		if _, ok := weeks[key]; !ok {
			weeks[key] = &weekData{}
			weekKeys = append(weekKeys, key)
		}
		weeks[key].total += dr.TotalGoals
		weeks[key].completed += dr.CompletedGoals
	}

	sort.Strings(weekKeys)

	streak := 0
	for i := len(weekKeys) - 1; i >= 0; i-- {
		w := weeks[weekKeys[i]]
		if w.total == 0 {
			break
		}
		rate := float64(w.completed) / float64(w.total) * 100
		if rate >= 80 {
			streak++
		} else {
			break
		}
	}
	return streak
}

// computeDynamicTrends builds per-dynamic trend data.
func computeDynamicTrends(instances []GoalInstance, dates []string) map[string][]DailyCompletionRate {
	// Group by date and dynamic.
	type key struct {
		date    string
		dynamic Dynamic
	}
	counts := make(map[key]struct{ total, completed int })

	for _, inst := range instances {
		for _, d := range inst.Dynamics {
			k := key{date: inst.Date, dynamic: d}
			c := counts[k]
			c.total++
			if inst.Status == StatusCompleted {
				c.completed++
			}
			counts[k] = c
		}
	}

	result := make(map[string][]DailyCompletionRate)
	for _, d := range AllDynamics {
		var rates []DailyCompletionRate
		for _, date := range dates {
			k := key{date: date, dynamic: d}
			c := counts[k]
			rate := 0.0
			if c.total > 0 {
				rate = float64(c.completed) / float64(c.total) * 100
			}
			if c.total > 0 {
				rates = append(rates, DailyCompletionRate{
					Date:           date,
					CompletionRate: rate,
				})
			}
		}
		if len(rates) > 0 {
			result[string(d)] = rates
		}
	}

	return result
}

// computeDynamicBalanceHistory groups instances by week and computes balance per week.
func computeDynamicBalanceHistory(instances []GoalInstance) []WeeklyDynamicBalance {
	// Group by week start (Sunday).
	weekInstances := make(map[string][]GoalInstance)
	var weekStarts []string

	for _, inst := range instances {
		t, err := time.Parse("2006-01-02", inst.Date)
		if err != nil {
			continue
		}
		weekStart := WeekStartDate(t)
		ws := weekStart.Format("2006-01-02")
		if _, ok := weekInstances[ws]; !ok {
			weekStarts = append(weekStarts, ws)
		}
		weekInstances[ws] = append(weekInstances[ws], inst)
	}

	sort.Strings(weekStarts)

	var history []WeeklyDynamicBalance
	for _, ws := range weekStarts {
		balance := ComputeDynamicBalance(weekInstances[ws])
		history = append(history, WeeklyDynamicBalance{
			WeekStart:      ws,
			DynamicBalance: balance,
		})
	}

	return history
}

// WeekStartDate returns the Sunday at the start of the week containing t.
func WeekStartDate(t time.Time) time.Time {
	offset := int(t.Weekday())
	return t.AddDate(0, 0, -offset).Truncate(24 * time.Hour)
}

// WeekEndDate returns the Saturday at the end of the week containing t.
func WeekEndDate(t time.Time) time.Time {
	return WeekStartDate(t).AddDate(0, 0, 6)
}
