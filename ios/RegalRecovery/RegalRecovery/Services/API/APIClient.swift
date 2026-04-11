import Foundation
import OSLog

// MARK: - Auth Token Provider Protocol

/// Abstraction for token storage so APIClient does not depend on a concrete auth service.
protocol AuthTokenProvider: Sendable {
    /// Current access token, or nil if not authenticated.
    var accessToken: String? { get async }
    /// Current refresh token, or nil if not available.
    var refreshToken: String? { get async }
    /// Persist new tokens after a successful refresh.
    func updateTokens(accessToken: String, refreshToken: String, expiresIn: Int) async
    /// Clear all stored tokens (e.g., on 401 after refresh failure).
    func clearTokens() async
}

// MARK: - API Client Configuration

struct APIClientConfiguration: Sendable {
    let baseURL: URL
    let maxRetries: Int
    let initialRetryDelay: TimeInterval
    let requestTimeout: TimeInterval

    static let local = APIClientConfiguration(
        baseURL: URL(string: "http://localhost:8080")!,
        maxRetries: 3,
        initialRetryDelay: 1.0,
        requestTimeout: 30
    )

    static let staging = APIClientConfiguration(
        baseURL: URL(string: "https://api.staging.regalrecovery.com")!,
        maxRetries: 3,
        initialRetryDelay: 1.0,
        requestTimeout: 30
    )

    static let production = APIClientConfiguration(
        baseURL: URL(string: "https://api.regalrecovery.com")!,
        maxRetries: 3,
        initialRetryDelay: 1.0,
        requestTimeout: 30
    )
}

// MARK: - API Client

/// Core HTTP client for Regal Recovery API.
/// Handles Siemens envelope parsing, auth injection, correlation IDs, retry logic, and logging.
final class APIClient: Sendable {

