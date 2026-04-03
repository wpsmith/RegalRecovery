// internal/repository/content_resolver_test.go
package repository

import (
	"testing"
)

func TestBuildFallbackChain(t *testing.T) {
	r := &ContentResolver{baseDBName: "regal-recovery-content"}

	tests := []struct {
		locale   string
		expected []string
	}{
		{
			locale:   "es-ES",
			expected: []string{"regal-recovery-content-es-ES", "regal-recovery-content-es", "regal-recovery-content"},
		},
		{
			locale:   "es",
			expected: []string{"regal-recovery-content-es", "regal-recovery-content"},
		},
		{
			locale:   "fr-FR",
			expected: []string{"regal-recovery-content-fr-FR", "regal-recovery-content-fr", "regal-recovery-content"},
		},
		{
			locale:   "en",
			expected: []string{"regal-recovery-content"},
		},
		{
			locale:   "",
			expected: []string{"regal-recovery-content"},
		},
		{
			locale:   "pt-BR",
			expected: []string{"regal-recovery-content-pt-BR", "regal-recovery-content-pt", "regal-recovery-content"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.locale, func(t *testing.T) {
			chain := r.buildFallbackChain(tt.locale)
			if len(chain) != len(tt.expected) {
				t.Fatalf("expected %d candidates, got %d: %v", len(tt.expected), len(chain), chain)
			}
			for i, name := range chain {
				if name != tt.expected[i] {
					t.Errorf("chain[%d]: expected %s, got %s", i, tt.expected[i], name)
				}
			}
		})
	}
}
