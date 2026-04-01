// test/unit/flags_test.go
package unit

import (
	"context"
	"fmt"
	"testing"

	"github.com/regalrecovery/api/internal/domain/flags"
)

// MockFlagRepository is a test double for the flag repository.
type MockFlagRepository struct {
	flags map[string]*flags.Flag
}

func NewMockFlagRepository() *MockFlagRepository {
	return &MockFlagRepository{
		flags: make(map[string]*flags.Flag),
	}
}

func (m *MockFlagRepository) GetFlag(ctx context.Context, key string) (*flags.Flag, error) {
	flag, exists := m.flags[key]
	if !exists {
		return nil, flags.ErrFlagNotFound
	}
	return flag, nil
}

func (m *MockFlagRepository) GetAllFlags(ctx context.Context) ([]*flags.Flag, error) {
	result := make([]*flags.Flag, 0, len(m.flags))
	for _, flag := range m.flags {
		result = append(result, flag)
	}
	return result, nil
}

func (m *MockFlagRepository) SetFlag(ctx context.Context, flag *flags.Flag) error {
	m.flags[flag.Key] = flag
	return nil
}

func (m *MockFlagRepository) DeleteFlag(ctx context.Context, key string) error {
	delete(m.flags, key)
	return nil
}

// MockFlagCache is a test double for the flag cache.
type MockFlagCache struct {
	flags map[string]*flags.Flag
}

func NewMockFlagCache() *MockFlagCache {
	return &MockFlagCache{
		flags: make(map[string]*flags.Flag),
	}
}

func (m *MockFlagCache) Get(ctx context.Context, key string) (*flags.Flag, error) {
	flag, exists := m.flags[key]
	if !exists {
		return nil, fmt.Errorf("cache miss")
	}
	return flag, nil
}

func (m *MockFlagCache) GetAll(ctx context.Context) ([]*flags.Flag, error) {
	result := make([]*flags.Flag, 0, len(m.flags))
	for _, flag := range m.flags {
		result = append(result, flag)
	}
	return result, nil
}

func (m *MockFlagCache) Set(ctx context.Context, key string, flag *flags.Flag, ttl int) error {
	m.flags[key] = flag
	return nil
}

func (m *MockFlagCache) SetAll(ctx context.Context, flagList []*flags.Flag, ttl int) error {
	for _, flag := range flagList {
		m.flags[flag.Key] = flag
	}
	return nil
}

func (m *MockFlagCache) Invalidate(ctx context.Context, key string) error {
	delete(m.flags, key)
	return nil
}

func (m *MockFlagCache) InvalidateAll(ctx context.Context) error {
	m.flags = make(map[string]*flags.Flag)
	return nil
}

// TestFlag_EvaluateEnabled_ReturnsTrue verifies that a flag with enabled=true
// and rollout=100 returns true for all users.
//
// Acceptance Criterion: When a flag is fully enabled (enabled=true, rollout=100%),
// all users receive the feature.
func TestFlag_EvaluateEnabled_ReturnsTrue(t *testing.T) {
	// Given - Flag fully enabled
	repo := NewMockFlagRepository()
	cache := NewMockFlagCache()
	service := flags.NewFlagService(repo, cache)

	flag := &flags.Flag{
		Key:               "feature.tracking",
		Enabled:           true,
		RolloutPercentage: 100,
	}
	repo.SetFlag(context.Background(), flag)

	userCtx := flags.UserContext{
		UserID:   "user_12345",
		TenantID: "DEFAULT",
	}

	// When
	result, err := service.EvaluateFlag(context.Background(), "feature.tracking", userCtx)

	// Then
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !result {
		t.Error("expected flag to be enabled for user")
	}
}

// TestFlag_EvaluateDisabled_ReturnsFalse verifies that a flag with enabled=false
// (kill switch) returns false regardless of other settings.
//
// Acceptance Criterion: Kill switch (enabled=false) overrides all other flag settings
// including rollout percentage and targeting rules.
func TestFlag_EvaluateDisabled_ReturnsFalse(t *testing.T) {
	// Given - Flag disabled (kill switch)
	repo := NewMockFlagRepository()
	cache := NewMockFlagCache()
	service := flags.NewFlagService(repo, cache)

	flag := &flags.Flag{
		Key:               "feature.recovery-agent",
		Enabled:           false,
		RolloutPercentage: 100,
	}
	repo.SetFlag(context.Background(), flag)

	userCtx := flags.UserContext{
		UserID:   "user_12345",
		TenantID: "DEFAULT",
	}

	// When
	result, err := service.EvaluateFlag(context.Background(), "feature.recovery-agent", userCtx)

	// Then
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result {
		t.Error("expected flag to be disabled (kill switch active)")
	}
}

