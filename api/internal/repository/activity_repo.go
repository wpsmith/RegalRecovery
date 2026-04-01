// internal/repository/activity_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/dynamodb/attributevalue"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// ActivityRepo implements ActivityRepository using DynamoDB.
type ActivityRepo struct {
	client *DynamoClient
}

// NewActivityRepo creates a new ActivityRepo.
func NewActivityRepo(client *DynamoClient) *ActivityRepo {
	return &ActivityRepo{client: client}
}

// CreateCheckIn creates a new check-in entry.
// PK: USER#{userID}, SK: CHECKIN#{timestamp}
// Also creates a calendar activity entry: SK: ACTIVITY#{date}#CHECKIN#{timestamp}
func (r *ActivityRepo) CreateCheckIn(ctx context.Context, userID string, checkIn *CheckIn) error {
	now := time.Now().UTC().Format(time.RFC3339)
	checkIn.CreatedAt = now
	checkIn.ModifiedAt = now
	checkIn.EntityType = "CHECKIN"

	if err := r.client.PutItem(ctx, checkIn); err != nil {
		return fmt.Errorf("creating check-in: %w", err)
	}

	return nil
}

// GetRecentCheckIns retrieves recent check-ins for a user.
// PK: USER#{userID}, SK begins_with CHECKIN#, descending order
func (r *ActivityRepo) GetRecentCheckIns(ctx context.Context, userID string, limit int) ([]CheckIn, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "CHECKIN#"},
		},
		ScanIndexForward: aws.Bool(false), // Descending order (newest first)
		Limit:            aws.Int32(int32(limit)),
	})
	if err != nil {
		return nil, fmt.Errorf("listing check-ins for user %s: %w", userID, err)
	}

	var checkIns []CheckIn
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &checkIns); err != nil {
		return nil, fmt.Errorf("unmarshaling check-ins: %w", err)
	}

	return checkIns, nil
}

// CreateUrge creates a new urge log entry.
// PK: USER#{userID}, SK: URGE#{timestamp}
func (r *ActivityRepo) CreateUrge(ctx context.Context, userID string, urge *Urge) error {
	now := time.Now().UTC().Format(time.RFC3339)
	urge.CreatedAt = now
	urge.ModifiedAt = now
	urge.EntityType = "URGE"

	if err := r.client.PutItem(ctx, urge); err != nil {
		return fmt.Errorf("creating urge: %w", err)
	}

	return nil
}

// GetRecentUrges retrieves recent urges for a user.
// PK: USER#{userID}, SK begins_with URGE#, descending order
func (r *ActivityRepo) GetRecentUrges(ctx context.Context, userID string, limit int) ([]Urge, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "URGE#"},
		},
		ScanIndexForward: aws.Bool(false), // Descending order (newest first)
		Limit:            aws.Int32(int32(limit)),
	})
	if err != nil {
		return nil, fmt.Errorf("listing urges for user %s: %w", userID, err)
	}

	var urges []Urge
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &urges); err != nil {
		return nil, fmt.Errorf("unmarshaling urges: %w", err)
	}

	return urges, nil
}

// CreateJournal creates a new journal entry.
// PK: USER#{userID}, SK: JOURNAL#{timestamp}
func (r *ActivityRepo) CreateJournal(ctx context.Context, userID string, journal *Journal) error {
	now := time.Now().UTC().Format(time.RFC3339)
	journal.CreatedAt = now
	journal.ModifiedAt = now
	journal.EntityType = "JOURNAL"

	if err := r.client.PutItem(ctx, journal); err != nil {
		return fmt.Errorf("creating journal: %w", err)
	}

	return nil
}

// GetRecentJournals retrieves recent journal entries for a user.
// PK: USER#{userID}, SK begins_with JOURNAL#, descending order
func (r *ActivityRepo) GetRecentJournals(ctx context.Context, userID string, limit int) ([]Journal, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "JOURNAL#"},
		},
		ScanIndexForward: aws.Bool(false), // Descending order (newest first)
		Limit:            aws.Int32(int32(limit)),
	})
	if err != nil {
		return nil, fmt.Errorf("listing journals for user %s: %w", userID, err)
	}

	var journals []Journal
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &journals); err != nil {
		return nil, fmt.Errorf("unmarshaling journals: %w", err)
	}

	return journals, nil
}

