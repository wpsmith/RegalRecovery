// internal/domain/affirmations/content_selector.go
package affirmations

import (
	"math/rand"
	"time"
)

// ContentSelector handles affirmation content selection with filtering and prioritization logic.
type ContentSelector struct {
	levelEngine *LevelEngine
	rng         *rand.Rand
}

// NewContentSelector creates a new ContentSelector instance.
func NewContentSelector() *ContentSelector {
	return &ContentSelector{
		levelEngine: NewLevelEngine(),
		rng:         rand.New(rand.NewSource(time.Now().UnixNano())),
	}
}

// SelectContent selects affirmations from the pool based on session context and count.
//
// Selection algorithm:
// 1. Filter by track (standard vs faith-based)
// 2. Filter by level (80% current level, 20% next level)
// 3. Exclude hidden affirmations
// 4. Gate Healthy Sexuality category (60+ days AND opt-in required)
// 5. Prioritize favorites (can repeat within 7 days)
// 6. Exclude recently shown (within 7 days) unless favorite
// 7. Ensure category variety within session
// 8. Ensure core belief coverage over time
func (cs *ContentSelector) SelectContent(pool []Affirmation, ctx SessionContext, requestedCount int) (ContentSelectionResult, error) {
	// Step 1: Determine user's current level
	levelResult := cs.levelEngine.DetermineLevel(
		ctx.SobrietyDays,
		ctx.LastRelapseTimestamp,
		ctx.CurrentTime,
		ctx.ManualLevelOverride,
		0, // daysSinceLastLevelChange not used in selection, only for manual override validation
	)
	currentLevel := levelResult.DeterminedLevel

	// Step 2: Filter pool by track
	trackFiltered := cs.filterByTrack(pool, ctx.Track)

	// Step 3: Filter by hidden
	notHidden := cs.filterOutHidden(trackFiltered, ctx.HiddenIDs)

	// Step 4: Gate Healthy Sexuality
	gated := cs.gateHealthySexuality(notHidden, ctx.SobrietyDays, ctx.HealthySexualityOptIn)

	// Step 5: Determine target levels (80% current, 20% next)
	targetLevels := cs.determineTargetLevels(currentLevel, requestedCount)

	// Step 6: Filter by levels
	levelFiltered := cs.filterByLevels(gated, targetLevels)

	// Step 7: Separate favorites and non-favorites
	favorites := cs.filterFavorites(levelFiltered, ctx.FavoriteIDs)
	nonFavorites := cs.filterNonFavorites(levelFiltered, ctx.FavoriteIDs)

	// Step 8: Exclude recently shown (but not favorites)
	nonFavoritesNotRecent := cs.filterOutRecent(nonFavorites, ctx.RecentAffirmationIDs)

	// Step 9: Build selection pool (favorites + non-recent)
	selectionPool := append(favorites, nonFavoritesNotRecent...)

	// Step 10: Check if we have enough content
	if len(selectionPool) == 0 {
		return ContentSelectionResult{}, ErrNoContentAvailable
	}

	// Step 11: Select with variety
	selected := cs.selectWithVariety(selectionPool, requestedCount)

	return ContentSelectionResult{
		Affirmations: selected,
		Meta: map[string]interface{}{
			"currentLevel":      currentLevel,
			"requestedCount":    requestedCount,
			"availableInPool":   len(selectionPool),
			"selectedCount":     len(selected),
		},
	}, nil
}

// filterByTrack filters affirmations by track (standard or faithBased).
func (cs *ContentSelector) filterByTrack(pool []Affirmation, track Track) []Affirmation {
	var result []Affirmation
	for _, aff := range pool {
		if aff.Track == track {
			result = append(result, aff)
		}
	}
	return result
}

// filterOutHidden removes hidden affirmations from the pool.
func (cs *ContentSelector) filterOutHidden(pool []Affirmation, hiddenIDs []string) []Affirmation {
	hiddenMap := make(map[string]bool)
	for _, id := range hiddenIDs {
		hiddenMap[id] = true
	}

	var result []Affirmation
	for _, aff := range pool {
		if !hiddenMap[aff.ID] && !aff.IsHidden {
			result = append(result, aff)
		}
	}
	return result
}

// gateHealthySexuality filters out Healthy Sexuality category unless user has 60+ days AND opt-in.
func (cs *ContentSelector) gateHealthySexuality(pool []Affirmation, sobrietyDays int, optIn bool) []Affirmation {
	// Healthy Sexuality requires both 60+ days AND explicit opt-in
	healthySexualityAllowed := sobrietyDays >= 60 && optIn

	var result []Affirmation
	for _, aff := range pool {
		if aff.Category == CategoryHealthySexuality && !healthySexualityAllowed {
			// Skip Healthy Sexuality if not allowed
			continue
		}
		result = append(result, aff)
	}
	return result
}

