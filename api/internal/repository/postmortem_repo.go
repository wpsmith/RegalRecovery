// internal/repository/postmortem_repo.go
package repository

import (
	"context"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/regalrecovery/api/internal/domain/postmortem"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

// PostMortemDocument is the MongoDB document model for a post-mortem analysis.
type PostMortemDocument struct {
	BaseDocument `bson:",inline"`

	UserID      string `bson:"userId"`
	EntityType  string `bson:"entityType"`
	AnalysisID  string `bson:"analysisId"`
	Status      string `bson:"status"`
	EventType   string `bson:"eventType"`
	RelapseID   string `bson:"relapseId,omitempty"`
	AddictionID string `bson:"addictionId,omitempty"`
	Timestamp   time.Time `bson:"timestamp"`

	Sections       PostMortemSectionsDoc `bson:"sections"`
	TriggerSummary []string              `bson:"triggerSummary,omitempty"`
	TriggerDetails []TriggerDetailDoc    `bson:"triggerDetails,omitempty"`
	FasterMapping  []FasterMappingDoc    `bson:"fasterMapping,omitempty"`
	ActionPlan     []ActionPlanItemDoc   `bson:"actionPlan,omitempty"`
	Sharing        SharingStatusDoc      `bson:"sharing"`
	LinkedEntities LinkedEntitiesDoc     `bson:"linkedEntities"`

	CompletedAt *time.Time `bson:"completedAt,omitempty"`
}

// PostMortemSectionsDoc stores the six walkthrough sections.
type PostMortemSectionsDoc struct {
	DayBefore        *DayBeforeSectionDoc        `bson:"dayBefore,omitempty"`
	Morning          *MorningSectionDoc           `bson:"morning,omitempty"`
	ThroughoutTheDay *ThroughoutTheDaySectionDoc  `bson:"throughoutTheDay,omitempty"`
	BuildUp          *BuildUpSectionDoc           `bson:"buildUp,omitempty"`
	ActingOut        *ActingOutSectionDoc          `bson:"actingOut,omitempty"`
	ImmediatelyAfter *ImmediatelyAfterSectionDoc  `bson:"immediatelyAfter,omitempty"`
}

type DayBeforeSectionDoc struct {
	Text                  string `bson:"text"`
	MoodRating            *int   `bson:"moodRating,omitempty"`
	RecoveryPracticesKept *bool  `bson:"recoveryPracticesKept,omitempty"`
	UnresolvedConflicts   string `bson:"unresolvedConflicts,omitempty"`
}

type MorningSectionDoc struct {
	Text                       string              `bson:"text"`
	MoodRating                 *int                `bson:"moodRating,omitempty"`
	MorningCommitmentCompleted *bool               `bson:"morningCommitmentCompleted,omitempty"`
	AffirmationViewed          *bool               `bson:"affirmationViewed,omitempty"`
	AutoPopulated              *AutoPopulatedDoc   `bson:"autoPopulated,omitempty"`
}

type AutoPopulatedDoc struct {
	MorningCommitmentCompleted *bool `bson:"morningCommitmentCompleted,omitempty"`
	MoodRating                 *int  `bson:"moodRating,omitempty"`
	AffirmationViewed          *bool `bson:"affirmationViewed,omitempty"`
}

type ThroughoutTheDaySectionDoc struct {
	TimeBlocks      []TimeBlockDoc    `bson:"timeBlocks,omitempty"`
	FreeFormEntries []FreeFormEntryDoc `bson:"freeFormEntries,omitempty"`
}

type TimeBlockDoc struct {
	Period       string   `bson:"period"`
	StartTime    string   `bson:"startTime"`
	EndTime      string   `bson:"endTime"`
	Activity     string   `bson:"activity,omitempty"`
	Location     string   `bson:"location,omitempty"`
	Company      string   `bson:"company,omitempty"`
	Thoughts     string   `bson:"thoughts,omitempty"`
	Feelings     string   `bson:"feelings,omitempty"`
	WarningSigns []string `bson:"warningSigns,omitempty"`
}

type FreeFormEntryDoc struct {
	Time string `bson:"time"`
	Text string `bson:"text"`
}

type BuildUpSectionDoc struct {
	FirstNoticed            string                     `bson:"firstNoticed,omitempty"`
	Triggers                []TriggerDetailDoc         `bson:"triggers,omitempty"`
	ResponseToWarnings      string                     `bson:"responseToWarnings,omitempty"`
	MissedHelpOpportunities []MissedHelpOpportunityDoc `bson:"missedHelpOpportunities,omitempty"`
	DecisionPoints          []DecisionPointDoc         `bson:"decisionPoints,omitempty"`
}

type MissedHelpOpportunityDoc struct {
	Description string `bson:"description"`
	Reason      string `bson:"reason"`
}

type DecisionPointDoc struct {
	TimeOfDay     string `bson:"timeOfDay"`
	Description   string `bson:"description"`
	CouldHaveDone string `bson:"couldHaveDone"`
	InsteadDid    string `bson:"insteadDid"`
}

type ActingOutSectionDoc struct {
	Description     string `bson:"description"`
	AddictionID     string `bson:"addictionId,omitempty"`
	DurationMinutes *int   `bson:"durationMinutes,omitempty"`
	LinkedRelapseID string `bson:"linkedRelapseId,omitempty"`
}

type ImmediatelyAfterSectionDoc struct {
	Feelings                []string `bson:"feelings,omitempty"`
	FeelingsWheelSelections []string `bson:"feelingsWheelSelections,omitempty"`
	WhatDidNext             string   `bson:"whatDidNext,omitempty"`
	ReachedOut              *bool    `bson:"reachedOut,omitempty"`
	ReachedOutTo            *string  `bson:"reachedOutTo,omitempty"`
	WishDoneDifferently     string   `bson:"wishDoneDifferently,omitempty"`
}

type TriggerDetailDoc struct {
	Category   string  `bson:"category"`
	Surface    string  `bson:"surface"`
	Underlying *string `bson:"underlying,omitempty"`
	CoreWound  *string `bson:"coreWound,omitempty"`
}

type FasterMappingDoc struct {
	TimeOfDay string `bson:"timeOfDay"`
	Stage     string `bson:"stage"`
}

type ActionPlanItemDoc struct {
	ActionID                string  `bson:"actionId"`
	TimelinePoint           string  `bson:"timelinePoint,omitempty"`
	Action                  string  `bson:"action"`
	Category                string  `bson:"category"`
	ConvertedToCommitmentID *string `bson:"convertedToCommitmentId,omitempty"`
	ConvertedToGoalID       *string `bson:"convertedToGoalId,omitempty"`
}

type SharingStatusDoc struct {
	IsShared   bool               `bson:"isShared"`
	SharedWith []SharedWithEntryDoc `bson:"sharedWith,omitempty"`
}

type SharedWithEntryDoc struct {
	ContactID string    `bson:"contactId"`
	ShareType string    `bson:"shareType"`
	SharedAt  time.Time `bson:"sharedAt"`
}

type LinkedEntitiesDoc struct {
	RelapseID      *string  `bson:"relapseId,omitempty"`
	UrgeLogIDs     []string `bson:"urgeLogIds,omitempty"`
	FasterEntryIDs []string `bson:"fasterEntryIds,omitempty"`
	CheckInIDs     []string `bson:"checkInIds,omitempty"`
}

// MongoPostMortemRepository implements PostMortemRepository using MongoDB.
type MongoPostMortemRepository struct {
	collection         *mongo.Collection
	calendarCollection *mongo.Collection
}

// NewMongoPostMortemRepository creates a new MongoDB-backed post-mortem repository.
func NewMongoPostMortemRepository(db *mongo.Database) *MongoPostMortemRepository {
	return &MongoPostMortemRepository{
		collection:         db.Collection("postMortems"),
		calendarCollection: db.Collection("calendarActivities"),
	}
}

// Create persists a new post-mortem analysis.
func (r *MongoPostMortemRepository) Create(ctx context.Context, analysis *postmortem.PostMortemAnalysis) error {
	doc := domainToDoc(analysis)
	SetBaseDocumentDefaults(&doc.BaseDocument)
	doc.EntityType = "POSTMORTEM"

	_, err := r.collection.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("inserting post-mortem: %w", err)
	}
	return nil
}

