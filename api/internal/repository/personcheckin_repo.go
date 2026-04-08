// internal/repository/personcheckin_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/personcheckin"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const (
	personCheckInCollection       = "regalRecovery"
	personCheckInEntityType       = "PERSON_CHECKIN"
	calendarActivityEntityType    = "CALENDAR_ACTIVITY"
	personCheckInSettingsEntity   = "PERSON_CHECKIN_SETTINGS"
	personCheckInStreakEntity     = "PERSON_CHECKIN_STREAK"
)

// MongoPersonCheckInRepository implements personcheckin.CheckInRepository.
type MongoPersonCheckInRepository struct {
	collection *mongo.Collection
}

// NewMongoPersonCheckInRepository creates a new repository for person check-ins.
func NewMongoPersonCheckInRepository(db *mongo.Database) *MongoPersonCheckInRepository {
	return &MongoPersonCheckInRepository{
		collection: db.Collection(personCheckInCollection),
	}
}

// Create persists a new person check-in and dual-writes to calendar activities.
func (r *MongoPersonCheckInRepository) Create(ctx context.Context, checkIn *personcheckin.PersonCheckIn) error {
	doc := bson.M{
		"PK":                   fmt.Sprintf("USER#%s", checkIn.UserID),
		"SK":                   fmt.Sprintf("PERSON_CHECKIN#%s", checkIn.Timestamp.Format(time.RFC3339)),
		"EntityType":           personCheckInEntityType,
		"TenantId":             checkIn.TenantID,
		"CreatedAt":            checkIn.CreatedAt,
		"ModifiedAt":           checkIn.ModifiedAt,
		"checkInId":            checkIn.CheckInID,
		"checkInType":          string(checkIn.CheckInType),
		"method":               string(checkIn.Method),
		"timestamp":            checkIn.Timestamp,
		"contactName":          checkIn.ContactName,
		"durationMinutes":      checkIn.DurationMinutes,
		"qualityRating":        checkIn.QualityRating,
		"topicsDiscussed":      checkIn.TopicsDiscussed,
		"notes":                checkIn.Notes,
		"followUpItems":        checkIn.FollowUpItems,
		"counselorSubCategory": checkIn.CounselorSubCategory,
	}

	_, err := r.collection.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting person check-in: %w", err)
	}

	// Dual-write to calendar activities.
	calDoc := bson.M{
		"PK":           fmt.Sprintf("USER#%s", checkIn.UserID),
		"SK":           fmt.Sprintf("ACTIVITY#%s#PERSON_CHECKIN#%s", checkIn.Timestamp.Format("2006-01-02"), checkIn.Timestamp.Format(time.RFC3339)),
		"EntityType":   calendarActivityEntityType,
		"activityType": "PERSON_CHECKIN",
		"summary": bson.M{
			"checkInType":   string(checkIn.CheckInType),
			"method":        string(checkIn.Method),
			"contactName":   checkIn.ContactName,
			"qualityRating": checkIn.QualityRating,
		},
		"sourceKey": fmt.Sprintf("PERSON_CHECKIN#%s", checkIn.Timestamp.Format(time.RFC3339)),
	}

	_, err = r.collection.InsertOne(ctx, calDoc)
	if err != nil {
		return fmt.Errorf("inserting calendar activity: %w", err)
	}

	return nil
}

// GetByID retrieves a single check-in by its ID for a user.
func (r *MongoPersonCheckInRepository) GetByID(ctx context.Context, userID, checkInID string) (*personcheckin.PersonCheckIn, error) {
	filter := bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": personCheckInEntityType,
		"checkInId":  checkInID,
	}

	var doc bson.M
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding person check-in: %w", err)
	}

	return docToPersonCheckIn(doc), nil
}

