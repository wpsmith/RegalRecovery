// internal/middleware/correlation.go
package middleware

import (
	"context"
	"net/http"

	"github.com/google/uuid"
)

const (
	ctxKeyCorrelationID ctxKey = 100 // Use a distinct value to avoid collision with other keys
	headerCorrelationID        = "X-Correlation-Id"
)

// CorrelationMiddleware reads or generates a correlation ID and injects it into context and response headers.
func CorrelationMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		correlationID := r.Header.Get(headerCorrelationID)
		if correlationID == "" {
			correlationID = uuid.New().String()
		}

		// Add correlation ID to response headers
		w.Header().Set(headerCorrelationID, correlationID)

		// Inject into context
		ctx := context.WithValue(r.Context(), ctxKeyCorrelationID, correlationID)

		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// GetCorrelationID retrieves the correlation ID from context.
func GetCorrelationID(ctx context.Context) string {
	if v := ctx.Value(ctxKeyCorrelationID); v != nil {
		if id, ok := v.(string); ok {
			return id
		}
	}
	return ""
}
