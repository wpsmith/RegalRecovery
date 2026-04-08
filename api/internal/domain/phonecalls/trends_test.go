// internal/domain/phonecalls/trends_test.go
package phonecalls

import (
	"testing"
	"time"
)

// --- Connection Rate Tests ---

func TestTrends_AC_PC_61_ConnectionRate_CalculatesCorrectly(t *testing.T) {
	// Given 10 outgoing calls, 8 connected
	calls := make([]PhoneCall, 0, 10)
	now := time.Now().UTC()
	for i := 0; i < 8; i++ {
		calls = append(calls, PhoneCall{
			Direction: DirectionMade,
			Connected: true,
			Timestamp: now.Add(-time.Duration(i) * time.Hour),
		})
	}
	for i := 0; i < 2; i++ {
		calls = append(calls, PhoneCall{
			Direction: DirectionMade,
			Connected: false,
			Timestamp: now.Add(-time.Duration(i+8) * time.Hour),
		})
	}

	// When
	rate := CalculateConnectionRate(calls)

	// Then - 80%
	if rate != 80.0 {
		t.Errorf("expected connection rate 80.0, got %.1f", rate)
	}
}

func TestTrends_AC_PC_61_ConnectionRate_NoOutgoingCalls_ReturnsZero(t *testing.T) {
	// Given only incoming calls
	calls := []PhoneCall{
		{Direction: DirectionReceived, Connected: true, Timestamp: time.Now()},
		{Direction: DirectionReceived, Connected: false, Timestamp: time.Now()},
	}

	// When
	rate := CalculateConnectionRate(calls)

	// Then
	if rate != 0 {
		t.Errorf("expected connection rate 0 for no outgoing calls, got %.1f", rate)
	}
}

func TestTrends_AC_PC_61_ConnectionRate_AllConnected_Returns100(t *testing.T) {
	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, Timestamp: time.Now()},
		{Direction: DirectionMade, Connected: true, Timestamp: time.Now()},
		{Direction: DirectionMade, Connected: true, Timestamp: time.Now()},
	}

	rate := CalculateConnectionRate(calls)

	if rate != 100.0 {
		t.Errorf("expected connection rate 100.0, got %.1f", rate)
	}
}

// --- Trends Summary Tests ---

func TestTrends_AC_PC_60_WeeklySummary_CorrectTotals(t *testing.T) {
	now := time.Now().UTC()
	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, ContactType: ContactTypeSponsor, Timestamp: now.Add(-1 * 24 * time.Hour)},
		{Direction: DirectionMade, Connected: false, ContactType: ContactTypeSponsor, Timestamp: now.Add(-2 * 24 * time.Hour)},
		{Direction: DirectionReceived, Connected: true, ContactType: ContactTypeAccountabilityPartner, Timestamp: now.Add(-3 * 24 * time.Hour)},
	}

	trends := CalculateTrends(calls, TrendPeriod7d, DefaultIsolationThresholdDays, time.UTC)

	if trends.TotalCalls != 3 {
		t.Errorf("expected total calls 3, got %d", trends.TotalCalls)
	}
	if trends.CallsMade != 2 {
		t.Errorf("expected calls made 2, got %d", trends.CallsMade)
	}
	if trends.CallsReceived != 1 {
		t.Errorf("expected calls received 1, got %d", trends.CallsReceived)
	}
	if trends.ConnectedCalls != 2 {
		t.Errorf("expected connected calls 2, got %d", trends.ConnectedCalls)
	}
	if trends.AttemptedCalls != 1 {
		t.Errorf("expected attempted calls 1, got %d", trends.AttemptedCalls)
	}
}

func TestTrends_AC_PC_60_WeeklySummary_PreviousWeekComparison(t *testing.T) {
	now := time.Now().UTC()
	calls := []PhoneCall{
		// Current period (last 7 days): 2 calls
		{Direction: DirectionMade, Connected: true, Timestamp: now.Add(-1 * 24 * time.Hour)},
		{Direction: DirectionMade, Connected: true, Timestamp: now.Add(-2 * 24 * time.Hour)},
		// Previous period (8-14 days ago): 1 call
		{Direction: DirectionMade, Connected: true, Timestamp: now.Add(-10 * 24 * time.Hour)},
	}

	trends := CalculateTrends(calls, TrendPeriod7d, DefaultIsolationThresholdDays, time.UTC)

	if trends.PreviousPeriodComparison == nil {
		t.Fatal("expected previous period comparison to be set")
	}
	if trends.PreviousPeriodComparison.TotalCallsDelta != 1 {
		t.Errorf("expected totalCallsDelta 1, got %d", trends.PreviousPeriodComparison.TotalCallsDelta)
	}
}

// --- Contact Type Distribution Tests ---