// List retrieves check-ins for a user with filtering, sorting, and pagination.
func (r *MongoPersonCheckInRepository) List(ctx context.Context, userID string, params personcheckin.ListCheckInsParams) ([]personcheckin.PersonCheckIn, string, error) {
	filter := bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": personCheckInEntityType,
	}

	if params.CheckInType != nil {
		filter["checkInType"] = string(*params.CheckInType)
	}
	if params.Method != nil {
		filter["method"] = string(*params.Method)
	}
	if params.MinQualityRating != nil {
		filter["qualityRating"] = bson.M{"$gte": *params.MinQualityRating}
	}
	if params.Topic != nil {
		filter["topicsDiscussed"] = string(*params.Topic)
	}
	if params.StartDate != nil || params.EndDate != nil {
		dateFilter := bson.M{}
		if params.StartDate != nil {
			dateFilter["$gte"] = *params.StartDate
		}
		if params.EndDate != nil {
			dateFilter["$lte"] = params.EndDate.Add(24*time.Hour - time.Second)
		}
		filter["timestamp"] = dateFilter
	}
	if params.Query != nil && *params.Query != "" {
		filter["$or"] = bson.A{
			bson.M{"notes": bson.M{"$regex": *params.Query, "$options": "i"}},
			bson.M{"followUpItems.text": bson.M{"$regex": *params.Query, "$options": "i"}},
		}
	}

	// Sort.
	sortField := "timestamp"
	sortOrder := -1
	if params.Sort == "+timestamp" {
		sortOrder = 1
	} else if params.Sort == "-qualityRating" {
		sortField = "qualityRating"
	} else if params.Sort == "+qualityRating" {
		sortField = "qualityRating"
		sortOrder = 1
	}

	opts := options.Find().
		SetSort(bson.D{{Key: sortField, Value: sortOrder}}).
		SetLimit(int64(params.Limit + 1))

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("finding person check-ins: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []bson.M
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding person check-ins: %w", err)
	}

	var nextCursor string
	if len(docs) > params.Limit {
		docs = docs[:params.Limit]
		lastDoc := docs[len(docs)-1]
		if ts, ok := lastDoc["timestamp"].(time.Time); ok {
			nextCursor = ts.Format(time.RFC3339)
		}
	}

	var checkIns []personcheckin.PersonCheckIn
	for _, doc := range docs {
		checkIns = append(checkIns, *docToPersonCheckIn(doc))
	}

	return checkIns, nextCursor, nil
}

// Update partially updates a check-in.
func (r *MongoPersonCheckInRepository) Update(ctx context.Context, checkIn *personcheckin.PersonCheckIn) error {
	filter := bson.M{
		"PK":         fmt.Sprintf("USER#%s", checkIn.UserID),
		"EntityType": personCheckInEntityType,
		"checkInId":  checkIn.CheckInID,
	}

	update := bson.M{
		"$set": bson.M{
			"ModifiedAt":           checkIn.ModifiedAt,
			"method":               string(checkIn.Method),
			"contactName":          checkIn.ContactName,
			"durationMinutes":      checkIn.DurationMinutes,
			"qualityRating":        checkIn.QualityRating,
			"topicsDiscussed":      checkIn.TopicsDiscussed,
			"notes":                checkIn.Notes,
			"followUpItems":        checkIn.FollowUpItems,
			"counselorSubCategory": checkIn.CounselorSubCategory,
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating person check-in: %w", err)
	}
	if result.MatchedCount == 0 {
		return personcheckin.ErrCheckInNotFound
	}

	return nil
}

// Delete removes a check-in and its calendar activity entry.
func (r *MongoPersonCheckInRepository) Delete(ctx context.Context, userID, checkInID string) error {
	// Find the check-in first to get the timestamp for calendar deletion.
	ci, err := r.GetByID(ctx, userID, checkInID)
	if err != nil {
		return err
	}
	if ci == nil {
		return personcheckin.ErrCheckInNotFound
	}

	// Delete the check-in.
	filter := bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": personCheckInEntityType,
		"checkInId":  checkInID,
	}

	_, err = r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting person check-in: %w", err)
	}

	// Delete the calendar activity.
	calFilter := bson.M{
		"PK":        fmt.Sprintf("USER#%s", userID),
		"sourceKey": fmt.Sprintf("PERSON_CHECKIN#%s", ci.Timestamp.Format(time.RFC3339)),
	}

	_, _ = r.collection.DeleteOne(ctx, calFilter)

	return nil
}

// GetByUserAndType retrieves check-ins for a user filtered by sub-type and date range.
func (r *MongoPersonCheckInRepository) GetByUserAndType(ctx context.Context, userID string, checkInType personcheckin.CheckInType, startDate, endDate time.Time) ([]personcheckin.PersonCheckIn, error) {
	filter := bson.M{
		"PK":          fmt.Sprintf("USER#%s", userID),
		"EntityType":  personCheckInEntityType,
		"checkInType": string(checkInType),
		"timestamp": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "timestamp", Value: -1}})

	cursor, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("finding person check-ins by type: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []bson.M
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding person check-ins: %w", err)
	}

	var checkIns []personcheckin.PersonCheckIn
	for _, doc := range docs {
		checkIns = append(checkIns, *docToPersonCheckIn(doc))
	}

	return checkIns, nil
}

