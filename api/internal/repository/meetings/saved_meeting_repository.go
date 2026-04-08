// internal/repository/meetings/saved_meeting_repository.go
package meetings

import (
	"context"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/meetings"
	"github.com/regalrecovery/api/internal/repository"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const savedMeetingsCollection = "savedMeetings"

// SavedMeetingDoc is the MongoDB document for a saved meeting template.
type SavedMeetingDoc struct {
	repository.BaseDocument `bson:",inline"`

	UserID                string       `bson:"userId"`
	SavedMeetingID        string       `bson:"savedMeetingId"`
	Name                  string       `bson:"name"`
	MeetingType           string       `bson:"meetingType"`
	CustomTypeLabel       *string      `bson:"customTypeLabel,omitempty"`
	Location              *string      `bson:"location,omitempty"`
	Schedule              *ScheduleDoc `bson:"schedule,omitempty"`
	ReminderMinutesBefore *int         `bson:"reminderMinutesBefore,omitempty"`
	IsActive              bool         `bson:"isActive"`
}

// ScheduleDoc is the MongoDB sub-document for a recurring schedule.
type ScheduleDoc struct {
	DayOfWeek string `bson:"dayOfWeek"`
	Time      string `bson:"time"`
	TimeZone  string `bson:"timeZone"`
}

// MongoSavedMeetingRepository implements meetings.SavedMeetingRepository using MongoDB.
type MongoSavedMeetingRepository struct {
	client *repository.MongoClient
}

// NewMongoSavedMeetingRepository creates a new MongoDB-backed saved meeting repository.
func NewMongoSavedMeetingRepository(client *repository.MongoClient) *MongoSavedMeetingRepository {
	return &MongoSavedMeetingRepository{client: client}
}

// Create creates a new saved meeting template.
func (r *MongoSavedMeetingRepository) Create(ctx context.Context, saved *meetings.SavedMeeting) error {
	doc := toSavedMeetingDoc(saved)
	repository.SetBaseDocumentDefaults(&doc.BaseDocument)

	_, err := r.client.Collection(savedMeetingsCollection).InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting saved meeting: %w", err)
	}

	return nil
}

// GetByID retrieves a saved meeting by its savedMeetingId.
func (r *MongoSavedMeetingRepository) GetByID(ctx context.Context, userID, savedMeetingID string) (*meetings.SavedMeeting, error) {
	filter := bson.M{"userId": userID, "savedMeetingId": savedMeetingID}

	var doc SavedMeetingDoc
	err := r.client.Collection(savedMeetingsCollection).FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding saved meeting: %w", err)
	}

	return fromSavedMeetingDoc(&doc), nil
}

// ListActive retrieves all active saved meetings for a user, sorted by name.
func (r *MongoSavedMeetingRepository) ListActive(ctx context.Context, userID string) ([]*meetings.SavedMeeting, error) {
	filter := bson.M{"userId": userID, "isActive": true}
	opts := options.Find().SetSort(bson.D{{Key: "name", Value: 1}})

	cursor, err := r.client.Collection(savedMeetingsCollection).Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("finding saved meetings: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []SavedMeetingDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding saved meetings: %w", err)
	}

	result := make([]*meetings.SavedMeeting, 0, len(docs))
	for _, doc := range docs {
		result = append(result, fromSavedMeetingDoc(&doc))
	}

	return result, nil
}

// Update updates an existing saved meeting template.
func (r *MongoSavedMeetingRepository) Update(ctx context.Context, saved *meetings.SavedMeeting) error {
	filter := bson.M{"userId": saved.UserID, "savedMeetingId": saved.SavedMeetingID}

	var scheduleDoc interface{}
	if saved.Schedule != nil {
		scheduleDoc = &ScheduleDoc{
			DayOfWeek: string(saved.Schedule.DayOfWeek),
			Time:      saved.Schedule.Time,
			TimeZone:  saved.Schedule.TimeZone,
		}
	}

	update := bson.M{
		"$set": bson.M{
			"name":                  saved.Name,
			"meetingType":           string(saved.MeetingType),
			"customTypeLabel":       saved.CustomTypeLabel,
			"location":              saved.Location,
			"schedule":              scheduleDoc,
			"reminderMinutesBefore": saved.ReminderMinutesBefore,
			"modifiedAt":            time.Now().UTC(),
		},
	}

	result, err := r.client.Collection(savedMeetingsCollection).UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating saved meeting: %w", err)
	}
	if result.MatchedCount == 0 {
		return meetings.ErrSavedMeetingNotFound
	}

	return nil
}

// SoftDelete marks a saved meeting as inactive.
func (r *MongoSavedMeetingRepository) SoftDelete(ctx context.Context, userID, savedMeetingID string) error {
	filter := bson.M{"userId": userID, "savedMeetingId": savedMeetingID}

	update := bson.M{
		"$set": bson.M{
			"isActive":   false,
			"modifiedAt": time.Now().UTC(),
		},
	}

	result, err := r.client.Collection(savedMeetingsCollection).UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("soft-deleting saved meeting: %w", err)
	}
	if result.MatchedCount == 0 {
		return meetings.ErrSavedMeetingNotFound
	}

	return nil
}

// --- Conversion helpers ---

func toSavedMeetingDoc(s *meetings.SavedMeeting) *SavedMeetingDoc {
	doc := &SavedMeetingDoc{
		BaseDocument: repository.BaseDocument{
			CreatedAt:  s.CreatedAt,
			ModifiedAt: s.ModifiedAt,
			TenantID:   s.TenantID,
		},
		UserID:                s.UserID,
		SavedMeetingID:        s.SavedMeetingID,
		Name:                  s.Name,
		MeetingType:           string(s.MeetingType),
		CustomTypeLabel:       s.CustomTypeLabel,
		Location:              s.Location,
		ReminderMinutesBefore: s.ReminderMinutesBefore,
		IsActive:              s.IsActive,
	}

	if s.Schedule != nil {
		doc.Schedule = &ScheduleDoc{
			DayOfWeek: string(s.Schedule.DayOfWeek),
			Time:      s.Schedule.Time,
			TimeZone:  s.Schedule.TimeZone,
		}
	}

	return doc
}

func fromSavedMeetingDoc(doc *SavedMeetingDoc) *meetings.SavedMeeting {
	saved := &meetings.SavedMeeting{
		SavedMeetingID:        doc.SavedMeetingID,
		UserID:                doc.UserID,
		TenantID:              doc.TenantID,
		Name:                  doc.Name,
		MeetingType:           meetings.MeetingType(doc.MeetingType),
		CustomTypeLabel:       doc.CustomTypeLabel,
		Location:              doc.Location,
		ReminderMinutesBefore: doc.ReminderMinutesBefore,
		IsActive:              doc.IsActive,
		CreatedAt:             doc.CreatedAt,
		ModifiedAt:            doc.ModifiedAt,
	}

	if doc.Schedule != nil {
		saved.Schedule = &meetings.MeetingSchedule{
			DayOfWeek: meetings.DayOfWeek(doc.Schedule.DayOfWeek),
			Time:      doc.Schedule.Time,
			TimeZone:  doc.Schedule.TimeZone,
		}
	}

	return saved
}
