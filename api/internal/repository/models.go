// internal/repository/models.go
package repository

import "time"

// BaseItem contains common attributes present on all DynamoDB items.
type BaseItem struct {
	PK         string `dynamodbav:"PK"`
	SK         string `dynamodbav:"SK"`
	EntityType string `dynamodbav:"EntityType"`
	CreatedAt  string `dynamodbav:"CreatedAt"`
	ModifiedAt string `dynamodbav:"ModifiedAt"`
	TenantID   string `dynamodbav:"TenantId"`
}

// OptionalGSI contains optional GSI attributes for items that need reverse lookups or tenant queries.
type OptionalGSI struct {
	GSI1PK *string `dynamodbav:"GSI1PK,omitempty"`
	GSI1SK *string `dynamodbav:"GSI1SK,omitempty"`
	GSI2PK *string `dynamodbav:"GSI2PK,omitempty"`
	GSI2SK *string `dynamodbav:"GSI2SK,omitempty"`
}

// OptionalTTL contains the TTL attribute for ephemeral items.
type OptionalTTL struct {
	ExpiresAt *int64 `dynamodbav:"expiresAt,omitempty"`
}

// User represents a user profile in DynamoDB.
type User struct {
	BaseItem
	OptionalGSI

	Email                 string `dynamodbav:"email"`
	DisplayName           string `dynamodbav:"displayName"`
	Role                  string `dynamodbav:"role"`
	PrimaryAddictionID    string `dynamodbav:"primaryAddictionId"`
	PreferredLanguage     string `dynamodbav:"preferredLanguage"`
	PreferredBibleVersion string `dynamodbav:"preferredBibleVersion"`
	BirthYear             int    `dynamodbav:"birthYear,omitempty"`
	Gender                string `dynamodbav:"gender,omitempty"`
	MaritalStatus         string `dynamodbav:"maritalStatus,omitempty"`
	TimeZone              string `dynamodbav:"timeZone"`
	EmailVerified         bool   `dynamodbav:"emailVerified"`
	BiometricEnabled      bool   `dynamodbav:"biometricEnabled"`
	RegionID              string `dynamodbav:"regionId"`
	SubscriptionTier      string `dynamodbav:"subscriptionTier"`
	SubscriptionExpiresAt string `dynamodbav:"subscriptionExpiresAt,omitempty"`
}

// UserSettings represents user preferences and configuration.
type UserSettings struct {
	BaseItem

	NotificationPreferences map[string]interface{} `dynamodbav:"notificationPreferences"`
	PrivacySettings         map[string]interface{} `dynamodbav:"privacySettings"`
	DisplaySettings         map[string]interface{} `dynamodbav:"displaySettings"`
	SecuritySettings        map[string]interface{} `dynamodbav:"securitySettings"`
}

// Addiction represents a tracked addiction with sobriety start date.
type Addiction struct {
	BaseItem

	AddictionID       string `dynamodbav:"addictionId"`
	Type              string `dynamodbav:"type"`
	SobrietyStartDate string `dynamodbav:"sobrietyStartDate"`
	IsPrimary         bool   `dynamodbav:"isPrimary"`
}

// Streak represents current and longest sobriety streak per addiction.
type Streak struct {
	BaseItem

	AddictionID       string  `dynamodbav:"addictionId"`
	CurrentStreakDays int     `dynamodbav:"currentStreakDays"`
	LongestStreakDays int     `dynamodbav:"longestStreakDays"`
	SobrietyStartDate string  `dynamodbav:"sobrietyStartDate"`
	LastRelapseDate   *string `dynamodbav:"lastRelapseDate,omitempty"`
	TotalSoberDays    int     `dynamodbav:"totalSoberDays"`
}

// Milestone represents a sobriety milestone achievement.
type Milestone struct {
	BaseItem

	MilestoneID  string `dynamodbav:"milestoneId"`
	AddictionID  string `dynamodbav:"addictionId"`
	Type         string `dynamodbav:"type"`
	Days         int    `dynamodbav:"days"`
	AchievedAt   string `dynamodbav:"achievedAt"`
	Celebrated   bool   `dynamodbav:"celebrated"`
	CoinImageURL string `dynamodbav:"coinImageUrl,omitempty"`
}

