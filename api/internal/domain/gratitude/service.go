package gratitude

import (
	"context"
	"errors"
	"fmt"
	"math"
	"sort"
	"time"

	"github.com/google/uuid"
)

var (
	// ErrEntryNotFound indicates a gratitude entry does not exist.
	ErrEntryNotFound = errors.New("gratitude entry not found")

	// ErrEditWindowExpired indicates the 24-hour edit window has passed (GL-DM-AC8).
	ErrEditWindowExpired = errors.New("edit window expired: gratitude entries are read-only after 24 hours")

	// ErrInvalidInput indicates invalid input data.
	ErrInvalidInput = errors.New("invalid input")

	// ErrItemTextTooLong indicates item text exceeds 300 characters (GL-DM-AC1).
	ErrItemTextTooLong = errors.New("item text exceeds 300 characters")

	// ErrNoItems indicates the entry has no items (GL-ES-AC1).
	ErrNoItems = errors.New("entry requires at least one non-empty item")

	// ErrInvalidMoodScore indicates mood score is outside 1-5 range (GL-DM-AC3).
	ErrInvalidMoodScore = errors.New("mood score must be between 1 and 5")

	// ErrInvalidCategory indicates an invalid category value.
	ErrInvalidCategory = errors.New("invalid gratitude category")

	// ErrFeatureDisabled indicates the feature flag is off (GL-IN-AC10).
	ErrFeatureDisabled = errors.New("gratitude feature is disabled")
)

// Service handles gratitude domain business logic.
type Service struct {
	repo Repository
}

// NewService creates a new gratitude Service.
func NewService(repo Repository) *Service {
	return &Service{repo: repo}
}

// CreateEntry creates a new gratitude entry (GL-ES-AC1 through GL-ES-AC15).
func (s *Service) CreateEntry(ctx context.Context, userID, tenantID string, req CreateEntryRequest) (*Entry, error) {
	if userID == "" {
		return nil, fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}
	if tenantID == "" {
		return nil, fmt.Errorf("tenant ID is required: %w", ErrInvalidInput)
	}

	// Validate items (GL-ES-AC1)
	if len(req.Items) == 0 {
		return nil, ErrNoItems
	}

	items := make([]Item, 0, len(req.Items))
	for _, input := range req.Items {
		if err := validateItemInput(input); err != nil {
			return nil, err
		}
		items = append(items, Item{
			ItemID:     "gi_" + uuid.New().String()[:8],
			Text:       input.Text,
			Category:   input.Category,
			IsFavorite: input.IsFavorite,
			SortOrder:  input.SortOrder,
		})
	}

	// Validate mood score (GL-DM-AC3)
	if req.MoodScore != nil {
		if *req.MoodScore < MinMoodScore || *req.MoodScore > MaxMoodScore {
			return nil, ErrInvalidMoodScore
		}
	}

	now := time.Now()
	entry := &Entry{
		GratitudeID: "g_" + uuid.New().String()[:8],
		UserID:      userID,
		TenantID:    tenantID,
		Timestamp:   req.Timestamp,
		Items:       items,
		MoodScore:   req.MoodScore,
		PhotoKey:    req.PhotoKey,
		PromptUsed:  req.PromptUsed,
		IsFavorite:  false,
		CreatedAt:   now, // Immutable (FR2.7, GL-DM-AC10)
		ModifiedAt:  now,
	}

	if err := s.repo.CreateEntry(ctx, entry); err != nil {
		return nil, fmt.Errorf("creating gratitude entry: %w", err)
	}

	return entry, nil
}

// GetEntry retrieves a gratitude entry by ID.
func (s *Service) GetEntry(ctx context.Context, gratitudeID string) (*Entry, error) {
	if gratitudeID == "" {
		return nil, fmt.Errorf("gratitude ID is required: %w", ErrInvalidInput)
	}

	entry, err := s.repo.GetEntry(ctx, gratitudeID)
	if err != nil {
		return nil, fmt.Errorf("retrieving gratitude entry: %w", err)
	}
	if entry == nil {
		return nil, ErrEntryNotFound
	}

	return entry, nil
}

