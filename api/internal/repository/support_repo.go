// internal/repository/support_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
)

// SupportRepo implements SupportRepository using MongoDB.
type SupportRepo struct {
	client *MongoClient
}

// NewSupportRepo creates a new SupportRepo.
func NewSupportRepo(client *MongoClient) *SupportRepo {
	return &SupportRepo{client: client}
}

// ListContacts lists all support contacts for a user.
func (r *SupportRepo) ListContacts(ctx context.Context, userID string) ([]SupportContact, error) {
	cursor, err := r.client.Collection("support_contacts").Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing contacts for user %s: %w", userID, err)
	}

	var contacts []SupportContact
	if err := cursor.All(ctx, &contacts); err != nil {
		return nil, fmt.Errorf("decoding contacts for user %s: %w", userID, err)
	}

	return contacts, nil
}

// GetContact retrieves a specific contact by ID.
func (r *SupportRepo) GetContact(ctx context.Context, userID, contactID string) (*SupportContact, error) {
	var contact SupportContact
	err := r.client.Collection("support_contacts").FindOne(ctx, bson.M{
		"userId":    userID,
		"contactId": contactID,
	}).Decode(&contact)
	if err != nil {
		return nil, fmt.Errorf("getting contact %s for user %s: %w", contactID, userID, err)
	}
	return &contact, nil
}

// CreateContact creates a new support contact.
func (r *SupportRepo) CreateContact(ctx context.Context, contact *SupportContact) error {
	SetBaseDocumentDefaults(&contact.BaseDocument)

	if _, err := r.client.Collection("support_contacts").InsertOne(ctx, contact); err != nil {
		return fmt.Errorf("creating contact: %w", err)
	}

	return nil
}

// UpdateContact updates an existing support contact.
func (r *SupportRepo) UpdateContact(ctx context.Context, contact *SupportContact) error {
	UpdateModified(&contact.BaseDocument)

	if _, err := r.client.Collection("support_contacts").ReplaceOne(ctx, bson.M{
		"userId":    contact.UserID,
		"contactId": contact.ContactID,
	}, contact); err != nil {
		return fmt.Errorf("updating contact: %w", err)
	}

	return nil
}

// ListPermissions lists all permissions for a user.
func (r *SupportRepo) ListPermissions(ctx context.Context, userID string) ([]Permission, error) {
	cursor, err := r.client.Collection("permissions").Find(ctx, bson.M{"userId": userID})
	if err != nil {
		return nil, fmt.Errorf("listing permissions for user %s: %w", userID, err)
	}

	var permissions []Permission
	if err := cursor.All(ctx, &permissions); err != nil {
		return nil, fmt.Errorf("decoding permissions for user %s: %w", userID, err)
	}

	return permissions, nil
}

// GetPermissionsForContact lists permissions for a specific contact.
func (r *SupportRepo) GetPermissionsForContact(ctx context.Context, userID, contactID string) ([]Permission, error) {
	cursor, err := r.client.Collection("permissions").Find(ctx, bson.M{
		"userId":    userID,
		"contactId": contactID,
	})
	if err != nil {
		return nil, fmt.Errorf("listing permissions for user %s contact %s: %w", userID, contactID, err)
	}

	var permissions []Permission
	if err := cursor.All(ctx, &permissions); err != nil {
		return nil, fmt.Errorf("decoding permissions for user %s contact %s: %w", userID, contactID, err)
	}

	return permissions, nil
}

// CheckPermission checks if a specific permission exists.
func (r *SupportRepo) CheckPermission(ctx context.Context, userID, contactID, dataCategory string) (*Permission, error) {
	var permission Permission
	err := r.client.Collection("permissions").FindOne(ctx, bson.M{
		"userId":       userID,
		"contactId":    contactID,
		"dataCategory": dataCategory,
	}).Decode(&permission)
	if err != nil {
		return nil, fmt.Errorf("checking permission for user %s contact %s category %s: %w", userID, contactID, dataCategory, err)
	}
	return &permission, nil
}

// GrantPermission grants a permission to a contact.
func (r *SupportRepo) GrantPermission(ctx context.Context, permission *Permission) error {
	SetBaseDocumentDefaults(&permission.BaseDocument)

	if _, err := r.client.Collection("permissions").InsertOne(ctx, permission); err != nil {
		return fmt.Errorf("granting permission: %w", err)
	}

	return nil
}

// RevokePermission revokes a permission.
func (r *SupportRepo) RevokePermission(ctx context.Context, userID, contactID, dataCategory string) error {
	if _, err := r.client.Collection("permissions").DeleteOne(ctx, bson.M{
		"userId":       userID,
		"contactId":    contactID,
		"dataCategory": dataCategory,
	}); err != nil {
		return fmt.Errorf("revoking permission for user %s contact %s category %s: %w", userID, contactID, dataCategory, err)
	}

	return nil
}