// GetByID retrieves a post-mortem by user ID and analysis ID.
func (r *MongoPostMortemRepository) GetByID(ctx context.Context, userID, analysisID string) (*postmortem.PostMortemAnalysis, error) {
	filter := bson.M{"userId": userID, "analysisId": analysisID}
	var doc PostMortemDocument
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding post-mortem: %w", err)
	}
	return docToDomain(&doc), nil
}

// GetByRelapseID retrieves a post-mortem linked to a specific relapse.
func (r *MongoPostMortemRepository) GetByRelapseID(ctx context.Context, userID, relapseID string) (*postmortem.PostMortemAnalysis, error) {
	filter := bson.M{"userId": userID, "relapseId": relapseID}
	var doc PostMortemDocument
	err := r.collection.FindOne(ctx, filter).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, fmt.Errorf("finding post-mortem by relapse: %w", err)
	}
	return docToDomain(&doc), nil
}

// List retrieves post-mortems for a user with filters and cursor-based pagination.
func (r *MongoPostMortemRepository) List(ctx context.Context, userID string, filter postmortem.ListFilter) (*postmortem.PaginatedResult, error) {
	query := bson.M{"userId": userID}

	if filter.StartDate != nil {
		if query["createdAt"] == nil {
			query["createdAt"] = bson.M{}
		}
		query["createdAt"].(bson.M)["$gte"] = *filter.StartDate
	}
	if filter.EndDate != nil {
		if query["createdAt"] == nil {
			query["createdAt"] = bson.M{}
		}
		query["createdAt"].(bson.M)["$lte"] = *filter.EndDate
	}
	if filter.AddictionID != nil {
		query["addictionId"] = *filter.AddictionID
	}
	if filter.Status != nil {
		query["status"] = *filter.Status
	}
	if filter.EventType != nil {
		query["eventType"] = *filter.EventType
	}

	// Cursor decoding.
	if filter.Cursor != "" {
		cursorBytes, err := base64.StdEncoding.DecodeString(filter.Cursor)
		if err == nil {
			cursorTime, parseErr := time.Parse(time.RFC3339, string(cursorBytes))
			if parseErr == nil {
				if query["createdAt"] == nil {
					query["createdAt"] = bson.M{}
				}
				query["createdAt"].(bson.M)["$lt"] = cursorTime
			}
		}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "createdAt", Value: -1}}).
		SetLimit(int64(filter.Limit + 1)) // Fetch one extra to determine if there's a next page.

	cursor, err := r.collection.Find(ctx, query, opts)
	if err != nil {
		return nil, fmt.Errorf("listing post-mortems: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []PostMortemDocument
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding post-mortems: %w", err)
	}

	result := &postmortem.PaginatedResult{}
	hasMore := len(docs) > filter.Limit
	if hasMore {
		docs = docs[:filter.Limit]
	}

	for _, doc := range docs {
		d := doc
		result.Analyses = append(result.Analyses, docToDomain(&d))
	}

	if hasMore && len(docs) > 0 {
		lastDoc := docs[len(docs)-1]
		result.NextCursor = base64.StdEncoding.EncodeToString(
			[]byte(lastDoc.CreatedAt.Format(time.RFC3339)),
		)
	}

	return result, nil
}

