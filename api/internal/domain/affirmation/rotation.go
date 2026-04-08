// internal/domain/affirmation/rotation.go
package affirmation

import (
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"sort"
	"time"
)

// SelectDailyAffirmation selects today's affirmation based on the user's rotation mode,
// owned packs, sobriety level, and contextual state.
//
// The selection is deterministic: same userId + same date = same affirmation.
func SelectDailyAffirmation(ctx SelectionContext, pool []Affirmation) (*Affirmation, ReadSource, error) {
	if len(pool) == 0 {
		return nil, "", fmt.Errorf("no affirmations available in pool")
	}

	state := ctx.RotationState
	if state == nil {
		// Default to random automatic
		state = &RotationState{SelectionMode: ModeRandomAutomatic}
	}

	maxLevel := GetEffectiveMaxLevel(ctx.CumulativeDays, ctx.SobrietyResetAt, ctx.SOSMode)
	hsAccessible := IsHealthySexualityAccessible(ctx.CumulativeDays, state.HealthySexualityOptIn)
	filtered := FilterByLevel(pool, maxLevel, hsAccessible)

	if len(filtered) == 0 {
		return nil, "", fmt.Errorf("no affirmations available after level filtering")
	}

	switch state.SelectionMode {
	case ModeIndividuallyChosen:
		return selectIndividuallyChosen(state, filtered)
	case ModeRandomAutomatic:
		return selectRandomAutomatic(ctx, filtered, state)
	case ModePermanentPackage:
		return selectPermanentPackage(ctx, filtered, state)
	case ModeDayOfWeekPackage:
		return selectDayOfWeek(ctx, filtered, state)
	default:
		return selectRandomAutomatic(ctx, filtered, state)
	}
}

// GetContextualAffirmation selects an affirmation relevant to a specific trigger category.
// This always overrides the current rotation mode.
func GetContextualAffirmation(ctx SelectionContext, pool []Affirmation, trigger TriggerCategory) (*Affirmation, error) {
	maxLevel := GetEffectiveMaxLevel(ctx.CumulativeDays, ctx.SobrietyResetAt, ctx.SOSMode)
	hsAccessible := false // Never show HS content in trigger context
	filtered := FilterByLevel(pool, maxLevel, hsAccessible)

	triggerTag := "trigger_" + string(trigger)
	var triggerMatches []Affirmation
	for _, a := range filtered {
		for _, tag := range a.Tags {
			if tag == triggerTag {
				triggerMatches = append(triggerMatches, a)
				break
			}
		}
	}

	if len(triggerMatches) == 0 {
		// Fallback to any affirmation at appropriate level
		if len(filtered) == 0 {
			return nil, fmt.Errorf("no affirmations available for trigger %s", trigger)
		}
		idx := deterministicIndex(ctx.UserID, ctx.Date, len(filtered))
		return &filtered[idx], nil
	}

	idx := deterministicIndex(ctx.UserID, ctx.Date, len(triggerMatches))
	return &triggerMatches[idx], nil
}

// BuildWeightedPool constructs a weighted pool of affirmations for random automatic mode.
// Weighting: triggers 40%, favorites 30%, under-served categories 20%, random 10%.
func BuildWeightedPool(
	affirmations []Affirmation,
	favorites []string,
	recentTriggers []string,
	categoryReadCounts map[string]int,
) []WeightedAffirmation {
	favoriteSet := make(map[string]bool)
	for _, f := range favorites {
		favoriteSet[f] = true
	}

	triggerTagSet := make(map[string]bool)
	for _, t := range recentTriggers {
		triggerTagSet["trigger_"+t] = true
	}

	// Find under-served categories (below average reads)
	totalReads := 0
	categoryCount := 0
	for _, count := range categoryReadCounts {
		totalReads += count
		categoryCount++
	}
	avgReads := 0.0
	if categoryCount > 0 {
		avgReads = float64(totalReads) / float64(categoryCount)
	}
	underServed := make(map[string]bool)
	for cat, count := range categoryReadCounts {
		if float64(count) < avgReads {
			underServed[cat] = true
		}
	}

	weighted := make([]WeightedAffirmation, len(affirmations))
	for i, a := range affirmations {
		weight := 0.10 // Base random weight: 10%

		// Trigger relevance: +40%
		for _, tag := range a.Tags {
			if triggerTagSet[tag] {
				weight += 0.40
				break
			}
		}

		// Favorite boost: +30%
		if favoriteSet[a.AffirmationID] {
			weight += 0.30
		}

		// Under-served category boost: +20%
		if underServed[string(a.Category)] {
			weight += 0.20
		}

		weighted[i] = WeightedAffirmation{
			Affirmation: a,
			Weight:      weight,
		}
	}

	return weighted
}

