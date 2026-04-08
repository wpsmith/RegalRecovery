// internal/domain/personcheckin/validation.go
package personcheckin

import (
	"errors"
	"fmt"
	"time"
)

var (
	// ErrInvalidCheckInType indicates the check-in type is not valid.
	ErrInvalidCheckInType = errors.New("invalid checkInType: must be one of spouse, sponsor, counselor-coach")

	// ErrInvalidMethod indicates the contact method is not valid.
	ErrInvalidMethod = errors.New("invalid method: must be one of in-person, phone-call, video-call, text-message, app-messaging")

	// ErrContactNameTooLong indicates the contact name exceeds 50 characters.
	ErrContactNameTooLong = errors.New("contactName exceeds 50 characters")

	// ErrNotesTooLong indicates the notes exceed 1000 characters.
	ErrNotesTooLong = errors.New("notes exceed 1000 characters")

	// ErrQualityRatingOutOfRange indicates quality rating is outside 1-5.
	ErrQualityRatingOutOfRange = errors.New("qualityRating must be between 1 and 5")

	// ErrInvalidTopic indicates a topic is not in the allowed set.
	ErrInvalidTopic = errors.New("invalid topic: not in the allowed set")

	// ErrTooManyFollowUpItems indicates more than 3 follow-up items.
	ErrTooManyFollowUpItems = errors.New("followUpItems cannot exceed 3 items")

	// ErrFollowUpItemTooLong indicates a follow-up item exceeds 200 characters.
	ErrFollowUpItemTooLong = errors.New("followUpItems item exceeds 200 characters")

	// ErrDurationOutOfRange indicates duration is outside 0-480.
	ErrDurationOutOfRange = errors.New("durationMinutes must be between 0 and 480")

	// ErrCheckInNotFound indicates the check-in was not found.
	ErrCheckInNotFound = errors.New("person check-in not found")

	// ErrImmutableField indicates an attempt to modify an immutable field.
	ErrImmutableField = errors.New("field is immutable and cannot be modified")

	// ErrCounselorSubCategoryForNonCounselor indicates counselorSubCategory used with non-counselor type.
	ErrCounselorSubCategoryForNonCounselor = errors.New("counselorSubCategory is only valid for counselor-coach check-in type")

	// ErrInvalidCounselorSubCategory indicates an invalid counselor sub-category.
	ErrInvalidCounselorSubCategory = errors.New("invalid counselorSubCategory: must be scheduled-session or between-session-contact")

	// ErrInvalidStreakFrequency indicates an invalid streak frequency value.
	ErrInvalidStreakFrequency = errors.New("invalid streakFrequency: must be daily, x-per-week, or weekly")

	// ErrInactivityAlertDaysOutOfRange indicates inactivity alert days outside 1-30.
	ErrInactivityAlertDaysOutOfRange = errors.New("inactivityAlertDays must be between 1 and 30")

	// ErrFollowUpIndexOutOfRange indicates a follow-up index is out of range.
	ErrFollowUpIndexOutOfRange = errors.New("follow-up item index is out of range")

	// ErrFollowUpAlreadyConverted indicates a follow-up item has already been converted to a goal.
	ErrFollowUpAlreadyConverted = errors.New("follow-up item has already been converted to a goal")

	// ErrInvalidInput indicates general invalid input.
	ErrInvalidInput = errors.New("invalid input data")

	// ErrTimestampInFuture indicates a timestamp is in the future.
	ErrTimestampInFuture = errors.New("timestamp cannot be in the future")
)

// ValidateCreateRequest validates a create person check-in request.
func ValidateCreateRequest(req *CreatePersonCheckInRequest) error {
	if !isValidCheckInType(req.CheckInType) {
		return ErrInvalidCheckInType
	}

	if !isValidMethod(req.Method) {
		return ErrInvalidMethod
	}

	if req.Timestamp != nil && req.Timestamp.After(time.Now().Add(time.Minute)) {
		return ErrTimestampInFuture
	}

	if req.ContactName != nil && len(*req.ContactName) > 50 {
		return ErrContactNameTooLong
	}

	if req.Notes != nil && len(*req.Notes) > 1000 {
		return ErrNotesTooLong
	}

	if req.QualityRating != nil && (*req.QualityRating < 1 || *req.QualityRating > 5) {
		return ErrQualityRatingOutOfRange
	}

	if req.DurationMinutes != nil && (*req.DurationMinutes < 0 || *req.DurationMinutes > 480) {
		return ErrDurationOutOfRange
	}

	if err := validateTopics(req.TopicsDiscussed); err != nil {
		return err
	}

	if err := validateFollowUpItems(req.FollowUpItems); err != nil {
		return err
	}

	if err := validateCounselorSubCategory(req.CheckInType, req.CounselorSubCategory); err != nil {
		return err
	}

	return nil
}

