import Foundation
import SwiftUI
import SwiftData

// MARK: - AuthService Token Provider Adapter

/// Bridges AuthService to the AuthTokenProvider protocol required by APIClient.
struct AuthServiceTokenProvider: AuthTokenProvider, Sendable {
    private let authService: AuthService

    init(authService: AuthService) {
        self.authService = authService
    }

    var accessToken: String? {
        get async { authService.accessToken }
    }

    var refreshToken: String? {
        get async { authService.currentRefreshToken }
    }

    func updateTokens(accessToken: String, refreshToken: String, expiresIn: Int) async {
        authService.updateTokens(access: accessToken, refresh: refreshToken)
    }

    func clearTokens() async {
        authService.signOut()
    }
}

// MARK: - Service Container

@Observable
final class ServiceContainer {

    static let shared = ServiceContainer()

    let authService: AuthService
    let apiClient: APIClient
    let networkMonitor: NetworkMonitor
    let syncEngine: SyncEngine
    let biometricService: BiometricService
    let featureFlagService: FeatureFlagService
    let syncStatus: SyncStatus
    let modelContainer: ModelContainer

    private init() {
        // Local-only mode: all data stays in SwiftData, no API calls.
        // Set RR_LOCAL_ONLY=1 or omit RR_API_BASE_URL to enable.
        let localOnly = ProcessInfo.processInfo.environment["RR_LOCAL_ONLY"] == "1"
            || ProcessInfo.processInfo.environment["RR_API_BASE_URL"] == nil
        self.isLocalOnly = localOnly

        let auth = AuthService()
        let tokenProvider = AuthServiceTokenProvider(authService: auth)
        let network = NetworkMonitor()

        #if DEBUG
        let apiConfig: APIClientConfiguration
        if !localOnly,
           let devURL = ProcessInfo.processInfo.environment["RR_API_BASE_URL"],
           let url = URL(string: devURL) {
            apiConfig = APIClientConfiguration(
                baseURL: url,
                maxRetries: 3,
                initialRetryDelay: 1.0,
                requestTimeout: 30
            )
        } else {
            apiConfig = .local
        }
        #else
        let apiConfig = APIClientConfiguration.production
        #endif

        let api = APIClient(
            configuration: apiConfig,
            authProvider: tokenProvider
        )

        // Use the app's shared ModelContainer (includes RRSyncQueueItem and all models)
        let modelContainer: ModelContainer
        do {
            modelContainer = try RRModelConfiguration.makeContainer()
        } catch {
            fatalError("Failed to create ModelContainer for SyncEngine: \(error)")
        }

        let sync = SyncEngine(
            apiClient: api,
            networkMonitor: network,
            modelContainer: modelContainer
        )

        self.authService = auth
        self.apiClient = api
        self.networkMonitor = network
        self.syncEngine = sync
        self.syncStatus = sync.status
        self.biometricService = BiometricService()
        self.featureFlagService = FeatureFlagService()
        self.modelContainer = modelContainer

        // In local-only mode, auto-authenticate and skip network
        if localOnly {
            auth.enableLocalMode()
        } else {
            network.start()
        }
    }

    // MARK: - Feature Flags

    func isFeatureEnabled(_ key: String) -> Bool {
        featureFlagService.isEnabled(key)
    }

    /// When true, the app runs entirely on local SwiftData — no API calls.
    let isLocalOnly: Bool

    // MARK: - Lifecycle

    /// Call when the app enters the foreground to refresh state.
    func onForeground() async {
        guard !isLocalOnly else { return }
        if authService.isAuthenticated {
            try? await authService.refreshTokenIfNeeded()
            syncEngine.onAppForeground()

            if let token = authService.accessToken {
                try? await featureFlagService.syncFromServer(
                    baseURL: apiClient.configuration.baseURL,
                    accessToken: token
                )
            }
        }
    }
}

// MARK: - SwiftUI Environment

// ServiceContainer is injected via .environment(container) as an @Observable object.
// Access in views with: @Environment(ServiceContainer.self) var services