// GetCalendarMonth retrieves calendar data for a month.
func (r *MongoPersonCheckInRepository) GetCalendarMonth(ctx context.Context, userID string, month string) ([]personcheckin.CalendarDay, error) {
	startDate := month + "-01"
	endDate := month + "-31~"

	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": bson.M{
			"$gte": fmt.Sprintf("ACTIVITY#%s", startDate),
			"$lte": fmt.Sprintf("ACTIVITY#%s", endDate),
		},
		"activityType": "PERSON_CHECKIN",
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("finding calendar activities: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []bson.M
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding calendar activities: %w", err)
	}

	// Aggregate by day and check-in type.
	dayMap := make(map[string]map[personcheckin.CheckInType]int)
	for _, doc := range docs {
		summary, _ := doc["summary"].(bson.M)
		if summary == nil {
			continue
		}
		ciType := personcheckin.CheckInType(getStringField(summary, "checkInType"))
		sk := getStringField(doc, "SK")
		// Extract date from SK: ACTIVITY#YYYY-MM-DD#PERSON_CHECKIN#...
		if len(sk) >= 18 {
			date := sk[9:19] // "YYYY-MM-DD"
			if dayMap[date] == nil {
				dayMap[date] = make(map[personcheckin.CheckInType]int)
			}
			dayMap[date][ciType]++
		}
	}

	var days []personcheckin.CalendarDay
	for date, typeCounts := range dayMap {
		var checkIns []personcheckin.CalendarDayCheckIn
		for ciType, count := range typeCounts {
			checkIns = append(checkIns, personcheckin.CalendarDayCheckIn{
				CheckInType: ciType,
				Count:       count,
			})
		}
		days = append(days, personcheckin.CalendarDay{
			Date:     date,
			CheckIns: checkIns,
		})
	}

	return days, nil
}

// --- Streak Repository ---

// MongoPersonCheckInStreakRepository implements personcheckin.StreakRepository.
type MongoPersonCheckInStreakRepository struct {
	collection *mongo.Collection
}

// NewMongoPersonCheckInStreakRepository creates a new streak repository.
func NewMongoPersonCheckInStreakRepository(db *mongo.Database) *MongoPersonCheckInStreakRepository {
	return &MongoPersonCheckInStreakRepository{
		collection: db.Collection(personCheckInCollection),
	}
}

// GetAllStreaks retrieves all sub-type streaks for a user.
func (r *MongoPersonCheckInStreakRepository) GetAllStreaks(ctx context.Context, userID string) ([]personcheckin.PersonCheckInStreak, error) {
	filter := bson.M{
		"PK":         fmt.Sprintf("USER#%s", userID),
		"EntityType": personCheckInStreakEntity,
	}

	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("finding streaks: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []bson.M
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding streaks: %w", err)
	}

	var streaks []personcheckin.PersonCheckInStreak
	for _, doc := range docs {
		streaks = append(streaks, *docToStreak(doc))
	}

	return streaks, nil
}

// GetStreakByType retrieves a single sub-type streak for a user.
func (r *MongoPersonCheckInStreakRepository) GetStreakByType(ctx context.Context, userID string, checkInType personcheckin.CheckInType) (*personcheckin.PersonCheckInStreak, error) {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": fmt.Sprintf("PERSON_CHECKIN_STREAK#%s", string(checkInType)),
	}

	var doc bson.M
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding streak: %w", err)
	}

	return docToStreak(doc), nil
}

// SaveStreak creates or updates a streak record.
func (r *MongoPersonCheckInStreakRepository) SaveStreak(ctx context.Context, userID string, streak *personcheckin.PersonCheckInStreak) error {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": fmt.Sprintf("PERSON_CHECKIN_STREAK#%s", string(streak.CheckInType)),
	}

	update := bson.M{
		"$set": bson.M{
			"EntityType":        personCheckInStreakEntity,
			"ModifiedAt":        time.Now(),
			"checkInType":       string(streak.CheckInType),
			"currentStreak":     streak.CurrentStreak,
			"longestStreak":     streak.LongestStreak,
			"streakUnit":        streak.StreakUnit,
			"checkInsThisWeek":  streak.CheckInsThisWeek,
			"checkInsThisMonth": streak.CheckInsThisMonth,
			"averagePerWeek":    streak.AveragePerWeek,
			"lastCheckInDate":   streak.LastCheckInDate,
		},
		"$setOnInsert": bson.M{
			"PK":        fmt.Sprintf("USER#%s", userID),
			"SK":        fmt.Sprintf("PERSON_CHECKIN_STREAK#%s", string(streak.CheckInType)),
			"CreatedAt": time.Now(),
		},
	}

	opts := options.UpdateOne().SetUpsert(true)

	_, err := r.collection.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return fmt.Errorf("saving streak: %w", err)
	}

	return nil
}

