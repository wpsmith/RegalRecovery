// internal/domain/threecircles/language_test.go
package threecircles

import (
	"errors"
	"testing"
)

func TestValidateTraumaInformedLanguage_EmptyString(t *testing.T) {
	t.Parallel()

	err := ValidateTraumaInformedLanguage("")
	if err != nil {
		t.Errorf("expected no error for empty string, got %v", err)
	}
}

func TestValidateTraumaInformedLanguage_ValidText(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		text string
	}{
		{
			name: "positive affirmation",
			text: "You're making progress in your recovery journey.",
		},
		{
			name: "neutral observation",
			text: "You contacted your middle circle yesterday.",
		},
		{
			name: "supportive message",
			text: "Consider reaching out to your sponsor for support.",
		},
		{
			name: "compassionate framing",
			text: "This is a challenging situation, and you're taking steps to address it.",
		},
		{
			name: "contains 'cleaned' but not 'clean'",
			text: "You cleaned your workspace today.",
		},
		{
			name: "contains 'weakness' as substring in 'meekness'",
			text: "Cultivate meekness and humility in your recovery.",
		},
		{
			name: "contains 'should' as substring in 'shoulder'",
			text: "Your sponsor can help shoulder the burden with you.",
		},
		{
			name: "contains 'addict' as substring in 'addicted'",
			text: "You have been experiencing addictive patterns.",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			err := ValidateTraumaInformedLanguage(tt.text)
			if err != nil {
				t.Errorf("expected no error for valid text '%s', got %v", tt.text, err)
			}
		})
	}
}

func TestValidateTraumaInformedLanguage_ForbiddenWords(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		text string
	}{
		{
			name: "failure at start",
			text: "failure is not an option here",
		},
		{
			name: "failures in middle",
			text: "Your past failures define you.",
		},
		{
			name: "failed at end",
			text: "You have failed",
		},
		{
			name: "clean as standalone",
			text: "Stay clean.",
		},
		{
			name: "dirty in sentence",
			text: "You were dirty when you did that.",
		},
		{
			name: "weakness at start",
			text: "Weakness is showing in your behavior.",
		},
		{
			name: "weaknesses in middle",
			text: "We need to address your weaknesses today.",
		},
		{
			name: "weak at end",
			text: "You are too weak",
		},
		{
			name: "addict as standalone",
			text: "You're an addict.",
		},
		{
			name: "addicts plural",
			text: "Many addicts struggle with this.",
		},
		{
			name: "should in sentence",
			text: "You should do better next time.",
		},
		{
			name: "must at start",
			text: "Must avoid this behavior at all costs.",
		},
		{
			name: "clean with punctuation",
			text: "Stay clean, okay?",
		},
		{
			name: "failure with period",
			text: "This is a failure.",
		},
		{
			name: "addict with exclamation",
			text: "You're an addict!",
		},
		{
			name: "should in question",
			text: "Should you have done that?",
		},
		{
			name: "must with quotes",
			text: "You 'must' change now.",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			err := ValidateTraumaInformedLanguage(tt.text)
			if err == nil {
				t.Errorf("expected error for forbidden text '%s', got nil", tt.text)
			}
			if !errors.Is(err, ErrTraumaInformedLanguageViolation) {
				t.Errorf("expected ErrTraumaInformedLanguageViolation, got %v", err)
			}
		})
	}
}

func TestValidateTraumaInformedLanguage_CaseInsensitive(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		text string
	}{
		{
			name: "FAILURE uppercase",
			text: "This is a FAILURE",
		},
		{
			name: "Failure title case",
			text: "Failure is not acceptable",
		},
		{
			name: "Clean mixed case",
			text: "You must stay Clean",
		},
		{
			name: "ADDICT all caps",
			text: "Stop being an ADDICT",
		},
		{
			name: "MuSt mixed case",
			text: "You MuSt change now",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			err := ValidateTraumaInformedLanguage(tt.text)
			if err == nil {
				t.Errorf("expected error for forbidden text '%s', got nil", tt.text)
			}
			if !errors.Is(err, ErrTraumaInformedLanguageViolation) {
				t.Errorf("expected ErrTraumaInformedLanguageViolation, got %v", err)
			}
		})
	}
}

