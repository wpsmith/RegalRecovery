// internal/domain/personcheckin/service.go
package personcheckin

import (
	"context"
	"errors"
	"fmt"
	"math/rand"
	"time"

	"github.com/google/uuid"
)

// PersonCheckInService handles person check-in business logic.
type PersonCheckInService struct {
	checkInRepo CheckInRepository
	streakRepo  StreakRepository
	settingsRepo SettingsRepository
	cache       StreakCache
	events      EventPublisher
	goalService GoalService
	permissions PermissionChecker
}

// NewPersonCheckInService creates a new PersonCheckInService with required dependencies.
func NewPersonCheckInService(
	checkInRepo CheckInRepository,
	streakRepo StreakRepository,
	settingsRepo SettingsRepository,
	cache StreakCache,
	events EventPublisher,
	goalService GoalService,
	permissions PermissionChecker,
) *PersonCheckInService {
	return &PersonCheckInService{
		checkInRepo:  checkInRepo,
		streakRepo:   streakRepo,
		settingsRepo: settingsRepo,
		cache:        cache,
		events:       events,
		goalService:  goalService,
		permissions:  permissions,
	}
}

// CreateCheckIn creates a new person check-in entry.
func (s *PersonCheckInService) CreateCheckIn(ctx context.Context, userID, tenantID string, req *CreatePersonCheckInRequest) (*PersonCheckIn, *PersonCheckInStreak, string, error) {
	if err := ValidateCreateRequest(req); err != nil {
		return nil, nil, "", fmt.Errorf("%w", err)
	}

	now := time.Now()
	timestamp := now
	if req.Timestamp != nil {
		timestamp = *req.Timestamp
	}

	checkInID := "pci_" + uuid.New().String()[:8]

	checkIn := &PersonCheckIn{
		CheckInID:            checkInID,
		UserID:               userID,
		TenantID:             tenantID,
		CheckInType:          req.CheckInType,
		Method:               req.Method,
		Timestamp:            timestamp,
		ContactName:          req.ContactName,
		DurationMinutes:      req.DurationMinutes,
		QualityRating:        req.QualityRating,
		TopicsDiscussed:      req.TopicsDiscussed,
		Notes:                req.Notes,
		FollowUpItems:        FollowUpItemsFromStrings(req.FollowUpItems),
		CounselorSubCategory: req.CounselorSubCategory,
		CreatedAt:            timestamp,
		ModifiedAt:           now,
	}

	if err := s.checkInRepo.Create(ctx, checkIn); err != nil {
		return nil, nil, "", fmt.Errorf("creating check-in: %w", err)
	}

	// Update settings with last-used method.
	settings, err := s.settingsRepo.Get(ctx, userID)
	if err != nil {
		settings = DefaultSettings(userID, tenantID)
	}
	UpdateLastUsedMethod(settings, req.CheckInType, req.Method)

	// Auto-save contact name if provided and not already set.
	subSettings := GetSubTypeSettings(settings, req.CheckInType)
	if req.ContactName != nil && (subSettings.ContactName == nil || *subSettings.ContactName == "") {
		subSettings.ContactName = req.ContactName
	}

	_ = s.settingsRepo.Save(ctx, settings)

	// Recalculate streak.
	streak, err := s.recalculateStreak(ctx, userID, tenantID, req.CheckInType, settings)
	if err != nil {
		// Non-fatal: log but don't fail the request.
		streak = &PersonCheckInStreak{CheckInType: req.CheckInType}
	}

	// Publish event.
	_ = s.events.PublishCheckInCreated(ctx, checkIn)

	encouragement := EncouragementMessages[rand.Intn(len(EncouragementMessages))]

	return checkIn, streak, encouragement, nil
}

