// internal/domain/phonecalls/service.go
package phonecalls

import (
	"context"
	"errors"
	"fmt"
	"time"
)

// PhoneCallRepository defines the persistence interface for phone call data.
type PhoneCallRepository interface {
	// Create persists a new phone call log and its calendar dual-write.
	Create(ctx context.Context, call *PhoneCall) error

	// GetByID retrieves a phone call by user ID and call ID.
	GetByID(ctx context.Context, userID, callID string) (*PhoneCall, error)

	// List retrieves phone calls for a user with filters and cursor pagination.
	// Returns calls and the next cursor token.
	List(ctx context.Context, userID string, filters ListFilters, cursor string, limit int) ([]PhoneCall, string, error)

	// Update applies a partial update to a phone call. Returns the updated call.
	Update(ctx context.Context, userID, callID string, req *UpdatePhoneCallRequest) (*PhoneCall, error)

	// Delete removes a phone call and its calendar dual-write.
	Delete(ctx context.Context, userID, callID string) error

	// GetByDateRange retrieves all calls for a user within a date range.
	GetByDateRange(ctx context.Context, userID string, start, end time.Time) ([]PhoneCall, error)

	// GetAll retrieves all calls for a user (used for streak/trend calculations).
	GetAll(ctx context.Context, userID string) ([]PhoneCall, error)
}

// SavedContactRepository defines the persistence interface for saved contact data.
type SavedContactRepository interface {
	// Create persists a new saved contact.
	Create(ctx context.Context, contact *SavedContact) error

	// List retrieves all saved contacts for a user.
	List(ctx context.Context, userID string) ([]SavedContact, error)

	// GetByID retrieves a saved contact by ID.
	GetByID(ctx context.Context, userID, savedContactID string) (*SavedContact, error)

	// Update applies a partial update to a saved contact. Returns the updated contact.
	Update(ctx context.Context, userID, savedContactID string, req *UpdateSavedContactRequest) (*SavedContact, error)

	// Delete removes a saved contact. Historical call logs are preserved.
	Delete(ctx context.Context, userID, savedContactID string) error

	// Count returns the number of saved contacts for a user.
	Count(ctx context.Context, userID string) (int, error)
}

// StreakCache defines the cache interface for phone call streak data.
type StreakCache interface {
	// Get retrieves the cached streak. Returns nil on cache miss.
	Get(ctx context.Context, userID string) (*PhoneCallStreak, error)

	// Set caches a streak with the given TTL in seconds.
	Set(ctx context.Context, userID string, streak *PhoneCallStreak, ttl int) error

	// Invalidate removes the cached streak.
	Invalidate(ctx context.Context, userID string) error
}

// PhoneCallService contains business logic for the phone calls feature.
type PhoneCallService struct {
	callRepo    PhoneCallRepository
	contactRepo SavedContactRepository
	cache       StreakCache
}

// NewPhoneCallService creates a new service with the given dependencies.
func NewPhoneCallService(
	callRepo PhoneCallRepository,
	contactRepo SavedContactRepository,
	cache StreakCache,
) *PhoneCallService {
	return &PhoneCallService{
		callRepo:    callRepo,
		contactRepo: contactRepo,
		cache:       cache,
	}
}

// streakCacheTTL is the TTL for cached streak data (5 minutes).
const streakCacheTTL = 300

// CreateCall creates a new phone call log entry.
func (s *PhoneCallService) CreateCall(ctx context.Context, userID, tenantID string, req *CreatePhoneCallRequest) (*PhoneCall, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", errors.New("invalid input"))
	}

	if err := ValidateCreateRequest(req); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	timestamp := now
	if req.Timestamp != nil {
		timestamp = *req.Timestamp
	}

	call := &PhoneCall{
		CallID:             generateCallID(),
		UserID:             userID,
		TenantID:           tenantID,
		Timestamp:          timestamp,
		Direction:          req.Direction,
		ContactType:        req.ContactType,
		CustomContactLabel: req.CustomContactLabel,
		Connected:          req.Connected,
		ContactName:        req.ContactName,
		SavedContactID:     req.SavedContactID,
		DurationMinutes:    req.DurationMinutes,
		Notes:              req.Notes,
		CreatedAt:          now,
		ModifiedAt:         now,
	}

	if err := s.callRepo.Create(ctx, call); err != nil {
		return nil, fmt.Errorf("creating phone call: %w", err)
	}

	// Invalidate streak cache since a new call was logged.
	_ = s.cache.Invalidate(ctx, userID)

	// Calculate current streak to include in response.
	streak, err := s.getOrCalculateStreak(ctx, userID)
	if err == nil {
		call.CallStreakDays = streak.CurrentStreakDays
	}

	// Set cross-reference prompt.
	prompt := "You logged a call. Would you also like to log a person check-in?"
	call.CrossRefPrompt = &prompt

	return call, nil
}

// GetCall retrieves a phone call by ID.
func (s *PhoneCallService) GetCall(ctx context.Context, userID, callID string) (*PhoneCall, error) {
	call, err := s.callRepo.GetByID(ctx, userID, callID)
	if err != nil {
		return nil, fmt.Errorf("retrieving phone call: %w", err)
	}
	if call == nil {
		return nil, ErrPhoneCallNotFound
	}
	return call, nil
}

// ListCalls retrieves phone calls with filters and pagination.
func (s *PhoneCallService) ListCalls(ctx context.Context, userID string, filters ListFilters, cursor string, limit int) ([]PhoneCall, string, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	return s.callRepo.List(ctx, userID, filters, cursor, limit)
}

