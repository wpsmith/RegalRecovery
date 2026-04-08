// internal/domain/phonecalls/trends.go
package phonecalls

import (
	"math"
	"time"
)

// DefaultIsolationThresholdDays is the default number of days without a call
// before an isolation warning is triggered.
const DefaultIsolationThresholdDays = 3

// CalculateTrends computes phone call trends for a given period.
func CalculateTrends(calls []PhoneCall, period TrendPeriod, isolationThreshold int, timezone *time.Location) PhoneCallTrends {
	if timezone == nil {
		timezone = time.UTC
	}
	if isolationThreshold <= 0 {
		isolationThreshold = DefaultIsolationThresholdDays
	}

	now := time.Now().In(timezone)
	periodDays := periodToDays(period)
	periodStart := now.AddDate(0, 0, -periodDays)

	// Filter calls within the current period.
	currentCalls := filterCallsByDateRange(calls, periodStart, now)

	// Calculate basic counts.
	totalCalls := len(currentCalls)
	callsMade := 0
	callsReceived := 0
	connectedCalls := 0
	attemptedCalls := 0
	contactTypeCounts := make(map[ContactType]int)

	for _, call := range currentCalls {
		if call.Direction == DirectionMade {
			callsMade++
		} else {
			callsReceived++
		}
		if call.Connected {
			connectedCalls++
		} else {
			attemptedCalls++
		}
		contactTypeCounts[call.ContactType]++
	}

	// Connection rate: connected outgoing / total outgoing * 100.
	connectionRate := CalculateConnectionRate(currentCalls)

	// Average calls per week.
	weeks := float64(periodDays) / 7.0
	averageCallsPerWeek := 0.0
	if weeks > 0 {
		averageCallsPerWeek = math.Round(float64(totalCalls)/weeks*10) / 10
	}

	// Contact type distribution.
	distribution := buildContactTypeDistribution(contactTypeCounts, totalCalls)

	// Previous period comparison.
	prevStart := periodStart.AddDate(0, 0, -periodDays)
	prevCalls := filterCallsByDateRange(calls, prevStart, periodStart)
	comparison := calculatePeriodComparison(currentCalls, prevCalls)

	// Days since last call.
	daysSinceLastCall := calculateDaysSinceLastCall(calls, now, timezone)

	// Isolation warning.
	isolationWarning := daysSinceLastCall >= isolationThreshold

	return PhoneCallTrends{
		Period:                   period,
		TotalCalls:               totalCalls,
		CallsMade:                callsMade,
		CallsReceived:            callsReceived,
		ConnectedCalls:           connectedCalls,
		AttemptedCalls:           attemptedCalls,
		ConnectionRate:           connectionRate,
		AverageCallsPerWeek:      averageCallsPerWeek,
		ContactTypeDistribution:  distribution,
		PreviousPeriodComparison: comparison,
		DaysSinceLastCall:        daysSinceLastCall,
		IsolationWarning:         isolationWarning,
	}
}

// CalculateConnectionRate computes the percentage of outgoing calls that connected.
// Returns 0 if there are no outgoing calls.
func CalculateConnectionRate(calls []PhoneCall) float64 {
	totalOutgoing := 0
	connectedOutgoing := 0

	for _, call := range calls {
		if call.Direction == DirectionMade {
			totalOutgoing++
			if call.Connected {
				connectedOutgoing++
			}
		}
	}

	if totalOutgoing == 0 {
		return 0
	}

	rate := float64(connectedOutgoing) / float64(totalOutgoing) * 100
	return math.Round(rate*10) / 10
}

// CalculateDailyTrends computes per-day call counts for a given period.
func CalculateDailyTrends(calls []PhoneCall, period TrendPeriod, timezone *time.Location) []DailyCallCount {
	if timezone == nil {
		timezone = time.UTC
	}

	now := time.Now().In(timezone)
	periodDays := periodToDays(period)
	periodStart := now.AddDate(0, 0, -periodDays)

	// Initialize all days in the period.
	dailyCounts := make(map[string]*DailyCallCount)
	for d := periodStart; !d.After(now); d = d.AddDate(0, 0, 1) {
		dateStr := d.Format("2006-01-02")
		dailyCounts[dateStr] = &DailyCallCount{Date: dateStr}
	}

	// Tally calls by day.
	for _, call := range calls {
		localTime := call.Timestamp.In(timezone)
		dateStr := localTime.Format("2006-01-02")
		dc, exists := dailyCounts[dateStr]
		if !exists {
			continue
		}
		dc.TotalCalls++
		if call.Direction == DirectionMade {
			dc.CallsMade++
		} else {
			dc.CallsReceived++
		}
		if call.Connected {
			dc.ConnectedCalls++
		} else {
			dc.AttemptedCalls++
		}
	}

	// Convert map to sorted slice.
	result := make([]DailyCallCount, 0, len(dailyCounts))
	for d := periodStart; !d.After(now); d = d.AddDate(0, 0, 1) {
		dateStr := d.Format("2006-01-02")
		if dc, exists := dailyCounts[dateStr]; exists {
			result = append(result, *dc)
		}
	}

	return result
}

// filterCallsByDateRange returns calls within [start, end).
func filterCallsByDateRange(calls []PhoneCall, start, end time.Time) []PhoneCall {
	var filtered []PhoneCall
	for _, call := range calls {
		if !call.Timestamp.Before(start) && call.Timestamp.Before(end) {
			filtered = append(filtered, call)
		}
	}
	return filtered
}

// buildContactTypeDistribution builds the contact type distribution from counts.
func buildContactTypeDistribution(counts map[ContactType]int, total int) []ContactTypeCount {
	distribution := make([]ContactTypeCount, 0, len(counts))
	for ct, count := range counts {
		pct := 0.0
		if total > 0 {
			pct = math.Round(float64(count)/float64(total)*1000) / 10
		}
		distribution = append(distribution, ContactTypeCount{
			ContactType: ct,
			Count:       count,
			Percentage:  pct,
		})
	}
	return distribution
}

// calculatePeriodComparison compares current and previous period calls.
func calculatePeriodComparison(current, previous []PhoneCall) *PeriodComparison {
	currentRate := CalculateConnectionRate(current)
	prevRate := CalculateConnectionRate(previous)

	return &PeriodComparison{
		TotalCallsDelta:     len(current) - len(previous),
		ConnectionRateDelta: math.Round((currentRate-prevRate)*10) / 10,
	}
}

// calculateDaysSinceLastCall returns the number of days since the most recent call.
func calculateDaysSinceLastCall(calls []PhoneCall, now time.Time, timezone *time.Location) int {
	if len(calls) == 0 {
		return -1 // No calls ever logged.
	}

	var latest time.Time
	for _, call := range calls {
		if call.Timestamp.After(latest) {
			latest = call.Timestamp
		}
	}

	// Calculate day difference using calendar dates.
	latestDate := latest.In(timezone)
	nowDate := now.In(timezone)

	latestDay := time.Date(latestDate.Year(), latestDate.Month(), latestDate.Day(), 0, 0, 0, 0, timezone)
	nowDay := time.Date(nowDate.Year(), nowDate.Month(), nowDate.Day(), 0, 0, 0, 0, timezone)

	days := int(nowDay.Sub(latestDay).Hours() / 24)
	if days < 0 {
		return 0
	}
	return days
}

// periodToDays converts a TrendPeriod to a number of days.
func periodToDays(period TrendPeriod) int {
	switch period {
	case TrendPeriod7d:
		return 7
	case TrendPeriod30d:
		return 30
	case TrendPeriod90d:
		return 90
	default:
		return 30
	}
}
