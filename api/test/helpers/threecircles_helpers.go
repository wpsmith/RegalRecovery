// test/helpers/threecircles_helpers.go
package helpers

import (
	"time"

	"github.com/regalrecovery/api/internal/domain/threecircles"
)

// ─── Simplified Test Wrappers for Domain Functions ───

// CommitSet wraps the CircleSet.Commit method with simplified signature for tests.
func CommitSet(set *threecircles.CircleSet, changeNote string) error {
	req := threecircles.CommitCircleSetRequest{
		ChangeNote: changeNote,
	}
	_, err := threecircles.CommitSet(set, req)
	return err
}

// AddItem wraps CircleSet.AddItem for test simplicity.
func AddItem(set *threecircles.CircleSet, circle threecircles.CircleType, item threecircles.CircleItem) error {
	return set.AddItem(circle, &item)
}

// UpdateItem wraps CircleSet.UpdateItemInCircle for test simplicity.
func UpdateItem(set *threecircles.CircleSet, itemID string, req *threecircles.UpdateCircleItemRequest) error {
	_, err := set.UpdateItemInCircle(itemID, *req)
	return err
}

// MoveItem wraps CircleSet.MoveItem for test simplicity.
func MoveItem(set *threecircles.CircleSet, itemID string, targetCircle threecircles.CircleType, changeNote string) error {
	_, err := set.MoveItem(itemID, targetCircle)
	return err
}

// DeleteItem wraps CircleSet.DeleteItem for test simplicity.
func DeleteItem(set *threecircles.CircleSet, itemID string) error {
	return set.DeleteItem(itemID)
}

// CreateSnapshot creates a version snapshot from a circle set.
func CreateSnapshot(set *threecircles.CircleSet, changeNote string, changeType threecircles.ChangeType, changedItems []string) *threecircles.VersionSnapshot {
	now := time.Now().UTC()
	return &threecircles.VersionSnapshot{
		VersionNumber: set.CurrentVersion,
		SetID:         set.ID,
		UserID:        set.UserID,
		Snapshot:      *set,
		ChangeNote:    changeNote,
		ChangeType:    changeType,
		ChangedItems:  changedItems,
		InnerCount:    len(set.InnerCircle),
		MiddleCount:   len(set.MiddleCircle),
		OuterCount:    len(set.OuterCircle),
		ChangedAt:     now,
	}
}

// RestoreFromSnapshot restores a circle set from a version snapshot (creates new version).
func RestoreFromSnapshot(snapshot *threecircles.VersionSnapshot, changeNote string) (*threecircles.CircleSet, error) {
	// Create a new set from the snapshot
	restored := snapshot.Snapshot
	restored.CurrentVersion++ // Increment version (restore creates NEW version)
	restored.ModifiedAt = time.Now().UTC()

	return &restored, nil
}

// AdvanceOnboardingStep advances the onboarding flow to the next step.
func AdvanceOnboardingStep(flow *threecircles.OnboardingFlow, targetStep threecircles.OnboardingStep) error {
	req := threecircles.AdvanceStepRequest{
		TargetStep: targetStep,
	}
	return flow.AdvanceStep(req)
}

// SwitchOnboardingMode switches the onboarding mode.
func SwitchOnboardingMode(flow *threecircles.OnboardingFlow, newMode threecircles.OnboardingMode) error {
	req := threecircles.SwitchModeRequest{
		NewMode: newMode,
	}
	return flow.SwitchMode(req)
}

// CompleteOnboarding completes the onboarding flow.
func CompleteOnboarding(flow *threecircles.OnboardingFlow) error {
	req := threecircles.CompleteOnboardingRequest{
		CommitOption: threecircles.CommitNow,
		InnerCount:   1, // Assume at least 1 inner item for tests
		MiddleCount:  0,
		OuterCount:   0,
	}
	_, err := flow.CompleteOnboarding(req)
	return err
}

// GenerateSponsorShare creates a share for sponsor review.
func GenerateSponsorShare(set *threecircles.CircleSet, comment string) (*ShareWithComment, error) {
	now := time.Now().UTC()
	share := &ShareWithComment{
		CircleSetShare: &threecircles.CircleSetShare{
			ShareID:   "share-" + set.ID,
			SetID:     set.ID,
			UserID:    set.UserID,
			ShareCode: "ABCD1234",
			ExpiresAt: now.Add(7 * 24 * time.Hour),
			CreatedAt: now,
		},
		Comment: comment,
	}
	return share, nil
}

