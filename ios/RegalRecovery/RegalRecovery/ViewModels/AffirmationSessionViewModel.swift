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

    // MARK: - Init

    init(apiClient: AffirmationsAPIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Hub Data Loading

    /// Fetches progress metrics and current level info for the hub screen.
    func loadHubData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let progressResp = try await apiClient.getProgress()
            progress = progressResp.data
            let levelResp = try await apiClient.getLevelInfo()
            levelInfo = levelResp.data
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Session Lifecycle

    /// Fetches a morning session from the API and begins the morning flow at card 0.
    func startMorningSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await apiClient.getMorningSession()
            morningSessionData = response.data
            currentStep = .morningCard(index: 0)
        } catch {
            self.error = "Unable to load session. Please try again."
        }
    }

    /// Fetches an evening session from the API and begins the evening flow.
    func startEveningSession() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await apiClient.getEveningSession()
            eveningSessionData = response.data
            currentStep = .eveningAffirmation
        } catch {
            self.error = "Unable to load session. Please try again."
        }
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
            // Session still recorded locally even if API fails
            hasMorningSessionToday = true
        }
    }

    /// Records evening session completion with the API. Falls back to local tracking on failure.
    private func completeEveningSession() async {
        guard let session = eveningSessionData else { return }
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
            // Session still recorded locally even if API fails
            hasEveningSessionToday = true
        }
    }

    // MARK: - Affirmation Actions

    /// Adds an affirmation to the user's favorites. Errors are ignored gracefully.
    func favoriteAffirmation(id: String) async {
        do {
            _ = try await apiClient.addFavorite(affirmationId: id)
        } catch {
            // Ignore errors — favorite is a best-effort action
        }
    }

    /// Hides an affirmation from future sessions. Returns a replacement affirmation if the API provides one.
    @discardableResult
    func hideAffirmation(id: String) async -> AffirmationItem? {
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
