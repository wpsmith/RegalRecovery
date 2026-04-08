// internal/repository/saved_contact_repo.go
package repository

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/regalrecovery/api/internal/domain/phonecalls"
)

// SavedContactDoc is the MongoDB document for a saved contact.
type SavedContactDoc struct {
	BaseDocument `bson:",inline"`

	SavedContactID string  `bson:"savedContactId"`
	UserID         string  `bson:"userId"`
	EntityType     string  `bson:"entityType"`
	ContactName    string  `bson:"contactName"`
	ContactType    string  `bson:"contactType"`
	PhoneNumber    *string `bson:"phoneNumber,omitempty"`
}

// MongoSavedContactRepo implements SavedContactRepository using MongoDB.
type MongoSavedContactRepo struct {
	client     *MongoClient
	collection string
}

// NewSavedContactRepo creates a new MongoSavedContactRepo.
func NewSavedContactRepo(client *MongoClient) *MongoSavedContactRepo {
	return &MongoSavedContactRepo{
		client:     client,
		collection: "savedContacts",
	}
}

// Create persists a new saved contact.
func (r *MongoSavedContactRepo) Create(ctx context.Context, contact *phonecalls.SavedContact) error {
	doc := savedContactToDoc(contact)
	coll := r.client.Collection(r.collection)
	if _, err := coll.InsertOne(ctx, doc); err != nil {
		return fmt.Errorf("inserting saved contact: %w", err)
	}
	return nil
}

// List retrieves all saved contacts for a user.
func (r *MongoSavedContactRepo) List(ctx context.Context, userID string) ([]phonecalls.SavedContact, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"entityType": "SAVED_CONTACT",
	}

	cur, err := coll.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("listing saved contacts: %w", err)
	}
	defer cur.Close(ctx)

	var docs []SavedContactDoc
	if err := cur.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding saved contacts: %w", err)
	}

	contacts := make([]phonecalls.SavedContact, 0, len(docs))
	for _, doc := range docs {
		contacts = append(contacts, *docToSavedContact(&doc))
	}

	return contacts, nil
}

// GetByID retrieves a saved contact by ID.
func (r *MongoSavedContactRepo) GetByID(ctx context.Context, userID, savedContactID string) (*phonecalls.SavedContact, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":         userID,
		"savedContactId": savedContactID,
		"entityType":     "SAVED_CONTACT",
	}

	var doc SavedContactDoc
	err := coll.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err.Error() == "mongo: no documents in result" {
			return nil, nil
		}
		return nil, fmt.Errorf("finding saved contact: %w", err)
	}

	return docToSavedContact(&doc), nil
}

// Update applies a partial update to a saved contact.
func (r *MongoSavedContactRepo) Update(ctx context.Context, userID, savedContactID string, req *phonecalls.UpdateSavedContactRequest) (*phonecalls.SavedContact, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":         userID,
		"savedContactId": savedContactID,
		"entityType":     "SAVED_CONTACT",
	}

	update := bson.M{"$set": bson.M{"modifiedAt": time.Now().UTC()}}
	setFields := update["$set"].(bson.M)

	if req.ContactName != nil {
		setFields["contactName"] = *req.ContactName
	}
	if req.ContactType != nil {
		setFields["contactType"] = string(*req.ContactType)
	}
	if req.PhoneNumber != nil {
		setFields["phoneNumber"] = *req.PhoneNumber
	}

	result, err := coll.UpdateOne(ctx, filter, update)
	if err != nil {
		return nil, fmt.Errorf("updating saved contact: %w", err)
	}
	if result.MatchedCount == 0 {
		return nil, nil
	}

	return r.GetByID(ctx, userID, savedContactID)
}

// Delete removes a saved contact.
func (r *MongoSavedContactRepo) Delete(ctx context.Context, userID, savedContactID string) error {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":         userID,
		"savedContactId": savedContactID,
		"entityType":     "SAVED_CONTACT",
	}

	result, err := coll.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting saved contact: %w", err)
	}
	if result.DeletedCount == 0 {
		return fmt.Errorf("saved contact not found")
	}

	return nil
}

// Count returns the number of saved contacts for a user.
func (r *MongoSavedContactRepo) Count(ctx context.Context, userID string) (int, error) {
	coll := r.client.Collection(r.collection)
	filter := bson.M{
		"userId":     userID,
		"entityType": "SAVED_CONTACT",
	}

	count, err := coll.CountDocuments(ctx, filter)
	if err != nil {
		return 0, fmt.Errorf("counting saved contacts: %w", err)
	}

	return int(count), nil
}

// --- Conversion helpers ---

func savedContactToDoc(contact *phonecalls.SavedContact) *SavedContactDoc {
	return &SavedContactDoc{
		BaseDocument: BaseDocument{
			CreatedAt:  contact.CreatedAt,
			ModifiedAt: contact.ModifiedAt,
			TenantID:   contact.TenantID,
		},
		SavedContactID: contact.SavedContactID,
		UserID:         contact.UserID,
		EntityType:     "SAVED_CONTACT",
		ContactName:    contact.ContactName,
		ContactType:    string(contact.ContactType),
		PhoneNumber:    contact.PhoneNumber,
	}
}

func docToSavedContact(doc *SavedContactDoc) *phonecalls.SavedContact {
	return &phonecalls.SavedContact{
		SavedContactID: doc.SavedContactID,
		UserID:         doc.UserID,
		TenantID:       doc.TenantID,
		ContactName:    doc.ContactName,
		ContactType:    phonecalls.ContactType(doc.ContactType),
		PhoneNumber:    doc.PhoneNumber,
		HasPhoneNumber: doc.PhoneNumber != nil,
		CreatedAt:      doc.CreatedAt,
		ModifiedAt:     doc.ModifiedAt,
	}
}
