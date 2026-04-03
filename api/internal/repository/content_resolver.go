// internal/repository/content_resolver.go
package repository

import (
	"context"
	"fmt"
	"strings"
	"sync"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// ContentResolver resolves a locale to the appropriate ContentClient
// using a fallback chain: full locale -> language only -> default.
type ContentResolver struct {
	client     *mongo.Client
	baseDBName string
	cache      map[string]*ContentClient
	mu         sync.RWMutex
}

// NewContentResolver creates a new ContentResolver.
func NewContentResolver(client *mongo.Client, baseDBName string) *ContentResolver {
	return &ContentResolver{
		client:     client,
		baseDBName: baseDBName,
		cache:      make(map[string]*ContentClient),
	}
}

// Resolve returns a ContentClient for the given locale.
// It tries databases in order: base-{locale}, base-{language}, base.
// Results are cached so each locale is resolved at most once.
func (r *ContentResolver) Resolve(ctx context.Context, locale string) *ContentClient {
	// Normalize locale
	locale = strings.TrimSpace(locale)

	// Check cache first
	r.mu.RLock()
	if client, ok := r.cache[locale]; ok {
		r.mu.RUnlock()
		return client
	}
	r.mu.RUnlock()

	// Build fallback chain
	candidates := r.buildFallbackChain(locale)

	// Try each candidate
	var resolved *ContentClient
	for _, dbName := range candidates {
		if r.databaseExists(ctx, dbName) {
			resolved = NewContentClient(r.client, dbName)
			break
		}
	}

	// Always fall back to default
	if resolved == nil {
		resolved = NewContentClient(r.client, r.baseDBName)
	}

	// Cache the result
	r.mu.Lock()
	r.cache[locale] = resolved
	r.mu.Unlock()

	return resolved
}

// Default returns the default (English) ContentClient.
func (r *ContentResolver) Default() *ContentClient {
	return NewContentClient(r.client, r.baseDBName)
}

// buildFallbackChain constructs the ordered list of database names to try.
// For locale "es-ES": ["regal-recovery-content-es-ES", "regal-recovery-content-es", "regal-recovery-content"]
// For locale "es": ["regal-recovery-content-es", "regal-recovery-content"]
// For locale "" or "en": ["regal-recovery-content"]
func (r *ContentResolver) buildFallbackChain(locale string) []string {
	if locale == "" || locale == "en" {
		return []string{r.baseDBName}
	}

	var chain []string

	// Full locale (e.g., "es-ES")
	if strings.Contains(locale, "-") {
		chain = append(chain, fmt.Sprintf("%s-%s", r.baseDBName, locale))
	}

	// Language only (e.g., "es")
	lang := locale
	if idx := strings.Index(locale, "-"); idx > 0 {
		lang = locale[:idx]
	}
	if lang != "en" {
		chain = append(chain, fmt.Sprintf("%s-%s", r.baseDBName, lang))
	}

	// Default
	chain = append(chain, r.baseDBName)

	return chain
}

// databaseExists checks if a database has any collections.
func (r *ContentResolver) databaseExists(ctx context.Context, dbName string) bool {
	db := r.client.Database(dbName)
	collections, err := db.ListCollectionNames(ctx, bson.M{})
	if err != nil {
		return false
	}
	return len(collections) > 0
}
