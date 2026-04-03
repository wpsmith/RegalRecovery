// internal/repository/models.go
package repository

import (
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
)

// BaseDocument contains common attributes present on all MongoDB documents.
type BaseDocument struct {
	ID         bson.ObjectID `bson:"_id,omitempty"`
	CreatedAt  time.Time     `bson:"createdAt"`
	ModifiedAt time.Time     `bson:"modifiedAt"`
	TenantID   string        `bson:"tenantId"`
}

// User represents a user profile.
type User struct {
	BaseDocument

	UserID                string     `bson:"userId"`
	Email                 string     `bson:"email"`
	DisplayName           string     `bson:"displayName"`
	Role                  string     `bson:"role"`
	PrimaryAddictionID    string     `bson:"primaryAddictionId"`
	PreferredLanguage     string     `bson:"preferredLanguage"`
	PreferredBibleVersion string     `bson:"preferredBibleVersion"`
	BirthYear             int        `bson:"birthYear,omitempty"`
	Gender                string     `bson:"gender,omitempty"`
	MaritalStatus         string     `bson:"maritalStatus,omitempty"`
	TimeZone              string     `bson:"timeZone"`
	EmailVerified         bool       `bson:"emailVerified"`
	BiometricEnabled      bool       `bson:"biometricEnabled"`
	RegionID              string     `bson:"regionId"`
	SubscriptionTier      string     `bson:"subscriptionTier"`
	SubscriptionExpiresAt *time.Time `bson:"subscriptionExpiresAt,omitempty"`
}

// UserSettings represents user preferences and configuration.
type UserSettings struct {
	BaseDocument

	UserID                  string                 `bson:"userId"`
	NotificationPreferences map[string]interface{} `bson:"notificationPreferences"`
	PrivacySettings         map[string]interface{} `bson:"privacySettings"`
	DisplaySettings         map[string]interface{} `bson:"displaySettings"`
	SecuritySettings        map[string]interface{} `bson:"securitySettings"`
}

// Addiction represents a tracked addiction with sobriety start date.
type Addiction struct {
	BaseDocument

	UserID            string `bson:"userId"`
	AddictionID       string `bson:"addictionId"`
	Type              string `bson:"type"`
	SobrietyStartDate string `bson:"sobrietyStartDate"`
	IsPrimary         bool   `bson:"isPrimary"`
}

// Streak represents current and longest sobriety streak per addiction.
type Streak struct {
	BaseDocument

	UserID            string     `bson:"userId"`
	AddictionID       string     `bson:"addictionId"`
	CurrentStreakDays int        `bson:"currentStreakDays"`
	LongestStreakDays int        `bson:"longestStreakDays"`
	SobrietyStartDate string    `bson:"sobrietyStartDate"`
	LastRelapseDate   *time.Time `bson:"lastRelapseDate,omitempty"`
	TotalSoberDays    int        `bson:"totalSoberDays"`
}

// Milestone represents a sobriety milestone achievement.
type Milestone struct {
	BaseDocument

	UserID       string    `bson:"userId"`
	MilestoneID  string    `bson:"milestoneId"`
	AddictionID  string    `bson:"addictionId"`
	Type         string    `bson:"type"`
	Days         int       `bson:"days"`
	AchievedAt   time.Time `bson:"achievedAt"`
	Celebrated   bool      `bson:"celebrated"`
	CoinImageURL string    `bson:"coinImageUrl,omitempty"`
}

// Relapse represents a relapse event.
type Relapse struct {
	BaseDocument

	UserID              string    `bson:"userId"`
	RelapseID           string    `bson:"relapseId"`
	AddictionID         string    `bson:"addictionId"`
	Timestamp           time.Time `bson:"timestamp"`
	PreviousStreakDays  int       `bson:"previousStreakDays"`
	Notes               string    `bson:"notes,omitempty"`
	PostMortemCompleted bool      `bson:"postMortemCompleted"`
}

