import Foundation

// MARK: - Domain Models

struct PersonCheckInEntry: Identifiable {
    let id: String
    let checkInType: PersonCheckInType
    let method: PersonCheckInMethod
    let timestamp: Date
    let contactName: String?
    let durationMinutes: Int?
    let qualityRating: Int?
    let topicsDiscussed: [PersonCheckInTopic]
    let notes: String?
    let followUpItems: [PersonFollowUpItem]

    init(
        id: String = UUID().uuidString,
        checkInType: PersonCheckInType,
        method: PersonCheckInMethod = .inPerson,
        timestamp: Date = Date(),
        contactName: String? = nil,
        durationMinutes: Int? = nil,
        qualityRating: Int? = nil,
        topicsDiscussed: [PersonCheckInTopic] = [],
        notes: String? = nil,
        followUpItems: [PersonFollowUpItem] = []
    ) {
        self.id = id
        self.checkInType = checkInType
        self.method = method
        self.timestamp = timestamp
        self.contactName = contactName
        self.durationMinutes = durationMinutes
        self.qualityRating = qualityRating
        self.topicsDiscussed = topicsDiscussed
        self.notes = notes
        self.followUpItems = followUpItems
    }
}

struct PersonFollowUpItem: Identifiable {
    let id = UUID()
    let text: String
    let goalId: String?
}

enum PersonCheckInType: String, CaseIterable, Codable {
    case spouse
    case sponsor
    case counselorCoach = "counselor-coach"

    var displayName: String {
        switch self {
        case .spouse: return "Spouse"
        case .sponsor: return "Sponsor"
        case .counselorCoach: return "Counselor/Coach"
        }
    }
}

enum PersonCheckInMethod: String, CaseIterable, Codable {
    case inPerson = "in-person"
    case phoneCall = "phone-call"
    case videoCall = "video-call"
    case textMessage = "text-message"
    case appMessaging = "app-messaging"

    var displayName: String {
        switch self {
        case .inPerson: return "In Person"
        case .phoneCall: return "Phone Call"
        case .videoCall: return "Video Call"
        case .textMessage: return "Text Message"
        case .appMessaging: return "App Messaging"
        }
    }

    var iconName: String {
        switch self {
        case .inPerson: return "person.2.fill"
        case .phoneCall: return "phone.fill"
        case .videoCall: return "video.fill"
        case .textMessage: return "message.fill"
        case .appMessaging: return "bubble.left.and.bubble.right.fill"
        }
    }
}

enum PersonCheckInTopic: String, CaseIterable, Codable {
    case sobrietyRecovery = "sobriety-recovery"
    case stepWork = "step-work"
    case triggersUrges = "triggers-urges"
    case emotionsFeelings = "emotions-feelings"
    case relationshipsMarriage = "relationships-marriage"
    case boundaries
    case goalsCommitments = "goals-commitments"
    case accountability
    case spiritualLife = "spiritual-life"
    case generalLifeSupport = "general-life-support"
    case crisisEmergency = "crisis-emergency"
    case other

    var displayName: String {
        switch self {
        case .sobrietyRecovery: return "Sobriety / Recovery"
        case .stepWork: return "Step Work"
        case .triggersUrges: return "Triggers / Urges"
        case .emotionsFeelings: return "Emotions / Feelings"
        case .relationshipsMarriage: return "Relationships / Marriage"
        case .boundaries: return "Boundaries"
        case .goalsCommitments: return "Goals / Commitments"
        case .accountability: return "Accountability"
        case .spiritualLife: return "Spiritual Life"
        case .generalLifeSupport: return "General Life / Support"
        case .crisisEmergency: return "Crisis / Emergency"
        case .other: return "Other"
        }
    }
}

struct PersonCheckInStreakInfo {
    let checkInType: PersonCheckInType
    let currentStreak: Int
    let longestStreak: Int
    let streakUnit: String
    let checkInsThisWeek: Int
    let checkInsThisMonth: Int
    let averagePerWeek: Double
}

// MARK: - ViewModel

@Observable
class PersonCheckInViewModel {

    // MARK: - State

    var history: [PersonCheckInEntry] = []
    var streaks: [PersonCheckInStreakInfo] = []
    var isLoading = false
    var error: String?
    var encouragement: String?

    // Form state
    var selectedCheckInType: PersonCheckInType = .spouse
    var selectedMethod: PersonCheckInMethod = .inPerson
    var contactName: String = ""
    var durationMinutes: Int = 15
    var qualityRating: Int = 3
    var selectedTopics: Set<PersonCheckInTopic> = []
    var notes: String = ""
    var followUpItems: [String] = []
    var currentFollowUpText: String = ""

