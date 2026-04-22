import SwiftUI
import SwiftData

extension Notification.Name {
    static let emergencyDismissed = Notification.Name("emergencyDismissed")
}

@main
struct RegalRecoveryApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    @AppStorage("biometricLockEnabled") private var biometricLockEnabled = false
    @State private var showEmergencyOverlay = false
    @State private var showUrgeSurfingTimer = false
    @State private var showUrgeLogAfterDismiss = false
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
            .environment(\.locale, LanguageManager.shared.effectiveLocale)
            .environment(services.authService as AuthService)
            .environment(services.biometricService as BiometricService)
            .environment(services.featureFlagService as FeatureFlagService)
            .environment(services.networkMonitor as NetworkMonitor)
            .environment(services)
            .modelContainer(services.modelContainer)
            .task {
                let context = ModelContext(services.modelContainer)
                try? SeedData.seedFeatureFlagsIfNeeded(context: context)
                await reschedulePlanNotifications(context: context)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                handleForeground()
            }
        }
    }

    private var mainTabView: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
                TodayView()
                    .tabItem { Label("Today", systemImage: "sun.max.fill") }
                    .tag(0)

                RecoveryWorkView()
                    .tabItem { Label("Work", systemImage: "briefcase.fill") }
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

            EmergencyFABButton(
                onTap: { showUrgeSurfingTimer = true },
                onLongPress: { showEmergencyOverlay = true }
            )
            .padding(.trailing, 16)
            .padding(.bottom, 60)
        }
        .fullScreenCover(isPresented: $showEmergencyOverlay) {
            EmergencyOverlayView(isPresented: $showEmergencyOverlay)
        }
        .fullScreenCover(isPresented: $showUrgeSurfingTimer) {
            UrgeSurfingTimerView(isPresented: $showUrgeSurfingTimer)
        }
        .sheet(isPresented: $showUrgeLogAfterDismiss) {
            NavigationStack {
                UrgeLogView()
                    .navigationTitle("Log Urge")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .emergencyDismissed)) { notification in
            if let reason = notification.userInfo?["reason"] as? String, reason == "okayNow" {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showUrgeLogAfterDismiss = true
                }
            }
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
            let context = ModelContext(services.modelContainer)
            await reschedulePlanNotifications(context: context)
        }
    }

    /// Reschedule plan-aware notifications from the active recovery plan.
    private func reschedulePlanNotifications(context: ModelContext) async {
        let scheduler = PlanNotificationScheduler()

        let planDescriptor = FetchDescriptor<RRRecoveryPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        guard let plan = try? context.fetch(planDescriptor).first,
              let items = plan.items else { return }

        let enabledItems = items.filter(\.isEnabled)

        // Load user first name for personalized notifications
        let userDescriptor = FetchDescriptor<RRUser>()
        let userName = (try? context.fetch(userDescriptor).first)?
            .name.components(separatedBy: " ").first ?? "friend"

        await scheduler.scheduleFromPlan(items: enabledItems, userName: userName)
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
