// internal/middleware/mood_feature_flag.go
package middleware

import (
	"net/http"
)

// FeatureFlagChecker is a function that evaluates whether a feature flag is enabled
// for the current request context.
type FeatureFlagChecker func(r *http.Request, flagKey string) bool

// MoodFeatureFlagMiddleware checks that the "activity.mood" feature flag is enabled.
// When disabled, all mood endpoints return 404 (fail closed).
func MoodFeatureFlagMiddleware(checker FeatureFlagChecker) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if !checker(r, "activity.mood") {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusNotFound)
				_, _ = w.Write([]byte(`{"errors":[{"status":404,"title":"Not Found","detail":"This feature is not available."}]}`))
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
