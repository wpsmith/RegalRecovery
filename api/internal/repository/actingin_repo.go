// internal/repository/actingin_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/regalrecovery/api/internal/domain/actingin"
)

// MongoActingInRepository implements actingin.ActingInRepository using MongoDB.
type MongoActingInRepository struct {
	db *mongo.Database
}

// NewMongoActingInRepository creates a new MongoDB-backed acting-in repository.
func NewMongoActingInRepository(db *mongo.Database) *MongoActingInRepository {
	return &MongoActingInRepository{db: db}
}

// collection returns the main user-scoped collection.
func (r *MongoActingInRepository) collection() *mongo.Collection {
	return r.db.Collection("actingInBehaviors")
}

// checkInCollection returns the check-in entries collection.
func (r *MongoActingInRepository) checkInCollection() *mongo.Collection {
	return r.db.Collection("userActivities")
}

// calendarCollection returns the calendar activities collection.
func (r *MongoActingInRepository) calendarCollection() *mongo.Collection {
	return r.db.Collection("calendarActivities")
}

// GetBehaviorConfig retrieves the user's behavior configuration.
func (r *MongoActingInRepository) GetBehaviorConfig(ctx context.Context, userID string) (*actingin.BehaviorConfig, error) {
	pk := fmt.Sprintf("USER#%s", userID)
	sk := "ACTINGIN_CONFIG"

	var doc ActingInConfigDoc
	err := r.collection().FindOne(ctx, bson.M{"PK": pk, "SK": sk}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding behavior config: %w", err)
	}

	return doc.ToDomain(userID), nil
}

// SaveBehaviorConfig creates or updates the user's behavior configuration.
func (r *MongoActingInRepository) SaveBehaviorConfig(ctx context.Context, config *actingin.BehaviorConfig) error {
	pk := fmt.Sprintf("USER#%s", config.UserID)
	sk := "ACTINGIN_CONFIG"

	doc := NewActingInConfigDoc(config)
	opts := options.Replace().SetUpsert(true)

	_, err := r.collection().ReplaceOne(ctx, bson.M{"PK": pk, "SK": sk}, doc, opts)
	if err != nil {
		return fmt.Errorf("saving behavior config: %w", err)
	}
	return nil
}

// GetSettings retrieves the user's acting-in settings.
func (r *MongoActingInRepository) GetSettings(ctx context.Context, userID string) (*actingin.Settings, error) {
	pk := fmt.Sprintf("USER#%s", userID)
	sk := "ACTINGIN_SETTINGS"

	var doc ActingInSettingsDoc
	err := r.checkInCollection().FindOne(ctx, bson.M{"PK": pk, "SK": sk}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding settings: %w", err)
	}

	return doc.ToDomain(userID), nil
}

// SaveSettings creates or updates the user's acting-in settings.
func (r *MongoActingInRepository) SaveSettings(ctx context.Context, settings *actingin.Settings) error {
	pk := fmt.Sprintf("USER#%s", settings.UserID)
	sk := "ACTINGIN_SETTINGS"

	doc := NewActingInSettingsDoc(settings)
	opts := options.Replace().SetUpsert(true)

	_, err := r.checkInCollection().ReplaceOne(ctx, bson.M{"PK": pk, "SK": sk}, doc, opts)
	if err != nil {
		return fmt.Errorf("saving settings: %w", err)
	}
	return nil
}

// CreateCheckIn persists a new check-in record.
func (r *MongoActingInRepository) CreateCheckIn(ctx context.Context, checkIn *actingin.CheckIn) error {
	pk := fmt.Sprintf("USER#%s", checkIn.UserID)
	sk := fmt.Sprintf("ACTINGIN_CHECKIN#%s", checkIn.Timestamp.Format(time.RFC3339))

	doc := NewActingInCheckInDoc(checkIn, pk, sk)
	_, err := r.checkInCollection().InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting check-in: %w", err)
	}
	return nil
}

