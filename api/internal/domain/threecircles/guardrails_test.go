// internal/domain/threecircles/guardrails_test.go
package threecircles

import (
	"testing"
	"time"
)

func TestCheckSpecificity_TooFewWords(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name          string
		behaviorName  string
		expectAdvice  bool
	}{
		{
			name:         "empty string",
			behaviorName: "",
			expectAdvice: false,
		},
		{
			name:         "one word",
			behaviorName: "pornography",
			expectAdvice: true,
		},
		{
			name:         "two words",
			behaviorName: "watch pornography",
			expectAdvice: true,
		},
		{
			name:         "three words",
			behaviorName: "watch adult content",
			expectAdvice: true,
		},
		{
			name:         "four words",
			behaviorName: "watch adult content online",
			expectAdvice: true,
		},
		{
			name:         "five words",
			behaviorName: "watch adult content online alone",
			expectAdvice: false,
		},
		{
			name:         "six words",
			behaviorName: "watch adult content online alone late",
			expectAdvice: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			advice := CheckSpecificity(tt.behaviorName)
			if tt.expectAdvice && advice == nil {
				t.Errorf("expected advice, got nil")
			}
			if !tt.expectAdvice && advice != nil {
				t.Errorf("expected no advice, got %+v", advice)
			}
			if advice != nil {
				if advice.Type != GuardrailSpecificity {
					t.Errorf("expected type %s, got %s", GuardrailSpecificity, advice.Type)
				}
				if advice.Blocking {
					t.Errorf("expected non-blocking advice")
				}
			}
		})
	}
}

func TestCheckSpecificity_VagueKeywords(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name          string
		behaviorName  string
		expectAdvice  bool
	}{
		{
			name:         "contains 'be' at start",
			behaviorName: "be more accountable with my sponsor regularly",
			expectAdvice: true,
		},
		{
			name:         "contains 'stop' in middle",
			behaviorName: "I need to stop looking at things online",
			expectAdvice: true,
		},
		{
			name:         "contains 'better' at end",
			behaviorName: "I want to be better",
			expectAdvice: true,
		},
		{
			name:         "contains 'good' as whole word",
			behaviorName: "this is a good habit to maintain",
			expectAdvice: true,
		},
		{
			name:         "contains 'bad' as standalone",
			behaviorName: "bad",
			expectAdvice: true,
		},
		{
			name:         "contains 'right' in context",
			behaviorName: "do the right thing every single time",
			expectAdvice: true,
		},
		{
			name:         "contains 'wrong' in context",
			behaviorName: "avoid doing the wrong thing with computers",
			expectAdvice: true,
		},
		{
			name:         "specific behavior without vague keywords",
			behaviorName: "viewing sexually explicit images alone on my phone after 10pm",
			expectAdvice: false,
		},
		{
			name:         "contains substring but not whole word (goodbye)",
			behaviorName: "say goodbye to unhealthy patterns when triggered",
			expectAdvice: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			advice := CheckSpecificity(tt.behaviorName)
			if tt.expectAdvice && advice == nil {
				t.Errorf("expected advice for '%s', got nil", tt.behaviorName)
			}
			if !tt.expectAdvice && advice != nil {
				t.Errorf("expected no advice for '%s', got %+v", tt.behaviorName, advice)
			}
		})
	}
}

