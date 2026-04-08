// internal/handler/postmortem_handler.go
package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/regalrecovery/api/internal/domain/postmortem"
)

// Error codes per implementation plan.
const (
	ErrCodeIncomplete        = "rr:0x00050001"
	ErrCodeInvalidEventType  = "rr:0x00050002"
	ErrCodeNearMissLink      = "rr:0x00050003"
	ErrCodeDeleteCompleted   = "rr:0x00050004"
	ErrCodeShareDraft        = "rr:0x00050005"
	ErrCodeInvalidTrigger    = "rr:0x00050006"
	ErrCodeInvalidFASTER     = "rr:0x00050007"
	ErrCodeInvalidAction     = "rr:0x00050008"
	ErrCodeActionItemLimit   = "rr:0x00050009"
	ErrCodeCompletedImmut    = "rr:0x0005000A"
	ErrCodeExportDraft       = "rr:0x0005000B"
)

// PostMortemHandler handles HTTP requests for the post-mortem API.
type PostMortemHandler struct {
	service *postmortem.PostMortemService
}

// NewPostMortemHandler creates a new PostMortemHandler.
func NewPostMortemHandler(service *postmortem.PostMortemService) *PostMortemHandler {
	return &PostMortemHandler{service: service}
}

// --- JSON Request/Response Types (camelCase per spec) ---

type createPostMortemRequest struct {
	Timestamp  string       `json:"timestamp"`
	EventType  string       `json:"eventType"`
	RelapseID  *string      `json:"relapseId,omitempty"`
	AddictionID *string     `json:"addictionId,omitempty"`
	Sections   *sectionsJSON `json:"sections,omitempty"`
}

type updatePostMortemRequest struct {
	Sections       *sectionsJSON          `json:"sections,omitempty"`
	TriggerSummary []string               `json:"triggerSummary,omitempty"`
	TriggerDetails []triggerDetailJSON     `json:"triggerDetails,omitempty"`
	FasterMapping  []fasterMappingJSON    `json:"fasterMapping,omitempty"`
	ActionPlan     []actionPlanItemJSON   `json:"actionPlan,omitempty"`
}

type sharePostMortemRequest struct {
	Shares []shareEntryJSON `json:"shares"`
}

type shareEntryJSON struct {
	ContactID string `json:"contactId"`
	ShareType string `json:"shareType"`
}

type convertActionItemRequest struct {
	TargetType string  `json:"targetType"`
	Title      string  `json:"title"`
	Frequency  *string `json:"frequency,omitempty"`
	TargetDate *string `json:"targetDate,omitempty"`
}

type sectionsJSON struct {
	DayBefore        *dayBeforeJSON        `json:"dayBefore,omitempty"`
	Morning          *morningJSON          `json:"morning,omitempty"`
	ThroughoutTheDay *throughoutTheDayJSON `json:"throughoutTheDay,omitempty"`
	BuildUp          *buildUpJSON          `json:"buildUp,omitempty"`
	ActingOut        *actingOutJSON        `json:"actingOut,omitempty"`
	ImmediatelyAfter *immediatelyAfterJSON `json:"immediatelyAfter,omitempty"`
}

type dayBeforeJSON struct {
	Text                  string `json:"text"`
	MoodRating            *int   `json:"moodRating,omitempty"`
	RecoveryPracticesKept *bool  `json:"recoveryPracticesKept,omitempty"`
	UnresolvedConflicts   string `json:"unresolvedConflicts,omitempty"`
}

type morningJSON struct {
	Text                       string             `json:"text"`
	MoodRating                 *int               `json:"moodRating,omitempty"`
	MorningCommitmentCompleted *bool              `json:"morningCommitmentCompleted,omitempty"`
	AffirmationViewed          *bool              `json:"affirmationViewed,omitempty"`
	AutoPopulated              *autoPopulatedJSON `json:"autoPopulated,omitempty"`
}

