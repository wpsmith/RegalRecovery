// internal/domain/personcheckin/trends.go
package personcheckin

import (
	"fmt"
	"math"
	"sort"
	"time"
)

// CalculateTrends computes all trend data from a list of check-ins.
func CalculateTrends(checkIns []PersonCheckIn, period string, now time.Time) TrendsData {
	days := periodDays(period)
	startDate := now.AddDate(0, 0, -days)

	// Filter to period.
	var filtered []PersonCheckIn
	for _, ci := range checkIns {
		if !ci.Timestamp.Before(startDate) && !ci.Timestamp.After(now) {
			filtered = append(filtered, ci)
		}
	}

	return TrendsData{
		Frequency:          calculateFrequency(filtered, startDate, now),
		MethodDistribution: calculateMethodDistribution(filtered),
		QualityTrends:      calculateQualityTrends(filtered, startDate, now),
		TopicFrequency:     calculateTopicFrequency(filtered),
		Balance:            calculateBalance(filtered),
	}
}

func periodDays(period string) int {
	switch period {
	case "7d":
		return 7
	case "30d":
		return 30
	case "90d":
		return 90
	default:
		return 30
	}
}

func calculateFrequency(checkIns []PersonCheckIn, startDate, endDate time.Time) []FrequencyDataPoint {
	// Build a map of date -> counts per type.
	dayCounts := make(map[string]map[CheckInType]int)

	for _, ci := range checkIns {
		day := ci.Timestamp.Format("2006-01-02")
		if dayCounts[day] == nil {
			dayCounts[day] = make(map[CheckInType]int)
		}
		dayCounts[day][ci.CheckInType]++
	}

	// Generate data points for each day in the range.
	var points []FrequencyDataPoint
	current := startDate
	for !current.After(endDate) {
		day := current.Format("2006-01-02")
		counts := dayCounts[day]
		points = append(points, FrequencyDataPoint{
			Date:           day,
			Spouse:         counts[CheckInTypeSpouse],
			Sponsor:        counts[CheckInTypeSponsor],
			CounselorCoach: counts[CheckInTypeCounselorCoach],
		})
		current = current.AddDate(0, 0, 1)
	}

	return points
}

func calculateMethodDistribution(checkIns []PersonCheckIn) map[string]map[string]int {
	dist := make(map[string]map[string]int)

	for _, ci := range checkIns {
		typeKey := string(ci.CheckInType)
		if dist[typeKey] == nil {
			dist[typeKey] = map[string]int{
				string(MethodInPerson):     0,
				string(MethodPhoneCall):    0,
				string(MethodVideoCall):    0,
				string(MethodTextMessage):  0,
				string(MethodAppMessaging): 0,
			}
		}
		dist[typeKey][string(ci.Method)]++
	}

	return dist
}

func calculateQualityTrends(checkIns []PersonCheckIn, startDate, endDate time.Time) map[string]QualityTrendData {
	trends := make(map[string]QualityTrendData)

	// Group by type.
	typeCheckIns := make(map[CheckInType][]PersonCheckIn)
	for _, ci := range checkIns {
		if ci.QualityRating != nil {
			typeCheckIns[ci.CheckInType] = append(typeCheckIns[ci.CheckInType], ci)
		}
	}

	for ciType, cis := range typeCheckIns {
		if len(cis) == 0 {
			continue
		}

		// Sort by timestamp.
		sort.Slice(cis, func(i, j int) bool {
			return cis[i].Timestamp.Before(cis[j].Timestamp)
		})

		// Calculate overall average.
		var totalRating int
		for _, ci := range cis {
			totalRating += *ci.QualityRating
		}
		avgRating := float64(totalRating) / float64(len(cis))

		// Calculate data points (bi-weekly averages for 30d, weekly for 7d).
		dataPoints := calculateQualityDataPoints(cis, startDate, endDate)

		// Determine trend.
		trend := determineTrend(dataPoints)

		trends[string(ciType)] = QualityTrendData{
			AverageRating: math.Round(avgRating*10) / 10,
			Trend:         trend,
			DataPoints:    dataPoints,
		}
	}

	return trends
}