// CheckIn represents a daily/evening check-in entry.
type CheckIn struct {
	BaseDocument

	UserID    string                 `bson:"userId"`
	CheckInID string                 `bson:"checkInId"`
	Type      string                 `bson:"type"`
	Responses map[string]interface{} `bson:"responses"`
	Score     int                    `bson:"score"`
	ColorCode string                 `bson:"colorCode"`
}

// Urge represents an urge log entry.
type Urge struct {
	BaseDocument

	UserID             string   `bson:"userId"`
	UrgeID             string   `bson:"urgeId"`
	AddictionID        string   `bson:"addictionId"`
	Intensity          int      `bson:"intensity"`
	Triggers           []string `bson:"triggers"`
	Notes              string   `bson:"notes,omitempty"`
	SobrietyMaintained bool     `bson:"sobrietyMaintained"`
	DurationMinutes    int      `bson:"durationMinutes,omitempty"`
}

// Journal represents a journal entry.
type Journal struct {
	BaseDocument

	UserID            string     `bson:"userId"`
	EntryID           string     `bson:"entryId"`
	Mode              string     `bson:"mode"`
	Content           string     `bson:"content"`
	EmotionalTags     []string   `bson:"emotionalTags,omitempty"`
	Prompt            string     `bson:"prompt,omitempty"`
	IsEphemeral       bool       `bson:"isEphemeral"`
	EphemeralDeleteAt *time.Time `bson:"ephemeralDeleteAt,omitempty"`
	ExpiresAt         *time.Time `bson:"expiresAt,omitempty"`
}

// Meeting represents a meeting attendance log.
type Meeting struct {
	BaseDocument

	UserID          string `bson:"userId"`
	MeetingID       string `bson:"meetingId"`
	MeetingType     string `bson:"meetingType"`
	Name            string `bson:"name"`
	Location        string `bson:"location,omitempty"`
	Notes           string `bson:"notes,omitempty"`
	DurationMinutes int    `bson:"durationMinutes"`
}

// Prayer represents a prayer log entry.
type Prayer struct {
	BaseDocument

	UserID          string     `bson:"userId"`
	PrayerID        string     `bson:"prayerId"`
	PrayerType      string     `bson:"prayerType"`
	Content         string     `bson:"content"`
	DurationMinutes int        `bson:"durationMinutes"`
	IsEphemeral     bool       `bson:"isEphemeral"`
	ExpiresAt       *time.Time `bson:"expiresAt,omitempty"`
}

// Exercise represents an exercise log entry.
type Exercise struct {
	BaseDocument

	UserID          string `bson:"userId"`
	ExerciseID      string `bson:"exerciseId"`
	Type            string `bson:"type"`
	DurationMinutes int    `bson:"durationMinutes"`
	Calories        int    `bson:"calories,omitempty"`
	Source          string `bson:"source"`
}

// Activity represents a calendar activity entry.
type Activity struct {
	BaseDocument

	UserID       string                 `bson:"userId"`
	ActivityType string                 `bson:"activityType"`
	Summary      map[string]interface{} `bson:"summary"`
	SourceKey    string                 `bson:"sourceKey"`
	Date         string                 `bson:"date"`
	Timestamp    time.Time              `bson:"timestamp"`
}

// SupportContact represents a support network contact.
type SupportContact struct {
	BaseDocument

	UserID        string     `bson:"userId"`
	ContactID     string     `bson:"contactId"`
	ContactUserID string     `bson:"contactUserId"`
	Role          string     `bson:"role"`
	DisplayName   string     `bson:"displayName"`
	Email         string     `bson:"email,omitempty"`
	Status        string     `bson:"status"`
	InvitedAt     time.Time  `bson:"invitedAt"`
	AcceptedAt    *time.Time `bson:"acceptedAt,omitempty"`
}

// Permission represents a granular data permission for a contact.
type Permission struct {
	BaseDocument

	UserID        string    `bson:"userId"`
	PermissionID  string    `bson:"permissionId"`
	ContactID     string    `bson:"contactId"`
	ContactUserID string    `bson:"contactUserId"`
	DataCategory  string    `bson:"dataCategory"`
	AccessLevel   string    `bson:"accessLevel"`
	GrantedAt     time.Time `bson:"grantedAt"`
}