    // Calendar state
    var calendarDays: [CalendarDayDTO] = []
    var selectedMonth: String = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }()

    // MARK: - Computed

    var qualityRatingLabel: String {
        switch qualityRating {
        case 1: return "Surface-level"
        case 2: return "Somewhat open"
        case 3: return "Honest"
        case 4: return "Deep"
        case 5: return "Deep and honest"
        default: return ""
        }
    }

    var checkInsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history.filter { $0.timestamp >= weekAgo }.count
    }

    var streakDisplayText: String {
        guard let spouseStreak = streaks.first(where: { $0.checkInType == .spouse }) else {
            return "No streak data"
        }
        return "\(spouseStreak.currentStreak) \(spouseStreak.streakUnit)"
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // TODO: Replace with API calls when backend is available.
        history = [
            PersonCheckInEntry(
                id: "pci_001",
                checkInType: .spouse,
                method: .inPerson,
                timestamp: Date().addingTimeInterval(-86400 * 1),
                contactName: "Sarah",
                durationMinutes: 30,
                qualityRating: 4,
                topicsDiscussed: [.relationshipsMarriage, .emotionsFeelings, .accountability],
                notes: "Had a really honest conversation about this week."
            ),
            PersonCheckInEntry(
                id: "pci_002",
                checkInType: .sponsor,
                method: .phoneCall,
                timestamp: Date().addingTimeInterval(-86400 * 2),
                contactName: "Mike S.",
                durationMinutes: 15,
                qualityRating: 5,
                topicsDiscussed: [.stepWork, .accountability]
            ),
            PersonCheckInEntry(
                id: "pci_003",
                checkInType: .counselorCoach,
                method: .inPerson,
                timestamp: Date().addingTimeInterval(-86400 * 5),
                contactName: "Dr. Johnson",
                durationMinutes: 50,
                qualityRating: 4,
                topicsDiscussed: [.triggersUrges, .emotionsFeelings, .boundaries]
            ),
        ]

        streaks = [
            PersonCheckInStreakInfo(checkInType: .spouse, currentStreak: 5, longestStreak: 21, streakUnit: "days", checkInsThisWeek: 4, checkInsThisMonth: 18, averagePerWeek: 4.5),
            PersonCheckInStreakInfo(checkInType: .sponsor, currentStreak: 12, longestStreak: 12, streakUnit: "days", checkInsThisWeek: 3, checkInsThisMonth: 14, averagePerWeek: 3.2),
            PersonCheckInStreakInfo(checkInType: .counselorCoach, currentStreak: 8, longestStreak: 15, streakUnit: "weeks", checkInsThisWeek: 1, checkInsThisMonth: 4, averagePerWeek: 1.0),
        ]
    }

    // MARK: - Quick Log

    func quickLog(type: PersonCheckInType) async throws {
        isLoading = true
        defer { isLoading = false }

        let entry = PersonCheckInEntry(
            checkInType: type,
            method: lastUsedMethod(for: type),
            timestamp: Date()
        )

        history.insert(entry, at: 0)
        encouragement = PersonCheckInEncouragement.random()
    }

    // MARK: - Submit Full Entry

    func submit() async throws {
        guard !contactName.isEmpty || !selectedTopics.isEmpty || notes.isEmpty else {
            // Minimal validation - at least type and method are required (set by default).
        }

        isLoading = true
        defer { isLoading = false }

        let entry = PersonCheckInEntry(
            checkInType: selectedCheckInType,
            method: selectedMethod,
            contactName: contactName.isEmpty ? nil : contactName,
            durationMinutes: durationMinutes > 0 ? durationMinutes : nil,
            qualityRating: qualityRating,
            topicsDiscussed: Array(selectedTopics),
            notes: notes.isEmpty ? nil : notes,
            followUpItems: followUpItems.map { PersonFollowUpItem(text: $0, goalId: nil) }
        )

        history.insert(entry, at: 0)
        encouragement = PersonCheckInEncouragement.random()
        resetForm()
    }

    // MARK: - Follow-up Items

    func addFollowUpItem() {
        guard !currentFollowUpText.isEmpty, followUpItems.count < 3 else { return }
        followUpItems.append(currentFollowUpText)
        currentFollowUpText = ""
    }

    func removeFollowUpItem(at index: Int) {
        guard index >= 0, index < followUpItems.count else { return }
        followUpItems.remove(at: index)
    }

    // MARK: - Private

    private func lastUsedMethod(for type: PersonCheckInType) -> PersonCheckInMethod {
        if let last = history.first(where: { $0.checkInType == type }) {
            return last.method
        }
        return .inPerson
    }

    private func resetForm() {
        selectedCheckInType = .spouse
        selectedMethod = .inPerson
        contactName = ""
        durationMinutes = 15
        qualityRating = 3
        selectedTopics = []
        notes = ""
        followUpItems = []
        currentFollowUpText = ""
    }
}

// MARK: - Encouragement Messages

enum PersonCheckInEncouragement {
    static let messages = [
        "Showing up for that conversation took courage. That's recovery in action.",
        "The people in your corner need to hear from you. And you need to hear from them.",
        "Every honest conversation builds something that addiction tried to destroy: trust.",
        "You didn't do today alone. That's worth celebrating.",
    ]

    static func random() -> String {
        messages.randomElement() ?? messages[0]
    }
}
