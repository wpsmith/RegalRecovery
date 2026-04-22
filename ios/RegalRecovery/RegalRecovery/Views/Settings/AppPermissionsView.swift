import AVFoundation
import AppTrackingTransparency
import Contacts
import CoreLocation
import LocalAuthentication
import SwiftUI
import UserNotifications

// MARK: - Permission Model

private enum PermissionStatus: String {
    case granted = "Granted"
    case denied = "Denied"
    case notDetermined = "Not Asked"

    var color: Color {
        switch self {
        case .granted: return .rrSuccess
        case .denied: return .rrDestructive
        case .notDetermined: return .rrTextSecondary
        }
    }
}

private struct PermissionItem: Identifiable {
    let id = UUID()
    let permissionKey: String
    let name: String
    let icon: String
    let iconColor: Color
    let status: PermissionStatus
    let description: String
    let action: (() -> Void)?
}

// MARK: - Location Manager Helper

/// Minimal CLLocationManager wrapper for permission requests from Settings.
@Observable
private class SettingsLocationManager: NSObject, CLLocationManagerDelegate {
    var onResult: (() -> Void)?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestWhenInUse() {
        let status = manager.authorizationStatus
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else {
            onResult?()
        }
    }

    func requestAlways() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse {
            manager.requestAlwaysAuthorization()
        } else {
            onResult?()
        }
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus != .notDetermined {
            onResult?()
        }
    }
}

// MARK: - View

