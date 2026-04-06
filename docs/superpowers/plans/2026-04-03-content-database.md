# Content Database Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the `regal-recovery-content` MongoDB database with 12 collections, Go models, repository layer, indexes, seed script, and content Lambda wiring.

**Architecture:** Separate MongoDB database (`regal-recovery-content`) on the same cluster as `regal-recovery`. New `ContentClient` wrapping a second `mongo.Database` connection. New models and repository in the existing `internal/repository` package, following the established patterns (BaseDocument, interfaces, repo structs). Content Lambda updated to use the new database.

**Tech Stack:** Go 1.22+, MongoDB driver v2, Docker Compose (same MongoDB instance, second database)

**Spec:** `docs/specs/mongodb/content-schema-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `internal/repository/content_models.go` | All 12 content collection models |
| Modify | `internal/repository/content_repo.go` | Replace existing content repo with new database-backed version |
| Modify | `internal/repository/interfaces.go` | Expand `ContentRepository` interface with all new methods |
| Create | `internal/repository/content_mongo.go` | `ContentClient` wrapper + `EnsureContentIndexes` |
| Modify | `internal/config/config.go` | Add `MongoContentDatabase` config field |
| Modify | `cmd/lambda/content/main.go` | Wire up `ContentClient` |
| Create | `scripts/seed-content-data.sh` | Seed script for all 12 content collections |
| Modify | `scripts/seed-local-data.sh` | Remove migrated content sections (affirmation_packs, affirmations, devotionals, prompts) |
| Create | `internal/repository/content_repo_test.go` | Integration tests for content repository |

---

### Task 1: Content Models

**Files:**
- Create: `api/internal/repository/content_models.go`

- [ ] **Step 1: Create content_models.go with all 12 collection models**

```go
// internal/repository/content_models.go
package repository

import (
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
)

// ContentBaseDocument contains common attributes for all content documents.
type ContentBaseDocument struct {
	ID         bson.ObjectID `bson:"_id,omitempty"`
	TenantID   string        `bson:"tenantId"`
	Status     string        `bson:"status"` // draft, published, archived
	CreatedAt  time.Time     `bson:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt"`
}

// SetContentDefaults sets default values for ContentBaseDocument fields on creation.
func SetContentDefaults(doc *ContentBaseDocument) {
	now := NowUTC()
	if doc.CreatedAt.IsZero() {
		doc.CreatedAt = now
	}
	doc.ModifiedAt = now
	if doc.TenantID == "" {
		doc.TenantID = "SYSTEM"
	}
	if doc.Status == "" {
		doc.Status = "published"
	}
}

// FeatureAbout describes what a feature is and how to use it.
type FeatureAbout struct {
	ContentBaseDocument `bson:",inline"`

	Slug               string `bson:"slug"`
	Title              string `bson:"title"`
	Summary            string `bson:"summary"`
	ContentHTML        string `bson:"contentHtml"`
	Category           string `bson:"category"` // activity, tool, assessment, communication, content
	RelatedFeatureFlag string `bson:"relatedFeatureFlag"`
	IconName           string `bson:"iconName"`
	SortOrder          int    `bson:"sortOrder"`
}

// ContentAffirmationPack is an affirmation pack in the content database.
type ContentAffirmationPack struct {
	ContentBaseDocument `bson:",inline"`

	PackID           string `bson:"packId"`
	Name             string `bson:"name"`
	Description      string `bson:"description"`
	Tier             string `bson:"tier"` // standard, premium
	Price            int    `bson:"price"`
	Currency         string `bson:"currency"`
	AffirmationCount int    `bson:"affirmationCount"`
	Category         string `bson:"category"`
	ThumbnailURL     string `bson:"thumbnailUrl"`
	SortOrder        int    `bson:"sortOrder"`
}

// ContentAffirmation is an affirmation in the content database.
type ContentAffirmation struct {
	ContentBaseDocument `bson:",inline"`

	AffirmationID      string `bson:"affirmationId"`
	PackID             string `bson:"packId"`
	Statement          string `bson:"statement"`
	ScriptureReference string `bson:"scriptureReference,omitempty"`
	Category           string `bson:"category"`
	Language           string `bson:"language"`
	SortOrder          int    `bson:"sortOrder"`
}

// DevotionalPack is a devotional pack in the content database.
type DevotionalPack struct {
	ContentBaseDocument `bson:",inline"`

	PackID          string `bson:"packId"`
	Name            string `bson:"name"`
	Description     string `bson:"description"`
	Tier            string `bson:"tier"` // standard, premium
	Price           int    `bson:"price"`
	Currency        string `bson:"currency"`
	DevotionalCount int    `bson:"devotionalCount"`
	Category        string `bson:"category"`
	ThumbnailURL    string `bson:"thumbnailUrl"`
	SortOrder       int    `bson:"sortOrder"`
}

// ContentDevotional is a devotional in the content database.
type ContentDevotional struct {
	ContentBaseDocument `bson:",inline"`

	DevotionalID  string `bson:"devotionalId"`
	PackID        string `bson:"packId"`
	Day           int    `bson:"day"`
	Title         string `bson:"title"`
	Scripture     string `bson:"scripture"`
	ScriptureText string `bson:"scriptureText"`
	Reflection    string `bson:"reflection"`
	PrayerPrompt  string `bson:"prayerPrompt"`
}

// JournalPrompt is a journal prompt in the content database.
type JournalPrompt struct {
	ContentBaseDocument `bson:",inline"`

	PromptID  string   `bson:"promptId"`
	Text      string   `bson:"text"`
	Category  string   `bson:"category"` // daily, sobriety, emotional, relationships, spiritual, shame, triggers, amends, gratitude, deep
	Tags      []string `bson:"tags"`
	SortOrder int      `bson:"sortOrder"`
}

// GlossaryTerm is a recovery glossary term.
type GlossaryTerm struct {
	ContentBaseDocument `bson:",inline"`

	TermID       string   `bson:"termId"`
	Term         string   `bson:"term"`
	Definition   string   `bson:"definition"`
	RelatedSlugs []string `bson:"relatedSlugs"`
	SortOrder    int      `bson:"sortOrder"`
}

// EveningReviewQuestion is an evening review question.
type EveningReviewQuestion struct {
	ContentBaseDocument `bson:",inline"`

	QuestionID string `bson:"questionId"`
	Text       string `bson:"text"`
	Dimension  string `bson:"dimension"` // sobriety, emotional, relational, spiritual, recovery, faster-scale, looking-forward
	SortOrder  int    `bson:"sortOrder"`
}

// ActingInBehavior is an acting-in behavior.
type ActingInBehavior struct {
	ContentBaseDocument `bson:",inline"`

	BehaviorID  string `bson:"behaviorId"`
	Name        string `bson:"name"`
	Description string `bson:"description"`
	SortOrder   int    `bson:"sortOrder"`
}

// Need is an emotional/relational need.
type Need struct {
	ContentBaseDocument `bson:",inline"`

	NeedID      string `bson:"needId"`
	Name        string `bson:"name"`
	Description string `bson:"description"`
	SortOrder   int    `bson:"sortOrder"`
}

// SobrietyResetMessage is an encouragement message shown on sobriety reset.
type SobrietyResetMessage struct {
	ContentBaseDocument `bson:",inline"`

	MessageID          string `bson:"messageId"`
	Text               string `bson:"text"`
	ScriptureReference string `bson:"scriptureReference,omitempty"`
	SortOrder          int    `bson:"sortOrder"`
}

// Theme is an app color scheme theme.
type Theme struct {
	ContentBaseDocument `bson:",inline"`

	ThemeID     string      `bson:"themeId"`
	Name        string      `bson:"name"`
	Description string      `bson:"description"`
	Tier        string      `bson:"tier"` // standard, premium
	Price       int         `bson:"price"`
	Currency    string      `bson:"currency"`
	Colors      ThemeColors `bson:"colors"`
	PreviewURL  string      `bson:"previewUrl"`
	SortOrder   int         `bson:"sortOrder"`
}

