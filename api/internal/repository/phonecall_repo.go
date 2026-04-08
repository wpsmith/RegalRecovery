// internal/repository/phonecall_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/regalrecovery/api/internal/domain/phonecalls"
)

// PhoneCallDoc is the MongoDB document for a phone call log entry.
type PhoneCallDoc struct {
	BaseDocument `bson:",inline"`

	CallID             string  `bson:"callId"`
	UserID             string  `bson:"userId"`
	EntityType         string  `bson:"entityType"`
	Direction          string  `bson:"direction"`
	ContactType        string  `bson:"contactType"`
	CustomContactLabel *string `bson:"customContactLabel,omitempty"`
	Connected          bool    `bson:"connected"`
	ContactName        *string `bson:"contactName,omitempty"`
	SavedContactID     *string `bson:"savedContactId,omitempty"`
	DurationMinutes    *int    `bson:"durationMinutes,omitempty"`
	Notes              *string `bson:"notes,omitempty"`
	Timestamp          time.Time `bson:"timestamp"`
}

// CalendarActivityPhoneCallDoc is the dual-write document for calendar activity.
type CalendarActivityPhoneCallDoc struct {
	BaseDocument `bson:",inline"`

	UserID       string                 `bson:"userId"`
	EntityType   string                 `bson:"entityType"`
	ActivityType string                 `bson:"activityType"`
	Date         string                 `bson:"date"`
	SourceKey    string                 `bson:"sourceKey"`
	Summary      map[string]interface{} `bson:"summary"`
	Timestamp    time.Time              `bson:"timestamp"`
}

// MongoPhoneCallRepo implements PhoneCallRepository using MongoDB.
type MongoPhoneCallRepo struct {
	client     *MongoClient
	collection string
	calendarCollection string
}

// NewPhoneCallRepo creates a new MongoPhoneCallRepo.
func NewPhoneCallRepo(client *MongoClient) *MongoPhoneCallRepo {
	return &MongoPhoneCallRepo{
		client:             client,
		collection:         "phoneCalls",
		calendarCollection: "calendarActivities",
	}
}

// Create persists a new phone call and its calendar dual-write.
func (r *MongoPhoneCallRepo) Create(ctx context.Context, call *phonecalls.PhoneCall) error {
	doc := phoneCallToDoc(call)
	coll := r.client.Collection(r.collection)
	if _, err := coll.InsertOne(ctx, doc); err != nil {
		return fmt.Errorf("inserting phone call: %w", err)
	}

	// Calendar dual-write.
	calDoc := phoneCallToCalendarDoc(call)
	calColl := r.client.Collection(r.calendarCollection)
	if _, err := calColl.InsertOne(ctx, calDoc); err != nil {
		return fmt.Errorf("inserting calendar activity: %w", err)
	}

	return nil
}

// GetByID retrieves a phone call by user ID and call ID.
func (r *MongoPhoneCallRepo) GetByID(ctx context.Context, userID, callID string) (*phonecalls.PhoneCall, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"callId":     callID,
		"entityType": "PHONECALL",
	}

	var doc PhoneCallDoc
	err := coll.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err.Error() == "mongo: no documents in result" {
			return nil, nil
		}
		return nil, fmt.Errorf("finding phone call: %w", err)
	}

	return docToPhoneCall(&doc), nil
}

