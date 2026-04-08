import Foundation
import OSLog

// MARK: - Direction

enum CallDirection: String, CaseIterable, Sendable {
    case made
    case received

    var displayName: String {
        switch self {
        case .made: return "Made"
        case .received: return "Received"
        }
    }

    var icon: String {
        switch self {
        case .made: return "arrow.up.right"
        case .received: return "arrow.down.left"
        }
    }
}

// MARK: - Recovery Contact Type

enum RecoveryContactType: String, CaseIterable, Sendable {
    case sponsor
    case accountabilityPartner = "accountability-partner"
    case counselor
    case coach
    case supportPerson = "support-person"
    case custom

    var displayName: String {
        switch self {
        case .sponsor: return "Sponsor"
        case .accountabilityPartner: return "Accountability Partner"
        case .counselor: return "Counselor"
        case .coach: return "Coach"
        case .supportPerson: return "Support Person"
        case .custom: return "Custom"
        }
    }
}

// MARK: - Duration Quick-Select

enum DurationQuickSelect: Int, CaseIterable, Sendable {
    case five = 5
    case ten = 10
    case fifteen = 15
    case twenty = 20
    case thirty = 30
    case sixty = 60

    var displayLabel: String {
        "\(rawValue) min"
    }
}

// MARK: - Phone Call Entry (Local)

struct PhoneCallEntry: Identifiable, Sendable {
    let id: String // callId
    let timestamp: Date
    let direction: CallDirection
    let contactType: RecoveryContactType
    let customContactLabel: String?
    let connected: Bool
    let contactName: String?
    let savedContactId: String?
    let durationMinutes: Int?
    let notes: String?
    let callStreakDays: Int?
    let crossReferencePrompt: String?
}

// MARK: - Saved Contact (Local)

struct SavedContactEntry: Identifiable, Sendable {
    let id: String // savedContactId
    let contactName: String
    let contactType: RecoveryContactType
    let phoneNumber: String?
    let hasPhoneNumber: Bool
}

// MARK: - Post-Log Encouraging Messages

private let encouragingMessages: [String] = [
    "Connected. That's what recovery looks like.",
    "Picking up the phone takes more courage than most people realize. Well done.",
    "You didn't isolate today. That matters more than you know.",
    "Even the calls that don't connect show that you're fighting for your recovery."
]

// MARK: - ViewModel