func TestCheckInnerCircleOverload(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name         string
		count        int
		expectAdvice bool
		expectBlock  bool
	}{
		{
			name:         "zero items",
			count:        0,
			expectAdvice: false,
			expectBlock:  false,
		},
		{
			name:         "five items",
			count:        5,
			expectAdvice: false,
			expectBlock:  false,
		},
		{
			name:         "eight items (boundary)",
			count:        8,
			expectAdvice: false,
			expectBlock:  false,
		},
		{
			name:         "nine items (soft warning)",
			count:        9,
			expectAdvice: true,
			expectBlock:  false,
		},
		{
			name:         "fifteen items (soft warning)",
			count:        15,
			expectAdvice: true,
			expectBlock:  false,
		},
		{
			name:         "twenty items (boundary)",
			count:        20,
			expectAdvice: false,
			expectBlock:  false,
		},
		{
			name:         "twenty-one items (hard error)",
			count:        21,
			expectAdvice: true,
			expectBlock:  true,
		},
		{
			name:         "thirty items (hard error)",
			count:        30,
			expectAdvice: true,
			expectBlock:  true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			advice := CheckInnerCircleOverload(tt.count)
			if tt.expectAdvice && advice == nil {
				t.Errorf("expected advice, got nil")
			}
			if !tt.expectAdvice && advice != nil {
				t.Errorf("expected no advice, got %+v", advice)
			}
			if advice != nil {
				if advice.Type != GuardrailOverload {
					t.Errorf("expected type %s, got %s", GuardrailOverload, advice.Type)
				}
				if advice.Blocking != tt.expectBlock {
					t.Errorf("expected blocking=%v, got %v", tt.expectBlock, advice.Blocking)
				}
			}
		})
	}
}

func TestCheckMiddleCircleDepth(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name         string
		count        int
		expectAdvice bool
	}{
		{
			name:         "zero items",
			count:        0,
			expectAdvice: true,
		},
		{
			name:         "one item",
			count:        1,
			expectAdvice: true,
		},
		{
			name:         "two items",
			count:        2,
			expectAdvice: true,
		},
		{
			name:         "three items (boundary)",
			count:        3,
			expectAdvice: false,
		},
		{
			name:         "five items",
			count:        5,
			expectAdvice: false,
		},
		{
			name:         "ten items",
			count:        10,
			expectAdvice: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			advice := CheckMiddleCircleDepth(tt.count)
			if tt.expectAdvice && advice == nil {
				t.Errorf("expected advice, got nil")
			}
			if !tt.expectAdvice && advice != nil {
				t.Errorf("expected no advice, got %+v", advice)
			}
			if advice != nil {
				if advice.Type != GuardrailMiddleCircleDepth {
					t.Errorf("expected type %s, got %s", GuardrailMiddleCircleDepth, advice.Type)
				}
				if advice.Blocking {
					t.Errorf("expected non-blocking advice")
				}
			}
		})
	}
}

func TestCheckIsolation(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name            string
		hasSponsorShare bool
		expectAdvice    bool
	}{
		{
			name:            "no sponsor share",
			hasSponsorShare: false,
			expectAdvice:    true,
		},
		{
			name:            "has sponsor share",
			hasSponsorShare: true,
			expectAdvice:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			advice := CheckIsolation(tt.hasSponsorShare)
			if tt.expectAdvice && advice == nil {
				t.Errorf("expected advice, got nil")
			}
			if !tt.expectAdvice && advice != nil {
				t.Errorf("expected no advice, got %+v", advice)
			}
			if advice != nil {
				if advice.Type != GuardrailIsolation {
					t.Errorf("expected type %s, got %s", GuardrailIsolation, advice.Type)
				}
				if advice.Blocking {
					t.Errorf("expected non-blocking advice")
				}
			}
		})
	}
}

func TestCheckInnerCircleAddition(t *testing.T) {
	t.Parallel()

	advice := CheckInnerCircleAddition()
	if advice == nil {
		t.Fatal("expected advice, got nil")
	}
	if advice.Type != GuardrailInnerCircleAdd {
		t.Errorf("expected type %s, got %s", GuardrailInnerCircleAdd, advice.Type)
	}
	if advice.Blocking {
		t.Errorf("expected non-blocking advice")
	}
	if advice.Message == "" {
		t.Errorf("expected non-empty message")
	}
}

func TestCheckInnerCircleRemoval(t *testing.T) {
	t.Parallel()

	advice := CheckInnerCircleRemoval()
	if advice == nil {
		t.Fatal("expected advice, got nil")
	}
	if advice.Type != GuardrailInnerCircleRemove {
		t.Errorf("expected type %s, got %s", GuardrailInnerCircleRemove, advice.Type)
	}
	if advice.Blocking {
		t.Errorf("expected non-blocking advice")
	}
	if advice.Message == "" {
		t.Errorf("expected non-empty message")
	}
}

