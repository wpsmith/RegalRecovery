import Foundation
import SwiftUI

@Observable
class LanguageManager {
    static let shared = LanguageManager()

    private static let key = "com.regalrecovery.appLanguage"

    var currentLanguage: String {
        didSet {
            if currentLanguage == "system" {
                UserDefaults.standard.removeObject(forKey: Self.key)
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set(currentLanguage, forKey: Self.key)
                UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            }
        }
    }

    var displayName: String {
        if currentLanguage == "system" {
            let systemCode = Locale.current.language.languageCode?.identifier ?? "en"
            let name = Locale.current.localizedString(forLanguageCode: systemCode) ?? systemCode
            return "\(name.capitalized) (System)"
        }
        return Locale.current.localizedString(forLanguageCode: currentLanguage)?.capitalized
            ?? currentLanguage.uppercased()
    }

    var effectiveLocale: Locale {
        if currentLanguage == "system" {
            return .current
        }
        return Locale(identifier: currentLanguage)
    }

    static let supportedLanguages: [(code: String, name: String)] = {
        let codes = ["system", "en", "es", "fr"]
        return codes.map { code in
            if code == "system" {
                return (code: code, name: "System Default")
            }
            let name = Locale(identifier: code).localizedString(forLanguageCode: code) ?? code
            return (code: code, name: name.capitalized)
        }
    }()

    private init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: Self.key) ?? "system"
    }
}
