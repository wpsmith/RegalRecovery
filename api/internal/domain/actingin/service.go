// internal/domain/actingin/service.go
package actingin

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrCheckInNotFound indicates the check-in does not exist.
	ErrCheckInNotFound = errors.New("check-in not found")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input")

	// ErrFeatureDisabled indicates the feature flag is off.
	ErrFeatureDisabled = errors.New("feature not available")
)

const (
	// InsightsCacheTTL is the Valkey cache TTL for insights data.
	InsightsCacheTTL = 5 * time.Minute
)

// Service handles acting-in behaviors business logic.
type Service struct {
	repo           ActingInRepository
	crossTool      CrossToolDataProvider
	insightsCache  InsightsCacheProvider
}

// NewService creates a new acting-in behaviors service.
func NewService(repo ActingInRepository, crossTool CrossToolDataProvider, cache InsightsCacheProvider) *Service {
	return &Service{
		repo:          repo,
		crossTool:     crossTool,
		insightsCache: cache,
	}
}

// GetOrCreateBehaviorConfig retrieves the user's behavior config, creating a new
// one with all defaults enabled if none exists.
func (s *Service) GetOrCreateBehaviorConfig(ctx context.Context, userID string) (*BehaviorConfig, error) {
	config, err := s.repo.GetBehaviorConfig(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("getting behavior config: %w", err)
	}
	if config == nil {
		config = NewBehaviorConfig(userID)
		if err := s.repo.SaveBehaviorConfig(ctx, config); err != nil {
			return nil, fmt.Errorf("creating default behavior config: %w", err)
		}
	}
	return config, nil
}

// ListBehaviors returns all behaviors (defaults + custom) for the user.
func (s *Service) ListBehaviors(ctx context.Context, userID string) ([]Behavior, error) {
	config, err := s.GetOrCreateBehaviorConfig(ctx, userID)
	if err != nil {
		return nil, err
	}
	return config.GetAllBehaviors(), nil
}

// CreateCustomBehavior adds a new custom behavior.
func (s *Service) CreateCustomBehavior(ctx context.Context, userID string, req *CreateCustomBehaviorRequest) (*Behavior, error) {
	config, err := s.GetOrCreateBehaviorConfig(ctx, userID)
	if err != nil {
		return nil, err
	}

	behavior, err := config.CreateCustomBehavior(req.Name, req.Description)
	if err != nil {
		return nil, err
	}

	if err := s.repo.SaveBehaviorConfig(ctx, config); err != nil {
		return nil, fmt.Errorf("saving behavior config: %w", err)
	}

	return behavior, nil
}

// UpdateCustomBehavior updates an existing custom behavior.
func (s *Service) UpdateCustomBehavior(ctx context.Context, userID, behaviorID string, req *UpdateCustomBehaviorRequest) (*Behavior, error) {
	config, err := s.GetOrCreateBehaviorConfig(ctx, userID)
	if err != nil {
		return nil, err
	}

	behavior, err := config.UpdateCustomBehavior(behaviorID, req.Name, req.Description)
	if err != nil {
		return nil, err
	}

	if err := s.repo.SaveBehaviorConfig(ctx, config); err != nil {
		return nil, fmt.Errorf("saving behavior config: %w", err)
	}

	return behavior, nil
}

// DeleteCustomBehavior removes a custom behavior.
func (s *Service) DeleteCustomBehavior(ctx context.Context, userID, behaviorID string) error {
	config, err := s.GetOrCreateBehaviorConfig(ctx, userID)
	if err != nil {
		return err
	}

	if err := config.DeleteCustomBehavior(behaviorID); err != nil {
		return err
	}

	if err := s.repo.SaveBehaviorConfig(ctx, config); err != nil {
		return fmt.Errorf("saving behavior config: %w", err)
	}

	return nil
}

// ToggleBehavior enables or disables a behavior.
func (s *Service) ToggleBehavior(ctx context.Context, userID, behaviorID string, enabled bool) (*Behavior, error) {
	config, err := s.GetOrCreateBehaviorConfig(ctx, userID)
	if err != nil {
		return nil, err
	}

	behavior, err := config.ToggleBehavior(behaviorID, enabled)
	if err != nil {
		return nil, err
	}

	if err := s.repo.SaveBehaviorConfig(ctx, config); err != nil {
		return nil, fmt.Errorf("saving behavior config: %w", err)
	}

	return behavior, nil
}

