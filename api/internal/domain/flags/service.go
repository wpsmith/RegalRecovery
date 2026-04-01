// internal/domain/flags/service.go
package flags

import (
	"context"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"

	"github.com/hashicorp/go-version"
)

var (
	// ErrFlagNotFound indicates flag does not exist.
	ErrFlagNotFound = errors.New("flag not found")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrInvalidVersion indicates invalid semantic version.
	ErrInvalidVersion = errors.New("invalid semantic version")
)

// FlagService handles feature flag business logic.
type FlagService struct {
	repo  FlagRepository
	cache FlagCache
}

// NewFlagService creates a new FlagService with required dependencies.
func NewFlagService(repo FlagRepository, cache FlagCache) *FlagService {
	return &FlagService{
		repo:  repo,
		cache: cache,
	}
}

// EvaluateFlag evaluates a flag for a specific user context.
// It checks cache first, falls back to repository, and evaluates based on:
// - Master enabled/disabled switch
// - User tier
// - User tenant
// - User platform
// - App version
// - Rollout percentage (deterministic hash on userID)
func (s *FlagService) EvaluateFlag(ctx context.Context, flagKey string, userCtx UserContext) (bool, error) {
	if flagKey == "" {
		return false, fmt.Errorf("flag key is required: %w", ErrInvalidInput)
	}
	if userCtx.UserID == "" {
		return false, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	// Try cache first.
	flag, err := s.cache.Get(ctx, flagKey)
	if err != nil || flag == nil {
		// Cache miss, fetch from repository.
		flag, err = s.repo.GetFlag(ctx, flagKey)
		if err != nil {
			return false, fmt.Errorf("retrieving flag: %w", err)
		}
		if flag == nil {
			return false, ErrFlagNotFound
		}

		// Store in cache with 60-second TTL.
		_ = s.cache.Set(ctx, flagKey, flag, 60)
	}

	// Master kill switch.
	if !flag.Enabled {
		return false, nil
	}

	// Check tier restrictions.
	if len(flag.Tiers) > 0 && !contains(flag.Tiers, "*") {
		if !contains(flag.Tiers, userCtx.Tier) {
			return false, nil
		}
	}

	// Check tenant restrictions.
	if len(flag.Tenants) > 0 && !contains(flag.Tenants, "*") {
		if !contains(flag.Tenants, userCtx.TenantID) {
			return false, nil
		}
	}

	// Check platform restrictions.
	if len(flag.Platforms) > 0 && !contains(flag.Platforms, "*") {
		if !contains(flag.Platforms, userCtx.Platform) {
			return false, nil
		}
	}

	// Check minimum app version.
	if flag.MinAppVersion != "" && userCtx.AppVersion != "" {
		meets, err := s.meetsMinVersion(userCtx.AppVersion, flag.MinAppVersion)
		if err != nil {
			return false, fmt.Errorf("checking version: %w", err)
		}
		if !meets {
			return false, nil
		}
	}

	// Check rollout percentage using consistent hashing.
	if flag.RolloutPercentage < 100 {
		userBucket := s.getUserBucket(userCtx.UserID, flagKey)
		if userBucket >= flag.RolloutPercentage {
			return false, nil
		}
	}

	return true, nil
}

// EvaluateAllFlags evaluates all flags for a user context.
func (s *FlagService) EvaluateAllFlags(ctx context.Context, userCtx UserContext) ([]EvaluatedFlag, error) {
	if userCtx.UserID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	// Try cache first.
	flags, err := s.cache.GetAll(ctx)
	if err != nil || len(flags) == 0 {
		// Cache miss, fetch from repository.
		flags, err = s.repo.GetAllFlags(ctx)
		if err != nil {
			return nil, fmt.Errorf("retrieving flags: %w", err)
		}

		// Store in cache with 60-second TTL.
		_ = s.cache.SetAll(ctx, flags, 60)
	}

	evaluated := make([]EvaluatedFlag, 0, len(flags))
	for _, flag := range flags {
		enabled := s.evaluateFlagFromObject(flag, userCtx)
		evaluated = append(evaluated, EvaluatedFlag{
			Key:     flag.Key,
			Enabled: enabled,
		})
	}

	return evaluated, nil
}

// GetAllFlags retrieves all flag configurations (admin only).
func (s *FlagService) GetAllFlags(ctx context.Context) ([]*Flag, error) {
	flags, err := s.repo.GetAllFlags(ctx)
	if err != nil {
		return nil, fmt.Errorf("retrieving flags: %w", err)
	}

	return flags, nil
}

// GetFlag retrieves a single flag configuration (admin only).
func (s *FlagService) GetFlag(ctx context.Context, key string) (*Flag, error) {
	if key == "" {
		return nil, fmt.Errorf("flag key is required: %w", ErrInvalidInput)
	}

	flag, err := s.repo.GetFlag(ctx, key)
	if err != nil {
		return nil, fmt.Errorf("retrieving flag: %w", err)
	}
	if flag == nil {
		return nil, ErrFlagNotFound
	}

	return flag, nil
}

// SetFlag creates or updates a flag (admin only).
func (s *FlagService) SetFlag(ctx context.Context, flag *Flag) error {
	if err := s.validateFlag(flag); err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	if err := s.repo.SetFlag(ctx, flag); err != nil {
		return fmt.Errorf("setting flag: %w", err)
	}

	// Invalidate cache.
	_ = s.cache.Invalidate(ctx, flag.Key)

	return nil
}

// evaluateFlagFromObject evaluates a flag object for a user context.
func (s *FlagService) evaluateFlagFromObject(flag *Flag, userCtx UserContext) bool {
	if !flag.Enabled {
		return false
	}

	if len(flag.Tiers) > 0 && !contains(flag.Tiers, "*") {
		if !contains(flag.Tiers, userCtx.Tier) {
			return false
		}
	}

	if len(flag.Tenants) > 0 && !contains(flag.Tenants, "*") {
		if !contains(flag.Tenants, userCtx.TenantID) {
			return false
		}
	}

	if len(flag.Platforms) > 0 && !contains(flag.Platforms, "*") {
		if !contains(flag.Platforms, userCtx.Platform) {
			return false
		}
	}

	if flag.MinAppVersion != "" && userCtx.AppVersion != "" {
		meets, err := s.meetsMinVersion(userCtx.AppVersion, flag.MinAppVersion)
		if err != nil || !meets {
			return false
		}
	}

	if flag.RolloutPercentage < 100 {
		userBucket := s.getUserBucket(userCtx.UserID, flag.Key)
		if userBucket >= flag.RolloutPercentage {
			return false
		}
	}

	return true
}

// getUserBucket returns a deterministic bucket (0-99) for a user and flag.
// Uses SHA256 hash to ensure consistent assignment.
func (s *FlagService) getUserBucket(userID, flagKey string) int {
	hash := sha256.Sum256([]byte(userID + ":" + flagKey))
	// Use first 8 bytes as uint64.
	num := binary.BigEndian.Uint64(hash[:8])
	return int(num % 100)
}

// meetsMinVersion checks if user's app version meets the minimum required version.
func (s *FlagService) meetsMinVersion(userVersion, minVersion string) (bool, error) {
	userVer, err := version.NewVersion(userVersion)
	if err != nil {
		return false, fmt.Errorf("parsing user version: %w", ErrInvalidVersion)
	}

	minVer, err := version.NewVersion(minVersion)
	if err != nil {
		return false, fmt.Errorf("parsing min version: %w", ErrInvalidVersion)
	}

	return userVer.GreaterThanOrEqual(minVer), nil
}

// validateFlag validates flag configuration.
func (s *FlagService) validateFlag(flag *Flag) error {
	if flag.Key == "" {
		return fmt.Errorf("flag key is required: %w", ErrInvalidInput)
	}
	if flag.RolloutPercentage < 0 || flag.RolloutPercentage > 100 {
		return fmt.Errorf("rollout percentage must be between 0 and 100: %w", ErrInvalidInput)
	}
	if flag.MinAppVersion != "" {
		if _, err := version.NewVersion(flag.MinAppVersion); err != nil {
			return fmt.Errorf("invalid min app version: %w", ErrInvalidVersion)
		}
	}

	return nil
}

// contains checks if a slice contains a string.
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
