// internal/repository/support_repo.go
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

// SupportRepo implements SupportRepository using DynamoDB.
type SupportRepo struct {
	client *DynamoClient
}

// NewSupportRepo creates a new SupportRepo.
func NewSupportRepo(client *DynamoClient) *SupportRepo {
	return &SupportRepo{client: client}
}

// ListContacts lists all support contacts for a user.
// PK: USER#{userID}, SK begins_with CONTACT#
func (r *SupportRepo) ListContacts(ctx context.Context, userID string) ([]SupportContact, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "CONTACT#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing contacts for user %s: %w", userID, err)
	}

	var contacts []SupportContact
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &contacts); err != nil {
		return nil, fmt.Errorf("unmarshaling contacts: %w", err)
	}

	return contacts, nil
}

// GetContact retrieves a specific contact by ID.
// PK: USER#{userID}, SK: CONTACT#{contactID}
func (r *SupportRepo) GetContact(ctx context.Context, userID, contactID string) (*SupportContact, error) {
	var contact SupportContact
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("CONTACT#%s", contactID), &contact)
	if err != nil {
		return nil, fmt.Errorf("getting contact %s for user %s: %w", contactID, userID, err)
	}
	return &contact, nil
}

// CreateContact creates a new support contact.
func (r *SupportRepo) CreateContact(ctx context.Context, contact *SupportContact) error {
	now := time.Now().UTC().Format(time.RFC3339)
	contact.CreatedAt = now
	contact.ModifiedAt = now
	contact.EntityType = "CONTACT"

	if err := r.client.PutItem(ctx, contact); err != nil {
		return fmt.Errorf("creating contact: %w", err)
	}

	return nil
}

// UpdateContact updates an existing support contact.
func (r *SupportRepo) UpdateContact(ctx context.Context, contact *SupportContact) error {
	contact.ModifiedAt = time.Now().UTC().Format(time.RFC3339)

	if err := r.client.PutItem(ctx, contact); err != nil {
		return fmt.Errorf("updating contact: %w", err)
	}

	return nil
}

// ListPermissions lists all permissions for a user.
// PK: USER#{userID}, SK begins_with PERMISSION#
func (r *SupportRepo) ListPermissions(ctx context.Context, userID string) ([]Permission, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: "PERMISSION#"},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing permissions for user %s: %w", userID, err)
	}

	var permissions []Permission
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &permissions); err != nil {
		return nil, fmt.Errorf("unmarshaling permissions: %w", err)
	}

	return permissions, nil
}

// GetPermissionsForContact lists permissions for a specific contact.
// PK: USER#{userID}, SK begins_with PERMISSION#{contactID}#
func (r *SupportRepo) GetPermissionsForContact(ctx context.Context, userID, contactID string) ([]Permission, error) {
	result, err := r.client.Query(ctx, &dynamodb.QueryInput{
		KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
		ExpressionAttributeValues: map[string]types.AttributeValue{
			":pk": &types.AttributeValueMemberS{Value: fmt.Sprintf("USER#%s", userID)},
			":sk": &types.AttributeValueMemberS{Value: fmt.Sprintf("PERMISSION#%s#", contactID)},
		},
	})
	if err != nil {
		return nil, fmt.Errorf("listing permissions for user %s contact %s: %w", userID, contactID, err)
	}

	var permissions []Permission
	if err := attributevalue.UnmarshalListOfMaps(result.Items, &permissions); err != nil {
		return nil, fmt.Errorf("unmarshaling permissions: %w", err)
	}

	return permissions, nil
}

// CheckPermission checks if a specific permission exists.
// PK: USER#{userID}, SK: PERMISSION#{contactID}#{dataCategory}
func (r *SupportRepo) CheckPermission(ctx context.Context, userID, contactID, dataCategory string) (*Permission, error) {
	var permission Permission
	err := r.client.GetItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("PERMISSION#%s#%s", contactID, dataCategory), &permission)
	if err != nil {
		return nil, fmt.Errorf("checking permission for user %s contact %s category %s: %w", userID, contactID, dataCategory, err)
	}
	return &permission, nil
}

// GrantPermission grants a permission to a contact.
func (r *SupportRepo) GrantPermission(ctx context.Context, permission *Permission) error {
	now := time.Now().UTC().Format(time.RFC3339)
	permission.CreatedAt = now
	permission.ModifiedAt = now
	permission.EntityType = "PERMISSION"

	if err := r.client.PutItem(ctx, permission); err != nil {
		return fmt.Errorf("granting permission: %w", err)
	}

	return nil
}

// RevokePermission revokes a permission.
func (r *SupportRepo) RevokePermission(ctx context.Context, userID, contactID, dataCategory string) error {
	if err := r.client.DeleteItem(ctx, fmt.Sprintf("USER#%s", userID), fmt.Sprintf("PERMISSION#%s#%s", contactID, dataCategory)); err != nil {
		return fmt.Errorf("revoking permission for user %s contact %s category %s: %w", userID, contactID, dataCategory, err)
	}

	return nil
}
