// internal/domain/goals/review.go
package goals

import "time"

// ProcessDailyReview processes dispositions for the end-of-day review (AC-ED-2, AC-ED-3, AC-ED-5).
// Returns the review record and any carried instances for tomorrow.
func ProcessDailyReview(
	instances []GoalInstance,
	req *SubmitDailyReviewRequest,
	userID, tenantID string,
) (*GoalReview, []GoalInstance, error) {
	if err := ValidateDailyReviewRequest(req); err != nil {
		return nil, nil, err
	}

	// Build lookup of instances by ID.
	instanceMap := make(map[string]*GoalInstance)
	for i := range instances {
		instanceMap[instances[i].GoalInstanceID] = &instances[i]
	}

	// Compute tomorrow's date.
	parsedDate, err := time.Parse("2006-01-02", req.Date)
	if err != nil {
		return nil, nil, err
	}
	tomorrowDate := parsedDate.AddDate(0, 0, 1).Format("2006-01-02")

	var carriedInstances []GoalInstance
	carriedCount := 0
	skippedCount := 0

	for _, disp := range req.Dispositions {
		inst, ok := instanceMap[disp.GoalInstanceID]
		if !ok {
			continue
		}

		switch disp.Action {
		case ActionCarryToTomorrow:
			CarryInstance(inst)
			carried := CreateCarriedInstance(inst, tomorrowDate)
			carriedInstances = append(carriedInstances, carried)
			carriedCount++
		case ActionSkipped:
			SkipInstance(inst)
			skippedCount++
		case ActionNoLongerRelevant:
			SkipInstance(inst)
			skippedCount++
		}
	}

	// Compute summary.
	balance := ComputeDynamicBalance(instances)
	completedCount := 0
	for _, inst := range instances {
		if inst.Status == StatusCompleted {
			completedCount++
		}
	}

	review := &GoalReview{
		ReviewID:    generateReviewID(),
		UserID:      userID,
		TenantID:    tenantID,
		Type:        "daily",
		Date:        req.Date,
		Dispositions: req.Dispositions,
		Reflection:  req.Reflection,
		Summary: &ReviewSummary{
			TotalGoals:     len(instances),
			CompletedGoals: completedCount,
			CarriedGoals:   carriedCount,
			SkippedGoals:   skippedCount,
			DynamicBalance: balance,
		},
		CreatedAt: time.Now().UTC(),
	}

	return review, carriedInstances, nil
}

// ComputeWeeklyStats computes end-of-week statistics (AC-EW-2).
func ComputeWeeklyStats(
	currentWeekInstances []GoalInstance,
	previousWeekInstances []GoalInstance,
) *WeeklyStats {
	total := len(currentWeekInstances)
	completed := 0
	for _, inst := range currentWeekInstances {
		if inst.Status == StatusCompleted {
			completed++
		}
	}

	completionRate := 0.0
	if total > 0 {
		completionRate = float64(completed) / float64(total) * 100
	}

	balance := ComputeDynamicBalance(currentWeekInstances)
	strongest, weakest := FindStrongestWeakest(currentWeekInstances)

	// Previous week comparison.
	prevTotal := len(previousWeekInstances)
	prevCompleted := 0
	for _, inst := range previousWeekInstances {
		if inst.Status == StatusCompleted {
			prevCompleted++
		}
	}
	prevRate := 0.0
	if prevTotal > 0 {
		prevRate = float64(prevCompleted) / float64(prevTotal) * 100
	}

	return &WeeklyStats{
		TotalGoals:                 total,
		CompletedGoals:             completed,
		CompletionRate:             completionRate,
		StrongestDynamic:           strongest,
		WeakestDynamic:             weakest,
		PreviousWeekCompletionRate: prevRate,
		Change:                     completionRate - prevRate,
		DynamicBalance:             balance,
	}
}

// FindStrongestWeakest determines the strongest and weakest dynamics (AC-EW-2).
// No goals set for a dynamic makes it the weakest.
func FindStrongestWeakest(instances []GoalInstance) (strongest, weakest Dynamic) {
	dynamicTotal := make(map[Dynamic]int)
	dynamicCompleted := make(map[Dynamic]int)

	for _, inst := range instances {
		for _, d := range inst.Dynamics {
			dynamicTotal[d]++
			if inst.Status == StatusCompleted {
				dynamicCompleted[d]++
			}
		}
	}

	bestRate := -1.0
	worstRate := 101.0
	strongest = DynamicSpiritual
	weakest = DynamicSpiritual

	for _, d := range AllDynamics {
		total := dynamicTotal[d]
		completed := dynamicCompleted[d]

		if total == 0 {
			// No goals = weakest (AC-EW-2 edge case).
			if worstRate > -1 {
				weakest = d
				worstRate = -1
			}
			continue
		}

		rate := float64(completed) / float64(total) * 100
		if rate > bestRate {
			bestRate = rate
			strongest = d
		}
		if rate < worstRate {
			worstRate = rate
			weakest = d
		}
	}

	return strongest, weakest
}

// WeeklyReflectionPrompts returns the standard weekly reflection prompts.
func WeeklyReflectionPrompts() []string {
	return []string{
		"What was your biggest win this week?",
		"What dynamic needs more attention next week?",
	}
}
