// internal/repository/timejournal_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	tj "github.com/regalrecovery/api/internal/domain/timejournal"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const (
	collTimeJournalEntries = "timeJournalEntries"
	collTimeJournalDays    = "timeJournalDays"
)

// TimeJournalRepo implements timejournal.TimeJournalRepository using MongoDB.
type TimeJournalRepo struct {
	client *MongoClient
}

// NewTimeJournalRepo creates a new TimeJournalRepo.
func NewTimeJournalRepo(client *MongoClient) *TimeJournalRepo {
	return &TimeJournalRepo{client: client}
}

func (r *TimeJournalRepo) entries() *mongo.Collection {
	return r.client.Collection(collTimeJournalEntries)
}

func (r *TimeJournalRepo) days() *mongo.Collection {
	return r.client.Collection(collTimeJournalDays)
}

// CreateEntry persists a new time journal entry.
func (r *TimeJournalRepo) CreateEntry(ctx context.Context, entry *tj.TimeJournalEntry) error {
	doc := TimeJournalEntryDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  entry.CreatedAt,
			ModifiedAt: entry.ModifiedAt,
			TenantID:   "DEFAULT", // populated by middleware in production
		},
		EntryID:              entry.ID,
		UserID:               entry.UserID,
		EntityType:           "TimeJournalEntry",
		Date:                 entry.Date,
		SlotStart:            entry.SlotStart,
		SlotEnd:              entry.SlotEnd,
		Mode:                 string(entry.Mode),
		Location:             entry.Location,
		GPSLatitude:          entry.GPSLatitude,
		GPSLongitude:         entry.GPSLongitude,
		GPSAddress:           entry.GPSAddress,
		Activity:             entry.Activity,
		People:               toPersonPresentDocs(entry.People),
		Emotions:             toEmotionDocs(entry.Emotions),
		Extras:               entry.Extras,
		SleepFlag:            entry.SleepFlag,
		Retroactive:          entry.Retroactive,
		RetroactiveTimestamp: entry.RetroactiveTimestamp,
		AutoFilled:           entry.AutoFilled,
		AutoFillSource:       entry.AutoFillSource,
		RedlineNote:          entry.RedlineNote,
	}

	_, err := r.entries().InsertOne(ctx, doc)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return tj.ErrDuplicateSlot
		}
		return fmt.Errorf("inserting time journal entry: %w", err)
	}
	return nil
}

// GetEntry retrieves a single entry by ID.
func (r *TimeJournalRepo) GetEntry(ctx context.Context, entryID string) (*tj.TimeJournalEntry, error) {
	var doc TimeJournalEntryDoc
	err := r.entries().FindOne(ctx, bson.M{"entryId": entryID}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding time journal entry: %w", err)
	}
	entry := docToEntry(&doc)
	return &entry, nil
}

// UpdateEntry applies a merge-patch update and returns the updated entry.
func (r *TimeJournalRepo) UpdateEntry(ctx context.Context, entryID string, req *tj.UpdateTimeJournalEntryRequest) (*tj.TimeJournalEntry, error) {
	update := bson.M{}

	if req.Location != nil {
		update["location"] = *req.Location
	}
	if req.GPSLatitude != nil {
		update["gpsLatitude"] = *req.GPSLatitude
	}
	if req.GPSLongitude != nil {
		update["gpsLongitude"] = *req.GPSLongitude
	}
	if req.GPSAddress != nil {
		update["gpsAddress"] = *req.GPSAddress
	}
	if req.Activity != nil {
		update["activity"] = *req.Activity
	}
	if req.People != nil {
		update["people"] = toPersonPresentDocs(*req.People)
	}
	if req.Emotions != nil {
		update["emotions"] = toEmotionDocs(*req.Emotions)
	}
	if req.Extras != nil {
		update["extras"] = req.Extras
	}
	if req.SleepFlag != nil {
		update["sleepFlag"] = *req.SleepFlag
	}
	if req.RedlineNote != nil {
		update["redlineNote"] = *req.RedlineNote
	}

	now := time.Now().UTC()
	update["modifiedAt"] = now

	opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
	var doc TimeJournalEntryDoc
	err := r.entries().FindOneAndUpdate(
		ctx,
		bson.M{"entryId": entryID},
		bson.M{"$set": update},
		opts,
	).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("updating time journal entry: %w", err)
	}

	entry := docToEntry(&doc)
	return &entry, nil
}