// FindDrafts retrieves all draft post-mortems for a user.
func (r *MongoPostMortemRepository) FindDrafts(ctx context.Context, userID string) ([]*postmortem.PostMortemAnalysis, error) {
	filter := bson.M{"userId": userID, "status": "draft"}
	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("finding drafts: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []PostMortemDocument
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding drafts: %w", err)
	}

	var result []*postmortem.PostMortemAnalysis
	for _, doc := range docs {
		d := doc
		result = append(result, docToDomain(&d))
	}
	return result, nil
}

// Update persists changes to a post-mortem analysis, preserving immutable createdAt.
func (r *MongoPostMortemRepository) Update(ctx context.Context, analysis *postmortem.PostMortemAnalysis) error {
	doc := domainToDoc(analysis)
	filter := bson.M{"userId": analysis.UserID, "analysisId": analysis.AnalysisID}

	// Explicitly exclude createdAt from $set to enforce immutability.
	update := bson.M{
		"$set": bson.M{
			"modifiedAt":     doc.ModifiedAt,
			"status":         doc.Status,
			"sections":       doc.Sections,
			"triggerSummary":  doc.TriggerSummary,
			"triggerDetails":  doc.TriggerDetails,
			"fasterMapping":   doc.FasterMapping,
			"actionPlan":      doc.ActionPlan,
			"sharing":         doc.Sharing,
			"linkedEntities":  doc.LinkedEntities,
			"completedAt":     doc.CompletedAt,
		},
	}

	result, err := r.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("updating post-mortem: %w", err)
	}
	if result.MatchedCount == 0 {
		return fmt.Errorf("post-mortem not found for update")
	}
	return nil
}