// ThemeColors holds color definitions for a theme.
type ThemeColors struct {
	Primary       string `bson:"primary"`
	Secondary     string `bson:"secondary"`
	Accent        string `bson:"accent"`
	Background    string `bson:"background"`
	Surface       string `bson:"surface"`
	Text          string `bson:"text"`
	TextSecondary string `bson:"textSecondary"`
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd api && go build ./internal/repository/`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add api/internal/repository/content_models.go
git commit -m "feat(content-db): add content database models for 12 collections"
```

---

### Task 2: Content Database Client and Indexes

**Files:**
- Create: `api/internal/repository/content_mongo.go`
- Modify: `api/internal/config/config.go`

- [ ] **Step 1: Add MongoContentDatabase to config**

In `api/internal/config/config.go`, add the field to the `Config` struct:

```go
// MongoContentDatabase is the MongoDB database name for content
MongoContentDatabase string
```

And in the `Load()` function, add:

```go
MongoContentDatabase: getEnv("MONGODB_CONTENT_DATABASE", "regal-recovery-content"),
```

- [ ] **Step 2: Create content_mongo.go with ContentClient and EnsureContentIndexes**

```go
// internal/repository/content_mongo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// ContentClient wraps a MongoDB database handle for the regal-recovery-content database.
type ContentClient struct {
	database *mongo.Database
}

// NewContentClient creates a ContentClient using an existing mongo.Client and a database name.
func NewContentClient(client *mongo.Client, dbName string) *ContentClient {
	return &ContentClient{
		database: client.Database(dbName),
	}
}

// Collection returns a handle to the named collection in the content database.
func (c *ContentClient) Collection(name string) *mongo.Collection {
	return c.database.Collection(name)
}

// EnsureContentIndexes creates all indexes for the content database.
func (c *ContentClient) EnsureContentIndexes(ctx context.Context) error {
	indexes := map[string][]mongo.IndexModel{
		"feature_abouts": {
			{Keys: bson.D{{Key: "slug", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"affirmation_packs": {
			{Keys: bson.D{{Key: "packId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "tier", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"affirmations": {
			{Keys: bson.D{{Key: "affirmationId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "packId", Value: 1}, {Key: "sortOrder", Value: 1}}},
		},
		"devotional_packs": {
			{Keys: bson.D{{Key: "packId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "tier", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
		"devotionals": {
			{Keys: bson.D{{Key: "devotionalId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "packId", Value: 1}, {Key: "day", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"journal_prompts": {
			{Keys: bson.D{{Key: "promptId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}}},
			{Keys: bson.D{{Key: "tags", Value: 1}}},
		},
		"glossary_terms": {
			{Keys: bson.D{{Key: "termId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "term", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"evening_review_questions": {
			{Keys: bson.D{{Key: "questionId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "dimension", Value: 1}, {Key: "sortOrder", Value: 1}}},
		},
		"acting_in_behaviors": {
			{Keys: bson.D{{Key: "behaviorId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"needs": {
			{Keys: bson.D{{Key: "needId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"sobriety_reset_messages": {
			{Keys: bson.D{{Key: "messageId", Value: 1}}, Options: options.Index().SetUnique(true)},
		},
		"themes": {
			{Keys: bson.D{{Key: "themeId", Value: 1}}, Options: options.Index().SetUnique(true)},
			{Keys: bson.D{{Key: "tier", Value: 1}}},
			{Keys: bson.D{{Key: "status", Value: 1}}},
		},
	}

	for collName, collIndexes := range indexes {
		_, err := c.Collection(collName).Indexes().CreateMany(ctx, collIndexes)
		if err != nil {
			return fmt.Errorf("creating indexes for %s: %w", collName, err)
		}
	}

	return nil
}
```

- [ ] **Step 3: Verify it compiles**

Run: `cd api && go build ./internal/repository/ && go build ./internal/config/`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add api/internal/repository/content_mongo.go api/internal/config/config.go
git commit -m "feat(content-db): add ContentClient with index definitions and config"
```

---

### Task 3: Content Repository Interface

**Files:**
- Modify: `api/internal/repository/interfaces.go`

- [ ] **Step 1: Replace the existing ContentRepository interface**

Replace the current `ContentRepository` interface (lines 117-131) with:

```go
// ContentRepository defines the interface for content database operations.
type ContentRepository interface {
	// Feature Abouts
	GetFeatureAbout(ctx context.Context, slug string) (*FeatureAbout, error)
	ListFeatureAbouts(ctx context.Context) ([]FeatureAbout, error)
	ListFeatureAboutsByCategory(ctx context.Context, category string) ([]FeatureAbout, error)

	// Affirmation Packs
	GetAffirmationPack(ctx context.Context, packID string) (*ContentAffirmationPack, error)
	ListAffirmationPacks(ctx context.Context) ([]ContentAffirmationPack, error)
	ListAffirmationsInPack(ctx context.Context, packID string) ([]ContentAffirmation, error)

	// Devotional Packs
	GetDevotionalPack(ctx context.Context, packID string) (*DevotionalPack, error)
	ListDevotionalPacks(ctx context.Context) ([]DevotionalPack, error)
	GetDevotional(ctx context.Context, packID string, day int) (*ContentDevotional, error)
	ListDevotionalsInPack(ctx context.Context, packID string) ([]ContentDevotional, error)

	// Journal Prompts
	GetJournalPrompt(ctx context.Context, promptID string) (*JournalPrompt, error)
	ListJournalPrompts(ctx context.Context, category string) ([]JournalPrompt, error)
	ListJournalPromptsByTag(ctx context.Context, tag string) ([]JournalPrompt, error)

	// Glossary
	ListGlossaryTerms(ctx context.Context) ([]GlossaryTerm, error)

	// Evening Review Questions
	ListEveningReviewQuestions(ctx context.Context, dimension string) ([]EveningReviewQuestion, error)

	// Acting-In Behaviors
	ListActingInBehaviors(ctx context.Context) ([]ActingInBehavior, error)

	// Needs
	ListNeeds(ctx context.Context) ([]Need, error)

	// Sobriety Reset Messages
	ListSobrietyResetMessages(ctx context.Context) ([]SobrietyResetMessage, error)
	GetRandomSobrietyResetMessage(ctx context.Context) (*SobrietyResetMessage, error)

	// Themes
	ListThemes(ctx context.Context) ([]Theme, error)
	ListThemesByTier(ctx context.Context, tier string) ([]Theme, error)
	GetTheme(ctx context.Context, themeID string) (*Theme, error)
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd api && go build ./internal/repository/`
Expected: Compile error — `ContentRepo` no longer satisfies the interface. This is expected and will be fixed in the next task.

- [ ] **Step 3: Commit**

```bash
git add api/internal/repository/interfaces.go
git commit -m "feat(content-db): expand ContentRepository interface for all 12 collections"
```

---

### Task 4: Content Repository Implementation

**Files:**
- Modify: `api/internal/repository/content_repo.go`

- [ ] **Step 1: Rewrite content_repo.go to use ContentClient**

Replace the entire file with:

```go
// internal/repository/content_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// ContentRepo implements ContentRepository using the content MongoDB database.
type ContentRepo struct {
	client *ContentClient
}

// NewContentRepo creates a new ContentRepo.
func NewContentRepo(client *ContentClient) *ContentRepo {
	return &ContentRepo{client: client}
}

// --- Feature Abouts ---

func (r *ContentRepo) GetFeatureAbout(ctx context.Context, slug string) (*FeatureAbout, error) {
	var doc FeatureAbout
	err := r.client.Collection("feature_abouts").FindOne(ctx, bson.M{"slug": slug, "status": "published"}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting feature about %s: %w", slug, err)
	}
	return &doc, nil
}

func (r *ContentRepo) ListFeatureAbouts(ctx context.Context) ([]FeatureAbout, error) {
	opts := options.Find().SetSort(bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("feature_abouts").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing feature abouts: %w", err)
	}
	var docs []FeatureAbout
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding feature abouts: %w", err)
	}
	return docs, nil
}

func (r *ContentRepo) ListFeatureAboutsByCategory(ctx context.Context, category string) ([]FeatureAbout, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("feature_abouts").Find(ctx, bson.M{"status": "published", "category": category}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing feature abouts by category %s: %w", category, err)
	}
	var docs []FeatureAbout
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding feature abouts: %w", err)
	}
	return docs, nil
}

