// internal/repository/threecircles_repo.go
package repository

import (
	"go.mongodb.org/mongo-driver/v2/mongo"
)

// ThreeCirclesRepo implements ThreeCirclesRepository using MongoDB.
// Manages 11 collections: circle sets, version history, templates, starter packs,
// onboarding flows, shares, sponsor comments, pattern timeline, insights, drift alerts, and reviews.
type ThreeCirclesRepo struct {
	sets         *mongo.Collection
	versions     *mongo.Collection
	templates    *mongo.Collection
	starterPacks *mongo.Collection
	onboarding   *mongo.Collection
	shares       *mongo.Collection
	comments     *mongo.Collection
	timeline     *mongo.Collection
	insights     *mongo.Collection
	driftAlerts  *mongo.Collection
	reviews      *mongo.Collection
	activities   *mongo.Collection // calendar activity dual-write
}

// NewThreeCirclesRepo creates a new ThreeCirclesRepo.
func NewThreeCirclesRepo(client *MongoClient) *ThreeCirclesRepo {
	return &ThreeCirclesRepo{
		sets:         client.Collection("circlesSets"),
		versions:     client.Collection("circlesVersions"),
		templates:    client.Collection("circlesTemplates"),
		starterPacks: client.Collection("circlesStarterPacks"),
		onboarding:   client.Collection("circlesOnboarding"),
		shares:       client.Collection("circlesShares"),
		comments:     client.Collection("circlesSponsorComments"),
		timeline:     client.Collection("circlesPatternTimeline"),
		insights:     client.Collection("circlesInsights"),
		driftAlerts:  client.Collection("circlesDriftAlerts"),
		reviews:      client.Collection("circlesReviews"),
		activities:   client.Collection("activities"),
	}
}
