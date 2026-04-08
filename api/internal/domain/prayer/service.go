// internal/domain/prayer/service.go
package prayer

import (
	"context"
	"fmt"
	"time"
)

// PrayerSessionRepository defines data access for prayer sessions.
type PrayerSessionRepository interface {
	CreateSession(ctx context.Context, session *PrayerSession) error
	GetSession(ctx context.Context, userID, prayerID string) (*PrayerSession, error)
	ListSessions(ctx context.Context, userID string, prayerType *string, startDate, endDate *time.Time, linkedPrayerID *string, cursor string, limit int) ([]PrayerSession, string, error)
	UpdateSession(ctx context.Context, session *PrayerSession) error
	DeleteSession(ctx context.Context, userID, prayerID string) error
	GetAllSessions(ctx context.Context, userID string) ([]PrayerSession, error)
}

// PersonalPrayerRepository defines data access for personal prayers.
type PersonalPrayerRepository interface {
	Create(ctx context.Context, prayer *PersonalPrayer) error
	Get(ctx context.Context, userID, prayerID string) (*PersonalPrayer, error)
	List(ctx context.Context, userID string, cursor string, limit int) ([]PersonalPrayer, string, error)
	Update(ctx context.Context, prayer *PersonalPrayer) error
	Delete(ctx context.Context, userID, prayerID string) error
	Reorder(ctx context.Context, userID string, prayerIDs []string) error
	Count(ctx context.Context, userID string) (int, error)
}

// FavoriteRepository defines data access for prayer favorites.
type FavoriteRepository interface {
	Add(ctx context.Context, fav *PrayerFavorite) error
	Remove(ctx context.Context, userID, prayerID string) error
	List(ctx context.Context, userID string, cursor string, limit int) ([]PrayerFavorite, string, error)
	Exists(ctx context.Context, userID, prayerID string) (bool, error)
}

// LibraryPrayerRepository defines data access for library prayers.
type LibraryPrayerRepository interface {
	List(ctx context.Context, packID, topic *string, step *int, search *string, tier *string, cursor string, limit int) ([]LibraryPrayer, string, error)
	Get(ctx context.Context, prayerID string) (*LibraryPrayer, error)
	GetTodayPrayer(ctx context.Context, ownedPackIDs []string, dayOfYear int) (*LibraryPrayer, error)
}

// PackOwnershipChecker checks if a user owns a given content pack.
type PackOwnershipChecker interface {
	UserOwnsPack(ctx context.Context, userID, packID string) (bool, error)
	GetOwnedPackIDs(ctx context.Context, userID string) ([]string, error)
}

// PrayerStreakCache defines cache operations for prayer streak data.
type PrayerStreakCache interface {
	Get(ctx context.Context, userID string) (*PrayerStats, error)
	Set(ctx context.Context, userID string, stats *PrayerStats, ttlSeconds int) error
	Invalidate(ctx context.Context, userID string) error
}

// EventPublisher defines event publishing for prayer domain events.
type EventPublisher interface {
	PublishSessionCreated(ctx context.Context, userID, prayerID string) error
	PublishStreakMilestone(ctx context.Context, userID string, milestone int) error
}

// Service handles prayer activity business logic.
type Service struct {
	sessions       PrayerSessionRepository
	personal       PersonalPrayerRepository
	favorites      FavoriteRepository
	library        LibraryPrayerRepository
	packOwnership  PackOwnershipChecker
	streakCache    PrayerStreakCache
	events         EventPublisher
	idGenerator    func() string
	timeFunc       func() time.Time
}

// ServiceConfig holds optional dependencies for constructing a Service.
type ServiceConfig struct {
	Sessions      PrayerSessionRepository
	Personal      PersonalPrayerRepository
	Favorites     FavoriteRepository
	Library       LibraryPrayerRepository
	PackOwnership PackOwnershipChecker
	StreakCache    PrayerStreakCache
	Events        EventPublisher
	IDGenerator   func() string
	TimeFunc      func() time.Time
}

