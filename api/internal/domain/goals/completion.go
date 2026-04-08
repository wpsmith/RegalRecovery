// internal/domain/goals/completion.go
package goals

import "time"

// CompleteInstance marks a goal instance as completed (AC-DV-4).
func CompleteInstance(instance *GoalInstance) {
	now := time.Now().UTC()
	instance.Status = StatusCompleted
	instance.CompletedAt = &now
	instance.ModifiedAt = now
}

// UncompleteInstance reverts a goal instance to pending (AC-DV-5).
func UncompleteInstance(instance *GoalInstance) {
	instance.Status = StatusPending
	instance.CompletedAt = nil
	instance.ModifiedAt = time.Now().UTC()
}

// DismissInstance marks an auto-populated goal as dismissed for a single day (AC-AP-4).
func DismissInstance(instance *GoalInstance) {
	instance.Status = StatusDismissed
	instance.ModifiedAt = time.Now().UTC()
}

// SkipInstance marks a goal as skipped during end-of-day review.
func SkipInstance(instance *GoalInstance) {
	instance.Status = StatusSkipped
	instance.ModifiedAt = time.Now().UTC()
}

// CarryInstance marks a goal as carried to tomorrow (AC-ED-3).
func CarryInstance(instance *GoalInstance) {
	instance.Status = StatusCarried
	instance.ModifiedAt = time.Now().UTC()
}

// CreateCarriedInstance creates a new instance for tomorrow from a carried goal (AC-ED-3).
func CreateCarriedInstance(original *GoalInstance, tomorrowDate string) GoalInstance {
	now := time.Now().UTC()
	return GoalInstance{
		GoalInstanceID: generateInstanceID(),
		GoalID:         original.GoalID,
		UserID:         original.UserID,
		TenantID:       original.TenantID,
		Date:           tomorrowDate,
		Text:           original.Text,
		Dynamics:       original.Dynamics,
		Scope:          original.Scope,
		Priority:       original.Priority,
		Status:         StatusPending,
		CompletedAt:    nil,
		Source:         original.Source,
		SourceID:       original.SourceID,
		CarriedFrom:    strPtr(original.Date),
		Notes:          original.Notes,
		CreatedAt:      now,
		ModifiedAt:     now,
	}
}

// AutoCompleteFromActivity marks a goal as completed when the corresponding
// activity is completed through its native flow (AC-AP-6).
func AutoCompleteFromActivity(instance *GoalInstance) {
	CompleteInstance(instance)
}