type autoPopulatedJSON struct {
	MorningCommitmentCompleted *bool `json:"morningCommitmentCompleted,omitempty"`
	MoodRating                 *int  `json:"moodRating,omitempty"`
	AffirmationViewed          *bool `json:"affirmationViewed,omitempty"`
}

type throughoutTheDayJSON struct {
	TimeBlocks      []timeBlockJSON    `json:"timeBlocks,omitempty"`
	FreeFormEntries []freeFormEntryJSON `json:"freeFormEntries,omitempty"`
}

type timeBlockJSON struct {
	Period       string   `json:"period"`
	StartTime    string   `json:"startTime"`
	EndTime      string   `json:"endTime"`
	Activity     string   `json:"activity,omitempty"`
	Location     string   `json:"location,omitempty"`
	Company      string   `json:"company,omitempty"`
	Thoughts     string   `json:"thoughts,omitempty"`
	Feelings     string   `json:"feelings,omitempty"`
	WarningSigns []string `json:"warningSigns,omitempty"`
}

type freeFormEntryJSON struct {
	Time string `json:"time"`
	Text string `json:"text"`
}

type buildUpJSON struct {
	FirstNoticed            string                       `json:"firstNoticed,omitempty"`
	Triggers                []triggerDetailJSON           `json:"triggers,omitempty"`
	ResponseToWarnings      string                       `json:"responseToWarnings,omitempty"`
	MissedHelpOpportunities []missedHelpOpportunityJSON  `json:"missedHelpOpportunities,omitempty"`
	DecisionPoints          []decisionPointJSON          `json:"decisionPoints,omitempty"`
}

type missedHelpOpportunityJSON struct {
	Description string `json:"description"`
	Reason      string `json:"reason"`
}

type decisionPointJSON struct {
	TimeOfDay     string `json:"timeOfDay"`
	Description   string `json:"description"`
	CouldHaveDone string `json:"couldHaveDone"`
	InsteadDid    string `json:"insteadDid"`
}

type actingOutJSON struct {
	Description     string  `json:"description"`
	AddictionID     string  `json:"addictionId,omitempty"`
	DurationMinutes *int    `json:"durationMinutes,omitempty"`
	LinkedRelapseID *string `json:"linkedRelapseId,omitempty"`
}

type immediatelyAfterJSON struct {
	Feelings                []string `json:"feelings,omitempty"`
	FeelingsWheelSelections []string `json:"feelingsWheelSelections,omitempty"`
	WhatDidNext             string   `json:"whatDidNext,omitempty"`
	ReachedOut              *bool    `json:"reachedOut,omitempty"`
	ReachedOutTo            *string  `json:"reachedOutTo,omitempty"`
	WishDoneDifferently     string   `json:"wishDoneDifferently,omitempty"`
}

type triggerDetailJSON struct {
	Category   string  `json:"category"`
	Surface    string  `json:"surface"`
	Underlying *string `json:"underlying,omitempty"`
	CoreWound  *string `json:"coreWound,omitempty"`
}

type fasterMappingJSON struct {
	TimeOfDay string `json:"timeOfDay"`
	Stage     string `json:"stage"`
}

type actionPlanItemJSON struct {
	ActionID                string  `json:"actionId,omitempty"`
	TimelinePoint           string  `json:"timelinePoint,omitempty"`
	Action                  string  `json:"action"`
	Category                string  `json:"category"`
	ConvertedToCommitmentID *string `json:"convertedToCommitmentId,omitempty"`
	ConvertedToGoalID       *string `json:"convertedToGoalId,omitempty"`
}

// --- Response types ---

