// internal/domain/goals/summary.go
package goals

// ComputeDynamicBalance calculates per-dynamic completion counts (AC-DV-3).
func ComputeDynamicBalance(instances []GoalInstance) DynamicBalance {
	totals := make(map[Dynamic]int)
	completed := make(map[Dynamic]int)

	for _, inst := range instances {
		if inst.Status == StatusDismissed {
			continue
		}
		for _, d := range inst.Dynamics {
			totals[d]++
			if inst.Status == StatusCompleted {
				completed[d]++
			}
		}
	}

	mkCount := func(d Dynamic) DynamicCompletionCount {
		t := totals[d]
		c := completed[d]
		rate := 0.0
		if t > 0 {
			rate = float64(c) / float64(t) * 100
		}
		return DynamicCompletionCount{
			Total:          t,
			Completed:      c,
			CompletionRate: rate,
		}
	}

	return DynamicBalance{
		Spiritual:    mkCount(DynamicSpiritual),
		Physical:     mkCount(DynamicPhysical),
		Emotional:    mkCount(DynamicEmotional),
		Intellectual: mkCount(DynamicIntellectual),
		Relational:   mkCount(DynamicRelational),
	}
}

// ComputeDailySummary computes the progress summary for a day (AC-DV-2).
func ComputeDailySummary(instances []GoalInstance) (totalGoals, completedGoals int) {
	for _, inst := range instances {
		if inst.Status == StatusDismissed {
			continue
		}
		totalGoals++
		if inst.Status == StatusCompleted {
			completedGoals++
		}
	}
	return
}

// ComputeWeeklySummary computes the progress summary for a week (AC-WV-2).
func ComputeWeeklySummary(instances []GoalInstance) (totalGoals, completedGoals int, completionRate float64) {
	totalGoals, completedGoals = ComputeDailySummary(instances)
	if totalGoals > 0 {
		completionRate = float64(completedGoals) / float64(totalGoals) * 100
	}
	return
}