// IsScheduledForToday returns whether a custom affirmation is scheduled for the given day.
func IsScheduledForToday(schedule Schedule, customDays []string, today time.Weekday) bool {
	switch schedule {
	case ScheduleDaily:
		return true
	case ScheduleWeekdays:
		return today >= time.Monday && today <= time.Friday
	case ScheduleWeekends:
		return today == time.Saturday || today == time.Sunday
	case ScheduleCustom:
		dayName := dayOfWeekName(today)
		for _, d := range customDays {
			if d == dayName {
				return true
			}
		}
		return false
	default:
		return false
	}
}

func selectIndividuallyChosen(state *RotationState, pool []Affirmation) (*Affirmation, ReadSource, error) {
	if state.ChosenAffirmationID == nil {
		return nil, "", fmt.Errorf("no affirmation chosen in individuallyChosen mode")
	}
	for _, a := range pool {
		if a.AffirmationID == *state.ChosenAffirmationID {
			return &a, SourceManualChoice, nil
		}
	}
	return nil, "", fmt.Errorf("chosen affirmation %s not found in available pool", *state.ChosenAffirmationID)
}

func selectRandomAutomatic(ctx SelectionContext, pool []Affirmation, state *RotationState) (*Affirmation, ReadSource, error) {
	// Filter out already-shown in current cycle
	unshown := filterUnshown(pool, state.RotationCycleShown)
	if len(unshown) == 0 {
		// Cycle complete, reset
		unshown = pool
	}

	idx := deterministicIndex(ctx.UserID, ctx.Date, len(unshown))
	return &unshown[idx], SourceDaily, nil
}

func selectPermanentPackage(ctx SelectionContext, pool []Affirmation, state *RotationState) (*Affirmation, ReadSource, error) {
	if state.ActivePackID == nil {
		return nil, "", fmt.Errorf("no active pack set for permanentPackage mode")
	}

	var packAffirmations []Affirmation
	for _, a := range pool {
		if a.PackID == *state.ActivePackID {
			packAffirmations = append(packAffirmations, a)
		}
	}
	if len(packAffirmations) == 0 {
		return nil, "", fmt.Errorf("no affirmations found in pack %s", *state.ActivePackID)
	}

	sort.Slice(packAffirmations, func(i, j int) bool {
		return packAffirmations[i].SortOrder < packAffirmations[j].SortOrder
	})

	// Determine position in cycle based on days since start
	daysSinceStart := int(ctx.Date.Sub(time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)).Hours() / 24)
	idx := daysSinceStart % len(packAffirmations)
	return &packAffirmations[idx], SourcePackageCycle, nil
}

func selectDayOfWeek(ctx SelectionContext, pool []Affirmation, state *RotationState) (*Affirmation, ReadSource, error) {
	if state.DayOfWeekAssignments == nil {
		return nil, "", fmt.Errorf("no day-of-week assignments set")
	}

	dayName := dayOfWeekName(ctx.Date.Weekday())
	affID, ok := state.DayOfWeekAssignments[dayName]
	if !ok {
		return nil, "", fmt.Errorf("no affirmation assigned for %s", dayName)
	}

	for _, a := range pool {
		if a.AffirmationID == affID {
			return &a, SourceDayOfWeek, nil
		}
	}
	return nil, "", fmt.Errorf("assigned affirmation %s not found for %s", affID, dayName)
}

// deterministicIndex produces a deterministic index from userId + date.
func deterministicIndex(userID string, date time.Time, poolSize int) int {
	if poolSize == 0 {
		return 0
	}
	dateStr := date.Format("2006-01-02")
	hash := sha256.Sum256([]byte(userID + dateStr))
	n := binary.BigEndian.Uint64(hash[:8])
	return int(n % uint64(poolSize))
}

func filterUnshown(pool []Affirmation, shown []string) []Affirmation {
	shownSet := make(map[string]bool)
	for _, id := range shown {
		shownSet[id] = true
	}
	var unshown []Affirmation
	for _, a := range pool {
		if !shownSet[a.AffirmationID] {
			unshown = append(unshown, a)
		}
	}
	return unshown
}

func dayOfWeekName(day time.Weekday) string {
	switch day {
	case time.Monday:
		return "monday"
	case time.Tuesday:
		return "tuesday"
	case time.Wednesday:
		return "wednesday"
	case time.Thursday:
		return "thursday"
	case time.Friday:
		return "friday"
	case time.Saturday:
		return "saturday"
	case time.Sunday:
		return "sunday"
	default:
		return "monday"
	}
}