// UpdateCall applies a partial update to a phone call.
func (s *PhoneCallService) UpdateCall(ctx context.Context, userID, callID string, req *UpdatePhoneCallRequest) (*PhoneCall, error) {
	if err := ValidateUpdateRequest(req); err != nil {
		return nil, err
	}

	// Verify the call exists and belongs to the user.
	existing, err := s.callRepo.GetByID(ctx, userID, callID)
	if err != nil {
		return nil, fmt.Errorf("retrieving phone call: %w", err)
	}
	if existing == nil {
		return nil, ErrPhoneCallNotFound
	}

	updated, err := s.callRepo.Update(ctx, userID, callID, req)
	if err != nil {
		return nil, fmt.Errorf("updating phone call: %w", err)
	}

	return updated, nil
}

// DeleteCall removes a phone call.
func (s *PhoneCallService) DeleteCall(ctx context.Context, userID, callID string) error {
	// Verify the call exists and belongs to the user.
	existing, err := s.callRepo.GetByID(ctx, userID, callID)
	if err != nil {
		return fmt.Errorf("retrieving phone call: %w", err)
	}
	if existing == nil {
		return ErrPhoneCallNotFound
	}

	if err := s.callRepo.Delete(ctx, userID, callID); err != nil {
		return fmt.Errorf("deleting phone call: %w", err)
	}

	// Invalidate streak cache since a call was deleted.
	_ = s.cache.Invalidate(ctx, userID)

	return nil
}

// GetStreak retrieves the current call streak, using cache-aside pattern.
func (s *PhoneCallService) GetStreak(ctx context.Context, userID string) (*PhoneCallStreak, error) {
	return s.getOrCalculateStreak(ctx, userID)
}

// GetTrends computes phone call trends for a given period.
func (s *PhoneCallService) GetTrends(ctx context.Context, userID string, period TrendPeriod, isolationThreshold int) (*PhoneCallTrends, error) {
	calls, err := s.callRepo.GetAll(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("retrieving calls for trends: %w", err)
	}

	trends := CalculateTrends(calls, period, isolationThreshold, nil)
	return &trends, nil
}

// GetDailyTrends computes per-day call counts for charting.
func (s *PhoneCallService) GetDailyTrends(ctx context.Context, userID string, period TrendPeriod) ([]DailyCallCount, error) {
	calls, err := s.callRepo.GetAll(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("retrieving calls for daily trends: %w", err)
	}

	return CalculateDailyTrends(calls, period, nil), nil
}

// CreateSavedContact creates a new saved contact.
func (s *PhoneCallService) CreateSavedContact(ctx context.Context, userID, tenantID string, req *CreateSavedContactRequest) (*SavedContact, error) {
	if err := ValidateCreateSavedContactRequest(req); err != nil {
		return nil, err
	}

	count, err := s.contactRepo.Count(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("counting saved contacts: %w", err)
	}
	if err := ValidateCanAddSavedContact(count); err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	contact := &SavedContact{
		SavedContactID: generateSavedContactID(),
		UserID:         userID,
		TenantID:       tenantID,
		ContactName:    req.ContactName,
		ContactType:    req.ContactType,
		PhoneNumber:    req.PhoneNumber,
		HasPhoneNumber: req.PhoneNumber != nil,
		CreatedAt:      now,
		ModifiedAt:     now,
	}

	if err := s.contactRepo.Create(ctx, contact); err != nil {
		return nil, fmt.Errorf("creating saved contact: %w", err)
	}

	return contact, nil
}

// ListSavedContacts retrieves all saved contacts for a user.
func (s *PhoneCallService) ListSavedContacts(ctx context.Context, userID string) ([]SavedContact, error) {
	return s.contactRepo.List(ctx, userID)
}

// UpdateSavedContact applies a partial update to a saved contact.
func (s *PhoneCallService) UpdateSavedContact(ctx context.Context, userID, savedContactID string, req *UpdateSavedContactRequest) (*SavedContact, error) {
	existing, err := s.contactRepo.GetByID(ctx, userID, savedContactID)
	if err != nil {
		return nil, fmt.Errorf("retrieving saved contact: %w", err)
	}
	if existing == nil {
		return nil, ErrSavedContactNotFound
	}

	return s.contactRepo.Update(ctx, userID, savedContactID, req)
}

// DeleteSavedContact removes a saved contact (preserves historical logs).
func (s *PhoneCallService) DeleteSavedContact(ctx context.Context, userID, savedContactID string) error {
	existing, err := s.contactRepo.GetByID(ctx, userID, savedContactID)
	if err != nil {
		return fmt.Errorf("retrieving saved contact: %w", err)
	}
	if existing == nil {
		return ErrSavedContactNotFound
	}

	return s.contactRepo.Delete(ctx, userID, savedContactID)
}

// getOrCalculateStreak retrieves streak from cache or calculates from DB.
func (s *PhoneCallService) getOrCalculateStreak(ctx context.Context, userID string) (*PhoneCallStreak, error) {
	// Try cache first.
	cached, err := s.cache.Get(ctx, userID)
	if err == nil && cached != nil {
		return cached, nil
	}

	// Cache miss: calculate from DB.
	calls, err := s.callRepo.GetAll(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("retrieving calls for streak: %w", err)
	}

	streak := CalculateStreak(calls, nil)
	// Cache the result.
	_ = s.cache.Set(ctx, userID, &streak, streakCacheTTL)

	return &streak, nil
}

// generateCallID creates a new call ID with the pc_ prefix.
func generateCallID() string {
	return fmt.Sprintf("pc_%d", time.Now().UnixNano())
}

// generateSavedContactID creates a new saved contact ID with the sc_ prefix.
func generateSavedContactID() string {
	return fmt.Sprintf("sc_%d", time.Now().UnixNano())
}
