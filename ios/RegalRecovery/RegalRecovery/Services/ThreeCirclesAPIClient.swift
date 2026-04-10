import Foundation
import OSLog

// MARK: - Three Circles API Error

/// Domain-specific errors for the Three Circles API, complementing the generic APIError.
enum ThreeCirclesAPIError: LocalizedError, Sendable {
    /// Feature flag `feature.3circles` is disabled (rr:0x000B0001).
    case featureDisabled
    /// Circle set not found (rr:0x000B0404).
    case circleSetNotFound
    /// Circle item not found (rr:0x000B0002).
    case circleItemNotFound
    /// Version not found (rr:0x000B0003).
    case versionNotFound
    /// Template not found (rr:0x000B0004).
    case templateNotFound
    /// Starter pack not found (rr:0x000B0005).
    case starterPackNotFound
    /// Onboarding flow not found (rr:0x000B0006).
    case onboardingFlowNotFound
    /// Share link not found or expired (rr:0x000B0007).
    case shareLinkNotFound
    /// Share link expired (HTTP 410).
    case shareLinkExpired
    /// Review not found (rr:0x000B0008).
    case reviewNotFound
    /// Drift alert not found (rr:0x000B0009).
    case driftAlertNotFound
    /// Validation error (rr:0x000B0422).
    case validationError(detail: String)
    /// Cannot commit: zero inner circle items (rr:0x000B0010).
    case cannotCommitEmpty
    /// Internal service error (rr:0x000B00FF).
    case internalError(message: String)
    /// Wraps a generic APIError for pass-through.
    case apiError(APIError)
    /// Unexpected error code from server.
    case unknown(code: String, detail: String?)

    var errorDescription: String? {
        switch self {
        case .featureDisabled:
            return "Three Circles feature is currently unavailable."
        case .circleSetNotFound:
            return "The requested circle set could not be found."
        case .circleItemNotFound:
            return "The requested circle item could not be found."
        case .versionNotFound:
            return "The requested version could not be found."
        case .templateNotFound:
            return "The requested template could not be found."
        case .starterPackNotFound:
            return "The requested starter pack could not be found."
        case .onboardingFlowNotFound:
            return "The onboarding session could not be found."
        case .shareLinkNotFound:
            return "The share link could not be found or has expired."
        case .shareLinkExpired:
            return "This share link has expired."
        case .reviewNotFound:
            return "The requested review could not be found."
        case .driftAlertNotFound:
            return "The drift alert could not be found."
        case .validationError(let detail):
            return detail
        case .cannotCommitEmpty:
            return "Cannot commit: at least one inner circle item is required."
        case .internalError(let message):
            return message
        case .apiError(let error):
            return error.errorDescription
        case .unknown(_, let detail):
            return detail ?? "An unexpected error occurred."
        }
    }

    /// Map a server error code to a domain-specific error.
    static func fromErrorCode(_ code: String, detail: String?) -> ThreeCirclesAPIError {
        switch code {
        case "rr:0x000B0001": return .featureDisabled
        case "rr:0x000B0002": return .circleItemNotFound
        case "rr:0x000B0003": return .versionNotFound
        case "rr:0x000B0004": return .templateNotFound
        case "rr:0x000B0005": return .starterPackNotFound
        case "rr:0x000B0006": return .onboardingFlowNotFound
        case "rr:0x000B0007": return .shareLinkNotFound
        case "rr:0x000B0008": return .reviewNotFound
        case "rr:0x000B0009": return .driftAlertNotFound
        case "rr:0x000B0010": return .cannotCommitEmpty
        case "rr:0x000B0404": return .circleSetNotFound
        case "rr:0x000B0401": return .apiError(.unauthorized)
        case "rr:0x000B0422": return .validationError(detail: detail ?? "Validation failed.")
        case "rr:0x000B00FF": return .internalError(message: detail ?? "Internal Three Circles service error.")
        default: return .unknown(code: code, detail: detail)
        }
    }
}

// MARK: - Three Circles API Client

