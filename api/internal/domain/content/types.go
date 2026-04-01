// internal/domain/content/types.go
package content

import "time"

// AffirmationPack represents a collection of affirmations.
type AffirmationPack struct {
	PackID       string
	Title        string
	Description  string
	Category     string
	Affirmations []Affirmation
	CreatedAt    time.Time
	ModifiedAt   time.Time
}

// Affirmation represents a single affirmation.
type Affirmation struct {
	AffirmationID string
	Text          string
	Scripture     string
	Category      string
	Order         int
}

// Devotional represents a daily devotional entry.
type Devotional struct {
	DevotionalID string
	Day          int
	Title        string
	Scripture    string
	Passage      string
	Reflection   string
	Prayer       string
	CreatedAt    time.Time
	ModifiedAt   time.Time
}

// AffirmationPacksResponse is the response envelope for affirmation packs list.
type AffirmationPacksResponse struct {
	Data  []AffirmationPack      `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// AffirmationPackResponse is the response envelope for a single affirmation pack.
type AffirmationPackResponse struct {
	Data  AffirmationPack        `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// DevotionalResponse is the response envelope for devotional data.
type DevotionalResponse struct {
	Data  Devotional             `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// Prompt represents a journal prompt for recovery reflection.
type Prompt struct {
	PromptID  string
	Text      string
	Category  string // "daily", "sobriety", "emotional", "relationships", "spiritual", "shame", "triggers", "amends", "gratitude", "deep"
	Tags      []string // framework tags: "FASTER", "3 Circles", "12-Step", "FANOS/FITNAP", "PCI", "Arousal Template"
	Order     int
}

// PromptsResponse is the response envelope for prompts list.
type PromptsResponse struct {
	Data  []Prompt               `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// PromptResponse is the response envelope for a single prompt.
type PromptResponse struct {
	Data  Prompt                 `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// TodaysAffirmationResponse is the response envelope for today's affirmation.
type TodaysAffirmationResponse struct {
	Data  Affirmation            `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}
