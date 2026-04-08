// internal/domain/postmortem/validation.go
package postmortem

import (
	"errors"
	"fmt"
	"strings"
)

// Validation errors.
var (
	ErrInvalidEventType       = errors.New("invalid event type")
	ErrNearMissCannotLink     = errors.New("near-miss event type cannot have relapseId")
	ErrInvalidTriggerCategory = errors.New("invalid trigger category")
	ErrInvalidFASTERStage     = errors.New("invalid FASTER stage")
	ErrInvalidActionCategory  = errors.New("invalid action category")
	ErrInvalidTimePeriod      = errors.New("invalid time period")
	ErrInvalidShareType       = errors.New("invalid share type")
	ErrMoodRatingOutOfRange   = errors.New("mood rating must be between 1 and 10")
	ErrTextTooLong            = errors.New("text exceeds maximum length")
	ErrDurationMustBePositive = errors.New("duration minutes must be positive")
	ErrActionItemLimit        = errors.New("action plan must have 1-10 items")
	ErrIncompletePostMortem   = errors.New("missing required sections for completion")
	ErrCannotDeleteCompleted  = errors.New("completed post-mortems cannot be deleted")
	ErrCannotShareDraft       = errors.New("only completed post-mortems can be shared")
	ErrCannotExportDraft      = errors.New("only completed post-mortems can be exported")
	ErrCompletedImmutable     = errors.New("cannot modify sections of completed post-mortem")
	ErrImmutableTimestamp     = errors.New("createdAt timestamp is immutable")
)

// ValidateEventType validates the event type string.
func ValidateEventType(eventType string) error {
	if !ValidEventTypes[eventType] {
		return fmt.Errorf("%w: %s; must be one of: relapse, near-miss, combined", ErrInvalidEventType, eventType)
	}
	return nil
}

// ValidateEventTypeRelapseLink validates that near-miss events don't link to a relapse.
func ValidateEventTypeRelapseLink(eventType string, relapseID *string) error {
	if eventType == EventTypeNearMiss && relapseID != nil && *relapseID != "" {
		return ErrNearMissCannotLink
	}
	return nil
}

// ValidateMoodRating validates a mood rating is within range.
func ValidateMoodRating(rating *int) error {
	if rating == nil {
		return nil
	}
	if *rating < MinMoodRating || *rating > MaxMoodRating {
		return fmt.Errorf("%w: got %d", ErrMoodRatingOutOfRange, *rating)
	}
	return nil
}

// ValidateTextLength validates a text field is within the maximum length.
func ValidateTextLength(text string, maxLen int) error {
	if len(text) > maxLen {
		return fmt.Errorf("%w: %d characters exceeds maximum of %d", ErrTextTooLong, len(text), maxLen)
	}
	return nil
}

// ValidateTriggerCategory validates a single trigger category.
func ValidateTriggerCategory(category string) error {
	if !ValidTriggerCategories[category] {
		return fmt.Errorf("%w: %s", ErrInvalidTriggerCategory, category)
	}
	return nil
}

// ValidateFASTERStage validates a single FASTER stage.
func ValidateFASTERStage(stage string) error {
	if !ValidFASTERStages[stage] {
		return fmt.Errorf("%w: %s", ErrInvalidFASTERStage, stage)
	}
	return nil
}

// ValidateActionCategory validates a single action category.
func ValidateActionCategory(category string) error {
	if !ValidActionCategories[category] {
		return fmt.Errorf("%w: %s", ErrInvalidActionCategory, category)
	}
	return nil
}

// ValidateTimePeriod validates a time block period.
func ValidateTimePeriod(period string) error {
	if !ValidTimePeriods[period] {
		return fmt.Errorf("%w: %s", ErrInvalidTimePeriod, period)
	}
	return nil
}

// ValidateShareType validates a share type.
func ValidateShareType(shareType string) error {
	if !ValidShareTypes[shareType] {
		return fmt.Errorf("%w: %s", ErrInvalidShareType, shareType)
	}
	return nil
}

