// internal/middleware/tenant.go
package middleware

import (
	"net/http"
)

// TenantMiddleware injects tenantId into the request context.
// This middleware must run after AuthMiddleware to access JWT claims.
func TenantMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tenantID := GetTenantID(r.Context())
		if tenantID == "" {
			http.Error(w, `{"errors":[{"status":403,"title":"Forbidden","detail":"Tenant ID missing or invalid"}]}`, http.StatusForbidden)
			return
		}

		// Tenant ID is already in context via AuthMiddleware; downstream repository calls can use GetTenantID(ctx)
		next.ServeHTTP(w, r)
	})
}