// NewService creates a new prayer Service with required dependencies.
func NewService(cfg ServiceConfig) *Service {
	s := &Service{
		sessions:      cfg.Sessions,
		personal:      cfg.Personal,
		favorites:     cfg.Favorites,
		library:       cfg.Library,
		packOwnership: cfg.PackOwnership,
		streakCache:   cfg.StreakCache,
		events:        cfg.Events,
		idGenerator:   cfg.IDGenerator,
		timeFunc:      cfg.TimeFunc,
	}
	if s.timeFunc == nil {
		s.timeFunc = time.Now
	}
	return s
}

// CreateSession creates a new prayer session (PR-AC1.1).
func (s *Service) CreateSession(ctx context.Context, userID string, req *CreatePrayerSessionRequest) (*PrayerSession, error) {
	now := s.timeFunc()

	if err := ValidateCreateSession(req, now); err != nil {
		return nil, err
	}

	// PR-AC1.6: Validate linked prayer is not locked.
	if req.LinkedPrayerID != nil {
		prayer, err := s.library.Get(ctx, *req.LinkedPrayerID)
		if err != nil {
			return nil, fmt.Errorf("looking up linked prayer: %w", err)
		}
		if prayer != nil && prayer.Tier == TierPremium {
			owns, err := s.packOwnership.UserOwnsPack(ctx, userID, prayer.PackID)
			if err != nil {
				return nil, fmt.Errorf("checking pack ownership: %w", err)
			}
			if !owns {
				return nil, ErrLinkedPrayerLocked
			}
		}
	}

	id := "ps_" + s.idGenerator()
	session := NewPrayerSession(id, userID, req, now)

	// PR-AC1.5: Resolve linked prayer title.
	if req.LinkedPrayerID != nil {
		title, err := s.resolveLinkedPrayerTitle(ctx, *req.LinkedPrayerID)
		if err == nil && title != "" {
			session.LinkedPrayerTitle = &title
		}
	}

	if err := s.sessions.CreateSession(ctx, session); err != nil {
		return nil, fmt.Errorf("creating prayer session: %w", err)
	}

	// Invalidate streak cache.
	if s.streakCache != nil {
		_ = s.streakCache.Invalidate(ctx, userID)
	}

	// Publish event.
	if s.events != nil {
		_ = s.events.PublishSessionCreated(ctx, userID, id)
	}

	return session, nil
}

// GetSession retrieves a prayer session by ID.
func (s *Service) GetSession(ctx context.Context, userID, prayerID string) (*PrayerSession, error) {
	session, err := s.sessions.GetSession(ctx, userID, prayerID)
	if err != nil {
		return nil, fmt.Errorf("getting prayer session: %w", err)
	}
	if session == nil {
		return nil, ErrPrayerNotFound
	}
	return session, nil
}

// ListSessions lists prayer sessions with filtering and pagination.
func (s *Service) ListSessions(ctx context.Context, userID string, prayerType *string, startDate, endDate *time.Time, linkedPrayerID *string, cursor string, limit int) ([]PrayerSession, string, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}
	return s.sessions.ListSessions(ctx, userID, prayerType, startDate, endDate, linkedPrayerID, cursor, limit)
}

// UpdateSession updates a prayer session (PR-AC1.10, PR-AC1.12, PR-AC1.13).
func (s *Service) UpdateSession(ctx context.Context, userID, prayerID string, req *UpdatePrayerSessionRequest) (*PrayerSession, error) {
	now := s.timeFunc()

	existing, err := s.sessions.GetSession(ctx, userID, prayerID)
	if err != nil {
		return nil, fmt.Errorf("getting prayer session for update: %w", err)
	}
	if existing == nil {
		return nil, ErrPrayerNotFound
	}

	if err := ValidateUpdateSession(req, existing, now); err != nil {
		return nil, err
	}

	updated := ApplyUpdate(existing, req, now)
	if err := s.sessions.UpdateSession(ctx, updated); err != nil {
		return nil, fmt.Errorf("updating prayer session: %w", err)
	}

	return updated, nil
}

