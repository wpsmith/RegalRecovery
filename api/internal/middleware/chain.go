// internal/middleware/chain.go
package middleware

import "net/http"

// Chain applies a series of middleware functions to an http.Handler.
// Middlewares are applied in order: the last middleware in the slice is executed first (wrapping innermost).
// Example: Chain(handler, CorrelationMiddleware, LoggingMiddleware, RecoveryMiddleware)
// Execution order: RecoveryMiddleware -> LoggingMiddleware -> CorrelationMiddleware -> handler
func Chain(h http.Handler, middlewares ...func(http.Handler) http.Handler) http.Handler {
	for i := len(middlewares) - 1; i >= 0; i-- {
		h = middlewares[i](h)
	}
	return h
}
