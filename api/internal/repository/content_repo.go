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

// publishedFilter returns a filter that only matches published content.
func publishedFilter() bson.M {
	return bson.M{"status": "published"}
}

// publishedFilterWith returns a filter that includes status=published and additional conditions.
func publishedFilterWith(additional bson.M) bson.M {
	filter := publishedFilter()
	for k, v := range additional {
		filter[k] = v
	}
	return filter
}

// Feature Abouts

// GetFeatureAbout retrieves a feature about by slug.
func (r *ContentRepo) GetFeatureAbout(ctx context.Context, slug string) (*FeatureAbout, error) {
	var feature FeatureAbout
	err := r.client.Collection("feature_abouts").FindOne(ctx, publishedFilterWith(bson.M{"slug": slug})).Decode(&feature)
	if err != nil {
		return nil, fmt.Errorf("getting feature about %s: %w", slug, err)
	}
	return &feature, nil
}

// ListFeatureAbouts retrieves all published feature abouts.
func (r *ContentRepo) ListFeatureAbouts(ctx context.Context) ([]FeatureAbout, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("feature_abouts").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing feature abouts: %w", err)
	}

	var features []FeatureAbout
	if err := cursor.All(ctx, &features); err != nil {
		return nil, fmt.Errorf("decoding feature abouts: %w", err)
	}
	return features, nil
}

// ListFeatureAboutsByCategory retrieves all published feature abouts in a category.
func (r *ContentRepo) ListFeatureAboutsByCategory(ctx context.Context, category string) ([]FeatureAbout, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("feature_abouts").Find(ctx, publishedFilterWith(bson.M{"category": category}), opts)
	if err != nil {
		return nil, fmt.Errorf("listing feature abouts for category %s: %w", category, err)
	}

	var features []FeatureAbout
	if err := cursor.All(ctx, &features); err != nil {
		return nil, fmt.Errorf("decoding feature abouts: %w", err)
	}
	return features, nil
}

// Affirmation Packs

// GetAffirmationPack retrieves an affirmation pack by ID.
func (r *ContentRepo) GetAffirmationPack(ctx context.Context, packID string) (*ContentAffirmationPack, error) {
	var pack ContentAffirmationPack
	err := r.client.Collection("affirmation_packs").FindOne(ctx, publishedFilterWith(bson.M{"packId": packID})).Decode(&pack)
	if err != nil {
		return nil, fmt.Errorf("getting affirmation pack %s: %w", packID, err)
	}
	return &pack, nil
}

// ListAffirmationPacks retrieves all published affirmation packs.
func (r *ContentRepo) ListAffirmationPacks(ctx context.Context) ([]ContentAffirmationPack, error) {
	opts := options.Find().SetSort(bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("affirmation_packs").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing affirmation packs: %w", err)
	}

	var packs []ContentAffirmationPack
	if err := cursor.All(ctx, &packs); err != nil {
		return nil, fmt.Errorf("decoding affirmation packs: %w", err)
	}
	return packs, nil
}

// ListAffirmationsInPack retrieves all published affirmations within a pack.
func (r *ContentRepo) ListAffirmationsInPack(ctx context.Context, packID string) ([]ContentAffirmation, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("affirmations").Find(ctx, publishedFilterWith(bson.M{"packId": packID}), opts)
	if err != nil {
		return nil, fmt.Errorf("listing affirmations for pack %s: %w", packID, err)
	}

	var affirmations []ContentAffirmation
	if err := cursor.All(ctx, &affirmations); err != nil {
		return nil, fmt.Errorf("decoding affirmations: %w", err)
	}
	return affirmations, nil
}

// Devotional Packs

// GetDevotionalPack retrieves a devotional pack by ID.
func (r *ContentRepo) GetDevotionalPack(ctx context.Context, packID string) (*DevotionalPack, error) {
	var pack DevotionalPack
	err := r.client.Collection("devotional_packs").FindOne(ctx, publishedFilterWith(bson.M{"packId": packID})).Decode(&pack)
	if err != nil {
		return nil, fmt.Errorf("getting devotional pack %s: %w", packID, err)
	}
	return &pack, nil
}

