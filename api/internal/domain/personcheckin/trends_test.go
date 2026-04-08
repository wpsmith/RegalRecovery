// internal/domain/personcheckin/trends_test.go
package personcheckin

import (
	"testing"
	"time"
)

func makeCheckIn(ciType CheckInType, method Method, ts time.Time, rating *int, topics []Topic) PersonCheckIn {
	return PersonCheckIn{
		CheckInType:     ciType,
		Method:          method,
		Timestamp:       ts,
		QualityRating:   rating,
		TopicsDiscussed: topics,
	}
}

func intPtr(v int) *int {
	return &v
}

func TestPersonCheckInTrends_FR_PCI_8_1_FrequencyOverTime_7Day(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 22), nil, nil),
		makeCheckIn(CheckInTypeSponsor, MethodPhoneCall, makeTimestamp(2026, 3, 23), nil, nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), nil, nil),
		makeCheckIn(CheckInTypeSponsor, MethodPhoneCall, makeTimestamp(2026, 3, 28), nil, nil),
	}

	trends := CalculateTrends(checkIns, "7d", now)

	if len(trends.Frequency) == 0 {
		t.Fatal("expected frequency data points")
	}
}

func TestPersonCheckInTrends_FR_PCI_8_1_FrequencyOverTime_30Day(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 1), nil, nil),
		makeCheckIn(CheckInTypeSponsor, MethodPhoneCall, makeTimestamp(2026, 3, 15), nil, nil),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	if len(trends.Frequency) < 28 {
		t.Fatalf("expected at least 28 data points for 30d, got %d", len(trends.Frequency))
	}
}

func TestPersonCheckInTrends_FR_PCI_8_1_FrequencyOverTime_90Day(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	trends := CalculateTrends(nil, "90d", now)

	if len(trends.Frequency) < 88 {
		t.Fatalf("expected at least 88 data points for 90d, got %d", len(trends.Frequency))
	}
}

func TestPersonCheckInTrends_FR_PCI_8_2_MethodDistributionPerSubType(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 20), nil, nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 21), nil, nil),
		makeCheckIn(CheckInTypeSpouse, MethodPhoneCall, makeTimestamp(2026, 3, 22), nil, nil),
		makeCheckIn(CheckInTypeSponsor, MethodPhoneCall, makeTimestamp(2026, 3, 22), nil, nil),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	spouseDist, ok := trends.MethodDistribution["spouse"]
	if !ok {
		t.Fatal("expected spouse method distribution")
	}
	if spouseDist["in-person"] != 2 {
		t.Fatalf("expected 2 in-person for spouse, got %d", spouseDist["in-person"])
	}
	if spouseDist["phone-call"] != 1 {
		t.Fatalf("expected 1 phone-call for spouse, got %d", spouseDist["phone-call"])
	}
}

func TestPersonCheckInTrends_FR_PCI_8_3_QualityTrendImproving(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 1), intPtr(2), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 5), intPtr(2), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 10), intPtr(3), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 15), intPtr(4), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 20), intPtr(4), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), intPtr(5), nil),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	spouseQuality, ok := trends.QualityTrends["spouse"]
	if !ok {
		t.Fatal("expected spouse quality trends")
	}
	if spouseQuality.Trend != QualityTrendImproving {
		t.Fatalf("expected improving trend, got %s", spouseQuality.Trend)
	}
}

func TestPersonCheckInTrends_FR_PCI_8_3_QualityTrendDeclining(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 1), intPtr(5), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 5), intPtr(5), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 15), intPtr(3), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 20), intPtr(2), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), intPtr(2), nil),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	spouseQuality := trends.QualityTrends["spouse"]
	if spouseQuality.Trend != QualityTrendDeclining {
		t.Fatalf("expected declining trend, got %s", spouseQuality.Trend)
	}
}

