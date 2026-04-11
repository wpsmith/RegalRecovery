import Foundation
import UIKit

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case registrationFailed(String)
    case tokenRefreshFailed
    case noRefreshToken
    case networkError(Error)
    case serverError(Int, String)
    case socialLoginFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .registrationFailed(let detail):
            return "Registration failed: \(detail)"
        case .tokenRefreshFailed:
            return "Session expired. Please sign in again."
        case .noRefreshToken:
            return "No active session. Please sign in."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message
        case .socialLoginFailed(let provider):
            return "\(provider) sign-in failed. Please try again."
        }
    }
}

// MARK: - API Response Types

private struct AuthTokenResponse: Codable {
    struct Data: Codable {
        let userId: String?
        let email: String?
        let displayName: String?
        let accessToken: String
        let refreshToken: String
        let expiresIn: Int
        let tokenType: String
    }
    let data: Data
}

// MARK: - Auth Service

@Observable
final class AuthService: @unchecked Sendable {

    var isAuthenticated = false
    var currentUser: AuthUser?
    var accessToken: String?

    private var refreshToken: String?
    private var tokenExpiryDate: Date?
    private let baseURL: URL
    private let urlSession: URLSession
    private let isDevMode: Bool

    init(
        baseURL: URL = URL(string: "https://api.regalrecovery.com")!,
        urlSession: URLSession = .shared
    ) {
        #if DEBUG
        if let devURL = ProcessInfo.processInfo.environment["RR_API_BASE_URL"],
           let url = URL(string: devURL) {
            self.baseURL = url
        } else {
            self.baseURL = URL(string: "http://localhost:8080")!
        }
        self.isDevMode = ProcessInfo.processInfo.environment["RR_DEV_MODE"] == "1"
        #else
        self.baseURL = baseURL
        self.isDevMode = false
        #endif

        self.urlSession = urlSession

        restoreSession()
    }

    // MARK: - Registration

    @discardableResult
    func register(name: String, email: String, password: String) async throws -> AuthUser {
        if isDevMode {
            return applyDevUser()
        }

        let body: [String: Any] = [
            "email": email,
            "password": password,
            "displayName": name,
            "primaryAddiction": "sex-addiction",
            "sobrietyStartDate": ISO8601DateFormatter.string(
                from: Date(), timeZone: .current, formatOptions: .withFullDate
            )
        ]

        var request = makeRequest(path: "/v1/auth/register", method: "POST")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = try validateResponse(data: data, response: response)

        guard httpResponse.statusCode == 201 else {
            throw AuthError.registrationFailed(extractErrorMessage(from: data))
        }

        let tokenResponse = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
        let user = AuthUser(
            id: tokenResponse.data.userId ?? "",
            email: tokenResponse.data.email ?? email,
            name: tokenResponse.data.displayName ?? name,
            tenantId: "default"
        )

        storeTokens(
            access: tokenResponse.data.accessToken,
            refresh: tokenResponse.data.refreshToken,
            expiresIn: tokenResponse.data.expiresIn
        )
        storeUser(user)
        return user
    }

    // MARK: - Email/Password Login

    @discardableResult
    func login(email: String, password: String) async throws -> AuthUser {
        if isDevMode || (email == "dev@regalrecovery.com" && password == "dev-token") {
            return applyDevUser()
        }

        let body: [String: String] = [
            "email": email,
            "password": password,
            "deviceId": deviceId,
            "deviceName": deviceName
        ]

        var request = makeRequest(path: "/v1/auth/login", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = try validateResponse(data: data, response: response)

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw AuthError.invalidCredentials
            }
            throw AuthError.serverError(httpResponse.statusCode, extractErrorMessage(from: data))
        }

        let tokenResponse = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
        let user = AuthUser(
            id: tokenResponse.data.userId ?? "",
            email: tokenResponse.data.email ?? email,
            name: tokenResponse.data.displayName ?? "",
            tenantId: "default"
        )

