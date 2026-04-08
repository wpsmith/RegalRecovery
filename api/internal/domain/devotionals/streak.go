// internal/domain/devotionals/streak.go
package devotionals

import (
	"context"
	"fmt"
	"time"
)

// StreakCalculator manages devotional streak computation.
type StreakCalculator struct {
	streakRepo DevotionalStreakRepository
}

// NewStreakCalculator creates a new StreakCalculator.
func NewStreakCalculator(streakRepo DevotionalStreakRepository) *StreakCalculator {
	return &StreakCalculator{streakRepo: streakRepo}
}

// RecordCompletion updates the streak after a devotional completion.
// completionDate is the user's local date (YYYY-MM-DD) when the completion occurred.
func (c *StreakCalculator) RecordCompletion(ctx context.Context, userID, completionDate, userTimezone string) (*DevotionalStreak, error) {
	streak, err := c.streakRepo.Get(ctx, userID)
	if err != nil {
		// First completion ever -- create initial streak
		streak = &StreakDoc{
			PK:                fmt.Sprintf("USER#%s", userID),
			SK:                "DEVSTREAK",
			EntityType:        "DEVOTIONAL_STREAK",
			TenantID:          "DEFAULT",
			CreatedAt:         time.Now().UTC(),
			CurrentDays:       0,
			LongestDays:       0,
			LastCompletedDate: nil,
		}
	}

	updated := CalculateStreak(streak.CurrentDays, streak.LongestDays, streak.LastCompletedDate, completionDate, userTimezone)

	streak.CurrentDays = updated.CurrentDays
	streak.LongestDays = updated.LongestDays
	streak.LastCompletedDate = &completionDate
	streak.ModifiedAt = time.Now().UTC()

	if err := c.streakRepo.Upsert(ctx, userID, streak); err != nil {
		return nil, fmt.Errorf("upserting streak: %w", err)
	}

	return &updated, nil
}

// GetStreak retrieves the current devotional streak.
func (c *StreakCalculator) GetStreak(ctx context.Context, userID, userTimezone string) (*DevotionalStreak, error) {
	streak, err := c.streakRepo.Get(ctx, userID)
	if err != nil {
		return &DevotionalStreak{CurrentDays: 0, LongestDays: 0}, nil
	}

	// Check if streak is still active (completed yesterday or today)
	if streak.LastCompletedDate != nil {
		todayStr := UserLocalDate(userTimezone).Format("2006-01-02")
		yesterdayStr := UserLocalDate(userTimezone).AddDate(0, 0, -1).Format("2006-01-02")

		if *streak.LastCompletedDate != todayStr && *streak.LastCompletedDate != yesterdayStr {
			// Streak is broken -- current goes to 0 but longest preserved
			return &DevotionalStreak{
				CurrentDays:       0,
				LongestDays:       streak.LongestDays,
				LastCompletedDate: streak.LastCompletedDate,
			}, nil
		}
	}

	return &DevotionalStreak{
		CurrentDays:       streak.CurrentDays,
		LongestDays:       streak.LongestDays,
		LastCompletedDate: streak.LastCompletedDate,
	}, nil
}

// CalculateStreak computes the updated streak values given the previous state
// and a new completion date.
func CalculateStreak(currentDays, longestDays int, lastCompletedDate *string, completionDate, userTimezone string) DevotionalStreak {
	newCurrent := 1 // At minimum, completing today = streak of 1

	if lastCompletedDate != nil && *lastCompletedDate != "" {
		lastDate, err := time.Parse("2006-01-02", *lastCompletedDate)
		if err == nil {
			compDate, err := time.Parse("2006-01-02", completionDate)
			if err == nil {
				dayDiff := int(compDate.Sub(lastDate).Hours() / 24)
				switch {
				case dayDiff == 1:
					// Consecutive day -- increment streak
					newCurrent = currentDays + 1
				case dayDiff == 0:
					// Same day -- streak unchanged
					newCurrent = currentDays
					if newCurrent == 0 {
						newCurrent = 1
					}
				default:
					// Gap > 1 day -- streak resets to 1
					newCurrent = 1
				}
			}
		}
	}

	newLongest := longestDays
	if newCurrent > newLongest {
		newLongest = newCurrent
	}

	return DevotionalStreak{
		CurrentDays:       newCurrent,
		LongestDays:       newLongest,
		LastCompletedDate: &completionDate,
	}
}