// --- Settings Repository ---

// MongoPersonCheckInSettingsRepository implements personcheckin.SettingsRepository.
type MongoPersonCheckInSettingsRepository struct {
	collection *mongo.Collection
}

// NewMongoPersonCheckInSettingsRepository creates a new settings repository.
func NewMongoPersonCheckInSettingsRepository(db *mongo.Database) *MongoPersonCheckInSettingsRepository {
	return &MongoPersonCheckInSettingsRepository{
		collection: db.Collection(personCheckInCollection),
	}
}

// Get retrieves settings for a user, returning defaults if none exist.
func (r *MongoPersonCheckInSettingsRepository) Get(ctx context.Context, userID string) (*personcheckin.PersonCheckInSettings, error) {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", userID),
		"SK": "PERSON_CHECKIN_SETTINGS",
	}

	var doc bson.M
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("settings not found")
		}
		return nil, fmt.Errorf("finding settings: %w", err)
	}

	return docToSettings(doc, userID), nil
}

// Save creates or updates settings for a user.
func (r *MongoPersonCheckInSettingsRepository) Save(ctx context.Context, settings *personcheckin.PersonCheckInSettings) error {
	filter := bson.M{
		"PK": fmt.Sprintf("USER#%s", settings.UserID),
		"SK": "PERSON_CHECKIN_SETTINGS",
	}

	update := bson.M{
		"$set": bson.M{
			"EntityType":    personCheckInSettingsEntity,
			"TenantId":      settings.TenantID,
			"ModifiedAt":    settings.ModifiedAt,
			"spouse":        subTypeSettingsToDoc(settings.Spouse),
			"sponsor":       subTypeSettingsToDoc(settings.Sponsor),
			"counselorCoach": subTypeSettingsToDoc(settings.CounselorCoach),
		},
		"$setOnInsert": bson.M{
			"PK":        fmt.Sprintf("USER#%s", settings.UserID),
			"SK":        "PERSON_CHECKIN_SETTINGS",
			"CreatedAt": settings.CreatedAt,
		},
	}

	opts := options.UpdateOne().SetUpsert(true)
	_, err := r.collection.UpdateOne(ctx, filter, update, opts)
	if err != nil {
		return fmt.Errorf("saving settings: %w", err)
	}

	return nil
}

// --- Helper functions ---

func docToPersonCheckIn(doc bson.M) *personcheckin.PersonCheckIn {
	ci := &personcheckin.PersonCheckIn{
		CheckInID:   getStringField(doc, "checkInId"),
		CheckInType: personcheckin.CheckInType(getStringField(doc, "checkInType")),
		Method:      personcheckin.Method(getStringField(doc, "method")),
	}

	if ts, ok := doc["timestamp"].(time.Time); ok {
		ci.Timestamp = ts
	}
	if ts, ok := doc["CreatedAt"].(time.Time); ok {
		ci.CreatedAt = ts
	}
	if ts, ok := doc["ModifiedAt"].(time.Time); ok {
		ci.ModifiedAt = ts
	}

	if v, ok := doc["contactName"].(*string); ok {
		ci.ContactName = v
	} else if v, ok := doc["contactName"].(string); ok && v != "" {
		ci.ContactName = &v
	}

	if v, ok := doc["durationMinutes"].(int32); ok {
		val := int(v)
		ci.DurationMinutes = &val
	}
	if v, ok := doc["qualityRating"].(int32); ok {
		val := int(v)
		ci.QualityRating = &val
	}

	if topics, ok := doc["topicsDiscussed"].(bson.A); ok {
		for _, t := range topics {
			if s, ok := t.(string); ok {
				ci.TopicsDiscussed = append(ci.TopicsDiscussed, personcheckin.Topic(s))
			}
		}
	}

	if v, ok := doc["notes"].(string); ok && v != "" {
		ci.Notes = &v
	}

	if items, ok := doc["followUpItems"].(bson.A); ok {
		for _, item := range items {
			if m, ok := item.(bson.M); ok {
				fi := personcheckin.FollowUpItem{
					Text: getStringField(m, "text"),
				}
				if gid, ok := m["goalId"].(string); ok && gid != "" {
					fi.GoalID = &gid
				}
				ci.FollowUpItems = append(ci.FollowUpItems, fi)
			}
		}
	}

	if v, ok := doc["counselorSubCategory"].(string); ok && v != "" {
		cat := personcheckin.CounselorSubCategory(v)
		ci.CounselorSubCategory = &cat
	}

	return ci
}

