// internal/domain/activities/types.go
package activities

import "time"

// Activity type constants.
const (
	ActivityTypeCommitmentMorning  = "commitment-morning"
	ActivityTypeCommitmentEvening  = "commitment-evening"
	ActivityTypeJournal            = "journal"
	ActivityTypeEmotionalJournal   = "emotional-journal"
	ActivityTypeTimeJournal        = "time-journal"
	ActivityTypeCheckIn            = "check-in"
	ActivityTypePersonCheckIn      = "person-check-in"
	ActivityTypeFASTER             = "faster"
	ActivityTypePCI                = "pci"
	ActivityTypeUrge               = "urge"
	ActivityTypeMood               = "mood"
	ActivityTypeGratitude          = "gratitude"
	ActivityTypePhoneCall          = "phone-call"
	ActivityTypePrayer             = "prayer"
	ActivityTypeMeeting            = "meeting"
	ActivityTypeExercise           = "exercise"
	ActivityTypeNutrition          = "nutrition"
	ActivityTypeDevotional         = "devotional"
	ActivityTypeIntegrityInventory = "integrity-inventory"
	ActivityTypeActingIn           = "acting-in"
	ActivityTypePostMortem         = "post-mortem"
	ActivityTypeFinancial          = "financial"
	ActivityTypeStepWork           = "step-work"
	ActivityTypeGoal               = "goal"
	ActivityTypeSpouseCheckInPrep  = "spouse-check-in-prep"
)

// Activity represents a recovery activity log entry.
type Activity struct {
	ActivityID   string
	UserID       string
	ActivityType string
	Timestamp    time.Time
	Data         map[string]interface{}
	Ephemeral    bool
	CreatedAt    time.Time
	ModifiedAt   time.Time
}

// ActivityResponse is the response envelope for activity data.
type ActivityResponse struct {
	Data  Activity               `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// ActivitiesListResponse is the response envelope for multiple activities.
type ActivitiesListResponse struct {
	Data  []Activity             `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta"`
}

// LogActivityRequest represents a request to log an activity.
type LogActivityRequest struct {
	Timestamp time.Time
	Data      map[string]interface{}
	Ephemeral bool
}

// CommitmentData represents commitment-specific data.
type CommitmentData struct {
	AddictionIDs []string `json:"addictionIds,omitempty"`
	Notes        string   `json:"notes,omitempty"`
}

// JournalData represents journal entry data.
type JournalData struct {
	Content  string   `json:"content"`
	PromptID string   `json:"promptId,omitempty"`
	Tags     []string `json:"tags,omitempty"`
	Mood     string   `json:"mood,omitempty"`
}

// EmotionalJournalData represents emotional awareness journal data.
type EmotionalJournalData struct {
	Emotion   string  `json:"emotion"`
	Intensity int     `json:"intensity"`
	Trigger   string  `json:"trigger,omitempty"`
	Response  string  `json:"response,omitempty"`
	Location  string  `json:"location,omitempty"`
	Latitude  float64 `json:"latitude,omitempty"`
	Longitude float64 `json:"longitude,omitempty"`
	PhotoURL  string  `json:"photoUrl,omitempty"`
}

// TimeJournalData represents time-based interval journal data.
type TimeJournalData struct {
	IntervalMinutes int      `json:"intervalMinutes"`
	Entries         []string `json:"entries"`
	Location        string   `json:"location,omitempty"`
	Activity        string   `json:"activity,omitempty"`
}

// CheckInData represents daily check-in data.
type CheckInData struct {
	Score        int    `json:"score"`
	Mood         string `json:"mood,omitempty"`
	SleepQuality int    `json:"sleepQuality,omitempty"`
	StressLevel  int    `json:"stressLevel,omitempty"`
	Notes        string `json:"notes,omitempty"`
}

// FASTERData represents FASTER scale assessment data.
type FASTERData struct {
	Stage              string              `json:"stage"`              // "restoration", "F", "A", "S", "T", "E", "R"
	SelectedIndicators map[string][]string `json:"selectedIndicators"` // stage key → selected indicator strings
	MoodScore          int                 `json:"moodScore"`          // 1-5
	JournalInsight     string              `json:"journalInsight"`     // "Ah-ha"
	JournalWarning     string              `json:"journalWarning"`     // "Uh-oh"
	JournalFreeText    string              `json:"journalFreeText"`    // optional free-text
}