// ValidateDurationMinutes validates that duration is positive.
func ValidateDurationMinutes(duration *int) error {
	if duration == nil {
		return nil
	}
	if *duration <= 0 {
		return ErrDurationMustBePositive
	}
	return nil
}

// ValidateActionPlanCount validates action item count for completion.
func ValidateActionPlanCount(count int) error {
	if count < MinActionItems || count > MaxActionItems {
		return fmt.Errorf("%w: got %d items", ErrActionItemLimit, count)
	}
	return nil
}

// ValidateDayBeforeSection validates the Day Before section.
func ValidateDayBeforeSection(s *DayBeforeSection) error {
	if s == nil {
		return nil
	}
	if err := ValidateTextLength(s.Text, MaxTextLength); err != nil {
		return fmt.Errorf("dayBefore.text: %w", err)
	}
	if err := ValidateMoodRating(s.MoodRating); err != nil {
		return fmt.Errorf("dayBefore.moodRating: %w", err)
	}
	return nil
}

// ValidateMorningSection validates the Morning section.
func ValidateMorningSection(s *MorningSection) error {
	if s == nil {
		return nil
	}
	if err := ValidateTextLength(s.Text, MaxTextLength); err != nil {
		return fmt.Errorf("morning.text: %w", err)
	}
	if err := ValidateMoodRating(s.MoodRating); err != nil {
		return fmt.Errorf("morning.moodRating: %w", err)
	}
	return nil
}

// ValidateThroughoutTheDaySection validates the Throughout the Day section.
func ValidateThroughoutTheDaySection(s *ThroughoutTheDaySection) error {
	if s == nil {
		return nil
	}
	for i, tb := range s.TimeBlocks {
		if err := ValidateTimePeriod(tb.Period); err != nil {
			return fmt.Errorf("throughoutTheDay.timeBlocks[%d].period: %w", i, err)
		}
	}
	return nil
}

// ValidateBuildUpSection validates the Build-Up section.
func ValidateBuildUpSection(s *BuildUpSection) error {
	if s == nil {
		return nil
	}
	for i, t := range s.Triggers {
		if err := ValidateTriggerCategory(t.Category); err != nil {
			return fmt.Errorf("buildUp.triggers[%d].category: %w", i, err)
		}
	}
	return nil
}

// ValidateActingOutSection validates the Acting Out section.
func ValidateActingOutSection(s *ActingOutSection) error {
	if s == nil {
		return nil
	}
	if err := ValidateTextLength(s.Description, MaxTextLength); err != nil {
		return fmt.Errorf("actingOut.description: %w", err)
	}
	if err := ValidateDurationMinutes(s.DurationMinutes); err != nil {
		return fmt.Errorf("actingOut.durationMinutes: %w", err)
	}
	return nil
}

// ValidateImmediatelyAfterSection validates the Immediately After section.
func ValidateImmediatelyAfterSection(s *ImmediatelyAfterSection) error {
	if s == nil {
		return nil
	}
	if err := ValidateTextLength(s.WhatDidNext, MaxShortTextLength); err != nil {
		return fmt.Errorf("immediatelyAfter.whatDidNext: %w", err)
	}
	if err := ValidateTextLength(s.WishDoneDifferently, MaxShortTextLength); err != nil {
		return fmt.Errorf("immediatelyAfter.wishDoneDifferently: %w", err)
	}
	return nil
}

// ValidateSections validates all provided sections.
func ValidateSections(s *Sections) error {
	if s == nil {
		return nil
	}
	if err := ValidateDayBeforeSection(s.DayBefore); err != nil {
		return err
	}
	if err := ValidateMorningSection(s.Morning); err != nil {
		return err
	}
	if err := ValidateThroughoutTheDaySection(s.ThroughoutTheDay); err != nil {
		return err
	}
	if err := ValidateBuildUpSection(s.BuildUp); err != nil {
		return err
	}
	if err := ValidateActingOutSection(s.ActingOut); err != nil {
		return err
	}
	if err := ValidateImmediatelyAfterSection(s.ImmediatelyAfter); err != nil {
		return err
	}
	return nil
}