// --- Affirmation Packs ---

func (r *ContentRepo) GetAffirmationPack(ctx context.Context, packID string) (*ContentAffirmationPack, error) {
	var doc ContentAffirmationPack
	err := r.client.Collection("affirmation_packs").FindOne(ctx, bson.M{"packId": packID, "status": "published"}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting affirmation pack %s: %w", packID, err)
	}
	return &doc, nil
}

func (r *ContentRepo) ListAffirmationPacks(ctx context.Context) ([]ContentAffirmationPack, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("affirmation_packs").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing affirmation packs: %w", err)
	}
	var docs []ContentAffirmationPack
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding affirmation packs: %w", err)
	}
	return docs, nil
}

func (r *ContentRepo) ListAffirmationsInPack(ctx context.Context, packID string) ([]ContentAffirmation, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("affirmations").Find(ctx, bson.M{"packId": packID, "status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing affirmations for pack %s: %w", packID, err)
	}
	var docs []ContentAffirmation
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding affirmations: %w", err)
	}
	return docs, nil
}

// --- Devotional Packs ---

func (r *ContentRepo) GetDevotionalPack(ctx context.Context, packID string) (*DevotionalPack, error) {
	var doc DevotionalPack
	err := r.client.Collection("devotional_packs").FindOne(ctx, bson.M{"packId": packID, "status": "published"}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting devotional pack %s: %w", packID, err)
	}
	return &doc, nil
}

func (r *ContentRepo) ListDevotionalPacks(ctx context.Context) ([]DevotionalPack, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("devotional_packs").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing devotional packs: %w", err)
	}
	var docs []DevotionalPack
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding devotional packs: %w", err)
	}
	return docs, nil
}

func (r *ContentRepo) GetDevotional(ctx context.Context, packID string, day int) (*ContentDevotional, error) {
	var doc ContentDevotional
	err := r.client.Collection("devotionals").FindOne(ctx, bson.M{"packId": packID, "day": day, "status": "published"}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting devotional pack=%s day=%d: %w", packID, day, err)
	}
	return &doc, nil
}

func (r *ContentRepo) ListDevotionalsInPack(ctx context.Context, packID string) ([]ContentDevotional, error) {
	opts := options.Find().SetSort(bson.D{{Key: "day", Value: 1}})
	cursor, err := r.client.Collection("devotionals").Find(ctx, bson.M{"packId": packID, "status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing devotionals for pack %s: %w", packID, err)
	}
	var docs []ContentDevotional
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding devotionals: %w", err)
	}
	return docs, nil
}

// --- Journal Prompts ---

func (r *ContentRepo) GetJournalPrompt(ctx context.Context, promptID string) (*JournalPrompt, error) {
	var doc JournalPrompt
	err := r.client.Collection("journal_prompts").FindOne(ctx, bson.M{"promptId": promptID, "status": "published"}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting journal prompt %s: %w", promptID, err)
	}
	return &doc, nil
}

func (r *ContentRepo) ListJournalPrompts(ctx context.Context, category string) ([]JournalPrompt, error) {
	filter := bson.M{"status": "published"}
	if category != "" {
		filter["category"] = category
	}
	opts := options.Find().SetSort(bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("journal_prompts").Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing journal prompts: %w", err)
	}
	var docs []JournalPrompt
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding journal prompts: %w", err)
	}
	return docs, nil
}

func (r *ContentRepo) ListJournalPromptsByTag(ctx context.Context, tag string) ([]JournalPrompt, error) {
	opts := options.Find().SetSort(bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("journal_prompts").Find(ctx, bson.M{"status": "published", "tags": tag}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing journal prompts by tag %s: %w", tag, err)
	}
	var docs []JournalPrompt
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding journal prompts: %w", err)
	}
	return docs, nil
}

// --- Glossary ---

func (r *ContentRepo) ListGlossaryTerms(ctx context.Context) ([]GlossaryTerm, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("glossary_terms").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing glossary terms: %w", err)
	}
	var docs []GlossaryTerm
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding glossary terms: %w", err)
	}
	return docs, nil
}

// --- Evening Review Questions ---

func (r *ContentRepo) ListEveningReviewQuestions(ctx context.Context, dimension string) ([]EveningReviewQuestion, error) {
	filter := bson.M{"status": "published"}
	if dimension != "" {
		filter["dimension"] = dimension
	}
	opts := options.Find().SetSort(bson.D{{Key: "dimension", Value: 1}, {Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("evening_review_questions").Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing evening review questions: %w", err)
	}
	var docs []EveningReviewQuestion
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding evening review questions: %w", err)
	}
	return docs, nil
}

// --- Acting-In Behaviors ---

func (r *ContentRepo) ListActingInBehaviors(ctx context.Context) ([]ActingInBehavior, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("acting_in_behaviors").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing acting-in behaviors: %w", err)
	}
	var docs []ActingInBehavior
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding acting-in behaviors: %w", err)
	}
	return docs, nil
}

// --- Needs ---

func (r *ContentRepo) ListNeeds(ctx context.Context) ([]Need, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("needs").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing needs: %w", err)
	}
	var docs []Need
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding needs: %w", err)
	}
	return docs, nil
}

// --- Sobriety Reset Messages ---

func (r *ContentRepo) ListSobrietyResetMessages(ctx context.Context) ([]SobrietyResetMessage, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("sobriety_reset_messages").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing sobriety reset messages: %w", err)
	}
	var docs []SobrietyResetMessage
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding sobriety reset messages: %w", err)
	}
	return docs, nil
}

func (r *ContentRepo) GetRandomSobrietyResetMessage(ctx context.Context) (*SobrietyResetMessage, error) {
	messages, err := r.ListSobrietyResetMessages(ctx)
	if err != nil {
		return nil, err
	}
	if len(messages) == 0 {
		return nil, nil
	}
	index := int(NowISO8601()[17]-'0') % len(messages)
	return &messages[index], nil
}

// --- Themes ---

func (r *ContentRepo) ListThemes(ctx context.Context) ([]Theme, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("themes").Find(ctx, bson.M{"status": "published"}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing themes: %w", err)
	}
	var docs []Theme
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding themes: %w", err)
	}
	return docs, nil
}

func (r *ContentRepo) ListThemesByTier(ctx context.Context, tier string) ([]Theme, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("themes").Find(ctx, bson.M{"status": "published", "tier": tier}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing themes by tier %s: %w", tier, err)
	}
	var docs []Theme
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding themes: %w", err)
	}
	return docs, nil
}