// QuickLogCheckIn creates a quick-log person check-in.
func (s *PersonCheckInService) QuickLogCheckIn(ctx context.Context, userID, tenantID string, req *QuickLogPersonCheckInRequest) (*PersonCheckIn, *PersonCheckInStreak, string, error) {
	if err := ValidateQuickLogRequest(req); err != nil {
		return nil, nil, "", fmt.Errorf("%w", err)
	}

	settings, err := s.settingsRepo.Get(ctx, userID)
	if err != nil {
		settings = DefaultSettings(userID, tenantID)
	}

	checkInID := "pci_" + uuid.New().String()[:8]
	checkIn := BuildQuickLogCheckIn(req, settings, checkInID, userID, tenantID)

	if err := s.checkInRepo.Create(ctx, checkIn); err != nil {
		return nil, nil, "", fmt.Errorf("creating quick-log check-in: %w", err)
	}

	// Update last-used method.
	UpdateLastUsedMethod(settings, req.CheckInType, checkIn.Method)
	_ = s.settingsRepo.Save(ctx, settings)

	// Recalculate streak.
	streak, err := s.recalculateStreak(ctx, userID, tenantID, req.CheckInType, settings)
	if err != nil {
		streak = &PersonCheckInStreak{CheckInType: req.CheckInType}
	}

	_ = s.events.PublishCheckInCreated(ctx, checkIn)

	encouragement := EncouragementMessages[rand.Intn(len(EncouragementMessages))]

	return checkIn, streak, encouragement, nil
}

// GetCheckIn retrieves a single check-in by ID.
func (s *PersonCheckInService) GetCheckIn(ctx context.Context, userID, checkInID string) (*PersonCheckIn, error) {
	checkIn, err := s.checkInRepo.GetByID(ctx, userID, checkInID)
	if err != nil {
		return nil, fmt.Errorf("retrieving check-in: %w", err)
	}
	if checkIn == nil {
		return nil, ErrCheckInNotFound
	}
	return checkIn, nil
}

// ListCheckIns retrieves check-ins for a user with filtering and pagination.
func (s *PersonCheckInService) ListCheckIns(ctx context.Context, userID string, params ListCheckInsParams) ([]PersonCheckIn, string, error) {
	if params.Limit <= 0 {
		params.Limit = 25
	}
	if params.Limit > 100 {
		params.Limit = 100
	}
	if params.Sort == "" {
		params.Sort = "-timestamp"
	}

	checkIns, nextCursor, err := s.checkInRepo.List(ctx, userID, params)
	if err != nil {
		return nil, "", fmt.Errorf("listing check-ins: %w", err)
	}

	return checkIns, nextCursor, nil
}

// UpdateCheckIn applies a partial update to a check-in.
func (s *PersonCheckInService) UpdateCheckIn(ctx context.Context, userID, checkInID string, req *UpdatePersonCheckInRequest) (*PersonCheckIn, error) {
	if err := ValidateUpdateRequest(req); err != nil {
		return nil, fmt.Errorf("%w", err)
	}

	checkIn, err := s.checkInRepo.GetByID(ctx, userID, checkInID)
	if err != nil {
		return nil, fmt.Errorf("retrieving check-in for update: %w", err)
	}
	if checkIn == nil {
		return nil, ErrCheckInNotFound
	}

	ApplyUpdate(checkIn, req)

	if err := s.checkInRepo.Update(ctx, checkIn); err != nil {
		return nil, fmt.Errorf("updating check-in: %w", err)
	}

	return checkIn, nil
}

// DeleteCheckIn removes a check-in and recalculates streaks.
func (s *PersonCheckInService) DeleteCheckIn(ctx context.Context, userID, tenantID, checkInID string) error {
	checkIn, err := s.checkInRepo.GetByID(ctx, userID, checkInID)
	if err != nil {
		return fmt.Errorf("retrieving check-in for deletion: %w", err)
	}
	if checkIn == nil {
		return ErrCheckInNotFound
	}

	if err := s.checkInRepo.Delete(ctx, userID, checkInID); err != nil {
		return fmt.Errorf("deleting check-in: %w", err)
	}

	// Recalculate streak after deletion.
	settings, err := s.settingsRepo.Get(ctx, userID)
	if err != nil {
		settings = DefaultSettings(userID, tenantID)
	}

	_, _ = s.recalculateStreak(ctx, userID, tenantID, checkIn.CheckInType, settings)

	_ = s.events.PublishCheckInDeleted(ctx, userID, checkInID, checkIn.CheckInType)

	return nil
}