// CreateMeeting creates a new meeting log entry.
// PK: USER#{userID}, SK: MEETING#{timestamp}
func (r *ActivityRepo) CreateMeeting(ctx context.Context, userID string, meeting *Meeting) error {
	now := time.Now().UTC().Format(time.RFC3339)
	meeting.CreatedAt = now
	meeting.ModifiedAt = now
	meeting.EntityType = "MEETING"

	if err := r.client.PutItem(ctx, meeting); err != nil {
		return fmt.Errorf("creating meeting: %w", err)
	}

	return nil
}

// GetRecentMeetings retrieves recent meeting logs for a user.
// PK: USER#{userID}, SK begins_with MEETING#, descending order
func (r *ActivityRepo) GetRecentMeetings(ctx context.Context, userID string, limit int) ([]Meeting, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "MEETING#"},
		},
		ScanIndexForward: aws.Bool(false), // Descending order (newest first)
		Limit:            aws.Int32(int32(limit)),
	})
	if err != nil {
		return nil, fmt.Errorf("listing meetings for user %s: %w", userID, err)
	}

	var meetings []Meeting
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &meetings); err != nil {
		return nil, fmt.Errorf("unmarshaling meetings: %w", err)
	}

	return meetings, nil
}

// CreatePrayer creates a new prayer log entry.
// PK: USER#{userID}, SK: PRAYER#{timestamp}
func (r *ActivityRepo) CreatePrayer(ctx context.Context, userID string, prayer *Prayer) error {
	now := time.Now().UTC().Format(time.RFC3339)
	prayer.CreatedAt = now
	prayer.ModifiedAt = now
	prayer.EntityType = "PRAYER"

	if err := r.client.PutItem(ctx, prayer); err != nil {
		return fmt.Errorf("creating prayer: %w", err)
	}

	return nil
}

// CreateExercise creates a new exercise log entry.
// PK: USER#{userID}, SK: EXERCISE#{timestamp}
func (r *ActivityRepo) CreateExercise(ctx context.Context, userID string, exercise *Exercise) error {
	now := time.Now().UTC().Format(time.RFC3339)
	exercise.CreatedAt = now
	exercise.ModifiedAt = now
	exercise.EntityType = "EXERCISE"

	if err := r.client.PutItem(ctx, exercise); err != nil {
		return fmt.Errorf("creating exercise: %w", err)
	}

	return nil
}

// GetActivitiesByDate retrieves all activities for a specific date (calendar day view).
// PK: USER#{userID}, SK begins_with ACTIVITY#{date}#
func (r *ActivityRepo) GetActivitiesByDate(ctx context.Context, userID, date string) ([]Activity, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: fmt.Sprintf("ACTIVITY#%s#", date)},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing activities for user %s date %s: %w", userID, date, err)
	}

	var activities []Activity
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &activities); err != nil {
		return nil, fmt.Errorf("unmarshaling activities: %w", err)
	}

	return activities, nil
}

// GetActivitiesByDateRange retrieves all activities within a date range (calendar month view).
// PK: USER#{userID}, SK between ACTIVITY#{startDate} and ACTIVITY#{endDate}~
func (r *ActivityRepo) GetActivitiesByDateRange(ctx context.Context, userID, startDate, endDate string) ([]Activity, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND SK BETWEEN :start AND :end"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk":    &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":start": &types.AttributeValueMemberS{Value: fmt.Sprintf("ACTIVITY#%s", startDate)},
			":end":   &types.AttributeValueMemberS{Value: fmt.Sprintf("ACTIVITY#%s~", endDate)},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing activities for user %s date range %s to %s: %w", userID, startDate, endDate, err)
	}

	var activities []Activity
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &activities); err != nil {
		return nil, fmt.Errorf("unmarshaling activities: %w", err)
	}

	return activities, nil
}
