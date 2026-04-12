import Foundation
import Observation

// MARK: - Flow Step Enum

/// Represents each discrete step in a morning or evening affirmation session flow.
/// `nil` currentStep means the user is on the hub screen.
enum AffirmationFlowStep: Equatable {
    case morningCard(index: Int)   // 0, 1, 2
    case morningIntention
    case morningComplete
    case eveningAffirmation
    case eveningRating
    case eveningReflection
    case eveningComplete
}

// MARK: - Affirmation Session ViewModel

/// Central state machine for morning and evening affirmation session flows.
///
/// Coordinates with `AffirmationsAPIClient` to fetch session data, record
/// completions, and manage favorites/hidden affirmations. Handles offline
/// fallback gracefully — sessions are still marked locally even when the
/// API call fails.
@Observable
final class AffirmationSessionViewModel {

    // MARK: - Flow State

    /// Current step in the session flow. `nil` means the hub is displayed.
    var currentStep: AffirmationFlowStep?

    // MARK: - Session Data from API

    var morningSessionData: MorningSessionData?
    var eveningSessionData: EveningSessionData?

    // MARK: - User Inputs

    var intentionText: String = ""
    var dayRating: Int = 0
    var reflectionText: String = ""

    // MARK: - Hub Data

    var progress: AffirmationProgress?
    var levelInfo: LevelInfo?
    var completionData: SessionCompletionData?

    // MARK: - Loading State

    var isLoading: Bool = false
    var error: String?

    // MARK: - Today's Status

    /// Whether the user has completed a morning session today.
    /// Set to `true` after a successful (or locally-recorded) morning completion.
    var hasMorningSessionToday: Bool = false

    /// Whether the user has completed an evening session today.
    var hasEveningSessionToday: Bool = false

    // MARK: - Dependencies

    private let apiClient: AffirmationsAPIClient
    /// When true, sessions use bundled/cached content instead of API calls.
    let isLocalOnly: Bool

    // MARK: - Init

    init(apiClient: AffirmationsAPIClient, isLocalOnly: Bool = false) {
        self.apiClient = apiClient
        self.isLocalOnly = isLocalOnly
    }

    // MARK: - Hub Data Loading

