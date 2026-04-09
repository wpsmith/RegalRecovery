import Foundation
import OSLog

// MARK: - Affirmation API Error

/// Domain-specific errors for the affirmations API, complementing the generic APIError.
enum AffirmationAPIError: LocalizedError, Sendable {
    /// Feature flag `activity.affirmations` is disabled (rr:0x000A0001).
    case featureDisabled
    /// Affirmation not found (rr:0x000A0002).
    case affirmationNotFound
    /// SOS session not found (rr:0x000A0003).
    case sosSessionNotFound
    /// Custom affirmation not found (rr:0x000A0004).
    case customAffirmationNotFound
    /// Audio recording not found (rr:0x000A0005).
    case audioRecordingNotFound
    /// Day 14 sobriety gate not met (rr:0x000A0010).
    case sobrietyGateNotMet(detail: String)
    /// 24-hour edit window expired (rr:0x000A0011).
    case editWindowExpired
    /// 30-day minimum at current level not met for upgrade (rr:0x000A0012).
    case upgradeNotEligible
    /// Healthy Sexuality requires 60+ sobriety days (rr:0x000A0013).
    case healthySexualityGateNotMet
    /// Cannot upgrade beyond Level 4 (rr:0x000A0014).
    case cannotUpgradeBeyondMax
    /// Cannot downgrade below Level 1 (rr:0x000A0015).
    case cannotDowngradeBelowMin
    /// Invalid audio format (rr:0x000A0020).
    case invalidAudioFormat
    /// Audio recording exceeds 60-second limit (rr:0x000A0021).
    case audioTooLong
    /// Audio file too large (rr:0x000A0022).
    case audioFileTooLarge
    /// Invalid day rating (rr:0x000A0030).
    case invalidDayRating
    /// Affirmation already favorited (rr:0x000A0031).
    case alreadyFavorited
    /// Affirmation already hidden (rr:0x000A0032).
    case alreadyHidden
    /// Affirmation not in favorites (rr:0x000A0033).
    case notInFavorites
    /// Affirmation not hidden (rr:0x000A0034).
    case notHidden
    /// Internal affirmation service error (rr:0x000A00FF).
    case internalError(message: String)
    /// Wraps a generic APIError for pass-through.
    case apiError(APIError)
    /// Unexpected error code from server.
    case unknown(code: String, detail: String?)

    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "Affirmations feature is currently unavailable."
        case .affirmationNotFound:
            return "The requested affirmation could not be found."
        case .sosSessionNotFound:
            return "The SOS session could not be found."
        case .customAffirmationNotFound:
            return "The custom affirmation could not be found."
        case .audioRecordingNotFound:
            return "The audio recording could not be found."
        case .sobrietyGateNotMet(let detail):
            return detail
        case .editWindowExpired:
            return "The 24-hour edit window for this affirmation has expired."
        case .upgradeNotEligible:
            return "You need 30 or more days at your current level before upgrading."
        case .healthySexualityGateNotMet:
            return "The Healthy Sexuality category requires 60 or more sobriety days."
        case .cannotUpgradeBeyondMax:
            return "You are already at the highest level."
        case .cannotDowngradeBelowMin:
            return "You are already at the lowest level."
        case .invalidAudioFormat:
            return "Audio must be in AAC .m4a format."
        case .audioTooLong:
            return "Audio recording cannot exceed 60 seconds."
        case .audioFileTooLarge:
            return "The audio file is too large to upload."
        case .invalidDayRating:
            return "Day rating must be between 1 and 5."
        case .alreadyFavorited:
            return "This affirmation is already in your favorites."
        case .alreadyHidden:
            return "This affirmation is already hidden."
        case .notInFavorites:
            return "This affirmation is not in your favorites."
        case .notHidden:
            return "This affirmation is not hidden."
        case .internalError(let message):
            return message
        case .apiError(let error):
            return error.errorDescription
        case .unknown(_, let detail):
            return detail ?? "An unexpected error occurred."
        }
    }

    /// Map a server error code to a domain-specific error.
    static func fromErrorCode(_ code: String, detail: String?) -> AffirmationAPIError {
        switch code {
        case "rr:0x000A0001": return .featureDisabled
        case "rr:0x000A0002": return .affirmationNotFound
        case "rr:0x000A0003": return .sosSessionNotFound
        case "rr:0x000A0004": return .customAffirmationNotFound
        case "rr:0x000A0005": return .audioRecordingNotFound
        case "rr:0x000A0010": return .sobrietyGateNotMet(detail: detail ?? "Day 14 sobriety gate not met.")
        case "rr:0x000A0011": return .editWindowExpired
        case "rr:0x000A0012": return .upgradeNotEligible
        case "rr:0x000A0013": return .healthySexualityGateNotMet
        case "rr:0x000A0014": return .cannotUpgradeBeyondMax
        case "rr:0x000A0015": return .cannotDowngradeBelowMin
        case "rr:0x000A0020": return .invalidAudioFormat
        case "rr:0x000A0021": return .audioTooLong
        case "rr:0x000A0022": return .audioFileTooLarge
        case "rr:0x000A0030": return .invalidDayRating
        case "rr:0x000A0031": return .alreadyFavorited
        case "rr:0x000A0032": return .alreadyHidden
        case "rr:0x000A0033": return .notInFavorites
        case "rr:0x000A0034": return .notHidden
        case "rr:0x000A00FF": return .internalError(message: detail ?? "Internal affirmation service error.")
        default: return .unknown(code: code, detail: detail)
        }
    }
}