// UpdateEntry updates a gratitude entry within the edit window (GL-DM-AC7, GL-DM-AC8).
func (s *Service) UpdateEntry(ctx context.Context, gratitudeID string, req UpdateEntryRequest) (*Entry, error) {
	entry, err := s.GetEntry(ctx, gratitudeID)
	if err != nil {
		return nil, err
	}

	// Check edit window (GL-DM-AC7, GL-DM-AC8)
	if !entry.IsEditable() {
		return nil, ErrEditWindowExpired
	}

	// Validate items
	if len(req.Items) == 0 {
		return nil, ErrNoItems
	}

	items := make([]Item, 0, len(req.Items))
	for _, input := range req.Items {
		if err := validateItemInput(input); err != nil {
			return nil, err
		}
		items = append(items, Item{
			ItemID:     "gi_" + uuid.New().String()[:8],
			Text:       input.Text,
			Category:   input.Category,
			IsFavorite: input.IsFavorite,
			SortOrder:  input.SortOrder,
		})
	}

	// Validate mood score
	if req.MoodScore != nil {
		if *req.MoodScore < MinMoodScore || *req.MoodScore > MaxMoodScore {
			return nil, ErrInvalidMoodScore
		}
	}

	// CreatedAt is immutable (FR2.7, GL-DM-AC10)
	entry.Items = items
	entry.MoodScore = req.MoodScore
	entry.PhotoKey = req.PhotoKey
	entry.PromptUsed = req.PromptUsed
	entry.ModifiedAt = time.Now()

	if err := s.repo.UpdateEntry(ctx, entry); err != nil {
		return nil, fmt.Errorf("updating gratitude entry: %w", err)
	}

	return entry, nil
}

// DeleteEntry deletes a gratitude entry within the edit window.
func (s *Service) DeleteEntry(ctx context.Context, gratitudeID string) error {
	entry, err := s.GetEntry(ctx, gratitudeID)
	if err != nil {
		return err
	}

	if !entry.IsEditable() {
		return ErrEditWindowExpired
	}

	return s.repo.DeleteEntry(ctx, gratitudeID)
}

// ListEntries retrieves entries for a user with filtering and pagination.
func (s *Service) ListEntries(ctx context.Context, userID string, filters ListFilters, cursor string, limit int) ([]*Entry, string, error) {
	if userID == "" {
		return nil, "", fmt.Errorf("user ID is required: %w", ErrInvalidInput)
	}

	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	// Validate filter values
	if filters.Category != nil && !ValidCategories[*filters.Category] {
		return nil, "", ErrInvalidCategory
	}
	if filters.MoodScore != nil && (*filters.MoodScore < MinMoodScore || *filters.MoodScore > MaxMoodScore) {
		return nil, "", ErrInvalidMoodScore
	}

	return s.repo.ListEntries(ctx, userID, filters, cursor, limit)
}

// ToggleItemFavorite toggles the favorite status of a specific item (GL-HS-AC9).
// Allowed regardless of the 24-hour window since favoriting is curation, not editing.
func (s *Service) ToggleItemFavorite(ctx context.Context, gratitudeID string, itemID string, isFavorite bool) error {
	return s.repo.ToggleItemFavorite(ctx, gratitudeID, itemID, isFavorite)
}

// ComputeStreakData computes streak statistics from entry dates (GL-TI-AC1 through GL-TI-AC4).
func (s *Service) ComputeStreakData(ctx context.Context, userID string) (*StreakData, error) {
	dates, err := s.repo.GetAllEntryDates(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("getting entry dates: %w", err)
	}

	if len(dates) == 0 {
		return &StreakData{}, nil
	}

	// Deduplicate to unique calendar days (GL-TI-AC4)
	uniqueDays := uniqueCalendarDays(dates)
	sort.Slice(uniqueDays, func(i, j int) bool {
		return uniqueDays[i].After(uniqueDays[j])
	})

	currentStreak := computeCurrentStreak(uniqueDays)
	longestStreak := computeLongestStreak(uniqueDays)

	return &StreakData{
		CurrentStreak:       currentStreak,
		LongestStreak:       longestStreak,
		TotalDaysWithEntries: len(uniqueDays),
	}, nil
}