// TestFlag_EvaluateRollout_ConsistentForSameUser verifies that rollout evaluation
// is deterministic for a given user.
//
// Acceptance Criterion: A user must consistently see the same flag state across
// multiple requests (no random toggling).
func TestFlag_EvaluateRollout_ConsistentForSameUser(t *testing.T) {
	// Given - Flag with 50% rollout
	repo := NewMockFlagRepository()
	cache := NewMockFlagCache()
	service := flags.NewFlagService(repo, cache)

	flag := &flags.Flag{
		Key:               "activity.time-journal",
		Enabled:           true,
		RolloutPercentage: 50,
	}
	repo.SetFlag(context.Background(), flag)

	userCtx := flags.UserContext{
		UserID:   "user_12345",
		TenantID: "DEFAULT",
	}

	ctx := context.Background()

	// When - Evaluate multiple times
	result1, _ := service.EvaluateFlag(ctx, "activity.time-journal", userCtx)
	result2, _ := service.EvaluateFlag(ctx, "activity.time-journal", userCtx)
	result3, _ := service.EvaluateFlag(ctx, "activity.time-journal", userCtx)

	// Then - Results must be consistent
	if result1 != result2 || result2 != result3 {
		t.Error("flag evaluation not consistent for same user across multiple calls")
	}
}

// TestFlag_EvaluateRollout_DifferentUsersGetDifferentResults verifies that with
// a 50% rollout, approximately half the users see the feature.
//
// Acceptance Criterion: Rollout percentage distributes users according to the
// specified percentage using consistent hashing.
func TestFlag_EvaluateRollout_DifferentUsersGetDifferentResults(t *testing.T) {
	// Given - Flag with 50% rollout
	repo := NewMockFlagRepository()
	cache := NewMockFlagCache()
	service := flags.NewFlagService(repo, cache)

	flag := &flags.Flag{
		Key:               "activity.time-journal",
		Enabled:           true,
		RolloutPercentage: 50,
	}
	repo.SetFlag(context.Background(), flag)

	ctx := context.Background()

	// When - Test with 100 different users
	enabledCount := 0
	for i := 0; i < 100; i++ {
		userCtx := flags.UserContext{
			UserID:   fmt.Sprintf("user_%d", i),
			TenantID: "DEFAULT",
		}
		result, _ := service.EvaluateFlag(ctx, "activity.time-journal", userCtx)
		if result {
			enabledCount++
		}
	}

	// Then - Expect approximately 50% (allow ±20% variance for small sample)
	if enabledCount < 30 || enabledCount > 70 {
		t.Errorf("expected ~50 users enabled with 50%% rollout, got %d", enabledCount)
	}
}

// TestFlag_FailClosed_UnknownFlagReturnsFalse verifies that evaluating a non-existent
// flag returns false (fail-closed behavior).
//
// Acceptance Criterion: Unknown flags must fail closed (return false) to prevent
// accidental feature exposure.
func TestFlag_FailClosed_UnknownFlagReturnsFalse(t *testing.T) {
	// Given - Empty repository (no flags)
	repo := NewMockFlagRepository()
	cache := NewMockFlagCache()
	service := flags.NewFlagService(repo, cache)

	userCtx := flags.UserContext{
		UserID:   "user_12345",
		TenantID: "DEFAULT",
	}

	// When - Try to evaluate non-existent flag
	_, err := service.EvaluateFlag(context.Background(), "feature.does-not-exist", userCtx)

	// Then - Must fail closed with error
	if err == nil {
		t.Error("expected error for unknown flag")
	}
}

// TestFlag_TierGating_PremiumOnly verifies that tier-gated flags only enable
// for users in the specified tiers.
//
// Acceptance Criterion: Tier gating restricts features to Premium, Premium+, etc.
func TestFlag_TierGating_PremiumOnly(t *testing.T) {
	// Given - Flag restricted to Premium tiers
	repo := NewMockFlagRepository()
	cache := NewMockFlagCache()
	service := flags.NewFlagService(repo, cache)

	flag := &flags.Flag{
		Key:               "feature.couples-mode",
		Enabled:           true,
		RolloutPercentage: 100,
		Tiers:             []string{"premium", "premium-plus"},
	}
	repo.SetFlag(context.Background(), flag)

	ctx := context.Background()

	tests := []struct {
		name     string
		tier     string
		expected bool
	}{
		{"free tier denied", "free", false},
		{"premium tier allowed", "premium", true},
		{"premium-plus tier allowed", "premium-plus", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			userCtx := flags.UserContext{
				UserID:   "user_12345",
				TenantID: "DEFAULT",
				Tier:     tt.tier,
			}

			// When
			result, err := service.EvaluateFlag(ctx, "feature.couples-mode", userCtx)

			// Then
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if result != tt.expected {
				t.Errorf("expected %v for tier %s, got %v", tt.expected, tt.tier, result)
			}
		})
	}
}