// MARK: - Affirmations API Client

/// Hand-written URLSession API client for all 27 affirmation endpoints.
/// Follows the existing APIClient pattern with Siemens envelope parsing.
///
/// All methods are async/throws. Bearer token auth is injected from the shared APIClient.
/// Errors are mapped to `AffirmationAPIError` for domain-specific handling.
final class AffirmationsAPIClient: Sendable {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "AffirmationsAPI")

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: - Base Path

    private static let basePath = "/activities/affirmations"

    // MARK: - Init

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Sessions (4 endpoints)

    /// GET /activities/affirmations/session/morning
    /// Returns a morning session with 3 level-appropriate affirmations and intention prompt.
    func getMorningSession() async throws -> SiemensResponse<MorningSessionData> {
        let endpoint = AffirmationEndpoint.getMorningSession
        return try await performRequest(endpoint)
    }

    /// POST /activities/affirmations/session/morning
    /// Records completion of a morning session.
    func completeMorningSession(_ request: CompleteMorningRequest) async throws -> SiemensResponse<SessionCompletionData> {
        let endpoint = AffirmationEndpoint.completeMorningSession(request)
        return try await performRequest(endpoint)
    }

    /// GET /activities/affirmations/session/evening
    /// Returns an evening session with one calming affirmation and optional morning intention.
    func getEveningSession() async throws -> SiemensResponse<EveningSessionData> {
        let endpoint = AffirmationEndpoint.getEveningSession
        return try await performRequest(endpoint)
    }

    /// POST /activities/affirmations/session/evening
    /// Records completion of an evening session.
    func completeEveningSession(_ request: CompleteEveningRequest) async throws -> SiemensResponse<SessionCompletionData> {
        let endpoint = AffirmationEndpoint.completeEveningSession(request)
        return try await performRequest(endpoint)
    }

    // MARK: - SOS Mode (2 endpoints)

    /// POST /activities/affirmations/sos
    /// Starts an SOS crisis session with Level 1-2 affirmations and 4-7-8 breathing.
    func startSOSSession() async throws -> SiemensResponse<SOSSessionData> {
        let endpoint = AffirmationEndpoint.startSOSSession
        return try await performRequest(endpoint)
    }

    /// POST /activities/affirmations/sos/{sosId}/complete
    /// Records completion of an SOS session.
    func completeSOSSession(sosId: String, request: CompleteSOSRequest) async throws -> SiemensResponse<SessionCompletionData> {
        let endpoint = AffirmationEndpoint.completeSOSSession(sosId: sosId, request: request)
        return try await performRequest(endpoint)
    }

    // MARK: - Library (2 endpoints)

    /// GET /activities/affirmations/library
    /// Browse the curated affirmation library with filtering and pagination.
    func browseLibrary(
        category: AffirmationCategory? = nil,
        level: Int? = nil,
        track: AffirmationTrack? = nil,
        keyword: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> AffirmationListResponse<AffirmationItem> {
        let endpoint = AffirmationEndpoint.browseLibrary(
            category: category,
            level: level,
            track: track,
            keyword: keyword,
            cursor: cursor,
            limit: limit
        )
        return try await performRequest(endpoint)
    }

    /// GET /activities/affirmations/library/{affirmationId}
    /// Retrieve a single affirmation by ID.
    func getAffirmation(id: String) async throws -> SiemensResponse<AffirmationItem> {
        let endpoint = AffirmationEndpoint.getAffirmation(id: id)
        return try await performRequest(endpoint)
    }

    // MARK: - Favorites (3 endpoints)

    /// POST /activities/affirmations/favorites
    /// Add an affirmation to favorites.
    func addFavorite(affirmationId: String) async throws -> SiemensResponse<FavoriteActionData> {
        let endpoint = AffirmationEndpoint.addFavorite(affirmationId: affirmationId)
        return try await performRequest(endpoint)
    }

    /// DELETE /activities/affirmations/favorites/{affirmationId}
    /// Remove an affirmation from favorites.
    func removeFavorite(affirmationId: String) async throws {
        let endpoint = AffirmationEndpoint.removeFavorite(affirmationId: affirmationId)
        try await performNoContentRequest(endpoint)
    }

    /// GET /activities/affirmations/favorites
    /// List all favorited affirmations.
    func listFavorites(cursor: String? = nil, limit: Int? = nil) async throws -> AffirmationListResponse<AffirmationItem> {
        let endpoint = AffirmationEndpoint.listFavorites(cursor: cursor, limit: limit)
        return try await performRequest(endpoint)
    }

    // MARK: - Hidden (3 endpoints)

    /// POST /activities/affirmations/hidden
    /// Hide an affirmation permanently for this user.
    func hideAffirmation(affirmationId: String, sessionId: String? = nil) async throws -> SiemensResponse<HideActionData> {
        let endpoint = AffirmationEndpoint.hideAffirmation(affirmationId: affirmationId, sessionId: sessionId)
        return try await performRequest(endpoint)
    }

    /// DELETE /activities/affirmations/hidden/{affirmationId}
    /// Un-hide an affirmation.
    func unhideAffirmation(affirmationId: String) async throws {
        let endpoint = AffirmationEndpoint.unhideAffirmation(affirmationId: affirmationId)
        try await performNoContentRequest(endpoint)
    }

    /// GET /activities/affirmations/hidden
    /// List all hidden affirmations.
    func listHidden(cursor: String? = nil, limit: Int? = nil) async throws -> AffirmationListResponse<AffirmationItem> {
        let endpoint = AffirmationEndpoint.listHidden(cursor: cursor, limit: limit)
        return try await performRequest(endpoint)
    }

    // MARK: - Custom Affirmations (4 endpoints)

    /// POST /activities/affirmations/custom
    /// Create a custom affirmation (Day 14+ gate).
    func createCustomAffirmation(_ request: CreateCustomAffirmationRequest) async throws -> SiemensResponse<CustomAffirmation> {
        let endpoint = AffirmationEndpoint.createCustom(request)
        return try await performRequest(endpoint)
    }

    /// GET /activities/affirmations/custom
    /// List all custom affirmations.
    func listCustomAffirmations(cursor: String? = nil, limit: Int? = nil) async throws -> AffirmationListResponse<CustomAffirmation> {
        let endpoint = AffirmationEndpoint.listCustom(cursor: cursor, limit: limit)
        return try await performRequest(endpoint)
    }

    /// PATCH /activities/affirmations/custom/{affirmationId}
    /// Update a custom affirmation (text editable within 24 hours only).
    func updateCustomAffirmation(id: String, request: UpdateCustomAffirmationRequest) async throws -> SiemensResponse<CustomAffirmation> {
        let endpoint = AffirmationEndpoint.updateCustom(id: id, request: request)
        return try await performRequest(endpoint)
    }

    /// DELETE /activities/affirmations/custom/{affirmationId}
    /// Delete a custom affirmation.
    func deleteCustomAffirmation(id: String) async throws {
        let endpoint = AffirmationEndpoint.deleteCustom(id: id)
        try await performNoContentRequest(endpoint)
    }

    // MARK: - Audio Recordings (3 endpoints)

    /// POST /activities/affirmations/{affirmationId}/audio (multipart/form-data)
    /// Upload an own-voice audio recording.
    func uploadAudioRecording(
        affirmationId: String,
        fileData: Data,
        fileName: String,
        backgroundMusic: AffirmationBackgroundMusic
    ) async throws -> SiemensResponse<AudioRecordingMeta> {
        let boundary = "Boundary-\(UUID().uuidString)"
        var body = Data()

        // File part
        body.appendMultipartField(
            name: "file",
            fileName: fileName,
            mimeType: "audio/mp4",
            data: fileData,
            boundary: boundary
        )

        // Background music part
        body.appendMultipartField(
            name: "backgroundMusic",
            value: backgroundMusic.rawValue,
            boundary: boundary
        )

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let path = "\(Self.basePath)/\(affirmationId)/audio"
        let url = apiClient.configuration.baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-Id")
        request.httpBody = body

        if let authProvider = apiClient.authProvider,
           let token = await authProvider.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AffirmationAPIError.apiError(.networkError(URLError(.badServerResponse)))
        }

        if (200..<300).contains(httpResponse.statusCode) {
            return try decoder.decode(SiemensResponse<AudioRecordingMeta>.self, from: data)
        }

        throw try mapError(statusCode: httpResponse.statusCode, data: data)
    }

    /// GET /activities/affirmations/{affirmationId}/audio
    /// Get audio recording metadata and playback URL.
    func getAudioRecording(affirmationId: String) async throws -> SiemensResponse<AudioRecordingMeta> {
        let endpoint = AffirmationEndpoint.getAudio(affirmationId: affirmationId)
        return try await performRequest(endpoint)
    }

    /// DELETE /activities/affirmations/{affirmationId}/audio
    /// Delete an audio recording.
    func deleteAudioRecording(affirmationId: String) async throws {
        let endpoint = AffirmationEndpoint.deleteAudio(affirmationId: affirmationId)
        try await performNoContentRequest(endpoint)
    }

    // MARK: - Progress (1 endpoint)

    /// GET /activities/affirmations/progress
    /// Get cumulative progress metrics.
    func getProgress() async throws -> SiemensResponse<AffirmationProgress> {
        let endpoint = AffirmationEndpoint.getProgress
        return try await performRequest(endpoint)
    }

    // MARK: - Settings (2 endpoints)

    /// GET /activities/affirmations/settings
    /// Get affirmation settings.
    func getSettings() async throws -> SiemensResponse<AffirmationSettings> {
        let endpoint = AffirmationEndpoint.getSettings
        return try await performRequest(endpoint)
    }

    /// PATCH /activities/affirmations/settings
    /// Update affirmation settings.
    func updateSettings(_ request: UpdateAffirmationSettingsRequest) async throws -> SiemensResponse<AffirmationSettings> {
        let endpoint = AffirmationEndpoint.updateSettings(request)
        return try await performRequest(endpoint)
    }

    // MARK: - Level (2 endpoints)

    /// GET /activities/affirmations/level
    /// Get current level information.
    func getLevelInfo() async throws -> SiemensResponse<LevelInfo> {
        let endpoint = AffirmationEndpoint.getLevelInfo
        return try await performRequest(endpoint)
    }

    /// POST /activities/affirmations/level/override
    /// Request a level change.
    func requestLevelOverride(_ request: LevelOverrideRequest) async throws -> SiemensResponse<LevelInfo> {
        let endpoint = AffirmationEndpoint.requestLevelOverride(request)
        return try await performRequest(endpoint)
    }

    // MARK: - Sharing (1 endpoint)

    /// GET /activities/affirmations/sharing/summary
    /// Get a privacy-safe sharing summary (session counts only).
    func getSharingSummary() async throws -> SiemensResponse<SharingSummaryData> {
        let endpoint = AffirmationEndpoint.getSharingSummary
        return try await performRequest(endpoint)
    }

    // MARK: - Internal Request Pipeline

    private func performRequest<T: Decodable & Sendable>(_ endpoint: AffirmationEndpoint) async throws -> T {
        do {
            let urlRequest = try await buildURLRequest(for: endpoint)

            #if DEBUG
            let correlationId = urlRequest.value(forHTTPHeaderField: "X-Correlation-Id") ?? "unknown"
            logger.debug("[\(correlationId)] --> \(endpoint.method.rawValue) \(endpoint.path)")
            #endif

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AffirmationAPIError.apiError(.networkError(URLError(.badServerResponse)))
            }

            #if DEBUG
            logger.debug("[\(correlationId)] <-- \(httpResponse.statusCode) (\(data.count) bytes)")
            #endif

            if (200..<300).contains(httpResponse.statusCode) {
                return try decoder.decode(T.self, from: data)
            }

            throw try mapError(statusCode: httpResponse.statusCode, data: data)

        } catch let error as AffirmationAPIError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw AffirmationAPIError.apiError(.offline)
            }
            throw AffirmationAPIError.apiError(.networkError(error))
        } catch let error as DecodingError {
            throw AffirmationAPIError.apiError(.decodingError(error))
        } catch {
            throw AffirmationAPIError.apiError(.networkError(error))
        }
    }

    private func performNoContentRequest(_ endpoint: AffirmationEndpoint) async throws {
        do {
            let urlRequest = try await buildURLRequest(for: endpoint)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AffirmationAPIError.apiError(.networkError(URLError(.badServerResponse)))
            }

            if httpResponse.statusCode == 204 || (200..<300).contains(httpResponse.statusCode) {
                return
            }

            throw try mapError(statusCode: httpResponse.statusCode, data: data)

        } catch let error as AffirmationAPIError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw AffirmationAPIError.apiError(.offline)
            }
            throw AffirmationAPIError.apiError(.networkError(error))
        } catch {
            throw AffirmationAPIError.apiError(.networkError(error))
        }
    }

    // MARK: - Request Building

    private func buildURLRequest(for endpoint: AffirmationEndpoint) async throws -> URLRequest {
        var components = URLComponents(
            url: apiClient.configuration.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )!
        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            throw AffirmationAPIError.apiError(.networkError(URLError(.badURL)))
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Correlation-Id")

        if let body = endpoint.body {
            let contentType = endpoint.method == .patch
                ? "application/merge-patch+json"
                : "application/json"
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
            request.httpBody = try encoder.encode(AnyEncodableWrapper(body))
        }

        if let authProvider = apiClient.authProvider,
           let token = await authProvider.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Error Mapping

    private func mapError(statusCode: Int, data: Data) throws -> AffirmationAPIError {
        // Try to decode affirmation-specific error codes
        if let errorResponse = try? decoder.decode(AffirmationErrorResponse.self, from: data),
           let firstError = errorResponse.errors.first,
           let code = firstError.code {
            return AffirmationAPIError.fromErrorCode(code, detail: firstError.detail)
        }

        // Fall back to generic HTTP error mapping
        switch statusCode {
        case 401: return .apiError(.unauthorized)
        case 403: return .apiError(.forbidden)
        case 404: return .affirmationNotFound
        case 422:
            if let errorResponse = try? decoder.decode(AffirmationErrorResponse.self, from: data) {
                let detail = errorResponse.errors.first?.detail
                return .internalError(message: detail ?? "Validation failed.")
            }
            return .internalError(message: "Validation failed.")
        default:
            return .apiError(.serverError(statusCode: statusCode, message: "HTTP \(statusCode)"))
        }
    }
}