// Relapse represents a relapse event.
type Relapse struct {
	BaseItem

	RelapseID           string `dynamodbav:"relapseId"`
	AddictionID         string `dynamodbav:"addictionId"`
	Timestamp           string `dynamodbav:"timestamp"`
	PreviousStreakDays  int    `dynamodbav:"previousStreakDays"`
	Notes               string `dynamodbav:"notes,omitempty"`
	PostMortemCompleted bool   `dynamodbav:"postMortemCompleted"`
}

// CheckIn represents a daily/evening check-in entry.
type CheckIn struct {
	BaseItem
	OptionalGSI

	CheckInID string                 `dynamodbav:"checkInId"`
	Type      string                 `dynamodbav:"type"`
	Responses map[string]interface{} `dynamodbav:"responses"`
	Score     int                    `dynamodbav:"score"`
	ColorCode string                 `dynamodbav:"colorCode"`
}

// Urge represents an urge log entry.
type Urge struct {
	BaseItem

	UrgeID             string   `dynamodbav:"urgeId"`
	AddictionID        string   `dynamodbav:"addictionId"`
	Intensity          int      `dynamodbav:"intensity"`
	Triggers           []string `dynamodbav:"triggers"`
	Notes              string   `dynamodbav:"notes,omitempty"`
	SobrietyMaintained bool     `dynamodbav:"sobrietyMaintained"`
	DurationMinutes    int      `dynamodbav:"durationMinutes,omitempty"`
}

// Journal represents a journal entry.
type Journal struct {
	BaseItem
	OptionalTTL

	EntryID           string   `dynamodbav:"entryId"`
	Mode              string   `dynamodbav:"mode"`
	Content           string   `dynamodbav:"content"`
	EmotionalTags     []string `dynamodbav:"emotionalTags,omitempty"`
	Prompt            string   `dynamodbav:"prompt,omitempty"`
	IsEphemeral       bool     `dynamodbav:"isEphemeral"`
	EphemeralDeleteAt *string  `dynamodbav:"ephemeralDeleteAt,omitempty"`
}

// Meeting represents a meeting attendance log.
type Meeting struct {
	BaseItem

	MeetingID       string `dynamodbav:"meetingId"`
	MeetingType     string `dynamodbav:"meetingType"`
	Name            string `dynamodbav:"name"`
	Location        string `dynamodbav:"location,omitempty"`
	Notes           string `dynamodbav:"notes,omitempty"`
	DurationMinutes int    `dynamodbav:"durationMinutes"`
}

// Prayer represents a prayer log entry.
type Prayer struct {
	BaseItem
	OptionalTTL

	PrayerID        string `dynamodbav:"prayerId"`
	PrayerType      string `dynamodbav:"prayerType"`
	Content         string `dynamodbav:"content"`
	DurationMinutes int    `dynamodbav:"durationMinutes"`
	IsEphemeral     bool   `dynamodbav:"isEphemeral"`
}

// Exercise represents an exercise log entry.
type Exercise struct {
	BaseItem

	ExerciseID      string `dynamodbav:"exerciseId"`
	Type            string `dynamodbav:"type"`
	DurationMinutes int    `dynamodbav:"durationMinutes"`
	Calories        int    `dynamodbav:"calories,omitempty"`
	Source          string `dynamodbav:"source"`
}

// Activity represents a calendar activity entry (denormalized view).
type Activity struct {
	BaseItem

	ActivityType string                 `dynamodbav:"activityType"`
	Summary      map[string]interface{} `dynamodbav:"summary"`
	SourceKey    string                 `dynamodbav:"sourceKey"`
	Date         string                 `dynamodbav:"-"` // Extracted from SK for convenience
	Timestamp    time.Time              `dynamodbav:"-"` // Extracted from SK for convenience
}

// SupportContact represents a support network contact.
type SupportContact struct {
	BaseItem
	OptionalGSI

	ContactID     string `dynamodbav:"contactId"`
	ContactUserID string `dynamodbav:"contactUserId"`
	Role          string `dynamodbav:"role"`
	DisplayName   string `dynamodbav:"displayName"`
	Email         string `dynamodbav:"email,omitempty"`
	Status        string `dynamodbav:"status"`
	InvitedAt     string `dynamodbav:"invitedAt"`
	AcceptedAt    string `dynamodbav:"acceptedAt,omitempty"`
}

