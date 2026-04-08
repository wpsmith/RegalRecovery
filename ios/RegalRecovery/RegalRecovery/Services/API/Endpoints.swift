import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Endpoint

/// Type-safe endpoint definitions matching the OpenAPI specifications.
/// Each case maps to exactly one API operation with its required parameters.
enum Endpoint: Sendable {
    // MARK: Auth
    case register(RegisterRequest)
    case login(LoginRequest)
    case refreshToken(RefreshTokenRequest)
    case logout(LogoutRequest)
    case listSessions
    case revokeSession(sessionId: String)
    case requestPasswordReset(email: String)
    case verifyEmail(email: String, code: String)

    // MARK: Users
    case getProfile
    case updateProfile(UpdateProfileRequest)
    case getSettings
    case updateSettings(UserSettingsData)
    case getPrivacySettings
    case updatePrivacySettings(PrivacySettingsData)
    case getAddictions
    case addAddiction(AddAddictionRequest)
    case deleteAddiction(addictionId: String)
    case setPrimaryAddiction(addictionId: String)

    // MARK: Tracking
    case getStreaks
    case getStreak(addictionId: String)
    case getMilestones(addictionId: String?, status: String?, sort: String?)
    case getCalendar(month: String?, startDate: String?, endDate: String?, addictionId: String?)
    case getCalendarDay(date: String)
    case getHistory(addictionId: String?, startDate: String?, endDate: String?, cursor: String?, limit: Int?)
    case logRelapse(RelapseRequest)

    // MARK: Activities
    case logActivity(type: String, data: ActivityRequest)
    case getActivities(type: String, cursor: String?, limit: Int?)

    // MARK: Content
    case listAffirmations(cursor: String?, limit: Int?, pack: String?, category: String?)
    case getTodayAffirmation
    case getAffirmation(id: String)
    case addFavoriteAffirmation(id: String)
    case removeFavoriteAffirmation(id: String)
    case listDevotionals(cursor: String?, limit: Int?)
    case getTodayDevotional
    case listPrayers(cursor: String?, limit: Int?, pack: String?)
    case listResources(cursor: String?, limit: Int?, type: String?, category: String?)
    case listContentPacks
    case listOwnedPacks
    case purchaseContentPack(packId: String, receipt: PurchaseRequest)

    // MARK: Post-Mortem
    case createPostMortem(CreatePostMortemRequest)
    case listPostMortems(startDate: String?, endDate: String?, addictionId: String?, status: String?, eventType: String?, cursor: String?, limit: Int?)
    case getPostMortem(analysisId: String)
    case updatePostMortem(analysisId: String, UpdatePostMortemRequest)
    case deletePostMortem(analysisId: String)
    case completePostMortem(analysisId: String)
    case sharePostMortem(analysisId: String, SharePostMortemRequestBody)
    case exportPostMortem(analysisId: String, format: String)
    case convertActionItem(analysisId: String, actionId: String, ConvertActionItemRequestBody)
    case getPostMortemInsights(addictionId: String?)

    // MARK: Flags
    case getFlags
    case evaluateFlag(key: String)

    // MARK: - Path

    var path: String {
        switch self {
        // Auth
        case .register: return "/auth/register"
        case .login: return "/auth/login"
        case .refreshToken: return "/auth/refresh"
        case .logout: return "/auth/logout"
        case .listSessions: return "/auth/sessions"
        case .revokeSession(let sessionId): return "/auth/sessions/\(sessionId)"
        case .requestPasswordReset: return "/auth/password-reset"
        case .verifyEmail: return "/auth/verify-email"

        // Users
        case .getProfile, .updateProfile: return "/users/me"
        case .getSettings, .updateSettings: return "/users/me/settings"
        case .getPrivacySettings, .updatePrivacySettings: return "/users/me/privacy"
        case .getAddictions, .addAddiction: return "/users/me/addictions"
        case .deleteAddiction(let id): return "/users/me/addictions/\(id)"
        case .setPrimaryAddiction(let id): return "/users/me/addictions/\(id)/primary"

        // Tracking
        case .getStreaks: return "/tracking/streaks"
        case .getStreak(let id): return "/tracking/streaks/\(id)"
        case .getMilestones: return "/tracking/milestones"
        case .getCalendar: return "/tracking/calendar"
        case .getCalendarDay(let date): return "/tracking/calendar/\(date)"
        case .getHistory: return "/tracking/history"
        case .logRelapse: return "/tracking/relapses"

        // Activities
        case .logActivity(let type, _): return "/activities/\(type)"
        case .getActivities(let type, _, _): return "/activities/\(type)"

        // Post-Mortem
        case .createPostMortem, .listPostMortems: return "/activities/post-mortem"
        case .getPostMortem(let id), .updatePostMortem(let id, _), .deletePostMortem(let id):
            return "/activities/post-mortem/\(id)"
        case .completePostMortem(let id): return "/activities/post-mortem/\(id)/complete"
        case .sharePostMortem(let id, _): return "/activities/post-mortem/\(id)/share"
        case .exportPostMortem(let id, _): return "/activities/post-mortem/\(id)/export"
        case .convertActionItem(let id, let actionId, _):
            return "/activities/post-mortem/\(id)/action-items/\(actionId)/convert"
        case .getPostMortemInsights: return "/activities/post-mortem/insights"

        // Content
        case .listAffirmations: return "/content/affirmations"
        case .getTodayAffirmation: return "/content/affirmations/today"
        case .getAffirmation(let id): return "/content/affirmations/\(id)"
        case .addFavoriteAffirmation(let id): return "/content/affirmations/favorites/\(id)"
        case .removeFavoriteAffirmation(let id): return "/content/affirmations/favorites/\(id)"
        case .listDevotionals: return "/content/devotionals"
        case .getTodayDevotional: return "/content/devotionals/today"
        case .listPrayers: return "/content/prayers"
        case .listResources: return "/content/resources"
        case .listContentPacks: return "/content/packs"
        case .listOwnedPacks: return "/content/packs/owned"
        case .purchaseContentPack(let packId, _): return "/content/packs/\(packId)/purchase"

        // Flags
        case .getFlags: return "/flags"
        case .evaluateFlag(let key): return "/flags/\(key)"
        }
    }

