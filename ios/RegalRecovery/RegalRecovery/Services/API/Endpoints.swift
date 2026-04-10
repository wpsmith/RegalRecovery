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

    // MARK: Flags
    case getFlags
    case evaluateFlag(key: String)

    // MARK: - Path

    var path: String {
        switch self {
        // Auth
        case .register: return "/v1/auth/register"
        case .login: return "/v1/auth/login"
        case .refreshToken: return "/v1/auth/refresh"
        case .logout: return "/v1/auth/logout"
        case .listSessions: return "/v1/auth/sessions"
        case .revokeSession(let sessionId): return "/v1/auth/sessions/\(sessionId)"
        case .requestPasswordReset: return "/v1/auth/password-reset"
        case .verifyEmail: return "/v1/auth/verify-email"

        // Users
        case .getProfile, .updateProfile: return "/v1/users/me"
        case .getSettings, .updateSettings: return "/v1/users/me/settings"
        case .getPrivacySettings, .updatePrivacySettings: return "/v1/users/me/privacy"
        case .getAddictions, .addAddiction: return "/v1/users/me/addictions"
        case .deleteAddiction(let id): return "/v1/users/me/addictions/\(id)"
        case .setPrimaryAddiction(let id): return "/v1/users/me/addictions/\(id)/primary"

        // Tracking
        case .getStreaks: return "/v1/tracking/streaks"
        case .getStreak(let id): return "/v1/tracking/streaks/\(id)"
        case .getMilestones: return "/v1/tracking/milestones"
        case .getCalendar: return "/v1/tracking/calendar"
        case .getCalendarDay(let date): return "/v1/tracking/calendar/\(date)"
        case .getHistory: return "/v1/tracking/history"
        case .logRelapse: return "/v1/tracking/relapses"

        // Activities
        case .logActivity(let type, _): return "/v1/activities/\(type)"
        case .getActivities(let type, _, _): return "/v1/activities/\(type)"

        // Content
        case .listAffirmations: return "/v1/content/affirmations"
        case .getTodayAffirmation: return "/v1/content/affirmations/today"
        case .getAffirmation(let id): return "/v1/content/affirmations/\(id)"
        case .addFavoriteAffirmation(let id): return "/v1/content/affirmations/favorites/\(id)"
        case .removeFavoriteAffirmation(let id): return "/v1/content/affirmations/favorites/\(id)"
        case .listDevotionals: return "/v1/content/devotionals"
        case .getTodayDevotional: return "/v1/content/devotionals/today"
        case .listPrayers: return "/v1/content/prayers"
        case .listResources: return "/v1/content/resources"
        case .listContentPacks: return "/v1/content/packs"
        case .listOwnedPacks: return "/v1/content/packs/owned"
        case .purchaseContentPack(let packId, _): return "/v1/content/packs/\(packId)/purchase"

        // Flags
        case .getFlags: return "/v1/flags"
        case .evaluateFlag(let key): return "/v1/flags/\(key)"
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
             .purchaseContentPack:
            return .post

        case .updateSettings, .updatePrivacySettings:
            return .put

        case .updateProfile, .setPrimaryAddiction:
            return .patch

        case .revokeSession, .deleteAddiction, .removeFavoriteAffirmation:
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