// Permission represents a granular data permission for a contact.
type Permission struct {
	BaseItem

	PermissionID  string `dynamodbav:"permissionId"`
	ContactID     string `dynamodbav:"contactId"`
	ContactUserID string `dynamodbav:"contactUserId"`
	DataCategory  string `dynamodbav:"dataCategory"`
	AccessLevel   string `dynamodbav:"accessLevel"`
	GrantedAt     string `dynamodbav:"grantedAt"`
}

// Flag represents a feature flag.
type Flag struct {
	BaseItem

	Enabled           bool     `dynamodbav:"enabled"`
	RolloutPercentage int      `dynamodbav:"rolloutPercentage"`
	Tiers             []string `dynamodbav:"tiers,omitempty"`
	Tenants           []string `dynamodbav:"tenants,omitempty"`
	Platforms         []string `dynamodbav:"platforms,omitempty"`
	MinAppVersion     string   `dynamodbav:"minAppVersion,omitempty"`
	Description       string   `dynamodbav:"description"`
	UpdatedAt         string   `dynamodbav:"updatedAt"`
	UpdatedBy         string   `dynamodbav:"updatedBy"`
}

// AffirmationPack represents metadata for an affirmation pack.
type AffirmationPack struct {
	BaseItem

	PackID           string `dynamodbav:"packId"`
	Name             string `dynamodbav:"name"`
	Description      string `dynamodbav:"description"`
	Tier             string `dynamodbav:"tier"`
	Price            int    `dynamodbav:"price"`
	AffirmationCount int    `dynamodbav:"affirmationCount"`
	Category         string `dynamodbav:"category"`
}

// Affirmation represents an affirmation within a pack.
type Affirmation struct {
	BaseItem

	AffirmationID      string `dynamodbav:"affirmationId"`
	Statement          string `dynamodbav:"statement"`
	ScriptureReference string `dynamodbav:"scriptureReference,omitempty"`
	Category           string `dynamodbav:"category"`
	Language           string `dynamodbav:"language"`
}

// DevotionalDay represents a single day's devotional content.
type DevotionalDay struct {
	BaseItem

	Day           int    `dynamodbav:"day"`
	Title         string `dynamodbav:"title"`
	Scripture     string `dynamodbav:"scripture"`
	ScriptureText string `dynamodbav:"scriptureText"`
	Reflection    string `dynamodbav:"reflection"`
}

// Prompt represents a journal prompt for recovery reflection.
type Prompt struct {
	BaseItem

	PromptID string   `dynamodbav:"promptId"`
	Text     string   `dynamodbav:"text"`
	Category string   `dynamodbav:"category"` // daily, sobriety, emotional, relationships, spiritual, shame, triggers, amends, gratitude, deep
	Tags     []string `dynamodbav:"tags"`      // FASTER, 3 Circles, 12-Step, FANOS/FITNAP, PCI, Arousal Template
	Order    int      `dynamodbav:"order"`
}

// Commitment represents a user commitment (e.g., "Call sponsor daily").
type Commitment struct {
	BaseItem

	CommitmentID      string `dynamodbav:"commitmentId"`
	Title             string `dynamodbav:"title"`
	Frequency         string `dynamodbav:"frequency"`
	Category          string `dynamodbav:"category"`
	IsActive          bool   `dynamodbav:"isActive"`
	CurrentStreakDays int    `dynamodbav:"currentStreakDays"`
	LastCompletedAt   string `dynamodbav:"lastCompletedAt,omitempty"`
	TotalCompletions  int    `dynamodbav:"totalCompletions"`
}

// Goal represents a recovery goal.
type Goal struct {
	BaseItem

	GoalID          string                   `dynamodbav:"goalId"`
	Title           string                   `dynamodbav:"title"`
	Description     string                   `dynamodbav:"description"`
	TargetDate      string                   `dynamodbav:"targetDate"`
	Category        string                   `dynamodbav:"category"`
	Status          string                   `dynamodbav:"status"`
	ProgressPercent int                      `dynamodbav:"progressPercent"`
	Milestones      []map[string]interface{} `dynamodbav:"milestones,omitempty"`
}

// Session represents an authentication session.
type Session struct {
	BaseItem
	OptionalGSI
	OptionalTTL

	SessionID string `dynamodbav:"sessionId"`
	DeviceID  string `dynamodbav:"deviceId"`
	IPAddress string `dynamodbav:"ipAddress"`
	UserAgent string `dynamodbav:"userAgent"`
}
