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

    // MARK: Exercise
    case createExerciseLog(CreateExerciseLogRequest)
    case listExerciseLogs(activityType: String?, intensity: String?, startDate: String?, endDate: String?, search: String?, cursor: String?, limit: Int?, sort: String?)
    case getExerciseLog(exerciseId: String)
    case updateExerciseLog(exerciseId: String, UpdateExerciseLogRequest)
    case deleteExerciseLog(exerciseId: String)
    case listExerciseFavorites
    case createExerciseFavorite(CreateExerciseFavoriteRequest)
    case updateExerciseFavorite(favoriteId: String, CreateExerciseFavoriteRequest)
    case deleteExerciseFavorite(favoriteId: String)
    case getExerciseStats(period: String, referenceDate: String?)
    case getExerciseStreak
    case getExerciseCorrelations
    case getExerciseGoal
    case setExerciseGoal(SetExerciseGoalRequest)
    case deleteExerciseGoal
    case getExerciseWidget

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

    // MARK: Prayer Activity
    case createPrayerSession(CreatePrayerSessionDTO)
    case listPrayerSessions(prayerType: String?, startDate: String?, endDate: String?, cursor: String?, limit: Int?)
    case getPrayerSession(id: String)
    case updatePrayerSession(id: String, UpdatePrayerSessionDTO)
    case deletePrayerSession(id: String)
    case getPrayerStats
    case getPrayerTrends(period: String)
    case getTodayPrayer
    case getPrayerById(id: String)
    case createPersonalPrayer(CreatePersonalPrayerDTO)
    case listPersonalPrayers(cursor: String?, limit: Int?)
    case updatePersonalPrayer(id: String, UpdatePersonalPrayerDTO)
    case deletePersonalPrayer(id: String)
    case reorderPersonalPrayers(ReorderPrayersDTO)
    case listFavoritePrayers(cursor: String?, limit: Int?)
    case favoritePrayer(id: String)
    case unfavoritePrayer(id: String)

    // MARK: Phone Calls
    case createPhoneCall(CreatePhoneCallRequest)
    case listPhoneCalls(direction: String?, contactType: String?, connected: Bool?, startDate: String?, endDate: String?, search: String?, cursor: String?, limit: Int?)
    case getPhoneCall(callId: String)
    case updatePhoneCall(callId: String, UpdatePhoneCallRequest)
    case deletePhoneCall(callId: String)
    case createSavedContact(CreateSavedContactAPIRequest)
    case listSavedContacts
    case updateSavedContact(savedContactId: String, UpdateSavedContactAPIRequest)
    case deleteSavedContact(savedContactId: String)
    case getPhoneCallStreak
    case getPhoneCallTrends(period: String?)
    case getPhoneCallDailyTrends(period: String?)

    // MARK: Flags
    case getFlags
    case evaluateFlag(key: String)

    // MARK: Meetings
    case createMeetingLog(CreateMeetingLogRequest)
    case listMeetingLogs(meetingType: MeetingType?, startDate: String?, endDate: String?, cursor: String?, limit: Int?, sort: String?)
    case getMeetingLog(meetingId: String)
    case updateMeetingLog(meetingId: String, UpdateMeetingLogRequest)
    case deleteMeetingLog(meetingId: String)
    case getMeetingAttendanceSummary(period: MeetingSummaryPeriod, date: String?)
    case createSavedMeeting(CreateSavedMeetingRequest)
    case listSavedMeetings
    case getSavedMeeting(savedMeetingId: String)
    case updateSavedMeeting(savedMeetingId: String, UpdateSavedMeetingRequest)
    case deleteSavedMeeting(savedMeetingId: String)

    // MARK: Nutrition
    case nutritionCreateMeal(CreateMealLogRequest)
    case nutritionQuickLog(CreateQuickMealLogRequest)
    case nutritionGetMeal(mealId: String)
    case nutritionListMeals(mealType: String?, eatingContext: String?, startDate: String?, endDate: String?, search: String?, cursor: String?, limit: Int?)
    case nutritionUpdateMeal(mealId: String, UpdateMealLogRequest)
    case nutritionDeleteMeal(mealId: String)
    case nutritionGetHydration
    case nutritionLogHydration(LogHydrationRequest)
    case nutritionHydrationHistory(startDate: String, endDate: String)
    case nutritionCalendar(year: Int, month: Int)
    case nutritionTrends(period: String)
    case nutritionWeeklySummary
    case nutritionGetSettings
    case nutritionUpdateSettings(Any)

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

        // Exercise
        case .createExerciseLog, .listExerciseLogs: return "/activities/exercise"
        case .getExerciseLog(let id), .updateExerciseLog(let id, _), .deleteExerciseLog(let id):
            return "/activities/exercise/\(id)"
        case .listExerciseFavorites, .createExerciseFavorite: return "/activities/exercise/favorites"
        case .updateExerciseFavorite(let id, _), .deleteExerciseFavorite(let id):
            return "/activities/exercise/favorites/\(id)"
        case .getExerciseStats: return "/activities/exercise/stats"
        case .getExerciseStreak: return "/activities/exercise/streak"
        case .getExerciseCorrelations: return "/activities/exercise/correlations"
        case .getExerciseGoal, .setExerciseGoal, .deleteExerciseGoal: return "/activities/exercise/goals"
        case .getExerciseWidget: return "/activities/exercise/widget"

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

        // Prayer Activity
        case .createPrayerSession, .listPrayerSessions: return "/activities/prayer"
        case .getPrayerSession(let id), .updatePrayerSession(let id, _), .deletePrayerSession(let id): return "/activities/prayer/\(id)"
        case .getPrayerStats: return "/activities/prayer/stats"
        case .getPrayerTrends: return "/activities/prayer/trends"
        case .getTodayPrayer: return "/content/prayers/today"
        case .getPrayerById(let id): return "/content/prayers/\(id)"
        case .createPersonalPrayer, .listPersonalPrayers: return "/content/prayers/personal"
        case .updatePersonalPrayer(let id, _), .deletePersonalPrayer(let id): return "/content/prayers/personal/\(id)"
        case .reorderPersonalPrayers: return "/content/prayers/personal/order"
        case .listFavoritePrayers: return "/content/prayers/favorites"
        case .favoritePrayer(let id), .unfavoritePrayer(let id): return "/content/prayers/favorites/\(id)"
        case .listContentPacks: return "/content/packs"
        case .listOwnedPacks: return "/content/packs/owned"
        case .purchaseContentPack(let packId, _): return "/content/packs/\(packId)/purchase"

        // Phone Calls
        case .createPhoneCall, .listPhoneCalls: return "/activities/phone-calls"
        case .getPhoneCall(let callId), .updatePhoneCall(let callId, _), .deletePhoneCall(let callId):
            return "/activities/phone-calls/\(callId)"
        case .createSavedContact, .listSavedContacts: return "/activities/phone-calls/saved-contacts"
        case .updateSavedContact(let id, _), .deleteSavedContact(let id):
            return "/activities/phone-calls/saved-contacts/\(id)"
        case .getPhoneCallStreak: return "/activities/phone-calls/streak"
        case .getPhoneCallTrends: return "/activities/phone-calls/trends"
        case .getPhoneCallDailyTrends: return "/activities/phone-calls/trends/daily"

        // Flags
        case .getFlags: return "/flags"
        case .evaluateFlag(let key): return "/flags/\(key)"

        // Meetings
        case .createMeetingLog, .listMeetingLogs: return "/activities/meetings"
        case .getMeetingLog(let id), .updateMeetingLog(let id, _), .deleteMeetingLog(let id):
            return "/activities/meetings/\(id)"
        case .getMeetingAttendanceSummary: return "/activities/meetings/summary"
        case .createSavedMeeting, .listSavedMeetings: return "/activities/meetings/saved"
        case .getSavedMeeting(let id), .updateSavedMeeting(let id, _), .deleteSavedMeeting(let id):
            return "/activities/meetings/saved/\(id)"

        // Nutrition
        case .nutritionCreateMeal, .nutritionListMeals: return "/activities/nutrition/meals"
        case .nutritionQuickLog: return "/activities/nutrition/meals/quick"
        case .nutritionGetMeal(let id), .nutritionUpdateMeal(let id, _), .nutritionDeleteMeal(let id):
            return "/activities/nutrition/meals/\(id)"
        case .nutritionGetHydration: return "/activities/nutrition/hydration"
        case .nutritionLogHydration: return "/activities/nutrition/hydration/log"
        case .nutritionHydrationHistory: return "/activities/nutrition/hydration/history"
        case .nutritionCalendar: return "/activities/nutrition/calendar"
        case .nutritionTrends: return "/activities/nutrition/trends"
        case .nutritionWeeklySummary: return "/activities/nutrition/trends/weekly-summary"
        case .nutritionGetSettings, .nutritionUpdateSettings: return "/activities/nutrition/settings"
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
             .createPrayerSession,
             .createPersonalPrayer,
             .favoritePrayer,
             .createPhoneCall,
             .createSavedContact,
             .createMeetingLog,
             .createSavedMeeting,
             .nutritionCreateMeal, .nutritionQuickLog, .nutritionLogHydration,
             .createExerciseLog,
             .createExerciseFavorite:
            return .post

        case .updateSettings, .updatePrivacySettings,
             .reorderPersonalPrayers,
             .updateExerciseFavorite, .setExerciseGoal:
            return .put

        case .updateProfile, .setPrimaryAddiction,
             .updatePrayerSession, .updatePersonalPrayer,
             .updatePhoneCall, .updateSavedContact,
             .updateMeetingLog, .updateSavedMeeting,
             .nutritionUpdateMeal, .nutritionUpdateSettings,
             .updateExerciseLog:
            return .patch

        case .revokeSession, .deleteAddiction, .removeFavoriteAffirmation,
             .deletePrayerSession, .deletePersonalPrayer, .unfavoritePrayer,
             .deletePhoneCall, .deleteSavedContact,
             .deleteMeetingLog, .deleteSavedMeeting,
             .nutritionDeleteMeal,
             .deleteExerciseLog, .deleteExerciseFavorite, .deleteExerciseGoal:
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
        case .createPrayerSession(let req): return req
        case .updatePrayerSession(_, let req): return req
        case .createPersonalPrayer(let req): return req
        case .updatePersonalPrayer(_, let req): return req
        case .reorderPersonalPrayers(let req): return req
        case .createPhoneCall(let req): return req
        case .updatePhoneCall(_, let req): return req
        case .createSavedContact(let req): return req
        case .updateSavedContact(_, let req): return req
        case .createMeetingLog(let req): return req
        case .updateMeetingLog(_, let req): return req
        case .createSavedMeeting(let req): return req
        case .updateSavedMeeting(_, let req): return req
        case .nutritionCreateMeal(let req): return req
        case .nutritionQuickLog(let req): return req
        case .nutritionUpdateMeal(_, let req): return req
        case .nutritionLogHydration(let req): return req
        case .createExerciseLog(let req): return req
        case .updateExerciseLog(_, let req): return req
        case .createExerciseFavorite(let req): return req
        case .updateExerciseFavorite(_, let req): return req
        case .setExerciseGoal(let req): return req
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

        case .listExerciseLogs(let activityType, let intensity, let startDate, let endDate, let search, let cursor, let limit, let sort):
            if let activityType { items.append(.init(name: "activityType", value: activityType)) }
            if let intensity { items.append(.init(name: "intensity", value: intensity)) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let search { items.append(.init(name: "search", value: search)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }
            if let sort { items.append(.init(name: "sort", value: sort)) }

        case .getExerciseStats(let period, let referenceDate):
            items.append(.init(name: "period", value: period))
            if let referenceDate { items.append(.init(name: "referenceDate", value: referenceDate)) }

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

        case .listPrayerSessions(let prayerType, let startDate, let endDate, let cursor, let limit):
            if let prayerType { items.append(.init(name: "prayerType", value: prayerType)) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .getPrayerTrends(let period):
            items.append(.init(name: "period", value: period))

        case .listPersonalPrayers(let cursor, let limit),
             .listFavoritePrayers(let cursor, let limit):
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .listPhoneCalls(let direction, let contactType, let connected, let startDate, let endDate, let search, let cursor, let limit):
            if let direction { items.append(.init(name: "direction", value: direction)) }
            if let contactType { items.append(.init(name: "contactType", value: contactType)) }
            if let connected { items.append(.init(name: "connected", value: String(connected))) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let search { items.append(.init(name: "search", value: search)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .getPhoneCallTrends(let period):
            if let period { items.append(.init(name: "period", value: period)) }

        case .getPhoneCallDailyTrends(let period):
            if let period { items.append(.init(name: "period", value: period)) }

        case .listMeetingLogs(let meetingType, let startDate, let endDate, let cursor, let limit, let sort):
            if let meetingType { items.append(.init(name: "meetingType", value: meetingType.rawValue)) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }
            if let sort { items.append(.init(name: "sort", value: sort)) }

        case .getMeetingAttendanceSummary(let period, let date):
            items.append(.init(name: "period", value: period.rawValue))
            if let date { items.append(.init(name: "date", value: date)) }

        case .nutritionListMeals(let mealType, let eatingContext, let startDate, let endDate, let search, let cursor, let limit):
            if let mealType { items.append(.init(name: "mealType", value: mealType)) }
            if let eatingContext { items.append(.init(name: "eatingContext", value: eatingContext)) }
            if let startDate { items.append(.init(name: "startDate", value: startDate)) }
            if let endDate { items.append(.init(name: "endDate", value: endDate)) }
            if let search { items.append(.init(name: "search", value: search)) }
            if let cursor { items.append(.init(name: "cursor", value: cursor)) }
            if let limit { items.append(.init(name: "limit", value: String(limit))) }

        case .nutritionHydrationHistory(let startDate, let endDate):
            items.append(.init(name: "startDate", value: startDate))
            items.append(.init(name: "endDate", value: endDate))

        case .nutritionCalendar(let year, let month):
            items.append(.init(name: "year", value: String(year)))
            items.append(.init(name: "month", value: String(month)))

        case .nutritionTrends(let period):
            items.append(.init(name: "period", value: period))

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
