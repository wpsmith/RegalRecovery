// internal/middleware/auth.go
package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

// ctxKey is a private type for context keys to avoid collisions.
type ctxKey int

const (
	ctxKeyUserID ctxKey = iota
	ctxKeyTenantID
	ctxKeyEmail
)

// JWTClaims represents the expected JWT claims structure from AWS Cognito.
type JWTClaims struct {
	Sub          string `json:"sub"`
	Email        string `json:"email"`
	CustomTenant string `json:"custom:tenantId"`
	jwt.RegisteredClaims
}

// AuthMiddleware validates the JWT Bearer token and extracts claims into context.
// For local development, accepts "dev-token" and injects hardcoded dev user.
func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			http.Error(w, `{"errors":[{"status":401,"title":"Unauthorized","detail":"Missing Authorization header"}]}`, http.StatusUnauthorized)
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			http.Error(w, `{"errors":[{"status":401,"title":"Unauthorized","detail":"Invalid Authorization header format"}]}`, http.StatusUnauthorized)
			return
		}

		tokenString := parts[1]

		// Local dev bypass: if token is "dev-token", inject hardcoded dev user
		if tokenString == "dev-token" {
			ctx := context.WithValue(r.Context(), ctxKeyUserID, "u_alex")
			ctx = context.WithValue(ctx, ctxKeyTenantID, "DEFAULT")
			ctx = context.WithValue(ctx, ctxKeyEmail, "alex@dev.local")
			next.ServeHTTP(w, r.WithContext(ctx))
			return
		}

		// Parse and validate JWT (no signature verification for now; in production, verify with Cognito JWKS)
		token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
			// In production, fetch public key from Cognito JWKS endpoint
			// For now, we skip signature validation (local dev scenario)
			return []byte(""), nil
		})

		if err != nil || !token.Valid {
			http.Error(w, `{"errors":[{"status":401,"title":"Unauthorized","detail":"Invalid or expired token"}]}`, http.StatusUnauthorized)
			return
		}

		claims, ok := token.Claims.(*JWTClaims)
		if !ok || claims.Sub == "" {
			http.Error(w, `{"errors":[{"status":401,"title":"Unauthorized","detail":"Invalid token claims"}]}`, http.StatusUnauthorized)
			return
		}

		// Inject claims into context
		ctx := context.WithValue(r.Context(), ctxKeyUserID, claims.Sub)
		ctx = context.WithValue(ctx, ctxKeyTenantID, claims.CustomTenant)
		ctx = context.WithValue(ctx, ctxKeyEmail, claims.Email)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// GetUserID retrieves the authenticated user ID from context.
func GetUserID(ctx context.Context) string {
	if v := ctx.Value(ctxKeyUserID); v != nil {
		if userID, ok := v.(string); ok {
			return userID
		}
	}
	return ""
}

// GetTenantID retrieves the tenant ID from context.
func GetTenantID(ctx context.Context) string {
	if v := ctx.Value(ctxKeyTenantID); v != nil {
		if tenantID, ok := v.(string); ok {
			return tenantID
		}
	}
	return ""
}

// GetEmail retrieves the user email from context.
func GetEmail(ctx context.Context) string {
	if v := ctx.Value(ctxKeyEmail); v != nil {
		if email, ok := v.(string); ok {
			return email
		}
	}
	return ""
}
