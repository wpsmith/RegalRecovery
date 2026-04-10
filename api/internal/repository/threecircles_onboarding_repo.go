// internal/repository/threecircles_onboarding_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// --- Onboarding flow operations ---
// AP-TC-14: Find active onboarding flow
// AP-TC-15: Get onboarding by flowId
// AP-TC-16: Check existing flow for recovery area

// CreateOnboardingFlow creates a new onboarding flow document.
func (r *ThreeCirclesRepo) CreateOnboardingFlow(ctx context.Context, flow *CircleOnboardingDoc) error {
	SetBaseDocumentDefaults(&flow.BaseDocument)

	if _, err := r.onboarding.InsertOne(ctx, flow); err != nil {
		return fmt.Errorf("creating onboarding flow: %w", err)
	}
	return nil
}

// GetOnboardingFlowByID retrieves an onboarding flow by flowId.
// AP-TC-15: Get onboarding by flowId
func (r *ThreeCirclesRepo) GetOnboardingFlowByID(ctx context.Context, flowID string) (*CircleOnboardingDoc, error) {
	var doc CircleOnboardingDoc
	err := r.onboarding.FindOne(ctx, bson.M{"flowId": flowID}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("onboarding flow %s: not found", flowID)
		}
		return nil, fmt.Errorf("getting onboarding flow %s: %w", flowID, err)
	}
	return &doc, nil
}

// GetActiveOnboardingFlow retrieves the active (incomplete) onboarding flow for a user.
// AP-TC-14: Find active onboarding flow
func (r *ThreeCirclesRepo) GetActiveOnboardingFlow(ctx context.Context, userID string) (*CircleOnboardingDoc, error) {
	var doc CircleOnboardingDoc
	filter := bson.M{
		"userId":    userID,
		"completed": false,
	}

	err := r.onboarding.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // No active flow is a valid state
		}
		return nil, fmt.Errorf("getting active onboarding flow: %w", err)
	}
	return &doc, nil
}

// GetActiveOnboardingFlowForRecoveryArea checks if an active flow exists for a specific recovery area.
// AP-TC-16: Check existing flow for recovery area
func (r *ThreeCirclesRepo) GetActiveOnboardingFlowForRecoveryArea(ctx context.Context, userID string, recoveryArea string) (*CircleOnboardingDoc, error) {
	var doc CircleOnboardingDoc
	filter := bson.M{
		"userId":       userID,
		"recoveryArea": recoveryArea,
		"completed":    false,
	}

	err := r.onboarding.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil // No flow for this area
		}
		return nil, fmt.Errorf("getting active onboarding flow for recovery area: %w", err)
	}
	return &doc, nil
}

// UpdateOnboardingFlow updates an existing onboarding flow (save progress).
func (r *ThreeCirclesRepo) UpdateOnboardingFlow(ctx context.Context, flow *CircleOnboardingDoc) error {
	UpdateModified(&flow.BaseDocument)

	filter := bson.M{"flowId": flow.FlowID}
	update := bson.M{"$set": flow}

	result, err := r.onboarding.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating onboarding flow %s: %w", flow.FlowID, err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("onboarding flow %s: not found", flow.FlowID)
	}

	return nil
}

// DeleteOnboardingFlow deletes an onboarding flow (cleanup after completion).
func (r *ThreeCirclesRepo) DeleteOnboardingFlow(ctx context.Context, flowID string) error {
	result, err := r.onboarding.DeleteOne(ctx, bson.M{"flowId": flowID})
	if err != nil {
		return fmt.Errorf("deleting onboarding flow %s: %w", flowID, err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("onboarding flow %s: not found", flowID)
	}

	return nil
}
