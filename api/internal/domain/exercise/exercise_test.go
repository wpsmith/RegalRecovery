// internal/domain/exercise/exercise_test.go
package exercise

import (
	"strings"
	"testing"
	"time"
)

func TestExerciseLog_FR_EX_1_1_ActivityTypeValidation_AcceptsPredefinedTypes(t *testing.T) {
	for actType := range ValidActivityTypes {
		if actType == ActivityTypeOther {
			continue
		}
		req := CreateExerciseLogRequest{
			Timestamp:       time.Now().UTC(),
			ActivityType:    actType,
			DurationMinutes: 30,
			Source:          SourceManual,
		}
		if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
			t.Errorf("expected activity type %s to be valid, got error: %v", actType, err)
		}
	}
}

func TestExerciseLog_FR_EX_1_1_ActivityTypeOther_RequiresCustomLabel(t *testing.T) {
	label := "Pickleball"
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeOther,
		CustomTypeLabel: &label,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
		t.Errorf("expected 'other' with label to be valid, got error: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_1_ActivityTypeOther_MissingLabel_ReturnsError(t *testing.T) {
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeOther,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	err := ValidateCreateRequest(req, time.Now().UTC())
	if err == nil {
		t.Error("expected error for 'other' without label, got nil")
	}
	if err != ErrCustomLabelRequired {
		t.Errorf("expected ErrCustomLabelRequired, got: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_2_DurationMinimum_RejectsZero(t *testing.T) {
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 0,
		Source:          SourceManual,
	}
	err := ValidateCreateRequest(req, time.Now().UTC())
	if err == nil {
		t.Error("expected error for duration 0, got nil")
	}
}

func TestExerciseLog_FR_EX_1_2_DurationMinimum_AcceptsOne(t *testing.T) {
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 1,
		Source:          SourceManual,
	}
	if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
		t.Errorf("expected duration 1 to be valid, got error: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_2_DurationMaximum_Rejects1441(t *testing.T) {
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 1441,
		Source:          SourceManual,
	}
	err := ValidateCreateRequest(req, time.Now().UTC())
	if err == nil {
		t.Error("expected error for duration 1441, got nil")
	}
}

func TestExerciseLog_FR_EX_1_3_IntensityValidation_AcceptsLightModerateVigorous(t *testing.T) {
	for _, intensity := range []string{IntensityLight, IntensityModerate, IntensityVigorous} {
		i := intensity
		req := CreateExerciseLogRequest{
			Timestamp:       time.Now().UTC(),
			ActivityType:    ActivityTypeRunning,
			DurationMinutes: 30,
			Intensity:       &i,
			Source:          SourceManual,
		}
		if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
			t.Errorf("expected intensity %s to be valid, got error: %v", intensity, err)
		}
	}
}

