import SwiftUI
import UserNotifications
import CoreLocation
import LocalAuthentication
import AppTrackingTransparency

// MARK: - Permission Page Model

private struct PermissionPage: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let headline: String
    let bullets: [(icon: String, text: String)]
    let allowLabel: String
    let skipLabel: String
}

// MARK: - Permissions View

struct PermissionsView: View {
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var locationManager = OnboardingLocationManager()

    private let pages: [PermissionPage] = [
        PermissionPage(
            id: "notifications",
            icon: "bell.badge.fill",
            iconColor: .rrPrimary,
            title: "Stay on Track",
            headline: "Gentle reminders keep your recovery front and center.",
            bullets: [
                (icon: "sunrise.fill", text: "Morning commitment reminders"),
                (icon: "moon.stars.fill", text: "Evening check-in prompts"),
                (icon: "text.quote", text: "Daily affirmation notifications"),
                (icon: "exclamationmark.triangle.fill", text: "Urge surfing encouragement"),
            ],
            allowLabel: "Enable Notifications",
            skipLabel: "Not Now"
        ),
        PermissionPage(
            id: "location",
            icon: "location.fill",
            iconColor: .blue,
            title: "Find Meetings Near You",
            headline: "Locate SA and Celebrate Recovery meetings in your area.",
            bullets: [
                (icon: "map.fill", text: "Nearby meeting search"),
                (icon: "clock.fill", text: "Time journal location context"),
                (icon: "shield.checkered", text: "Your location is never shared or stored on our servers"),
            ],
            allowLabel: "Allow Location",
            skipLabel: "Not Now"
        ),
        PermissionPage(
            id: "locationAlways",
            icon: "location.fill.viewfinder",
            iconColor: .blue,
            title: "Background Meeting Alerts",
            headline: "Allow location access at all times so we can notify you when you're near a meeting.",
            bullets: [
                (icon: "bell.badge.fill", text: "Get notified about nearby meetings"),
                (icon: "shield.checkered", text: "Location-aware safety reminders"),
                (icon: "lock.shield.fill", text: "Your location is never shared or stored on our servers"),
            ],
            allowLabel: "Always Allow",
            skipLabel: "Not Now"
        ),
        PermissionPage(
            id: "biometrics",
            icon: "faceid",
            iconColor: .rrPrimary,
            title: "Protect Your Privacy",
            headline: "Your recovery data is deeply personal. Lock it with biometrics so only you can access it.",
            bullets: [
                (icon: "lock.shield.fill", text: "App locks instantly when backgrounded"),
                (icon: "eye.slash.fill", text: "No one can open your journal or logs"),
                (icon: "bolt.fill", text: "Unlock instantly with Face ID or Touch ID"),
            ],
            allowLabel: "Enable Face ID",
            skipLabel: "Not Now"
        ),
        PermissionPage(
            id: "tracking",
            icon: "hand.raised.fill",
            iconColor: .rrPrimary,
            title: "Help Us Reach More People",
            headline: "Allow tracking to help us understand how people discover Regal Recovery. This never shares your personal recovery data.",
            bullets: [
                (icon: "chart.bar.fill", text: "Helps us measure which outreach efforts work"),
                (icon: "lock.shield.fill", text: "Your journal, logs, and recovery data stay private"),
                (icon: "gearshape.fill", text: "You can change this anytime in Settings"),
            ],
            allowLabel: "Allow Tracking",
            skipLabel: "Not Now"
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            progressIndicator
                .padding(.top, 16)

            TabView(selection: $currentStep) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                    permissionPage(page, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentStep)
        }
        .background(Color.rrBackground.ignoresSafeArea())
        .onAppear {
            updateBiometricLabel()
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pages.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                    .frame(width: index == currentStep ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Page Layout

    private func permissionPage(_ page: PermissionPage, index: Int) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 56))
                .foregroundStyle(page.iconColor)
                .frame(width: 100, height: 100)
                .background(page.iconColor.opacity(0.12))
                .clipShape(Circle())
                .padding(.bottom, 24)

            // Title
            Text(page.title)
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)

            // Headline
            Text(page.headline)
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)

            // Bullet points
            VStack(alignment: .leading, spacing: 16) {
                ForEach(page.bullets, id: \.text) { bullet in
                    HStack(spacing: 14) {
                        Image(systemName: bullet.icon)
                            .font(.body)
                            .foregroundStyle(page.iconColor)
                            .frame(width: 24)
                        Text(bullet.text)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // Allow button
            RRButton(page.allowLabel, icon: nil) {
                handleAllow(for: page.id)
            }
            .padding(.horizontal, 32)

            // Skip button
            Button {
                advance()
            } label: {
                Text(page.skipLabel)
                    .font(RRFont.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.vertical, 12)
            }
            .padding(.bottom, 32)
        }
    }

    // MARK: - Permission Handlers

    private func handleAllow(for permissionId: String) {
        switch permissionId {
        case "notifications":
            requestNotifications()
        case "location":
            requestLocation()
        case "locationAlways":
            requestLocationAlways()
        case "biometrics":
            requestBiometrics()
        case "tracking":
            requestTracking()
        default:
            advance()
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async { advance() }
        }
    }

    private func requestLocation() {
        locationManager.onResult = { advance() }
        locationManager.requestPermission()
    }

    private func requestLocationAlways() {
        locationManager.onResult = { advance() }
        locationManager.requestAlwaysPermission()
    }

    private func requestTracking() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async { advance() }
        }
    }

    private func requestBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            UserDefaults.standard.set(false, forKey: "biometricLockEnabled")
            advance()
            return
        }
        Task {
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Verify to enable biometric lock for Regal Recovery"
                )
                await MainActor.run {
                    UserDefaults.standard.set(success, forKey: "biometricLockEnabled")
                    advance()
                }
            } catch {
                await MainActor.run {
                    UserDefaults.standard.set(false, forKey: "biometricLockEnabled")
                    advance()
                }
            }
        }
    }

    private func advance() {
        if currentStep < pages.count - 1 {
            withAnimation { currentStep += 1 }
        } else {
            onComplete()
        }
    }

    private func updateBiometricLabel() {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        // The page uses a static label; biometric type is detected at runtime
        // by the BiometricService used elsewhere in the app.
    }
}

// MARK: - Location Manager Helper

/// Minimal CLLocationManager wrapper for onboarding permission request.
@Observable
private class OnboardingLocationManager: NSObject, CLLocationManagerDelegate {
    var onResult: (() -> Void)?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            onResult?()
        }
    }

    func requestAlwaysPermission() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        } else {
            onResult?()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined {
            onResult?()
        }
    }
}

#Preview {
    PermissionsView(onComplete: {})
}
