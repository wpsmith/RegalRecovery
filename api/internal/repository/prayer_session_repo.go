// internal/repository/prayer_session_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/regalrecovery/api/internal/domain/prayer"
)

// PrayerSessionDoc is the MongoDB document for a prayer session.
type PrayerSessionDoc struct {
	BaseDocument `bson:",inline"`

	PK                 string     `bson:"PK"`
	SK                 string     `bson:"SK"`
	EntityType         string     `bson:"entityType"`
	PrayerID           string     `bson:"prayerId"`
	UserID             string     `bson:"userId"`
	PrayerType         string     `bson:"prayerType"`
	DurationMinutes    *int       `bson:"durationMinutes,omitempty"`
	Notes              *string    `bson:"notes,omitempty"`
	LinkedPrayerID     *string    `bson:"linkedPrayerId,omitempty"`
	LinkedPrayerTitle  *string    `bson:"linkedPrayerTitle,omitempty"`
	MoodBefore         *int       `bson:"moodBefore,omitempty"`
	MoodAfter          *int       `bson:"moodAfter,omitempty"`
	IsEphemeral        bool       `bson:"isEphemeral"`
	NotesEditableUntil time.Time  `bson:"notesEditableUntil"`
	Timestamp          time.Time  `bson:"timestamp"`
	EphemeralDeleteAt  *time.Time `bson:"ephemeralDeleteAt,omitempty"`
	ExpiresAt          *int64     `bson:"expiresAt,omitempty"`
}

// CalendarActivityDoc is the MongoDB document for a calendar activity entry.
type CalendarActivityDoc struct {
	BaseDocument `bson:",inline"`

	PK           string                 `bson:"PK"`
	SK           string                 `bson:"SK"`
	EntityType   string                 `bson:"entityType"`
	ActivityType string                 `bson:"activityType"`
	Summary      map[string]interface{} `bson:"summary"`
	SourceKey    string                 `bson:"sourceKey"`
}

// MongoPrayerSessionRepo implements PrayerSessionRepository using MongoDB.
type MongoPrayerSessionRepo struct {
	collection *mongo.Collection
}

// NewMongoPrayerSessionRepo creates a new MongoPrayerSessionRepo.
func NewMongoPrayerSessionRepo(db *mongo.Database) *MongoPrayerSessionRepo {
	return &MongoPrayerSessionRepo{
		collection: db.Collection("main"),
	}
}

// CreateSession creates a prayer session with calendar dual-write (PR-AC10.1).
func (r *MongoPrayerSessionRepo) CreateSession(ctx context.Context, session *prayer.PrayerSession) error {
	pk := "USER#" + session.UserID
	sk := "PRAYER#" + session.Timestamp.UTC().Format(time.RFC3339)

	doc := PrayerSessionDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  session.CreatedAt,
			ModifiedAt: session.ModifiedAt,
			TenantID:   "DEFAULT",
		},
		PK:                 pk,
		SK:                 sk,
		EntityType:         "PRAYER_SESSION",
		PrayerID:           session.PrayerID,
		UserID:             session.UserID,
		PrayerType:         session.PrayerType,
		DurationMinutes:    session.DurationMinutes,
		Notes:              session.Notes,
		LinkedPrayerID:     session.LinkedPrayerID,
		LinkedPrayerTitle:  session.LinkedPrayerTitle,
		MoodBefore:         session.MoodBefore,
		MoodAfter:          session.MoodAfter,
		IsEphemeral:        session.IsEphemeral,
		NotesEditableUntil: session.NotesEditableUntil,
		Timestamp:          session.Timestamp,
	}

	// Set ephemeral TTL fields.
	if session.IsEphemeral {
		deleteAt := prayer.EphemeralDeleteAt(session.CreatedAt)
		doc.EphemeralDeleteAt = &deleteAt
		expiresAt := deleteAt.Unix()
		doc.ExpiresAt = &expiresAt
	}

	// Calendar dual-write document (PR-AC10.1).
	dateStr := session.Timestamp.UTC().Format("2006-01-02")
	calendarSK := fmt.Sprintf("ACTIVITY#%s#PRAYER#%s", dateStr, session.Timestamp.UTC().Format(time.RFC3339))
	summary := map[string]interface{}{
		"prayerType":      session.PrayerType,
		"durationMinutes": session.DurationMinutes,
	}
	if session.LinkedPrayerTitle != nil {
		summary["linkedPrayerTitle"] = *session.LinkedPrayerTitle
	}

	calendarDoc := CalendarActivityDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  session.CreatedAt,
			ModifiedAt: session.ModifiedAt,
			TenantID:   "DEFAULT",
		},
		PK:           pk,
		SK:           calendarSK,
		EntityType:   "CALENDAR_ACTIVITY",
		ActivityType: "PRAYER",
		Summary:      summary,
		SourceKey:    sk,
	}

	// Use ordered insert for both documents.
	docs := []interface{}{doc, calendarDoc}
	_, err := r.collection.InsertMany(ctx, docs)
	if err != nil {
		return fmt.Errorf("inserting prayer session and calendar activity: %w", err)
	}

	return nil
}

// GetSession retrieves a prayer session by user ID and prayer ID.
func (r *MongoPrayerSessionRepo) GetSession(ctx context.Context, userID, prayerID string) (*prayer.PrayerSession, error) {
	filter := bson.M{
		"PK":         "USER#" + userID,
		"entityType": "PRAYER_SESSION",
		"prayerId":   prayerID,
	}

	var doc PrayerSessionDoc
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding prayer session: %w", err)
	}

	return docToSession(&doc), nil
}