// MARK: - Affirmation Endpoints

/// Type-safe endpoint definitions for all 27 affirmation API operations.
private enum AffirmationEndpoint: Sendable {
    // Sessions
    case getMorningSession
    case completeMorningSession(CompleteMorningRequest)
    case getEveningSession
    case completeEveningSession(CompleteEveningRequest)

    // SOS
    case startSOSSession
    case completeSOSSession(sosId: String, request: CompleteSOSRequest)

    // Library
    case browseLibrary(category: AffirmationCategory?, level: Int?, track: AffirmationTrack?, keyword: String?, cursor: String?, limit: Int?)
    case getAffirmation(id: String)

    // Favorites
    case addFavorite(affirmationId: String)
    case removeFavorite(affirmationId: String)
    case listFavorites(cursor: String?, limit: Int?)

    // Hidden
    case hideAffirmation(affirmationId: String, sessionId: String?)
    case unhideAffirmation(affirmationId: String)
    case listHidden(cursor: String?, limit: Int?)

    // Custom
    case createCustom(CreateCustomAffirmationRequest)
    case listCustom(cursor: String?, limit: Int?)
    case updateCustom(id: String, request: UpdateCustomAffirmationRequest)
    case deleteCustom(id: String)

    // Audio
    case getAudio(affirmationId: String)
    case deleteAudio(affirmationId: String)