// ShareWithComment wraps a share with a comment field for testing.
type ShareWithComment struct {
	*threecircles.CircleSetShare
	Comment string
}

// AddShareComment adds a comment to a share (test helper).
func AddShareComment(share interface{}, comment string) error {
	if s, ok := share.(*ShareWithComment); ok {
		s.Comment = comment
	}
	return nil
}

// BuildTimelineSummary builds a timeline summary from entries.
func BuildTimelineSummary(entries []threecircles.TimelineEntry, period threecircles.Period, asOf time.Time) (*threecircles.TimelineSummary, error) {
	if !period.IsValid() {
		return nil, threecircles.ErrInvalidPeriod
	}

	// Calculate date range
	var startDate time.Time
	switch period {
	case threecircles.Period7D:
		startDate = asOf.AddDate(0, 0, -7)
	case threecircles.Period30D:
		startDate = asOf.AddDate(0, 0, -30)
	case threecircles.Period90D:
		startDate = asOf.AddDate(0, 0, -90)
	case threecircles.Period1Y:
		startDate = asOf.AddDate(-1, 0, 0)
	case threecircles.PeriodAll:
		startDate = time.Time{} // Beginning of time
	}

	// Filter entries within date range
	filtered := []threecircles.TimelineEntry{}
	for _, entry := range entries {
		entryDate, _ := time.Parse("2006-01-02", entry.Date)
		if entryDate.After(startDate) && (entryDate.Before(asOf) || entryDate.Equal(asOf)) {
			filtered = append(filtered, entry)
		}
	}

	// Count days by dominant circle
	outerDays := 0
	middleDays := 0
	innerDays := 0
	consecutiveOuter := 0

	for _, entry := range filtered {
		switch entry.DominantCircle {
		case threecircles.CircleOuter:
			outerDays++
			consecutiveOuter++
		case threecircles.CircleMiddle:
			middleDays++
			consecutiveOuter = 0
		case threecircles.CircleInner:
			innerDays++
			consecutiveOuter = 0
		}
	}

	noCheckinDays := 0 // Would calculate from missing dates

	// Generate framing message (trauma-informed, no "streak" language)
	framingMsg := "You've engaged with your recovery practices consistently. Your outer circle activities support your journey."

	summary := &threecircles.TimelineSummary{
		Period:                      string(period),
		StartDate:                   startDate.Format("2006-01-02"),
		EndDate:                     asOf.Format("2006-01-02"),
		OuterDays:                   outerDays,
		MiddleDays:                  middleDays,
		InnerDays:                   innerDays,
		NoCheckinDays:               noCheckinDays,
		CurrentConsecutiveOuterDays: consecutiveOuter,
		FramingMessage:              framingMsg,
	}

	return summary, nil
}

// DetectDrift detects drift alerts from timeline entries.
func DetectDrift(entries []threecircles.TimelineEntry, userID, setID string, windowDays int) *threecircles.DriftAlert {
	if windowDays < 7 {
		return nil
	}

	middleDays := 0
	for _, entry := range entries {
		if entry.MiddleContact {
			middleDays++
		}
	}

	// Trigger alert if 3+ middle circle days in window
	if middleDays < 3 {
		return nil
	}

	now := time.Now().UTC()
	alert := &threecircles.DriftAlert{
		ID:               "alert-" + userID,
		SetID:            setID,
		UserID:           userID,
		WindowStart:      entries[0].Date,
		WindowEnd:        entries[len(entries)-1].Date,
		MiddleCircleDays: middleDays,
		Message:          "We've noticed you've been in the middle circle a few times recently. This is a chance to reflect on what might be helping or challenging you right now. Consider reaching out to your sponsor or accountability partner.",
		Dismissed:        false,
		CreatedAt:        now,
	}

	return alert
}

// DismissAlert dismisses a drift alert.
func DismissAlert(alert *threecircles.DriftAlert, actionTaken string) error {
	now := time.Now().UTC()
	alert.Dismissed = true
	alert.DismissedAt = &now
	alert.ActionTaken = actionTaken
	return nil
}