// Delete removes a post-mortem by user ID and analysis ID.
func (r *MongoPostMortemRepository) Delete(ctx context.Context, userID, analysisID string) error {
	filter := bson.M{"userId": userID, "analysisId": analysisID}
	result, err := r.collection.DeleteOne(ctx, filter)
	if err != nil {
		return fmt.Errorf("deleting post-mortem: %w", err)
	}
	if result.DeletedCount == 0 {
		return fmt.Errorf("post-mortem not found for deletion")
	}
	return nil
}

// GetInsightsData retrieves completed post-mortems for cross-analysis insights.
func (r *MongoPostMortemRepository) GetInsightsData(ctx context.Context, userID string, filter *postmortem.InsightsFilter) ([]*postmortem.PostMortemAnalysis, error) {
	query := bson.M{"userId": userID, "status": "complete"}
	if filter != nil && filter.AddictionID != nil {
		query["addictionId"] = *filter.AddictionID
	}

	cursor, err := r.collection.Find(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("getting insights data: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []PostMortemDocument
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding insights data: %w", err)
	}

	var result []*postmortem.PostMortemAnalysis
	for _, doc := range docs {
		d := doc
		result = append(result, docToDomain(&d))
	}
	return result, nil
}

// GetSharedWith retrieves post-mortems shared with a specific contact.
func (r *MongoPostMortemRepository) GetSharedWith(ctx context.Context, contactID string) ([]*postmortem.PostMortemAnalysis, error) {
	filter := bson.M{"sharing.sharedWith.contactId": contactID}
	cursor, err := r.collection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("getting shared post-mortems: %w", err)
	}
	defer cursor.Close(ctx)

	var docs []PostMortemDocument
	if err := cursor.All(ctx, &docs); err != nil {
		return nil, fmt.Errorf("decoding shared post-mortems: %w", err)
	}

	var result []*postmortem.PostMortemAnalysis
	for _, doc := range docs {
		d := doc
		result = append(result, docToDomain(&d))
	}
	return result, nil
}

