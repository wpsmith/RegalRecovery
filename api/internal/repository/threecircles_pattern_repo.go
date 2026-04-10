// internal/repository/threecircles_pattern_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// --- Pattern timeline operations ---
// AP-TC-22: Get timeline for period
// AP-TC-23: Count days by circle type in window
// AP-TC-24: Consecutive outer circle days
// AP-TC-25: Middle circle days in 7-day window

// CreateTimelineEntry creates a new pattern timeline entry (one per day per set).
func (r *ThreeCirclesRepo) CreateTimelineEntry(ctx context.Context, entry *CirclePatternTimelineDoc) error {
	SetBaseDocumentDefaults(&entry.BaseDocument)

	if _, err := r.timeline.InsertOne(ctx, entry); err != nil {
		return fmt.Errorf("creating timeline entry: %w", err)
	}
	return nil
}

// GetTimelineForPeriod retrieves timeline entries for a given set within a date range.
// AP-TC-22: Get timeline for period
func (r *ThreeCirclesRepo) GetTimelineForPeriod(ctx context.Context, userID string, setID string, startDate string, endDate string) ([]CirclePatternTimelineDoc, error) {
	filter := bson.M{
		"userId": userID,
		"setId":  setID,
		"date": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "date", Value: 1}})
	cursor, err := r.timeline.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting timeline for period: %w", err)
	}

	var docs []CirclePatternTimelineDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding timeline entries: %w", err)
	}
	return docs, nil
}

// CountDaysByCircleType aggregates days by circle type within a window.
// AP-TC-23: Count days by circle type in window
func (r *ThreeCirclesRepo) CountDaysByCircleType(ctx context.Context, userID string, setID string, startDate string, endDate string) (map[string]int, error) {
	pipeline := bson.A{
		bson.M{"$match": bson.M{
			"userId": userID,
			"setId":  setID,
			"date": bson.M{
				"$gte": startDate,
				"$lte": endDate,
			},
		}},
		bson.M{"$group": bson.M{
			"_id":   "$circle",
			"count": bson.M{"$sum": 1},
		}},
	}

	cursor, err := r.timeline.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, fmt.Errorf("counting days by circle type: %w", err)
	}

	var results []struct {
		ID    string `bson:"_id"`
		Count int    `bson:"count"`
	}
	if err := cursor.All(ctx, &results); err != nil {
		return nil, fmt.Errorf("decoding aggregation results: %w", err)
	}

	counts := make(map[string]int)
	for _, r := range results {
		counts[r.ID] = r.Count
	}
	return counts, nil
}

// GetConsecutiveOuterDays calculates the current consecutive outer circle days.
// AP-TC-24: Consecutive outer circle days
func (r *ThreeCirclesRepo) GetConsecutiveOuterDays(ctx context.Context, userID string, setID string) (int, error) {
	filter := bson.M{
		"userId": userID,
		"setId":  setID,
		"circle": "outer",
	}

	opts := options.Find().SetSort(bson.D{{Key: "date", Value: -1}})
	cursor, err := r.timeline.Find(ctx, filter, opts)
	if err != nil {
		return 0, fmt.Errorf("getting consecutive outer days: %w", err)
	}

	var entries []CirclePatternTimelineDoc
	if err := cursor.All(ctx, &entries); err != nil {
		return 0, fmt.Errorf("decoding entries: %w", err)
	}

	// Count consecutive days from most recent backwards.
	count := 0
	for i, entry := range entries {
		if i == 0 {
			count++
			continue
		}

		// Parse dates and check if consecutive.
		prevDate, _ := time.Parse("2006-01-02", entries[i-1].Date)
		currDate, _ := time.Parse("2006-01-02", entry.Date)
		diff := prevDate.Sub(currDate).Hours() / 24

		if diff == 1 {
			count++
		} else {
			break // Non-consecutive, stop counting
		}
	}
	return count, nil
}

// CountMiddleCircleDaysInWindow counts middle circle days in the last N days.
// AP-TC-25: Middle circle days in 7-day window
func (r *ThreeCirclesRepo) CountMiddleCircleDaysInWindow(ctx context.Context, userID string, setID string, startDate string) (int64, error) {
	filter := bson.M{
		"userId": userID,
		"setId":  setID,
		"circle": "middle",
		"date":   bson.M{"$gte": startDate},
	}

	count, err := r.timeline.CountDocuments(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("counting middle circle days in window: %w", err)
	}
	return count, nil
}

// --- Insight operations ---
// AP-TC-26: Active insights for a set
// AP-TC-27: Insights by type

// CreateInsight creates a new pattern insight card.
func (r *ThreeCirclesRepo) CreateInsight(ctx context.Context, insight *CircleInsightDoc) error {
	SetBaseDocumentDefaults(&insight.BaseDocument)

	if _, err := r.insights.InsertOne(ctx, insight); err != nil {
		return fmt.Errorf("creating insight: %w", err)
	}
	return nil
}