func calculateQualityDataPoints(checkIns []PersonCheckIn, startDate, endDate time.Time) []QualityDataPoint {
	totalDays := int(endDate.Sub(startDate).Hours()/24) + 1

	// Use bi-weekly buckets for periods > 14 days, weekly for shorter.
	bucketDays := 14
	if totalDays <= 14 {
		bucketDays = 7
	}

	var points []QualityDataPoint
	bucketStart := startDate

	for bucketStart.Before(endDate) {
		bucketEnd := bucketStart.AddDate(0, 0, bucketDays)
		if bucketEnd.After(endDate) {
			bucketEnd = endDate.AddDate(0, 0, 1)
		}

		var sum, count int
		for _, ci := range checkIns {
			if ci.QualityRating != nil && !ci.Timestamp.Before(bucketStart) && ci.Timestamp.Before(bucketEnd) {
				sum += *ci.QualityRating
				count++
			}
		}

		if count > 0 {
			avg := float64(sum) / float64(count)
			points = append(points, QualityDataPoint{
				Date:    bucketStart.Format("2006-01-02"),
				Average: math.Round(avg*10) / 10,
			})
		}

		bucketStart = bucketEnd
	}

	return points
}

func determineTrend(points []QualityDataPoint) QualityTrend {
	if len(points) < 2 {
		return QualityTrendStable
	}

	first := points[0].Average
	last := points[len(points)-1].Average

	diff := last - first
	if diff > 0.3 {
		return QualityTrendImproving
	} else if diff < -0.3 {
		return QualityTrendDeclining
	}
	return QualityTrendStable
}

func calculateTopicFrequency(checkIns []PersonCheckIn) []TopicFrequency {
	topicCounts := make(map[string]int)
	for _, ci := range checkIns {
		for _, topic := range ci.TopicsDiscussed {
			topicCounts[string(topic)]++
		}
	}

	var frequencies []TopicFrequency
	for topic, count := range topicCounts {
		frequencies = append(frequencies, TopicFrequency{
			Topic: topic,
			Count: count,
		})
	}

	// Sort by count descending.
	sort.Slice(frequencies, func(i, j int) bool {
		return frequencies[i].Count > frequencies[j].Count
	})

	return frequencies
}

func calculateBalance(checkIns []PersonCheckIn) BalanceData {
	counts := make(map[CheckInType]int)
	for _, ci := range checkIns {
		counts[ci.CheckInType]++
	}

	balance := BalanceData{
		Spouse:         counts[CheckInTypeSpouse],
		Sponsor:        counts[CheckInTypeSponsor],
		CounselorCoach: counts[CheckInTypeCounselorCoach],
	}

	// Detect gaps: find the max and check if any type is significantly below.
	activeTypes := 0
	maxCount := 0
	for _, count := range counts {
		if count > 0 {
			activeTypes++
		}
		if count > maxCount {
			maxCount = count
		}
	}

	if activeTypes >= 2 {
		threshold := float64(maxCount) * 0.3 // Gap if < 30% of max.

		typeNames := map[CheckInType]string{
			CheckInTypeSpouse:        "spouse",
			CheckInTypeSponsor:       "sponsor",
			CheckInTypeCounselorCoach: "counselor-coach",
		}
		typeDisplayNames := map[CheckInType]string{
			CheckInTypeSpouse:        "spouse",
			CheckInTypeSponsor:       "sponsor",
			CheckInTypeCounselorCoach: "counselor",
		}

		for ciType, count := range counts {
			if count > 0 && float64(count) < threshold {
				// Find the highest type for comparison.
				var highType CheckInType
				for t, c := range counts {
					if c == maxCount {
						highType = t
						break
					}
				}
				balance.Gaps = append(balance.Gaps, BalanceGap{
					Type: typeNames[ciType],
					Message: fmt.Sprintf(
						"You've checked in with your %s %d times this month but your %s only %d times (outside of scheduled sessions).",
						typeDisplayNames[highType], maxCount,
						typeDisplayNames[ciType], count,
					),
				})
			}
		}
	}

	if balance.Gaps == nil {
		balance.Gaps = []BalanceGap{}
	}

	return balance
}