// DeleteSession deletes a prayer session.
func (s *Service) DeleteSession(ctx context.Context, userID, prayerID string) error {
	existing, err := s.sessions.GetSession(ctx, userID, prayerID)
	if err != nil {
		return fmt.Errorf("getting prayer session for delete: %w", err)
	}
	if existing == nil {
		return ErrPrayerNotFound
	}

	if err := s.sessions.DeleteSession(ctx, userID, prayerID); err != nil {
		return fmt.Errorf("deleting prayer session: %w", err)
	}

	// Invalidate streak cache.
	if s.streakCache != nil {
		_ = s.streakCache.Invalidate(ctx, userID)
	}

	return nil
}

// GetStats returns prayer statistics and streak (PR-AC5.5).
func (s *Service) GetStats(ctx context.Context, userID string, userLocation *time.Location) (*PrayerStats, error) {
	// Try cache first.
	if s.streakCache != nil {
		cached, err := s.streakCache.Get(ctx, userID)
		if err == nil && cached != nil {
			return cached, nil
		}
	}

	sessions, err := s.sessions.GetAllSessions(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("getting all prayer sessions: %w", err)
	}

	now := s.timeFunc()
	stats := CalculateFullStats(sessions, now, userLocation)

	// Cache the result (5-minute TTL).
	if s.streakCache != nil {
		_ = s.streakCache.Set(ctx, userID, stats, 300)
	}

	return stats, nil
}

// CreatePersonalPrayer creates a personal prayer (PR-AC3.1).
func (s *Service) CreatePersonalPrayer(ctx context.Context, userID string, req *CreatePersonalPrayerRequest) (*PersonalPrayer, error) {
	if err := ValidateCreatePersonalPrayer(req); err != nil {
		return nil, err
	}

	now := s.timeFunc()
	id := "pp_" + s.idGenerator()

	// Get current count for sort order.
	count, err := s.personal.Count(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("counting personal prayers: %w", err)
	}

	prayer := NewPersonalPrayer(id, userID, req, count+1, now)
	if err := s.personal.Create(ctx, prayer); err != nil {
		return nil, fmt.Errorf("creating personal prayer: %w", err)
	}

	return prayer, nil
}

// GetPersonalPrayer retrieves a personal prayer by ID.
func (s *Service) GetPersonalPrayer(ctx context.Context, userID, prayerID string) (*PersonalPrayer, error) {
	prayer, err := s.personal.Get(ctx, userID, prayerID)
	if err != nil {
		return nil, fmt.Errorf("getting personal prayer: %w", err)
	}
	if prayer == nil {
		return nil, ErrPrayerNotFound
	}
	return prayer, nil
}

// ListPersonalPrayers lists personal prayers with pagination (PR-AC3.3).
func (s *Service) ListPersonalPrayers(ctx context.Context, userID string, cursor string, limit int) ([]PersonalPrayer, string, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}
	return s.personal.List(ctx, userID, cursor, limit)
}

// UpdatePersonalPrayer updates a personal prayer (PR-AC3.4).
func (s *Service) UpdatePersonalPrayer(ctx context.Context, userID, prayerID string, req *UpdatePersonalPrayerRequest) (*PersonalPrayer, error) {
	if err := ValidateUpdatePersonalPrayer(req); err != nil {
		return nil, err
	}

	existing, err := s.personal.Get(ctx, userID, prayerID)
	if err != nil {
		return nil, fmt.Errorf("getting personal prayer for update: %w", err)
	}
	if existing == nil {
		return nil, ErrPrayerNotFound
	}

	now := s.timeFunc()
	updated := ApplyPersonalPrayerUpdate(existing, req, now)
	if err := s.personal.Update(ctx, updated); err != nil {
		return nil, fmt.Errorf("updating personal prayer: %w", err)
	}

	return updated, nil
}

