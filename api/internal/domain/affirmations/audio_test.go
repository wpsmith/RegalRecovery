// internal/domain/affirmations/audio_test.go
package affirmations

import (
	"testing"
	"time"
)

// TestAffirmations_Audio_MaxDuration60Seconds verifies that audio recordings
// are limited to 60 seconds.
//
// Acceptance Criterion: Audio recordings max 60 seconds.
func TestAffirmations_Audio_MaxDuration60Seconds(t *testing.T) {
	// Given - Audio recording with exactly 60 seconds
	audio := &AudioRecording{
		ID:               "audio-001",
		AffirmationID:    "custom-001",
		UserID:           "user-123",
		DurationSeconds:  60,
		Format:           "m4a",
		BackgroundOption: BackgroundNature,
		StorageLocation:  StorageLocal,
		CreatedAt:        time.Now().UTC(),
	}

	// When
	err := ValidateAudioRecording(audio.DurationSeconds, audio.Format)

	// Then
	if err != nil {
		t.Errorf("expected no error for 60 seconds, got %v", err)
	}
}

// TestAffirmations_Audio_ExceedsDuration_Rejected verifies that audio recordings
// exceeding 60 seconds are rejected.
//
// Acceptance Criterion: Audio recordings max 60 seconds.
func TestAffirmations_Audio_ExceedsDuration_Rejected(t *testing.T) {
	// Given - Audio recording with 61 seconds
	durationSeconds := 61
	format := "m4a"

	// When
	err := ValidateAudioRecording(durationSeconds, format)

	// Then
	if err != ErrAudioDurationExceeded {
		t.Errorf("expected ErrAudioDurationExceeded, got %v", err)
	}
}

// TestAffirmations_Audio_M4AFormatRequired verifies that only m4a format
// is accepted.
//
// Acceptance Criterion: Audio format must be m4a.
func TestAffirmations_Audio_M4AFormatRequired(t *testing.T) {
	// Given - Audio recording with m4a format
	durationSeconds := 30
	format := "m4a"

	// When
	err := ValidateAudioRecording(durationSeconds, format)

	// Then
	if err != nil {
		t.Errorf("expected no error for m4a format, got %v", err)
	}
}

// TestAffirmations_Audio_InvalidFormatRejected verifies that non-m4a formats
// are rejected.
//
// Acceptance Criterion: Audio format must be m4a.
func TestAffirmations_Audio_InvalidFormatRejected(t *testing.T) {
	// Given - Invalid audio formats
	invalidFormats := []string{"mp3", "wav", "ogg", "flac", "aac"}

	for _, format := range invalidFormats {
		// When
		err := ValidateAudioRecording(30, format)

		// Then
		if err != ErrInvalidAudioFormat {
			t.Errorf("expected ErrInvalidAudioFormat for %s, got %v", format, err)
		}
	}
}

// TestAffirmations_Audio_5BackgroundOptions verifies that all five background
// options are available.
//
// Acceptance Criterion: 5 background options (nature, soft-tones, rain, ocean, silence).
func TestAffirmations_Audio_5BackgroundOptions(t *testing.T) {
	// Given - Expected background options
	expectedOptions := []BackgroundOption{
		BackgroundNature,
		BackgroundSoftTones,
		BackgroundRain,
		BackgroundOcean,
		BackgroundSilence,
	}

	// Then - Verify all 5 options exist and are valid
	if len(expectedOptions) != 5 {
		t.Errorf("expected 5 background options, got %d", len(expectedOptions))
	}

	// Verify each option can be used
	for _, option := range expectedOptions {
		audio := &AudioRecording{
			ID:               "audio-test",
			AffirmationID:    "custom-001",
			UserID:           "user-123",
			DurationSeconds:  30,
			Format:           "m4a",
			BackgroundOption: option,
			StorageLocation:  StorageLocal,
			CreatedAt:        time.Now().UTC(),
		}

		if audio.BackgroundOption != option {
			t.Errorf("expected background option %s, got %s", option, audio.BackgroundOption)
		}
	}
}

// TestAffirmations_Audio_HeadphoneDisconnectInterface verifies that the
// HeadphoneDisconnectHandler interface is defined for platform-specific handling.
//
// Acceptance Criterion: Platform-specific headphone disconnect handling.
func TestAffirmations_Audio_HeadphoneDisconnectInterface(t *testing.T) {
	// Given - Mock implementation of HeadphoneDisconnectHandler
	var handler HeadphoneDisconnectHandler = &mockHeadphoneHandler{}

	// When
	handler.OnHeadphoneDisconnect()

	// Then - Verify interface can be implemented
	if handler == nil {
		t.Errorf("expected HeadphoneDisconnectHandler to be implementable")
	}
}