// Flag represents a feature flag.
type Flag struct {
	BaseDocument

	FlagKey           string    `bson:"flagKey"`
	Enabled           bool      `bson:"enabled"`
	RolloutPercentage int       `bson:"rolloutPercentage"`
	Tiers             []string  `bson:"tiers,omitempty"`
	Tenants           []string  `bson:"tenants,omitempty"`
	Platforms         []string  `bson:"platforms,omitempty"`
	MinAppVersion     string    `bson:"minAppVersion,omitempty"`
	Description       string    `bson:"description"`
	UpdatedAt         time.Time `bson:"updatedAt"`
	UpdatedBy         string    `bson:"updatedBy"`
}

// AffirmationPack represents metadata for an affirmation pack.
type AffirmationPack struct {
	BaseDocument

	PackID           string `bson:"packId"`
	Name             string `bson:"name"`
	Description      string `bson:"description"`
	Tier             string `bson:"tier"`
	Price            int    `bson:"price"`
	AffirmationCount int    `bson:"affirmationCount"`
	Category         string `bson:"category"`
}

// Affirmation represents an affirmation within a pack.
type Affirmation struct {
	BaseDocument

	AffirmationID      string `bson:"affirmationId"`
	PackID             string `bson:"packId"`
	Statement          string `bson:"statement"`
	ScriptureReference string `bson:"scriptureReference,omitempty"`
	Category           string `bson:"category"`
	Language           string `bson:"language"`
}

// DevotionalDay represents a single day's devotional content.
type DevotionalDay struct {
	BaseDocument

	Day           int    `bson:"day"`
	Title         string `bson:"title"`
	Scripture     string `bson:"scripture"`
	ScriptureText string `bson:"scriptureText"`
	Reflection    string `bson:"reflection"`
}

// Prompt represents a journal prompt for recovery reflection.
type Prompt struct {
	BaseDocument

	PromptID string   `bson:"promptId"`
	Text     string   `bson:"text"`
	Category string   `bson:"category"` // daily, sobriety, emotional, relationships, spiritual, shame, triggers, amends, gratitude, deep
	Tags     []string `bson:"tags"`     // FASTER, 3 Circles, 12-Step, FANOS/FITNAP, PCI, Arousal Template
	Order    int      `bson:"order"`
}

// Commitment represents a user commitment (e.g., "Call sponsor daily").
type Commitment struct {
	BaseDocument

	UserID            string     `bson:"userId"`
	CommitmentID      string     `bson:"commitmentId"`
	Title             string     `bson:"title"`
	Frequency         string     `bson:"frequency"`
	Category          string     `bson:"category"`
	IsActive          bool       `bson:"isActive"`
	CurrentStreakDays int        `bson:"currentStreakDays"`
	LastCompletedAt   *time.Time `bson:"lastCompletedAt,omitempty"`
	TotalCompletions  int        `bson:"totalCompletions"`
}

// Goal represents a recovery goal.
type Goal struct {
	BaseDocument

	UserID          string                   `bson:"userId"`
	GoalID          string                   `bson:"goalId"`
	Title           string                   `bson:"title"`
	Description     string                   `bson:"description"`
	TargetDate      string                   `bson:"targetDate"`
	Category        string                   `bson:"category"`
	Status          string                   `bson:"status"`
	ProgressPercent int                      `bson:"progressPercent"`
	Milestones      []map[string]interface{} `bson:"milestones,omitempty"`
}

// Session represents an authentication session.
type Session struct {
	BaseDocument

	UserID    string     `bson:"userId"`
	SessionID string     `bson:"sessionId"`
	DeviceID  string     `bson:"deviceId"`
	IPAddress string     `bson:"ipAddress"`
	UserAgent string     `bson:"userAgent"`
	ExpiresAt *time.Time `bson:"expiresAt,omitempty"`
}
