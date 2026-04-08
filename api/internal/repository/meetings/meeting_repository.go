// internal/repository/meetings/meeting_repository.go
package meetings

import (
	"context"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/repository"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const (
	meetingsCollection          = "meetings"
	calendarActivitiesCollection = "activities"
)

// MeetingLogDoc is the MongoDB document for a meeting log.
type MeetingLogDoc struct {
	repository.BaseDocument `bson:",inline"`

	UserID          string  `bson:"userId"`
	MeetingID       string  `bson:"meetingId"`
	Timestamp       time.Time `bson:"timestamp"`
	MeetingType     string  `bson:"meetingType"`
	CustomTypeLabel *string `bson:"customTypeLabel,omitempty"`
	Name            *string `bson:"name,omitempty"`
	Location        *string `bson:"location,omitempty"`
	DurationMinutes *int    `bson:"durationMinutes,omitempty"`
	Notes           *string `bson:"notes,omitempty"`
	Status          string  `bson:"status"`
	SavedMeetingID  *string `bson:"savedMeetingId,omitempty"`
}

// CalendarActivityDoc is the MongoDB document for a calendar activity dual-write.
type CalendarActivityDoc struct {
	repository.BaseDocument `bson:",inline"`

	UserID       string                 `bson:"userId"`
	ActivityType string                 `bson:"activityType"`
	Date         string                 `bson:"date"` // YYYY-MM-DD
	Timestamp    time.Time              `bson:"timestamp"`
	Summary      map[string]interface{} `bson:"summary"`
	SourceKey    string                 `bson:"sourceKey"`
}

// MongoMeetingRepository implements meetings.MeetingRepository using MongoDB.
type MongoMeetingRepository struct {
	client *repository.MongoClient
}

// NewMongoMeetingRepository creates a new MongoDB-backed meeting repository.
func NewMongoMeetingRepository(client *repository.MongoClient) *MongoMeetingRepository {
	return &MongoMeetingRepository{client: client}
}

// Create creates a new meeting log and its calendar activity dual-write.
func (r *MongoMeetingRepository) Create(ctx context.Context, meeting *meetings.MeetingLog) error {
	doc := toMeetingLogDoc(meeting)
	repository.SetBaseDocumentDefaults(&doc.BaseDocument)

	_, err := r.client.Collection(meetingsCollection).InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting meeting log: %w", err)
	}

	// Calendar activity dual-write.
	calDoc := &CalendarActivityDoc{
		UserID:       meeting.UserID,
		ActivityType: "MEETING",
		Date:         meeting.Timestamp.Format("2006-01-02"),
		Timestamp:    meeting.Timestamp,
		Summary: map[string]interface{}{
			"meetingType": string(meeting.MeetingType),
			"status":      string(meeting.Status),
		},
		SourceKey: "MEETING#" + meeting.MeetingID,
	}
	if meeting.Name != nil {
		calDoc.Summary["name"] = *meeting.Name
	}
	repository.SetBaseDocumentDefaults(&calDoc.BaseDocument)
	calDoc.TenantID = meeting.TenantID

	_, err = r.client.Collection(calendarActivitiesCollection).InsertOne(ctx, calDoc)
	if err != nil {
		return fmt.Errorf("inserting calendar activity: %w", err)
	}

	return nil
}

// GetByID retrieves a meeting log by its meetingId.
func (r *MongoMeetingRepository) GetByID(ctx context.Context, userID, meetingID string) (*meetings.MeetingLog, error) {
	filter := bson.M{"userId": userID, "meetingId": meetingID}

	var doc MeetingLogDoc
	err := r.client.Collection(meetingsCollection).FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding meeting log: %w", err)
	}

	return fromMeetingLogDoc(&doc), nil
}

// ListByUser retrieves meeting logs for a user with filters and cursor pagination.
func (r *MongoMeetingRepository) ListByUser(ctx context.Context, userID string, filter meetings.ListMeetingLogsFilter) ([]*meetings.MeetingLog, string, error) {
	mongoFilter := bson.M{"userId": userID}

	if filter.MeetingType != nil {
		mongoFilter["meetingType"] = string(*filter.MeetingType)
	}

	if filter.StartDate != nil || filter.EndDate != nil {
		tsFilter := bson.M{}
		if filter.StartDate != nil {
			tsFilter["$gte"] = *filter.StartDate
		}
		if filter.EndDate != nil {
			tsFilter["$lte"] = *filter.EndDate
		}
		mongoFilter["timestamp"] = tsFilter
	}

	// Cursor-based pagination: decode cursor as a timestamp.
	if filter.Cursor != "" {
		cursorBytes, err := base64.StdEncoding.DecodeString(filter.Cursor)
		if err == nil {
			cursorTime, err := time.Parse(time.RFC3339Nano, string(cursorBytes))
			if err == nil {
				if filter.Sort == "timestamp" {
					mongoFilter["timestamp"] = bson.M{"$gt": cursorTime}
				} else {
					mongoFilter["timestamp"] = bson.M{"$lt": cursorTime}
				}
			}
		}
	}

	// Sort direction.
	sortDir := -1 // Newest first (default).
	if filter.Sort == "timestamp" {
		sortDir = 1
	}

	limit := int64(filter.Limit)
	if limit <= 0 {
		limit = 50
	}
	// Fetch one extra to determine if there are more results.
	fetchLimit := limit + 1

	opts := options.Find().
		SetSort(bson.D{{Key: "timestamp", Value: sortDir}}).
		SetLimit(fetchLimit)

	cursor, err := r.client.Collection(meetingsCollection).Find(ctx, mongoFilter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("finding meeting logs: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []MeetingLogDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding meeting logs: %w", err)
	}

	hasMore := int64(len(docs)) > limit
	if hasMore {
		docs = docs[:limit]
	}

	result := make([]*meetings.MeetingLog, 0, len(docs))
	for _, doc := range docs {
		result = append(result, fromMeetingLogDoc(&doc))
	}

	nextCursor := ""
	if hasMore && len(docs) > 0 {
		lastTimestamp := docs[len(docs)-1].Timestamp.Format(time.RFC3339Nano)
		nextCursor = base64.StdEncoding.EncodeToString([]byte(lastTimestamp))
	}

	return result, nextCursor, nil
}