type postMortemResponseJSON struct {
	Data interface{}            `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

type postMortemSummaryJSON struct {
	AnalysisID        string            `json:"analysisId"`
	Timestamp         string            `json:"timestamp"`
	Status            string            `json:"status"`
	EventType         string            `json:"eventType"`
	RelapseID         *string           `json:"relapseId,omitempty"`
	AddictionID       *string           `json:"addictionId,omitempty"`
	SectionsCompleted []string          `json:"sectionsCompleted"`
	SectionsRemaining []string          `json:"sectionsRemaining"`
	TriggerSummary    []string          `json:"triggerSummary,omitempty"`
	ActionItemCount   int               `json:"actionItemCount"`
	CompletedAt       *string           `json:"completedAt,omitempty"`
	Links             map[string]string `json:"links,omitempty"`
}

type errorResponseJSON struct {
	Errors []errorObjectJSON `json:"errors"`
}

type errorObjectJSON struct {
	ID            string      `json:"id"`
	Code          string      `json:"code"`
	Status        int         `json:"status"`
	Title         string      `json:"title"`
	Detail        string      `json:"detail,omitempty"`
	CorrelationID string      `json:"correlationId,omitempty"`
	Source        interface{} `json:"source,omitempty"`
}

// --- Handler Methods ---

// CreatePostMortemAnalysis handles POST /activities/post-mortem.
func (h *PostMortemHandler) CreatePostMortemAnalysis(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-Id")
	tenantID := r.Header.Get("X-Tenant-Id")
	correlationID := r.Header.Get("X-Correlation-Id")
	if tenantID == "" {
		tenantID = "DEFAULT"
	}

	var req createPostMortemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, 400, "rr:0x00000001", "Bad Request", "Invalid JSON body", correlationID)
		return
	}

	ts, err := time.Parse(time.RFC3339, req.Timestamp)
	if err != nil {
		writeError(w, 400, "rr:0x00000001", "Bad Request", "Invalid timestamp format", correlationID)
		return
	}

	var sections *postmortem.Sections
	if req.Sections != nil {
		sections = sectionsJSONToDomain(req.Sections)
	}

	analysis, err := h.service.CreateAnalysis(r.Context(), userID, tenantID, req.EventType, req.RelapseID, req.AddictionID, ts, sections)
	if err != nil {
		h.writeValidationError(w, err, correlationID)
		return
	}

	summary := domainToSummaryJSON(analysis)
	resp := postMortemResponseJSON{
		Data: summary,
		Meta: map[string]interface{}{
			"createdAt": analysis.CreatedAt.Format(time.RFC3339),
			"message":   postmortem.OpeningMessage,
		},
	}

	w.Header().Set("Location", fmt.Sprintf("/v1/activities/post-mortem/%s", analysis.AnalysisID))
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Correlation-Id", correlationID)
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(resp)
}

// ListPostMortemAnalyses handles GET /activities/post-mortem.
func (h *PostMortemHandler) ListPostMortemAnalyses(w http.ResponseWriter, r *http.Request) {
	userID := r.Header.Get("X-User-Id")
	query := r.URL.Query()

	filter := postmortem.ListFilter{
		Cursor: query.Get("cursor"),
	}

	if v := query.Get("limit"); v != "" {
		if limit, err := strconv.Atoi(v); err == nil {
			filter.Limit = limit
		}
	}
	if v := query.Get("startDate"); v != "" {
		if t, err := time.Parse("2006-01-02", v); err == nil {
			filter.StartDate = &t
		}
	}
	if v := query.Get("endDate"); v != "" {
		if t, err := time.Parse("2006-01-02", v); err == nil {
			filter.EndDate = &t
		}
	}
	if v := query.Get("addictionId"); v != "" {
		filter.AddictionID = &v
	}
	if v := query.Get("status"); v != "" {
		filter.Status = &v
	}
	if v := query.Get("eventType"); v != "" {
		filter.EventType = &v
	}

	result, err := h.service.ListAnalyses(r.Context(), userID, filter)
	if err != nil {
		writeError(w, 500, "rr:0x00050FFF", "Internal Server Error", err.Error(), "")
		return
	}

	var summaries []postMortemSummaryJSON
	for _, a := range result.Analyses {
		summaries = append(summaries, domainToSummaryJSON(a))
	}
	if summaries == nil {
		summaries = []postMortemSummaryJSON{}
	}

	resp := map[string]interface{}{
		"data": summaries,
		"links": map[string]interface{}{
			"self": r.URL.String(),
		},
		"meta": map[string]interface{}{
			"page": map[string]interface{}{
				"nextCursor": nilIfEmpty(result.NextCursor),
				"limit":      filter.Limit,
			},
			"totalComplete": result.TotalComplete,
			"totalDrafts":   result.TotalDrafts,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// GetPostMortemAnalysis handles GET /activities/post-mortem/{analysisId}.
func (h *PostMortemHandler) GetPostMortemAnalysis(w http.ResponseWriter, r *http.Request, analysisID string) {
	userID := r.Header.Get("X-User-Id")
	correlationID := r.Header.Get("X-Correlation-Id")

	analysis, err := h.service.GetAnalysis(r.Context(), userID, userID, analysisID)
	if err != nil {
		if errors.Is(err, postmortem.ErrNotFound) {
			writeError(w, 404, "rr:0x00000404", "Not Found", "Post-mortem analysis not found", correlationID)
			return
		}
		writeError(w, 500, "rr:0x00050FFF", "Internal Server Error", err.Error(), correlationID)
		return
	}

	resp := postMortemResponseJSON{
		Data: analysis,
		Meta: map[string]interface{}{
			"createdAt":  analysis.CreatedAt.Format(time.RFC3339),
			"modifiedAt": analysis.ModifiedAt.Format(time.RFC3339),
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// UpdatePostMortemAnalysis handles PATCH /activities/post-mortem/{analysisId}.
func (h *PostMortemHandler) UpdatePostMortemAnalysis(w http.ResponseWriter, r *http.Request, analysisID string) {
	userID := r.Header.Get("X-User-Id")
	correlationID := r.Header.Get("X-Correlation-Id")

	analysis, err := h.service.GetAnalysis(r.Context(), userID, userID, analysisID)
	if err != nil {
		if errors.Is(err, postmortem.ErrNotFound) {
			writeError(w, 404, "rr:0x00000404", "Not Found", "Post-mortem analysis not found", correlationID)
			return
		}
		writeError(w, 500, "rr:0x00050FFF", "Internal Server Error", err.Error(), correlationID)
		return
	}

	var req updatePostMortemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, 400, "rr:0x00000001", "Bad Request", "Invalid JSON body", correlationID)
		return
	}

	var sections *postmortem.Sections
	if req.Sections != nil {
		sections = sectionsJSONToDomain(req.Sections)
	}

	var triggerDetails []postmortem.TriggerDetail
	if req.TriggerDetails != nil {
		for _, td := range req.TriggerDetails {
			triggerDetails = append(triggerDetails, postmortem.TriggerDetail{
				Category: td.Category, Surface: td.Surface,
				Underlying: td.Underlying, CoreWound: td.CoreWound,
			})
		}
	}

	var fasterMapping []postmortem.FasterMappingEntry
	if req.FasterMapping != nil {
		for _, fm := range req.FasterMapping {
			fasterMapping = append(fasterMapping, postmortem.FasterMappingEntry{
				TimeOfDay: fm.TimeOfDay, Stage: fm.Stage,
			})
		}
	}

	var actionPlan []postmortem.ActionPlanItem
	if req.ActionPlan != nil {
		for _, ap := range req.ActionPlan {
			actionPlan = append(actionPlan, postmortem.ActionPlanItem{
				ActionID: ap.ActionID, TimelinePoint: ap.TimelinePoint,
				Action: ap.Action, Category: ap.Category,
			})
		}
		actionPlan = postmortem.AssignActionIDs(actionPlan)
	}

	updated, err := h.service.UpdateAnalysis(r.Context(), userID, analysis, sections, req.TriggerSummary, triggerDetails, fasterMapping, actionPlan)
	if err != nil {
		h.writeValidationError(w, err, correlationID)
		return
	}

	resp := postMortemResponseJSON{
		Data: domainToSummaryJSON(updated),
		Meta: map[string]interface{}{
			"createdAt":  updated.CreatedAt.Format(time.RFC3339),
			"modifiedAt": updated.ModifiedAt.Format(time.RFC3339),
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// DeletePostMortemAnalysis handles DELETE /activities/post-mortem/{analysisId}.
func (h *PostMortemHandler) DeletePostMortemAnalysis(w http.ResponseWriter, r *http.Request, analysisID string) {
	userID := r.Header.Get("X-User-Id")
	correlationID := r.Header.Get("X-Correlation-Id")

	err := h.service.DeleteAnalysis(r.Context(), userID, analysisID)
	if err != nil {
		if errors.Is(err, postmortem.ErrNotFound) {
			writeError(w, 404, "rr:0x00000404", "Not Found", "Post-mortem analysis not found", correlationID)
			return
		}
		if errors.Is(err, postmortem.ErrCannotDeleteCompleted) {
			writeError(w, 422, ErrCodeDeleteCompleted, "Cannot Delete Completed", "Completed post-mortems cannot be deleted", correlationID)
			return
		}
		writeError(w, 500, "rr:0x00050FFF", "Internal Server Error", err.Error(), correlationID)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// CompletePostMortemAnalysis handles POST /activities/post-mortem/{analysisId}/complete.
func (h *PostMortemHandler) CompletePostMortemAnalysis(w http.ResponseWriter, r *http.Request, analysisID string) {
	userID := r.Header.Get("X-User-Id")
	correlationID := r.Header.Get("X-Correlation-Id")

	completed, err := h.service.CompleteAnalysis(r.Context(), userID, analysisID)
	if err != nil {
		if errors.Is(err, postmortem.ErrNotFound) {
			writeError(w, 404, "rr:0x00000404", "Not Found", "Post-mortem analysis not found", correlationID)
			return
		}
		if errors.Is(err, postmortem.ErrIncompletePostMortem) {
			writeError(w, 422, ErrCodeIncomplete, "Incomplete Post-Mortem", err.Error(), correlationID)
			return
		}
		writeError(w, 500, "rr:0x00050FFF", "Internal Server Error", err.Error(), correlationID)
		return
	}

	resp := postMortemResponseJSON{
		Data: completed,
		Meta: map[string]interface{}{
			"createdAt":  completed.CreatedAt.Format(time.RFC3339),
			"modifiedAt": completed.ModifiedAt.Format(time.RFC3339),
			"message":    postmortem.ClosingMessage,
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// SharePostMortemAnalysis handles POST /activities/post-mortem/{analysisId}/share.
func (h *PostMortemHandler) SharePostMortemAnalysis(w http.ResponseWriter, r *http.Request, analysisID string) {
	userID := r.Header.Get("X-User-Id")
	correlationID := r.Header.Get("X-Correlation-Id")

	var req sharePostMortemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, 400, "rr:0x00000001", "Bad Request", "Invalid JSON body", correlationID)
		return
	}

	var shares []postmortem.SharedWithEntry
	now := time.Now().UTC()
	for _, s := range req.Shares {
		shares = append(shares, postmortem.SharedWithEntry{
			ContactID: s.ContactID,
			ShareType: s.ShareType,
			SharedAt:  now,
		})
	}

	updated, err := h.service.ShareAnalysis(r.Context(), userID, analysisID, shares)
	if err != nil {
		if errors.Is(err, postmortem.ErrNotFound) {
			writeError(w, 404, "rr:0x00000404", "Not Found", "Post-mortem analysis not found", correlationID)
			return
		}
		if errors.Is(err, postmortem.ErrCannotShareDraft) {
			writeError(w, 422, ErrCodeShareDraft, "Cannot Share Draft", "Only completed post-mortems can be shared", correlationID)
			return
		}
		h.writeValidationError(w, err, correlationID)
		return
	}

	resp := map[string]interface{}{
		"data": map[string]interface{}{
			"analysisId": updated.AnalysisID,
			"sharing":    updated.Sharing,
		},
		"meta": map[string]interface{}{
			"modifiedAt": updated.ModifiedAt.Format(time.RFC3339),
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

// --- Helper Methods ---

func (h *PostMortemHandler) writeValidationError(w http.ResponseWriter, err error, correlationID string) {
	code := "rr:0x00050000"
	title := "Validation Error"
	status := 422

	switch {
	case errors.Is(err, postmortem.ErrInvalidEventType):
		code = ErrCodeInvalidEventType
		title = "Invalid Event Type"
	case errors.Is(err, postmortem.ErrNearMissCannotLink):
		code = ErrCodeNearMissLink
		title = "Near-Miss Cannot Link Relapse"
	case errors.Is(err, postmortem.ErrInvalidTriggerCategory):
		code = ErrCodeInvalidTrigger
		title = "Invalid Trigger Category"
	case errors.Is(err, postmortem.ErrInvalidFASTERStage):
		code = ErrCodeInvalidFASTER
		title = "Invalid FASTER Stage"
	case errors.Is(err, postmortem.ErrInvalidActionCategory):
		code = ErrCodeInvalidAction
		title = "Invalid Action Category"
	case errors.Is(err, postmortem.ErrActionItemLimit):
		code = ErrCodeActionItemLimit
		title = "Action Item Limit"
	case errors.Is(err, postmortem.ErrCompletedImmutable):
		code = ErrCodeCompletedImmut
		title = "Completed Post-Mortem Immutable"
	case errors.Is(err, postmortem.ErrIncompletePostMortem):
		code = ErrCodeIncomplete
		title = "Incomplete Post-Mortem"
	case errors.Is(err, postmortem.ErrNotFound):
		code = "rr:0x00000404"
		title = "Not Found"
		status = 404
	}

	writeError(w, status, code, title, err.Error(), correlationID)
}

func writeError(w http.ResponseWriter, status int, code, title, detail, correlationID string) {
	resp := errorResponseJSON{
		Errors: []errorObjectJSON{
			{
				ID:            uuid.New().String(),
				Code:          code,
				Status:        status,
				Title:         title,
				Detail:        detail,
				CorrelationID: correlationID,
			},
		},
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(resp)
}

func domainToSummaryJSON(a *postmortem.PostMortemAnalysis) postMortemSummaryJSON {
	summary := postMortemSummaryJSON{
		AnalysisID:        a.AnalysisID,
		Timestamp:         a.Timestamp.Format(time.RFC3339),
		Status:            a.Status,
		EventType:         a.EventType,
		RelapseID:         a.RelapseID,
		AddictionID:       a.AddictionID,
		SectionsCompleted: postmortem.CompletedSections(&a.Sections),
		SectionsRemaining: postmortem.RemainingSections(&a.Sections),
		TriggerSummary:    a.TriggerSummary,
		ActionItemCount:   len(a.ActionPlan),
		Links: map[string]string{
			"self":     fmt.Sprintf("/v1/activities/post-mortem/%s", a.AnalysisID),
			"complete": fmt.Sprintf("/v1/activities/post-mortem/%s/complete", a.AnalysisID),
		},
	}
	if a.CompletedAt != nil {
		ts := a.CompletedAt.Format(time.RFC3339)
		summary.CompletedAt = &ts
	}
	if summary.SectionsCompleted == nil {
		summary.SectionsCompleted = []string{}
	}
	if summary.SectionsRemaining == nil {
		summary.SectionsRemaining = []string{}
	}
	return summary
}

func sectionsJSONToDomain(s *sectionsJSON) *postmortem.Sections {
	sections := &postmortem.Sections{}
	if s.DayBefore != nil {
		sections.DayBefore = &postmortem.DayBeforeSection{
			Text: s.DayBefore.Text, MoodRating: s.DayBefore.MoodRating,
			RecoveryPracticesKept: s.DayBefore.RecoveryPracticesKept,
			UnresolvedConflicts: s.DayBefore.UnresolvedConflicts,
		}
	}
	if s.Morning != nil {
		sections.Morning = &postmortem.MorningSection{
			Text: s.Morning.Text, MoodRating: s.Morning.MoodRating,
			MorningCommitmentCompleted: s.Morning.MorningCommitmentCompleted,
			AffirmationViewed: s.Morning.AffirmationViewed,
		}
		if s.Morning.AutoPopulated != nil {
			sections.Morning.AutoPopulated = &postmortem.AutoPopulatedData{
				MorningCommitmentCompleted: s.Morning.AutoPopulated.MorningCommitmentCompleted,
				MoodRating: s.Morning.AutoPopulated.MoodRating,
				AffirmationViewed: s.Morning.AutoPopulated.AffirmationViewed,
			}
		}
	}
	if s.ThroughoutTheDay != nil {
		td := &postmortem.ThroughoutTheDaySection{}
		for _, tb := range s.ThroughoutTheDay.TimeBlocks {
			td.TimeBlocks = append(td.TimeBlocks, postmortem.TimeBlock{
				Period: tb.Period, StartTime: tb.StartTime, EndTime: tb.EndTime,
				Activity: tb.Activity, Location: tb.Location, Company: tb.Company,
				Thoughts: tb.Thoughts, Feelings: tb.Feelings, WarningSigns: tb.WarningSigns,
			})
		}
		for _, fe := range s.ThroughoutTheDay.FreeFormEntries {
			td.FreeFormEntries = append(td.FreeFormEntries, postmortem.FreeFormEntry{Time: fe.Time, Text: fe.Text})
		}
		sections.ThroughoutTheDay = td
	}
	if s.BuildUp != nil {
		bu := &postmortem.BuildUpSection{
			FirstNoticed: s.BuildUp.FirstNoticed,
			ResponseToWarnings: s.BuildUp.ResponseToWarnings,
		}
		for _, t := range s.BuildUp.Triggers {
			bu.Triggers = append(bu.Triggers, postmortem.TriggerDetail{
				Category: t.Category, Surface: t.Surface,
				Underlying: t.Underlying, CoreWound: t.CoreWound,
			})
		}
		for _, mho := range s.BuildUp.MissedHelpOpportunities {
			bu.MissedHelpOpportunities = append(bu.MissedHelpOpportunities, postmortem.MissedHelpOpportunity{
				Description: mho.Description, Reason: mho.Reason,
			})
		}
		for _, dp := range s.BuildUp.DecisionPoints {
			bu.DecisionPoints = append(bu.DecisionPoints, postmortem.DecisionPoint{
				TimeOfDay: dp.TimeOfDay, Description: dp.Description,
				CouldHaveDone: dp.CouldHaveDone, InsteadDid: dp.InsteadDid,
			})
		}
		sections.BuildUp = bu
	}
	if s.ActingOut != nil {
		sections.ActingOut = &postmortem.ActingOutSection{
			Description: s.ActingOut.Description, AddictionID: s.ActingOut.AddictionID,
			DurationMinutes: s.ActingOut.DurationMinutes, LinkedRelapseID: s.ActingOut.LinkedRelapseID,
		}
	}
	if s.ImmediatelyAfter != nil {
		sections.ImmediatelyAfter = &postmortem.ImmediatelyAfterSection{
			Feelings: s.ImmediatelyAfter.Feelings,
			FeelingsWheelSelections: s.ImmediatelyAfter.FeelingsWheelSelections,
			WhatDidNext: s.ImmediatelyAfter.WhatDidNext,
			ReachedOut: s.ImmediatelyAfter.ReachedOut,
			ReachedOutTo: s.ImmediatelyAfter.ReachedOutTo,
			WishDoneDifferently: s.ImmediatelyAfter.WishDoneDifferently,
		}
	}
	return sections
}

func nilIfEmpty(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}
