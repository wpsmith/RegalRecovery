// internal/domain/threecircles/language.go
package threecircles

import (
	"errors"
	"strings"
)

// ErrTraumaInformedLanguageViolation is returned when text contains forbidden trauma-informed language.
var ErrTraumaInformedLanguageViolation = errors.New("text contains non-trauma-informed language")

// Forbidden words that violate trauma-informed language principles.
// These words are judgmental, shaming, or imply moral failure.
var forbiddenWords = []string{
	"failure",
	"failures",
	"failed",
	"clean",
	"dirty",
	"weakness",
	"weaknesses",
	"weak",
	"addict",
	"addicts",
	"should",
	"must",
}

// ValidateTraumaInformedLanguage checks if the given text contains forbidden words.
// This validation is applied to ALL system-generated messages to ensure compassionate communication.
// Returns ErrTraumaInformedLanguageViolation if text contains forbidden words.
func ValidateTraumaInformedLanguage(text string) error {
	if text == "" {
		return nil
	}

	lowerText := strings.ToLower(text)

	for _, word := range forbiddenWords {
		// Match whole words only to avoid false positives.
		// e.g., "cleaned" should not match "clean", but "clean slate" should.
		if containsWholeWord(lowerText, word) {
			return ErrTraumaInformedLanguageViolation
		}
	}

	return nil
}

// containsWholeWord checks if a word appears as a whole word in the text.
// This prevents false positives like "cleaned" matching "clean".
func containsWholeWord(text, word string) bool {
	// Add spaces around text to handle edge cases.
	paddedText := " " + text + " "
	paddedWord := " " + word + " "

	// Check if the word appears as a whole word.
	if strings.Contains(paddedText, paddedWord) {
		return true
	}

	// Check for punctuation boundaries.
	// e.g., "clean." or "clean," or "clean!" should match "clean"
	punctuation := []string{".", ",", "!", "?", ";", ":", "'", "\"", "(", ")", "[", "]", "{", "}", "-", "\n", "\t", "\r"}
	for _, p := range punctuation {
		if strings.Contains(paddedText, " "+word+p) || strings.Contains(paddedText, p+word+" ") {
			return true
		}
		// Check for punctuation on both sides e.g., "(clean)" or "[clean]"
		for _, p2 := range punctuation {
			if strings.Contains(paddedText, p+word+p2) {
				return true
			}
		}
	}

	return false
}

// SuggestAlternative provides trauma-informed alternatives for common phrases.
// This is a helper for developers writing system messages.
func SuggestAlternative(phrase string) string {
	alternatives := map[string]string{
		"failure":   "setback",
		"failed":    "experienced a setback",
		"clean":     "in recovery",
		"dirty":     "struggling",
		"weakness":  "challenge",
		"addict":    "person in recovery",
		"should":    "could consider",
		"must":      "it may help to",
	}

	lower := strings.ToLower(phrase)
	if alt, ok := alternatives[lower]; ok {
		return alt
	}

	return phrase
}