// SubmitCheckIn validates and records an acting-in check-in.
func (s *Service) SubmitCheckIn(ctx context.Context, userID string, req *CreateCheckInRequest) (*CheckIn, error) {
	config, err := s.GetOrCreateBehaviorConfig(ctx, userID)
	if err != nil {
		return nil, err
	}

	if err := ValidateCheckInRequest(req, config); err != nil {
		return nil, err
	}

	// Get current settings for streak calculation.
	settings, err := s.GetOrCreateSettings(ctx, userID)
	if err != nil {
		return nil, err
	}

	checkIn := CreateCheckIn(req, config, settings.StreakCount)

	// Persist the check-in.
	if err := s.repo.CreateCheckIn(ctx, checkIn); err != nil {
		return nil, fmt.Errorf("creating check-in: %w", err)
	}

	// Dual-write to calendar.
	if err := s.repo.CreateCalendarActivity(ctx, userID, checkIn); err != nil {
		// Log but don't fail -- calendar is secondary.
		_ = err
	}

	// Update streak.
	settings.StreakCount++
	now := time.Now().UTC()
	settings.LastCheckInAt = &now
	settings.ModifiedAt = now
	if err := s.repo.SaveSettings(ctx, settings); err != nil {
		return nil, fmt.Errorf("updating settings: %w", err)
	}

	// Invalidate insights cache.
	if s.insightsCache != nil {
		_ = s.insightsCache.InvalidateInsightsCache(ctx, userID)
	}

	return checkIn, nil
}

// GetCheckIn retrieves a specific check-in.
func (s *Service) GetCheckIn(ctx context.Context, userID, checkInID string) (*CheckIn, error) {
	checkIn, err := s.repo.GetCheckIn(ctx, userID, checkInID)
	if err != nil {
		return nil, fmt.Errorf("getting check-in: %w", err)
	}
	if checkIn == nil {
		return nil, ErrCheckInNotFound
	}
	return checkIn, nil
}

// ListCheckIns retrieves check-ins with pagination and filters.
func (s *Service) ListCheckIns(ctx context.Context, userID string, filters CheckInFilters, cursor string, limit int) ([]CheckIn, string, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	return s.repo.ListCheckIns(ctx, userID, filters, cursor, limit)
}

// GetFrequencyInsights returns behavior frequency insights for the given range.
func (s *Service) GetFrequencyInsights(ctx context.Context, userID string, r InsightsRange) (*FrequencyInsights, error) {
	days := RangeToDays(r)
	start := time.Now().UTC().AddDate(0, 0, -days*2) // Fetch 2x range for trend comparison.
	end := time.Now().UTC()

	checkIns, err := s.repo.GetCheckInsByDateRange(ctx, userID, start, end)
	if err != nil {
		return nil, fmt.Errorf("getting check-ins for insights: %w", err)
	}

	return CalculateFrequencyInsights(checkIns, r), nil
}

// GetTriggerInsights returns trigger analysis for the given range.
func (s *Service) GetTriggerInsights(ctx context.Context, userID string, r InsightsRange) (*TriggerInsights, error) {
	days := RangeToDays(r)
	start := time.Now().UTC().AddDate(0, 0, -days)
	end := time.Now().UTC()

	checkIns, err := s.repo.GetCheckInsByDateRange(ctx, userID, start, end)
	if err != nil {
		return nil, fmt.Errorf("getting check-ins for trigger insights: %w", err)
	}

	return CalculateTriggerInsights(checkIns, r), nil
}

// GetRelationshipInsights returns relationship impact insights for the given range.
func (s *Service) GetRelationshipInsights(ctx context.Context, userID string, r InsightsRange) (*RelationshipInsights, error) {
	days := RangeToDays(r)
	start := time.Now().UTC().AddDate(0, 0, -days*2)
	end := time.Now().UTC()

	checkIns, err := s.repo.GetCheckInsByDateRange(ctx, userID, start, end)
	if err != nil {
		return nil, fmt.Errorf("getting check-ins for relationship insights: %w", err)
	}

	return CalculateRelationshipInsights(checkIns, r), nil
}