// GetCheckIn retrieves a specific check-in by ID.
func (r *MongoActingInRepository) GetCheckIn(ctx context.Context, userID, checkInID string) (*actingin.CheckIn, error) {
	pk := fmt.Sprintf("USER#%s", userID)

	var doc ActingInCheckInDoc
	err := r.checkInCollection().FindOne(ctx, bson.M{
		"PK":        pk,
		"checkInId": checkInID,
	}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding check-in: %w", err)
	}

	return doc.ToDomain(userID), nil
}

// ListCheckIns retrieves check-ins with cursor-based pagination and optional filters.
func (r *MongoActingInRepository) ListCheckIns(ctx context.Context, userID string, filters actingin.CheckInFilters, cursor string, limit int) ([]actingin.CheckIn, string, error) {
	pk := fmt.Sprintf("USER#%s", userID)

	filter := bson.M{
		"PK":         pk,
		"entityType": "ACTINGIN_CHECKIN",
	}

	if filters.StartDate != nil || filters.EndDate != nil {
		skFilter := bson.M{}
		if filters.StartDate != nil {
			skFilter["$gte"] = fmt.Sprintf("ACTINGIN_CHECKIN#%s", filters.StartDate.Format(time.RFC3339))
		}
		if filters.EndDate != nil {
			skFilter["$lte"] = fmt.Sprintf("ACTINGIN_CHECKIN#%s", filters.EndDate.Format(time.RFC3339))
		}
		filter["SK"] = skFilter
	}

	if filters.BehaviorID != "" {
		filter["behaviors.behaviorId"] = filters.BehaviorID
	}
	if filters.Trigger != "" {
		filter["triggers"] = string(filters.Trigger)
	}
	if filters.RelationshipTag != "" {
		filter["relationshipTags"] = string(filters.RelationshipTag)
	}

	if cursor != "" {
		filter["SK"] = bson.M{"$lt": cursor}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "SK", Value: -1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.checkInCollection().Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("querying check-ins: %w", err)
	}
	defer cur.Close(ctx)

	var docs []ActingInCheckInDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding check-ins: %w", err)
	}

	nextCursor := ""
	if len(docs) > limit {
		nextCursor = docs[limit].SK
		docs = docs[:limit]
	}

	checkIns := make([]actingin.CheckIn, len(docs))
	for i, doc := range docs {
		checkIns[i] = *doc.ToDomain(userID)
	}

	return checkIns, nextCursor, nil
}

// GetCheckInsByDateRange retrieves all check-ins in a date range.
func (r *MongoActingInRepository) GetCheckInsByDateRange(ctx context.Context, userID string, start, end time.Time) ([]actingin.CheckIn, error) {
	pk := fmt.Sprintf("USER#%s", userID)

	filter := bson.M{
		"PK":         pk,
		"entityType": "ACTINGIN_CHECKIN",
		"SK": bson.M{
			"$gte": fmt.Sprintf("ACTINGIN_CHECKIN#%s", start.Format(time.RFC3339)),
			"$lte": fmt.Sprintf("ACTINGIN_CHECKIN#%s", end.Format(time.RFC3339)),
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "SK", Value: -1}})

	cur, err := r.checkInCollection().Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("querying check-ins by range: %w", err)
	}
	defer cur.Close(ctx)

	var docs []ActingInCheckInDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding check-ins: %w", err)
	}

	checkIns := make([]actingin.CheckIn, len(docs))
	for i, doc := range docs {
		checkIns[i] = *doc.ToDomain(userID)
	}

	return checkIns, nil
}