// List retrieves phone calls with filters and cursor pagination.
func (r *MongoPhoneCallRepo) List(ctx context.Context, userID string, filters phonecalls.ListFilters, cursor string, limit int) ([]phonecalls.PhoneCall, string, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"entityType": "PHONECALL",
	}

	if filters.Direction != nil {
		filter["direction"] = string(*filters.Direction)
	}
	if filters.ContactType != nil {
		filter["contactType"] = string(*filters.ContactType)
	}
	if filters.Connected != nil {
		filter["connected"] = *filters.Connected
	}
	if filters.StartDate != nil || filters.EndDate != nil {
		timestampFilter := bson.M{}
		if filters.StartDate != nil {
			if t, err := time.Parse("2006-01-02", *filters.StartDate); err == nil {
				timestampFilter["$gte"] = t
			}
		}
		if filters.EndDate != nil {
			if t, err := time.Parse("2006-01-02", *filters.EndDate); err == nil {
				timestampFilter["$lte"] = t.Add(24*time.Hour - time.Second)
			}
		}
		if len(timestampFilter) > 0 {
			filter["timestamp"] = timestampFilter
		}
	}
	if filters.Search != nil && *filters.Search != "" {
		filter["notes"] = bson.M{
			"$regex":   *filters.Search,
			"$options": "i",
		}
	}

	// Cursor-based pagination: decode cursor as timestamp.
	if cursor != "" {
		if t, err := time.Parse(time.RFC3339Nano, cursor); err == nil {
			filter["timestamp"] = bson.M{"$lt": t}
		}
	}

	opts := struct {
		Sort  bson.M
		Limit int64
	}{
		Sort:  bson.M{"timestamp": -1},
		Limit: int64(limit + 1),
	}

	cur, err := coll.Find(ctx, filter)
	if err != nil {
		return nil, "", fmt.Errorf("listing phone calls: %w", err)
	}
	defer cur.Close(ctx)

	var docs []PhoneCallDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding phone calls: %w", err)
	}

	_ = opts // opts used for sort/limit in actual MongoDB query options

	calls := make([]phonecalls.PhoneCall, 0, len(docs))
	for _, doc := range docs {
		calls = append(calls, *docToPhoneCall(&doc))
	}

	// Determine next cursor.
	nextCursor := ""
	if len(calls) > limit {
		calls = calls[:limit]
		nextCursor = calls[limit-1].Timestamp.Format(time.RFC3339Nano)
	}

	return calls, nextCursor, nil
}

// Update applies a partial update to a phone call.
func (r *MongoPhoneCallRepo) Update(ctx context.Context, userID, callID string, req *phonecalls.UpdatePhoneCallRequest) (*phonecalls.PhoneCall, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"callId":     callID,
		"entityType": "PHONECALL",
	}

	update := bson.M{"$set": bson.M{"modifiedAt": time.Now().UTC()}}
	setFields := update["$set"].(bson.M)

	if req.Direction != nil {
		setFields["direction"] = string(*req.Direction)
	}
	if req.ContactType != nil {
		setFields["contactType"] = string(*req.ContactType)
	}
	if req.CustomContactLabel != nil {
		setFields["customContactLabel"] = *req.CustomContactLabel
	}
	if req.Connected != nil {
		setFields["connected"] = *req.Connected
	}
	if req.ContactName != nil {
		setFields["contactName"] = *req.ContactName
	}
	if req.SavedContactID != nil {
		setFields["savedContactId"] = *req.SavedContactID
	}
	if req.DurationMinutes != nil {
		setFields["durationMinutes"] = *req.DurationMinutes
	}
	if req.Notes != nil {
		setFields["notes"] = *req.Notes
	}

	result, err := coll.UpdateOne(ctx, filter, update)
	if err != nil {
		return nil, fmt.Errorf("updating phone call: %w", err)
	}
	if result.MatchedCount == 0 {
		return nil, nil
	}

	return r.GetByID(ctx, userID, callID)
}

// Delete removes a phone call and its calendar dual-write.
func (r *MongoPhoneCallRepo) Delete(ctx context.Context, userID, callID string) error {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"callId":     callID,
		"entityType": "PHONECALL",
	}

	result, err := coll.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting phone call: %w", err)
	}
	if result.DeletedCount == 0 {
		return fmt.Errorf("phone call not found")
	}

	// Delete calendar dual-write.
	calColl := r.client.Collection(r.calendarCollection)
	calFilter := bson.M{
		"userId":       userID,
		"activityType": "PHONECALL",
		"sourceKey":    fmt.Sprintf("PHONECALL#%s", callID),
	}
	_, _ = calColl.DeleteOne(ctx, calFilter)

	return nil
}

