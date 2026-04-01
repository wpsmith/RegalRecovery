// internal/domain/auth/types.go
package auth

import "time"

// User represents an authenticated user in the system.
type User struct {
	ID                string
	Email             string
	DisplayName       string
	EmailVerified     bool
	PrimaryAddiction  string
	SobrietyStartDate time.Time
	CreatedAt         time.Time
	ModifiedAt        time.Time
}

// Session represents an active user session.
type Session struct {
	UserID       string
	TenantID     string
	SessionID    string
	DeviceID     string
	DeviceName   string
	IPAddress    string
	IssuedAt     time.Time
	ExpiresAt    time.Time
	LastActivity time.Time
}

// RegisterRequest contains user registration data.
type RegisterRequest struct {
	Email             string
	Password          string
	DisplayName       string
	PrimaryAddiction  string
	SobrietyStartDate string // YYYY-MM-DD format
	PreferredLanguage string
	TimeZone          string
}

// RegisterResponse is the response envelope for registration.
type RegisterResponse struct {
	Data  RegisterData           `json:"data"`
	Links map[string]string      `json:"links"`
	Meta  map[string]interface{} `json:"meta"`
}

// RegisterData contains the registration response data.
type RegisterData struct {
	UserID        string `json:"userId"`
	Email         string `json:"email"`
	DisplayName   string `json:"displayName"`
	EmailVerified bool   `json:"emailVerified"`
	AccessToken   string `json:"accessToken"`
	RefreshToken  string `json:"refreshToken"`
	ExpiresIn     int    `json:"expiresIn"`
	TokenType     string `json:"tokenType"`
}

// SessionResponse is the response envelope for session data.
type SessionResponse struct {
	Data  SessionData            `json:"data"`
	Links map[string]string      `json:"links,omitempty"`
	Meta  map[string]interface{} `json:"meta,omitempty"`
}

// SessionData contains session information.
type SessionData struct {
	UserID     string    `json:"userId"`
	TenantID   string    `json:"tenantId,omitempty"`
	SessionID  string    `json:"sessionId"`
	DeviceID   string    `json:"deviceId,omitempty"`
	DeviceName string    `json:"deviceName,omitempty"`
	ExpiresAt  time.Time `json:"expiresAt"`
}

// ErrorResponse represents an error response following Siemens API conventions.
type ErrorResponse struct {
	Errors []ErrorObject `json:"errors"`
}

// ErrorObject represents a single error.
type ErrorObject struct {
	ID            string            `json:"id,omitempty"`
	Code          string            `json:"code,omitempty"`
	Status        int               `json:"status"`
	Title         string            `json:"title"`
	Detail        string            `json:"detail,omitempty"`
	CorrelationID string            `json:"correlationId,omitempty"`
	Source        map[string]string `json:"source,omitempty"`
	Links         map[string]string `json:"links,omitempty"`
}
