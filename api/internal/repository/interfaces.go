// internal/repository/interfaces.go
package repository

import (
	"context"
	"time"
)

// UserRepository defines the interface for user data operations.
type UserRepository interface {
	// GetUser retrieves a user profile by user ID.
	GetUser(ctx context.Context, userID string) (*User, error)

	// GetUserByEmail retrieves a user profile by email address (GSI1 query).
	GetUserByEmail(ctx context.Context, email string) (*User, error)

	// CreateUser creates a new user profile.
	CreateUser(ctx context.Context, user *User) error

	// UpdateUser updates an existing user profile.
	UpdateUser(ctx context.Context, user *User) error

	// DeleteUser deletes a user profile.
	DeleteUser(ctx context.Context, userID string) error

	// GetUserSettings retrieves user settings.
	GetUserSettings(ctx context.Context, userID string) (*UserSettings, error)

	// UpdateUserSettings updates user settings.
	UpdateUserSettings(ctx context.Context, settings *UserSettings) error

	// ListAddictions lists all addictions for a user.
	ListAddictions(ctx context.Context, userID string) ([]Addiction, error)

	// GetAddiction retrieves a specific addiction by ID.
	GetAddiction(ctx context.Context, userID, addictionID string) (*Addiction, error)

	// CreateAddiction creates a new addiction record.
	CreateAddiction(ctx context.Context, addiction *Addiction) error

	// UpdateAddiction updates an existing addiction record.
	UpdateAddiction(ctx context.Context, addiction *Addiction) error
}

// TrackingRepository defines the interface for sobriety tracking operations.
type TrackingRepository interface {
	// GetStreak retrieves the current streak for an addiction.
	GetStreak(ctx context.Context, userID, addictionID string) (*Streak, error)

	// UpdateStreak updates the streak record.
	UpdateStreak(ctx context.Context, streak *Streak) error

	// RecordRelapse records a relapse event and returns the relapse record.
	RecordRelapse(ctx context.Context, userID string, relapse *Relapse) error

	// GetMilestones retrieves all milestones for a user.
	GetMilestones(ctx context.Context, userID string) ([]Milestone, error)

	// GetMilestonesForAddiction retrieves milestones for a specific addiction.
	GetMilestonesForAddiction(ctx context.Context, userID, addictionID string) ([]Milestone, error)

	// CreateMilestone creates a new milestone record.
	CreateMilestone(ctx context.Context, userID string, milestone *Milestone) error

	// GetRelapseHistory retrieves relapse history for a user.
	GetRelapseHistory(ctx context.Context, userID string, limit int) ([]Relapse, error)
}

// ActivityRepository defines the interface for activity logging operations.
type ActivityRepository interface {
	// CreateCheckIn creates a new check-in entry.
	CreateCheckIn(ctx context.Context, userID string, checkIn *CheckIn) error

	// GetRecentCheckIns retrieves recent check-ins for a user.
	GetRecentCheckIns(ctx context.Context, userID string, limit int) ([]CheckIn, error)

	// CreateUrge creates a new urge log entry.
	CreateUrge(ctx context.Context, userID string, urge *Urge) error

	// GetRecentUrges retrieves recent urges for a user.
	GetRecentUrges(ctx context.Context, userID string, limit int) ([]Urge, error)

	// CreateJournal creates a new journal entry.
	CreateJournal(ctx context.Context, userID string, journal *Journal) error

	// GetRecentJournals retrieves recent journal entries for a user.
	GetRecentJournals(ctx context.Context, userID string, limit int) ([]Journal, error)

	// CreateMeeting creates a new meeting log entry.
	CreateMeeting(ctx context.Context, userID string, meeting *Meeting) error

	// GetRecentMeetings retrieves recent meeting logs for a user.
	GetRecentMeetings(ctx context.Context, userID string, limit int) ([]Meeting, error)

	// CreatePrayer creates a new prayer log entry.
	CreatePrayer(ctx context.Context, userID string, prayer *Prayer) error

	// CreateExercise creates a new exercise log entry.
	CreateExercise(ctx context.Context, userID string, exercise *Exercise) error

	// GetActivitiesByDate retrieves all activities for a specific date (calendar view).
	GetActivitiesByDate(ctx context.Context, userID, date string) ([]Activity, error)

	// GetActivitiesByDateRange retrieves all activities within a date range (calendar month view).
	GetActivitiesByDateRange(ctx context.Context, userID, startDate, endDate string) ([]Activity, error)
}

