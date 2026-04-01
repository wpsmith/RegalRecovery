// internal/repository/interfaces.go
package repository

import "context"

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

// FlagRepository defines the interface for feature flag operations.
type FlagRepository interface {
	// GetFlag retrieves a single feature flag by key.
	GetFlag(ctx context.Context, flagKey string) (*Flag, error)

	// GetAllFlags retrieves all feature flags.
	GetAllFlags(ctx context.Context) ([]Flag, error)

	// SetFlag creates or updates a feature flag.
	SetFlag(ctx context.Context, flag *Flag) error
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