// PCIData represents Personal Craziness Index data.
type PCIData struct {
	Score int      `json:"score"`
	Items []string `json:"items"`
	Notes string   `json:"notes,omitempty"`
}

// UrgeData represents urge log data.
type UrgeData struct {
	Intensity          int      `json:"intensity"` // 1-10
	Trigger            string   `json:"trigger,omitempty"`
	ToolsUsed          []string `json:"toolsUsed,omitempty"`
	SobrietyMaintained bool     `json:"sobrietyMaintained"`
	Notes              string   `json:"notes,omitempty"`
}

// MoodData represents mood rating data.
type MoodData struct {
	Mood   string `json:"mood"`
	Rating int    `json:"rating"` // 1-10
	Notes  string `json:"notes,omitempty"`
}

// GratitudeData represents gratitude entry data.
type GratitudeData struct {
	Items []string `json:"items"`
	Notes string   `json:"notes,omitempty"`
}

// PhoneCallData represents phone call log data.
type PhoneCallData struct {
	ContactType string `json:"contactType"` // sponsor, accountability-partner, friend
	Duration    int    `json:"duration"`    // minutes
	Notes       string `json:"notes,omitempty"`
}

// PrayerData represents prayer log data.
type PrayerData struct {
	Duration int      `json:"duration"`       // minutes
	Type     string   `json:"type,omitempty"` // adoration, confession, thanksgiving, supplication
	Topics   []string `json:"topics,omitempty"`
	Notes    string   `json:"notes,omitempty"`
}

// MeetingData represents meeting attendance data.
type MeetingData struct {
	Type     string `json:"type"` // SA, CR, AA, etc.
	Location string `json:"location,omitempty"`
	Duration int    `json:"duration"` // minutes
	Notes    string `json:"notes,omitempty"`
}

// ExerciseData represents exercise tracking data.
type ExerciseData struct {
	Type      string `json:"type"`
	Duration  int    `json:"duration"`            // minutes
	Intensity string `json:"intensity,omitempty"` // low, moderate, high
	Notes     string `json:"notes,omitempty"`
}

// NutritionData represents nutrition tracking data.
type NutritionData struct {
	MealType string   `json:"mealType"` // breakfast, lunch, dinner, snack
	Foods    []string `json:"foods"`
	Notes    string   `json:"notes,omitempty"`
}

// DevotionalData represents devotional completion data.
type DevotionalData struct {
	DevotionalID string `json:"devotionalId"`
	Duration     int    `json:"duration"` // minutes
	Reflection   string `json:"reflection,omitempty"`
}

// IntegrityInventoryData represents daily integrity check data.
type IntegrityInventoryData struct {
	Honest      bool   `json:"honest"`
	Faithful    bool   `json:"faithful"`
	Pure        bool   `json:"pure"`
	Accountable bool   `json:"accountable"`
	Notes       string `json:"notes,omitempty"`
}

// ActingInData represents acting-in behavior (outer circle) data.
type ActingInData struct {
	Behavior    string `json:"behavior"`
	Frequency   int    `json:"frequency"`
	Description string `json:"description,omitempty"`
}

// PostMortemData represents post-relapse analysis data.
type PostMortemData struct {
	RelapseID  string   `json:"relapseId"`
	Triggers   []string `json:"triggers"`
	Feelings   []string `json:"feelings"`
	Thoughts   []string `json:"thoughts"`
	Prevention string   `json:"prevention,omitempty"`
	Lessons    string   `json:"lessons,omitempty"`
}

// FinancialData represents financial tracking data.
type FinancialData struct {
	Amount      float64 `json:"amount"`
	Category    string  `json:"category"` // saved, spent-recovery, spent-addiction
	Description string  `json:"description,omitempty"`
}

// StepWorkData represents 12-step work data.
type StepWorkData struct {
	StepNumber int    `json:"stepNumber"` // 1-12
	Progress   string `json:"progress,omitempty"`
	Reflection string `json:"reflection,omitempty"`
}

// GoalData represents recovery goal data.
type GoalData struct {
	Type        string `json:"type"` // daily, weekly
	Description string `json:"description"`
	Completed   bool   `json:"completed"`
	Notes       string `json:"notes,omitempty"`
}

// SpouseCheckInPrepData represents FANOS/FITNAP spouse check-in preparation data.
type SpouseCheckInPrepData struct {
	Framework string                 `json:"framework"` // FANOS, FITNAP
	Data      map[string]interface{} `json:"data"`
}