// ContentRepository defines the interface for content operations.
type ContentRepository interface {
	// GetAffirmationPack retrieves an affirmation pack by ID.
	GetAffirmationPack(ctx context.Context, packID string) (*AffirmationPack, error)

	// GetAffirmationPacks retrieves all affirmation packs (pack metadata only).
	GetAffirmationPacks(ctx context.Context) ([]AffirmationPack, error)

	// GetAffirmationsInPack retrieves all affirmations within a pack.
	GetAffirmationsInPack(ctx context.Context, packID string) ([]Affirmation, error)

	// GetDevotional retrieves a devotional by day number.
	GetDevotional(ctx context.Context, day int) (*DevotionalDay, error)
}

// SupportRepository defines the interface for support network operations.
type SupportRepository interface {
	// ListContacts lists all support contacts for a user.
	ListContacts(ctx context.Context, userID string) ([]SupportContact, error)

	// GetContact retrieves a specific contact by ID.
	GetContact(ctx context.Context, userID, contactID string) (*SupportContact, error)

	// CreateContact creates a new support contact.
	CreateContact(ctx context.Context, contact *SupportContact) error

	// UpdateContact updates an existing support contact.
	UpdateContact(ctx context.Context, contact *SupportContact) error

	// ListPermissions lists all permissions for a user.
	ListPermissions(ctx context.Context, userID string) ([]Permission, error)

	// GetPermissionsForContact lists permissions for a specific contact.
	GetPermissionsForContact(ctx context.Context, userID, contactID string) ([]Permission, error)

	// CheckPermission checks if a specific permission exists.
	CheckPermission(ctx context.Context, userID, contactID, dataCategory string) (*Permission, error)

	// GrantPermission grants a permission to a contact.
	GrantPermission(ctx context.Context, permission *Permission) error

	// RevokePermission revokes a permission.
	RevokePermission(ctx context.Context, userID, contactID, dataCategory string) error
}

// CommitmentRepository defines the interface for commitment operations.
type CommitmentRepository interface {
	// ListCommitments lists all commitments for a user.
	ListCommitments(ctx context.Context, userID string) ([]Commitment, error)

	// GetCommitment retrieves a specific commitment by ID.
	GetCommitment(ctx context.Context, userID, commitmentID string) (*Commitment, error)

	// CreateCommitment creates a new commitment.
	CreateCommitment(ctx context.Context, commitment *Commitment) error

	// UpdateCommitment updates an existing commitment.
	UpdateCommitment(ctx context.Context, commitment *Commitment) error
}

// GoalRepository defines the interface for goal operations.
type GoalRepository interface {
	// ListGoals lists all goals for a user.
	ListGoals(ctx context.Context, userID string) ([]Goal, error)

	// GetGoal retrieves a specific goal by ID.
	GetGoal(ctx context.Context, userID, goalID string) (*Goal, error)

	// CreateGoal creates a new goal.
	CreateGoal(ctx context.Context, goal *Goal) error

	// UpdateGoal updates an existing goal.
	UpdateGoal(ctx context.Context, goal *Goal) error
}

// SessionRepository defines the interface for session operations.
type SessionRepository interface {
	// CreateSession creates a new session.
	CreateSession(ctx context.Context, session *Session) error

	// GetSession retrieves a session by session ID (GSI1 query).
	GetSessionByID(ctx context.Context, sessionID string) (*Session, error)

	// ListUserSessions lists all active sessions for a user.
	ListUserSessions(ctx context.Context, userID string) ([]Session, error)

	// DeleteSession deletes a session.
	DeleteSession(ctx context.Context, userID, sessionID string) error
}