// WriteCalendarActivity writes a calendar activity entry on post-mortem completion.
func (r *MongoPostMortemRepository) WriteCalendarActivity(ctx context.Context, entry *postmortem.CalendarActivityEntry) error {
	doc := bson.M{
		"userId":       entry.UserID,
		"date":         entry.Date,
		"activityType": entry.ActivityType,
		"timestamp":    entry.Timestamp,
		"summary": bson.M{
			"analysisId":      entry.Summary.AnalysisID,
			"eventType":       entry.Summary.EventType,
			"status":          entry.Summary.Status,
			"triggerCount":    entry.Summary.TriggerCount,
			"actionItemCount": entry.Summary.ActionItemCount,
		},
		"sourceKey":  entry.SourceKey,
		"createdAt":  NowUTC(),
		"modifiedAt": NowUTC(),
		"tenantId":   "DEFAULT",
	}

	_, err := r.calendarCollection.InsertOne(ctx, doc)
	if err != nil {
		return fmt.Errorf("writing calendar activity: %w", err)
	}
	return nil
}

// --- Document <-> Domain Conversion ---

func domainToDoc(a *postmortem.PostMortemAnalysis) *PostMortemDocument {
	doc := &PostMortemDocument{
		UserID:      a.UserID,
		AnalysisID:  a.AnalysisID,
		Status:      a.Status,
		EventType:   a.EventType,
		Timestamp:   a.Timestamp,
		CompletedAt: a.CompletedAt,
	}
	doc.CreatedAt = a.CreatedAt
	doc.ModifiedAt = a.ModifiedAt
	doc.TenantID = a.TenantID

	if a.RelapseID != nil {
		doc.RelapseID = *a.RelapseID
	}
	if a.AddictionID != nil {
		doc.AddictionID = *a.AddictionID
	}

	doc.Sections = sectionsDomainToDoc(&a.Sections)
	doc.TriggerSummary = a.TriggerSummary
	doc.TriggerDetails = triggerDetailsDomainToDoc(a.TriggerDetails)
	doc.FasterMapping = fasterMappingDomainToDoc(a.FasterMapping)
	doc.ActionPlan = actionPlanDomainToDoc(a.ActionPlan)
	doc.Sharing = sharingDomainToDoc(a.Sharing)
	doc.LinkedEntities = linkedEntitiesDomainToDoc(a.LinkedEntities)

	return doc
}

func docToDomain(doc *PostMortemDocument) *postmortem.PostMortemAnalysis {
	a := &postmortem.PostMortemAnalysis{
		AnalysisID:  doc.AnalysisID,
		UserID:      doc.UserID,
		TenantID:    doc.TenantID,
		Status:      doc.Status,
		EventType:   doc.EventType,
		Timestamp:   doc.Timestamp,
		CreatedAt:   doc.CreatedAt,
		ModifiedAt:  doc.ModifiedAt,
		CompletedAt: doc.CompletedAt,
	}

	if doc.RelapseID != "" {
		a.RelapseID = &doc.RelapseID
	}
	if doc.AddictionID != "" {
		a.AddictionID = &doc.AddictionID
	}

	a.Sections = sectionsDocToDomain(&doc.Sections)
	a.TriggerSummary = doc.TriggerSummary
	a.TriggerDetails = triggerDetailsDocToDomain(doc.TriggerDetails)
	a.FasterMapping = fasterMappingDocToDomain(doc.FasterMapping)
	a.ActionPlan = actionPlanDocToDomain(doc.ActionPlan)
	a.Sharing = sharingDocToDomain(doc.Sharing)
	a.LinkedEntities = linkedEntitiesDocToDomain(doc.LinkedEntities)

	return a
}