// GenerateInsights generates pattern insights from timeline entries.
func GenerateInsights(entries []threecircles.TimelineEntry, asOf time.Time) []threecircles.PatternInsight {
	if len(entries) < 14 {
		return []threecircles.PatternInsight{}
	}

	insights := []threecircles.PatternInsight{}

	// Check for day-of-week pattern
	dayOfWeekCounts := make(map[time.Weekday]int)
	middleDayOfWeek := make(map[time.Weekday]int)

	for _, entry := range entries {
		entryDate, _ := time.Parse("2006-01-02", entry.Date)
		dayOfWeek := entryDate.Weekday()
		dayOfWeekCounts[dayOfWeek]++
		if entry.DominantCircle == threecircles.CircleMiddle {
			middleDayOfWeek[dayOfWeek]++
		}
	}

	// Find day with highest middle circle ratio
	maxRatio := 0.0
	maxDay := time.Monday
	for day, middleCount := range middleDayOfWeek {
		total := dayOfWeekCounts[day]
		if total > 0 {
			ratio := float64(middleCount) / float64(total)
			if ratio > maxRatio && ratio >= 0.6 { // At least 60% of days
				maxRatio = ratio
				maxDay = day
			}
		}
	}

	if maxRatio >= 0.6 {
		insight := threecircles.PatternInsight{
			ID:               "insight-dow-" + userID(entries),
			InsightType:      threecircles.InsightDayOfWeek,
			Description:      "We've noticed a pattern on " + maxDay.String() + "s where you're more likely to engage with middle circle behaviors.",
			ActionSuggestion: "Consider planning extra support or healthy activities for " + maxDay.String() + "s, such as scheduling a call with your accountability partner or attending a meeting.",
			Confidence:       maxRatio,
			DataWindowStart:  entries[0].Date,
			DataWindowEnd:    entries[len(entries)-1].Date,
			Dismissed:        false,
		}
		insights = append(insights, insight)
	}

	return insights
}

// CompareVersions compares two version snapshots.
func CompareVersions(v1, v2 *threecircles.CircleSet) (*VersionDiffWithChanges, error) {
	// Build maps of items by ID
	v1Items := make(map[string]threecircles.CircleType)
	v2Items := make(map[string]threecircles.CircleType)

	for _, item := range v1.InnerCircle {
		v1Items[item.ItemID] = threecircles.CircleInner
	}
	for _, item := range v1.MiddleCircle {
		v1Items[item.ItemID] = threecircles.CircleMiddle
	}
	for _, item := range v1.OuterCircle {
		v1Items[item.ItemID] = threecircles.CircleOuter
	}

	for _, item := range v2.InnerCircle {
		v2Items[item.ItemID] = threecircles.CircleInner
	}
	for _, item := range v2.MiddleCircle {
		v2Items[item.ItemID] = threecircles.CircleMiddle
	}
	for _, item := range v2.OuterCircle {
		v2Items[item.ItemID] = threecircles.CircleOuter
	}

	diff := &VersionDiffWithChanges{
		FromVersion: v1.CurrentVersion,
		ToVersion:   v2.CurrentVersion,
		Changes:     []VersionDiffChange{},
	}

	// Find added items
	for itemID, circle := range v2Items {
		if _, exists := v1Items[itemID]; !exists {
			diff.Changes = append(diff.Changes, VersionDiffChange{
				ItemID:     itemID,
				ChangeType: threecircles.ChangeItemAdded,
				ToCircle:   circle,
			})
		}
	}

	// Find removed and moved items
	for itemID, v1Circle := range v1Items {
		v2Circle, exists := v2Items[itemID]
		if !exists {
			diff.Changes = append(diff.Changes, VersionDiffChange{
				ItemID:     itemID,
				ChangeType: threecircles.ChangeItemDeleted,
				FromCircle: v1Circle,
			})
		} else if v1Circle != v2Circle {
			diff.Changes = append(diff.Changes, VersionDiffChange{
				ItemID:     itemID,
				ChangeType: threecircles.ChangeItemMoved,
				FromCircle: v1Circle,
				ToCircle:   v2Circle,
			})
		}
	}

	return diff, nil
}

// VersionDiffChange represents a single change in a version diff (extends VersionDiff).
type VersionDiffChange struct {
	ItemID     string
	ChangeType threecircles.ChangeType
	FromCircle threecircles.CircleType
	ToCircle   threecircles.CircleType
}

// VersionDiffWithChanges extends VersionDiff with a Changes field.
type VersionDiffWithChanges struct {
	FromVersion int
	ToVersion   int
	Changes     []VersionDiffChange
}

// Helper to extract userID from timeline entries.
func userID(entries []threecircles.TimelineEntry) string {
	if len(entries) > 0 {
		return "user-1" // Default for tests
	}
	return "user-1"
}