// GetStreaks retrieves all sub-type streaks for a user.
func (s *PersonCheckInService) GetStreaks(ctx context.Context, userID, tenantID string) (*StreaksResponseData, error) {
	settings, err := s.settingsRepo.Get(ctx, userID)
	if err != nil {
		settings = DefaultSettings(userID, tenantID)
	}

	var streaks []PersonCheckInStreak

	for _, ciType := range ValidCheckInTypes {
		// Try cache first.
		streak, err := s.cache.Get(ctx, userID, ciType)
		if err == nil && streak != nil {
			streaks = append(streaks, *streak)
			continue
		}

		// Cache miss: calculate from history.
		streak, err = s.recalculateStreak(ctx, userID, tenantID, ciType, settings)
		if err != nil {
			streaks = append(streaks, PersonCheckInStreak{CheckInType: ciType})
			continue
		}
		streaks = append(streaks, *streak)
	}

	// Calculate combined.
	var totalWeek, totalMonth int
	for _, s := range streaks {
		totalWeek += s.CheckInsThisWeek
		totalMonth += s.CheckInsThisMonth
	}

	return &StreaksResponseData{
		Streaks: streaks,
		Combined: CombinedStreakData{
			TotalCheckInsThisWeek:  totalWeek,
			TotalCheckInsThisMonth: totalMonth,
		},
	}, nil
}

// GetSettings retrieves settings for a user.
func (s *PersonCheckInService) GetSettings(ctx context.Context, userID, tenantID string) (*PersonCheckInSettings, error) {
	settings, err := s.settingsRepo.Get(ctx, userID)
	if err != nil {
		settings = DefaultSettings(userID, tenantID)
		_ = s.settingsRepo.Save(ctx, settings)
	}
	return settings, nil
}

// UpdateSettings applies a partial update to settings.
func (s *PersonCheckInService) UpdateSettings(ctx context.Context, userID, tenantID string, req *UpdateSettingsRequest) (*PersonCheckInSettings, error) {
	if err := ValidateSettingsUpdate(req); err != nil {
		return nil, fmt.Errorf("%w", err)
	}

	settings, err := s.settingsRepo.Get(ctx, userID)
	if err != nil {
		settings = DefaultSettings(userID, tenantID)
	}

	streakFreqChanged := ApplySettingsUpdate(settings, req)

	if err := s.settingsRepo.Save(ctx, settings); err != nil {
		return nil, fmt.Errorf("saving settings: %w", err)
	}

	// FR-PCI-5.1: Streak frequency change triggers full recalculation.
	if streakFreqChanged {
		_ = s.cache.InvalidateAll(ctx, userID)
		for _, ciType := range ValidCheckInTypes {
			_, _ = s.recalculateStreak(ctx, userID, tenantID, ciType, settings)
		}
	}

	return settings, nil
}

// GetTrends retrieves trend data for a user.
func (s *PersonCheckInService) GetTrends(ctx context.Context, userID, tenantID string, period string, checkInType *CheckInType) (*TrendsData, error) {
	days := periodDays(period)
	now := time.Now()
	startDate := now.AddDate(0, 0, -days)

	var checkIns []PersonCheckIn
	var err error

	if checkInType != nil {
		checkIns, err = s.checkInRepo.GetByUserAndType(ctx, userID, *checkInType, startDate, now)
	} else {
		checkIns, _, err = s.checkInRepo.List(ctx, userID, ListCheckInsParams{
			StartDate: &startDate,
			EndDate:   &now,
			Limit:     1000,
			Sort:      "+timestamp",
		})
	}
	if err != nil {
		return nil, fmt.Errorf("retrieving check-ins for trends: %w", err)
	}

	trends := CalculateTrends(checkIns, period, now)
	return &trends, nil
}

// GetCalendar retrieves calendar view data for a month.
func (s *PersonCheckInService) GetCalendar(ctx context.Context, userID, month string) (*CalendarData, error) {
	days, err := s.checkInRepo.GetCalendarMonth(ctx, userID, month)
	if err != nil {
		return nil, fmt.Errorf("retrieving calendar data: %w", err)
	}

	return &CalendarData{
		Month: month,
		Days:  days,
	}, nil
}

