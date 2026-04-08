// test/unit/affirmation_sharing_test.go
package unit

import (
	"strings"
	"testing"

	"github.com/regalrecovery/api/internal/domain/affirmation"
)

// TestAffirmation_AFF_IN_AC10_Sharing_TextFormat verifies text share includes
// statement, scripture, and attribution.
//
// Acceptance Criterion (AFF-IN-AC10): Share includes statement, scripture, and watermark.
func TestAffirmation_AFF_IN_AC10_Sharing_TextFormat(t *testing.T) {
	aff := &affirmation.Affirmation{
		Statement:    "I am fearfully and wonderfully made.",
		ScriptureRef: "Psalm 139:14",
	}

	text := affirmation.GenerateShareableText(aff)

	if !strings.Contains(text, aff.Statement) {
		t.Error("expected shareable text to contain statement")
	}
	if !strings.Contains(text, aff.ScriptureRef) {
		t.Error("expected shareable text to contain scripture reference")
	}
	if !strings.Contains(text, "Regal Recovery") {
		t.Error("expected shareable text to contain Regal Recovery attribution")
	}
}

// TestAffirmation_AFF_IN_AC10_Sharing_NoExpansionOrPrayer verifies expansion and prayer
// are excluded from shared content.
func TestAffirmation_AFF_IN_AC10_Sharing_NoExpansionOrPrayer(t *testing.T) {
	expansion := "This is the expansion text that should not be shared."
	prayer := "This is the prayer text that should not be shared."
	aff := &affirmation.Affirmation{
		Statement:    "I am fearfully and wonderfully made.",
		ScriptureRef: "Psalm 139:14",
		Expansion:    &expansion,
		Prayer:       &prayer,
	}

	text := affirmation.GenerateShareableText(aff)

	if strings.Contains(text, expansion) {
		t.Error("expected shareable text to NOT contain expansion")
	}
	if strings.Contains(text, prayer) {
		t.Error("expected shareable text to NOT contain prayer")
	}
}

// TestAffirmation_AFF_IN_AC4_DashboardWidget_Truncation verifies widget truncation.
//
// Acceptance Criterion (AFF-IN-AC4): Dashboard widget truncates to 100 chars.
func TestAffirmation_AFF_IN_AC4_DashboardWidget_Truncation(t *testing.T) {
	longStatement := strings.Repeat("a", 300)
	aff := &affirmation.Affirmation{
		AffirmationID: "aff_001",
		Statement:     longStatement,
		Category:      affirmation.CategoryIdentity,
	}
	progress := &affirmation.AffirmationProgress{TotalRead: 100, TotalFavorites: 5}

	widget := affirmation.GetWidgetData(aff, progress, true)

	if len(widget.TodayStatement) > 100 {
		t.Errorf("expected widget statement <= 100 chars, got %d", len(widget.TodayStatement))
	}
	if !strings.HasSuffix(widget.TodayStatement, "...") {
		t.Error("expected truncated statement to end with ...")
	}
}

// TestAffirmation_AFF_IN_AC4_DashboardWidget_HasRead verifies widget hasReadToday.
func TestAffirmation_AFF_IN_AC4_DashboardWidget_HasRead(t *testing.T) {
	aff := &affirmation.Affirmation{
		AffirmationID: "aff_001",
		Statement:     "Short statement",
		Category:      affirmation.CategoryIdentity,
	}
	progress := &affirmation.AffirmationProgress{TotalRead: 142, TotalFavorites: 12}

	widget := affirmation.GetWidgetData(aff, progress, true)

	if !widget.HasReadToday {
		t.Error("expected hasReadToday to be true")
	}
	if widget.TotalRead != 142 {
		t.Errorf("expected totalRead 142, got %d", widget.TotalRead)
	}
}
