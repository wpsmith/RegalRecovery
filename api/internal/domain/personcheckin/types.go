// internal/domain/personcheckin/types.go
package personcheckin

import "time"

// CheckInType represents the sub-type of person check-in.
type CheckInType string

const (
	CheckInTypeSpouse        CheckInType = "spouse"
	CheckInTypeSponsor       CheckInType = "sponsor"
	CheckInTypeCounselorCoach CheckInType = "counselor-coach"
)

// ValidCheckInTypes contains all valid check-in types.
var ValidCheckInTypes = []CheckInType{
	CheckInTypeSpouse,
	CheckInTypeSponsor,
	CheckInTypeCounselorCoach,
}

// Method represents how the check-in happened.
type Method string

const (
	MethodInPerson     Method = "in-person"
	MethodPhoneCall    Method = "phone-call"
	MethodVideoCall    Method = "video-call"
	MethodTextMessage  Method = "text-message"
	MethodAppMessaging Method = "app-messaging"
)

// ValidMethods contains all valid contact methods.
var ValidMethods = []Method{
	MethodInPerson,
	MethodPhoneCall,
	MethodVideoCall,
	MethodTextMessage,
	MethodAppMessaging,
}

// Topic represents a discussion topic.
type Topic string

const (
	TopicSobrietyRecovery    Topic = "sobriety-recovery"
	TopicStepWork            Topic = "step-work"
	TopicTriggersUrges       Topic = "triggers-urges"
	TopicEmotionsFeelings    Topic = "emotions-feelings"
	TopicRelationshipsMarriage Topic = "relationships-marriage"
	TopicBoundaries          Topic = "boundaries"
	TopicGoalsCommitments    Topic = "goals-commitments"
	TopicAccountability      Topic = "accountability"
	TopicSpiritualLife       Topic = "spiritual-life"
	TopicGeneralLifeSupport  Topic = "general-life-support"
	TopicCrisisEmergency     Topic = "crisis-emergency"
	TopicOther               Topic = "other"
)

// ValidTopics contains all valid discussion topics.
var ValidTopics = []Topic{
	TopicSobrietyRecovery,
	TopicStepWork,
	TopicTriggersUrges,
	TopicEmotionsFeelings,
	TopicRelationshipsMarriage,
	TopicBoundaries,
	TopicGoalsCommitments,
	TopicAccountability,
	TopicSpiritualLife,
	TopicGeneralLifeSupport,
	TopicCrisisEmergency,
	TopicOther,
}

// StreakFrequency represents how streak is measured.
type StreakFrequency string

const (
	StreakFrequencyDaily    StreakFrequency = "daily"
	StreakFrequencyXPerWeek StreakFrequency = "x-per-week"
	StreakFrequencyWeekly   StreakFrequency = "weekly"
)

// ValidStreakFrequencies contains all valid streak frequency values.
var ValidStreakFrequencies = []StreakFrequency{
	StreakFrequencyDaily,
	StreakFrequencyXPerWeek,
	StreakFrequencyWeekly,
}

// CounselorSubCategory represents the sub-category for counselor check-ins.
type CounselorSubCategory string

const (
	CounselorSubCategoryScheduledSession      CounselorSubCategory = "scheduled-session"
	CounselorSubCategoryBetweenSessionContact CounselorSubCategory = "between-session-contact"
)

// QualityTrend represents the direction of quality change.
type QualityTrend string

const (
	QualityTrendImproving QualityTrend = "improving"
	QualityTrendStable    QualityTrend = "stable"
	QualityTrendDeclining QualityTrend = "declining"
)

// FollowUpItem represents an action item from a check-in.
type FollowUpItem struct {
	Text   string  `json:"text"`
	GoalID *string `json:"goalId"`
}

