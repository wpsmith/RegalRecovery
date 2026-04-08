// internal/domain/phonecalls/types.go
package phonecalls

import "time"

// FeatureFlagKey is the feature flag key for the phone calls activity.
// This flag must be enabled for users to access phone call endpoints.
// When disabled, all endpoints return 404 (fail closed).
const FeatureFlagKey = "activity.phone-calls"

// Direction represents whether a call was made or received.
type Direction string

const (
	DirectionMade     Direction = "made"
	DirectionReceived Direction = "received"
)

// ContactType represents the type of recovery contact.
type ContactType string

const (
	ContactTypeSponsor               ContactType = "sponsor"
	ContactTypeAccountabilityPartner ContactType = "accountability-partner"
	ContactTypeCounselor             ContactType = "counselor"
	ContactTypeCoach                 ContactType = "coach"
	ContactTypeSupportPerson         ContactType = "support-person"
	ContactTypeCustom                ContactType = "custom"
)

// TrendPeriod represents a time period for trend analysis.
type TrendPeriod string

const (
	TrendPeriod7d  TrendPeriod = "7d"
	TrendPeriod30d TrendPeriod = "30d"
	TrendPeriod90d TrendPeriod = "90d"
)

// PhoneCall represents a phone call log entry.
type PhoneCall struct {
	CallID             string     `json:"callId"`
	UserID             string     `json:"-"`
	TenantID           string     `json:"-"`
	Timestamp          time.Time  `json:"timestamp"`
	Direction          Direction  `json:"direction"`
	ContactType        ContactType `json:"contactType"`
	CustomContactLabel *string    `json:"customContactLabel,omitempty"`
	Connected          bool       `json:"connected"`
	ContactName        *string    `json:"contactName,omitempty"`
	SavedContactID     *string    `json:"savedContactId,omitempty"`
	DurationMinutes    *int       `json:"durationMinutes,omitempty"`
	Notes              *string    `json:"notes,omitempty"`
	CallStreakDays     int        `json:"callStreakDays"`
	CrossRefPrompt     *string    `json:"crossReferencePrompt,omitempty"`
	CreatedAt          time.Time  `json:"createdAt"`
	ModifiedAt         time.Time  `json:"modifiedAt"`
}

// SavedContact represents a saved recovery contact for quick-select.
type SavedContact struct {
	SavedContactID string      `json:"savedContactId"`
	UserID         string      `json:"-"`
	TenantID       string      `json:"-"`
	ContactName    string      `json:"contactName"`
	ContactType    ContactType `json:"contactType"`
	PhoneNumber    *string     `json:"phoneNumber,omitempty"`
	HasPhoneNumber bool        `json:"hasPhoneNumber"`
	CreatedAt      time.Time   `json:"createdAt"`
	ModifiedAt     time.Time   `json:"modifiedAt"`
}

// PhoneCallStreak represents the call streak data.
type PhoneCallStreak struct {
	CurrentStreakDays  int     `json:"currentStreakDays"`
	LongestStreakDays  int     `json:"longestStreakDays"`
	LastCallDate       *string `json:"lastCallDate"`
	TotalCallsAllTime  int     `json:"totalCallsAllTime"`
	TotalConnectedCalls int    `json:"totalConnectedCalls"`
}

// PhoneCallTrends represents trend and insight data.
type PhoneCallTrends struct {
	Period                   TrendPeriod              `json:"period"`
	TotalCalls               int                      `json:"totalCalls"`
	CallsMade                int                      `json:"callsMade"`
	CallsReceived            int                      `json:"callsReceived"`
	ConnectedCalls           int                      `json:"connectedCalls"`
	AttemptedCalls           int                      `json:"attemptedCalls"`
	ConnectionRate           float64                  `json:"connectionRate"`
	AverageCallsPerWeek      float64                  `json:"averageCallsPerWeek"`
	ContactTypeDistribution  []ContactTypeCount       `json:"contactTypeDistribution"`
	PreviousPeriodComparison *PeriodComparison        `json:"previousPeriodComparison,omitempty"`
	DaysSinceLastCall        int                      `json:"daysSinceLastCall"`
	IsolationWarning         bool                     `json:"isolationWarning"`
}