func sectionsDomainToDoc(s *postmortem.Sections) PostMortemSectionsDoc {
	doc := PostMortemSectionsDoc{}
	if s.DayBefore != nil {
		doc.DayBefore = &DayBeforeSectionDoc{
			Text: s.DayBefore.Text, MoodRating: s.DayBefore.MoodRating,
			RecoveryPracticesKept: s.DayBefore.RecoveryPracticesKept,
			UnresolvedConflicts: s.DayBefore.UnresolvedConflicts,
		}
	}
	if s.Morning != nil {
		doc.Morning = &MorningSectionDoc{
			Text: s.Morning.Text, MoodRating: s.Morning.MoodRating,
			MorningCommitmentCompleted: s.Morning.MorningCommitmentCompleted,
			AffirmationViewed: s.Morning.AffirmationViewed,
		}
		if s.Morning.AutoPopulated != nil {
			doc.Morning.AutoPopulated = &AutoPopulatedDoc{
				MorningCommitmentCompleted: s.Morning.AutoPopulated.MorningCommitmentCompleted,
				MoodRating: s.Morning.AutoPopulated.MoodRating,
				AffirmationViewed: s.Morning.AutoPopulated.AffirmationViewed,
			}
		}
	}
	if s.ThroughoutTheDay != nil {
		td := &ThroughoutTheDaySectionDoc{}
		for _, tb := range s.ThroughoutTheDay.TimeBlocks {
			td.TimeBlocks = append(td.TimeBlocks, TimeBlockDoc{
				Period: tb.Period, StartTime: tb.StartTime, EndTime: tb.EndTime,
				Activity: tb.Activity, Location: tb.Location, Company: tb.Company,
				Thoughts: tb.Thoughts, Feelings: tb.Feelings, WarningSigns: tb.WarningSigns,
			})
		}
		for _, fe := range s.ThroughoutTheDay.FreeFormEntries {
			td.FreeFormEntries = append(td.FreeFormEntries, FreeFormEntryDoc{Time: fe.Time, Text: fe.Text})
		}
		doc.ThroughoutTheDay = td
	}
	if s.BuildUp != nil {
		bu := &BuildUpSectionDoc{
			FirstNoticed: s.BuildUp.FirstNoticed,
			ResponseToWarnings: s.BuildUp.ResponseToWarnings,
		}
		bu.Triggers = triggerDetailsDomainToDoc(s.BuildUp.Triggers)
		for _, mho := range s.BuildUp.MissedHelpOpportunities {
			bu.MissedHelpOpportunities = append(bu.MissedHelpOpportunities, MissedHelpOpportunityDoc{
				Description: mho.Description, Reason: mho.Reason,
			})
		}
		for _, dp := range s.BuildUp.DecisionPoints {
			bu.DecisionPoints = append(bu.DecisionPoints, DecisionPointDoc{
				TimeOfDay: dp.TimeOfDay, Description: dp.Description,
				CouldHaveDone: dp.CouldHaveDone, InsteadDid: dp.InsteadDid,
			})
		}
		doc.BuildUp = bu
	}
	if s.ActingOut != nil {
		ao := &ActingOutSectionDoc{
			Description: s.ActingOut.Description, AddictionID: s.ActingOut.AddictionID,
			DurationMinutes: s.ActingOut.DurationMinutes,
		}
		if s.ActingOut.LinkedRelapseID != nil {
			ao.LinkedRelapseID = *s.ActingOut.LinkedRelapseID
		}
		doc.ActingOut = ao
	}
	if s.ImmediatelyAfter != nil {
		doc.ImmediatelyAfter = &ImmediatelyAfterSectionDoc{
			Feelings: s.ImmediatelyAfter.Feelings,
			FeelingsWheelSelections: s.ImmediatelyAfter.FeelingsWheelSelections,
			WhatDidNext: s.ImmediatelyAfter.WhatDidNext,
			ReachedOut: s.ImmediatelyAfter.ReachedOut,
			ReachedOutTo: s.ImmediatelyAfter.ReachedOutTo,
			WishDoneDifferently: s.ImmediatelyAfter.WishDoneDifferently,
		}
	}
	return doc
}

