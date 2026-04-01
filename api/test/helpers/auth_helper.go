// test/helpers/auth_helper.go
package helpers

import (
	"context"
)

// AuthClaims represents the authentication claims stored in context during testing.
type AuthClaims struct {
	UserID   string
	TenantID string
	Email    string
}

type contextKey string

const authClaimsKey contextKey = "authClaims"

// TestUserContext creates a context with authentication claims for testing.
// This simulates an authenticated user making a request with the given userID and tenantID.
func TestUserContext(userID, tenantID string) context.Context {
	claims := &AuthClaims{
		UserID:   userID,
		TenantID: tenantID,
	}
	return context.WithValue(context.Background(), authClaimsKey, claims)
}

// TestUserContextWithEmail creates a context with authentication claims including email.
func TestUserContextWithEmail(userID, tenantID, email string) context.Context {
	claims := &AuthClaims{
		UserID:   userID,
		TenantID: tenantID,
		Email:    email,
	}
	return context.WithValue(context.Background(), authClaimsKey, claims)
}

// GetAuthClaims retrieves authentication claims from context.
// Returns nil if no claims are present.
func GetAuthClaims(ctx context.Context) *AuthClaims {
	claims, ok := ctx.Value(authClaimsKey).(*AuthClaims)
	if !ok {
		return nil
	}
	return claims
}

// DevToken returns a static development token for local auth bypass.
// This token is recognized by the local auth middleware as a valid test credential.
func DevToken() string {
	return "dev-token"
}
