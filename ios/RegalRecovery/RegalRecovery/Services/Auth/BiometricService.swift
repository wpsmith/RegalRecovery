import Foundation
import LocalAuthentication

@Observable
final class BiometricService {

    private(set) var biometricType: LABiometryType = .none

    init() {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        biometricType = context.biometryType
    }

    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        biometricType = context.biometryType
        return available
    }

    func authenticate(reason: String) async throws -> Bool {
        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error {
                throw BiometricError.evaluationFailed(error.localizedDescription)
            }
            return false
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch let error as LAError {
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                return false
            case .biometryNotAvailable:
                throw BiometricError.notAvailable
            case .biometryNotEnrolled:
                throw BiometricError.notEnrolled
            case .biometryLockout:
                throw BiometricError.lockout
            default:
                throw BiometricError.evaluationFailed(error.localizedDescription)
            }
        }
    }

    var biometricName: String {
        switch biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        @unknown default: return "Biometrics"
        }
    }
}

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case lockout
    case evaluationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .notEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .lockout:
            return "Biometric authentication is locked. Please use your device passcode."
        case .evaluationFailed(let message):
            return message
        }
    }
}