// ValidateTriggerDetails validates trigger details array.
func ValidateTriggerDetails(triggers []TriggerDetail) error {
	for i, t := range triggers {
		if err := ValidateTriggerCategory(t.Category); err != nil {
			return fmt.Errorf("triggerDetails[%d]: %w", i, err)
		}
	}
	return nil
}

// ValidateFasterMapping validates FASTER mapping entries.
func ValidateFasterMapping(entries []FasterMappingEntry) error {
	for i, e := range entries {
		if err := ValidateFASTERStage(e.Stage); err != nil {
			return fmt.Errorf("fasterMapping[%d]: %w", i, err)
		}
	}
	return nil
}

// ValidateActionPlan validates the action plan items.
func ValidateActionPlan(items []ActionPlanItem) error {
	for i, item := range items {
		if err := ValidateActionCategory(item.Category); err != nil {
			return fmt.Errorf("actionPlan[%d]: %w", i, err)
		}
	}
	return nil
}

// ValidateCompleteness checks if a post-mortem is ready for completion.
// Returns the list of missing sections for error reporting.
func ValidateCompleteness(pm *PostMortemAnalysis) ([]string, error) {
	var missing []string
	if pm.Sections.DayBefore == nil {
		missing = append(missing, SectionDayBefore)
	}
	if pm.Sections.Morning == nil {
		missing = append(missing, SectionMorning)
	}
	if pm.Sections.ThroughoutTheDay == nil {
		missing = append(missing, SectionThroughoutTheDay)
	}
	if pm.Sections.BuildUp == nil {
		missing = append(missing, SectionBuildUp)
	}
	if pm.Sections.ActingOut == nil {
		missing = append(missing, SectionActingOut)
	}
	if pm.Sections.ImmediatelyAfter == nil {
		missing = append(missing, SectionImmediatelyAfter)
	}

	actionCount := len(pm.ActionPlan)

	if len(missing) > 0 || actionCount < MinActionItems {
		detail := ""
		if len(missing) > 0 {
			detail = "Missing required sections: " + strings.Join(missing, ", ") + "."
		}
		if actionCount < MinActionItems {
			if detail != "" {
				detail += " "
			}
			detail += fmt.Sprintf("Minimum %d action plan item required.", MinActionItems)
		}
		return missing, fmt.Errorf("%w: %s", ErrIncompletePostMortem, detail)
	}

	if actionCount > MaxActionItems {
		return nil, fmt.Errorf("%w: %d items exceeds maximum of %d", ErrActionItemLimit, actionCount, MaxActionItems)
	}

	return nil, nil
}

// CompletedSections returns names of sections that have been filled in.
func CompletedSections(s *Sections) []string {
	var completed []string
	if s.DayBefore != nil {
		completed = append(completed, SectionDayBefore)
	}
	if s.Morning != nil {
		completed = append(completed, SectionMorning)
	}
	if s.ThroughoutTheDay != nil {
		completed = append(completed, SectionThroughoutTheDay)
	}
	if s.BuildUp != nil {
		completed = append(completed, SectionBuildUp)
	}
	if s.ActingOut != nil {
		completed = append(completed, SectionActingOut)
	}
	if s.ImmediatelyAfter != nil {
		completed = append(completed, SectionImmediatelyAfter)
	}
	return completed
}

// RemainingSections returns names of sections not yet filled in.
func RemainingSections(s *Sections) []string {
	completed := make(map[string]bool)
	for _, c := range CompletedSections(s) {
		completed[c] = true
	}
	var remaining []string
	for _, section := range AllSections {
		if !completed[section] {
			remaining = append(remaining, section)
		}
	}
	return remaining
}