// PersonCheckIn represents a person check-in entry.
type PersonCheckIn struct {
	CheckInID            string               `json:"checkInId"`
	UserID               string               `json:"-"`
	TenantID             string               `json:"-"`
	CheckInType          CheckInType          `json:"checkInType"`
	Method               Method               `json:"method"`
	Timestamp            time.Time            `json:"timestamp"`
	ContactName          *string              `json:"contactName,omitempty"`
	DurationMinutes      *int                 `json:"durationMinutes,omitempty"`
	QualityRating        *int                 `json:"qualityRating,omitempty"`
	TopicsDiscussed      []Topic              `json:"topicsDiscussed,omitempty"`
	Notes                *string              `json:"notes,omitempty"`
	FollowUpItems        []FollowUpItem       `json:"followUpItems,omitempty"`
	CounselorSubCategory *CounselorSubCategory `json:"counselorSubCategory,omitempty"`
	CreatedAt            time.Time            `json:"createdAt"`
	ModifiedAt           time.Time            `json:"modifiedAt"`
	Links                *Links               `json:"links,omitempty"`
}

// CreatePersonCheckInRequest represents the request to create a check-in.
type CreatePersonCheckInRequest struct {
	CheckInType          CheckInType          `json:"checkInType"`
	Method               Method               `json:"method"`
	Timestamp            *time.Time           `json:"timestamp,omitempty"`
	ContactName          *string              `json:"contactName,omitempty"`
	DurationMinutes      *int                 `json:"durationMinutes,omitempty"`
	QualityRating        *int                 `json:"qualityRating,omitempty"`
	TopicsDiscussed      []Topic              `json:"topicsDiscussed,omitempty"`
	Notes                *string              `json:"notes,omitempty"`
	FollowUpItems        []string             `json:"followUpItems,omitempty"`
	CounselorSubCategory *CounselorSubCategory `json:"counselorSubCategory,omitempty"`
}

// QuickLogPersonCheckInRequest represents the request for a quick-log check-in.
type QuickLogPersonCheckInRequest struct {
	CheckInType CheckInType `json:"checkInType"`
	Method      *Method     `json:"method,omitempty"`
}

// UpdatePersonCheckInRequest represents the request to update a check-in.
type UpdatePersonCheckInRequest struct {
	Method               *Method              `json:"method,omitempty"`
	ContactName          *string              `json:"contactName,omitempty"`
	DurationMinutes      *int                 `json:"durationMinutes,omitempty"`
	QualityRating        *int                 `json:"qualityRating,omitempty"`
	TopicsDiscussed      []Topic              `json:"topicsDiscussed,omitempty"`
	Notes                *string              `json:"notes,omitempty"`
	FollowUpItems        []string             `json:"followUpItems,omitempty"`
	CounselorSubCategory *CounselorSubCategory `json:"counselorSubCategory,omitempty"`
}

// PersonCheckInStreak represents streak data for a sub-type.
type PersonCheckInStreak struct {
	CheckInType     CheckInType `json:"checkInType"`
	CurrentStreak   int         `json:"currentStreak"`
	LongestStreak   int         `json:"longestStreak"`
	StreakUnit      string      `json:"streakUnit"`
	CheckInsThisWeek  int       `json:"checkInsThisWeek"`
	CheckInsThisMonth int       `json:"checkInsThisMonth"`
	AveragePerWeek  float64     `json:"averagePerWeek"`
	LastCheckInDate *string     `json:"lastCheckInDate,omitempty"`
}

// SubTypeSettings represents settings for a single sub-type.
type SubTypeSettings struct {
	ContactName         *string         `json:"contactName"`
	StreakFrequency     StreakFrequency `json:"streakFrequency"`
	RequiredCountPerWeek *int           `json:"requiredCountPerWeek"`
	InactivityAlertDays int            `json:"inactivityAlertDays"`
	ReminderEnabled     bool           `json:"reminderEnabled"`
	ReminderTime        *string        `json:"reminderTime"`
	ReminderFrequency   *string        `json:"reminderFrequency"`
	LastUsedMethod      *Method        `json:"lastUsedMethod,omitempty"`
}