// DeletePersonalPrayer deletes a personal prayer (PR-AC3.5).
func (s *Service) DeletePersonalPrayer(ctx context.Context, userID, prayerID string) error {
	existing, err := s.personal.Get(ctx, userID, prayerID)
	if err != nil {
		return fmt.Errorf("getting personal prayer for delete: %w", err)
	}
	if existing == nil {
		return ErrPrayerNotFound
	}

	if err := s.personal.Delete(ctx, userID, prayerID); err != nil {
		return fmt.Errorf("deleting personal prayer: %w", err)
	}

	return nil
}

// ReorderPersonalPrayers sets the display order (PR-AC3.6).
func (s *Service) ReorderPersonalPrayers(ctx context.Context, userID string, prayerIDs []string) error {
	if len(prayerIDs) == 0 {
		return ErrInvalidReorderIDs
	}
	return s.personal.Reorder(ctx, userID, prayerIDs)
}

// FavoritePrayer adds a prayer to favorites (PR-AC4.1).
func (s *Service) FavoritePrayer(ctx context.Context, userID, prayerID string) error {
	exists, err := s.favorites.Exists(ctx, userID, prayerID)
	if err != nil {
		return fmt.Errorf("checking favorite existence: %w", err)
	}
	if exists {
		return ErrFavoriteAlreadyExists
	}

	// Determine source and title.
	source := "library"
	title := ""
	if len(prayerID) > 3 && prayerID[:3] == "pp_" {
		source = "personal"
		pp, err := s.personal.Get(ctx, userID, prayerID)
		if err != nil {
			return fmt.Errorf("getting personal prayer for favorite: %w", err)
		}
		if pp == nil {
			return ErrPrayerNotFound
		}
		title = pp.Title
	} else {
		lp, err := s.library.Get(ctx, prayerID)
		if err != nil {
			return fmt.Errorf("getting library prayer for favorite: %w", err)
		}
		if lp == nil {
			return ErrPrayerNotFound
		}
		title = lp.Title
	}

	now := s.timeFunc()
	fav := &PrayerFavorite{
		UserID:       userID,
		PrayerID:     prayerID,
		PrayerSource: source,
		Title:        title,
		CreatedAt:    now,
	}

	return s.favorites.Add(ctx, fav)
}

// UnfavoritePrayer removes a prayer from favorites (PR-AC4.2).
func (s *Service) UnfavoritePrayer(ctx context.Context, userID, prayerID string) error {
	exists, err := s.favorites.Exists(ctx, userID, prayerID)
	if err != nil {
		return fmt.Errorf("checking favorite existence: %w", err)
	}
	if !exists {
		return ErrFavoriteNotFound
	}
	return s.favorites.Remove(ctx, userID, prayerID)
}

// ListFavorites lists favorite prayers (PR-AC4.3).
func (s *Service) ListFavorites(ctx context.Context, userID string, cursor string, limit int) ([]PrayerFavorite, string, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}
	return s.favorites.List(ctx, userID, cursor, limit)
}

// resolveLinkedPrayerTitle resolves the title from a library or personal prayer ID.
func (s *Service) resolveLinkedPrayerTitle(ctx context.Context, prayerID string) (string, error) {
	if len(prayerID) > 3 && prayerID[:3] == "pp_" {
		pp, err := s.personal.Get(ctx, "", prayerID)
		if err != nil {
			return "", err
		}
		if pp != nil {
			return pp.Title, nil
		}
	}
	lp, err := s.library.Get(ctx, prayerID)
	if err != nil {
		return "", err
	}
	if lp != nil {
		return lp.Title, nil
	}
	return "", nil
}
