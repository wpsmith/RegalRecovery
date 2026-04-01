// internal/middleware/recovery.go
package middleware

import (
	"log/slog"
	"net/http"
	"runtime/debug"
)

// RecoveryMiddleware catches panics, logs stack trace, and returns 500 Internal Server Error.
func RecoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				correlationID := GetCorrelationID(r.Context())

				// Log the panic with stack trace
				slog.Error("panic_recovered",
					slog.String("correlation_id", correlationID),
					slog.Any("error", err),
					slog.String("stack", string(debug.Stack())),
				)

				// Return 500 error response
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusInternalServerError)
				w.Write([]byte(`{"errors":[{"status":500,"title":"Internal Server Error","detail":"An unexpected error occurred"}]}`))
			}
		}()

		next.ServeHTTP(w, r)
	})
}