func TestTrends_AC_PC_62_ContactTypeDistribution_CorrectPercentages(t *testing.T) {
	now := time.Now().UTC()
	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, ContactType: ContactTypeSponsor, Timestamp: now.Add(-1 * time.Hour)},
		{Direction: DirectionMade, Connected: true, ContactType: ContactTypeSponsor, Timestamp: now.Add(-2 * time.Hour)},
		{Direction: DirectionMade, Connected: true, ContactType: ContactTypeAccountabilityPartner, Timestamp: now.Add(-3 * time.Hour)},
		{Direction: DirectionMade, Connected: true, ContactType: ContactTypeCounselor, Timestamp: now.Add(-4 * time.Hour)},
	}

	trends := CalculateTrends(calls, TrendPeriod7d, DefaultIsolationThresholdDays, time.UTC)

	// Check that distribution is populated.
	if len(trends.ContactTypeDistribution) == 0 {
		t.Fatal("expected non-empty contact type distribution")
	}

	// Find sponsor count.
	found := false
	for _, ctc := range trends.ContactTypeDistribution {
		if ctc.ContactType == ContactTypeSponsor {
			found = true
			if ctc.Count != 2 {
				t.Errorf("expected sponsor count 2, got %d", ctc.Count)
			}
			if ctc.Percentage != 50.0 {
				t.Errorf("expected sponsor percentage 50.0, got %.1f", ctc.Percentage)
			}
		}
	}
	if !found {
		t.Error("expected sponsor in contact type distribution")
	}
}

func TestTrends_AC_PC_62_ContactTypeDistribution_SingleType_Returns100Percent(t *testing.T) {
	now := time.Now().UTC()
	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, ContactType: ContactTypeSponsor, Timestamp: now.Add(-1 * time.Hour)},
		{Direction: DirectionMade, Connected: true, ContactType: ContactTypeSponsor, Timestamp: now.Add(-2 * time.Hour)},
	}

	trends := CalculateTrends(calls, TrendPeriod7d, DefaultIsolationThresholdDays, time.UTC)

	if len(trends.ContactTypeDistribution) != 1 {
		t.Fatalf("expected 1 contact type, got %d", len(trends.ContactTypeDistribution))
	}
	if trends.ContactTypeDistribution[0].Percentage != 100.0 {
		t.Errorf("expected 100%% for single type, got %.1f%%", trends.ContactTypeDistribution[0].Percentage)
	}
}

// --- Isolation Warning Tests ---

func TestTrends_AC_PC_63_IsolationWarning_ThresholdReached_ReturnsTrue(t *testing.T) {
	// Given no calls for 4 days (threshold = 3)
	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, Timestamp: time.Now().UTC().AddDate(0, 0, -4)},
	}

	trends := CalculateTrends(calls, TrendPeriod30d, 3, time.UTC)

	if !trends.IsolationWarning {
		t.Error("expected isolation warning to be true when threshold reached")
	}
	if trends.DaysSinceLastCall < 3 {
		t.Errorf("expected daysSinceLastCall >= 3, got %d", trends.DaysSinceLastCall)
	}
}

func TestTrends_AC_PC_63_IsolationWarning_BelowThreshold_ReturnsFalse(t *testing.T) {
	// Given call today (threshold = 3)
	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, Timestamp: time.Now().UTC()},
	}

	trends := CalculateTrends(calls, TrendPeriod30d, 3, time.UTC)

	if trends.IsolationWarning {
		t.Error("expected isolation warning to be false when below threshold")
	}
}

func TestTrends_AC_PC_64_IsolationWarning_CustomThreshold_Respected(t *testing.T) {
	// Given no calls for 4 days with custom threshold of 5
	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, Timestamp: time.Now().UTC().AddDate(0, 0, -4)},
	}

	trends := CalculateTrends(calls, TrendPeriod30d, 5, time.UTC)

	// 4 days since last call < 5 threshold
	if trends.IsolationWarning {
		t.Error("expected no isolation warning with custom threshold of 5 and 4 days gap")
	}
}

// --- Daily Breakdown Tests ---

func TestTrends_DailyBreakdown_CorrectPerDayCounts(t *testing.T) {
	now := time.Now().UTC()
	todayStr := now.Format("2006-01-02")

	calls := []PhoneCall{
		{Direction: DirectionMade, Connected: true, Timestamp: now.Add(-1 * time.Hour)},
		{Direction: DirectionReceived, Connected: false, Timestamp: now.Add(-2 * time.Hour)},
	}

	daily := CalculateDailyTrends(calls, TrendPeriod7d, time.UTC)

	// Find today's entry.
	found := false
	for _, d := range daily {
		if d.Date == todayStr {
			found = true
			if d.TotalCalls != 2 {
				t.Errorf("expected 2 calls today, got %d", d.TotalCalls)
			}
			if d.CallsMade != 1 {
				t.Errorf("expected 1 call made today, got %d", d.CallsMade)
			}
			if d.CallsReceived != 1 {
				t.Errorf("expected 1 call received today, got %d", d.CallsReceived)
			}
			if d.ConnectedCalls != 1 {
				t.Errorf("expected 1 connected call today, got %d", d.ConnectedCalls)
			}
			if d.AttemptedCalls != 1 {
				t.Errorf("expected 1 attempted call today, got %d", d.AttemptedCalls)
			}
		}
	}
	if !found {
		t.Error("today's date not found in daily breakdown")
	}
}

func TestTrends_EmptyPeriod_ReturnsZeros(t *testing.T) {
	calls := []PhoneCall{}

	trends := CalculateTrends(calls, TrendPeriod30d, DefaultIsolationThresholdDays, time.UTC)

	if trends.TotalCalls != 0 {
		t.Errorf("expected 0 total calls for empty period, got %d", trends.TotalCalls)
	}
	if trends.ConnectionRate != 0 {
		t.Errorf("expected 0 connection rate for empty period, got %.1f", trends.ConnectionRate)
	}
}