// AffirmationsRepository defines the interface for affirmation operations.
type AffirmationsRepository interface {
	// --- Library affirmations ---
	GetLibraryAffirmations(ctx context.Context, level int, category, track string, active bool, limit int) ([]AffirmationLibraryDoc, error)
	GetLibraryAffirmationByID(ctx context.Context, affirmationID string) (*AffirmationLibraryDoc, error)
	SearchLibraryAffirmations(ctx context.Context, keyword string, active bool, limit int) ([]AffirmationLibraryDoc, error)

	// --- Sessions ---
	CreateSession(ctx context.Context, session *AffirmationSessionDoc) error
	GetSession(ctx context.Context, sessionID string) (*AffirmationSessionDoc, error)
	ListSessions(ctx context.Context, userID string, limit int) ([]AffirmationSessionDoc, error)
	ListSessionsByTypeAndDateRange(ctx context.Context, userID, sessionType string, startDate, endDate time.Time, limit int) ([]AffirmationSessionDoc, error)
	CountSessionsInDateRange(ctx context.Context, userID string, startDate, endDate time.Time) (int64, error)
	GetRecentSessionAffirmationIDs(ctx context.Context, userID string, days int) ([]string, error)
	GetEveningSessionsByDateRange(ctx context.Context, userID string, startDate, endDate time.Time) ([]AffirmationSessionDoc, error)
	GetMorningSessionForDate(ctx context.Context, userID, date string) (*AffirmationSessionDoc, error)

	// --- Settings ---
	GetSettings(ctx context.Context, userID string) (*AffirmationSettingsDoc, error)
	UpsertSettings(ctx context.Context, settings *AffirmationSettingsDoc) error

	// --- Progress ---
	GetProgress(ctx context.Context, userID string) (*AffirmationProgressDoc, error)
	UpsertProgress(ctx context.Context, progress *AffirmationProgressDoc) error
	IncrementSessionCount(ctx context.Context, userID string, sessionType string) error
	IncrementAffirmationCount(ctx context.Context, userID string, count int) error
	RecordMilestone(ctx context.Context, userID string, milestoneType string, achievedAt time.Time) error
	UpdateLastServedAffirmations(ctx context.Context, userID string, affirmationIDs []string, timestamp time.Time) error
	RecordLevelChange(ctx context.Context, userID string, newLevel int, timestamp time.Time) error

	// --- Favorites ---
	AddFavorite(ctx context.Context, userID, affirmationID string, tenantID string) error
	RemoveFavorite(ctx context.Context, userID, affirmationID string) error
	ListFavorites(ctx context.Context, userID string) ([]AffirmationFavoriteDoc, error)
	IsFavorite(ctx context.Context, userID, affirmationID string) (bool, error)

	// --- Hidden ---
	HideAffirmation(ctx context.Context, userID, affirmationID string, tenantID string, sessionHideCount int) error
	UnhideAffirmation(ctx context.Context, userID, affirmationID string) error
	ListHidden(ctx context.Context, userID string) ([]AffirmationHiddenDoc, error)
	IsHidden(ctx context.Context, userID, affirmationID string) (bool, error)
	CountHiddenInSession(ctx context.Context, userID string, sessionStartTime time.Time) (int64, error)

	// --- Custom affirmations ---
	CreateCustom(ctx context.Context, custom *AffirmationCustomDoc) error
	GetCustom(ctx context.Context, customID string) (*AffirmationCustomDoc, error)
	ListCustom(ctx context.Context, userID string) ([]AffirmationCustomDoc, error)
	UpdateCustom(ctx context.Context, custom *AffirmationCustomDoc) error
	DeleteCustom(ctx context.Context, customID string) error
	ToggleRotation(ctx context.Context, customID string, includeInRotation bool) error

	// --- Audio recordings ---
	SaveAudioMetadata(ctx context.Context, audio *AffirmationAudioDoc) error
	GetAudioMetadata(ctx context.Context, userID, affirmationID string) (*AffirmationAudioDoc, error)
	DeleteAudioMetadata(ctx context.Context, recordingID string) error
	ListAudioByUser(ctx context.Context, userID string) ([]AffirmationAudioDoc, error)

	// --- Calendar dual-write ---
	WriteCalendarActivity(ctx context.Context, activity *Activity) error
}