    private let session: URLSession
    let configuration: APIClientConfiguration
    let authProvider: AuthTokenProvider?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "APIClient")

    init(
        configuration: APIClientConfiguration,
        authProvider: AuthTokenProvider? = nil,
        session: URLSession? = nil
    ) {
        self.configuration = configuration
        self.authProvider = authProvider

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = configuration.requestTimeout
            config.waitsForConnectivity = false
            self.session = URLSession(configuration: config)
        }
    }

    // MARK: - Public Request Methods

    /// Perform a GET request that returns a Siemens-enveloped single object.
    func get<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> SiemensResponse<T> {
        return try await request(endpoint)
    }

    /// Perform a GET request that returns a paginated list.
    func getList<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> PaginatedResponse<T> {
        return try await request(endpoint)
    }

    /// Perform a POST request that returns a Siemens-enveloped response.
    func post<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> SiemensResponse<T> {
        return try await request(endpoint)
    }

    /// Perform a POST request that returns no body (204 No Content).
    func postNoContent(_ endpoint: Endpoint) async throws {
        try await requestNoContent(endpoint)
    }

    /// Perform a PUT request that returns a Siemens-enveloped response.
    func put<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> SiemensResponse<T> {
        return try await request(endpoint)
    }

    /// Perform a PATCH request that returns a Siemens-enveloped response.
    func patch<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> SiemensResponse<T> {
        return try await request(endpoint)
    }

    /// Perform a DELETE request that returns no body (204 No Content).
    func delete(_ endpoint: Endpoint) async throws {
        try await requestNoContent(endpoint)
    }

    // MARK: - Token Refresh

    /// Attempt to refresh the access token. Returns true on success.
    func refreshAccessToken() async throws -> Bool {
        guard let authProvider,
              let currentRefreshToken = await authProvider.refreshToken else {
            return false
        }

        let endpoint = Endpoint.refreshToken(RefreshTokenRequest(refreshToken: currentRefreshToken))
        let urlRequest = try await buildURLRequest(for: endpoint, includeAuth: false)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }

        guard httpResponse.statusCode == 200 else {
            // Refresh token is invalid/expired; clear tokens
            await authProvider.clearTokens()
            return false
        }

        let refreshResponse = try decoder.decode(SiemensResponse<RefreshTokenData>.self, from: data)
        await authProvider.updateTokens(
            accessToken: refreshResponse.data.accessToken,
            refreshToken: refreshResponse.data.refreshToken,
            expiresIn: refreshResponse.data.expiresIn
        )
        return true
    }

    // MARK: - Internal Request Pipeline

    private func request<T: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = try await buildURLRequest(for: endpoint, includeAuth: endpoint.requiresAuth)
        return try await executeWithRetry(urlRequest, endpoint: endpoint)
    }

    private func requestNoContent(_ endpoint: Endpoint) async throws {
        let urlRequest = try await buildURLRequest(for: endpoint, includeAuth: endpoint.requiresAuth)
        let _: EmptyResponse = try await executeWithRetry(urlRequest, endpoint: endpoint, allowEmpty: true)
    }

    private func executeWithRetry<T: Decodable & Sendable>(
        _ urlRequest: URLRequest,
        endpoint: Endpoint,
        allowEmpty: Bool = false,
        attempt: Int = 0
    ) async throws -> T {
        let correlationId = urlRequest.value(forHTTPHeaderField: "X-Correlation-Id") ?? "unknown"

        do {
            #if DEBUG
            logRequest(urlRequest, correlationId: correlationId)
            #endif

            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError(URLError(.badServerResponse))
            }

            #if DEBUG
            logResponse(httpResponse, data: data, correlationId: correlationId)
            #endif

            // 204 No Content
            if httpResponse.statusCode == 204, allowEmpty {
                // Return a sentinel empty response
                if let empty = EmptyResponse() as? T {
                    return empty
                }
                throw APIError.decodingError(
                    DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Expected empty response"))
                )
            }

            // Success range
            if (200..<300).contains(httpResponse.statusCode) {
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            }

            // Error handling
            let apiError = try mapHTTPError(statusCode: httpResponse.statusCode, data: data, response: httpResponse)

            // 401 - attempt token refresh once
            if httpResponse.statusCode == 401, endpoint.requiresAuth, attempt == 0 {
                let refreshed = try await refreshAccessToken()
                if refreshed {
                    // Rebuild request with new token
                    let retryRequest = try await buildURLRequest(for: endpoint, includeAuth: true)
                    return try await executeWithRetry(retryRequest, endpoint: endpoint, allowEmpty: allowEmpty, attempt: 1)
                }
            }

            // Retry for 429 / 503
            if apiError.isRetryable, attempt < configuration.maxRetries {
                let delay = retryDelay(for: apiError, attempt: attempt, response: httpResponse)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(urlRequest, endpoint: endpoint, allowEmpty: allowEmpty, attempt: attempt + 1)
            }

            throw apiError

        } catch let error as APIError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw APIError.offline
            }
            if error.code == .cancelled {
                throw APIError.cancelled
            }
            if error.isRetryable, attempt < configuration.maxRetries {
                let delay = configuration.initialRetryDelay * pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await executeWithRetry(urlRequest, endpoint: endpoint, allowEmpty: allowEmpty, attempt: attempt + 1)
            }
            throw APIError.networkError(error)
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Request Building

    private func buildURLRequest(for endpoint: Endpoint, includeAuth: Bool) async throws -> URLRequest {
        var components = URLComponents(url: configuration.baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)!
        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            throw APIError.networkError(URLError(.badURL))
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-Id")

        if let body = endpoint.body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        if includeAuth, let authProvider, let token = await authProvider.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Error Mapping

    private func mapHTTPError(statusCode: Int, data: Data, response: HTTPURLResponse) throws -> APIError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            let message = parseErrorMessage(from: data) ?? "A conflict occurred."
            return .conflict(message: message)
        case 412:
            return .preconditionFailed
        case 422:
            let errors = parseErrors(from: data)
            return .validationFailed(errors: errors)
        case 429:
            let retryAfter = parseRetryAfter(response)
            return .rateLimited(retryAfter: retryAfter)
        case 500..<600:
            let message = parseErrorMessage(from: data) ?? "An unexpected server error occurred."
            return .serverError(statusCode: statusCode, message: message)
        default:
            let message = parseErrorMessage(from: data) ?? "HTTP \(statusCode)"
            return .serverError(statusCode: statusCode, message: message)
        }
    }

    private func parseErrors(from data: Data) -> [SiemensError] {
        (try? decoder.decode(SiemensErrorResponse.self, from: data))?.errors ?? []
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let errorResponse = try? decoder.decode(SiemensErrorResponse.self, from: data),
              let firstError = errorResponse.errors.first else {
            return nil
        }
        return firstError.detail ?? firstError.title
    }

    private func parseRetryAfter(_ response: HTTPURLResponse) -> TimeInterval {
        if let retryString = response.value(forHTTPHeaderField: "Retry-After"),
           let seconds = TimeInterval(retryString) {
            return seconds
        }
        return 60 // Default per spec
    }

    // MARK: - Retry Logic

    private func retryDelay(for error: APIError, attempt: Int, response: HTTPURLResponse) -> TimeInterval {
        if case .rateLimited(let retryAfter) = error {
            return retryAfter
        }
        // Exponential backoff with jitter
        let base = configuration.initialRetryDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.5)
        return base + jitter
    }

    // MARK: - Logging

    #if DEBUG
    private func logRequest(_ request: URLRequest, correlationId: String) {
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        logger.debug("[\(correlationId)] --> \(method) \(url)")
        if let body = request.httpBody, body.count < 4096,
           let bodyString = String(data: body, encoding: .utf8) {
            logger.debug("[\(correlationId)] Body: \(bodyString)")
        }
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, correlationId: String) {
        let status = response.statusCode
        let size = data.count
        logger.debug("[\(correlationId)] <-- \(status) (\(size) bytes)")
        if status >= 400, data.count < 4096,
           let bodyString = String(data: data, encoding: .utf8) {
            logger.debug("[\(correlationId)] Error body: \(bodyString)")
        }
    }
    #endif
}

// MARK: - Helper Types

/// Sentinel type for 204 No Content responses.
struct EmptyResponse: Decodable, Sendable {
    init() {}
    init(from decoder: Decoder) throws {}
}

/// Type-erased Encodable wrapper so we can encode any Endpoint body.
private struct AnyEncodable: Encodable {
    private let _encode: @Sendable (Encoder) throws -> Void

    init(_ value: any Encodable & Sendable) {
        self._encode = { encoder in
            try value.encode(to: encoder)
        }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}

// MARK: - URLError Retryable Extension

private extension URLError {
    var isRetryable: Bool {
        switch code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}