    /// Fetches progress metrics and current level info for the hub screen.
    /// In local-only mode, skips API calls and leaves progress/level as nil.
    func loadHubData() async {
        guard !isLocalOnly else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let progressResp = try await apiClient.getProgress()
            progress = progressResp.data
            let levelResp = try await apiClient.getLevelInfo()
            levelInfo = levelResp.data
        } catch {
            // Silently continue — hub shows without progress data
        }
    }

    // MARK: - Session Lifecycle

    /// Fetches a morning session from the API and begins the morning flow at card 0.
    /// Falls back to local content if the API is unavailable or in local-only mode.
    func startMorningSession() async {
        isLoading = true
        defer { isLoading = false }

        if isLocalOnly {
            morningSessionData = Self.localMorningSession()
            currentStep = .morningCard(index: 0)
            return
        }

        do {
            let response = try await apiClient.getMorningSession()
            morningSessionData = response.data
            currentStep = .morningCard(index: 0)
        } catch {
            // Offline fallback: use local affirmations
            morningSessionData = Self.localMorningSession()
            currentStep = .morningCard(index: 0)
        }
    }

    /// Fetches an evening session from the API and begins the evening flow.
    /// Falls back to local content if the API is unavailable or in local-only mode.
    func startEveningSession() async {
        isLoading = true
        defer { isLoading = false }

        if isLocalOnly {
            eveningSessionData = Self.localEveningSession()
            currentStep = .eveningAffirmation
            return
        }

        do {
            let response = try await apiClient.getEveningSession()
            eveningSessionData = response.data
            currentStep = .eveningAffirmation
        } catch {
            eveningSessionData = Self.localEveningSession()
            currentStep = .eveningAffirmation
        }
    }

    // MARK: - Local Session Builders

    private static func localMorningSession() -> MorningSessionData {
        let affirmations = localAffirmationPool().prefix(3).map { $0 }
        return MorningSessionData(
            sessionId: "local-\(UUID().uuidString.prefix(8))",
            sessionType: .morning,
            affirmations: affirmations,
            intentionPrompt: "What is one thing you want to protect in your recovery today?",
            createdAt: Date()
        )
    }

    private static func localEveningSession() -> EveningSessionData {
        let affirmation = localAffirmationPool().randomElement() ?? localAffirmationPool()[0]
        return EveningSessionData(
            sessionId: "local-\(UUID().uuidString.prefix(8))",
            sessionType: .evening,
            affirmation: affirmation,
            morningIntention: nil,
            ratingPrompt: "How well did you live out your morning intention today?",
            createdAt: Date()
        )
    }

    private static func localAffirmationPool() -> [AffirmationItem] {
        [
            AffirmationItem(id: "local_001", text: "I am accepted in Christ. My identity is not defined by my past.", level: 1, coreBeliefs: [1], category: .selfWorth, track: .faithBased, recoveryStage: .early),
            AffirmationItem(id: "local_002", text: "I am secure because God holds me. I do not need to control everything.", level: 1, coreBeliefs: [2], category: .selfWorth, track: .faithBased, recoveryStage: .early),
            AffirmationItem(id: "local_003", text: "I am significant because God created me with purpose.", level: 1, coreBeliefs: [3], category: .purposeMeaning, track: .faithBased, recoveryStage: .early),
            AffirmationItem(id: "local_004", text: "My recovery is evidence of God's faithfulness, not my perfection.", level: 1, coreBeliefs: [1, 3], category: .shameResilience, track: .faithBased, recoveryStage: .early),
            AffirmationItem(id: "local_005", text: "I choose honesty today because secrets keep me sick.", level: 1, coreBeliefs: [2], category: .integrityHonesty, track: .standard, recoveryStage: .early),
            AffirmationItem(id: "local_006", text: "I am not alone. God is with me and my community supports me.", level: 1, coreBeliefs: [1, 2], category: .connection, track: .faithBased, recoveryStage: .early),
            AffirmationItem(id: "local_007", text: "Today I will guard my eyes, my heart, and my mind.", level: 1, coreBeliefs: [2], category: .dailyStrength, track: .standard, recoveryStage: .early),
            AffirmationItem(id: "local_008", text: "A setback is not my story. God's grace is bigger than my worst day.", level: 1, coreBeliefs: [1, 3], category: .shameResilience, track: .faithBased, recoveryStage: .early),
            AffirmationItem(id: "local_009", text: "I am worth fighting for. My family is worth fighting for.", level: 1, coreBeliefs: [3], category: .healthyRelationships, track: .standard, recoveryStage: .early),
            AffirmationItem(id: "local_010", text: "Vulnerability is not weakness. It is the doorway to freedom.", level: 2, coreBeliefs: [1, 2], category: .emotionalRegulation, track: .standard, recoveryStage: .middle),
        ]
    }

    // MARK: - Step Navigation

    /// Advances the flow to the next step based on the current state.
    func advanceStep() {
        guard let step = currentStep else { return }
        switch step {
        case .morningCard(let index):
            if index < 2 {
                currentStep = .morningCard(index: index + 1)
            } else {
                currentStep = .morningIntention
            }
        case .morningIntention:
            currentStep = .morningComplete
            Task { await completeMorningSession() }
        case .morningComplete:
            resetFlow()
        case .eveningAffirmation:
            currentStep = .eveningRating
        case .eveningRating:
            currentStep = .eveningReflection
        case .eveningReflection:
            currentStep = .eveningComplete
            Task { await completeEveningSession() }
        case .eveningComplete:
            resetFlow()
        }
    }

    /// Navigates backward through the flow where applicable.
    func goBack() {
        guard let step = currentStep else { return }
        switch step {
        case .morningCard(let index):
            if index > 0 {
                currentStep = .morningCard(index: index - 1)
            }
        case .morningIntention:
            currentStep = .morningCard(index: 2)
        case .eveningRating:
            currentStep = .eveningAffirmation
        case .eveningReflection:
            currentStep = .eveningRating
        default:
            // No back navigation from complete screens or first card
            break
        }
    }

    // MARK: - Session Completion

    /// Records morning session completion with the API. Falls back to local tracking on failure.
    private func completeMorningSession() async {
        guard let session = morningSessionData else { return }
        if isLocalOnly {
            hasMorningSessionToday = true
            return
        }
        do {
            let request = CompleteMorningRequest(
                sessionId: session.sessionId,
                intention: intentionText.isEmpty ? nil : intentionText,
                affirmationInteractions: nil
            )
            let response = try await apiClient.completeMorningSession(request)
            completionData = response.data
            hasMorningSessionToday = true
        } catch {
            hasMorningSessionToday = true
        }
    }

    private func completeEveningSession() async {
        guard let session = eveningSessionData else { return }
        if isLocalOnly {
            hasEveningSessionToday = true
            return
        }
        do {
            let request = CompleteEveningRequest(
                sessionId: session.sessionId,
                dayRating: dayRating,
                reflection: reflectionText.isEmpty ? nil : reflectionText
            )
            let response = try await apiClient.completeEveningSession(request)
            completionData = response.data
            hasEveningSessionToday = true
        } catch {
            hasEveningSessionToday = true
        }
    }

    // MARK: - Affirmation Actions

    func favoriteAffirmation(id: String) async {
        guard !isLocalOnly else { return }
        do {
            _ = try await apiClient.addFavorite(affirmationId: id)
        } catch {
            // Best-effort
        }
    }

    /// Hides an affirmation from future sessions. Returns a replacement affirmation if the API provides one.
    @discardableResult
    func hideAffirmation(id: String) async -> AffirmationItem? {
        guard !isLocalOnly else { return nil }
        do {
            let response = try await apiClient.hideAffirmation(affirmationId: id)
            return response.data.replacement
        } catch {
            return nil
        }
    }

    // MARK: - Flow Reset

    /// Resets the flow back to hub mode and clears all transient session state.
    func resetFlow() {
        currentStep = nil
        intentionText = ""
        dayRating = 0
        reflectionText = ""
        completionData = nil
    }
}