// ThreeCirclesRepository defines the interface for Three Circles operations.
type ThreeCirclesRepository interface {
	// --- Circle Set CRUD ---
	CreateCircleSet(ctx context.Context, set *CircleSetDoc) error
	GetCircleSetByID(ctx context.Context, setID string) (*CircleSetDoc, error)
	ListCircleSetsByUser(ctx context.Context, userID string, status *string) ([]CircleSetDoc, error)
	ListCircleSetsByRecoveryArea(ctx context.Context, userID string, recoveryArea string) ([]CircleSetDoc, error)
	ListCircleSetsDueForReview(ctx context.Context, userID string, nowISO string) ([]CircleSetDoc, error)
	UpdateCircleSet(ctx context.Context, set *CircleSetDoc) error
	DeleteCircleSet(ctx context.Context, setID string) error

	// --- Version History ---
	CreateCircleSetVersion(ctx context.Context, version *CircleSetVersionDoc) error
	ListVersionsForSet(ctx context.Context, setID string) ([]CircleSetVersionDoc, error)
	GetCircleSetVersion(ctx context.Context, setID string, versionNumber int) (*CircleSetVersionDoc, error)
	GetLatestCircleSetVersion(ctx context.Context, setID string) (*CircleSetVersionDoc, error)

	// --- Templates ---
	GetCircleTemplateByID(ctx context.Context, templateID string) (*CircleTemplateDoc, error)
	ListCircleTemplates(ctx context.Context, recoveryArea string, circle *string, active bool) ([]CircleTemplateDoc, error)
	ListCircleTemplatesByFramework(ctx context.Context, recoveryArea string, frameworkVariant *string) ([]CircleTemplateDoc, error)

	// --- Starter Packs ---
	GetStarterPackByID(ctx context.Context, packID string) (*CircleStarterPackDoc, error)
	ListStarterPacks(ctx context.Context, recoveryArea string, variant *string, active bool) ([]CircleStarterPackDoc, error)

	// --- Onboarding Flows ---
	CreateOnboardingFlow(ctx context.Context, flow *CircleOnboardingDoc) error
	GetOnboardingFlowByID(ctx context.Context, flowID string) (*CircleOnboardingDoc, error)
	GetActiveOnboardingFlow(ctx context.Context, userID string) (*CircleOnboardingDoc, error)
	GetActiveOnboardingFlowForRecoveryArea(ctx context.Context, userID string, recoveryArea string) (*CircleOnboardingDoc, error)
	UpdateOnboardingFlow(ctx context.Context, flow *CircleOnboardingDoc) error
	DeleteOnboardingFlow(ctx context.Context, flowID string) error

	// --- Share Links ---
	CreateCircleShare(ctx context.Context, share *CircleShareDoc) error
	GetCircleShareByCode(ctx context.Context, shareCode string) (*CircleShareDoc, error)
	ListActiveSharesForSet(ctx context.Context, setID string) ([]CircleShareDoc, error)
	UpdateCircleShare(ctx context.Context, share *CircleShareDoc) error
	DeleteCircleShare(ctx context.Context, shareID string) error

	// --- Sponsor Comments ---
	CreateSponsorComment(ctx context.Context, comment *CircleSponsorCommentDoc) error
	ListCommentsByShareCode(ctx context.Context, shareCode string) ([]CircleSponsorCommentDoc, error)
	GetUnreadCommentsForSet(ctx context.Context, userID string, setID string) ([]CircleSponsorCommentDoc, error)
	CountUnreadCommentsForSet(ctx context.Context, userID string, setID string) (int64, error)
	MarkCommentsAsRead(ctx context.Context, userID string, setID string) error

	// --- Pattern Timeline ---
	CreateTimelineEntry(ctx context.Context, entry *CirclePatternTimelineDoc) error
	GetTimelineForPeriod(ctx context.Context, userID string, setID string, startDate string, endDate string) ([]CirclePatternTimelineDoc, error)
	CountDaysByCircleType(ctx context.Context, userID string, setID string, startDate string, endDate string) (map[string]int, error)
	GetConsecutiveOuterDays(ctx context.Context, userID string, setID string) (int, error)
	CountMiddleCircleDaysInWindow(ctx context.Context, userID string, setID string, startDate string) (int64, error)

	// --- Insights ---
	CreateInsight(ctx context.Context, insight *CircleInsightDoc) error
	GetActiveInsightsForSet(ctx context.Context, userID string, setID string) ([]CircleInsightDoc, error)
	GetInsightsByType(ctx context.Context, userID string, insightType string) ([]CircleInsightDoc, error)
	UpdateInsight(ctx context.Context, insight *CircleInsightDoc) error

	// --- Drift Alerts ---
	CreateDriftAlert(ctx context.Context, alert *CircleDriftAlertDoc) error
	GetActiveDriftAlerts(ctx context.Context, userID string, setID string) ([]CircleDriftAlertDoc, error)
	GetRecentDriftEpisodes(ctx context.Context, userID string, limit int) ([]CircleDriftAlertDoc, error)
	UpdateDriftAlert(ctx context.Context, alert *CircleDriftAlertDoc) error

	// --- Quarterly Reviews ---
	CreateCircleReview(ctx context.Context, review *CircleReviewDoc) error
	GetCircleReviewByID(ctx context.Context, reviewID string) (*CircleReviewDoc, error)
	ListReviewsForSet(ctx context.Context, userID string, setID string) ([]CircleReviewDoc, error)
	GetIncompleteReviewForSet(ctx context.Context, userID string, setID string) (*CircleReviewDoc, error)
	UpdateCircleReview(ctx context.Context, review *CircleReviewDoc) error
	DeleteCircleReview(ctx context.Context, reviewID string) error

	// --- Calendar dual-write ---
	WriteCalendarActivity(ctx context.Context, activity *Activity) error
}