// Update updates an existing meeting log.
func (r *MongoMeetingRepository) Update(ctx context.Context, meeting *meetings.MeetingLog) error {
	filter := bson.M{"userId": meeting.UserID, "meetingId": meeting.MeetingID}

	update := bson.M{
		"$set": bson.M{
			"meetingType":     string(meeting.MeetingType),
			"customTypeLabel": meeting.CustomTypeLabel,
			"name":            meeting.Name,
			"location":        meeting.Location,
			"durationMinutes": meeting.DurationMinutes,
			"notes":           meeting.Notes,
			"status":          string(meeting.Status),
			"modifiedAt":      meeting.ModifiedAt,
		},
	}

	result, err := r.client.Collection(meetingsCollection).UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating meeting log: %w", err)
	}
	if result.MatchedCount == 0 {
		return meetings.ErrMeetingNotFound
	}

	return nil
}

// Delete permanently removes a meeting log and its calendar activity.
func (r *MongoMeetingRepository) Delete(ctx context.Context, userID, meetingID string) error {
	// Delete the meeting log.
	filter := bson.M{"userId": userID, "meetingId": meetingID}
	result, err := r.client.Collection(meetingsCollection).DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting meeting log: %w", err)
	}
	if result.DeletedCount == 0 {
		return meetings.ErrMeetingNotFound
	}

	// Delete the calendar activity dual-write.
	calFilter := bson.M{
		"userId":    userID,
		"sourceKey": "MEETING#" + meetingID,
	}
	_, _ = r.client.Collection(calendarActivitiesCollection).DeleteOne(ctx, calFilter)

	return nil
}

// GetMeetingsInRange retrieves all meeting logs for a user within a date range.
func (r *MongoMeetingRepository) GetMeetingsInRange(ctx context.Context, userID string, start, end time.Time) ([]*meetings.MeetingLog, error) {
	filter := bson.M{
		"userId": userID,
		"timestamp": bson.M{
			"$gte": start,
			"$lte": end.Add(24*time.Hour - time.Nanosecond),
		},
	}

	opts := options.Find().SetSort(bson.D{{Key: "timestamp", Value: -1}})

	cursor, err := r.client.Collection(meetingsCollection).Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("finding meetings in range: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []MeetingLogDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding meetings: %w", err)
	}

	result := make([]*meetings.MeetingLog, 0, len(docs))
	for _, doc := range docs {
		result = append(result, fromMeetingLogDoc(&doc))
	}

	return result, nil
}

// --- Conversion helpers ---

func toMeetingLogDoc(m *meetings.MeetingLog) *MeetingLogDoc {
	return &MeetingLogDoc{
		BaseDocument: repository.BaseDocument{
			CreatedAt:  m.CreatedAt,
			ModifiedAt: m.ModifiedAt,
			TenantID:   m.TenantID,
		},
		UserID:          m.UserID,
		MeetingID:       m.MeetingID,
		Timestamp:       m.Timestamp,
		MeetingType:     string(m.MeetingType),
		CustomTypeLabel: m.CustomTypeLabel,
		Name:            m.Name,
		Location:        m.Location,
		DurationMinutes: m.DurationMinutes,
		Notes:           m.Notes,
		Status:          string(m.Status),
		SavedMeetingID:  m.SavedMeetingID,
	}
}

func fromMeetingLogDoc(doc *MeetingLogDoc) *meetings.MeetingLog {
	return &meetings.MeetingLog{
		MeetingID:       doc.MeetingID,
		UserID:          doc.UserID,
		TenantID:        doc.TenantID,
		Timestamp:       doc.Timestamp,
		MeetingType:     meetings.MeetingType(doc.MeetingType),
		CustomTypeLabel: doc.CustomTypeLabel,
		Name:            doc.Name,
		Location:        doc.Location,
		DurationMinutes: doc.DurationMinutes,
		Notes:           doc.Notes,
		Status:          meetings.MeetingStatus(doc.Status),
		SavedMeetingID:  doc.SavedMeetingID,
		CreatedAt:       doc.CreatedAt,
		ModifiedAt:      doc.ModifiedAt,
	}
}