// PersonCheckInSettings represents per-sub-type configuration.
type PersonCheckInSettings struct {
	UserID       string          `json:"-"`
	TenantID     string          `json:"-"`
	Spouse       SubTypeSettings `json:"spouse"`
	Sponsor      SubTypeSettings `json:"sponsor"`
	CounselorCoach SubTypeSettings `json:"counselorCoach"`
	CreatedAt    time.Time       `json:"-"`
	ModifiedAt   time.Time       `json:"-"`
}

// SubTypeSettingsUpdate represents partial update fields for settings.
type SubTypeSettingsUpdate struct {
	ContactName         *string         `json:"contactName,omitempty"`
	StreakFrequency     *StreakFrequency `json:"streakFrequency,omitempty"`
	RequiredCountPerWeek *int           `json:"requiredCountPerWeek,omitempty"`
	InactivityAlertDays *int            `json:"inactivityAlertDays,omitempty"`
	ReminderEnabled     *bool           `json:"reminderEnabled,omitempty"`
	ReminderTime        *string        `json:"reminderTime,omitempty"`
	ReminderFrequency   *string        `json:"reminderFrequency,omitempty"`
}

// UpdateSettingsRequest represents the request to update settings.
type UpdateSettingsRequest struct {
	Spouse         *SubTypeSettingsUpdate `json:"spouse,omitempty"`
	Sponsor        *SubTypeSettingsUpdate `json:"sponsor,omitempty"`
	CounselorCoach *SubTypeSettingsUpdate `json:"counselorCoach,omitempty"`
}

// FrequencyDataPoint represents a single day's frequency data.
type FrequencyDataPoint struct {
	Date           string `json:"date"`
	Spouse         int    `json:"spouse"`
	Sponsor        int    `json:"sponsor"`
	CounselorCoach int    `json:"counselorCoach"`
}

// QualityDataPoint represents average quality for a date.
type QualityDataPoint struct {
	Date    string  `json:"date"`
	Average float64 `json:"average"`
}

// QualityTrendData represents quality trend for a sub-type.
type QualityTrendData struct {
	AverageRating float64            `json:"averageRating"`
	Trend         QualityTrend       `json:"trend"`
	DataPoints    []QualityDataPoint `json:"dataPoints"`
}

// TopicFrequency represents a topic and its count.
type TopicFrequency struct {
	Topic string `json:"topic"`
	Count int    `json:"count"`
}

// BalanceGap represents a detected gap in check-in balance.
type BalanceGap struct {
	Type    string `json:"type"`
	Message string `json:"message"`
}

// BalanceData represents balance analysis across sub-types.
type BalanceData struct {
	Spouse         int          `json:"spouse"`
	Sponsor        int          `json:"sponsor"`
	CounselorCoach int          `json:"counselorCoach"`
	Gaps           []BalanceGap `json:"gaps"`
}

// TrendsData represents all trend data.
type TrendsData struct {
	Frequency          []FrequencyDataPoint       `json:"frequency"`
	MethodDistribution map[string]map[string]int   `json:"methodDistribution"`
	QualityTrends      map[string]QualityTrendData `json:"qualityTrends"`
	TopicFrequency     []TopicFrequency            `json:"topicFrequency"`
	Balance            BalanceData                 `json:"balance"`
}

// CalendarDayCheckIn represents a check-in count for a sub-type on a day.
type CalendarDayCheckIn struct {
	CheckInType CheckInType `json:"checkInType"`
	Count       int         `json:"count"`
}

// CalendarDay represents a single day in the calendar view.
type CalendarDay struct {
	Date     string              `json:"date"`
	CheckIns []CalendarDayCheckIn `json:"checkIns"`
}

// CalendarData represents the calendar month view.
type CalendarData struct {
	Month string        `json:"month"`
	Days  []CalendarDay `json:"days"`
}