func TestPersonCheckInTrends_FR_PCI_8_3_QualityTrendStable(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 1), intPtr(3), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 15), intPtr(3), nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), intPtr(3), nil),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	spouseQuality := trends.QualityTrends["spouse"]
	if spouseQuality.Trend != QualityTrendStable {
		t.Fatalf("expected stable trend, got %s", spouseQuality.Trend)
	}
}

func TestPersonCheckInTrends_FR_PCI_8_4_TopicFrequencyAcrossAllCheckIns(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 20), nil, []Topic{TopicAccountability, TopicStepWork}),
		makeCheckIn(CheckInTypeSponsor, MethodPhoneCall, makeTimestamp(2026, 3, 22), nil, []Topic{TopicAccountability, TopicStepWork}),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), nil, []Topic{TopicEmotionsFeelings}),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	if len(trends.TopicFrequency) == 0 {
		t.Fatal("expected topic frequency data")
	}

	// Accountability should be most frequent.
	if trends.TopicFrequency[0].Topic != string(TopicAccountability) && trends.TopicFrequency[0].Topic != string(TopicStepWork) {
		t.Fatalf("expected accountability or step-work as top topic, got %s", trends.TopicFrequency[0].Topic)
	}
}

func TestPersonCheckInTrends_FR_PCI_8_4_TopicFrequencyPerSubType(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), nil, []Topic{TopicRelationshipsMarriage}),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	found := false
	for _, tf := range trends.TopicFrequency {
		if tf.Topic == string(TopicRelationshipsMarriage) && tf.Count == 1 {
			found = true
		}
	}
	if !found {
		t.Fatal("expected relationships-marriage topic with count 1")
	}
}

func TestPersonCheckInTrends_FR_PCI_8_5_BalanceAnalysisDetectsGaps(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	var checkIns []PersonCheckIn
	// 15 spouse, 2 counselor.
	for i := 0; i < 15; i++ {
		checkIns = append(checkIns, makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 1+i), nil, nil))
	}
	checkIns = append(checkIns,
		makeCheckIn(CheckInTypeCounselorCoach, MethodInPerson, makeTimestamp(2026, 3, 5), nil, nil),
		makeCheckIn(CheckInTypeCounselorCoach, MethodInPerson, makeTimestamp(2026, 3, 20), nil, nil),
	)

	trends := CalculateTrends(checkIns, "30d", now)

	if len(trends.Balance.Gaps) == 0 {
		t.Fatal("expected at least one gap detected")
	}
}

func TestPersonCheckInTrends_FR_PCI_8_5_BalanceAnalysisNoGapsWhenBalanced(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 20), nil, nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), nil, nil),
		makeCheckIn(CheckInTypeSponsor, MethodPhoneCall, makeTimestamp(2026, 3, 21), nil, nil),
		makeCheckIn(CheckInTypeSponsor, MethodPhoneCall, makeTimestamp(2026, 3, 26), nil, nil),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	if len(trends.Balance.Gaps) != 0 {
		t.Fatalf("expected no gaps for balanced check-ins, got %d", len(trends.Balance.Gaps))
	}
}

func TestPersonCheckInTrends_EmptyHistory_ReturnsEmptyTrends(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)
	trends := CalculateTrends(nil, "30d", now)

	if len(trends.TopicFrequency) != 0 {
		t.Fatal("expected empty topic frequency for empty history")
	}
	if len(trends.MethodDistribution) != 0 {
		t.Fatal("expected empty method distribution for empty history")
	}
}

func TestPersonCheckInTrends_SingleSubType_OmitsBalanceGaps(t *testing.T) {
	now := makeTimestamp(2026, 3, 28)

	checkIns := []PersonCheckIn{
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 25), nil, nil),
		makeCheckIn(CheckInTypeSpouse, MethodInPerson, makeTimestamp(2026, 3, 26), nil, nil),
	}

	trends := CalculateTrends(checkIns, "30d", now)

	if len(trends.Balance.Gaps) != 0 {
		t.Fatal("expected no gaps when only one sub-type has check-ins")
	}
}