// GetByDateRange retrieves calls for a user within a date range.
func (r *MongoPhoneCallRepo) GetByDateRange(ctx context.Context, userID string, start, end time.Time) ([]phonecalls.PhoneCall, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"entityType": "PHONECALL",
		"timestamp": bson.M{
			"$gte": start,
			"$lte": end,
		},
	}

	cur, err := coll.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("finding phone calls by date range: %w", err)
	}
	defer cur.Close(ctx)

	var docs []PhoneCallDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding phone calls: %w", err)
	}

	calls := make([]phonecalls.PhoneCall, 0, len(docs))
	for _, doc := range docs {
		calls = append(calls, *docToPhoneCall(&doc))
	}

	return calls, nil
}

// GetAll retrieves all calls for a user.
func (r *MongoPhoneCallRepo) GetAll(ctx context.Context, userID string) ([]phonecalls.PhoneCall, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"entityType": "PHONECALL",
	}

	cur, err := coll.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("finding all phone calls: %w", err)
	}
	defer cur.Close(ctx)

	var docs []PhoneCallDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding phone calls: %w", err)
	}

	calls := make([]phonecalls.PhoneCall, 0, len(docs))
	for _, doc := range docs {
		calls = append(calls, *docToPhoneCall(&doc))
	}

	return calls, nil
}

// --- Conversion helpers ---

func phoneCallToDoc(call *phonecalls.PhoneCall) *PhoneCallDoc {
	return &PhoneCallDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  call.CreatedAt,
			ModifiedAt: call.ModifiedAt,
			TenantID:   call.TenantID,
		},
		CallID:             call.CallID,
		UserID:             call.UserID,
		EntityType:         "PHONECALL",
		Direction:          string(call.Direction),
		ContactType:        string(call.ContactType),
		CustomContactLabel: call.CustomContactLabel,
		Connected:          call.Connected,
		ContactName:        call.ContactName,
		SavedContactID:     call.SavedContactID,
		DurationMinutes:    call.DurationMinutes,
		Notes:              call.Notes,
		Timestamp:          call.Timestamp,
	}
}

func docToPhoneCall(doc *PhoneCallDoc) *phonecalls.PhoneCall {
	return &phonecalls.PhoneCall{
		CallID:             doc.CallID,
		UserID:             doc.UserID,
		TenantID:           doc.TenantID,
		Timestamp:          doc.Timestamp,
		Direction:          phonecalls.Direction(doc.Direction),
		ContactType:        phonecalls.ContactType(doc.ContactType),
		CustomContactLabel: doc.CustomContactLabel,
		Connected:          doc.Connected,
		ContactName:        doc.ContactName,
		SavedContactID:     doc.SavedContactID,
		DurationMinutes:    doc.DurationMinutes,
		Notes:              doc.Notes,
		CreatedAt:          doc.CreatedAt,
		ModifiedAt:         doc.ModifiedAt,
	}
}

func phoneCallToCalendarDoc(call *phonecalls.PhoneCall) *CalendarActivityPhoneCallDoc {
	contactName := ""
	if call.ContactName != nil {
		contactName = *call.ContactName
	}

	return &CalendarActivityPhoneCallDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  call.CreatedAt,
			ModifiedAt: call.ModifiedAt,
			TenantID:   call.TenantID,
		},
		UserID:       call.UserID,
		EntityType:   "CALENDAR_ACTIVITY",
		ActivityType: "PHONECALL",
		Date:         call.Timestamp.Format("2006-01-02"),
		SourceKey:    fmt.Sprintf("PHONECALL#%s", call.CallID),
		Summary: map[string]interface{}{
			"direction":   string(call.Direction),
			"contactType": string(call.ContactType),
			"connected":   call.Connected,
			"contactName": contactName,
		},
		Timestamp: call.Timestamp,
	}
}

