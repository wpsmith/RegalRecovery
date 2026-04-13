import Foundation

// MARK: - BookLanguageManager

@Observable
final class BookLanguageManager {

    static let shared = BookLanguageManager()

    // MARK: - Supported Languages

    static let supportedLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Español"),
        ("fr", "Français"),
    ]

    // MARK: - User Selection

    /// User's explicitly selected language, or `nil` to follow device locale.
    var selectedLanguage: String? {
        didSet { UserDefaults.standard.set(selectedLanguage, forKey: Self.defaultsKey) }
    }

    // MARK: - Resolved Language

    /// The language code that should be used for book content.
    /// Priority: explicit selection → device locale (if supported) → English.
    var currentLanguage: String {
        if let selected = selectedLanguage { return selected }
        return Self.resolveDeviceLanguage()
    }

    // MARK: - Helpers

    /// Returns the display name for a language code, e.g. "es" → "Español".
    static func displayName(for code: String) -> String {
        supportedLanguages.first(where: { $0.code == code })?.name ?? code
    }

    // MARK: - Private

    private static let defaultsKey = "books.language"

    private init() {
        selectedLanguage = UserDefaults.standard.string(forKey: Self.defaultsKey)
    }

    /// The device locale resolved to a supported language code (for display in the picker).
    static var resolvedDeviceLanguage: String { resolveDeviceLanguage() }

    /// Resolves the device locale to a supported language code.
    /// Handles full locales like "es-US" by extracting the language prefix.
    private static func resolveDeviceLanguage() -> String {
        let localeCode = Locale.current.language.languageCode?.identifier ?? "en"
        if supportedLanguages.contains(where: { $0.code == localeCode }) {
            return localeCode
        }
        // Extract language prefix from regional locale (e.g. "es" from "es-US")
        let prefix = String(localeCode.prefix(while: { $0 != "-" && $0 != "_" }))
        if supportedLanguages.contains(where: { $0.code == prefix }) {
            return prefix
        }
        return "en"
    }
}
