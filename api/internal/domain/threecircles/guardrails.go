// internal/domain/threecircles/guardrails.go
package threecircles

import (
	"strings"
)

// GuardrailType represents the type of guardrail advice provided to the user.
type GuardrailType string

const (
	GuardrailSpecificity        GuardrailType = "specificity"
	GuardrailOverload           GuardrailType = "overload"
	GuardrailMiddleCircleDepth  GuardrailType = "middleCircleDepth"
	GuardrailIsolation          GuardrailType = "isolation"
	GuardrailInnerCircleAdd     GuardrailType = "innerCircleAdd"
	GuardrailInnerCircleRemove  GuardrailType = "innerCircleRemove"
	GuardrailPacing             GuardrailType = "pacing"
	GuardrailFlowDuration       GuardrailType = "flowDuration"
)

// GuardrailAdvice represents a single piece of guardrail feedback.
type GuardrailAdvice struct {
	Type     GuardrailType `json:"type"`
	Message  string        `json:"message"`
	ItemID   string        `json:"itemId,omitempty"`
	Blocking bool          `json:"blocking"`
}

// Vague keywords that trigger specificity nudge.
var vagueKeywords = []string{
	"be",
	"stop",
	"better",
	"good",
	"bad",
	"right",
	"wrong",
}

// CheckSpecificity detects if a behavior name is too vague.
// Returns advisory (non-blocking) if:
// - Less than 5 words
// - Contains vague keywords
func CheckSpecificity(behaviorName string) *GuardrailAdvice {
	trimmed := strings.TrimSpace(behaviorName)
	if trimmed == "" {
		return nil
	}

	// Count words.
	words := strings.Fields(trimmed)
	if len(words) < 5 {
		return &GuardrailAdvice{
			Type:     GuardrailSpecificity,
			Message:  "Consider adding more detail to make this behavior more specific. What does this look like for you?",
			Blocking: false,
		}
	}

	// Check for vague keywords.
	lowerText := strings.ToLower(trimmed)
	for _, keyword := range vagueKeywords {
		// Match whole words only.
		if strings.Contains(" "+lowerText+" ", " "+keyword+" ") ||
			strings.HasPrefix(lowerText, keyword+" ") ||
			strings.HasSuffix(lowerText, " "+keyword) ||
			lowerText == keyword {
			return &GuardrailAdvice{
				Type:     GuardrailSpecificity,
				Message:  "Consider adding more detail to make this behavior more specific. What does this look like for you?",
				Blocking: false,
			}
		}
	}

	return nil
}

// CheckInnerCircleOverload detects when the inner circle has too many items.
// - Soft advisory at > 8 items (and < 20)
// - Hard error (blocking) at > 20 items
// - At exactly 20 items: no advice (boundary case, user is at max but not over)
func CheckInnerCircleOverload(count int) *GuardrailAdvice {
	if count > 20 {
		return &GuardrailAdvice{
			Type:     GuardrailOverload,
			Message:  "Inner circle is at maximum capacity (20 items). Consider moving some items to the middle circle.",
			Blocking: true,
		}
	}
	if count > 8 && count < 20 {
		return &GuardrailAdvice{
			Type:     GuardrailOverload,
			Message:  "Your inner circle is getting full. Consider reviewing which items are truly non-negotiable for your recovery.",
			Blocking: false,
		}
	}
	return nil
}

// CheckMiddleCircleDepth detects when the middle circle has too few items at commit time.
// Returns advisory if middle circle has fewer than 3 items.
func CheckMiddleCircleDepth(count int) *GuardrailAdvice {
	if count < 3 {
		return &GuardrailAdvice{
			Type:     GuardrailMiddleCircleDepth,
			Message:  "Your middle circle could use more depth. Consider adding behaviors that could lead to your inner circle.",
			Blocking: false,
		}
	}
	return nil
}

// CheckIsolation detects when a user is committing without prior sponsor share.
// Returns advisory if hasSponsorShare is false.
func CheckIsolation(hasSponsorShare bool) *GuardrailAdvice {
	if !hasSponsorShare {
		return &GuardrailAdvice{
			Type:     GuardrailIsolation,
			Message:  "Consider sharing your Three Circles with your sponsor or accountability partner before committing.",
			Blocking: false,
		}
	}
	return nil
}

// CheckInnerCircleAddition returns an advisory when a user is about to add an item to the inner circle.
// Always returns a message to emphasize the significance of the commitment.
func CheckInnerCircleAddition() *GuardrailAdvice {
	return &GuardrailAdvice{
		Type:     GuardrailInnerCircleAdd,
		Message:  "Adding to inner circle is a significant commitment. This represents a behavior you're committing to avoid for your recovery.",
		Blocking: false,
	}
}

// CheckInnerCircleRemoval returns an advisory when a user is about to remove an item from the inner circle.
// Always returns a message to clarify what removal means.
func CheckInnerCircleRemoval() *GuardrailAdvice {
	return &GuardrailAdvice{
		Type:     GuardrailInnerCircleRemove,
		Message:  "Removing from inner circle means you're no longer committing to avoid this. Consider discussing with your sponsor first.",
		Blocking: false,
	}
}

// CheckPacing detects when the same item has been edited too many times.
// Returns advisory if editCount >= 3.
func CheckPacing(editCount int) *GuardrailAdvice {
	if editCount >= 3 {
		return &GuardrailAdvice{
			Type:     GuardrailPacing,
			Message:  "Take your time. You can always change this later. There's no rush to get it perfect.",
			Blocking: false,
		}
	}
	return nil
}

// CheckFlowDuration detects when the onboarding flow has taken too long.
// Returns advisory if minutes > 15.
func CheckFlowDuration(minutes int) *GuardrailAdvice {
	if minutes > 15 {
		return &GuardrailAdvice{
			Type:     GuardrailFlowDuration,
			Message:  "You've been working on this for a while. Consider taking a break and returning to it later.",
			Blocking: false,
		}
	}
	return nil
}

// CollectGuardrails runs all applicable guardrails on a circle set and returns advice.
// This is typically called before committing a set.
func CollectGuardrails(set *CircleSet, hasSponsorShare bool) []GuardrailAdvice {
	var advice []GuardrailAdvice

	// Check inner circle overload.
	if overload := CheckInnerCircleOverload(len(set.InnerCircle)); overload != nil {
		advice = append(advice, *overload)
	}

	// Check middle circle depth.
	if depth := CheckMiddleCircleDepth(len(set.MiddleCircle)); depth != nil {
		advice = append(advice, *depth)
	}

	// Check isolation.
	if isolation := CheckIsolation(hasSponsorShare); isolation != nil {
		advice = append(advice, *isolation)
	}

	// Check specificity for all items across all circles.
	for _, item := range set.InnerCircle {
		if spec := CheckSpecificity(item.BehaviorName); spec != nil {
			specWithID := *spec
			specWithID.ItemID = item.ItemID
			advice = append(advice, specWithID)
		}
	}
	for _, item := range set.MiddleCircle {
		if spec := CheckSpecificity(item.BehaviorName); spec != nil {
			specWithID := *spec
			specWithID.ItemID = item.ItemID
			advice = append(advice, specWithID)
		}
	}
	for _, item := range set.OuterCircle {
		if spec := CheckSpecificity(item.BehaviorName); spec != nil {
			specWithID := *spec
			specWithID.ItemID = item.ItemID
			advice = append(advice, specWithID)
		}
	}

	return advice
}