// GetEntriesForDate retrieves all entries for a user on a specific date.
func (r *TimeJournalRepo) GetEntriesForDate(ctx context.Context, userID string, date string, mode tj.TimeJournalMode) ([]tj.TimeJournalEntry, error) {
	filter := bson.M{
		"userId": userID,
		"date":   date,
	}
	if mode != "" {
		filter["mode"] = string(mode)
	}

	opts := options.Find().SetSort(bson.D{{Key: "slotStart", Value: 1}})
	cursor, err := r.entries().Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("finding entries for date: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []TimeJournalEntryDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding entries: %w", err)
	}

	entries := make([]tj.TimeJournalEntry, 0, len(docs))
	for i := range docs {
		entries = append(entries, docToEntry(&docs[i]))
	}
	return entries, nil
}

// GetDaySummary retrieves the aggregated day summary for a date.
func (r *TimeJournalRepo) GetDaySummary(ctx context.Context, userID string, date string) (*tj.TimeJournalDay, error) {
	var doc TimeJournalDayDoc
	err := r.days().FindOne(ctx, bson.M{"userId": userID, "date": date}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding day summary: %w", err)
	}
	day := docToDay(&doc)
	return &day, nil
}

// GetDaySummaries retrieves paginated day summaries within a date range.
func (r *TimeJournalRepo) GetDaySummaries(ctx context.Context, userID string, startDate string, endDate string, mode *tj.TimeJournalMode, cursor string, limit int) ([]tj.TimeJournalDay, string, error) {
	filter := bson.M{"userId": userID}

	if startDate != "" || endDate != "" {
		dateFilter := bson.M{}
		if startDate != "" {
			dateFilter["$gte"] = startDate
		}
		if endDate != "" {
			dateFilter["$lte"] = endDate
		}
		filter["date"] = dateFilter
	}

	if mode != nil {
		filter["mode"] = string(*mode)
	}

	if cursor != "" {
		filter["date"] = bson.M{"$lt": cursor}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "date", Value: -1}}).
		SetLimit(int64(limit + 1)) // fetch one extra for cursor

	cur, err := r.days().Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("finding day summaries: %w", err)
	}
	defer cur.Close(ctx)

	var docs []TimeJournalDayDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding day summaries: %w", err)
	}

	var nextCursor string
	if len(docs) > limit {
		nextCursor = docs[limit].Date
		docs = docs[:limit]
	}

	days := make([]tj.TimeJournalDay, 0, len(docs))
	for i := range docs {
		days = append(days, docToDay(&docs[i]))
	}

	return days, nextCursor, nil
}

// GetStreak retrieves the computed streak data for a user by reading day summaries.
func (r *TimeJournalRepo) GetStreak(ctx context.Context, userID string) (*tj.TimeJournalStreak, error) {
	// Fetch all days sorted descending by date to compute streak.
	opts := options.Find().SetSort(bson.D{{Key: "date", Value: -1}})
	cur, err := r.days().Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("finding days for streak: %w", err)
	}
	defer cur.Close(ctx)

	var docs []TimeJournalDayDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding days for streak: %w", err)
	}

	days := make([]tj.TimeJournalDay, 0, len(docs))
	for i := range docs {
		days = append(days, docToDay(&docs[i]))
	}

	current, longest := tj.CalculateStreak(days)

	streak := &tj.TimeJournalStreak{
		CurrentStreakDays:  current,
		LongestStreakDays:  longest,
		ThresholdPercent:   80,
		TotalJournalDays:   len(days),
	}

	// Compute next milestone.
	nextMilestoneTarget := nextMilestoneTarget(current)
	if nextMilestoneTarget > 0 {
		streak.NextMilestone = &tj.NextMilestone{
			Days:          nextMilestoneTarget,
			DaysRemaining: nextMilestoneTarget - current,
			Label:         fmt.Sprintf("%d-day streak", nextMilestoneTarget),
		}
	}

	return streak, nil
}

