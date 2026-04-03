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

func setupContentTest(t *testing.T) (*repository.ContentRepo, *repository.ContentClient, func()) {
	t.Helper()
	client := helpers.SetupLocalMongo(t)
	contentClient := repository.NewContentClient(client, "regal-recovery-content-test")

	ctx := context.Background()
	if err := contentClient.EnsureContentIndexes(ctx); err != nil {
		t.Fatalf("failed to create indexes: %v", err)
	}

	repo := repository.NewContentRepo(contentClient)

	cleanup := func() {
		db := client.Database("regal-recovery-content-test")
		collections, _ := db.ListCollectionNames(ctx, bson.M{})
		for _, coll := range collections {
			db.Collection(coll).Drop(ctx)
		}
	}

	return repo, contentClient, cleanup
}

func seedFeatureAbout(t *testing.T, cc *repository.ContentClient, slug, category string, sortOrder int) {
	t.Helper()
	now := time.Now().UTC()
	_, err := cc.Collection("feature_abouts").InsertOne(context.Background(), bson.M{
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
	repo, cc, cleanup := setupContentTest(t)
	defer cleanup()

	seedFeatureAbout(t, cc, "faster-scale", "activity", 1)

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
	repo, cc, cleanup := setupContentTest(t)
	defer cleanup()

	seedFeatureAbout(t, cc, "faster-scale", "activity", 1)
	seedFeatureAbout(t, cc, "3circles", "tool", 1)
	seedFeatureAbout(t, cc, "urge-logging", "activity", 2)

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
	repo, cc, cleanup := setupContentTest(t)
	defer cleanup()

	now := time.Now().UTC()
	cc.Collection("glossary_terms").InsertOne(context.Background(), bson.M{
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
	repo, cc, cleanup := setupContentTest(t)
	defer cleanup()

	now := time.Now().UTC()
	cc.Collection("acting_in_behaviors").InsertMany(context.Background(), []interface{}{
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
	repo, cc, cleanup := setupContentTest(t)
	defer cleanup()

	now := time.Now().UTC()
	cc.Collection("themes").InsertOne(context.Background(), bson.M{
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
