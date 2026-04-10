// internal/repository/threecircles_template_repo.go
package repository

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// --- Template operations ---
// AP-TC-09: List templates by recovery area and circle
// AP-TC-10: Get template detail
// AP-TC-11: List framework-specific templates

// GetCircleTemplateByID retrieves a single template by ID.
// AP-TC-10: Get template detail
func (r *ThreeCirclesRepo) GetCircleTemplateByID(ctx context.Context, templateID string) (*CircleTemplateDoc, error) {
	var doc CircleTemplateDoc
	err := r.templates.FindOne(ctx, bson.M{"templateId": templateID}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting template %s: %w", templateID, err)
	}
	return &doc, nil
}

// ListCircleTemplates retrieves templates filtered by recovery area, circle, and active status.
// AP-TC-09: List templates by recovery area and circle
func (r *ThreeCirclesRepo) ListCircleTemplates(ctx context.Context, recoveryArea string, circle *string, active bool) ([]CircleTemplateDoc, error) {
	filter := bson.M{
		"recoveryArea": recoveryArea,
		"active":       active,
	}
	if circle != nil {
		filter["circle"] = *circle
	}

	opts := options.Find().SetSort(bson.D{{Key: "sortOrder", Value: 1}})
	cursor, err := r.templates.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing templates: %w", err)
	}

	var docs []CircleTemplateDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding templates: %w", err)
	}
	return docs, nil
}

// ListCircleTemplatesByFramework retrieves templates for a specific recovery area and framework.
// AP-TC-11: List framework-specific templates
func (r *ThreeCirclesRepo) ListCircleTemplatesByFramework(ctx context.Context, recoveryArea string, frameworkVariant *string) ([]CircleTemplateDoc, error) {
	filter := bson.M{
		"recoveryArea": recoveryArea,
		"active":       true,
	}

	// Include universal templates (null framework) and framework-specific templates.
	if frameworkVariant != nil {
		filter["$or"] = []bson.M{
			{"frameworkVariant": nil},
			{"frameworkVariant": *frameworkVariant},
		}
	} else {
		filter["frameworkVariant"] = nil
	}

	opts := options.Find().SetSort(bson.D{{Key: "circle", Value: 1}, {Key: "sortOrder", Value: 1}})
	cursor, err := r.templates.Find(ctx, filter, opts)
	if err != nil {
		return nil, fmt.Errorf("listing framework templates: %w", err)
	}

	var docs []CircleTemplateDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding framework templates: %w", err)
	}
	return docs, nil
}

// --- Starter Pack operations ---
// AP-TC-12: List starter packs by recovery area + variant
// AP-TC-13: Get starter pack detail

// GetStarterPackByID retrieves a single starter pack by ID.
// AP-TC-13: Get starter pack detail
func (r *ThreeCirclesRepo) GetStarterPackByID(ctx context.Context, packID string) (*CircleStarterPackDoc, error) {
	var doc CircleStarterPackDoc
	err := r.starterPacks.FindOne(ctx, bson.M{"packId": packID}).Decode(&doc)
	if err != nil {
		return nil, fmt.Errorf("getting starter pack %s: %w", packID, err)
	}
	return &doc, nil
}

// ListStarterPacks retrieves starter packs filtered by recovery area and variant.
// AP-TC-12: List starter packs by recovery area + variant
func (r *ThreeCirclesRepo) ListStarterPacks(ctx context.Context, recoveryArea string, variant *string, active bool) ([]CircleStarterPackDoc, error) {
	filter := bson.M{
		"recoveryArea": recoveryArea,
		"active":       active,
	}
	if variant != nil {
		filter["variant"] = *variant
	}

	cursor, err := r.starterPacks.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("listing starter packs: %w", err)
	}

	var docs []CircleStarterPackDoc
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding starter packs: %w", err)
	}
	return docs, nil
}