        storeTokens(
            access: tokenResponse.data.accessToken,
            refresh: tokenResponse.data.refreshToken,
            expiresIn: tokenResponse.data.expiresIn
        )
        storeUser(user)
        return user
    }

    // MARK: - Social Login

    @discardableResult
    func loginWithApple(identityToken: Data) async throws -> AuthUser {
        if isDevMode {
            return applyDevUser()
        }

        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.socialLoginFailed("Apple")
        }

        let body: [String: String] = [
            "provider": "apple",
            "identityToken": tokenString,
            "deviceId": deviceId,
            "deviceName": deviceName
        ]

        return try await performSocialLogin(body: body, provider: "Apple")
    }

    @discardableResult
    func loginWithGoogle(idToken: String) async throws -> AuthUser {
        if isDevMode {
            return applyDevUser()
        }

        let body: [String: String] = [
            "provider": "google",
            "idToken": idToken,
            "deviceId": deviceId,
            "deviceName": deviceName
        ]

        return try await performSocialLogin(body: body, provider: "Google")
    }

    // MARK: - Logout

    func logout() async {
        if let refresh = refreshToken {
            var request = makeRequest(path: "/auth/logout", method: "POST")
            let body = ["refreshToken": refresh]
            request.httpBody = try? JSONEncoder().encode(body)
            if let token = accessToken {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            _ = try? await urlSession.data(for: request)
        }

        clearSession()
    }

    // MARK: - Token Management

    func refreshTokenIfNeeded() async throws {
        guard let expiry = tokenExpiryDate else {
            throw AuthError.noRefreshToken
        }

        // Refresh if token expires within 60 seconds
        guard Date().addingTimeInterval(60) >= expiry else { return }

        try await refreshToken()
    }

    func refreshToken() async throws {
        guard let refresh = refreshToken else {
            throw AuthError.noRefreshToken
        }

        if isDevMode {
            storeTokens(access: "dev-token", refresh: "dev-refresh", expiresIn: 900)
            return
        }

        let body = ["refreshToken": refresh]
        var request = makeRequest(path: "/v1/auth/refresh", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = try validateResponse(data: data, response: response)

        guard httpResponse.statusCode == 200 else {
            clearSession()
            throw AuthError.tokenRefreshFailed
        }

        let tokenResponse = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
        storeTokens(
            access: tokenResponse.data.accessToken,
            refresh: tokenResponse.data.refreshToken,
            expiresIn: tokenResponse.data.expiresIn
        )
    }

    func getAccessToken() async throws -> String {
        try await refreshTokenIfNeeded()

        guard let token = accessToken else {
            throw AuthError.noRefreshToken
        }
        return token
    }

    // MARK: - Private Helpers

    private func performSocialLogin(body: [String: String], provider: String) async throws -> AuthUser {
        var request = makeRequest(path: "/v1/auth/login", method: "POST")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = try validateResponse(data: data, response: response)

        guard httpResponse.statusCode == 200 else {
            throw AuthError.socialLoginFailed(provider)
        }

        let tokenResponse = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
        let user = AuthUser(
            id: tokenResponse.data.userId ?? "",
            email: tokenResponse.data.email ?? "",
            name: tokenResponse.data.displayName ?? "",
            tenantId: "default"
        )

        storeTokens(
            access: tokenResponse.data.accessToken,
            refresh: tokenResponse.data.refreshToken,
            expiresIn: tokenResponse.data.expiresIn
        )
        storeUser(user)
        return user
    }

    private func makeRequest(path: String, method: String) -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("1.0.0", forHTTPHeaderField: "Api-Version")
        return request
    }

    private func validateResponse(data: Data, response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError(
                NSError(domain: "AuthService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid response"
                ])
            )
        }
        return httpResponse
    }

    private func extractErrorMessage(from data: Data) -> String {
        struct ErrorEnvelope: Codable {
            struct ErrorItem: Codable {
                let detail: String?
                let title: String?
            }
            let errors: [ErrorItem]?
        }

        if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data),
           let first = envelope.errors?.first {
            return first.detail ?? first.title ?? "Unknown error"
        }
        return "Unknown error"
    }

    // MARK: - Session Persistence

    private func storeTokens(access: String, refresh: String, expiresIn: Int) {
        accessToken = access
        refreshToken = refresh
        tokenExpiryDate = Date().addingTimeInterval(TimeInterval(expiresIn))
        isAuthenticated = true

        KeychainHelper.saveString(access, forKey: KeychainHelper.Keys.accessToken)
        KeychainHelper.saveString(refresh, forKey: KeychainHelper.Keys.refreshToken)
        if let expiryData = try? JSONEncoder().encode(tokenExpiryDate) {
            KeychainHelper.save(key: KeychainHelper.Keys.tokenExpiry, data: expiryData)
        }
    }

    private func storeUser(_ user: AuthUser) {
        currentUser = user
        KeychainHelper.saveCodable(user, forKey: KeychainHelper.Keys.currentUser)
    }

    private func restoreSession() {
        guard let access = KeychainHelper.readString(forKey: KeychainHelper.Keys.accessToken),
              let refresh = KeychainHelper.readString(forKey: KeychainHelper.Keys.refreshToken),
              let user = KeychainHelper.readCodable(AuthUser.self, forKey: KeychainHelper.Keys.currentUser)
        else { return }

        accessToken = access
        refreshToken = refresh
        currentUser = user
        isAuthenticated = true

        if let expiryData = KeychainHelper.read(key: KeychainHelper.Keys.tokenExpiry),
           let expiry = try? JSONDecoder().decode(Date.self, from: expiryData) {
            tokenExpiryDate = expiry
        }
    }

    // MARK: - Token Provider Bridge (used by APIClient's AuthTokenProvider)

    /// The current refresh token, exposed for the AuthServiceTokenProvider adapter.
    var currentRefreshToken: String? { refreshToken }

    /// Update tokens from an external token refresh (e.g., APIClient automatic refresh).
    func updateTokens(access: String, refresh: String) {
        storeTokens(access: access, refresh: refresh, expiresIn: 900)
    }

    /// Clear all auth state. Called when token refresh fails.
    func signOut() {
        clearSession()
    }

    private func clearSession() {
        accessToken = nil
        refreshToken = nil
        tokenExpiryDate = nil
        currentUser = nil
        isAuthenticated = false
        KeychainHelper.deleteAll()
    }

    @discardableResult
    private func applyDevUser() -> AuthUser {
        let user = AuthUser(
            id: "u_dev_alex",
            email: "alex@regalrecovery.com",
            name: "Alex",
            tenantId: "default"
        )
        storeTokens(access: "dev-token", refresh: "dev-refresh", expiresIn: 900)
        storeUser(user)
        return user
    }

    private var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    private var deviceName: String {
        UIDevice.current.name
    }
}