// GetCheckInDates retrieves the timestamps of all check-ins for streak calculation.
func (r *MongoActingInRepository) GetCheckInDates(ctx context.Context, userID string) ([]time.Time, error) {
	pk := fmt.Sprintf("USER#%s", userID)

	filter := bson.M{
		"PK":         pk,
		"entityType": "ACTINGIN_CHECKIN",
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "SK", Value: -1}}).
		SetProjection(bson.M{"timestamp": 1})

	cur, err := r.checkInCollection().Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("querying check-in dates: %w", err)
	}
	defer cur.Close(ctx)

	var dates []time.Time
	for cur.Next(ctx) {
		var doc struct {
			Timestamp time.Time `bson:"timestamp"`
		}
		if err := cur.Decode(&doc); err != nil {
			continue
		}
		dates = append(dates, doc.Timestamp)
	}

	return dates, nil
}

// CreateCalendarActivity writes the dual-write calendar activity entry.
func (r *MongoActingInRepository) CreateCalendarActivity(ctx context.Context, userID string, checkIn *actingin.CheckIn) error {
	pk := fmt.Sprintf("USER#%s", userID)
	date := checkIn.Timestamp.Format("2006-01-02")
	sk := fmt.Sprintf("ACTIVITY#%s#ACTINGIN_CHECKIN#%s", date, checkIn.Timestamp.Format(time.RFC3339))

	doc := bson.M{
		"PK":           pk,
		"SK":           sk,
		"entityType":   "CALENDAR_ACTIVITY",
		"activityType": "ACTINGIN_CHECKIN",
		"summary":      bson.M{"behaviorCount": checkIn.BehaviorCount},
		"sourceKey":    fmt.Sprintf("ACTINGIN_CHECKIN#%s", checkIn.Timestamp.Format(time.RFC3339)),
		"date":         date,
		"timestamp":    checkIn.Timestamp,
		"createdAt":    time.Now().UTC(),
	}

	_, err := r.calendarCollection().InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting calendar activity: %w", err)
	}
	return nil
}

// --- Document models for MongoDB ---

// ActingInConfigDoc represents the MongoDB document for behavior configuration.
type ActingInConfigDoc struct {
	PK              string                    `bson:"PK"`
	SK              string                    `bson:"SK"`
	EntityType      string                    `bson:"entityType"`
	TenantID        string                    `bson:"tenantId"`
	CreatedAt       time.Time                 `bson:"createdAt"`
	ModifiedAt      time.Time                 `bson:"modifiedAt"`
	Defaults        map[string]DefaultStateDoc `bson:"defaults"`
	CustomBehaviors []CustomBehaviorDoc       `bson:"customBehaviors"`
}

// DefaultStateDoc represents enabled/disabled state in MongoDB.
type DefaultStateDoc struct {
	Enabled   bool `bson:"enabled"`
	SortOrder int  `bson:"sortOrder"`
}

// CustomBehaviorDoc represents a custom behavior in MongoDB.
type CustomBehaviorDoc struct {
	BehaviorID  string    `bson:"behaviorId"`
	Name        string    `bson:"name"`
	Description string    `bson:"description,omitempty"`
	Enabled     bool      `bson:"enabled"`
	SortOrder   int       `bson:"sortOrder"`
	CreatedAt   time.Time `bson:"createdAt"`
}

// NewActingInConfigDoc creates a MongoDB document from a domain BehaviorConfig.
func NewActingInConfigDoc(config *actingin.BehaviorConfig) *ActingInConfigDoc {
	defaults := make(map[string]DefaultStateDoc, len(config.Defaults))
	for id, state := range config.Defaults {
		defaults[id] = DefaultStateDoc{
			Enabled:   state.Enabled,
			SortOrder: state.SortOrder,
		}
	}

	customs := make([]CustomBehaviorDoc, len(config.CustomBehaviors))
	for i, cb := range config.CustomBehaviors {
		customs[i] = CustomBehaviorDoc{
			BehaviorID:  cb.BehaviorID,
			Name:        cb.Name,
			Description: cb.Description,
			Enabled:     cb.Enabled,
			SortOrder:   cb.SortOrder,
			CreatedAt:   cb.CreatedAt,
		}
	}

	return &ActingInConfigDoc{
		PK:              fmt.Sprintf("USER#%s", config.UserID),
		SK:              "ACTINGIN_CONFIG",
		EntityType:      "ACTINGIN_CONFIG",
		TenantID:        "DEFAULT",
		CreatedAt:       config.CreatedAt,
		ModifiedAt:      config.ModifiedAt,
		Defaults:        defaults,
		CustomBehaviors: customs,
	}
}