// ListSessions lists prayer sessions with filtering and cursor-based pagination.
func (r *MongoPrayerSessionRepo) ListSessions(ctx context.Context, userID string, prayerType *string, startDate, endDate *time.Time, linkedPrayerID *string, cursor string, limit int) ([]prayer.PrayerSession, string, error) {
	filter := bson.M{
		"PK":         "USER#" + userID,
		"entityType": "PRAYER_SESSION",
	}

	// Filter by prayer type (PR-AC6.2).
	if prayerType != nil {
		filter["prayerType"] = *prayerType
	}

	// Filter by date range (PR-AC6.3).
	if startDate != nil || endDate != nil {
		skFilter := bson.M{}
		if startDate != nil {
			skFilter["$gte"] = "PRAYER#" + startDate.UTC().Format(time.RFC3339)
		}
		if endDate != nil {
			// End of day.
			end := endDate.AddDate(0, 0, 1)
			skFilter["$lt"] = "PRAYER#" + end.UTC().Format(time.RFC3339)
		}
		filter["SK"] = skFilter
	}

	// Filter by linked prayer.
	if linkedPrayerID != nil {
		filter["linkedPrayerId"] = *linkedPrayerID
	}

	// Cursor-based pagination.
	if cursor != "" {
		if _, ok := filter["SK"]; ok {
			skFilter := filter["SK"].(bson.M)
			skFilter["$lt"] = cursor
		} else {
			filter["SK"] = bson.M{"$lt": cursor}
		}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "SK", Value: -1}}).
		SetLimit(int64(limit + 1))

	cur, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, "", fmt.Errorf("listing prayer sessions: %w", err)
	}
	defer cur.Close(ctx)

	var docs []PrayerSessionDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, "", fmt.Errorf("decoding prayer sessions: %w", err)
	}

	var sessions []prayer.PrayerSession
	var nextCursor string
	for i, doc := range docs {
		if i >= limit {
			nextCursor = doc.SK
			break
		}
		sessions = append(sessions, *docToSession(&doc))
	}

	return sessions, nextCursor, nil
}

// UpdateSession updates a prayer session.
func (r *MongoPrayerSessionRepo) UpdateSession(ctx context.Context, session *prayer.PrayerSession) error {
	filter := bson.M{
		"PK":         "USER#" + session.UserID,
		"entityType": "PRAYER_SESSION",
		"prayerId":   session.PrayerID,
	}

	update := bson.M{
		"$set": bson.M{
			"prayerType":      session.PrayerType,
			"durationMinutes": session.DurationMinutes,
			"notes":           session.Notes,
			"linkedPrayerId":  session.LinkedPrayerID,
			"linkedPrayerTitle": session.LinkedPrayerTitle,
			"moodBefore":      session.MoodBefore,
			"moodAfter":       session.MoodAfter,
			"modifiedAt":      session.ModifiedAt,
		},
	}

	_, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating prayer session: %w", err)
	}
	return nil
}

// DeleteSession deletes a prayer session and its calendar entry.
func (r *MongoPrayerSessionRepo) DeleteSession(ctx context.Context, userID, prayerID string) error {
	// First find the session to get the SK for calendar cleanup.
	session, err := r.GetSession(ctx, userID, prayerID)
	if err != nil {
		return err
	}
	if session == nil {
		return nil
	}

	pk := "USER#" + userID

	// Delete prayer session.
	_, err = r.collection.DeleteOne(ctx, bson.M{
		"PK":         pk,
		"entityType": "PRAYER_SESSION",
		"prayerId":   prayerID,
	})
	if err != nil {
		return fmt.Errorf("deleting prayer session: %w", err)
	}

	// Delete associated calendar entry.
	dateStr := session.Timestamp.UTC().Format("2006-01-02")
	calendarSK := fmt.Sprintf("ACTIVITY#%s#PRAYER#%s", dateStr, session.Timestamp.UTC().Format(time.RFC3339))
	_, _ = r.collection.DeleteOne(ctx, bson.M{
		"PK": pk,
		"SK": calendarSK,
	})

	return nil
}

// GetAllSessions retrieves all prayer sessions for a user (for stats calculation).
func (r *MongoPrayerSessionRepo) GetAllSessions(ctx context.Context, userID string) ([]prayer.PrayerSession, error) {
	filter := bson.M{
		"PK":         "USER#" + userID,
		"entityType": "PRAYER_SESSION",
	}

	opts := options.Find().SetSort(bson.D{{Key: "SK", Value: -1}})

	cur, err := r.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("getting all prayer sessions: %w", err)
	}
	defer cur.Close(ctx)

	var docs []PrayerSessionDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding all prayer sessions: %w", err)
	}

	sessions := make([]prayer.PrayerSession, len(docs))
	for i, doc := range docs {
		sessions[i] = *docToSession(&doc)
	}
	return sessions, nil
}

func docToSession(doc *PrayerSessionDoc) *prayer.PrayerSession {
	return &prayer.PrayerSession{
		PrayerID:           doc.PrayerID,
		UserID:             doc.UserID,
		Timestamp:          doc.Timestamp,
		PrayerType:         doc.PrayerType,
		DurationMinutes:    doc.DurationMinutes,
		Notes:              doc.Notes,
		LinkedPrayerID:     doc.LinkedPrayerID,
		LinkedPrayerTitle:  doc.LinkedPrayerTitle,
		MoodBefore:         doc.MoodBefore,
		MoodAfter:          doc.MoodAfter,
		IsEphemeral:        doc.IsEphemeral,
		NotesEditableUntil: doc.NotesEditableUntil,
		CreatedAt:          doc.CreatedAt,
		ModifiedAt:         doc.ModifiedAt,
	}
}
