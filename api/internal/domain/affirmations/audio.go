// internal/domain/affirmations/audio.go
package affirmations

import (
	"errors"
	"time"
)

// Sentinel errors for audio recordings.
var (
	ErrAudioDurationExceeded   = errors.New("audio duration exceeds 60 seconds")
	ErrInvalidAudioDuration    = errors.New("audio duration must be positive")
	ErrInvalidAudioFormat      = errors.New("audio format must be m4a")
	ErrInvalidBackgroundOption = errors.New("invalid background option")
)

const (
	// MaxAudioDurationSeconds is the maximum duration for audio recordings.
	MaxAudioDurationSeconds = 60
	// RequiredAudioFormat is the only accepted audio format.
	RequiredAudioFormat = "m4a"
)

// BackgroundOption represents audio background options.
type BackgroundOption string

const (
	// BackgroundNature is nature sounds background.
	BackgroundNature BackgroundOption = "nature"
	// BackgroundSoftTones is soft tones background.
	BackgroundSoftTones BackgroundOption = "soft-tones"
	// BackgroundRain is rain sounds background.
	BackgroundRain BackgroundOption = "rain"
	// BackgroundOcean is ocean sounds background.
	BackgroundOcean BackgroundOption = "ocean"
	// BackgroundSilence is no background sound.
	BackgroundSilence BackgroundOption = "silence"
)

// StorageLocation represents where audio is stored.
type StorageLocation string

const (
	// StorageLocal indicates audio is stored locally on device only.
	StorageLocal StorageLocation = "local"
	// StorageCloud indicates audio is synced to cloud storage.
	StorageCloud StorageLocation = "cloud"
)

// AudioRecording represents metadata for a user's audio affirmation recording.
type AudioRecording struct {
	ID               string           `json:"id"`
	AffirmationID    string           `json:"affirmationId"`
	UserID           string           `json:"userId"`
	DurationSeconds  int              `json:"durationSeconds"`
	Format           string           `json:"format"`
	BackgroundOption BackgroundOption `json:"backgroundOption"`
	StorageLocation  StorageLocation  `json:"storageLocation"`
	CreatedAt        time.Time        `json:"createdAt"`
}

// HeadphoneDisconnectHandler defines platform-specific behavior when headphones disconnect.
// Implementations should pause playback and optionally show a notification.
type HeadphoneDisconnectHandler interface {
	OnHeadphoneDisconnect()
}

// ValidateAudioRecording validates audio recording duration and format.
func ValidateAudioRecording(durationSeconds int, format string) error {
	// Check duration is positive.
	if durationSeconds <= 0 {
		return ErrInvalidAudioDuration
	}

	// Check duration does not exceed maximum.
	if durationSeconds > MaxAudioDurationSeconds {
		return ErrAudioDurationExceeded
	}

	// Check format is m4a.
	if format != RequiredAudioFormat {
		return ErrInvalidAudioFormat
	}

	return nil
}

// IsValidBackgroundOption checks if the given background option is valid.
func IsValidBackgroundOption(option BackgroundOption) bool {
	validOptions := []BackgroundOption{
		BackgroundNature,
		BackgroundSoftTones,
		BackgroundRain,
		BackgroundOcean,
		BackgroundSilence,
	}

	for _, valid := range validOptions {
		if option == valid {
			return true
		}
	}

	return false
}

// ValidateAudioMetadata validates all audio recording metadata.
func ValidateAudioMetadata(audio *AudioRecording) error {
	// Validate duration and format.
	if err := ValidateAudioRecording(audio.DurationSeconds, audio.Format); err != nil {
		return err
	}

	// Validate background option.
	if !IsValidBackgroundOption(audio.BackgroundOption) {
		return ErrInvalidBackgroundOption
	}

	return nil
}

// SetStorageLocation updates the storage location for an audio recording.
// This represents explicit opt-in to cloud sync.
func (a *AudioRecording) SetStorageLocation(location StorageLocation) {
	a.StorageLocation = location
}

// IsCloudSynced returns true if the audio is stored in the cloud.
func (a *AudioRecording) IsCloudSynced() bool {
	return a.StorageLocation == StorageCloud
}
