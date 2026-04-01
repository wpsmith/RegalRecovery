import SwiftUI

extension Color {
    // Dynamic theme colors — change with selected theme
    static var rrPrimary: Color { ThemeManager.shared.current.primary }
    static var rrSecondary: Color { ThemeManager.shared.current.secondary }
    static var rrDestructive: Color { ThemeManager.shared.current.destructive }
    static var rrSuccess: Color { ThemeManager.shared.current.success }

    // Neutral colors — same across all themes, from Asset Catalog
    static let rrBackground = Color("rrBackground", bundle: nil)
    static let rrSurface = Color("rrSurface", bundle: nil)
    static let rrText = Color("rrText", bundle: nil)
    static let rrTextSecondary = Color("rrTextSecondary", bundle: nil)
}

extension ShapeStyle where Self == Color {
    static var rrPrimary: Color { .rrPrimary }
    static var rrSecondary: Color { .rrSecondary }
    static var rrBackground: Color { .rrBackground }
    static var rrSurface: Color { .rrSurface }
    static var rrDestructive: Color { .rrDestructive }
    static var rrSuccess: Color { .rrSuccess }
    static var rrText: Color { .rrText }
    static var rrTextSecondary: Color { .rrTextSecondary }
}
