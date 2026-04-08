import Foundation

// MARK: - Phone Call API Models

/// Matches OpenAPI CreatePhoneCallRequest schema.
struct CreatePhoneCallRequest: Codable, Sendable {
    let timestamp: String?
    let direction: String
    let contactType: String
    let customContactLabel: String?
    let connected: Bool
    let contactName: String?
    let savedContactId: String?
    let durationMinutes: Int?
    let notes: String?

    init(
        timestamp: String? = nil,
        direction: String = "made",
        contactType: String = "sponsor",
        customContactLabel: String? = nil,
        connected: Bool = true,
        contactName: String? = nil,
        savedContactId: String? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.direction = direction
        self.contactType = contactType
        self.customContactLabel = customContactLabel
        self.connected = connected
        self.contactName = contactName
        self.savedContactId = savedContactId
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}

/// Matches OpenAPI UpdatePhoneCallRequest schema (merge-patch).
struct UpdatePhoneCallRequest: Codable, Sendable {
    let direction: String?
    let contactType: String?
    let customContactLabel: String?
    let connected: Bool?
    let contactName: String?
    let savedContactId: String?
    let durationMinutes: Int?
    let notes: String?

    init(
        direction: String? = nil,
        contactType: String? = nil,
        customContactLabel: String? = nil,
        connected: Bool? = nil,
        contactName: String? = nil,
        savedContactId: String? = nil,
        durationMinutes: Int? = nil,
        notes: String? = nil
    ) {
        self.direction = direction
        self.contactType = contactType
        self.customContactLabel = customContactLabel
        self.connected = connected
        self.contactName = contactName
        self.savedContactId = savedContactId
        self.durationMinutes = durationMinutes
        self.notes = notes
    }
}

/// Matches OpenAPI CreateSavedContactRequest schema.
struct CreateSavedContactAPIRequest: Codable, Sendable {
    let contactName: String
    let contactType: String
    let phoneNumber: String?

    init(contactName: String, contactType: String, phoneNumber: String? = nil) {
        self.contactName = contactName
        self.contactType = contactType
        self.phoneNumber = phoneNumber
    }
}

/// Matches OpenAPI UpdateSavedContactRequest schema.
struct UpdateSavedContactAPIRequest: Codable, Sendable {
    let contactName: String?
    let contactType: String?
    let phoneNumber: String?
}

// MARK: - Response Data Models

/// Matches OpenAPI PhoneCall schema.
struct PhoneCallData: Codable, Sendable {
    let callId: String
    let timestamp: String
    let direction: String
    let contactType: String
    let customContactLabel: String?
    let connected: Bool
    let contactName: String?
    let savedContactId: String?
    let durationMinutes: Int?
    let notes: String?
    let callStreakDays: Int?
    let crossReferencePrompt: String?
}

/// Matches OpenAPI SavedContact schema.
struct SavedContactData: Codable, Sendable {
    let savedContactId: String
    let contactName: String
    let contactType: String
    let phoneNumber: String?
    let hasPhoneNumber: Bool?
}

/// Matches OpenAPI PhoneCallStreakResponse.data schema.
struct PhoneCallStreakData: Codable, Sendable {
    let currentStreakDays: Int
    let longestStreakDays: Int
    let lastCallDate: String?
    let totalCallsAllTime: Int
    let totalConnectedCalls: Int
}

/// Matches OpenAPI PhoneCallTrendsResponse.data schema.
struct PhoneCallTrendsData: Codable, Sendable {
    let period: String
    let totalCalls: Int
    let callsMade: Int
    let callsReceived: Int
    let connectedCalls: Int
    let attemptedCalls: Int
    let connectionRate: Double
    let averageCallsPerWeek: Double
    let contactTypeDistribution: [ContactTypeDistributionItem]?
    let previousPeriodComparison: PeriodComparisonData?
    let daysSinceLastCall: Int
    let isolationWarning: Bool

    struct ContactTypeDistributionItem: Codable, Sendable {
        let contactType: String
        let count: Int
        let percentage: Double
    }

    struct PeriodComparisonData: Codable, Sendable {
        let totalCallsDelta: Int
        let connectionRateDelta: Double
    }
}

/// Matches OpenAPI PhoneCallDailyTrendsResponse.data item schema.
struct DailyCallCountData: Codable, Sendable {
    let date: String
    let totalCalls: Int
    let callsMade: Int
    let callsReceived: Int
    let connectedCalls: Int
    let attemptedCalls: Int
}