// GetActiveInsightsForSet retrieves active (non-dismissed) insights for a set.
// AP-TC-26: Active insights for a set
func (r *ThreeCirclesRepo) GetActiveInsightsForSet(ctx context.Context, userID string, setID string) ([]CircleInsightDoc, error) {
	filter := bson.M{
		"userId":    userID,
		"setId":     setID,
		"dismissed": false,
	}

	opts := options.Find().SetSort(bson.D{{Key: "detectedAt", Value: -1}})
	cursor, err := r.insights.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting active insights: %w", err)
	}

	var docs []CircleInsightDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding insights: %w", err)
	}
	return docs, nil
}

// GetInsightsByType retrieves insights filtered by type.
// AP-TC-27: Insights by type
func (r *ThreeCirclesRepo) GetInsightsByType(ctx context.Context, userID string, insightType string) ([]CircleInsightDoc, error) {
	filter := bson.M{
		"userId": userID,
		"type":   insightType,
	}

	opts := options.Find().SetSort(bson.D{{Key: "detectedAt", Value: -1}})
	cursor, err := r.insights.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting insights by type: %w", err)
	}

	var docs []CircleInsightDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding insights: %w", err)
	}
	return docs, nil
}

// UpdateInsight updates an existing insight (e.g., dismiss).
func (r *ThreeCirclesRepo) UpdateInsight(ctx context.Context, insight *CircleInsightDoc) error {
	UpdateModified(&insight.BaseDocument)

	filter := bson.M{"insightId": insight.InsightID}
	update := bson.M{"$set": insight}

	result, err := r.insights.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating insight %s: %w", insight.InsightID, err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("insight %s: not found", insight.InsightID)
	}

	return nil
}

// --- Drift alert operations ---
// AP-TC-28: Active drift alerts
// AP-TC-29: Recent drift episodes

// CreateDriftAlert creates a new drift detection alert.
func (r *ThreeCirclesRepo) CreateDriftAlert(ctx context.Context, alert *CircleDriftAlertDoc) error {
	SetBaseDocumentDefaults(&alert.BaseDocument)

	if _, err := r.driftAlerts.InsertOne(ctx, alert); err != nil {
		return fmt.Errorf("creating drift alert: %w", err)
	}
	return nil
}

// GetActiveDriftAlerts retrieves active (non-dismissed) drift alerts for a set.
// AP-TC-28: Active drift alerts
func (r *ThreeCirclesRepo) GetActiveDriftAlerts(ctx context.Context, userID string, setID string) ([]CircleDriftAlertDoc, error) {
	filter := bson.M{
		"userId":    userID,
		"setId":     setID,
		"dismissed": false,
	}

	opts := options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}})
	cursor, err := r.driftAlerts.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting active drift alerts: %w", err)
	}

	var docs []CircleDriftAlertDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding drift alerts: %w", err)
	}
	return docs, nil
}

// GetRecentDriftEpisodes retrieves recent drift alerts (last N) for a user.
// AP-TC-29: Recent drift episodes
func (r *ThreeCirclesRepo) GetRecentDriftEpisodes(ctx context.Context, userID string, limit int) ([]CircleDriftAlertDoc, error) {
	filter := bson.M{"userId": userID}
	opts := options.Find().SetSort(bson.D{{Key: "windowEnd", Value: -1}}).SetLimit(int64(limit))

	cursor, err := r.driftAlerts.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting recent drift episodes: %w", err)
	}

	var docs []CircleDriftAlertDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding drift episodes: %w", err)
	}
	return docs, nil
}

// UpdateDriftAlert updates an existing drift alert (e.g., dismiss, record action).
func (r *ThreeCirclesRepo) UpdateDriftAlert(ctx context.Context, alert *CircleDriftAlertDoc) error {
	UpdateModified(&alert.BaseDocument)

	filter := bson.M{"alertId": alert.AlertID}
	update := bson.M{"$set": alert}

	result, err := r.driftAlerts.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating drift alert %s: %w", alert.AlertID, err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("drift alert %s: not found", alert.AlertID)
	}

	return nil
}

// WriteCalendarActivity writes a calendar activity entry for Three Circles events.
// AP-TC-CALENDAR: Calendar activity dual-write
func (r *ThreeCirclesRepo) WriteCalendarActivity(ctx context.Context, activity *Activity) error {
	SetBaseDocumentDefaults(&activity.BaseDocument)

	if _, err := r.activities.InsertOne(ctx, activity); err != nil {
		return fmt.Errorf("writing calendar activity: %w", err)
	}
	return nil
}
