// internal/domain/auth/service.go
package auth

import (
	"context"
	"errors"
	"fmt"
	"time"
)

var (
	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrEmailAlreadyExists indicates email is already registered.
	ErrEmailAlreadyExists = errors.New("email already registered")

	// ErrUserNotFound indicates user does not exist.
	ErrUserNotFound = errors.New("user not found")

	// ErrSessionNotFound indicates session does not exist.
	ErrSessionNotFound = errors.New("session not found")

	// ErrInvalidCredentials indicates invalid authentication credentials.
	ErrInvalidCredentials = errors.New("invalid credentials")

	// ErrSessionExpired indicates session has expired.
	ErrSessionExpired = errors.New("session expired")
)

// AuthService handles authentication business logic.
type AuthService struct {
	userRepo     UserRepository
	sessionRepo  SessionRepository
	tokenSvc     TokenService
	sessionCache SessionCache
}

// NewAuthService creates a new AuthService with required dependencies.
func NewAuthService(userRepo UserRepository, sessionRepo SessionRepository, tokenSvc TokenService, sessionCache SessionCache) *AuthService {
	return &AuthService{
		userRepo:     userRepo,
		sessionRepo:  sessionRepo,
		tokenSvc:     tokenSvc,
		sessionCache: sessionCache,
	}
}

// Register creates a new user account.
// It validates input, checks for duplicate email, creates the user, and returns tokens.
func (s *AuthService) Register(ctx context.Context, req RegisterRequest) (*User, string, string, int, error) {
	// Validate input.
	if err := s.validateRegisterRequest(req); err != nil {
		return nil, "", "", 0, fmt.Errorf("validation failed: %w", err)
	}

	// Check if email already exists.
	exists, err := s.userRepo.EmailExists(ctx, req.Email)
	if err != nil {
		return nil, "", "", 0, fmt.Errorf("checking email existence: %w", err)
	}
	if exists {
		return nil, "", "", 0, ErrEmailAlreadyExists
	}

	// Parse sobriety start date.
	sobrietyDate, err := time.Parse("2006-01-02", req.SobrietyStartDate)
	if err != nil {
		return nil, "", "", 0, fmt.Errorf("parsing sobriety date: %w", ErrInvalidInput)
	}

	// Validate sobriety date is not in the future.
	now := time.Now()
	if sobrietyDate.After(now) {
		return nil, "", "", 0, fmt.Errorf("sobriety date cannot be in the future: %w", ErrInvalidInput)
	}

	// Create user object.
	user := &User{
		Email:             req.Email,
		DisplayName:       req.DisplayName,
		EmailVerified:     false,
		PrimaryAddiction:  req.PrimaryAddiction,
		SobrietyStartDate: sobrietyDate,
		CreatedAt:         now,
		ModifiedAt:        now,
	}

	// Create user in repository.
	// Note: Password hashing is handled by the repository implementation.
	if err := s.userRepo.CreateUser(ctx, user, req.Password); err != nil {
		return nil, "", "", 0, fmt.Errorf("creating user: %w", err)
	}

	// Generate tokens.
	accessToken, expiresIn, err := s.tokenSvc.GenerateAccessToken(ctx, user.ID, user.Email)
	if err != nil {
		return nil, "", "", 0, fmt.Errorf("generating access token: %w", err)
	}

	refreshToken, err := s.tokenSvc.GenerateRefreshToken(ctx, user.ID)
	if err != nil {
		return nil, "", "", 0, fmt.Errorf("generating refresh token: %w", err)
	}

	return user, accessToken, refreshToken, expiresIn, nil
}

