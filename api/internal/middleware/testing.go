// internal/middleware/testing.go
package middleware

import "context"

// Test context key aliases for use in test code.
// These allow test files in other packages to inject auth context values.
var (
	TestKeyUserID        = ctxKeyUserID
	TestKeyTenantID      = ctxKeyTenantID
	TestKeyCorrelationID = ctxKeyCorrelationID
)

// WithTestAuth creates a context with test user/tenant values for handler tests.
func WithTestAuth(ctx context.Context, userID, tenantID string) context.Context {
	ctx = context.WithValue(ctx, ctxKeyUserID, userID)
	ctx = context.WithValue(ctx, ctxKeyTenantID, tenantID)
	return ctx
}

// WithTestCorrelation creates a context with a test correlation ID.
func WithTestCorrelation(ctx context.Context, correlationID string) context.Context {
	return context.WithValue(ctx, ctxKeyCorrelationID, correlationID)
}