func (r *ContentRepo) GetTheme(ctx context.Context, themeID string) (*Theme, error) {
	var doc Theme
	err := r.client.Collection("themes").FindOne(ctx, bson.M{"themeId": themeID, "status": "published"}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting theme %s: %w", themeID, err)
	}
	return &doc, nil
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd api && go build ./internal/repository/`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add api/internal/repository/content_repo.go
git commit -m "feat(content-db): implement ContentRepository for all 12 content collections"
```

---

### Task 5: Wire Content Lambda

**Files:**
- Modify: `api/cmd/lambda/content/main.go`

- [ ] **Step 1: Update content Lambda to create ContentClient**

Replace the file with:

```go
// cmd/lambda/content/main.go
package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"

	appconfig "github.com/regalrecovery/api/internal/config"
	"github.com/regalrecovery/api/internal/middleware"
	"github.com/regalrecovery/api/internal/repository"
	"github.com/regalrecovery/api/pkg/lambdahttp"
)

// mongoClient is declared at package level for connection reuse across Lambda invocations.
var mongoClient *repository.MongoClient
var contentClient *repository.ContentClient

func init() {
	ctx := context.Background()
	cfg := appconfig.Load()

	var err error
	mongoClient, err = repository.NewMongoClient(ctx, cfg.MongoURI, cfg.MongoDatabase)
	if err != nil {
		slog.Error("failed to connect to MongoDB", "error", err)
		os.Exit(1)
	}

	// Create content database client using the same underlying connection
	contentClient = repository.NewContentClient(mongoClient.Client(), cfg.MongoContentDatabase)
}

func main() {
	// Initialize structured logger
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	// Create content repository
	_ = repository.NewContentRepo(contentClient)

	// Create HTTP router
	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/content/affirmations", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Content service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/content/affirmations/{packId}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Content service not yet implemented"}]}`))
	})
	mux.HandleFunc("GET /v1/content/devotional/{day}", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusNotImplemented)
		w.Write([]byte(`{"errors":[{"status":501,"title":"Not Implemented","detail":"Content service not yet implemented"}]}`))
	})

	// Wrap with middleware chain
	handler := middleware.Chain(
		mux,
		middleware.RecoveryMiddleware,
		middleware.CorrelationMiddleware,
		middleware.LoggingMiddleware,
		middleware.AuthMiddleware,
		middleware.TenantMiddleware,
	)

	// Create Lambda adapter and start
	adapter := lambdahttp.NewAdapter(handler)
	lambda.Start(adapter.Handle)
}
```

- [ ] **Step 2: Add Client() method to MongoClient**

In `api/internal/repository/mongo.go`, add this method:

```go
// Client returns the underlying mongo.Client for creating additional database connections.
func (m *MongoClient) Client() *mongo.Client {
	return m.client
}
```

- [ ] **Step 3: Verify it compiles**

Run: `cd api && go build ./cmd/lambda/content/`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
git add api/cmd/lambda/content/main.go api/internal/repository/mongo.go
git commit -m "feat(content-db): wire ContentClient into content Lambda"
```

---

### Task 6: Content Seed Script

**Files:**
- Create: `api/scripts/seed-content-data.sh`

- [ ] **Step 1: Create the seed script**