// ListDevotionalPacks retrieves all published devotional packs.
func (r *ContentRepo) ListDevotionalPacks(ctx context.Context) ([]DevotionalPack, error) {
	opts := options.Find().SetSort(bson.D{{Key: "category", Value: 1}, {Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("devotional_packs").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing devotional packs: %w", err)
	}

	var packs []DevotionalPack
	if err := cursor.All(ctx, &packs); err != nil {
		return nil, fmt.Errorf("decoding devotional packs: %w", err)
	}
	return packs, nil
}

// GetDevotional retrieves a specific devotional by pack ID and day number.
func (r *ContentRepo) GetDevotional(ctx context.Context, packID string, day int) (*ContentDevotional, error) {
	var devotional ContentDevotional
	err := r.client.Collection("devotionals").FindOne(ctx, publishedFilterWith(bson.M{"packId": packID, "day": day})).Decode(&devotional)
	if err != nil {
		return nil, fmt.Errorf("getting devotional day %d in pack %s: %w", day, packID, err)
	}
	return &devotional, nil
}

// ListDevotionalsInPack retrieves all published devotionals in a pack.
func (r *ContentRepo) ListDevotionalsInPack(ctx context.Context, packID string) ([]ContentDevotional, error) {
	opts := options.Find().SetSort(bson.D{{Key: "day", Value: 1}})
	cursor, err := r.client.Collection("devotionals").Find(ctx, publishedFilterWith(bson.M{"packId": packID}), opts)
	if err != nil {
		return nil, fmt.Errorf("listing devotionals for pack %s: %w", packID, err)
	}

	var devotionals []ContentDevotional
	if err := cursor.All(ctx, &devotionals); err != nil {
		return nil, fmt.Errorf("decoding devotionals: %w", err)
	}
	return devotionals, nil
}

// Journal Prompts

// GetJournalPrompt retrieves a specific journal prompt by ID.
func (r *ContentRepo) GetJournalPrompt(ctx context.Context, promptID string) (*JournalPrompt, error) {
	var prompt JournalPrompt
	err := r.client.Collection("journal_prompts").FindOne(ctx, publishedFilterWith(bson.M{"promptId": promptID})).Decode(&prompt)
	if err != nil {
		return nil, fmt.Errorf("getting journal prompt %s: %w", promptID, err)
	}
	return &prompt, nil
}

// ListJournalPrompts retrieves all published journal prompts, optionally filtered by category.
func (r *ContentRepo) ListJournalPrompts(ctx context.Context, category string) ([]JournalPrompt, error) {
	filter := publishedFilter()
	if category != "" {
		filter["category"] = category
	}
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("journal_prompts").Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing journal prompts: %w", err)
	}

	var prompts []JournalPrompt
	if err := cursor.All(ctx, &prompts); err != nil {
		return nil, fmt.Errorf("decoding journal prompts: %w", err)
	}
	return prompts, nil
}

// ListJournalPromptsByTag retrieves all published journal prompts with a specific tag.
func (r *ContentRepo) ListJournalPromptsByTag(ctx context.Context, tag string) ([]JournalPrompt, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("journal_prompts").Find(ctx, publishedFilterWith(bson.M{"tags": tag}), opts)
	if err != nil {
		return nil, fmt.Errorf("listing journal prompts by tag %s: %w", tag, err)
	}

	var prompts []JournalPrompt
	if err := cursor.All(ctx, &prompts); err != nil {
		return nil, fmt.Errorf("decoding journal prompts: %w", err)
	}
	return prompts, nil
}

// Glossary

// ListGlossaryTerms retrieves all published glossary terms.
func (r *ContentRepo) ListGlossaryTerms(ctx context.Context) ([]GlossaryTerm, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("glossary").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing glossary terms: %w", err)
	}

	var terms []GlossaryTerm
	if err := cursor.All(ctx, &terms); err != nil {
		return nil, fmt.Errorf("decoding glossary terms: %w", err)
	}
	return terms, nil
}

