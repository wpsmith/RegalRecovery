import Foundation

// MARK: - API Error Types

/// Typed errors for all API failure modes, mapped from Siemens error responses.
enum APIError: LocalizedError, Sendable {
    /// 401 - Access token missing, invalid, or expired
    case unauthorized
    /// 403 - Insufficient permissions
    case forbidden
    /// 404 - Resource does not exist
    case notFound
    /// 409 - Duplicate or concurrent modification conflict
    case conflict(message: String)
    /// 412 - ETag mismatch (optimistic locking failure)
    case preconditionFailed
    /// 422 - Validation failure with Siemens error detail
    case validationFailed(errors: [SiemensError])
    /// 429 - Rate limit exceeded; retry after the given interval
    case rateLimited(retryAfter: TimeInterval)
    /// 5xx - Server-side failure
    case serverError(statusCode: Int, message: String)
    /// Transport-level failure (DNS, TLS, timeout, etc.)
    case networkError(Error)
    /// Response body could not be decoded into the expected type
    case decodingError(Error)
    /// Device has no network connectivity
    case offline
    /// Request was explicitly cancelled
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .forbidden:
            return "You don't have permission to perform this action."
        case .notFound:
            return "The requested resource was not found."
        case .conflict(let message):
            return message
        case .preconditionFailed:
            return "This resource was modified by another session. Please refresh and try again."
        case .validationFailed(let errors):
            let details = errors.map { $0.detail ?? $0.title }.joined(separator: "; ")
            return details.isEmpty ? "Validation failed." : details
        case .rateLimited(let retryAfter):
            return "Too many requests. Please try again in \(Int(retryAfter)) seconds."
        case .serverError(_, let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError(let error):
            return "Failed to process server response: \(error.localizedDescription)"
        case .offline:
            return "No internet connection. Changes will sync when you're back online."
        case .cancelled:
            return "Request was cancelled."
        }
    }

    /// Whether this error is transient and the request should be retried.
    var isRetryable: Bool {
        switch self {
        case .rateLimited, .serverError(503, _), .networkError, .offline:
            return true
        default:
            return false
        }
    }
}

// MARK: - Siemens Error Object

/// Individual error object conforming to Siemens REST API Guidelines [304, 305].
struct SiemensError: Codable, Sendable, Identifiable {
    let id: String?
    let code: String?
    let status: Int
    let title: String
    let detail: String?
    let correlationId: String?
    let source: ErrorSource?
    let links: ErrorLinks?

    struct ErrorSource: Codable, Sendable {
        let pointer: String?
        let parameter: String?
        let header: String?
    }

    struct ErrorLinks: Codable, Sendable {
        let about: String?
    }
}

/// Siemens error envelope - top-level response when `errors` is present.
/// Per Siemens guidelines, `errors` and `data` MUST NOT coexist.
struct SiemensErrorResponse: Codable, Sendable {
    let errors: [SiemensError]
}