func TestCheckPacing(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name         string
		editCount    int
		expectAdvice bool
	}{
		{
			name:         "zero edits",
			editCount:    0,
			expectAdvice: false,
		},
		{
			name:         "one edit",
			editCount:    1,
			expectAdvice: false,
		},
		{
			name:         "two edits",
			editCount:    2,
			expectAdvice: false,
		},
		{
			name:         "three edits (boundary)",
			editCount:    3,
			expectAdvice: true,
		},
		{
			name:         "five edits",
			editCount:    5,
			expectAdvice: true,
		},
		{
			name:         "ten edits",
			editCount:    10,
			expectAdvice: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			advice := CheckPacing(tt.editCount)
			if tt.expectAdvice && advice == nil {
				t.Errorf("expected advice, got nil")
			}
			if !tt.expectAdvice && advice != nil {
				t.Errorf("expected no advice, got %+v", advice)
			}
			if advice != nil {
				if advice.Type != GuardrailPacing {
					t.Errorf("expected type %s, got %s", GuardrailPacing, advice.Type)
				}
				if advice.Blocking {
					t.Errorf("expected non-blocking advice")
				}
			}
		})
	}
}

func TestCheckFlowDuration(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name         string
		minutes      int
		expectAdvice bool
	}{
		{
			name:         "zero minutes",
			minutes:      0,
			expectAdvice: false,
		},
		{
			name:         "five minutes",
			minutes:      5,
			expectAdvice: false,
		},
		{
			name:         "fifteen minutes (boundary)",
			minutes:      15,
			expectAdvice: false,
		},
		{
			name:         "sixteen minutes",
			minutes:      16,
			expectAdvice: true,
		},
		{
			name:         "thirty minutes",
			minutes:      30,
			expectAdvice: true,
		},
		{
			name:         "sixty minutes",
			minutes:      60,
			expectAdvice: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			advice := CheckFlowDuration(tt.minutes)
			if tt.expectAdvice && advice == nil {
				t.Errorf("expected advice, got nil")
			}
			if !tt.expectAdvice && advice != nil {
				t.Errorf("expected no advice, got %+v", advice)
			}
			if advice != nil {
				if advice.Type != GuardrailFlowDuration {
					t.Errorf("expected type %s, got %s", GuardrailFlowDuration, advice.Type)
				}
				if advice.Blocking {
					t.Errorf("expected non-blocking advice")
				}
			}
		})
	}
}

func TestCollectGuardrails_EmptySet(t *testing.T) {
	t.Parallel()

	set := &CircleSet{
		ID:           "set-1",
		UserID:       "user-1",
		TenantID:     "tenant-1",
		Name:         "My Set",
		InnerCircle:  []CircleItem{},
		MiddleCircle: []CircleItem{},
		OuterCircle:  []CircleItem{},
		CreatedAt:    time.Now(),
		ModifiedAt:   time.Now(),
	}

	advice := CollectGuardrails(set, false)

	// Expect middle circle depth advice and isolation advice.
	if len(advice) < 2 {
		t.Errorf("expected at least 2 pieces of advice, got %d", len(advice))
	}

	hasMiddleDepth := false
	hasIsolation := false
	for _, a := range advice {
		if a.Type == GuardrailMiddleCircleDepth {
			hasMiddleDepth = true
		}
		if a.Type == GuardrailIsolation {
			hasIsolation = true
		}
	}

	if !hasMiddleDepth {
		t.Errorf("expected middle circle depth advice")
	}
	if !hasIsolation {
		t.Errorf("expected isolation advice")
	}
}