func TestValidateTraumaInformedLanguage_EdgeCases(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		text      string
		expectErr bool
	}{
		{
			name:      "word at start of text",
			text:      "Clean your room",
			expectErr: true,
		},
		{
			name:      "word at end of text",
			text:      "This is clean",
			expectErr: true,
		},
		{
			name:      "word with newline",
			text:      "You failed\nto do this",
			expectErr: true,
		},
		{
			name:      "word with tab",
			text:      "This is a\tfailure",
			expectErr: true,
		},
		{
			name:      "multiple forbidden words",
			text:      "You failed because you're weak and dirty",
			expectErr: true,
		},
		{
			name:      "word in parentheses",
			text:      "This is a (failure) in judgment",
			expectErr: true,
		},
		{
			name:      "word in quotes",
			text:      "He called it a \"failure\"",
			expectErr: true,
		},
		{
			name:      "word with hyphen after",
			text:      "This clean-up effort",
			expectErr: true,
		},
		{
			name:      "word with hyphen before",
			text:      "A pre-failure analysis",
			expectErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			err := ValidateTraumaInformedLanguage(tt.text)
			if tt.expectErr && err == nil {
				t.Errorf("expected error for text '%s', got nil", tt.text)
			}
			if !tt.expectErr && err != nil {
				t.Errorf("expected no error for text '%s', got %v", tt.text, err)
			}
		})
	}
}

func TestValidateTraumaInformedLanguage_SubstringFalsePositives(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		text string
	}{
		{
			name: "cleaned contains clean",
			text: "You cleaned the house today",
		},
		{
			name: "clearly contains clean",
			text: "This is clearly a good choice",
		},
		{
			name: "nuclear contains clean",
			text: "This is a nuclear family structure",
		},
		{
			name: "addicted contains addict",
			text: "You have been experiencing addictive behaviors",
		},
		{
			name: "predicted contains addict",
			text: "This was predicted by the research",
		},
		{
			name: "shoulder contains should",
			text: "Your sponsor can shoulder this burden",
		},
		{
			name: "musty contains must",
			text: "The room smells musty",
		},
		{
			name: "mustard contains must",
			text: "Would you like mustard on that?",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			err := ValidateTraumaInformedLanguage(tt.text)
			if err != nil {
				t.Errorf("expected no error for text '%s' (should not match substring), got %v", tt.text, err)
			}
		})
	}
}

func TestSuggestAlternative(t *testing.T) {
	t.Parallel()

	tests := []struct {
		phrase   string
		expected string
	}{
		{
			phrase:   "failure",
			expected: "setback",
		},
		{
			phrase:   "failed",
			expected: "experienced a setback",
		},
		{
			phrase:   "clean",
			expected: "in recovery",
		},
		{
			phrase:   "dirty",
			expected: "struggling",
		},
		{
			phrase:   "weakness",
			expected: "challenge",
		},
		{
			phrase:   "addict",
			expected: "person in recovery",
		},
		{
			phrase:   "should",
			expected: "could consider",
		},
		{
			phrase:   "must",
			expected: "it may help to",
		},
		{
			phrase:   "unknown",
			expected: "unknown",
		},
		{
			phrase:   "FAILURE",
			expected: "setback",
		},
		{
			phrase:   "Failure",
			expected: "setback",
		},
	}

	for _, tt := range tests {
		t.Run(tt.phrase, func(t *testing.T) {
			t.Parallel()
			result := SuggestAlternative(tt.phrase)
			if result != tt.expected {
				t.Errorf("expected '%s', got '%s'", tt.expected, result)
			}
		})
	}
}

func TestContainsWholeWord(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name     string
		text     string
		word     string
		expected bool
	}{
		{
			name:     "word at start",
			text:     "clean room",
			word:     "clean",
			expected: true,
		},
		{
			name:     "word at end",
			text:     "room is clean",
			word:     "clean",
			expected: true,
		},
		{
			name:     "word in middle",
			text:     "the clean room",
			word:     "clean",
			expected: true,
		},
		{
			name:     "word standalone",
			text:     "clean",
			word:     "clean",
			expected: true,
		},
		{
			name:     "word with period",
			text:     "room is clean.",
			word:     "clean",
			expected: true,
		},
		{
			name:     "word with comma",
			text:     "clean, tidy room",
			word:     "clean",
			expected: true,
		},
		{
			name:     "word with exclamation",
			text:     "stay clean!",
			word:     "clean",
			expected: true,
		},
		{
			name:     "word as substring",
			text:     "cleaned",
			word:     "clean",
			expected: false,
		},
		{
			name:     "word as prefix",
			text:     "cleaner",
			word:     "clean",
			expected: false,
		},
		{
			name:     "word embedded",
			text:     "unclean",
			word:     "clean",
			expected: false,
		},
		{
			name:     "word not present",
			text:     "room is tidy",
			word:     "clean",
			expected: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			result := containsWholeWord(tt.text, tt.word)
			if result != tt.expected {
				t.Errorf("containsWholeWord('%s', '%s') = %v, expected %v", tt.text, tt.word, result, tt.expected)
			}
		})
	}
}
