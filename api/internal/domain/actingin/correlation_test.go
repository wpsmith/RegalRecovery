// internal/domain/actingin/correlation_test.go
package actingin

import (
	"testing"
	"time"
)

// TestCorrelation_AC_AIB_036_PciElevatedWithActingIn verifies that elevated PCI
// scores on the same day as high acting-in count returns a correlation.
//
// AC-AIB-036: Elevated PCI scores coincide with increased acting-in behaviors.
func TestCorrelation_AC_AIB_036_PciElevatedWithActingIn(t *testing.T) {
	now := time.Now().UTC()

	checkIns := []CheckIn{
		{
			Timestamp:     now.AddDate(0, 0, -1),
			BehaviorCount: 3,
			Behaviors: []CheckedBehavior{
				{BehaviorID: "a"}, {BehaviorID: "b"}, {BehaviorID: "c"},
			},
		},
		{
			Timestamp:     now.AddDate(0, 0, -2),
			BehaviorCount: 4,
			Behaviors: []CheckedBehavior{
				{BehaviorID: "a"}, {BehaviorID: "b"}, {BehaviorID: "c"}, {BehaviorID: "d"},
			},
		},
	}

	pciData := []PciDayData{
		{Date: now.AddDate(0, 0, -1), Score: 7},
		{Date: now.AddDate(0, 0, -2), Score: 8},
		{Date: now.AddDate(0, 0, -3), Score: 2}, // Low PCI, no acting-in.
	}

	result := CalculatePciCorrelation(checkIns, pciData, Range30d)

	if !result.CorrelationFound {
		t.Error("expected correlation to be found")
	}
	if result.PciElevatedDays != 2 {
		t.Errorf("expected 2 elevated PCI days, got %d", result.PciElevatedDays)
	}
	if result.Narrative == "" {
		t.Error("expected narrative to be non-empty")
	}
}

// TestCorrelation_AC_AIB_037_FasterStageCorrelation verifies that acting-in
// spikes during Anxiety/Ticked stages are detected.
//
// AC-AIB-037: FASTER stages (particularly Anxiety and Ticked Off) correlate with acting-in spikes.
func TestCorrelation_AC_AIB_037_FasterStageCorrelation(t *testing.T) {
	now := time.Now().UTC()

	checkIns := []CheckIn{
		{
			Timestamp:     now.AddDate(0, 0, -1),
			BehaviorCount: 5,
			Behaviors:     []CheckedBehavior{{BehaviorID: "a"}, {BehaviorID: "b"}, {BehaviorID: "c"}, {BehaviorID: "d"}, {BehaviorID: "e"}},
		},
		{
			Timestamp:     now.AddDate(0, 0, -3),
			BehaviorCount: 1,
			Behaviors:     []CheckedBehavior{{BehaviorID: "a"}},
		},
	}

	fasterData := []FasterEntry{
		{Date: now.AddDate(0, 0, -1), Stage: "A"}, // Anxiety.
		{Date: now.AddDate(0, 0, -3), Stage: "restoration"},
	}

	result := CalculateFasterCorrelation(checkIns, fasterData, Range30d)

	if !result.CorrelationFound {
		t.Error("expected FASTER correlation to be found")
	}
	if len(result.StageBreakdown) == 0 {
		t.Error("expected stage breakdown to be non-empty")
	}

	// Check that A stage has the most acting-in.
	found := false
	for _, s := range result.StageBreakdown {
		if s.Stage == "A" && s.ActingInCount == 5 {
			found = true
		}
	}
	if !found {
		t.Error("expected stage A to have 5 acting-in behaviors")
	}
}

// TestCorrelation_AC_AIB_038_PostMortemBuildUp verifies that acting-in behaviors
// in the build-up phase of past relapses are identified.
//
// AC-AIB-038: Acting-in behaviors identified in the build-up phase of past relapses.
func TestCorrelation_AC_AIB_038_PostMortemBuildUp(t *testing.T) {
	now := time.Now().UTC()
	relapseDate := now.AddDate(0, 0, -30)
	buildUpStart := relapseDate.AddDate(0, 0, -14) // 2 weeks before relapse.

	checkIns := []CheckIn{
		{
			Timestamp:     buildUpStart.AddDate(0, 0, 3),
			BehaviorCount: 2,
			Behaviors: []CheckedBehavior{
				{BehaviorID: "beh_default_stonewall", BehaviorName: "Stonewall"},
				{BehaviorID: "beh_default_avoid", BehaviorName: "Avoid"},
			},
		},
		{
			Timestamp:     buildUpStart.AddDate(0, 0, 7),
			BehaviorCount: 1,
			Behaviors: []CheckedBehavior{
				{BehaviorID: "beh_default_hide", BehaviorName: "Hide"},
			},
		},
	}

	postMortems := []PostMortemEntry{
		{
			PostMortemID: "pm_001",
			RelapseDate:  relapseDate,
			BuildUpStart: buildUpStart,
			BuildUpEnd:   relapseDate,
		},
	}

	patterns := CalculatePostMortemPatterns(checkIns, postMortems)

	if len(patterns) != 1 {
		t.Fatalf("expected 1 pattern, got %d", len(patterns))
	}
	if len(patterns[0].BuildUpBehaviors) != 3 {
		t.Errorf("expected 3 build-up behaviors, got %d", len(patterns[0].BuildUpBehaviors))
	}
}

// TestCorrelation_NoPci_ReturnsNoCorrelation verifies that missing PCI data
// returns correlationFound=false.
func TestCorrelation_NoPci_ReturnsNoCorrelation(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{{BehaviorID: "a", BehaviorName: "A"}}),
	}

	result := CalculatePciCorrelation(checkIns, nil, Range30d)
	if result.CorrelationFound {
		t.Error("expected correlationFound=false with no PCI data")
	}
}

// TestCorrelation_NoFaster_ReturnsNoCorrelation verifies that missing FASTER data
// returns correlationFound=false.
func TestCorrelation_NoFaster_ReturnsNoCorrelation(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{{BehaviorID: "a", BehaviorName: "A"}}),
	}

	result := CalculateFasterCorrelation(checkIns, nil, Range30d)
	if result.CorrelationFound {
		t.Error("expected correlationFound=false with no FASTER data")
	}
}

// TestCorrelation_NoPostMortems_ReturnsEmpty verifies that no post-mortem data
// returns an empty patterns slice.
func TestCorrelation_NoPostMortems_ReturnsEmpty(t *testing.T) {
	checkIns := []CheckIn{
		makeCheckIn(1, []CheckedBehavior{{BehaviorID: "a", BehaviorName: "A"}}),
	}

	patterns := CalculatePostMortemPatterns(checkIns, nil)
	if len(patterns) != 0 {
		t.Errorf("expected 0 patterns, got %d", len(patterns))
	}
}