// InactivityAlert represents an alert for a sub-type.
type InactivityAlert struct {
	CheckInType    CheckInType `json:"checkInType"`
	ContactName    *string     `json:"contactName,omitempty"`
	DaysSinceLastCheckIn int  `json:"daysSinceLastCheckIn"`
	ThresholdDays  int         `json:"thresholdDays"`
	Message        string      `json:"message"`
}

// Links represents HATEOAS links.
type Links struct {
	Self string `json:"self"`
}

// PaginationLinks represents pagination HATEOAS links.
type PaginationLinks struct {
	Self string  `json:"self"`
	Next *string `json:"next,omitempty"`
	Prev *string `json:"prev,omitempty"`
}

// PageMetadata represents cursor-based pagination metadata.
type PageMetadata struct {
	NextCursor *string `json:"nextCursor,omitempty"`
	PrevCursor *string `json:"prevCursor,omitempty"`
	Limit      int     `json:"limit"`
}

// PersonCheckInResponse is the response envelope for a single check-in.
type PersonCheckInResponse struct {
	Data PersonCheckIn          `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// PersonCheckInListResponse is the response envelope for a list of check-ins.
type PersonCheckInListResponse struct {
	Data  []PersonCheckIn        `json:"data"`
	Links PaginationLinks        `json:"links"`
	Meta  map[string]interface{} `json:"meta"`
}

// PersonCheckInStreaksResponse is the response envelope for streaks.
type PersonCheckInStreaksResponse struct {
	Data  StreaksResponseData    `json:"data"`
	Links Links                 `json:"links"`
	Meta  map[string]interface{} `json:"meta"`
}

// StreaksResponseData contains streak data.
type StreaksResponseData struct {
	Streaks  []PersonCheckInStreak `json:"streaks"`
	Combined CombinedStreakData    `json:"combined"`
}

// CombinedStreakData contains combined streak metrics.
type CombinedStreakData struct {
	TotalCheckInsThisWeek  int `json:"totalCheckInsThisWeek"`
	TotalCheckInsThisMonth int `json:"totalCheckInsThisMonth"`
}

// PersonCheckInSettingsResponse is the response envelope for settings.
type PersonCheckInSettingsResponse struct {
	Data  PersonCheckInSettings  `json:"data"`
	Links Links                  `json:"links"`
	Meta  map[string]interface{} `json:"meta"`
}

// PersonCheckInTrendsResponse is the response envelope for trends.
type PersonCheckInTrendsResponse struct {
	Data  TrendsData             `json:"data"`
	Links Links                  `json:"links"`
	Meta  map[string]interface{} `json:"meta"`
}

// PersonCheckInCalendarResponse is the response envelope for calendar.
type PersonCheckInCalendarResponse struct {
	Data  CalendarData           `json:"data"`
	Links Links                  `json:"links"`
	Meta  map[string]interface{} `json:"meta"`
}

// ConvertFollowUpResponse is the response for converting a follow-up to a goal.
type ConvertFollowUpResponse struct {
	Data  ConvertFollowUpData    `json:"data"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// ConvertFollowUpData contains the goal conversion data.
type ConvertFollowUpData struct {
	GoalID       string `json:"goalId"`
	FollowUpText string `json:"followUpText"`
	Links        struct {
		Goal    string `json:"goal"`
		CheckIn string `json:"checkIn"`
	} `json:"links"`
}

// ListCheckInsParams contains parameters for listing check-ins.
type ListCheckInsParams struct {
	CheckInType      *CheckInType
	Method           *Method
	MinQualityRating *int
	Topic            *Topic
	StartDate        *time.Time
	EndDate          *time.Time
	Query            *string
	Sort             string
	Cursor           string
	Limit            int
}

// Encouragement messages rotating for post-log.
var EncouragementMessages = []string{
	"Showing up for that conversation took courage. That's recovery in action.",
	"The people in your corner need to hear from you. And you need to hear from them.",
	"Every honest conversation builds something that addiction tried to destroy: trust.",
	"You didn't do today alone. That's worth celebrating.",
}
