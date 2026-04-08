// internal/domain/mood/labels_test.go
package mood

import "testing"

func TestMood_LabelForRating_AllValues(t *testing.T) {
	tests := []struct {
		rating int
		label  string
	}{
		{1, "Crisis"},
		{2, "Struggling"},
		{3, "Okay"},
		{4, "Good"},
		{5, "Great"},
	}

	for _, tt := range tests {
		got := LabelForRating(tt.rating)
		if got != tt.label {
			t.Errorf("LabelForRating(%d) = %q, want %q", tt.rating, got, tt.label)
		}
	}
}

func TestMood_LabelForRating_InvalidRating(t *testing.T) {
	got := LabelForRating(0)
	if got != "" {
		t.Errorf("LabelForRating(0) = %q, want empty string", got)
	}
	got = LabelForRating(6)
	if got != "" {
		t.Errorf("LabelForRating(6) = %q, want empty string", got)
	}
}

func TestMood_ValidEmotionLabels_ContainsAll15(t *testing.T) {
	expectedLabels := []string{
		"Peaceful", "Grateful", "Hopeful", "Confident", "Connected",
		"Anxious", "Lonely", "Angry", "Ashamed", "Overwhelmed",
		"Sad", "Numb", "Restless", "Afraid", "Frustrated",
	}

	if len(ValidEmotionLabels) != 15 {
		t.Errorf("expected 15 emotion labels, got %d", len(ValidEmotionLabels))
	}

	for _, label := range expectedLabels {
		if !ValidEmotionLabels[label] {
			t.Errorf("expected '%s' to be a valid emotion label", label)
		}
	}
}

func TestMood_ValidEmotionLabels_InvalidNotPresent(t *testing.T) {
	invalidLabels := []string{"Happy", "Excited", "Bored", "Fine", "Bad"}
	for _, label := range invalidLabels {
		if ValidEmotionLabels[label] {
			t.Errorf("expected '%s' to NOT be a valid emotion label", label)
		}
	}
}

func TestMood_ValidSources_ContainsAll(t *testing.T) {
	expectedSources := []string{"direct", "widget", "post-activity", "notification"}
	for _, src := range expectedSources {
		if !ValidSources[src] {
			t.Errorf("expected '%s' to be a valid source", src)
		}
	}
}

func TestMood_ColorCode_AllBands(t *testing.T) {
	tests := []struct {
		avg       float64
		colorCode string
	}{
		{5.0, "green"},
		{4.5, "green"},
		{4.0, "green"},
		{3.9, "yellow"},
		{3.5, "yellow"},
		{3.0, "yellow"},
		{2.9, "orange"},
		{2.5, "orange"},
		{2.0, "orange"},
		{1.9, "red"},
		{1.5, "red"},
		{1.0, "red"},
		{0.0, "gray"},
		{-1.0, "gray"},
	}

	for _, tt := range tests {
		got := ColorCode(tt.avg)
		if got != tt.colorCode {
			t.Errorf("ColorCode(%.1f) = %q, want %q", tt.avg, got, tt.colorCode)
		}
	}
}

func TestMood_AllEmotionLabels_Returns15(t *testing.T) {
	labels := AllEmotionLabels()
	if len(labels) != 15 {
		t.Errorf("expected 15 labels from AllEmotionLabels(), got %d", len(labels))
	}
}