// UpsertDayAggregate recalculates and upserts the daily aggregate for a given date.
func (r *TimeJournalRepo) UpsertDayAggregate(ctx context.Context, userID string, date string, mode tj.TimeJournalMode) error {
	// Count entries for this date.
	entries, err := r.GetEntriesForDate(ctx, userID, date, mode)
	if err != nil {
		return fmt.Errorf("fetching entries for aggregate: %w", err)
	}

	totalSlots := mode.TotalSlots()
	filledSlots := len(entries)
	completionScore := 0.0
	if totalSlots > 0 {
		completionScore = float64(filledSlots) / float64(totalSlots)
	}

	now := time.Now().UTC()
	status := tj.EvaluateDayStatus(entries, mode, now)

	overdueSlots := 0
	for _, e := range entries {
		_ = e // count is handled by filled vs total
	}
	// Recount overdue from the status engine perspective.
	durationMinutes := mode.SlotDurationMinutes()
	filledSet := make(map[string]bool, len(entries))
	for _, e := range entries {
		filledSet[e.SlotStart] = true
	}
	todayStr := now.Format("2006-01-02")
	for i := range totalSlots {
		hour := (i * durationMinutes) / 60
		minute := (i * durationMinutes) % 60
		slotStart := fmt.Sprintf("%02d:%02d:00", hour, minute)
		slotEndStr := fmt.Sprintf("%s %s", todayStr, slotStart)
		slotEndTime, _ := time.Parse("2006-01-02 15:04:05", slotEndStr)
		slotEndTime = slotEndTime.Add(time.Duration(durationMinutes) * time.Minute)
		elapsed := now.After(slotEndTime) || now.Equal(slotEndTime)
		if elapsed && !filledSet[slotStart] {
			overdueSlots++
		}
	}

	filter := bson.M{"userId": userID, "date": date}
	update := bson.M{
		"$set": bson.M{
			"mode":             string(mode),
			"totalSlots":       totalSlots,
			"filledSlots":      filledSlots,
			"completionScore":  completionScore,
			"status":           string(status),
			"overdueSlotCount": overdueSlots,
			"streakEligible":   completionScore >= 0.8,
			"lastUpdatedAt":    now,
			"modifiedAt":       now,
			"entityType":       "TimeJournalDay",
			"tenantId":         "DEFAULT",
		},
		"$setOnInsert": bson.M{
			"dayId":     generateDayID(),
			"createdAt": now,
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	_, err = r.days().UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return fmt.Errorf("upserting day aggregate: %w", err)
	}

	return nil
}

// generateDayID creates a day aggregate ID with the tjd_ prefix.
func generateDayID() string {
	return fmt.Sprintf("tjd_%d", time.Now().UnixNano())
}

// --- Conversion helpers ---

func toPersonPresentDocs(people []tj.PersonPresent) []PersonPresentDoc {
	if people == nil {
		return nil
	}
	docs := make([]PersonPresentDoc, len(people))
	for i, p := range people {
		docs[i] = PersonPresentDoc{Name: p.Name, Gender: p.Gender}
	}
	return docs
}

func toEmotionDocs(emotions []tj.Emotion) []EmotionDoc {
	if emotions == nil {
		return nil
	}
	docs := make([]EmotionDoc, len(emotions))
	for i, e := range emotions {
		docs[i] = EmotionDoc{Name: e.Name, Intensity: e.Intensity, Why: e.Why}
	}
	return docs
}

func docToEntry(doc *TimeJournalEntryDoc) tj.TimeJournalEntry {
	people := make([]tj.PersonPresent, 0, len(doc.People))
	for _, p := range doc.People {
		people = append(people, tj.PersonPresent{Name: p.Name, Gender: p.Gender})
	}
	emotions := make([]tj.Emotion, 0, len(doc.Emotions))
	for _, e := range doc.Emotions {
		emotions = append(emotions, tj.Emotion{Name: e.Name, Intensity: e.Intensity, Why: e.Why})
	}

	return tj.TimeJournalEntry{
		ID:                   doc.EntryID,
		UserID:               doc.UserID,
		Date:                 doc.Date,
		SlotStart:            doc.SlotStart,
		SlotEnd:              doc.SlotEnd,
		Mode:                 tj.TimeJournalMode(doc.Mode),
		Location:             doc.Location,
		GPSLatitude:          doc.GPSLatitude,
		GPSLongitude:         doc.GPSLongitude,
		GPSAddress:           doc.GPSAddress,
		Activity:             doc.Activity,
		People:               people,
		Emotions:             emotions,
		Extras:               doc.Extras,
		SleepFlag:            doc.SleepFlag,
		Retroactive:          doc.Retroactive,
		RetroactiveTimestamp: doc.RetroactiveTimestamp,
		AutoFilled:           doc.AutoFilled,
		AutoFillSource:       doc.AutoFillSource,
		RedlineNote:          doc.RedlineNote,
		CreatedAt:            doc.CreatedAt,
		ModifiedAt:           doc.ModifiedAt,
	}
}

func docToDay(doc *TimeJournalDayDoc) tj.TimeJournalDay {
	return tj.TimeJournalDay{
		Date:             doc.Date,
		Mode:             tj.TimeJournalMode(doc.Mode),
		TotalSlots:       doc.TotalSlots,
		FilledSlots:      doc.FilledSlots,
		CompletionScore:  doc.CompletionScore,
		Status:           tj.DayStatus(doc.Status),
		OverdueSlotCount: doc.OverdueSlotCount,
		LastUpdatedAt:    doc.LastUpdatedAt,
	}
}

// nextMilestoneTarget returns the next milestone day count above the current streak.
func nextMilestoneTarget(currentDays int) int {
	milestones := []int{7, 14, 30, 60, 90, 180, 365}
	for _, m := range milestones {
		if m > currentDays {
			return m
		}
	}
	return 0
}
