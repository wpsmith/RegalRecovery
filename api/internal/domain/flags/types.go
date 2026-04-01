// internal/domain/flags/types.go
package flags

import "time"

// Flag represents a feature flag configuration.
type Flag struct {
	Key               string
	Enabled           bool
	RolloutPercentage int
	Tiers             []string
	Tenants           []string
	Platforms         []string
	MinAppVersion     string
	Description       string
	UpdatedAt         time.Time
	UpdatedBy         string
}

// EvaluatedFlag represents a flag evaluated for a specific user.
type EvaluatedFlag struct {
	Key     string `json:"key"`
	Enabled bool   `json:"enabled"`
}

// EvaluatedFlagsResponse is the response envelope for evaluated flags.
type EvaluatedFlagsResponse struct {
	Data []EvaluatedFlag        `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// FlagConfigResponse is the response envelope for flag configuration.
type FlagConfigResponse struct {
	Data  Flag                   `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// FlagsListResponse is the response envelope for multiple flag configurations.
type FlagsListResponse struct {
	Data []Flag                 `json:"data"`
	Meta map[string]interface{} `json:"meta"`
}

// FlagUpdate represents a partial update to flag configuration.
type FlagUpdate struct {
	Enabled           *bool
	RolloutPercentage *int
	Tiers             []string
	Tenants           []string
	Platforms         []string
	MinAppVersion     *string
	Description       *string
}

// UserContext contains user-specific information for flag evaluation.
type UserContext struct {
	UserID     string
	TenantID   string
	Tier       string
	Platform   string
	AppVersion string
}