// GetHeatmapInsights returns heatmap data for the given range.
func (s *Service) GetHeatmapInsights(ctx context.Context, userID string, r InsightsRange) (*HeatmapInsights, error) {
	days := RangeToDays(r)
	start := time.Now().UTC().AddDate(0, 0, -days)
	end := time.Now().UTC()

	checkIns, err := s.repo.GetCheckInsByDateRange(ctx, userID, start, end)
	if err != nil {
		return nil, fmt.Errorf("getting check-ins for heatmap: %w", err)
	}

	return CalculateHeatmap(checkIns, r, nil), nil
}

// GetCrossToolInsights returns cross-tool correlation data.
func (s *Service) GetCrossToolInsights(ctx context.Context, userID string, r InsightsRange) (*CrossToolInsights, error) {
	days := RangeToDays(r)
	start := time.Now().UTC().AddDate(0, 0, -days)
	end := time.Now().UTC()

	checkIns, err := s.repo.GetCheckInsByDateRange(ctx, userID, start, end)
	if err != nil {
		return nil, fmt.Errorf("getting check-ins for cross-tool insights: %w", err)
	}

	// Fetch cross-tool data -- gracefully handle missing data.
	var pciData []PciDayData
	var fasterData []FasterEntry
	var postMortems []PostMortemEntry

	if s.crossTool != nil {
		pciData, _ = s.crossTool.GetPciData(ctx, userID, start, end)
		fasterData, _ = s.crossTool.GetFasterData(ctx, userID, start, end)
		postMortems, _ = s.crossTool.GetPostMortemData(ctx, userID)
	}

	return CalculateCrossToolInsights(checkIns, pciData, fasterData, postMortems, r), nil
}

// ExportHistory generates an export of check-in history.
func (s *Service) ExportHistory(ctx context.Context, userID string, format ExportFormat, startDate, endDate *time.Time) ([]byte, string, error) {
	// Determine date range for fetching data.
	fetchStart := time.Time{}
	fetchEnd := time.Now().UTC()
	if startDate != nil {
		fetchStart = *startDate
	}
	if endDate != nil {
		fetchEnd = *endDate
	}

	checkIns, err := s.repo.GetCheckInsByDateRange(ctx, userID, fetchStart, fetchEnd)
	if err != nil {
		return nil, "", fmt.Errorf("getting check-ins for export: %w", err)
	}

	switch format {
	case ExportCSV:
		data := ExportCSVData(checkIns, startDate, endDate)
		return data, "text/csv", nil
	case ExportPDF:
		data := ExportPDFData(checkIns, startDate, endDate)
		return data, "application/pdf", nil
	default:
		return nil, "", fmt.Errorf("unsupported export format: %s", format)
	}
}

// GetOrCreateSettings retrieves the user's settings, creating defaults if none exist.
func (s *Service) GetOrCreateSettings(ctx context.Context, userID string) (*Settings, error) {
	settings, err := s.repo.GetSettings(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("getting settings: %w", err)
	}
	if settings == nil {
		settings = DefaultSettings(userID)
		if err := s.repo.SaveSettings(ctx, settings); err != nil {
			return nil, fmt.Errorf("creating default settings: %w", err)
		}
	}
	return settings, nil
}

// UpdateSettings updates the user's acting-in settings.
func (s *Service) UpdateSettings(ctx context.Context, userID string, req *UpdateSettingsRequest) (*Settings, error) {
	settings, err := s.GetOrCreateSettings(ctx, userID)
	if err != nil {
		return nil, err
	}

	freqChanged, err := ApplySettingsUpdate(settings, req)
	if err != nil {
		return nil, err
	}

	// If frequency changed, recalculate streak.
	if freqChanged {
		dates, err := s.repo.GetCheckInDates(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("getting check-in dates for streak recalculation: %w", err)
		}
		settings.StreakCount = RecalculateStreakOnFrequencyChange(settings.Frequency, dates, nil)
	}

	if err := s.repo.SaveSettings(ctx, settings); err != nil {
		return nil, fmt.Errorf("saving settings: %w", err)
	}

	return settings, nil
}