func docToStreak(doc bson.M) *personcheckin.PersonCheckInStreak {
	s := &personcheckin.PersonCheckInStreak{
		CheckInType: personcheckin.CheckInType(getStringField(doc, "checkInType")),
		StreakUnit:  getStringField(doc, "streakUnit"),
	}

	if v, ok := doc["currentStreak"].(int32); ok {
		s.CurrentStreak = int(v)
	}
	if v, ok := doc["longestStreak"].(int32); ok {
		s.LongestStreak = int(v)
	}
	if v, ok := doc["checkInsThisWeek"].(int32); ok {
		s.CheckInsThisWeek = int(v)
	}
	if v, ok := doc["checkInsThisMonth"].(int32); ok {
		s.CheckInsThisMonth = int(v)
	}
	if v, ok := doc["averagePerWeek"].(float64); ok {
		s.AveragePerWeek = v
	}
	if v, ok := doc["lastCheckInDate"].(string); ok && v != "" {
		s.LastCheckInDate = &v
	}

	return s
}

func docToSettings(doc bson.M, userID string) *personcheckin.PersonCheckInSettings {
	settings := &personcheckin.PersonCheckInSettings{
		UserID: userID,
	}

	if v, ok := doc["TenantId"].(string); ok {
		settings.TenantID = v
	}
	if v, ok := doc["CreatedAt"].(time.Time); ok {
		settings.CreatedAt = v
	}
	if v, ok := doc["ModifiedAt"].(time.Time); ok {
		settings.ModifiedAt = v
	}

	if spouse, ok := doc["spouse"].(bson.M); ok {
		settings.Spouse = docToSubTypeSettings(spouse)
	}
	if sponsor, ok := doc["sponsor"].(bson.M); ok {
		settings.Sponsor = docToSubTypeSettings(sponsor)
	}
	if cc, ok := doc["counselorCoach"].(bson.M); ok {
		settings.CounselorCoach = docToSubTypeSettings(cc)
	}

	return settings
}

func docToSubTypeSettings(doc bson.M) personcheckin.SubTypeSettings {
	s := personcheckin.SubTypeSettings{
		StreakFrequency: personcheckin.StreakFrequency(getStringField(doc, "streakFrequency")),
		ReminderEnabled: false,
	}

	if v, ok := doc["contactName"].(string); ok && v != "" {
		s.ContactName = &v
	}
	if v, ok := doc["inactivityAlertDays"].(int32); ok {
		s.InactivityAlertDays = int(v)
	}
	if v, ok := doc["reminderEnabled"].(bool); ok {
		s.ReminderEnabled = v
	}
	if v, ok := doc["reminderTime"].(string); ok && v != "" {
		s.ReminderTime = &v
	}
	if v, ok := doc["reminderFrequency"].(string); ok && v != "" {
		s.ReminderFrequency = &v
	}
	if v, ok := doc["lastUsedMethod"].(string); ok && v != "" {
		m := personcheckin.Method(v)
		s.LastUsedMethod = &m
	}
	if v, ok := doc["requiredCountPerWeek"].(int32); ok {
		val := int(v)
		s.RequiredCountPerWeek = &val
	}

	return s
}

func subTypeSettingsToDoc(s personcheckin.SubTypeSettings) bson.M {
	doc := bson.M{
		"streakFrequency":     string(s.StreakFrequency),
		"inactivityAlertDays": s.InactivityAlertDays,
		"reminderEnabled":     s.ReminderEnabled,
	}

	if s.ContactName != nil {
		doc["contactName"] = *s.ContactName
	}
	if s.RequiredCountPerWeek != nil {
		doc["requiredCountPerWeek"] = *s.RequiredCountPerWeek
	}
	if s.ReminderTime != nil {
		doc["reminderTime"] = *s.ReminderTime
	}
	if s.ReminderFrequency != nil {
		doc["reminderFrequency"] = *s.ReminderFrequency
	}
	if s.LastUsedMethod != nil {
		doc["lastUsedMethod"] = string(*s.LastUsedMethod)
	}

	return doc
}

func getStringField(doc bson.M, key string) string {
	if v, ok := doc[key].(string); ok {
		return v
	}
	return ""
}