// Evening Review

// ListEveningReviewQuestions retrieves all published evening review questions, optionally filtered by dimension.
func (r *ContentRepo) ListEveningReviewQuestions(ctx context.Context, dimension string) ([]EveningReviewQuestion, error) {
	filter := publishedFilter()
	if dimension != "" {
		filter["dimension"] = dimension
	}
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("evening_review_questions").Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing evening review questions: %w", err)
	}

	var questions []EveningReviewQuestion
	if err := cursor.All(ctx, &questions); err != nil {
		return nil, fmt.Errorf("decoding evening review questions: %w", err)
	}
	return questions, nil
}

// Acting-In

// ListActingInBehaviors retrieves all published acting-in behaviors.
func (r *ContentRepo) ListActingInBehaviors(ctx context.Context) ([]ActingInBehavior, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("acting_in_behaviors").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing acting-in behaviors: %w", err)
	}

	var behaviors []ActingInBehavior
	if err := cursor.All(ctx, &behaviors); err != nil {
		return nil, fmt.Errorf("decoding acting-in behaviors: %w", err)
	}
	return behaviors, nil
}

// Needs

// ListNeeds retrieves all published needs.
func (r *ContentRepo) ListNeeds(ctx context.Context) ([]Need, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("needs").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing needs: %w", err)
	}

	var needs []Need
	if err := cursor.All(ctx, &needs); err != nil {
		return nil, fmt.Errorf("decoding needs: %w", err)
	}
	return needs, nil
}

// Sobriety Reset

// ListSobrietyResetMessages retrieves all published sobriety reset messages.
func (r *ContentRepo) ListSobrietyResetMessages(ctx context.Context) ([]SobrietyResetMessage, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("sobriety_reset_messages").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing sobriety reset messages: %w", err)
	}

	var messages []SobrietyResetMessage
	if err := cursor.All(ctx, &messages); err != nil {
		return nil, fmt.Errorf("decoding sobriety reset messages: %w", err)
	}
	return messages, nil
}

// GetRandomSobrietyResetMessage retrieves a random published sobriety reset message.
// Uses time-based selection for pseudo-randomness.
func (r *ContentRepo) GetRandomSobrietyResetMessage(ctx context.Context) (*SobrietyResetMessage, error) {
	messages, err := r.ListSobrietyResetMessages(ctx)
	if err != nil {
		return nil, err
	}
	if len(messages) == 0 {
		return nil, nil
	}
	// Use a simple time-based selection for randomness.
	index := int(NowISO8601()[17]-'0') % len(messages)
	return &messages[index], nil
}

// Themes

// ListThemes retrieves all published themes.
func (r *ContentRepo) ListThemes(ctx context.Context) ([]Theme, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("themes").Find(ctx, publishedFilter(), opts)
	if err != nil {
		return nil, fmt.Errorf("listing themes: %w", err)
	}

	var themes []Theme
	if err := cursor.All(ctx, &themes); err != nil {
		return nil, fmt.Errorf("decoding themes: %w", err)
	}
	return themes, nil
}

// ListThemesByTier retrieves all published themes in a specific tier.
func (r *ContentRepo) ListThemesByTier(ctx context.Context, tier string) ([]Theme, error) {
	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.client.Collection("themes").Find(ctx, publishedFilterWith(bson.M{"tier": tier}), opts)
	if err != nil {
		return nil, fmt.Errorf("listing themes for tier %s: %w", tier, err)
	}

	var themes []Theme
	if err := cursor.All(ctx, &themes); err != nil {
		return nil, fmt.Errorf("decoding themes: %w", err)
	}
	return themes, nil
}

// GetTheme retrieves a theme by ID.
func (r *ContentRepo) GetTheme(ctx context.Context, themeID string) (*Theme, error) {
	var theme Theme
	err := r.client.Collection("themes").FindOne(ctx, publishedFilterWith(bson.M{"themeId": themeID})).Decode(&theme)
	if err != nil {
		return nil, fmt.Errorf("getting theme %s: %w", themeID, err)
	}
	return &theme, nil
}
