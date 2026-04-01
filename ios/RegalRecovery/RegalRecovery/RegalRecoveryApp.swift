import SwiftUI
import SwiftData

@main
struct RegalRecoveryApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @State private var showEmergencyOverlay = false
    @State private var selectedTab = 0
    @State private var isUnlocked = true

    private let services = ServiceContainer.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !isUnlocked && biometricLockEnabled {
                    biometricLockScreen
                } else if hasCompletedOnboarding {
                    mainTabView
                } else {
                    OnboardingFlow(onComplete: {
                        withAnimation { hasCompletedOnboarding = true }
                    })
                }
            }
            .preferredColorScheme(colorScheme)
            .environment(services.authService as AuthService)
            .environment(services.biometricService as BiometricService)
            .environment(services.featureFlagService as FeatureFlagService)
            .environment(services.networkMonitor as NetworkMonitor)
            .environment(services)
            .modelContainer(services.modelContainer)
            .task {
                let context = ModelContext(services.modelContainer)
                try? SeedData.seedDatabase(context: context)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                handleForeground()
            }
        }
    }

    private var mainTabView: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                ActivitiesListView()
                    .tabItem { Label("Activities", systemImage: "list.bullet.clipboard.fill") }
                    .tag(1)

                RecoveryProgressView()
                    .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                    .tag(2)

                ContentTabView()
                    .tabItem { Label("Resources", systemImage: "book.fill") }
                    .tag(3)

                SettingsView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                    .tag(4)
            }
            .tint(Color.rrPrimary)

            EmergencyFABButton {
                showEmergencyOverlay = true
            }
            .padding(.trailing, 16)
            .padding(.bottom, 60)
        }
        .fullScreenCover(isPresented: $showEmergencyOverlay) {
            EmergencyOverlayView(isPresented: $showEmergencyOverlay)
        }
    }

    private var biometricLockScreen: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrPrimary)

            Text("Regal Recovery")
                .font(.title2.weight(.semibold))

            Text("Unlock to continue")
                .foregroundStyle(.secondary)

            Button {
                authenticateWithBiometrics()
            } label: {
                Label("Unlock with \(services.biometricService.biometricName)", systemImage: "faceid")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.rrPrimary)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .onAppear {
            authenticateWithBiometrics()
        }
    }

    private var colorScheme: ColorScheme? {
        switch AppearanceMode(rawValue: appearanceMode) {
        case .light: return .light
        case .dark: return .dark
        default: return nil
        }
    }

    // MARK: - Lifecycle

    private func handleForeground() {
        if biometricLockEnabled {
            isUnlocked = false
        }

        Task {
            await services.onForeground()
        }
    }

    private func authenticateWithBiometrics() {
        guard services.biometricService.canUseBiometrics() else {
            isUnlocked = true
            return
        }

        Task {
            do {
                let success = try await services.biometricService.authenticate(
                    reason: "Unlock Regal Recovery"
                )
                await MainActor.run {
                    if success {
                        withAnimation { isUnlocked = true }
                    }
                }
            } catch {
                await MainActor.run {
                    isUnlocked = true
                }
            }
        }
    }
}