/// Hand-written URLSession API client for all Three Circles endpoints.
/// Follows the existing AffirmationsAPIClient pattern with Siemens envelope parsing.
///
/// All methods are async/throws. Bearer token auth is injected from the shared APIClient.
/// Errors are mapped to `ThreeCirclesAPIError` for domain-specific handling.
final class ThreeCirclesAPIClient: Sendable {

    // MARK: - Dependencies

    private let apiClient: APIClient
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "ThreeCirclesAPI")

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

    private static let basePath = "/tools/three-circles"

    // MARK: - Init

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Circle Sets (5 endpoints)

    /// GET /tools/three-circles/sets
    /// List user's circle sets with optional filtering.
    func listCircleSets(
        status: CircleSetStatus? = nil,
        recoveryArea: RecoveryArea? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> ThreeCirclesListResponse<CircleSet> {
        let endpoint = ThreeCirclesEndpoint.listCircleSets(
            status: status, recoveryArea: recoveryArea, cursor: cursor, limit: limit
        )
        return try await performRequest(endpoint)
    }

    /// POST /tools/three-circles/sets
    /// Create a new circle set.
    func createCircleSet(_ request: CreateCircleSetRequest) async throws -> ThreeCirclesDataResponse<CircleSet> {
        let endpoint = ThreeCirclesEndpoint.createCircleSet(request)
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/sets/{setId}
    /// Get full circle set detail with version history summary and comment count.
    func getCircleSet(setId: String) async throws -> ThreeCirclesDataResponse<CircleSetDetail> {
        let endpoint = ThreeCirclesEndpoint.getCircleSet(setId: setId)
        return try await performRequest(endpoint)
    }

    /// PUT /tools/three-circles/sets/{setId}
    /// Full replace of a circle set. Creates a new version snapshot.
    func replaceCircleSet(setId: String, request: ReplaceCircleSetRequest) async throws -> ThreeCirclesDataResponse<CircleSet> {
        let endpoint = ThreeCirclesEndpoint.replaceCircleSet(setId: setId, request: request)
        return try await performRequest(endpoint)
    }

    /// PATCH /tools/three-circles/sets/{setId}
    /// Partial update of a circle set.
    func updateCircleSet(setId: String, request: UpdateCircleSetRequest) async throws -> ThreeCirclesDataResponse<CircleSet> {
        let endpoint = ThreeCirclesEndpoint.updateCircleSet(setId: setId, request: request)
        return try await performRequest(endpoint)
    }

    /// DELETE /tools/three-circles/sets/{setId}
    /// Soft delete (archive) a circle set.
    func deleteCircleSet(setId: String) async throws {
        let endpoint = ThreeCirclesEndpoint.deleteCircleSet(setId: setId)
        try await performNoContentRequest(endpoint)
    }

    /// POST /tools/three-circles/sets/{setId}/commit
    /// Transition a draft circle set to active status.
    func commitCircleSet(setId: String, request: CommitCircleSetRequest? = nil) async throws -> ThreeCirclesDataResponse<CircleSet> {
        let endpoint = ThreeCirclesEndpoint.commitCircleSet(setId: setId, request: request)
        return try await performRequest(endpoint)
    }

    // MARK: - Circle Items (3 endpoints)

    /// POST /tools/three-circles/sets/{setId}/items
    /// Add an item to a circle.
    func addCircleItem(setId: String, request: CreateCircleItemRequest) async throws -> ThreeCirclesDataResponse<CircleItem> {
        let endpoint = ThreeCirclesEndpoint.addCircleItem(setId: setId, request: request)
        return try await performRequest(endpoint)
    }

    /// PUT /tools/three-circles/sets/{setId}/items/{itemId}
    /// Update an existing circle item.
    func updateCircleItem(setId: String, itemId: String, request: UpdateCircleItemRequest) async throws -> ThreeCirclesDataResponse<CircleItem> {
        let endpoint = ThreeCirclesEndpoint.updateCircleItem(setId: setId, itemId: itemId, request: request)
        return try await performRequest(endpoint)
    }

    /// DELETE /tools/three-circles/sets/{setId}/items/{itemId}
    /// Remove an item from a circle.
    func deleteCircleItem(setId: String, itemId: String) async throws {
        let endpoint = ThreeCirclesEndpoint.deleteCircleItem(setId: setId, itemId: itemId)
        try await performNoContentRequest(endpoint)
    }

    /// POST /tools/three-circles/sets/{setId}/items/{itemId}/move
    /// Move an item between circles.
    func moveCircleItem(setId: String, itemId: String, request: MoveItemRequest) async throws -> ThreeCirclesDataResponse<CircleItem> {
        let endpoint = ThreeCirclesEndpoint.moveCircleItem(setId: setId, itemId: itemId, request: request)
        return try await performRequest(endpoint)
    }

    // MARK: - Version History (3 endpoints)

    /// GET /tools/three-circles/sets/{setId}/versions
    /// List version history for a circle set.
    func listVersions(
        setId: String,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> ThreeCirclesListResponse<VersionListItem> {
        let endpoint = ThreeCirclesEndpoint.listVersions(setId: setId, cursor: cursor, limit: limit)
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/sets/{setId}/versions/{versionId}
    /// Get a specific version snapshot.
    func getVersion(setId: String, versionId: String) async throws -> ThreeCirclesDataResponse<CircleSetVersion> {
        let endpoint = ThreeCirclesEndpoint.getVersion(setId: setId, versionId: versionId)
        return try await performRequest(endpoint)
    }

    /// POST /tools/three-circles/sets/{setId}/versions/{versionId}/restore
    /// Restore a circle set to a previous version.
    func restoreVersion(
        setId: String,
        versionId: String,
        request: RestoreVersionRequest? = nil
    ) async throws -> ThreeCirclesDataResponse<CircleSet> {
        let endpoint = ThreeCirclesEndpoint.restoreVersion(setId: setId, versionId: versionId, request: request)
        return try await performRequest(endpoint)
    }

    // MARK: - Templates (2 endpoints)

    /// GET /tools/three-circles/templates
    /// List templates filtered by recovery area, circle, and framework.
    func listTemplates(
        recoveryArea: RecoveryArea,
        circle: CircleType? = nil,
        framework: FrameworkPreference? = nil
    ) async throws -> ThreeCirclesListResponse<Template> {
        let endpoint = ThreeCirclesEndpoint.listTemplates(
            recoveryArea: recoveryArea, circle: circle, framework: framework
        )
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/templates/{templateId}
    /// Get a single template with full rationale.
    func getTemplate(templateId: String) async throws -> ThreeCirclesDataResponse<Template> {
        let endpoint = ThreeCirclesEndpoint.getTemplate(templateId: templateId)
        return try await performRequest(endpoint)
    }

    // MARK: - Starter Packs (3 endpoints)

    /// GET /tools/three-circles/starter-packs
    /// List starter packs by recovery area and variant.
    func listStarterPacks(
        recoveryArea: RecoveryArea,
        variant: StarterPackVariant? = nil
    ) async throws -> ThreeCirclesListResponse<StarterPackListItem> {
        let endpoint = ThreeCirclesEndpoint.listStarterPacks(recoveryArea: recoveryArea, variant: variant)
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/starter-packs/{packId}
    /// Get a starter pack with all items.
    func getStarterPack(packId: String) async throws -> ThreeCirclesDataResponse<StarterPack> {
        let endpoint = ThreeCirclesEndpoint.getStarterPack(packId: packId)
        return try await performRequest(endpoint)
    }

    /// POST /tools/three-circles/sets/{setId}/apply-starter-pack
    /// Apply a starter pack to an existing circle set.
    func applyStarterPack(
        setId: String,
        request: ApplyStarterPackRequest
    ) async throws -> ThreeCirclesDataResponse<CircleSet> {
        let endpoint = ThreeCirclesEndpoint.applyStarterPack(setId: setId, request: request)
        return try await performRequest(endpoint)
    }

    // MARK: - Onboarding (3 endpoints)

    /// POST /tools/three-circles/onboarding/start
    /// Start an onboarding flow.
    func startOnboarding(
        request: StartOnboardingRequest? = nil
    ) async throws -> ThreeCirclesDataResponse<OnboardingFlow> {
        let endpoint = ThreeCirclesEndpoint.startOnboarding(request: request)
        return try await performRequest(endpoint)
    }

    /// PATCH /tools/three-circles/onboarding/{flowId}
    /// Update onboarding progress.
    func updateOnboarding(
        flowId: String,
        request: UpdateOnboardingRequest
    ) async throws -> ThreeCirclesDataResponse<OnboardingFlow> {
        let endpoint = ThreeCirclesEndpoint.updateOnboarding(flowId: flowId, request: request)
        return try await performRequest(endpoint)
    }

    /// POST /tools/three-circles/onboarding/{flowId}/complete
    /// Complete onboarding and create circle set.
    func completeOnboarding(
        flowId: String,
        request: CompleteOnboardingRequest
    ) async throws -> ThreeCirclesDataResponse<OnboardingCompletionData> {
        let endpoint = ThreeCirclesEndpoint.completeOnboarding(flowId: flowId, request: request)
        return try await performRequest(endpoint)
    }

    // MARK: - Sponsor Review (4 endpoints)

    /// POST /tools/three-circles/sets/{setId}/share
    /// Generate a share link/code for sponsor review.
    func shareCircleSet(
        setId: String,
        request: CreateShareLinkRequest? = nil
    ) async throws -> ThreeCirclesDataResponse<ShareLinkData> {
        let endpoint = ThreeCirclesEndpoint.shareCircleSet(setId: setId, request: request)
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/share/{shareCode}
    /// View a shared circle set (public, no auth required).
    func viewSharedCircleSet(
        shareCode: String
    ) async throws -> ThreeCirclesDataResponse<SharedCircleSetView> {
        let endpoint = ThreeCirclesEndpoint.viewSharedCircleSet(shareCode: shareCode)
        return try await performRequest(endpoint, requiresAuth: false)
    }

    /// POST /tools/three-circles/share/{shareCode}/comments
    /// Add a sponsor comment (public, no auth required).
    func addSponsorComment(
        shareCode: String,
        request: AddSponsorCommentRequest
    ) async throws -> ThreeCirclesDataResponse<SponsorComment> {
        let endpoint = ThreeCirclesEndpoint.addSponsorComment(shareCode: shareCode, request: request)
        return try await performRequest(endpoint, requiresAuth: false)
    }

    /// GET /tools/three-circles/sets/{setId}/comments
    /// Get all sponsor/therapist comments on a circle set.
    func getComments(
        setId: String,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> ThreeCirclesListResponse<SponsorComment> {
        let endpoint = ThreeCirclesEndpoint.getComments(setId: setId, cursor: cursor, limit: limit)
        return try await performRequest(endpoint)
    }

    // MARK: - Pattern Visualization (4 endpoints)

    /// GET /tools/three-circles/patterns/timeline
    /// Get circle timeline (which circle each day).
    func getTimeline(
        setId: String,
        period: TimelinePeriod? = nil,
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> ThreeCirclesDataResponse<TimelineData> {
        let endpoint = ThreeCirclesEndpoint.getTimeline(
            setId: setId, period: period, startDate: startDate, endDate: endDate
        )
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/patterns/insights
    /// Get auto-generated pattern insight cards.
    func getInsights(
        setId: String,
        category: InsightType? = nil,
        limit: Int? = nil
    ) async throws -> ThreeCirclesListResponse<PatternInsight> {
        let endpoint = ThreeCirclesEndpoint.getInsights(setId: setId, category: category, limit: limit)
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/patterns/summary
    /// Get weekly/monthly pattern summary.
    func getSummary(
        setId: String,
        period: SummaryPeriod,
        startDate: String? = nil
    ) async throws -> ThreeCirclesDataResponse<PatternSummary> {
        let endpoint = ThreeCirclesEndpoint.getSummary(setId: setId, period: period, startDate: startDate)
        return try await performRequest(endpoint)
    }

    /// GET /tools/three-circles/patterns/drift-alerts
    /// Get active drift alerts.
    func getDriftAlerts(
        setId: String,
        status: DriftAlertStatus? = nil
    ) async throws -> ThreeCirclesListResponse<DriftAlert> {
        let endpoint = ThreeCirclesEndpoint.getDriftAlerts(setId: setId, status: status)
        return try await performRequest(endpoint)
    }

    /// POST /tools/three-circles/patterns/drift-alerts/{alertId}/dismiss
    /// Dismiss a drift alert.
    func dismissDriftAlert(alertId: String) async throws {
        let endpoint = ThreeCirclesEndpoint.dismissDriftAlert(alertId: alertId)
        try await performNoContentRequest(endpoint)
    }

    // MARK: - Quarterly Review (4 endpoints)

    /// GET /tools/three-circles/reviews
    /// List review history.
    func listReviews(
        setId: String,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> ThreeCirclesListResponse<ReviewListItem> {
        let endpoint = ThreeCirclesEndpoint.listReviews(setId: setId, cursor: cursor, limit: limit)
        return try await performRequest(endpoint)
    }

    /// POST /tools/three-circles/reviews
    /// Start a quarterly review.
    func startReview(request: StartReviewRequest) async throws -> ThreeCirclesDataResponse<Review> {
        let endpoint = ThreeCirclesEndpoint.startReview(request: request)
        return try await performRequest(endpoint)
    }

    /// PATCH /tools/three-circles/reviews/{reviewId}
    /// Update review progress.
    func updateReview(
        reviewId: String,
        request: UpdateReviewRequest
    ) async throws -> ThreeCirclesDataResponse<Review> {
        let endpoint = ThreeCirclesEndpoint.updateReview(reviewId: reviewId, request: request)
        return try await performRequest(endpoint)
    }

    /// POST /tools/three-circles/reviews/{reviewId}/complete
    /// Complete a quarterly review.
    func completeReview(
        reviewId: String,
        request: CompleteReviewRequest? = nil
    ) async throws -> ThreeCirclesDataResponse<Review> {
        let endpoint = ThreeCirclesEndpoint.completeReview(reviewId: reviewId, request: request)
        return try await performRequest(endpoint)
    }

    // MARK: - Internal Request Pipeline

    private func performRequest<T: Decodable & Sendable>(
        _ endpoint: ThreeCirclesEndpoint,
        requiresAuth: Bool = true
    ) async throws -> T {
        do {
            let urlRequest = try await buildURLRequest(for: endpoint, requiresAuth: requiresAuth)

            #if DEBUG
            let correlationId = urlRequest.value(forHTTPHeaderField: "X-Correlation-Id") ?? "unknown"
            logger.debug("[\(correlationId)] --> \(endpoint.method.rawValue) \(endpoint.path)")
            #endif

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ThreeCirclesAPIError.apiError(.networkError(URLError(.badServerResponse)))
            }

            #if DEBUG
            logger.debug("[\(correlationId)] <-- \(httpResponse.statusCode) (\(data.count) bytes)")
            #endif

            if (200..<300).contains(httpResponse.statusCode) {
                return try decoder.decode(T.self, from: data)
            }

            throw try mapError(statusCode: httpResponse.statusCode, data: data)

        } catch let error as ThreeCirclesAPIError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw ThreeCirclesAPIError.apiError(.offline)
            }
            throw ThreeCirclesAPIError.apiError(.networkError(error))
        } catch let error as DecodingError {
            throw ThreeCirclesAPIError.apiError(.decodingError(error))
        } catch {
            throw ThreeCirclesAPIError.apiError(.networkError(error))
        }
    }

    private func performNoContentRequest(_ endpoint: ThreeCirclesEndpoint) async throws {
        do {
            let urlRequest = try await buildURLRequest(for: endpoint)

            let (data, response) = try await URLSession.shared.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ThreeCirclesAPIError.apiError(.networkError(URLError(.badServerResponse)))
            }

            if httpResponse.statusCode == 204 || (200..<300).contains(httpResponse.statusCode) {
                return
            }

            throw try mapError(statusCode: httpResponse.statusCode, data: data)

        } catch let error as ThreeCirclesAPIError {
            throw error
        } catch let error as URLError {
            if error.code == .notConnectedToInternet || error.code == .networkConnectionLost {
                throw ThreeCirclesAPIError.apiError(.offline)
            }
            throw ThreeCirclesAPIError.apiError(.networkError(error))
        } catch {
            throw ThreeCirclesAPIError.apiError(.networkError(error))
        }
    }

    // MARK: - Request Building

    private func buildURLRequest(
        for endpoint: ThreeCirclesEndpoint,
        requiresAuth: Bool = true
    ) async throws -> URLRequest {
        var components = URLComponents(
            url: apiClient.configuration.baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )!
        components.queryItems = endpoint.queryItems

        guard let url = components.url else {
            throw ThreeCirclesAPIError.apiError(.networkError(URLError(.badURL)))
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
            request.httpBody = try encoder.encode(ThreeCirclesEncodableWrapper(body))
        }

        if requiresAuth,
           let authProvider = apiClient.authProvider,
           let token = await authProvider.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    // MARK: - Error Mapping

    private func mapError(statusCode: Int, data: Data) throws -> ThreeCirclesAPIError {
        // Try to decode Three Circles-specific error codes
        if let errorResponse = try? decoder.decode(ThreeCirclesErrorResponse.self, from: data),
           let firstError = errorResponse.errors.first,
           let code = firstError.code {
            return ThreeCirclesAPIError.fromErrorCode(code, detail: firstError.detail)
        }

        // Fall back to generic HTTP error mapping
        switch statusCode {
        case 401: return .apiError(.unauthorized)
        case 403: return .apiError(.forbidden)
        case 404: return .circleSetNotFound
        case 410: return .shareLinkExpired
        case 422:
            if let errorResponse = try? decoder.decode(ThreeCirclesErrorResponse.self, from: data) {
                let detail = errorResponse.errors.first?.detail
                return .validationError(detail: detail ?? "Validation failed.")
            }
            return .validationError(detail: "Validation failed.")
        default:
            return .apiError(.serverError(statusCode: statusCode, message: "HTTP \(statusCode)"))
        }
    }
}

// MARK: - Three Circles Endpoints

/// Type-safe endpoint definitions for all Three Circles API operations.
private enum ThreeCirclesEndpoint: Sendable {
    // Circle Sets
    case listCircleSets(status: CircleSetStatus?, recoveryArea: RecoveryArea?, cursor: String?, limit: Int?)
    case createCircleSet(CreateCircleSetRequest)
    case getCircleSet(setId: String)
    case replaceCircleSet(setId: String, request: ReplaceCircleSetRequest)
    case updateCircleSet(setId: String, request: UpdateCircleSetRequest)
    case deleteCircleSet(setId: String)
    case commitCircleSet(setId: String, request: CommitCircleSetRequest?)

    // Circle Items
    case addCircleItem(setId: String, request: CreateCircleItemRequest)
    case updateCircleItem(setId: String, itemId: String, request: UpdateCircleItemRequest)
    case deleteCircleItem(setId: String, itemId: String)
    case moveCircleItem(setId: String, itemId: String, request: MoveItemRequest)

    // Version History
    case listVersions(setId: String, cursor: String?, limit: Int?)
    case getVersion(setId: String, versionId: String)
    case restoreVersion(setId: String, versionId: String, request: RestoreVersionRequest?)

    // Templates
    case listTemplates(recoveryArea: RecoveryArea, circle: CircleType?, framework: FrameworkPreference?)
    case getTemplate(templateId: String)

    // Starter Packs
    case listStarterPacks(recoveryArea: RecoveryArea, variant: StarterPackVariant?)
    case getStarterPack(packId: String)
    case applyStarterPack(setId: String, request: ApplyStarterPackRequest)

    // Onboarding
    case startOnboarding(request: StartOnboardingRequest?)
    case updateOnboarding(flowId: String, request: UpdateOnboardingRequest)
    case completeOnboarding(flowId: String, request: CompleteOnboardingRequest)

    // Sponsor Review
    case shareCircleSet(setId: String, request: CreateShareLinkRequest?)
    case viewSharedCircleSet(shareCode: String)
    case addSponsorComment(shareCode: String, request: AddSponsorCommentRequest)
    case getComments(setId: String, cursor: String?, limit: Int?)

    // Pattern Visualization
    case getTimeline(setId: String, period: TimelinePeriod?, startDate: String?, endDate: String?)
    case getInsights(setId: String, category: InsightType?, limit: Int?)
    case getSummary(setId: String, period: SummaryPeriod, startDate: String?)
    case getDriftAlerts(setId: String, status: DriftAlertStatus?)
    case dismissDriftAlert(alertId: String)

    // Quarterly Review
    case listReviews(setId: String, cursor: String?, limit: Int?)
    case startReview(request: StartReviewRequest)
    case updateReview(reviewId: String, request: UpdateReviewRequest)
    case completeReview(reviewId: String, request: CompleteReviewRequest?)

    private static let base = "/tools/three-circles"

    var path: String {
        switch self {
        // Circle Sets
        case .listCircleSets, .createCircleSet:
            return "\(Self.base)/sets"
        case .getCircleSet(let setId),
             .replaceCircleSet(let setId, _),
             .updateCircleSet(let setId, _),
             .deleteCircleSet(let setId):
            return "\(Self.base)/sets/\(setId)"
        case .commitCircleSet(let setId, _):
            return "\(Self.base)/sets/\(setId)/commit"

        // Circle Items
        case .addCircleItem(let setId, _):
            return "\(Self.base)/sets/\(setId)/items"
        case .updateCircleItem(let setId, let itemId, _),
             .deleteCircleItem(let setId, let itemId):
            return "\(Self.base)/sets/\(setId)/items/\(itemId)"
        case .moveCircleItem(let setId, let itemId, _):
            return "\(Self.base)/sets/\(setId)/items/\(itemId)/move"

        // Version History
        case .listVersions(let setId, _, _):
            return "\(Self.base)/sets/\(setId)/versions"
        case .getVersion(let setId, let versionId):
            return "\(Self.base)/sets/\(setId)/versions/\(versionId)"
        case .restoreVersion(let setId, let versionId, _):
            return "\(Self.base)/sets/\(setId)/versions/\(versionId)/restore"

        // Templates
        case .listTemplates:
            return "\(Self.base)/templates"
        case .getTemplate(let templateId):
            return "\(Self.base)/templates/\(templateId)"

        // Starter Packs
        case .listStarterPacks:
            return "\(Self.base)/starter-packs"
        case .getStarterPack(let packId):
            return "\(Self.base)/starter-packs/\(packId)"
        case .applyStarterPack(let setId, _):
            return "\(Self.base)/sets/\(setId)/apply-starter-pack"

        // Onboarding
        case .startOnboarding:
            return "\(Self.base)/onboarding/start"
        case .updateOnboarding(let flowId, _):
            return "\(Self.base)/onboarding/\(flowId)"
        case .completeOnboarding(let flowId, _):
            return "\(Self.base)/onboarding/\(flowId)/complete"

        // Sponsor Review
        case .shareCircleSet(let setId, _):
            return "\(Self.base)/sets/\(setId)/share"
        case .viewSharedCircleSet(let shareCode):
            return "\(Self.base)/share/\(shareCode)"
        case .addSponsorComment(let shareCode, _):
            return "\(Self.base)/share/\(shareCode)/comments"
        case .getComments(let setId, _, _):
            return "\(Self.base)/sets/\(setId)/comments"

        // Pattern Visualization
        case .getTimeline:
            return "\(Self.base)/patterns/timeline"
        case .getInsights:
            return "\(Self.base)/patterns/insights"
        case .getSummary:
            return "\(Self.base)/patterns/summary"
        case .getDriftAlerts:
            return "\(Self.base)/patterns/drift-alerts"
        case .dismissDriftAlert(let alertId):
            return "\(Self.base)/patterns/drift-alerts/\(alertId)/dismiss"

        // Quarterly Review
        case .listReviews, .startReview:
            return "\(Self.base)/reviews"
        case .updateReview(let reviewId, _):
            return "\(Self.base)/reviews/\(reviewId)"
        case .completeReview(let reviewId, _):
            return "\(Self.base)/reviews/\(reviewId)/complete"
        }
    }

    var method: HTTPMethod {
        switch self {
        // GET
        case .listCircleSets, .getCircleSet,
             .listVersions, .getVersion,
             .listTemplates, .getTemplate,
             .listStarterPacks, .getStarterPack,
             .viewSharedCircleSet, .getComments,
             .getTimeline, .getInsights, .getSummary, .getDriftAlerts,
             .listReviews:
            return .get

        // POST
        case .createCircleSet, .commitCircleSet,
             .addCircleItem, .moveCircleItem,
             .restoreVersion,
             .applyStarterPack,
             .startOnboarding, .completeOnboarding,
             .shareCircleSet, .addSponsorComment,
             .dismissDriftAlert,
             .startReview, .completeReview:
            return .post

        // PUT
        case .replaceCircleSet, .updateCircleItem:
            return .put

        // PATCH
        case .updateCircleSet, .updateOnboarding, .updateReview:
            return .patch

        // DELETE
        case .deleteCircleSet, .deleteCircleItem:
            return .delete
        }
    }

    var body: (any Encodable & Sendable)? {
        switch self {
        // Circle Sets
        case .createCircleSet(let req): return req
        case .replaceCircleSet(_, let req): return req
        case .updateCircleSet(_, let req): return req
        case .commitCircleSet(_, let req): return req

        // Circle Items
        case .addCircleItem(_, let req): return req
        case .updateCircleItem(_, _, let req): return req
        case .moveCircleItem(_, _, let req): return req

        // Version History
        case .restoreVersion(_, _, let req): return req

        // Starter Packs
        case .applyStarterPack(_, let req): return req

        // Onboarding
        case .startOnboarding(let req): return req
        case .updateOnboarding(_, let req): return req
        case .completeOnboarding(_, let req): return req

        // Sponsor Review
        case .shareCircleSet(_, let req): return req
        case .addSponsorComment(_, let req): return req

        // Quarterly Review
        case .startReview(let req): return req
        case .updateReview(_, let req): return req
        case .completeReview(_, let req): return req

        default: return nil
        }
    }

    var queryItems: [URLQueryItem]? {
        var items: [URLQueryItem] = []

        switch self {
        case .listCircleSets(let status, let recoveryArea, let cursor, let limit):
            if let status { items.append(.init(name: "status", value: status.rawValue)) }
            if let recoveryArea { items.append(.init(name: "recoveryArea", value: recoveryArea.rawValue)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .listVersions(_, let cursor, let limit):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .listTemplates(let recoveryArea, let circle, let framework):
            items.append(.init(name: "recoveryArea", value: recoveryArea.rawValue))
            if let circle { items.append(.init(name: "circle", value: circle.rawValue)) }
            if let framework { items.append(.init(name: "framework", value: framework.rawValue)) }

        case .listStarterPacks(let recoveryArea, let variant):
            items.append(.init(name: "recoveryArea", value: recoveryArea.rawValue))
            if let variant { items.append(.init(name: "variant", value: variant.rawValue)) }

        case .getComments(_, let cursor, let limit):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .getTimeline(let setId, let period, let startDate, let endDate):
            items.append(.init(name: "setId", value: setId))
            if let period { items.append(.init(name: "period", value: period.rawValue)) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }

        case .getInsights(let setId, let category, let limit):
            items.append(.init(name: "setId", value: setId))
            if let category { items.append(.init(name: "category", value: category.rawValue)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .getSummary(let setId, let period, let startDate):
            items.append(.init(name: "setId", value: setId))
            items.append(.init(name: "period", value: period.rawValue))
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }

        case .getDriftAlerts(let setId, let status):
            items.append(.init(name: "setId", value: setId))
            if let status { items.append(.init(name: "status", value: status.rawValue)) }

        case .listReviews(let setId, let cursor, let limit):
            items.append(.init(name: "setId", value: setId))
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        default:
            break
        }

        return items.isEmpty ? nil : items
    }
}

// MARK: - Type-Erased Encodable Wrapper

private struct ThreeCirclesEncodableWrapper: Encodable {
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