// ConvertFollowUpToGoal converts a follow-up item to a goal.
func (s *PersonCheckInService) ConvertFollowUpToGoal(ctx context.Context, userID, checkInID string, index int) (*ConvertFollowUpData, error) {
	checkIn, err := s.checkInRepo.GetByID(ctx, userID, checkInID)
	if err != nil {
		return nil, fmt.Errorf("retrieving check-in: %w", err)
	}
	if checkIn == nil {
		return nil, ErrCheckInNotFound
	}

	if err := ValidateFollowUpIndex(checkIn, index); err != nil {
		return nil, err
	}

	if IsFollowUpAlreadyConverted(checkIn, index) {
		return nil, ErrFollowUpAlreadyConverted
	}

	followUpText := checkIn.FollowUpItems[index].Text

	goalID, err := s.goalService.CreateGoalFromFollowUp(ctx, userID, followUpText)
	if err != nil {
		return nil, fmt.Errorf("creating goal from follow-up: %w", err)
	}

	LinkGoalToFollowUp(checkIn, index, goalID)

	if err := s.checkInRepo.Update(ctx, checkIn); err != nil {
		return nil, fmt.Errorf("updating check-in with goal link: %w", err)
	}

	return &ConvertFollowUpData{
		GoalID:       goalID,
		FollowUpText: followUpText,
		Links: struct {
			Goal    string `json:"goal"`
			CheckIn string `json:"checkIn"`
		}{
			Goal:    fmt.Sprintf("/goals/%s", goalID),
			CheckIn: fmt.Sprintf("/activities/person-check-ins/%s", checkInID),
		},
	}, nil
}

// recalculateStreak recalculates the streak for a specific sub-type from the full check-in history.
func (s *PersonCheckInService) recalculateStreak(ctx context.Context, userID, tenantID string, checkInType CheckInType, settings *PersonCheckInSettings) (*PersonCheckInStreak, error) {
	now := time.Now()
	farPast := now.AddDate(-5, 0, 0) // Look back 5 years.

	checkIns, err := s.checkInRepo.GetByUserAndType(ctx, userID, checkInType, farPast, now)
	if err != nil {
		return nil, fmt.Errorf("retrieving check-ins for streak: %w", err)
	}

	var timestamps []time.Time
	for _, ci := range checkIns {
		timestamps = append(timestamps, ci.Timestamp)
	}

	subSettings := GetSubTypeSettings(settings, checkInType)
	freq := StreakFrequencyDaily
	requiredCount := 1
	if subSettings != nil {
		freq = subSettings.StreakFrequency
		if subSettings.RequiredCountPerWeek != nil {
			requiredCount = *subSettings.RequiredCountPerWeek
		}
	}

	currentStreak, longestStreak := CalculateStreak(timestamps, freq, requiredCount, now)
	thisWeek, thisMonth, avgPerWeek := CalculateFrequencyMetrics(timestamps, now)

	var lastDate *string
	if len(checkIns) > 0 {
		d := checkIns[0].Timestamp.Format("2006-01-02")
		lastDate = &d
	}

	streak := &PersonCheckInStreak{
		CheckInType:       checkInType,
		CurrentStreak:     currentStreak,
		LongestStreak:     longestStreak,
		StreakUnit:         StreakUnitForFrequency(freq),
		CheckInsThisWeek:  thisWeek,
		CheckInsThisMonth: thisMonth,
		AveragePerWeek:    avgPerWeek,
		LastCheckInDate:   lastDate,
	}

	// Save to repo.
	_ = s.streakRepo.SaveStreak(ctx, userID, streak)

	// Cache with 5-minute TTL (NFR-PCI-6).
	_ = s.cache.Set(ctx, userID, checkInType, streak, 300)

	return streak, nil
}

// ListCheckInsForViewer retrieves check-ins filtered by viewer permissions.
func (s *PersonCheckInService) ListCheckInsForViewer(ctx context.Context, ownerUserID, viewerUserID string, params ListCheckInsParams) ([]PersonCheckIn, string, error) {
	hasPermission, err := s.permissions.HasPermission(ctx, ownerUserID, viewerUserID, "person-check-ins")
	if err != nil {
		return nil, "", fmt.Errorf("checking permission: %w", err)
	}

	viewerRole, err := s.permissions.GetViewerRole(ctx, ownerUserID, viewerUserID)
	if err != nil {
		return nil, "", fmt.Errorf("getting viewer role: %w", err)
	}

	if !CanViewPersonCheckIns(hasPermission, viewerRole) {
		return nil, "", ErrCheckInNotFound
	}

	checkIns, nextCursor, err := s.checkInRepo.List(ctx, ownerUserID, params)
	if err != nil {
		return nil, "", fmt.Errorf("listing check-ins: %w", err)
	}

	filtered := FilterCheckInsByViewerRole(checkIns, viewerRole)
	if filtered == nil {
		return nil, "", errors.New("no check-ins visible to viewer")
	}

	return filtered, nextCursor, nil
}