func sectionsDocToDomain(doc *PostMortemSectionsDoc) postmortem.Sections {
	s := postmortem.Sections{}
	if doc.DayBefore != nil {
		s.DayBefore = &postmortem.DayBeforeSection{
			Text: doc.DayBefore.Text, MoodRating: doc.DayBefore.MoodRating,
			RecoveryPracticesKept: doc.DayBefore.RecoveryPracticesKept,
			UnresolvedConflicts: doc.DayBefore.UnresolvedConflicts,
		}
	}
	if doc.Morning != nil {
		s.Morning = &postmortem.MorningSection{
			Text: doc.Morning.Text, MoodRating: doc.Morning.MoodRating,
			MorningCommitmentCompleted: doc.Morning.MorningCommitmentCompleted,
			AffirmationViewed: doc.Morning.AffirmationViewed,
		}
		if doc.Morning.AutoPopulated != nil {
			s.Morning.AutoPopulated = &postmortem.AutoPopulatedData{
				MorningCommitmentCompleted: doc.Morning.AutoPopulated.MorningCommitmentCompleted,
				MoodRating: doc.Morning.AutoPopulated.MoodRating,
				AffirmationViewed: doc.Morning.AutoPopulated.AffirmationViewed,
			}
		}
	}
	if doc.ThroughoutTheDay != nil {
		td := &postmortem.ThroughoutTheDaySection{}
		for _, tb := range doc.ThroughoutTheDay.TimeBlocks {
			td.TimeBlocks = append(td.TimeBlocks, postmortem.TimeBlock{
				Period: tb.Period, StartTime: tb.StartTime, EndTime: tb.EndTime,
				Activity: tb.Activity, Location: tb.Location, Company: tb.Company,
				Thoughts: tb.Thoughts, Feelings: tb.Feelings, WarningSigns: tb.WarningSigns,
			})
		}
		for _, fe := range doc.ThroughoutTheDay.FreeFormEntries {
			td.FreeFormEntries = append(td.FreeFormEntries, postmortem.FreeFormEntry{Time: fe.Time, Text: fe.Text})
		}
		s.ThroughoutTheDay = td
	}
	if doc.BuildUp != nil {
		bu := &postmortem.BuildUpSection{
			FirstNoticed: doc.BuildUp.FirstNoticed,
			ResponseToWarnings: doc.BuildUp.ResponseToWarnings,
			Triggers: triggerDetailsDocToDomain(doc.BuildUp.Triggers),
		}
		for _, mho := range doc.BuildUp.MissedHelpOpportunities {
			bu.MissedHelpOpportunities = append(bu.MissedHelpOpportunities, postmortem.MissedHelpOpportunity{
				Description: mho.Description, Reason: mho.Reason,
			})
		}
		for _, dp := range doc.BuildUp.DecisionPoints {
			bu.DecisionPoints = append(bu.DecisionPoints, postmortem.DecisionPoint{
				TimeOfDay: dp.TimeOfDay, Description: dp.Description,
				CouldHaveDone: dp.CouldHaveDone, InsteadDid: dp.InsteadDid,
			})
		}
		s.BuildUp = bu
	}
	if doc.ActingOut != nil {
		ao := &postmortem.ActingOutSection{
			Description: doc.ActingOut.Description, AddictionID: doc.ActingOut.AddictionID,
			DurationMinutes: doc.ActingOut.DurationMinutes,
		}
		if doc.ActingOut.LinkedRelapseID != "" {
			ao.LinkedRelapseID = &doc.ActingOut.LinkedRelapseID
		}
		s.ActingOut = ao
	}
	if doc.ImmediatelyAfter != nil {
		s.ImmediatelyAfter = &postmortem.ImmediatelyAfterSection{
			Feelings: doc.ImmediatelyAfter.Feelings,
			FeelingsWheelSelections: doc.ImmediatelyAfter.FeelingsWheelSelections,
			WhatDidNext: doc.ImmediatelyAfter.WhatDidNext,
			ReachedOut: doc.ImmediatelyAfter.ReachedOut,
			ReachedOutTo: doc.ImmediatelyAfter.ReachedOutTo,
			WishDoneDifferently: doc.ImmediatelyAfter.WishDoneDifferently,
		}
	}
	return s
}

func triggerDetailsDomainToDoc(triggers []postmortem.TriggerDetail) []TriggerDetailDoc {
	var docs []TriggerDetailDoc
	for _, t := range triggers {
		docs = append(docs, TriggerDetailDoc{
			Category: t.Category, Surface: t.Surface,
			Underlying: t.Underlying, CoreWound: t.CoreWound,
		})
	}
	return docs
}