// GetSession retrieves the current session from the request context.
// The session should be injected by authentication middleware.
func (s *AuthService) GetSession(ctx context.Context) (*Session, error) {
	// Extract session from context.
	// In a real implementation, the session would be stored in context by middleware
	// after validating the JWT token. This is a placeholder for that pattern.
	sessionID, ok := ctx.Value("sessionID").(string)
	if !ok || sessionID == "" {
		return nil, ErrSessionNotFound
	}

	// Try cache first.
	session, err := s.sessionCache.GetSession(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("checking cache for session: %w", err)
	}

	// Cache hit: validate and return.
	if session != nil {
		if time.Now().After(session.ExpiresAt) {
			return nil, ErrSessionExpired
		}
		return session, nil
	}

	// Cache miss: fetch from repository.
	session, err = s.sessionRepo.GetSession(ctx, sessionID)
	if err != nil {
		return nil, fmt.Errorf("retrieving session: %w", err)
	}

	// Check if session is expired.
	if time.Now().After(session.ExpiresAt) {
		return nil, ErrSessionExpired
	}

	// Store in cache for next time.
	if err := s.sessionCache.SetSession(ctx, sessionID, session); err != nil {
		// Log cache error but don't fail the request.
		// In production, this should use structured logging.
		_ = err
	}

	return session, nil
}

// GetUserByID retrieves a user by ID.
func (s *AuthService) GetUserByID(ctx context.Context, userID string) (*User, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	user, err := s.userRepo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("retrieving user: %w", err)
	}

	return user, nil
}

// GetUserByEmail retrieves a user by email address.
func (s *AuthService) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	if email == "" {
		return nil, fmt.Errorf("email is required: %w", ErrInvalidInput)
	}

	user, err := s.userRepo.GetUserByEmail(ctx, email)
	if err != nil {
		return nil, fmt.Errorf("retrieving user by email: %w", err)
	}

	return user, nil
}

// CreateSession creates a new session for a user.
func (s *AuthService) CreateSession(ctx context.Context, userID, deviceID, deviceName, ipAddress string) (*Session, error) {
	now := time.Now()
	session := &Session{
		UserID:       userID,
		DeviceID:     deviceID,
		DeviceName:   deviceName,
		IPAddress:    ipAddress,
		IssuedAt:     now,
		ExpiresAt:    now.Add(30 * 24 * time.Hour), // 30 days
		LastActivity: now,
	}

	if err := s.sessionRepo.CreateSession(ctx, session); err != nil {
		return nil, fmt.Errorf("creating session: %w", err)
	}

	// Cache the newly created session.
	if err := s.sessionCache.SetSession(ctx, session.SessionID, session); err != nil {
		// Log cache error but don't fail the request.
		// In production, this should use structured logging.
		_ = err
	}

	return session, nil
}

// RevokeSession revokes a specific session.
func (s *AuthService) RevokeSession(ctx context.Context, sessionID string) error {
	if sessionID == "" {
		return fmt.Errorf("session ID is required: %w", ErrInvalidInput)
	}

	if err := s.sessionRepo.DeleteSession(ctx, sessionID); err != nil {
		return fmt.Errorf("revoking session: %w", err)
	}

	// Invalidate cache after deleting from repository.
	if err := s.sessionCache.InvalidateSession(ctx, sessionID); err != nil {
		// Log cache error but don't fail the request.
		// In production, this should use structured logging.
		_ = err
	}

	return nil
}

// validateRegisterRequest validates registration request data.
func (s *AuthService) validateRegisterRequest(req RegisterRequest) error {
	if req.Email == "" {
		return fmt.Errorf("email is required: %w", ErrInvalidInput)
	}
	if req.Password == "" {
		return fmt.Errorf("password is required: %w", ErrInvalidInput)
	}
	if len(req.Password) < 8 {
		return fmt.Errorf("password must be at least 8 characters: %w", ErrInvalidInput)
	}
	if req.DisplayName == "" {
		return fmt.Errorf("display name is required: %w", ErrInvalidInput)
	}
	if req.PrimaryAddiction == "" {
		return fmt.Errorf("primary addiction is required: %w", ErrInvalidInput)
	}
	if req.SobrietyStartDate == "" {
		return fmt.Errorf("sobriety start date is required: %w", ErrInvalidInput)
	}

	return nil
}