```bash
#!/usr/bin/env bash
# Seed regal-recovery-content database with all 12 collections
set -euo pipefail

echo "Seeding regal-recovery-content database..."
echo ""

docker compose exec -T mongodb mongosh regal-recovery-content --eval '
db.dropDatabase();
print("✓ Dropped existing content database for fresh seed");
print("");

// =============================================================================
// FEATURE ABOUTS (31 entries)
// =============================================================================

var now = ISODate("2026-04-03T00:00:00Z");
var base = { tenantId: "SYSTEM", status: "published", createdAt: now, modifiedAt: now };

db.feature_abouts.insertMany([
  { ...base, slug: "faster-scale", title: "Understanding the FASTER Scale", summary: "The FASTER Scale helps identify where you are in the relapse cycle.", contentHtml: "<p>Developed by Michael Dye, the FASTER Scale maps six progressive stages leading to relapse.</p>", category: "activity", relatedFeatureFlag: "activity.faster-scale", iconName: "speedometer", sortOrder: 1 },
  { ...base, slug: "triggers", title: "Understanding Triggers", summary: "Learn to identify and manage the triggers that precede compulsive behavior.", contentHtml: "<p>In recovery, a trigger is any internal state or external stimulus that activates the urge to act out.</p>", category: "tool", relatedFeatureFlag: "feature.triggers", iconName: "alert-triangle", sortOrder: 1 },
  { ...base, slug: "3circles", title: "The Three Circles", summary: "A boundary-setting tool for categorizing behaviors into inner, middle, and outer circles.", contentHtml: "<p>The Three Circles model categorizes behaviors into inner (acting out), middle (warning), and outer (healthy) circles.</p>", category: "tool", relatedFeatureFlag: "feature.three-circles", iconName: "circles", sortOrder: 2 },
  { ...base, slug: "evening-review", title: "Evening Review", summary: "A structured end-of-day inventory for sobriety, honesty, and emotional health.", contentHtml: "<p>The evening review is the daily practice of Step 10 — an honest end-of-day accounting.</p>", category: "activity", relatedFeatureFlag: "activity.check-ins", iconName: "moon", sortOrder: 2 },
  { ...base, slug: "urge-logging", title: "Urge Logging", summary: "Track urges with intensity, triggers, and outcomes to reveal patterns.", contentHtml: "<p>Logging urges builds self-awareness and reveals patterns over time.</p>", category: "activity", relatedFeatureFlag: "activity.urge-logging", iconName: "flame", sortOrder: 3 },
  { ...base, slug: "journaling", title: "Recovery Journaling", summary: "Process thoughts and emotions through guided or free-form writing.", contentHtml: "<p>Journaling is a cornerstone recovery practice for processing emotions and tracking growth.</p>", category: "activity", relatedFeatureFlag: "activity.journaling", iconName: "book-open", sortOrder: 4 },
  { ...base, slug: "fanos", title: "FANOS Check-In", summary: "A structured framework for honest communication: Feelings, Appreciation, Needs, Ownership, Sobriety.", contentHtml: "<p>FANOS provides a safe structure for sharing with your spouse or accountability partner.</p>", category: "communication", relatedFeatureFlag: "activity.fanos", iconName: "message-circle", sortOrder: 1 },
  { ...base, slug: "fitnap", title: "FITNAP Check-In", summary: "An alternative check-in framework: Feelings, Intimacy, Triggers, Needs, Affirmations, Prayer.", contentHtml: "<p>FITNAP is an alternative to FANOS with explicit discussion of triggers and a spiritual component.</p>", category: "communication", relatedFeatureFlag: "activity.fitnap", iconName: "message-square", sortOrder: 2 },
  { ...base, slug: "pci", title: "Personal Craziness Index", summary: "Track 10 personalized warning behaviors that signal rising vulnerability.", contentHtml: "<p>Created by Patrick Carnes, the PCI measures overall life manageability across behavioral dimensions.</p>", category: "activity", relatedFeatureFlag: "activity.pci", iconName: "activity", sortOrder: 5 },
  { ...base, slug: "sobriety-commitment", title: "Sobriety Commitment", summary: "Declare your daily commitment to sobriety as a recovery anchor.", contentHtml: "<p>The sobriety commitment is a daily declaration that anchors your recovery intention.</p>", category: "activity", relatedFeatureFlag: "activity.sobriety-commitment", iconName: "shield", sortOrder: 6 },
  { ...base, slug: "affirmations", title: "Daily Affirmations", summary: "Scripture-based affirmations to renew your mind and identity.", contentHtml: "<p>Daily affirmations combat the lies of addiction with biblical truth about your identity.</p>", category: "content", relatedFeatureFlag: "activity.affirmations", iconName: "sun", sortOrder: 1 },
  { ...base, slug: "devotionals", title: "Daily Devotionals", summary: "Scripture, reflection, and prayer for your recovery journey.", contentHtml: "<p>Daily devotionals provide scripture-grounded reflection specific to recovery themes.</p>", category: "content", relatedFeatureFlag: "feature.content-resources", iconName: "book", sortOrder: 2 },
  { ...base, slug: "step-work", title: "12-Step Work", summary: "Guided journaling through the 12 Steps of recovery.", contentHtml: "<p>The 12 Steps guide you from admitting powerlessness through spiritual awakening and service.</p>", category: "content", relatedFeatureFlag: "activity.step-work", iconName: "list-ordered", sortOrder: 3 },
  { ...base, slug: "acting-in", title: "Acting In", summary: "Track subtle internalized addiction behaviors that occur within relationships.", contentHtml: "<p>Acting in refers to subtle behaviors like emotional withdrawal, dishonesty by omission, and manipulation.</p>", category: "activity", relatedFeatureFlag: "activity.acting-in", iconName: "eye-off", sortOrder: 7 },
  { ...base, slug: "arousal-template", title: "Arousal Template", summary: "Map the patterns of thoughts, feelings, and situations that fuel compulsive behavior.", contentHtml: "<p>Developed by Patrick Carnes, the arousal template describes your unique constellation of triggers.</p>", category: "tool", relatedFeatureFlag: "feature.arousal-template", iconName: "map", sortOrder: 3 },
  { ...base, slug: "relapse-prevention", title: "Relapse Prevention Plan", summary: "A structured plan of triggers, coping strategies, and emergency contacts.", contentHtml: "<p>Your relapse prevention plan is your personalized defense strategy for high-risk situations.</p>", category: "tool", relatedFeatureFlag: "feature.relapse-prevention", iconName: "shield-check", sortOrder: 4 },
  { ...base, slug: "vision-statement", title: "Vision Statement", summary: "Write the vision for the man you are becoming in recovery.", contentHtml: "<p>Your vision statement describes the life recovery is making possible — grounded and honest.</p>", category: "tool", relatedFeatureFlag: "feature.vision-statement", iconName: "target", sortOrder: 5 },
  { ...base, slug: "mood-tracking", title: "Mood Tracking", summary: "Rate and track your emotional state throughout the day.", contentHtml: "<p>Regular mood tracking builds emotional awareness — a core recovery skill.</p>", category: "activity", relatedFeatureFlag: "activity.mood-tracking", iconName: "smile", sortOrder: 8 },
  { ...base, slug: "gratitude-list", title: "Gratitude List", summary: "Capture what you are grateful for to shift focus from struggle to blessing.", contentHtml: "<p>Gratitude practice rewires the brain away from negativity bias and toward hope.</p>", category: "activity", relatedFeatureFlag: "activity.gratitude", iconName: "heart", sortOrder: 9 },
  { ...base, slug: "prayer", title: "Prayer", summary: "Log your prayer practice and track spiritual engagement.", contentHtml: "<p>Prayer is the lifeline of recovery — your direct communication with God.</p>", category: "activity", relatedFeatureFlag: "activity.prayer", iconName: "hands", sortOrder: 10 },
  { ...base, slug: "meetings", title: "Meeting Attendance", summary: "Track 12-step and recovery meeting attendance.", contentHtml: "<p>Regular meeting attendance is one of the strongest predictors of sustained recovery.</p>", category: "activity", relatedFeatureFlag: "activity.meetings", iconName: "users", sortOrder: 11 },
  { ...base, slug: "exercise", title: "Exercise", summary: "Log physical activity that supports recovery and emotional regulation.", contentHtml: "<p>Exercise releases endorphins, reduces stress, and rebuilds the brain pathways damaged by addiction.</p>", category: "activity", relatedFeatureFlag: "activity.exercise", iconName: "dumbbell", sortOrder: 12 },
  { ...base, slug: "time-journal", title: "Time Journal", summary: "Interval-based check-ins that capture location, emotion, and activity throughout the day.", contentHtml: "<p>The time journal is a structured, interval-based journaling activity for pattern recognition.</p>", category: "activity", relatedFeatureFlag: "activity.time-journal", iconName: "clock", sortOrder: 13 },
  { ...base, slug: "emotional-journal", title: "Emotional Journal", summary: "Quick emotional awareness captures with optional location and selfie.", contentHtml: "<p>The emotional journal is designed for frequent, low-friction emotional awareness throughout the day.</p>", category: "activity", relatedFeatureFlag: "activity.emotional-journal", iconName: "heart-pulse", sortOrder: 14 },
  { ...base, slug: "post-mortem", title: "Post-Mortem Analysis", summary: "Structured reflection after a relapse to learn and prevent recurrence.", contentHtml: "<p>A relapse is not a failure — it is information. The post-mortem helps you learn from what happened.</p>", category: "activity", relatedFeatureFlag: "activity.post-mortem", iconName: "search", sortOrder: 15 },
  { ...base, slug: "sast-r", title: "SAST-R Assessment", summary: "A validated screening tool for assessing sexual addiction patterns.", contentHtml: "<p>The Sexual Addiction Screening Test (Revised) measures behavioral patterns across multiple dimensions.</p>", category: "assessment", relatedFeatureFlag: "activity.sast-r", iconName: "clipboard-check", sortOrder: 1 },
  { ...base, slug: "denial", title: "Denial Assessment", summary: "Identify patterns of denial that block honest self-assessment.", contentHtml: "<p>Denial is the primary defense mechanism of addiction — recognizing it is the first step to freedom.</p>", category: "assessment", relatedFeatureFlag: "activity.denial", iconName: "shield-off", sortOrder: 2 },
  { ...base, slug: "rl-backbone", title: "Backbone", summary: "Build your daily recovery backbone — the non-negotiable practices that sustain freedom.", contentHtml: "<p>Your backbone is the set of daily recovery practices you commit to no matter what.</p>", category: "activity", relatedFeatureFlag: "activity.backbone", iconName: "spine", sortOrder: 16 },
  { ...base, slug: "memory-verse", title: "Memory Verse Review", summary: "Memorize and review scripture verses that anchor your recovery.", contentHtml: "<p>Scripture memorization renews the mind and provides truth to combat addictive thinking.</p>", category: "activity", relatedFeatureFlag: "activity.memory-verse", iconName: "bookmark", sortOrder: 17 },
  { ...base, slug: "nutrition", title: "Nutrition", summary: "Track meals and eating habits that support physical recovery.", contentHtml: "<p>Proper nutrition stabilizes blood sugar, supports brain healing, and reduces vulnerability to triggers.</p>", category: "activity", relatedFeatureFlag: "activity.nutrition", iconName: "apple", sortOrder: 18 },
  { ...base, slug: "book-reading", title: "Book Reading", summary: "Track recovery and spiritual reading progress.", contentHtml: "<p>Reading recovery literature and scripture deepens understanding and reinforces recovery principles.</p>", category: "activity", relatedFeatureFlag: "activity.book-reading", iconName: "book-open-check", sortOrder: 19 }
]);
print("✓ Created 31 feature abouts");

// =============================================================================
// AFFIRMATION PACKS + AFFIRMATIONS (migrated from regal-recovery)
// =============================================================================

db.affirmation_packs.insertOne({
  ...base, packId: "pack_christian", name: "Christian Affirmations",
  description: "44 biblical affirmations for daily recovery",
  tier: "standard", price: 0, currency: "USD", affirmationCount: 5,
  category: "christian", thumbnailUrl: "", sortOrder: 1
});
print("✓ Created affirmation pack: Christian Affirmations");

db.affirmations.insertMany([
  { ...base, affirmationId: "aff_001", packId: "pack_christian", statement: "I am fearfully and wonderfully made.", scriptureReference: "Psalm 139:14", category: "identity", language: "en", sortOrder: 1 },
  { ...base, affirmationId: "aff_002", packId: "pack_christian", statement: "I can do all things through Christ who strengthens me.", scriptureReference: "Philippians 4:13", category: "strength", language: "en", sortOrder: 2 },
  { ...base, affirmationId: "aff_003", packId: "pack_christian", statement: "The Lord is my shepherd; I shall not want.", scriptureReference: "Psalm 23:1", category: "peace", language: "en", sortOrder: 3 },
  { ...base, affirmationId: "aff_004", packId: "pack_christian", statement: "God is my refuge and strength, an ever-present help in trouble.", scriptureReference: "Psalm 46:1", category: "strength", language: "en", sortOrder: 4 },
  { ...base, affirmationId: "aff_005", packId: "pack_christian", statement: "I am a new creation in Christ; the old has passed away.", scriptureReference: "2 Corinthians 5:17", category: "identity", language: "en", sortOrder: 5 }
]);
print("✓ Created 5 affirmations");

// =============================================================================
// DEVOTIONAL PACKS + DEVOTIONALS (new pack structure)
// =============================================================================

db.devotional_packs.insertOne({
  ...base, packId: "dpack_foundations", name: "Foundations",
  description: "Core devotionals for the recovery journey",
  tier: "standard", price: 0, currency: "USD", devotionalCount: 3,
  category: "core", thumbnailUrl: "", sortOrder: 1
});
print("✓ Created devotional pack: Foundations");

db.devotionals.insertMany([
  { ...base, devotionalId: "dev_001", packId: "dpack_foundations", day: 1, title: "A New Beginning", scripture: "2 Corinthians 5:17", scriptureText: "Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!", reflection: "Every day in recovery is a fresh start. God does not define us by our past failures but by His redeeming love.", prayerPrompt: "Lord, help me embrace this new beginning." },
  { ...base, devotionalId: "dev_002", packId: "dpack_foundations", day: 2, title: "Strength for the Journey", scripture: "Isaiah 40:31", scriptureText: "But those who hope in the Lord will renew their strength.", reflection: "Recovery requires daily surrender. When we place our hope in the Lord, He renews us.", prayerPrompt: "Father, renew my strength today as I place my hope in You." },
  { ...base, devotionalId: "dev_003", packId: "dpack_foundations", day: 3, title: "Freedom from Shame", scripture: "Romans 8:1", scriptureText: "Therefore, there is now no condemnation for those who are in Christ Jesus.", reflection: "Shame is the enemy of recovery. God has removed our condemnation through Jesus.", prayerPrompt: "God, free me from the weight of shame and help me walk in Your grace." }
]);
print("✓ Created 3 devotionals");

// =============================================================================
// JOURNAL PROMPTS (migrated from regal-recovery.prompts)
// =============================================================================

db.journal_prompts.insertMany([
  { ...base, promptId: "prompt_001", text: "What am I most grateful for today, and what was the hardest part of my day?", category: "daily", tags: [], sortOrder: 1 },
  { ...base, promptId: "prompt_002", text: "What triggers did I encounter today, and how did I respond?", category: "sobriety", tags: ["FASTER", "triggers"], sortOrder: 1 },
  { ...base, promptId: "prompt_003", text: "What emotions am I experiencing right now? Where do I feel them in my body?", category: "emotional", tags: ["FANOS/FITNAP"], sortOrder: 1 },
  { ...base, promptId: "prompt_004", text: "What relationship brought me joy today? What relationship challenged me?", category: "relationships", tags: [], sortOrder: 1 },
  { ...base, promptId: "prompt_005", text: "How did I experience God today? Where did I see His hand at work?", category: "spiritual", tags: ["12-Step"], sortOrder: 1 }
]);
print("✓ Created 5 journal prompts");

// =============================================================================
// GLOSSARY TERMS
// =============================================================================

db.glossary_terms.insertMany([
  { ...base, termId: "term_faster", term: "FASTER Scale", definition: "A relapse-awareness tool developed by Michael Dye that maps six progressive stages leading to relapse: Forgetting Priorities, Anxiety, Speeding Up, Ticked Off, Exhausted, Relapse.", relatedSlugs: ["faster-scale"], sortOrder: 1 },
  { ...base, termId: "term_fanos", term: "FANOS", definition: "A structured couples check-in framework: Feelings, Affirmations, Needs, Ownership, Sobriety.", relatedSlugs: ["fanos"], sortOrder: 2 },
  { ...base, termId: "term_3circles", term: "3 Circles", definition: "A boundary-setting tool where behaviors are categorized into inner (acting out), middle (warning), and outer (healthy) circles.", relatedSlugs: ["3circles"], sortOrder: 3 },
  { ...base, termId: "term_pci", term: "PCI", definition: "Personal Craziness Index — a self-assessment tool by Patrick Carnes that measures overall life manageability.", relatedSlugs: ["pci"], sortOrder: 4 },
  { ...base, termId: "term_sastr", term: "SAST-R", definition: "Sexual Addiction Screening Test (Revised) — a validated clinical screening instrument for sexual addiction.", relatedSlugs: ["sast-r"], sortOrder: 5 }
]);
print("✓ Created 5 glossary terms");

// =============================================================================
// EVENING REVIEW QUESTIONS
// =============================================================================

db.evening_review_questions.insertMany([
  { ...base, questionId: "erq_001", text: "Was I sober today in thought, word, and action?", dimension: "sobriety", sortOrder: 1 },
  { ...base, questionId: "erq_002", text: "Was I fully honest today — no lies, omissions, or secrets?", dimension: "sobriety", sortOrder: 2 },
  { ...base, questionId: "erq_003", text: "What emotions did I experience today? Can I name at least three?", dimension: "emotional", sortOrder: 1 },
  { ...base, questionId: "erq_004", text: "Did I treat the people around me with respect and kindness today?", dimension: "relational", sortOrder: 1 },
  { ...base, questionId: "erq_005", text: "Did I spend time with God today — in prayer, scripture, or quiet listening?", dimension: "spiritual", sortOrder: 1 },
  { ...base, questionId: "erq_006", text: "Did I work my recovery plan today?", dimension: "recovery", sortOrder: 1 },
  { ...base, questionId: "erq_007", text: "Where am I on the FASTER Scale right now, honestly?", dimension: "faster-scale", sortOrder: 1 },
  { ...base, questionId: "erq_008", text: "What is one thing I need to do differently tomorrow?", dimension: "looking-forward", sortOrder: 1 }
]);
print("✓ Created 8 evening review questions");

// =============================================================================
// ACTING-IN BEHAVIORS
// =============================================================================

db.acting_in_behaviors.insertMany([
  { ...base, behaviorId: "aib_001", name: "Blame", description: "", sortOrder: 1 },
  { ...base, behaviorId: "aib_002", name: "Shame", description: "", sortOrder: 2 },
  { ...base, behaviorId: "aib_003", name: "Criticism", description: "", sortOrder: 3 },
  { ...base, behaviorId: "aib_004", name: "Stonewall", description: "", sortOrder: 4 },
  { ...base, behaviorId: "aib_005", name: "Avoid", description: "", sortOrder: 5 },
  { ...base, behaviorId: "aib_006", name: "Hide", description: "", sortOrder: 6 },
  { ...base, behaviorId: "aib_007", name: "Lie", description: "", sortOrder: 7 },
  { ...base, behaviorId: "aib_008", name: "Excuse", description: "", sortOrder: 8 },
  { ...base, behaviorId: "aib_009", name: "Manipulate", description: "", sortOrder: 9 },
  { ...base, behaviorId: "aib_010", name: "Control with Anger", description: "", sortOrder: 10 },
  { ...base, behaviorId: "aib_011", name: "Passivity", description: "", sortOrder: 11 },
  { ...base, behaviorId: "aib_012", name: "Humor", description: "", sortOrder: 12 },
  { ...base, behaviorId: "aib_013", name: "Placating", description: "", sortOrder: 13 },
  { ...base, behaviorId: "aib_014", name: "Withhold Love/Sex", description: "", sortOrder: 14 },
  { ...base, behaviorId: "aib_015", name: "HyperSpiritualize", description: "", sortOrder: 15 }
]);
print("✓ Created 15 acting-in behaviors");

// =============================================================================
// NEEDS
// =============================================================================

db.needs.insertMany([
  { ...base, needId: "need_001", name: "Acceptance", description: "", sortOrder: 1 },
  { ...base, needId: "need_002", name: "Affirmation", description: "", sortOrder: 2 },
  { ...base, needId: "need_003", name: "Agency", description: "", sortOrder: 3 },
  { ...base, needId: "need_004", name: "Belonging", description: "", sortOrder: 4 },
  { ...base, needId: "need_005", name: "Comfort", description: "", sortOrder: 5 },
  { ...base, needId: "need_006", name: "Compassion", description: "", sortOrder: 6 },
  { ...base, needId: "need_007", name: "Connection", description: "", sortOrder: 7 },
  { ...base, needId: "need_008", name: "Empathy", description: "", sortOrder: 8 },
  { ...base, needId: "need_009", name: "Encouragement", description: "", sortOrder: 9 },
  { ...base, needId: "need_010", name: "Forgiveness", description: "", sortOrder: 10 },
  { ...base, needId: "need_011", name: "Grace", description: "", sortOrder: 11 },
  { ...base, needId: "need_012", name: "Hope", description: "", sortOrder: 12 },
  { ...base, needId: "need_013", name: "Love", description: "", sortOrder: 13 },
  { ...base, needId: "need_014", name: "Peace", description: "", sortOrder: 14 },
  { ...base, needId: "need_015", name: "Reassurance", description: "", sortOrder: 15 },
  { ...base, needId: "need_016", name: "Respect", description: "", sortOrder: 16 },
  { ...base, needId: "need_017", name: "Safety", description: "", sortOrder: 17 },
  { ...base, needId: "need_018", name: "Security", description: "", sortOrder: 18 },
  { ...base, needId: "need_019", name: "Understanding", description: "", sortOrder: 19 },
  { ...base, needId: "need_020", name: "Validation", description: "", sortOrder: 20 }
]);
print("✓ Created 20 needs");

// =============================================================================
// SOBRIETY RESET MESSAGES (first 10 of 50)
// =============================================================================

db.sobriety_reset_messages.insertMany([
  { ...base, messageId: "srm_001", text: "His mercies are new this morning — and so are you.", scriptureReference: "Lamentations 3:22-23", sortOrder: 1 },
  { ...base, messageId: "srm_002", text: "A reset is not the end of your story. It is a turning point. God is still writing.", scriptureReference: "", sortOrder: 2 },
  { ...base, messageId: "srm_003", text: "You are not defined by your worst moment. You are defined by the One who calls you His own.", scriptureReference: "", sortOrder: 3 },
  { ...base, messageId: "srm_004", text: "The righteous may fall seven times but still get up.", scriptureReference: "Proverbs 24:16", sortOrder: 4 },
  { ...base, messageId: "srm_005", text: "Right now, grace is louder than shame.", scriptureReference: "", sortOrder: 5 },
  { ...base, messageId: "srm_006", text: "God did not flinch. He knew this day would come, and He is still here, still for you, still working.", scriptureReference: "", sortOrder: 6 },
  { ...base, messageId: "srm_007", text: "There is therefore now no condemnation for those who are in Christ Jesus.", scriptureReference: "Romans 8:1", sortOrder: 7 },
  { ...base, messageId: "srm_008", text: "You had the courage to be honest. That matters more than you know.", scriptureReference: "", sortOrder: 8 },
  { ...base, messageId: "srm_009", text: "This reset does not erase the growth that came before it. Every sober day still counted.", scriptureReference: "", sortOrder: 9 },
  { ...base, messageId: "srm_010", text: "He heals the brokenhearted and binds up their wounds.", scriptureReference: "Psalm 147:3", sortOrder: 10 }
]);
print("✓ Created 10 sobriety reset messages");

// =============================================================================
// THEMES
// =============================================================================

db.themes.insertMany([
  { ...base, themeId: "theme_light", name: "Light", description: "Clean, bright default theme", tier: "standard", price: 0, currency: "USD", colors: { primary: "#1E3A5F", secondary: "#4A90D9", accent: "#F5A623", background: "#FFFFFF", surface: "#F5F5F5", text: "#1A1A1A", textSecondary: "#666666" }, previewUrl: "", sortOrder: 1 },
  { ...base, themeId: "theme_dark", name: "Dark", description: "Easy-on-the-eyes dark theme", tier: "standard", price: 0, currency: "USD", colors: { primary: "#4A90D9", secondary: "#1E3A5F", accent: "#F5A623", background: "#121212", surface: "#1E1E1E", text: "#E0E0E0", textSecondary: "#A0A0A0" }, previewUrl: "", sortOrder: 2 },
  { ...base, themeId: "theme_midnight", name: "Midnight", description: "Deep navy dark theme", tier: "standard", price: 0, currency: "USD", colors: { primary: "#1A1A2E", secondary: "#16213E", accent: "#0F3460", background: "#0A0A1A", surface: "#1A1A2E", text: "#E0E0E0", textSecondary: "#A0A0A0" }, previewUrl: "", sortOrder: 3 }
]);
print("✓ Created 3 themes");

print("");
print("=============================================================================");
print("✅ CONTENT DATABASE SEED COMPLETE");
print("=============================================================================");
print("");
print("Collections seeded:");
print("  - Feature Abouts: 31");
print("  - Affirmation Packs: 1");
print("  - Affirmations: 5");
print("  - Devotional Packs: 1");
print("  - Devotionals: 3");
print("  - Journal Prompts: 5");
print("  - Glossary Terms: 5");
print("  - Evening Review Questions: 8");
print("  - Acting-In Behaviors: 15");
print("  - Needs: 20");
print("  - Sobriety Reset Messages: 10");
print("  - Themes: 3");
'

echo ""
echo "Content database seed complete!"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x api/scripts/seed-content-data.sh`