// CategoryBreakdown computes category distribution for a period (GL-TI-AC5).
func (s *Service) CategoryBreakdown(ctx context.Context, userID string, periodDays *int) ([]CategoryBreakdownItem, error) {
	filters := ListFilters{}
	if periodDays != nil {
		cutoff := time.Now().AddDate(0, 0, -*periodDays)
		filters.StartDate = &cutoff
	}

	entries, _, err := s.repo.ListEntries(ctx, userID, filters, "", 10000)
	if err != nil {
		return nil, err
	}

	counts := make(map[string]int)
	for _, entry := range entries {
		for _, item := range entry.Items {
			if item.Category != nil {
				counts[*item.Category]++
			}
		}
	}

	total := 0
	for _, c := range counts {
		total += c
	}
	if total == 0 {
		return nil, nil
	}

	result := make([]CategoryBreakdownItem, 0, len(counts))
	for cat, count := range counts {
		result = append(result, CategoryBreakdownItem{
			Category:   cat,
			Count:      count,
			Percentage: math.Round(float64(count)/float64(total)*1000) / 10,
		})
	}

	sort.Slice(result, func(i, j int) bool {
		return result[i].Count > result[j].Count
	})

	return result, nil
}

// AverageItemsPerEntry computes the mean item count (GL-TI-AC7).
func (s *Service) AverageItemsPerEntry(entries []*Entry) float64 {
	if len(entries) == 0 {
		return 0
	}
	total := 0
	for _, e := range entries {
		total += len(e.Items)
	}
	return float64(total) / float64(len(entries))
}

// GenerateShareText produces privacy-safe share text (GL-SH-AC3).
// NEVER includes mood, category, or photo data.
func (s *Service) GenerateShareText(entry *Entry) string {
	text := "Gratitude \u2014 " + entry.Timestamp.Format("January 2, 2006") + "\n"
	sorted := make([]Item, len(entry.Items))
	copy(sorted, entry.Items)
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].SortOrder < sorted[j].SortOrder
	})
	for i, item := range sorted {
		text += fmt.Sprintf("\n%d. %s", i+1, item.Text)
	}
	return text
}

// GenerateShareItemText produces share text for a single item (GL-SH-AC1).
func (s *Service) GenerateShareItemText(item Item) string {
	return item.Text
}

// --- Private helpers ---

func validateItemInput(input ItemInput) error {
	if len(input.Text) == 0 {
		return fmt.Errorf("item text is required: %w", ErrInvalidInput)
	}
	if len(input.Text) > MaxItemTextLength {
		return ErrItemTextTooLong
	}
	if input.Category != nil && !ValidCategories[*input.Category] {
		return fmt.Errorf("invalid category %q: %w", *input.Category, ErrInvalidCategory)
	}
	return nil
}

func uniqueCalendarDays(dates []time.Time) []time.Time {
	seen := make(map[string]bool)
	var result []time.Time

	for _, d := range dates {
		day := d.Format("2006-01-02")
		if !seen[day] {
			seen[day] = true
			y, m, dd := d.Date()
			result = append(result, time.Date(y, m, dd, 0, 0, 0, 0, d.Location()))
		}
	}

	return result
}

func computeCurrentStreak(sortedDaysDesc []time.Time) int {
	if len(sortedDaysDesc) == 0 {
		return 0
	}

	today := time.Now()
	todayStart := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, today.Location())

	mostRecent := sortedDaysDesc[0]
	daysDiff := int(todayStart.Sub(mostRecent).Hours() / 24)

	if daysDiff > 1 {
		return 0
	}

	streak := 1
	expected := mostRecent

	for i := 1; i < len(sortedDaysDesc); i++ {
		prev := expected.AddDate(0, 0, -1)
		if sortedDaysDesc[i].Equal(prev) {
			streak++
			expected = prev
		} else {
			break
		}
	}

	return streak
}

func computeLongestStreak(sortedDaysDesc []time.Time) int {
	if len(sortedDaysDesc) <= 1 {
		return len(sortedDaysDesc)
	}

	// Work ascending
	ascending := make([]time.Time, len(sortedDaysDesc))
	copy(ascending, sortedDaysDesc)
	sort.Slice(ascending, func(i, j int) bool {
		return ascending[i].Before(ascending[j])
	})

	longest := 1
	current := 1

	for i := 1; i < len(ascending); i++ {
		expected := ascending[i-1].AddDate(0, 0, 1)
		if ascending[i].Equal(expected) {
			current++
			if current > longest {
				longest = current
			}
		} else {
			current = 1
		}
	}

	return longest
}