    // MARK: - Method

    var method: HTTPMethod {
        switch self {
        case .register, .login, .refreshToken, .logout,
             .requestPasswordReset, .verifyEmail,
             .addAddiction,
             .logRelapse,
             .logActivity,
             .addFavoriteAffirmation,
             .purchaseContentPack,
             .createPostMortem,
             .completePostMortem,
             .sharePostMortem,
             .convertActionItem:
            return .post

        case .updateSettings, .updatePrivacySettings:
            return .put

        case .updateProfile, .setPrimaryAddiction, .updatePostMortem:
            return .patch

        case .revokeSession, .deleteAddiction, .removeFavoriteAffirmation, .deletePostMortem:
            return .delete

        default:
            return .get
        }
    }

    // MARK: - Body

    var body: (any Encodable & Sendable)? {
        switch self {
        case .register(let req): return req
        case .login(let req): return req
        case .refreshToken(let req): return req
        case .logout(let req): return req
        case .requestPasswordReset(let email):
            return ["email": email] as [String: String]
        case .verifyEmail(let email, let code):
            return ["email": email, "code": code] as [String: String]
        case .updateProfile(let req): return req
        case .updateSettings(let req): return req
        case .updatePrivacySettings(let req): return req
        case .addAddiction(let req): return req
        case .logRelapse(let req): return req
        case .logActivity(_, let data): return data
        case .purchaseContentPack(_, let receipt): return receipt
        case .createPostMortem(let req): return req
        case .updatePostMortem(_, let req): return req
        case .sharePostMortem(_, let req): return req
        case .convertActionItem(_, _, let req): return req
        default: return nil
        }
    }

    // MARK: - Query Items

    var queryItems: [URLQueryItem]? {
        var items: [URLQueryItem] = []

        switch self {
        case .getMilestones(let addictionId, let status, let sort):
            if let addictionId { items.append(.init(name: "addictionId", value: addictionId)) }
            if let status { items.append(.init(name: "status", value: status)) }
            if let sort { items.append(.init(name: "sort", value: sort)) }

        case .getCalendar(let month, let startDate, let endDate, let addictionId):
            if let month { items.append(.init(name: "month", value: month)) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let addictionId { items.append(.init(name: "addictionId", value: addictionId)) }

        case .getHistory(let addictionId, let startDate, let endDate, let cursor, let limit):
            if let addictionId { items.append(.init(name: "addictionId", value: addictionId)) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .getActivities(_, let cursor, let limit):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .listAffirmations(let cursor, let limit, let pack, let category):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }
            if let pack { items.append(.init(name: "pack", value: pack)) }
            if let category { items.append(.init(name: "category", value: category)) }

        case .listDevotionals(let cursor, let limit):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .listPrayers(let cursor, let limit, let pack):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }
            if let pack { items.append(.init(name: "pack", value: pack)) }

        case .listResources(let cursor, let limit, let type, let category):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }
            if let type { items.append(.init(name: "type", value: type)) }
            if let category { items.append(.init(name: "category", value: category)) }

        case .listPostMortems(let startDate, let endDate, let addictionId, let status, let eventType, let cursor, let limit):
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let addictionId { items.append(.init(name: "addictionId", value: addictionId)) }
            if let status { items.append(.init(name: "status", value: status)) }
            if let eventType { items.append(.init(name: "eventType", value: eventType)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .exportPostMortem(_, let format):
            items.append(.init(name: "format", value: format))

        case .getPostMortemInsights(let addictionId):
            if let addictionId { items.append(.init(name: "addictionId", value: addictionId)) }

        default:
            break
        }

        return items.isEmpty ? nil : items
    }

    // MARK: - Auth Required

    /// Whether this endpoint requires a Bearer token. Public endpoints (register, login, etc.) do not.
    var requiresAuth: Bool {
        switch self {
        case .register, .login, .refreshToken, .requestPasswordReset, .verifyEmail:
            return false
        default:
            return true
        }
    }
}