- [ ] **Step 3: Commit**

```bash
git add api/scripts/seed-content-data.sh
git commit -m "feat(content-db): add seed script for regal-recovery-content database"
```

---

### Task 7: Remove Migrated Content from User DB Seed

**Files:**
- Modify: `api/scripts/seed-local-data.sh`

- [ ] **Step 1: Remove SECTION 10 (affirmation_packs, affirmations, devotionals, prompts) from seed-local-data.sh**

Delete everything between the comment `// SECTION 10: CONTENT LIBRARY` and the final `print` block (lines 986-1146 approximately). The content now lives in `seed-content-data.sh`.

Also update the final print summary to remove the content counts:
- Remove: `"  - Affirmation Packs: 1"`
- Remove: `"  - Affirmations: 5"`
- Remove: `"  - Devotionals: 3"`
- Remove: `"  - Prompts: 5"`

- [ ] **Step 2: Commit**

```bash
git add api/scripts/seed-local-data.sh
git commit -m "refactor(content-db): remove migrated content from user database seed"
```

---

### Task 8: Integration Tests

**Files:**
- Create: `api/internal/repository/content_repo_test.go`

- [ ] **Step 1: Write integration tests for key content repository methods**

```go
// internal/repository/content_repo_test.go
package repository_test

import (
	"context"
	"testing"
	"time"

	"github.com/regalrecovery/api/internal/repository"
	"github.com/regalrecovery/api/test/helpers"
	"go.mongodb.org/mongo-driver/v2/bson"
)

func setupContentTest(t *testing.T) (*repository.ContentRepo, func()) {
	t.Helper()
	client := helpers.SetupLocalMongo(t)
	db := client.Database("regal-recovery-content-test")
	contentClient := repository.NewContentClient(client, "regal-recovery-content-test")

	ctx := context.Background()
	if err := contentClient.EnsureContentIndexes(ctx); err != nil {
		t.Fatalf("failed to create indexes: %v", err)
	}

	repo := repository.NewContentRepo(contentClient)

	cleanup := func() {
		collections, _ := db.ListCollectionNames(ctx, bson.M{})
		for _, coll := range collections {
			db.Collection(coll).Drop(ctx)
		}
	}

	return repo, cleanup
}

func seedFeatureAbout(t *testing.T, contentClient *repository.ContentClient, slug, category string, sortOrder int) {
	t.Helper()
	now := time.Now().UTC()
	_, err := contentClient.Collection("feature_abouts").InsertOne(context.Background(), bson.M{
		"tenantId": "SYSTEM", "status": "published", "createdAt": now, "modifiedAt": now,
		"slug": slug, "title": "Test " + slug, "summary": "Test summary",
		"contentHtml": "<p>Test</p>", "category": category,
		"relatedFeatureFlag": "test." + slug, "iconName": "test", "sortOrder": sortOrder,
	})
	if err != nil {
		t.Fatalf("failed to seed feature about: %v", err)
	}
}

func TestGetFeatureAbout(t *testing.T) {
	repo, cleanup := setupContentTest(t)
	defer cleanup()

	client := helpers.SetupLocalMongo(t)
	contentClient := repository.NewContentClient(client, "regal-recovery-content-test")
	seedFeatureAbout(t, contentClient, "faster-scale", "activity", 1)

	ctx := context.Background()
	doc, err := repo.GetFeatureAbout(ctx, "faster-scale")
	if err != nil {
		t.Fatalf("GetFeatureAbout failed: %v", err)
	}
	if doc.Slug != "faster-scale" {
		t.Errorf("expected slug faster-scale, got %s", doc.Slug)
	}
	if doc.Category != "activity" {
		t.Errorf("expected category activity, got %s", doc.Category)
	}
}

func TestListFeatureAboutsByCategory(t *testing.T) {
	repo, cleanup := setupContentTest(t)
	defer cleanup()

	client := helpers.SetupLocalMongo(t)
	contentClient := repository.NewContentClient(client, "regal-recovery-content-test")
	seedFeatureAbout(t, contentClient, "faster-scale", "activity", 1)
	seedFeatureAbout(t, contentClient, "3circles", "tool", 1)
	seedFeatureAbout(t, contentClient, "urge-logging", "activity", 2)

	ctx := context.Background()
	docs, err := repo.ListFeatureAboutsByCategory(ctx, "activity")
	if err != nil {
		t.Fatalf("ListFeatureAboutsByCategory failed: %v", err)
	}
	if len(docs) != 2 {
		t.Errorf("expected 2 activity abouts, got %d", len(docs))
	}
	if docs[0].SortOrder > docs[1].SortOrder {
		t.Errorf("expected sorted by sortOrder, got %d before %d", docs[0].SortOrder, docs[1].SortOrder)
	}
}

func TestListGlossaryTerms(t *testing.T) {
	repo, cleanup := setupContentTest(t)
	defer cleanup()

	client := helpers.SetupLocalMongo(t)
	contentClient := repository.NewContentClient(client, "regal-recovery-content-test")
	now := time.Now().UTC()
	contentClient.Collection("glossary_terms").InsertOne(context.Background(), bson.M{
		"tenantId": "SYSTEM", "status": "published", "createdAt": now, "modifiedAt": now,
		"termId": "term_faster", "term": "FASTER Scale",
		"definition": "A relapse-awareness tool.", "relatedSlugs": []string{"faster-scale"}, "sortOrder": 1,
	})

	ctx := context.Background()
	docs, err := repo.ListGlossaryTerms(ctx)
	if err != nil {
		t.Fatalf("ListGlossaryTerms failed: %v", err)
	}
	if len(docs) != 1 {
		t.Errorf("expected 1 glossary term, got %d", len(docs))
	}
	if docs[0].Term != "FASTER Scale" {
		t.Errorf("expected term FASTER Scale, got %s", docs[0].Term)
	}
}

func TestListActingInBehaviors(t *testing.T) {
	repo, cleanup := setupContentTest(t)
	defer cleanup()

	client := helpers.SetupLocalMongo(t)
	contentClient := repository.NewContentClient(client, "regal-recovery-content-test")
	now := time.Now().UTC()
	contentClient.Collection("acting_in_behaviors").InsertMany(context.Background(), []interface{}{
		bson.M{"tenantId": "SYSTEM", "status": "published", "createdAt": now, "modifiedAt": now, "behaviorId": "aib_001", "name": "Blame", "description": "", "sortOrder": 1},
		bson.M{"tenantId": "SYSTEM", "status": "published", "createdAt": now, "modifiedAt": now, "behaviorId": "aib_002", "name": "Shame", "description": "", "sortOrder": 2},
	})

	ctx := context.Background()
	docs, err := repo.ListActingInBehaviors(ctx)
	if err != nil {
		t.Fatalf("ListActingInBehaviors failed: %v", err)
	}
	if len(docs) != 2 {
		t.Errorf("expected 2 behaviors, got %d", len(docs))
	}
}

func TestGetTheme(t *testing.T) {
	repo, cleanup := setupContentTest(t)
	defer cleanup()

	client := helpers.SetupLocalMongo(t)
	contentClient := repository.NewContentClient(client, "regal-recovery-content-test")
	now := time.Now().UTC()
	contentClient.Collection("themes").InsertOne(context.Background(), bson.M{
		"tenantId": "SYSTEM", "status": "published", "createdAt": now, "modifiedAt": now,
		"themeId": "theme_dark", "name": "Dark", "description": "Dark theme",
		"tier": "standard", "price": 0, "currency": "USD",
		"colors": bson.M{"primary": "#4A90D9", "secondary": "#1E3A5F", "accent": "#F5A623", "background": "#121212", "surface": "#1E1E1E", "text": "#E0E0E0", "textSecondary": "#A0A0A0"},
		"previewUrl": "", "sortOrder": 1,
	})

	ctx := context.Background()
	doc, err := repo.GetTheme(ctx, "theme_dark")
	if err != nil {
		t.Fatalf("GetTheme failed: %v", err)
	}
	if doc.Name != "Dark" {
		t.Errorf("expected name Dark, got %s", doc.Name)
	}
	if doc.Colors.Primary != "#4A90D9" {
		t.Errorf("expected primary color #4A90D9, got %s", doc.Colors.Primary)
	}
}
```