    // Progress & Settings
    case getProgress
    case getSettings
    case updateSettings(UpdateAffirmationSettingsRequest)
    case getLevelInfo
    case requestLevelOverride(LevelOverrideRequest)

    // Sharing
    case getSharingSummary

    private static let base = "/activities/affirmations"

    var path: String {
        switch self {
        case .getMorningSession, .completeMorningSession:
            return "\(Self.base)/session/morning"
        case .getEveningSession, .completeEveningSession:
            return "\(Self.base)/session/evening"
        case .startSOSSession:
            return "\(Self.base)/sos"
        case .completeSOSSession(let sosId, _):
            return "\(Self.base)/sos/\(sosId)/complete"
        case .browseLibrary:
            return "\(Self.base)/library"
        case .getAffirmation(let id):
            return "\(Self.base)/library/\(id)"
        case .addFavorite, .listFavorites:
            return "\(Self.base)/favorites"
        case .removeFavorite(let id):
            return "\(Self.base)/favorites/\(id)"
        case .hideAffirmation, .listHidden:
            return "\(Self.base)/hidden"
        case .unhideAffirmation(let id):
            return "\(Self.base)/hidden/\(id)"
        case .createCustom, .listCustom:
            return "\(Self.base)/custom"
        case .updateCustom(let id, _), .deleteCustom(let id):
            return "\(Self.base)/custom/\(id)"
        case .getAudio(let id), .deleteAudio(let id):
            return "\(Self.base)/\(id)/audio"
        case .getProgress:
            return "\(Self.base)/progress"
        case .getSettings, .updateSettings:
            return "\(Self.base)/settings"
        case .getLevelInfo:
            return "\(Self.base)/level"
        case .requestLevelOverride:
            return "\(Self.base)/level/override"
        case .getSharingSummary:
            return "\(Self.base)/sharing/summary"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMorningSession, .getEveningSession,
             .browseLibrary, .getAffirmation,
             .listFavorites, .listHidden, .listCustom,
             .getAudio, .getProgress, .getSettings,
             .getLevelInfo, .getSharingSummary:
            return .get
        case .completeMorningSession, .completeEveningSession,
             .startSOSSession, .completeSOSSession,
             .addFavorite, .hideAffirmation, .createCustom,
             .requestLevelOverride:
            return .post
        case .updateCustom, .updateSettings:
            return .patch
        case .removeFavorite, .unhideAffirmation, .deleteCustom, .deleteAudio:
            return .delete
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        case .completeMorningSession(let req): return req
        case .completeEveningSession(let req): return req
        case .completeSOSSession(_, let req): return req
        case .addFavorite(let id):
            return ["affirmationId": id] as [String: String]
        case .hideAffirmation(let id, let sessionId):
            var dict: [String: String] = ["affirmationId": id]
            if let sessionId { dict["sessionId"] = sessionId }
            return dict
        case .createCustom(let req): return req
        case .updateCustom(_, let req): return req
        case .updateSettings(let req): return req
        case .requestLevelOverride(let req): return req
        default: return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        var items: [URLQueryItem] = []

        switch self {
        case .browseLibrary(let category, let level, let track, let keyword, let cursor, let limit):
            if let category { items.append(.init(name: "category", value: category.rawValue)) }
            if let level { items.append(.init(name: "level", value: String(level))) }
            if let track { items.append(.init(name: "track", value: track.rawValue)) }
            if let keyword { items.append(.init(name: "keyword", value: keyword)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .listFavorites(let cursor, let limit),
             .listHidden(let cursor, let limit),
             .listCustom(let cursor, let limit):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        default:
            break
        }

        return items.isEmpty ? nil : items
    }
}

// MARK: - Type-Erased Encodable Wrapper

private struct AnyEncodableWrapper: Encodable {
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

// MARK: - Data Multipart Helpers

private extension Data {
    mutating func appendMultipartField(name: String, value: String, boundary: String) {
        let fieldString = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n"
        append(fieldString.data(using: .utf8)!)
    }

    mutating func appendMultipartField(name: String, fileName: String, mimeType: String, data: Data, boundary: String) {
        var header = "--\(boundary)\r\n"
        header += "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n"
        header += "Content-Type: \(mimeType)\r\n\r\n"
        append(header.data(using: .utf8)!)
        append(data)
        append("\r\n".data(using: .utf8)!)
    }
}