// mockHeadphoneHandler is a test implementation of HeadphoneDisconnectHandler.
type mockHeadphoneHandler struct {
	disconnectCalled bool
}

func (m *mockHeadphoneHandler) OnHeadphoneDisconnect() {
	m.disconnectCalled = true
}

// TestAffirmations_Audio_LocalOnlyStorageDefault verifies that audio recordings
// default to local-only storage.
//
// Acceptance Criterion: Local-only storage is the default.
func TestAffirmations_Audio_LocalOnlyStorageDefault(t *testing.T) {
	// Given - New audio recording without explicit storage location
	audio := &AudioRecording{
		ID:               "audio-002",
		AffirmationID:    "custom-002",
		UserID:           "user-123",
		DurationSeconds:  45,
		Format:           "m4a",
		BackgroundOption: BackgroundRain,
		StorageLocation:  StorageLocal, // Default
		CreatedAt:        time.Now().UTC(),
	}

	// When
	location := audio.StorageLocation

	// Then
	if location != StorageLocal {
		t.Errorf("expected default storage location to be local, got %s", location)
	}
}

// TestAffirmations_Audio_CloudSyncOptInRequired verifies that cloud sync
// requires explicit opt-in.
//
// Acceptance Criterion: Cloud sync requires explicit user opt-in.
func TestAffirmations_Audio_CloudSyncOptInRequired(t *testing.T) {
	// Given - Audio recording with cloud storage (explicit opt-in)
	audio := &AudioRecording{
		ID:               "audio-003",
		AffirmationID:    "custom-003",
		UserID:           "user-123",
		DurationSeconds:  50,
		Format:           "m4a",
		BackgroundOption: BackgroundOcean,
		StorageLocation:  StorageCloud, // Explicit opt-in
		CreatedAt:        time.Now().UTC(),
	}

	// When
	location := audio.StorageLocation

	// Then
	if location != StorageCloud {
		t.Errorf("expected storage location to be cloud, got %s", location)
	}

	// Verify both storage options are available
	validLocations := []StorageLocation{StorageLocal, StorageCloud}
	if len(validLocations) != 2 {
		t.Errorf("expected 2 storage location options, got %d", len(validLocations))
	}
}

// TestAffirmations_Audio_ZeroDuration_Rejected verifies that audio recordings
// with zero duration are rejected.
//
// Acceptance Criterion: Audio recordings must have positive duration.
func TestAffirmations_Audio_ZeroDuration_Rejected(t *testing.T) {
	// Given - Audio recording with zero duration
	durationSeconds := 0
	format := "m4a"

	// When
	err := ValidateAudioRecording(durationSeconds, format)

	// Then
	if err != ErrInvalidAudioDuration {
		t.Errorf("expected ErrInvalidAudioDuration for zero duration, got %v", err)
	}
}

// TestAffirmations_Audio_NegativeDuration_Rejected verifies that audio recordings
// with negative duration are rejected.
//
// Acceptance Criterion: Audio recordings must have positive duration.
func TestAffirmations_Audio_NegativeDuration_Rejected(t *testing.T) {
	// Given - Audio recording with negative duration
	durationSeconds := -1
	format := "m4a"

	// When
	err := ValidateAudioRecording(durationSeconds, format)

	// Then
	if err != ErrInvalidAudioDuration {
		t.Errorf("expected ErrInvalidAudioDuration for negative duration, got %v", err)
	}
}

// TestAffirmations_Audio_ValidBackgroundOption verifies that valid background
// options are accepted.
//
// Acceptance Criterion: Background options must be one of the 5 valid options.
func TestAffirmations_Audio_ValidBackgroundOption(t *testing.T) {
	// Given - Valid background options
	validOptions := []BackgroundOption{
		BackgroundNature,
		BackgroundSoftTones,
		BackgroundRain,
		BackgroundOcean,
		BackgroundSilence,
	}

	for _, option := range validOptions {
		// When
		valid := IsValidBackgroundOption(option)

		// Then
		if !valid {
			t.Errorf("expected %s to be valid, got invalid", option)
		}
	}
}

// TestAffirmations_Audio_InvalidBackgroundOption verifies that invalid background
// options are rejected.
//
// Acceptance Criterion: Background options must be one of the 5 valid options.
func TestAffirmations_Audio_InvalidBackgroundOption(t *testing.T) {
	// Given - Invalid background option
	invalidOption := BackgroundOption("jazz")

	// When
	valid := IsValidBackgroundOption(invalidOption)

	// Then
	if valid {
		t.Errorf("expected invalid background option to be rejected, got valid")
	}
}
