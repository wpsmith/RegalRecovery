// internal/repository/content_resolver.go
package repository

import (
	"context"
	"fmt"
	"strings"
	"sync"

	"go.mongodb.org/mongo-driver/v2/mongo"
)

// ContentResolver resolves a locale to the appropriate ContentClient
// using a fallback chain: full locale -> language only -> default.
// It fetches the list of available databases once and matches against it.
type ContentResolver struct {
	client     *mongo.Client
	baseDBName string
	cache      map[string]*ContentClient
	databases  map[string]bool // set of database names that exist
	mu         sync.RWMutex
}

// NewContentResolver creates a new ContentResolver.
// Call LoadDatabases before first use to populate the available database list.
func NewContentResolver(client *mongo.Client, baseDBName string) *ContentResolver {
	return &ContentResolver{
		client:     client,
		baseDBName: baseDBName,
		cache:      make(map[string]*ContentClient),
		databases:  make(map[string]bool),
	}
}

// LoadDatabases fetches the list of all databases from MongoDB and caches it.
// Call this once at startup (Lambda init). The list is used for all subsequent
// Resolve calls without additional database queries.
func (r *ContentResolver) LoadDatabases(ctx context.Context) error {
	names, err := r.client.ListDatabaseNames(ctx, map[string]interface{}{})
	if err != nil {
		return fmt.Errorf("listing databases: %w", err)
	}

	r.mu.Lock()
	defer r.mu.Unlock()

	r.databases = make(map[string]bool, len(names))
	for _, name := range names {
		r.databases[name] = true
	}

	return nil
}

// Resolve returns a ContentClient for the given locale.
// It matches the fallback chain against the pre-loaded database list.
// Results are cached so each locale is resolved at most once.
func (r *ContentResolver) Resolve(locale string) *ContentClient {
	locale = strings.TrimSpace(locale)

	// Check cache first
	r.mu.RLock()
	if client, ok := r.cache[locale]; ok {
		r.mu.RUnlock()
		return client
	}
	r.mu.RUnlock()

	// Build fallback chain and match against known databases
	candidates := r.buildFallbackChain(locale)

	var resolved *ContentClient
	r.mu.RLock()
	for _, dbName := range candidates {
		if r.databases[dbName] {
			resolved = NewContentClient(r.client, dbName)
			break
		}
	}
	r.mu.RUnlock()

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
