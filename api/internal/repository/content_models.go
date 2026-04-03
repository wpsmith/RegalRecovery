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
	Category           string `bson:"category"`
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
	Tier             string `bson:"tier"`
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
	Tier            string `bson:"tier"`
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
	Category  string   `bson:"category"`
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
	Dimension  string `bson:"dimension"`
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
	Tier        string      `bson:"tier"`
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
