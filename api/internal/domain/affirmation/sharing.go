// internal/domain/affirmation/sharing.go
package affirmation

import "fmt"

// GenerateShareableText creates plain text shareable content for an affirmation.
// Shared content includes statement, scripture reference, and Regal Recovery attribution.
// Expansion and prayer are intentionally excluded from sharing.
func GenerateShareableText(aff *Affirmation) string {
	text := fmt.Sprintf("\"%s\"\n\n— %s\n\nRegal Recovery", aff.Statement, aff.ScriptureRef)
	return text
}

// GenerateShareableContent generates the full shareable content based on format.
func GenerateShareableContent(aff *Affirmation, format string) (*ShareableContent, error) {
	switch format {
	case "text":
		return &ShareableContent{
			Text: GenerateShareableText(aff),
		}, nil
	case "styledGraphic":
		// Styled graphic generation would be handled by a separate image service.
		// For now, return text with a placeholder for the graphic URL.
		return &ShareableContent{
			Text: GenerateShareableText(aff),
			// GraphicURL would be populated by the image rendering service
		}, nil
	default:
		return nil, fmt.Errorf("invalid share format: %s", format)
	}
}
