import SwiftUI
import UIKit

struct ColorTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let primary: Color
    let secondary: Color
    let destructive: Color
    let success: Color
    let previewColors: [Color] // for the picker swatch

    static let teal = ColorTheme(
        id: "teal",
        name: "Teal",
        primary: Color(light: .init(red: 0.106, green: 0.420, blue: 0.427), dark: .init(red: 0.306, green: 0.804, blue: 0.769)),
        secondary: Color(light: .init(red: 0.910, green: 0.659, blue: 0.220), dark: .init(red: 0.941, green: 0.753, blue: 0.376)),
        destructive: Color(red: 0.761, green: 0.357, blue: 0.337),
        success: Color(red: 0.420, green: 0.624, blue: 0.443),
        previewColors: [Color(red: 0.106, green: 0.420, blue: 0.427), Color(red: 0.910, green: 0.659, blue: 0.220)]
    )

    static let ocean = ColorTheme(
        id: "ocean",
        name: "Ocean",
        primary: Color(light: .init(red: 0.20, green: 0.35, blue: 0.60), dark: .init(red: 0.40, green: 0.62, blue: 0.90)),
        secondary: Color(light: .init(red: 0.85, green: 0.55, blue: 0.25), dark: .init(red: 0.95, green: 0.70, blue: 0.40)),
        destructive: Color(red: 0.80, green: 0.30, blue: 0.30),
        success: Color(red: 0.30, green: 0.60, blue: 0.50),
        previewColors: [Color(red: 0.20, green: 0.35, blue: 0.60), Color(red: 0.85, green: 0.55, blue: 0.25)]
    )

    static let forest = ColorTheme(
        id: "forest",
        name: "Forest",
        primary: Color(light: .init(red: 0.25, green: 0.45, blue: 0.30), dark: .init(red: 0.40, green: 0.72, blue: 0.48)),
        secondary: Color(light: .init(red: 0.75, green: 0.60, blue: 0.35), dark: .init(red: 0.88, green: 0.75, blue: 0.50)),
        destructive: Color(red: 0.72, green: 0.32, blue: 0.32),
        success: Color(red: 0.35, green: 0.58, blue: 0.38),
        previewColors: [Color(red: 0.25, green: 0.45, blue: 0.30), Color(red: 0.75, green: 0.60, blue: 0.35)]
    )

    static let plum = ColorTheme(
        id: "plum",
        name: "Plum",
        primary: Color(light: .init(red: 0.42, green: 0.28, blue: 0.55), dark: .init(red: 0.65, green: 0.50, blue: 0.82)),
        secondary: Color(light: .init(red: 0.85, green: 0.55, blue: 0.50), dark: .init(red: 0.95, green: 0.68, blue: 0.62)),
        destructive: Color(red: 0.75, green: 0.30, blue: 0.35),
        success: Color(red: 0.40, green: 0.60, blue: 0.45),
        previewColors: [Color(red: 0.42, green: 0.28, blue: 0.55), Color(red: 0.85, green: 0.55, blue: 0.50)]
    )

    static let allThemes: [ColorTheme] = [.teal, .ocean, .forest, .plum]

    static func theme(for id: String) -> ColorTheme {
        allThemes.first { $0.id == id } ?? .teal
    }
}

// MARK: - Color initializer for light/dark

private extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Observable Theme Manager

@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    var current: ColorTheme {
        didSet {
            UserDefaults.standard.set(current.id, forKey: "selectedTheme")
        }
    }

    private init() {
        let savedID = UserDefaults.standard.string(forKey: "selectedTheme") ?? "teal"
        self.current = ColorTheme.theme(for: savedID)
    }
}
