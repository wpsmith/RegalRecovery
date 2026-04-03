// internal/repository/activity_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// ActivityRepo implements ActivityRepository using MongoDB.
type ActivityRepo struct {
	client *MongoClient
}

// NewActivityRepo creates a new ActivityRepo.
func NewActivityRepo(client *MongoClient) *ActivityRepo {
	return &ActivityRepo{client: client}
}

// CreateCheckIn creates a new check-in entry.
func (r *ActivityRepo) CreateCheckIn(ctx context.Context, userID string, checkIn *CheckIn) error {
	checkIn.UserID = userID
	SetBaseDocumentDefaults(&checkIn.BaseDocument)

	_, err := r.client.Collection("check_ins").InsertOne(ctx, checkIn)
	if err != nil {
		return fmt.Errorf("creating check-in: %w", err)
	}
	return nil
}

// GetRecentCheckIns retrieves recent check-ins for a user, sorted newest first.
func (r *ActivityRepo) GetRecentCheckIns(ctx context.Context, userID string, limit int) ([]CheckIn, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := r.client.Collection("check_ins").Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing check-ins for user %s: %w", userID, err)
	}

	var checkIns []CheckIn
	if err := cursor.All(ctx, &checkIns); err != nil {
		return nil, fmt.Errorf("decoding check-ins: %w", err)
	}
	return checkIns, nil
}

// CreateUrge creates a new urge log entry.
func (r *ActivityRepo) CreateUrge(ctx context.Context, userID string, urge *Urge) error {
	urge.UserID = userID
	SetBaseDocumentDefaults(&urge.BaseDocument)

	_, err := r.client.Collection("urges").InsertOne(ctx, urge)
	if err != nil {
		return fmt.Errorf("creating urge: %w", err)
	}
	return nil
}

// GetRecentUrges retrieves recent urges for a user, sorted newest first.
func (r *ActivityRepo) GetRecentUrges(ctx context.Context, userID string, limit int) ([]Urge, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := r.client.Collection("urges").Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing urges for user %s: %w", userID, err)
	}

	var urges []Urge
	if err := cursor.All(ctx, &urges); err != nil {
		return nil, fmt.Errorf("decoding urges: %w", err)
	}
	return urges, nil
}

// CreateJournal creates a new journal entry.
func (r *ActivityRepo) CreateJournal(ctx context.Context, userID string, journal *Journal) error {
	journal.UserID = userID
	SetBaseDocumentDefaults(&journal.BaseDocument)

	_, err := r.client.Collection("journals").InsertOne(ctx, journal)
	if err != nil {
		return fmt.Errorf("creating journal: %w", err)
	}
	return nil
}

// GetRecentJournals retrieves recent journal entries for a user, sorted newest first.
func (r *ActivityRepo) GetRecentJournals(ctx context.Context, userID string, limit int) ([]Journal, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := r.client.Collection("journals").Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing journals for user %s: %w", userID, err)
	}

	var journals []Journal
	if err := cursor.All(ctx, &journals); err != nil {
		return nil, fmt.Errorf("decoding journals: %w", err)
	}
	return journals, nil
}

// CreateMeeting creates a new meeting log entry.
func (r *ActivityRepo) CreateMeeting(ctx context.Context, userID string, meeting *Meeting) error {
	meeting.UserID = userID
	SetBaseDocumentDefaults(&meeting.BaseDocument)

	_, err := r.client.Collection("meetings").InsertOne(ctx, meeting)
	if err != nil {
		return fmt.Errorf("creating meeting: %w", err)
	}
	return nil
}

// GetRecentMeetings retrieves recent meeting logs for a user, sorted newest first.
func (r *ActivityRepo) GetRecentMeetings(ctx context.Context, userID string, limit int) ([]Meeting, error) {
	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(limit))

	cursor, err := r.client.Collection("meetings").Find(ctx, bson.M{"userId": userID}, opts)
	if err != nil {
		return nil, fmt.Errorf("listing meetings for user %s: %w", userID, err)
	}

	var meetings []Meeting
	if err := cursor.All(ctx, &meetings); err != nil {
		return nil, fmt.Errorf("decoding meetings: %w", err)
	}
	return meetings, nil
}

// CreatePrayer creates a new prayer log entry.
func (r *ActivityRepo) CreatePrayer(ctx context.Context, userID string, prayer *Prayer) error {
	prayer.UserID = userID
	SetBaseDocumentDefaults(&prayer.BaseDocument)

	_, err := r.client.Collection("prayers").InsertOne(ctx, prayer)
	if err != nil {
		return fmt.Errorf("creating prayer: %w", err)
	}
	return nil
}

// CreateExercise creates a new exercise log entry.
func (r *ActivityRepo) CreateExercise(ctx context.Context, userID string, exercise *Exercise) error {
	exercise.UserID = userID
	SetBaseDocumentDefaults(&exercise.BaseDocument)

	_, err := r.client.Collection("exercises").InsertOne(ctx, exercise)
	if err != nil {
		return fmt.Errorf("creating exercise: %w", err)
	}
	return nil
}

// GetActivitiesByDate retrieves all activities for a specific date.
func (r *ActivityRepo) GetActivitiesByDate(ctx context.Context, userID, date string) ([]Activity, error) {
	cursor, err := r.client.Collection("activities").Find(ctx, bson.M{
		"userId": userID,
		"date":   date,
	})
	if err != nil {
		return nil, fmt.Errorf("listing activities for user %s date %s: %w", userID, date, err)
	}

	var activities []Activity
	if err := cursor.All(ctx, &activities); err != nil {
		return nil, fmt.Errorf("decoding activities: %w", err)
	}
	return activities, nil
}

// GetActivitiesByDateRange retrieves all activities within a date range.
func (r *ActivityRepo) GetActivitiesByDateRange(ctx context.Context, userID, startDate, endDate string) ([]Activity, error) {
	cursor, err := r.client.Collection("activities").Find(ctx, bson.M{
		"userId": userID,
		"date": bson.M{
			"$gte": startDate,
			"$lte": endDate,
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing activities for user %s date range %s to %s: %w", userID, startDate, endDate, err)
	}

	var activities []Activity
	if err := cursor.All(ctx, &activities); err != nil {
		return nil, fmt.Errorf("decoding activities: %w", err)
	}
	return activities, nil
}