func triggerDetailsDocToDomain(docs []TriggerDetailDoc) []postmortem.TriggerDetail {
	var triggers []postmortem.TriggerDetail
	for _, d := range docs {
		triggers = append(triggers, postmortem.TriggerDetail{
			Category: d.Category, Surface: d.Surface,
			Underlying: d.Underlying, CoreWound: d.CoreWound,
		})
	}
	return triggers
}

func fasterMappingDomainToDoc(entries []postmortem.FasterMappingEntry) []FasterMappingDoc {
	var docs []FasterMappingDoc
	for _, e := range entries {
		docs = append(docs, FasterMappingDoc{TimeOfDay: e.TimeOfDay, Stage: e.Stage})
	}
	return docs
}

func fasterMappingDocToDomain(docs []FasterMappingDoc) []postmortem.FasterMappingEntry {
	var entries []postmortem.FasterMappingEntry
	for _, d := range docs {
		entries = append(entries, postmortem.FasterMappingEntry{TimeOfDay: d.TimeOfDay, Stage: d.Stage})
	}
	return entries
}

func actionPlanDomainToDoc(items []postmortem.ActionPlanItem) []ActionPlanItemDoc {
	var docs []ActionPlanItemDoc
	for _, i := range items {
		docs = append(docs, ActionPlanItemDoc{
			ActionID: i.ActionID, TimelinePoint: i.TimelinePoint,
			Action: i.Action, Category: i.Category,
			ConvertedToCommitmentID: i.ConvertedToCommitmentID,
			ConvertedToGoalID: i.ConvertedToGoalID,
		})
	}
	return docs
}

func actionPlanDocToDomain(docs []ActionPlanItemDoc) []postmortem.ActionPlanItem {
	var items []postmortem.ActionPlanItem
	for _, d := range docs {
		items = append(items, postmortem.ActionPlanItem{
			ActionID: d.ActionID, TimelinePoint: d.TimelinePoint,
			Action: d.Action, Category: d.Category,
			ConvertedToCommitmentID: d.ConvertedToCommitmentID,
			ConvertedToGoalID: d.ConvertedToGoalID,
		})
	}
	return items
}

func sharingDomainToDoc(s postmortem.SharingStatus) SharingStatusDoc {
	doc := SharingStatusDoc{IsShared: s.IsShared}
	for _, sw := range s.SharedWith {
		doc.SharedWith = append(doc.SharedWith, SharedWithEntryDoc{
			ContactID: sw.ContactID, ShareType: sw.ShareType, SharedAt: sw.SharedAt,
		})
	}
	return doc
}

func sharingDocToDomain(doc SharingStatusDoc) postmortem.SharingStatus {
	s := postmortem.SharingStatus{IsShared: doc.IsShared}
	for _, sw := range doc.SharedWith {
		s.SharedWith = append(s.SharedWith, postmortem.SharedWithEntry{
			ContactID: sw.ContactID, ShareType: sw.ShareType, SharedAt: sw.SharedAt,
		})
	}
	return s
}

func linkedEntitiesDomainToDoc(le postmortem.LinkedEntities) LinkedEntitiesDoc {
	return LinkedEntitiesDoc{
		RelapseID: le.RelapseID, UrgeLogIDs: le.UrgeLogIDs,
		FasterEntryIDs: le.FasterEntryIDs, CheckInIDs: le.CheckInIDs,
	}
}

func linkedEntitiesDocToDomain(doc LinkedEntitiesDoc) postmortem.LinkedEntities {
	return postmortem.LinkedEntities{
		RelapseID: doc.RelapseID, UrgeLogIDs: doc.UrgeLogIDs,
		FasterEntryIDs: doc.FasterEntryIDs, CheckInIDs: doc.CheckInIDs,
	}
}