func TestExerciseLog_FR_EX_1_3_IntensityOptional_NilIsValid(t *testing.T) {
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
		t.Errorf("expected nil intensity to be valid, got error: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_4_TimestampDefault_UsesCurrentTime(t *testing.T) {
	now := time.Now().UTC()
	req := CreateExerciseLogRequest{
		Timestamp:       now,
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	if err := ValidateCreateRequest(req, now); err != nil {
		t.Errorf("expected current time to be valid, got error: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_4_TimestampBackdated_AllowsPastDate(t *testing.T) {
	now := time.Now().UTC()
	yesterday := now.AddDate(0, 0, -1)
	req := CreateExerciseLogRequest{
		Timestamp:       yesterday,
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	if err := ValidateCreateRequest(req, now); err != nil {
		t.Errorf("expected yesterday to be valid, got error: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_4_TimestampFuture_RejectsBeyond24Hours(t *testing.T) {
	now := time.Now().UTC()
	future := now.Add(25 * time.Hour)
	req := CreateExerciseLogRequest{
		Timestamp:       future,
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	err := ValidateCreateRequest(req, now)
	if err == nil {
		t.Error("expected error for timestamp > 24h in future, got nil")
	}
	if err != ErrTimestampTooFarFuture {
		t.Errorf("expected ErrTimestampTooFarFuture, got: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_5_NotesMaxLength_Rejects501Chars(t *testing.T) {
	longNotes := strings.Repeat("a", 501)
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 30,
		Notes:           &longNotes,
		Source:          SourceManual,
	}
	err := ValidateCreateRequest(req, time.Now().UTC())
	if err == nil {
		t.Error("expected error for 501-char notes, got nil")
	}
}

func TestExerciseLog_FR_EX_1_5_NotesOptional_NilIsValid(t *testing.T) {
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
		t.Errorf("expected nil notes to be valid, got error: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_6_MoodBeforeAfter_AcceptsRange1To5(t *testing.T) {
	for i := 1; i <= 5; i++ {
		before := i
		after := i
		req := CreateExerciseLogRequest{
			Timestamp:       time.Now().UTC(),
			ActivityType:    ActivityTypeRunning,
			DurationMinutes: 30,
			MoodBefore:      &before,
			MoodAfter:       &after,
			Source:          SourceManual,
		}
		if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
			t.Errorf("expected mood %d to be valid, got error: %v", i, err)
		}
	}
}

func TestExerciseLog_FR_EX_1_6_MoodBeforeAfter_RejectsOutOfRange(t *testing.T) {
	cases := []struct {
		name   string
		before *int
		after  *int
	}{
		{"mood before 0", intPtr(0), nil},
		{"mood before 6", intPtr(6), nil},
		{"mood after 0", nil, intPtr(0)},
		{"mood after 6", nil, intPtr(6)},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			req := CreateExerciseLogRequest{
				Timestamp:       time.Now().UTC(),
				ActivityType:    ActivityTypeRunning,
				DurationMinutes: 30,
				MoodBefore:      tc.before,
				MoodAfter:       tc.after,
				Source:          SourceManual,
			}
			err := ValidateCreateRequest(req, time.Now().UTC())
			if err == nil {
				t.Errorf("expected error for %s, got nil", tc.name)
			}
		})
	}
}

func TestExerciseLog_FR_EX_1_6_MoodOptional_NilIsValid(t *testing.T) {
	req := CreateExerciseLogRequest{
		Timestamp:       time.Now().UTC(),
		ActivityType:    ActivityTypeRunning,
		DurationMinutes: 30,
		Source:          SourceManual,
	}
	if err := ValidateCreateRequest(req, time.Now().UTC()); err != nil {
		t.Errorf("expected nil mood to be valid, got error: %v", err)
	}
}

func TestExerciseLog_FR_EX_1_7_ImmutableTimestamp_RejectsModification(t *testing.T) {
	raw := map[string]interface{}{"timestamp": "2026-01-01T00:00:00Z"}
	err := CheckImmutableFieldViolation(raw)
	if err == nil {
		t.Error("expected error when modifying timestamp")
	}
}

func TestExerciseLog_FR_EX_1_7_ImmutableCreatedAt_RejectsModification(t *testing.T) {
	raw := map[string]interface{}{"createdAt": "2026-01-01T00:00:00Z"}
	err := CheckImmutableFieldViolation(raw)
	if err == nil {
		t.Error("expected error when modifying createdAt")
	}
}

func TestExerciseLog_FR_EX_1_7_ImmutableActivityType_RejectsModification(t *testing.T) {
	raw := map[string]interface{}{"activityType": "yoga"}
	err := CheckImmutableFieldViolation(raw)
	if err == nil {
		t.Error("expected error when modifying activityType")
	}
}

func TestExerciseLog_FR_EX_1_7_ImmutableDuration_RejectsModification(t *testing.T) {
	raw := map[string]interface{}{"durationMinutes": 60}
	err := CheckImmutableFieldViolation(raw)
	if err == nil {
		t.Error("expected error when modifying durationMinutes")
	}
}

func TestExerciseLog_FR_EX_1_7_ImmutableSource_RejectsModification(t *testing.T) {
	raw := map[string]interface{}{"source": "apple-health"}
	err := CheckImmutableFieldViolation(raw)
	if err == nil {
		t.Error("expected error when modifying source")
	}
}

func TestExerciseLog_FR_EX_1_7_MutableIntensity_AcceptsUpdate(t *testing.T) {
	intensity := IntensityVigorous
	req := UpdateExerciseLogRequest{Intensity: &intensity}
	updates, err := ValidateUpdateRequest(req)
	if err != nil {
		t.Errorf("expected intensity update to be valid, got error: %v", err)
	}
	if updates["intensity"] != IntensityVigorous {
		t.Error("expected intensity to be updated")
	}
}

func TestExerciseLog_FR_EX_1_7_MutableNotes_AcceptsUpdate(t *testing.T) {
	notes := "Updated notes"
	req := UpdateExerciseLogRequest{Notes: &notes}
	updates, err := ValidateUpdateRequest(req)
	if err != nil {
		t.Errorf("expected notes update to be valid, got error: %v", err)
	}
	if updates["notes"] != "Updated notes" {
		t.Error("expected notes to be updated")
	}
}

func TestExerciseLog_FR_EX_1_7_MutableMood_AcceptsUpdate(t *testing.T) {
	before := 2
	after := 4
	req := UpdateExerciseLogRequest{MoodBefore: &before, MoodAfter: &after}
	updates, err := ValidateUpdateRequest(req)
	if err != nil {
		t.Errorf("expected mood update to be valid, got error: %v", err)
	}
	if updates["moodBefore"] != 2 {
		t.Error("expected moodBefore to be updated")
	}
	if updates["moodAfter"] != 4 {
		t.Error("expected moodAfter to be updated")
	}
}

func intPtr(i int) *int { return &i }