struct AppPermissionsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var permissions: [PermissionItem] = []
    @State private var locationManager = SettingsLocationManager()

    var body: some View {
        List {
            Section {
                if permissions.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(permissions) { permission in
                        permissionRow(permission)
                    }
                }
            } header: {
                Text("Permissions")
            } footer: {
                Text("Tap a permission to request it, or open iOS Settings for denied permissions.")
                    .font(RRFont.caption)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("App Permissions")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadPermissions()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await loadPermissions()
                }
            }
        }
    }

    // MARK: - Permission Row

    @ViewBuilder
    private func permissionRow(_ permission: PermissionItem) -> some View {
        let isTappable = permission.status != .granted && permission.action != nil

        Group {
            if isTappable {
                Button {
                    permission.action?()
                } label: {
                    permissionRowContent(permission)
                }
                .buttonStyle(.plain)
            } else {
                permissionRowContent(permission)
            }
        }
    }

    @ViewBuilder
    private func permissionRowContent(_ permission: PermissionItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: permission.icon)
                .font(.body)
                .foregroundStyle(permission.iconColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(permission.name)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Text(permission.description)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                if permission.status == .denied {
                    Text("Tap to open Settings and enable")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrPrimary)
                        .padding(.top, 1)
                }
            }

            Spacer()

            RRBadge(text: permission.status.rawValue, color: permission.status.color)

            if permission.status == .notDetermined {
                Text("Request")
                    .font(RRFont.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrPrimary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Load Permissions

    @MainActor
    private func loadPermissions() async {
        var items: [PermissionItem] = []

        // 1. Notifications
        let notifSettings = await UNUserNotificationCenter.current().notificationSettings()
        let notifStatus: PermissionStatus = switch notifSettings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: .granted
        case .denied: .denied
        default: .notDetermined
        }
        items.append(PermissionItem(
            permissionKey: "notifications",
            name: "Notifications",
            icon: "bell.fill",
            iconColor: .orange,
            status: notifStatus,
            description: "Daily reminders and recovery alerts",
            action: notifStatus == .notDetermined ? requestNotifications :
                    notifStatus == .denied ? openSettings : nil
        ))

        // 2. Location (When In Use)
        let locationAuth = locationManager.authorizationStatus
        let whenInUseStatus: PermissionStatus = switch locationAuth {
        case .authorizedWhenInUse, .authorizedAlways: .granted
        case .denied, .restricted: .denied
        default: .notDetermined
        }
        items.append(PermissionItem(
            permissionKey: "locationWhenInUse",
            name: "Location (When In Use)",
            icon: "location.fill",
            iconColor: .blue,
            status: whenInUseStatus,
            description: "Journal entries and meeting locations",
            action: whenInUseStatus == .notDetermined ? requestLocationWhenInUse :
                    whenInUseStatus == .denied ? openSettings : nil
        ))

        // 3. Location (Always)
        let alwaysStatus: PermissionStatus = switch locationAuth {
        case .authorizedAlways: .granted
        case .denied, .restricted: .denied
        case .authorizedWhenInUse: .notDetermined
        default: .notDetermined
        }
        items.append(PermissionItem(
            permissionKey: "locationAlways",
            name: "Location (Always)",
            icon: "location.circle.fill",
            iconColor: .blue,
            status: alwaysStatus,
            description: "Geofencing and Time Journal location context",
            action: alwaysStatus == .notDetermined ? requestLocationAlways :
                    alwaysStatus == .denied ? openSettings : nil
        ))

        // 4. Face ID / Touch ID
        let laContext = LAContext()
        var laError: NSError?
        let canEvaluate = laContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &laError)
        let biometricEnabled = UserDefaults.standard.bool(forKey: "biometricLockEnabled")
        let biometricName = laContext.biometryType == .faceID ? "Face ID" : "Touch ID"
        let biometricIcon = laContext.biometryType == .faceID ? "faceid" : "touchid"

        let biometricStatus: PermissionStatus
        if !canEvaluate {
            if let laErr = laError, LAError.Code(rawValue: laErr.code) == .biometryNotAvailable {
                biometricStatus = .denied
            } else {
                biometricStatus = .notDetermined
            }
        } else {
            biometricStatus = biometricEnabled ? .granted : .notDetermined
        }
        items.append(PermissionItem(
            permissionKey: "biometrics",
            name: biometricName,
            icon: biometricIcon,
            iconColor: .green,
            status: biometricStatus,
            description: "Secure app access with biometrics",
            action: biometricStatus == .notDetermined ? requestBiometrics :
                    biometricStatus == .denied ? openSettings : nil
        ))

        // 5. App Tracking
        let trackingStatus: PermissionStatus = switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized: .granted
        case .denied, .restricted: .denied
        default: .notDetermined
        }
        items.append(PermissionItem(
            permissionKey: "tracking",
            name: "App Tracking",
            icon: "hand.raised.fill",
            iconColor: .purple,
            status: trackingStatus,
            description: "Controls ad tracking transparency",
            action: trackingStatus == .notDetermined ? requestTracking :
                    trackingStatus == .denied ? openSettings : nil
        ))

        // 6. Contacts
        let contactsStatus: PermissionStatus = switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: .granted
        case .denied, .restricted: .denied
        default: .notDetermined
        }
        items.append(PermissionItem(
            permissionKey: "contacts",
            name: "Contacts",
            icon: "person.crop.circle.fill",
            iconColor: .cyan,
            status: contactsStatus,
            description: "Import support network contacts",
            action: contactsStatus == .notDetermined ? requestContacts :
                    contactsStatus == .denied ? openSettings : nil
        ))

        // 7. Camera
        let cameraStatus: PermissionStatus = switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: .granted
        case .denied, .restricted: .denied
        default: .notDetermined
        }
        items.append(PermissionItem(
            permissionKey: "camera",
            name: "Camera",
            icon: "camera.fill",
            iconColor: .gray,
            status: cameraStatus,
            description: "Profile photo and journal attachments",
            action: cameraStatus == .notDetermined ? requestCamera :
                    cameraStatus == .denied ? openSettings : nil
        ))

        permissions = items
    }

    // MARK: - Permission Request Handlers

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                Task { await loadPermissions() }
            }
        }
    }

    private func requestLocationWhenInUse() {
        locationManager.onResult = {
            Task { await loadPermissions() }
        }
        locationManager.requestWhenInUse()
    }

    private func requestLocationAlways() {
        locationManager.onResult = {
            Task { await loadPermissions() }
        }
        locationManager.requestAlways()
    }

    private func requestBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
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
                    Task { await loadPermissions() }
                }
            } catch {
                await MainActor.run {
                    UserDefaults.standard.set(false, forKey: "biometricLockEnabled")
                    Task { await loadPermissions() }
                }
            }
        }
    }

    private func requestTracking() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            DispatchQueue.main.async {
                Task { await loadPermissions() }
            }
        }
    }

    private func requestContacts() {
        CNContactStore().requestAccess(for: .contacts) { _, _ in
            DispatchQueue.main.async {
                Task { await loadPermissions() }
            }
        }
    }

    private func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async {
                Task { await loadPermissions() }
            }
        }
    }

    // MARK: - Open Settings

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        AppPermissionsView()
    }
}