// ToDomain converts a MongoDB document to a domain BehaviorConfig.
func (d *ActingInConfigDoc) ToDomain(userID string) *actingin.BehaviorConfig {
	defaults := make(map[string]actingin.DefaultState, len(d.Defaults))
	for id, state := range d.Defaults {
		defaults[id] = actingin.DefaultState{
			Enabled:   state.Enabled,
			SortOrder: state.SortOrder,
		}
	}

	customs := make([]actingin.CustomBehavior, len(d.CustomBehaviors))
	for i, cb := range d.CustomBehaviors {
		customs[i] = actingin.CustomBehavior{
			BehaviorID:  cb.BehaviorID,
			Name:        cb.Name,
			Description: cb.Description,
			Enabled:     cb.Enabled,
			SortOrder:   cb.SortOrder,
			CreatedAt:   cb.CreatedAt,
		}
	}

	return &actingin.BehaviorConfig{
		UserID:          userID,
		Defaults:        defaults,
		CustomBehaviors: customs,
		CreatedAt:       d.CreatedAt,
		ModifiedAt:      d.ModifiedAt,
	}
}

// ActingInSettingsDoc represents the MongoDB document for settings.
type ActingInSettingsDoc struct {
	PK              string     `bson:"PK"`
	SK              string     `bson:"SK"`
	EntityType      string     `bson:"entityType"`
	TenantID        string     `bson:"tenantId"`
	CreatedAt       time.Time  `bson:"createdAt"`
	ModifiedAt      time.Time  `bson:"modifiedAt"`
	Frequency       string     `bson:"frequency"`
	ReminderTime    string     `bson:"reminderTime"`
	ReminderDay     string     `bson:"reminderDay"`
	FirstUseCompleted bool     `bson:"firstUseCompleted"`
	StreakCount      int       `bson:"streakCount"`
	LastCheckInAt   *time.Time `bson:"lastCheckInAt,omitempty"`
}

// NewActingInSettingsDoc creates a MongoDB document from domain Settings.
func NewActingInSettingsDoc(s *actingin.Settings) *ActingInSettingsDoc {
	return &ActingInSettingsDoc{
		PK:                fmt.Sprintf("USER#%s", s.UserID),
		SK:                "ACTINGIN_SETTINGS",
		EntityType:        "ACTINGIN_SETTINGS",
		TenantID:          "DEFAULT",
		CreatedAt:         s.CreatedAt,
		ModifiedAt:        s.ModifiedAt,
		Frequency:         string(s.Frequency),
		ReminderTime:      s.ReminderTime,
		ReminderDay:       string(s.ReminderDay),
		FirstUseCompleted: s.FirstUseCompleted,
		StreakCount:       s.StreakCount,
		LastCheckInAt:     s.LastCheckInAt,
	}
}

// ToDomain converts a MongoDB document to domain Settings.
func (d *ActingInSettingsDoc) ToDomain(userID string) *actingin.Settings {
	return &actingin.Settings{
		UserID:            userID,
		Frequency:         actingin.Frequency(d.Frequency),
		ReminderTime:      d.ReminderTime,
		ReminderDay:       actingin.Weekday(d.ReminderDay),
		FirstUseCompleted: d.FirstUseCompleted,
		StreakCount:       d.StreakCount,
		LastCheckInAt:     d.LastCheckInAt,
		CreatedAt:         d.CreatedAt,
		ModifiedAt:        d.ModifiedAt,
	}
}