- [ ] **Step 2: Run tests (requires local MongoDB)**

Run: `cd api && go test ./internal/repository/ -run TestGetFeatureAbout -v -count=1`
Expected: PASS (if MongoDB is running locally)

- [ ] **Step 3: Commit**

```bash
git add api/internal/repository/content_repo_test.go
git commit -m "test(content-db): add integration tests for content repository"
```

---

### Task 9: Update Content Init-Indexes Script

**Files:**
- Create: `api/scripts/init-content-indexes.sh`

- [ ] **Step 1: Create the content indexes script**

```bash
#!/usr/bin/env bash
# Create MongoDB indexes for regal-recovery-content database
set -euo pipefail

echo "Creating indexes in database: regal-recovery-content"

docker compose exec -T mongodb mongosh regal-recovery-content --eval '
db.feature_abouts.createIndex({ slug: 1 }, { unique: true });
db.feature_abouts.createIndex({ category: 1, sortOrder: 1 });
db.feature_abouts.createIndex({ status: 1 });

db.affirmation_packs.createIndex({ packId: 1 }, { unique: true });
db.affirmation_packs.createIndex({ tier: 1 });
db.affirmation_packs.createIndex({ status: 1 });

db.affirmations.createIndex({ affirmationId: 1 }, { unique: true });
db.affirmations.createIndex({ packId: 1, sortOrder: 1 });

db.devotional_packs.createIndex({ packId: 1 }, { unique: true });
db.devotional_packs.createIndex({ tier: 1 });
db.devotional_packs.createIndex({ status: 1 });

db.devotionals.createIndex({ devotionalId: 1 }, { unique: true });
db.devotionals.createIndex({ packId: 1, day: 1 }, { unique: true });

db.journal_prompts.createIndex({ promptId: 1 }, { unique: true });
db.journal_prompts.createIndex({ category: 1, sortOrder: 1 });
db.journal_prompts.createIndex({ tags: 1 });

db.glossary_terms.createIndex({ termId: 1 }, { unique: true });
db.glossary_terms.createIndex({ term: 1 }, { unique: true });

db.evening_review_questions.createIndex({ questionId: 1 }, { unique: true });
db.evening_review_questions.createIndex({ dimension: 1, sortOrder: 1 });

db.acting_in_behaviors.createIndex({ behaviorId: 1 }, { unique: true });

db.needs.createIndex({ needId: 1 }, { unique: true });

db.sobriety_reset_messages.createIndex({ messageId: 1 }, { unique: true });

db.themes.createIndex({ themeId: 1 }, { unique: true });
db.themes.createIndex({ tier: 1 });
db.themes.createIndex({ status: 1 });

print("All content indexes created successfully");
'

echo "Content indexes created successfully"
```

- [ ] **Step 2: Make it executable**

Run: `chmod +x api/scripts/init-content-indexes.sh`

- [ ] **Step 3: Commit**

```bash
git add api/scripts/init-content-indexes.sh
git commit -m "feat(content-db): add content database index initialization script"
```