@Observable
class PhoneCallViewModel {

    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "PhoneCallViewModel")

    // MARK: - State

    var history: [PhoneCallEntry] = []
    var savedContacts: [SavedContactEntry] = []
    var isLoading = false
    var error: String?

    // Streak
    var currentStreakDays: Int = 0
    var longestStreakDays: Int = 0
    var lastCallDate: String?
    var totalCallsAllTime: Int = 0

    // Trends
    var connectionRate: Double = 0
    var daysSinceLastCall: Int = 0
    var isolationWarning: Bool = false

    // Entry form state
    var formDirection: CallDirection = .made
    var formContactType: RecoveryContactType = .sponsor
    var formCustomLabel: String = ""
    var formConnected: Bool = true
    var formContactName: String = ""
    var formSavedContactId: String?
    var formDurationMinutes: Int?
    var formNotes: String = ""
    var formTimestamp: Date = Date()

    // Post-log state
    var showPostLogMessage: Bool = false
    var postLogMessage: String = ""

    // Feature flag
    var isFeatureEnabled: Bool = false

    // MARK: - Quick Log Defaults

    /// Last used contact type for quick log default.
    private var lastUsedContactType: RecoveryContactType = .sponsor

    // MARK: - Computed

    var callsToday: Int {
        let calendar = Calendar.current
        return history.filter { calendar.isDateInToday($0.timestamp) }.count
    }

    var callsThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history.filter { $0.timestamp >= weekAgo }.count
    }

    var totalMinutesThisWeek: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return history
            .filter { $0.timestamp >= weekAgo }
            .reduce(0) { $0 + ($1.durationMinutes ?? 0) }
    }

    var streakDisplayText: String {
        if currentStreakDays == 1 {
            return "1 day"
        }
        return "\(currentStreakDays) days"
    }

    var todayStatusText: String {
        if callsToday > 0 {
            return "\(callsToday) call\(callsToday == 1 ? "" : "s") today"
        }
        return "No calls yet today"
    }

    // MARK: - Load

    func load() async {
        isLoading = true
        defer { isLoading = false }

        // In real implementation, these would be API calls via APIClient.
        // For now, load from mock data / local storage.
        do {
            history = try await loadCallHistory()
            savedContacts = try await loadSavedContacts()
            await loadStreak()
        } catch {
            self.error = error.localizedDescription
            logger.error("Failed to load phone call data: \(error.localizedDescription)")
        }
    }

    // MARK: - Quick Log

    /// Quick log with minimal friction: direction defaults to made, contactType to last used, connected to true.
    func quickLog() async throws {
        let req = CreatePhoneCallRequest(
            direction: CallDirection.made.rawValue,
            contactType: lastUsedContactType.rawValue,
            connected: true
        )
        try await createCall(request: req)
    }

    // MARK: - Submit Full Log

    func submit() async throws {
        guard formContactType != .custom || !formCustomLabel.isEmpty else {
            throw ActivityError.validationFailed("Custom label is required when contact type is Custom.")
        }

        let req = CreatePhoneCallRequest(
            timestamp: ISO8601DateFormatter().string(from: formTimestamp),
            direction: formDirection.rawValue,
            contactType: formContactType.rawValue,
            customContactLabel: formContactType == .custom ? formCustomLabel : nil,
            connected: formConnected,
            contactName: formContactName.isEmpty ? nil : formContactName,
            savedContactId: formSavedContactId,
            durationMinutes: formDurationMinutes,
            notes: formNotes.isEmpty ? nil : formNotes
        )

        try await createCall(request: req)
        lastUsedContactType = formContactType
        resetForm()
    }

    // MARK: - Create Call (shared)

    private func createCall(request: CreatePhoneCallRequest) async throws {
        // TODO: Replace with actual APIClient call
        // let response: SiemensResponse<PhoneCallData> = try await apiClient.post(.createPhoneCall(request))
        // Map response to local entry and insert at top of history.

        let entry = PhoneCallEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            direction: CallDirection(rawValue: request.direction) ?? .made,
            contactType: RecoveryContactType(rawValue: request.contactType) ?? .sponsor,
            customContactLabel: request.customContactLabel,
            connected: request.connected,
            contactName: request.contactName,
            savedContactId: request.savedContactId,
            durationMinutes: request.durationMinutes,
            notes: request.notes,
            callStreakDays: currentStreakDays + 1,
            crossReferencePrompt: "You logged a call. Would you also like to log a person check-in?"
        )
        history.insert(entry, at: 0)
        currentStreakDays = entry.callStreakDays ?? currentStreakDays

        // Show rotating encouraging message.
        showEncouragingMessage()
    }

    // MARK: - Update (expand quick log)

    func expandQuickLog(callId: String, contactName: String?, durationMinutes: Int?, notes: String?) async throws {
        // TODO: Replace with actual PATCH call
        // let req = UpdatePhoneCallRequest(contactName: contactName, durationMinutes: durationMinutes, notes: notes)
        // let response: SiemensResponse<PhoneCallData> = try await apiClient.patch(.updatePhoneCall(callId: callId, req))

        if let index = history.firstIndex(where: { $0.id == callId }) {
            let existing = history[index]
            let updated = PhoneCallEntry(
                id: existing.id,
                timestamp: existing.timestamp, // preserved (immutable)
                direction: existing.direction,
                contactType: existing.contactType,
                customContactLabel: existing.customContactLabel,
                connected: existing.connected,
                contactName: contactName ?? existing.contactName,
                savedContactId: existing.savedContactId,
                durationMinutes: durationMinutes ?? existing.durationMinutes,
                notes: notes ?? existing.notes,
                callStreakDays: existing.callStreakDays,
                crossReferencePrompt: existing.crossReferencePrompt
            )
            history[index] = updated
        }
    }

    // MARK: - Delete

    func deleteCall(callId: String) async throws {
        // TODO: Replace with actual DELETE call
        // try await apiClient.delete(.deletePhoneCall(callId: callId))
        history.removeAll { $0.id == callId }
        await loadStreak() // Recalculate
    }

    // MARK: - Post-Log Message

    private var messageIndex = 0

    private func showEncouragingMessage() {
        postLogMessage = encouragingMessages[messageIndex % encouragingMessages.count]
        messageIndex += 1
        showPostLogMessage = true
    }

    // MARK: - Form Reset

    private func resetForm() {
        formDirection = .made
        formContactType = lastUsedContactType
        formCustomLabel = ""
        formConnected = true
        formContactName = ""
        formSavedContactId = nil
        formDurationMinutes = nil
        formNotes = ""
        formTimestamp = Date()
    }

    // MARK: - Isolation Warning

    var isolationWarningText: String {
        "It's been \(daysSinceLastCall) days since you last connected with someone by phone. Isolation is addiction's favorite weapon. Who could you call right now?"
    }

    // MARK: - Private Loaders

    private func loadCallHistory() async throws -> [PhoneCallEntry] {
        // TODO: Replace with API call
        return []
    }

    private func loadSavedContacts() async throws -> [SavedContactEntry] {
        // TODO: Replace with API call
        return []
    }

    private func loadStreak() async {
        // TODO: Replace with API call
        // let response: SiemensResponse<PhoneCallStreakData> = try await apiClient.get(.getPhoneCallStreak)
    }
}