// ContactTypeCount represents a count and percentage for a contact type.
type ContactTypeCount struct {
	ContactType ContactType `json:"contactType"`
	Count       int         `json:"count"`
	Percentage  float64     `json:"percentage"`
}

// PeriodComparison represents a comparison to the previous period.
type PeriodComparison struct {
	TotalCallsDelta     int     `json:"totalCallsDelta"`
	ConnectionRateDelta float64 `json:"connectionRateDelta"`
}

// DailyCallCount represents per-day call counts for charting.
type DailyCallCount struct {
	Date           string `json:"date"`
	TotalCalls     int    `json:"totalCalls"`
	CallsMade      int    `json:"callsMade"`
	CallsReceived  int    `json:"callsReceived"`
	ConnectedCalls int    `json:"connectedCalls"`
	AttemptedCalls int    `json:"attemptedCalls"`
}

// --- Request types ---

// CreatePhoneCallRequest represents the request to log a phone call.
type CreatePhoneCallRequest struct {
	Timestamp          *time.Time  `json:"timestamp,omitempty"`
	Direction          Direction   `json:"direction"`
	ContactType        ContactType `json:"contactType"`
	CustomContactLabel *string     `json:"customContactLabel,omitempty"`
	Connected          bool        `json:"connected"`
	ContactName        *string     `json:"contactName,omitempty"`
	SavedContactID     *string     `json:"savedContactId,omitempty"`
	DurationMinutes    *int        `json:"durationMinutes,omitempty"`
	Notes              *string     `json:"notes,omitempty"`
}

// UpdatePhoneCallRequest represents a merge-patch update to a phone call.
type UpdatePhoneCallRequest struct {
	Timestamp          *time.Time  `json:"timestamp,omitempty"`
	Direction          *Direction  `json:"direction,omitempty"`
	ContactType        *ContactType `json:"contactType,omitempty"`
	CustomContactLabel *string     `json:"customContactLabel,omitempty"`
	Connected          *bool       `json:"connected,omitempty"`
	ContactName        *string     `json:"contactName,omitempty"`
	SavedContactID     *string     `json:"savedContactId,omitempty"`
	DurationMinutes    *int        `json:"durationMinutes,omitempty"`
	Notes              *string     `json:"notes,omitempty"`
}

// CreateSavedContactRequest represents the request to create a saved contact.
type CreateSavedContactRequest struct {
	ContactName string      `json:"contactName"`
	ContactType ContactType `json:"contactType"`
	PhoneNumber *string     `json:"phoneNumber,omitempty"`
}

// UpdateSavedContactRequest represents a merge-patch update to a saved contact.
type UpdateSavedContactRequest struct {
	ContactName *string      `json:"contactName,omitempty"`
	ContactType *ContactType `json:"contactType,omitempty"`
	PhoneNumber *string      `json:"phoneNumber,omitempty"`
}

// --- Response envelope types ---

// PhoneCallResponse wraps a single PhoneCall.
type PhoneCallResponse struct {
	Data PhoneCall              `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// PhoneCallListResponse wraps a list of PhoneCalls with pagination.
type PhoneCallListResponse struct {
	Data  []PhoneCall            `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// SavedContactResponse wraps a single SavedContact.
type SavedContactResponse struct {
	Data SavedContact           `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// SavedContactListResponse wraps a list of SavedContacts.
type SavedContactListResponse struct {
	Data []SavedContact         `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// StreakResponse wraps PhoneCallStreak.
type StreakResponse struct {
	Data PhoneCallStreak        `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// TrendsResponse wraps PhoneCallTrends.
type TrendsResponse struct {
	Data PhoneCallTrends        `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// DailyTrendsResponse wraps daily call counts.
type DailyTrendsResponse struct {
	Data []DailyCallCount       `json:"data"`
	Meta map[string]interface{} `json:"meta,omitempty"`
}

// ListFilters holds the filter options for listing phone calls.
type ListFilters struct {
	Direction   *Direction
	ContactType *ContactType
	Connected   *bool
	StartDate   *string
	EndDate     *string
	Search      *string
}