func TestCollectGuardrails_InnerCircleOverload(t *testing.T) {
	t.Parallel()

	// Create a set with 10 inner circle items (should trigger soft warning).
	innerCircle := make([]CircleItem, 10)
	for i := 0; i < 10; i++ {
		innerCircle[i] = CircleItem{
			ItemID:       "item-" + string(rune('0'+i)),
			BehaviorName: "Specific behavior with enough words to avoid specificity warning",
			CreatedAt:    time.Now(),
			ModifiedAt:   time.Now(),
		}
	}

	set := &CircleSet{
		ID:           "set-1",
		UserID:       "user-1",
		TenantID:     "tenant-1",
		Name:         "My Set",
		InnerCircle:  innerCircle,
		MiddleCircle: []CircleItem{
			{ItemID: "m1", BehaviorName: "Middle circle behavior with enough words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
			{ItemID: "m2", BehaviorName: "Another middle circle behavior with words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
			{ItemID: "m3", BehaviorName: "Yet another middle circle behavior words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
		},
		OuterCircle: []CircleItem{},
		CreatedAt:   time.Now(),
		ModifiedAt:  time.Now(),
	}

	advice := CollectGuardrails(set, true)

	// Should have overload warning.
	hasOverload := false
	for _, a := range advice {
		if a.Type == GuardrailOverload {
			hasOverload = true
			if a.Blocking {
				t.Errorf("expected non-blocking advice for 10 items")
			}
		}
	}

	if !hasOverload {
		t.Errorf("expected overload advice for 10 inner circle items")
	}
}

func TestCollectGuardrails_SpecificityChecks(t *testing.T) {
	t.Parallel()

	set := &CircleSet{
		ID:       "set-1",
		UserID:   "user-1",
		TenantID: "tenant-1",
		Name:     "My Set",
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "stop", CreatedAt: time.Now(), ModifiedAt: time.Now()}, // Vague
		},
		MiddleCircle: []CircleItem{
			{ItemID: "m1", BehaviorName: "be better", CreatedAt: time.Now(), ModifiedAt: time.Now()}, // Vague
			{ItemID: "m2", BehaviorName: "Specific behavior with enough words to pass", CreatedAt: time.Now(), ModifiedAt: time.Now()},
			{ItemID: "m3", BehaviorName: "Another specific behavior with enough words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
		},
		OuterCircle: []CircleItem{
			{ItemID: "o1", BehaviorName: "good", CreatedAt: time.Now(), ModifiedAt: time.Now()}, // Vague
		},
		CreatedAt:  time.Now(),
		ModifiedAt: time.Now(),
	}

	advice := CollectGuardrails(set, true)

	// Should have 3 specificity warnings (i1, m1, o1).
	specificityCount := 0
	for _, a := range advice {
		if a.Type == GuardrailSpecificity {
			specificityCount++
		}
	}

	if specificityCount != 3 {
		t.Errorf("expected 3 specificity warnings, got %d", specificityCount)
	}
}

func TestCollectGuardrails_WithSponsorShare(t *testing.T) {
	t.Parallel()

	set := &CircleSet{
		ID:       "set-1",
		UserID:   "user-1",
		TenantID: "tenant-1",
		Name:     "My Set",
		InnerCircle: []CircleItem{
			{ItemID: "i1", BehaviorName: "Specific inner circle behavior with words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
		},
		MiddleCircle: []CircleItem{
			{ItemID: "m1", BehaviorName: "Specific middle circle behavior with words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
			{ItemID: "m2", BehaviorName: "Another middle circle behavior with words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
			{ItemID: "m3", BehaviorName: "Yet another middle circle behavior words", CreatedAt: time.Now(), ModifiedAt: time.Now()},
		},
		OuterCircle: []CircleItem{},
		CreatedAt:   time.Now(),
		ModifiedAt:  time.Now(),
	}

	advice := CollectGuardrails(set, true)

	// Should NOT have isolation advice.
	for _, a := range advice {
		if a.Type == GuardrailIsolation {
			t.Errorf("expected no isolation advice when sponsor share is true")
		}
	}
}
