import Foundation

enum ActivityError: LocalizedError {
    case validationFailed(String)
    case saveFailed(String)
    case notImplemented

    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .notImplemented:
            return "Storage not yet implemented."
        }
    }
}