// ValidateQuickLogRequest validates a quick-log request.
func ValidateQuickLogRequest(req *QuickLogPersonCheckInRequest) error {
	if !isValidCheckInType(req.CheckInType) {
		return ErrInvalidCheckInType
	}

	if req.Method != nil && !isValidMethod(*req.Method) {
		return ErrInvalidMethod
	}

	return nil
}

// ValidateUpdateRequest validates an update person check-in request.
func ValidateUpdateRequest(req *UpdatePersonCheckInRequest) error {
	if req.Method != nil && !isValidMethod(*req.Method) {
		return ErrInvalidMethod
	}

	if req.ContactName != nil && len(*req.ContactName) > 50 {
		return ErrContactNameTooLong
	}

	if req.Notes != nil && len(*req.Notes) > 1000 {
		return ErrNotesTooLong
	}

	if req.QualityRating != nil && (*req.QualityRating < 1 || *req.QualityRating > 5) {
		return ErrQualityRatingOutOfRange
	}

	if req.DurationMinutes != nil && (*req.DurationMinutes < 0 || *req.DurationMinutes > 480) {
		return ErrDurationOutOfRange
	}

	if err := validateTopics(req.TopicsDiscussed); err != nil {
		return err
	}

	if err := validateFollowUpItems(req.FollowUpItems); err != nil {
		return err
	}

	return nil
}

// ValidateSettingsUpdate validates a settings update request.
func ValidateSettingsUpdate(req *UpdateSettingsRequest) error {
	if req.Spouse != nil {
		if err := validateSubTypeSettingsUpdate(req.Spouse); err != nil {
			return fmt.Errorf("spouse: %w", err)
		}
	}
	if req.Sponsor != nil {
		if err := validateSubTypeSettingsUpdate(req.Sponsor); err != nil {
			return fmt.Errorf("sponsor: %w", err)
		}
	}
	if req.CounselorCoach != nil {
		if err := validateSubTypeSettingsUpdate(req.CounselorCoach); err != nil {
			return fmt.Errorf("counselorCoach: %w", err)
		}
	}
	return nil
}

func validateSubTypeSettingsUpdate(update *SubTypeSettingsUpdate) error {
	if update.StreakFrequency != nil && !isValidStreakFrequency(*update.StreakFrequency) {
		return ErrInvalidStreakFrequency
	}

	if update.InactivityAlertDays != nil && (*update.InactivityAlertDays < 1 || *update.InactivityAlertDays > 30) {
		return ErrInactivityAlertDaysOutOfRange
	}

	if update.ContactName != nil && len(*update.ContactName) > 50 {
		return ErrContactNameTooLong
	}

	return nil
}

func isValidCheckInType(t CheckInType) bool {
	for _, valid := range ValidCheckInTypes {
		if t == valid {
			return true
		}
	}
	return false
}

func isValidMethod(m Method) bool {
	for _, valid := range ValidMethods {
		if m == valid {
			return true
		}
	}
	return false
}

func isValidTopic(t Topic) bool {
	for _, valid := range ValidTopics {
		if t == valid {
			return true
		}
	}
	return false
}

func isValidStreakFrequency(f StreakFrequency) bool {
	for _, valid := range ValidStreakFrequencies {
		if f == valid {
			return true
		}
	}
	return false
}

func validateTopics(topics []Topic) error {
	if len(topics) > 12 {
		return fmt.Errorf("topicsDiscussed cannot exceed 12 items: %w", ErrInvalidInput)
	}
	for _, t := range topics {
		if !isValidTopic(t) {
			return fmt.Errorf("%s: %w", string(t), ErrInvalidTopic)
		}
	}
	return nil
}

func validateFollowUpItems(items []string) error {
	if len(items) > 3 {
		return ErrTooManyFollowUpItems
	}
	for _, item := range items {
		if len(item) > 200 {
			return ErrFollowUpItemTooLong
		}
	}
	return nil
}

func validateCounselorSubCategory(checkInType CheckInType, subCat *CounselorSubCategory) error {
	if subCat == nil {
		return nil
	}

	if checkInType != CheckInTypeCounselorCoach {
		return ErrCounselorSubCategoryForNonCounselor
	}

	if *subCat != CounselorSubCategoryScheduledSession && *subCat != CounselorSubCategoryBetweenSessionContact {
		return ErrInvalidCounselorSubCategory
	}

	return nil
}
