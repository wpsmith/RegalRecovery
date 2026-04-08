// internal/domain/nutrition/hydration.go
package nutrition

import (
	"context"
	"fmt"
	"time"
)

// HydrationRepository defines the interface for hydration data access.
type HydrationRepository interface {
	GetHydrationLog(ctx context.Context, userID, date string) (*HydrationLog, error)
	UpsertHydrationLog(ctx context.Context, log *HydrationLog) error
	GetHydrationHistory(ctx context.Context, userID, startDate, endDate string) ([]HydrationLog, error)
}

// HydrationService handles hydration business logic.
type HydrationService struct {
	hydrationRepo HydrationRepository
	settingsRepo  SettingsRepository
}

// NewHydrationService creates a new HydrationService.
func NewHydrationService(hydrationRepo HydrationRepository, settingsRepo SettingsRepository) *HydrationService {
	return &HydrationService{
		hydrationRepo: hydrationRepo,
		settingsRepo:  settingsRepo,
	}
}

// GetTodayStatus returns today's hydration status.
func (s *HydrationService) GetTodayStatus(ctx context.Context, userID string, userTimezone *time.Location) (*HydrationLog, error) {
	date := DateForTimezone(time.Now(), userTimezone)

	log, err := s.hydrationRepo.GetHydrationLog(ctx, userID, date)
	if err != nil {
		return nil, fmt.Errorf("getting hydration log: %w", err)
	}

	// If no log exists for today, return a zero-state with defaults.
	if log == nil {
		settings, err := s.getOrCreateSettings(ctx, userID)
		if err != nil {
			return nil, err
		}

		log = &HydrationLog{
			UserID:              userID,
			Date:                date,
			ServingsLogged:      0,
			ServingSizeOz:       settings.Hydration.ServingSizeOz,
			TotalOunces:         0,
			DailyTargetServings: settings.Hydration.DailyTargetServings,
			GoalMet:             false,
			GoalProgressPercent: 0,
			Entries:             []HydrationEntry{},
			CreatedAt:           time.Now().UTC(),
			ModifiedAt:          time.Now().UTC(),
		}
	}

	return log, nil
}

// LogHydration adds or removes water intake for a given date.
// FR-NUT-3.1: Increment water intake.
// FR-NUT-3.2: Decrement water intake. Cannot go below 0.
// FR-NUT-3.3: Configurable serving size.
// FR-NUT-3.8: Date boundary is determined by user timezone.
func (s *HydrationService) LogHydration(ctx context.Context, userID, tenantID string, req *LogHydrationRequest, userTimezone *time.Location) (*HydrationLog, error) {
	if err := ValidateHydrationLog(req); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	timestamp := now
	if req.Timestamp != nil {
		timestamp = *req.Timestamp
	}

	// FR-NUT-3.8: Use user's timezone for date boundary.
	date := DateForTimezone(timestamp, userTimezone)

	settings, err := s.getOrCreateSettings(ctx, userID)
	if err != nil {
		return nil, err
	}

	log, err := s.hydrationRepo.GetHydrationLog(ctx, userID, date)
	if err != nil {
		return nil, fmt.Errorf("getting hydration log: %w", err)
	}

	if log == nil {
		log = &HydrationLog{
			UserID:              userID,
			TenantID:            tenantID,
			Date:                date,
			ServingsLogged:      0,
			ServingSizeOz:       settings.Hydration.ServingSizeOz,
			TotalOunces:         0,
			DailyTargetServings: settings.Hydration.DailyTargetServings,
			Entries:             []HydrationEntry{},
			CreatedAt:           now,
			ModifiedAt:          now,
		}
	}

	servings := req.Servings
	if servings == 0 {
		servings = 1
	}

	switch req.Action {
	case HydrationActionAdd:
		log.ServingsLogged += servings
	case HydrationActionRemove:
		log.ServingsLogged -= servings
		if log.ServingsLogged < 0 {
			log.ServingsLogged = 0
		}
	}

	// Recalculate derived fields.
	log.TotalOunces = float64(log.ServingsLogged) * log.ServingSizeOz
	log.GoalMet = log.ServingsLogged >= log.DailyTargetServings
	log.GoalProgressPercent = CalculateGoalProgress(log.ServingsLogged, log.DailyTargetServings)
	log.ModifiedAt = now

	// Append the entry for auditability.
	log.Entries = append(log.Entries, HydrationEntry{
		Timestamp: timestamp,
		Servings:  servings,
		Action:    req.Action,
	})

	if err := s.hydrationRepo.UpsertHydrationLog(ctx, log); err != nil {
		return nil, fmt.Errorf("upserting hydration log: %w", err)
	}

	return log, nil
}

// GetHydrationHistory retrieves daily hydration data for a date range.
func (s *HydrationService) GetHydrationHistory(ctx context.Context, userID, startDate, endDate string) ([]HydrationLog, error) {
	logs, err := s.hydrationRepo.GetHydrationHistory(ctx, userID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("getting hydration history: %w", err)
	}
	return logs, nil
}

func (s *HydrationService) getOrCreateSettings(ctx context.Context, userID string) (*NutritionSettings, error) {
	settings, err := s.settingsRepo.GetSettings(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("getting settings: %w", err)
	}
	if settings == nil {
		settings = DefaultNutritionSettings(userID)
	}
	return settings, nil
}