// ActingInCheckInDoc represents the MongoDB document for a check-in.
type ActingInCheckInDoc struct {
	PK               string                     `bson:"PK"`
	SK               string                     `bson:"SK"`
	EntityType       string                     `bson:"entityType"`
	TenantID         string                     `bson:"tenantId"`
	CreatedAt        time.Time                  `bson:"createdAt"`
	ModifiedAt       time.Time                  `bson:"modifiedAt"`
	CheckInID        string                     `bson:"checkInId"`
	Timestamp        time.Time                  `bson:"timestamp"`
	BehaviorCount    int                        `bson:"behaviorCount"`
	Behaviors        []CheckedBehaviorDoc       `bson:"behaviors"`
	Triggers         []string                   `bson:"triggers"`
	RelationshipTags []string                   `bson:"relationshipTags"`
}

// CheckedBehaviorDoc represents a checked behavior in MongoDB.
type CheckedBehaviorDoc struct {
	BehaviorID      string `bson:"behaviorId"`
	BehaviorName    string `bson:"behaviorName"`
	ContextNote     string `bson:"contextNote,omitempty"`
	Trigger         string `bson:"trigger,omitempty"`
	RelationshipTag string `bson:"relationshipTag,omitempty"`
}

// NewActingInCheckInDoc creates a MongoDB document from a domain CheckIn.
func NewActingInCheckInDoc(ci *actingin.CheckIn, pk, sk string) *ActingInCheckInDoc {
	behaviors := make([]CheckedBehaviorDoc, len(ci.Behaviors))
	for i, b := range ci.Behaviors {
		behaviors[i] = CheckedBehaviorDoc{
			BehaviorID:      b.BehaviorID,
			BehaviorName:    b.BehaviorName,
			ContextNote:     b.ContextNote,
			Trigger:         string(b.Trigger),
			RelationshipTag: string(b.RelationshipTag),
		}
	}

	triggers := make([]string, len(ci.Triggers))
	for i, t := range ci.Triggers {
		triggers[i] = string(t)
	}

	tags := make([]string, len(ci.RelationshipTags))
	for i, t := range ci.RelationshipTags {
		tags[i] = string(t)
	}

	return &ActingInCheckInDoc{
		PK:               pk,
		SK:               sk,
		EntityType:       "ACTINGIN_CHECKIN",
		TenantID:         "DEFAULT",
		CreatedAt:        ci.CreatedAt,
		ModifiedAt:       ci.ModifiedAt,
		CheckInID:        ci.CheckInID,
		Timestamp:        ci.Timestamp,
		BehaviorCount:    ci.BehaviorCount,
		Behaviors:        behaviors,
		Triggers:         triggers,
		RelationshipTags: tags,
	}
}

// ToDomain converts a MongoDB document to a domain CheckIn.
func (d *ActingInCheckInDoc) ToDomain(userID string) *actingin.CheckIn {
	behaviors := make([]actingin.CheckedBehavior, len(d.Behaviors))
	for i, b := range d.Behaviors {
		behaviors[i] = actingin.CheckedBehavior{
			BehaviorID:      b.BehaviorID,
			BehaviorName:    b.BehaviorName,
			ContextNote:     b.ContextNote,
			Trigger:         actingin.Trigger(b.Trigger),
			RelationshipTag: actingin.RelationshipTag(b.RelationshipTag),
		}
	}

	triggers := make([]actingin.Trigger, len(d.Triggers))
	for i, t := range d.Triggers {
		triggers[i] = actingin.Trigger(t)
	}

	tags := make([]actingin.RelationshipTag, len(d.RelationshipTags))
	for i, t := range d.RelationshipTags {
		tags[i] = actingin.RelationshipTag(t)
	}

	return &actingin.CheckIn{
		CheckInID:        d.CheckInID,
		UserID:           userID,
		Timestamp:        d.Timestamp,
		BehaviorCount:    d.BehaviorCount,
		Behaviors:        behaviors,
		Triggers:         triggers,
		RelationshipTags: tags,
		CreatedAt:        d.CreatedAt,
		ModifiedAt:       d.ModifiedAt,
	}
}