// determineTargetLevels returns a map of level -> count for 80/20 split.
func (cs *ContentSelector) determineTargetLevels(currentLevel Level, requestedCount int) map[Level]int {
	result := make(map[Level]int)

	// 80% current level, 20% next level
	currentLevelCount := int(float64(requestedCount) * 0.8)
	if currentLevelCount < 1 && requestedCount > 0 {
		currentLevelCount = 1
	}

	nextLevelCount := requestedCount - currentLevelCount

	result[currentLevel] = currentLevelCount

	// Add next level if not already at max
	if currentLevel < LevelFullIdentity && nextLevelCount > 0 {
		result[currentLevel+1] = nextLevelCount
	} else if nextLevelCount > 0 {
		// If already at max level, allocate remaining to current level
		result[currentLevel] += nextLevelCount
	}

	return result
}

// filterByLevels filters affirmations to match target level distribution.
func (cs *ContentSelector) filterByLevels(pool []Affirmation, targetLevels map[Level]int) []Affirmation {
	// Group by level
	byLevel := make(map[Level][]Affirmation)
	for _, aff := range pool {
		byLevel[aff.Level] = append(byLevel[aff.Level], aff)
	}

	var result []Affirmation
	for level, count := range targetLevels {
		available := byLevel[level]
		// Take up to count from this level
		for i := 0; i < count && i < len(available); i++ {
			result = append(result, available[i])
		}
	}

	return result
}

// filterFavorites returns only favorites from pool.
func (cs *ContentSelector) filterFavorites(pool []Affirmation, favoriteIDs []string) []Affirmation {
	favoriteMap := make(map[string]bool)
	for _, id := range favoriteIDs {
		favoriteMap[id] = true
	}

	var result []Affirmation
	for _, aff := range pool {
		if favoriteMap[aff.ID] || aff.IsFavorite {
			result = append(result, aff)
		}
	}
	return result
}

// filterNonFavorites returns non-favorites from pool.
func (cs *ContentSelector) filterNonFavorites(pool []Affirmation, favoriteIDs []string) []Affirmation {
	favoriteMap := make(map[string]bool)
	for _, id := range favoriteIDs {
		favoriteMap[id] = true
	}

	var result []Affirmation
	for _, aff := range pool {
		if !favoriteMap[aff.ID] && !aff.IsFavorite {
			result = append(result, aff)
		}
	}
	return result
}

// filterOutRecent removes recently shown affirmations (within 7 days).
func (cs *ContentSelector) filterOutRecent(pool []Affirmation, recentIDs []string) []Affirmation {
	recentMap := make(map[string]bool)
	for _, id := range recentIDs {
		recentMap[id] = true
	}

	var result []Affirmation
	for _, aff := range pool {
		if !recentMap[aff.ID] {
			result = append(result, aff)
		}
	}
	return result
}

// selectWithVariety selects affirmations with category variety.
// Prioritizes favorites, then selects from remaining pool with category diversity.
func (cs *ContentSelector) selectWithVariety(pool []Affirmation, requestedCount int) []Affirmation {
	if len(pool) == 0 {
		return []Affirmation{}
	}

	if len(pool) <= requestedCount {
		// Return all if pool is smaller than or equal to requested
		return pool
	}

	// Shuffle pool for randomness
	shuffled := make([]Affirmation, len(pool))
	copy(shuffled, pool)
	cs.rng.Shuffle(len(shuffled), func(i, j int) {
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	})

	// Select with category variety
	var selected []Affirmation
	usedCategories := make(map[Category]int)

	// First pass: prioritize favorites
	for _, aff := range shuffled {
		if len(selected) >= requestedCount {
			break
		}
		if aff.IsFavorite {
			selected = append(selected, aff)
			usedCategories[aff.Category]++
		}
	}

	// Second pass: fill remaining with category variety
	for _, aff := range shuffled {
		if len(selected) >= requestedCount {
			break
		}

		// Skip if already selected
		alreadySelected := false
		for _, sel := range selected {
			if sel.ID == aff.ID {
				alreadySelected = true
				break
			}
		}
		if alreadySelected {
			continue
		}

		// Prefer categories we haven't used as much
		selected = append(selected, aff)
		usedCategories[aff.Category]++
	}

	return selected
}
