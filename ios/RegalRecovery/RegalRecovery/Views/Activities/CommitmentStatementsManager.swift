import Foundation

/// Manages persistence of user-customizable commitment statements for the Sobriety Commitment
/// and Morning Commitment views. Statements are stored in UserDefaults and seeded with defaults
/// on first access.
final class CommitmentStatementsManager {

    static let shared = CommitmentStatementsManager()

    // MARK: - UserDefaults Keys

    private static let morningStatementsKey = "sobriety.commitment.morningStatements"
    private static let eveningStatementsKey = "sobriety.commitment.eveningStatements"

    // MARK: - Default Statements

    static let defaultMorningStatements: [String] = [
        "I commit to sexual sobriety today \u{2014} no sex with self, no sex outside of marriage.",
        "I will reach out to my sponsor or accountability partner if I am struggling.",
        "I will attend my scheduled recovery meeting.",
        "I will spend time in prayer and scripture today.",
        "I will be honest with myself and others today.",
        "I surrender this day to God and trust His plan for my recovery.",
    ]

    static let defaultEveningStatements: [String] = [
        "Did I maintain my sobriety commitment today?",
        "Was I honest in all my interactions today?",
        "Did I reach out for support when I needed it?",
        "What am I grateful for today?",
    ]

    // MARK: - Public API

    var morningStatements: [String] {
        get {
            if let saved = UserDefaults.standard.stringArray(forKey: Self.morningStatementsKey) {
                return saved
            }
            // Seed defaults on first access
            UserDefaults.standard.set(Self.defaultMorningStatements, forKey: Self.morningStatementsKey)
            return Self.defaultMorningStatements
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.morningStatementsKey)
        }
    }

    var eveningStatements: [String] {
        get {
            if let saved = UserDefaults.standard.stringArray(forKey: Self.eveningStatementsKey) {
                return saved
            }
            // Seed defaults on first access
            UserDefaults.standard.set(Self.defaultEveningStatements, forKey: Self.eveningStatementsKey)
            return Self.defaultEveningStatements
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.eveningStatementsKey)
        }
    }

    func resetMorningToDefaults() {
        morningStatements = Self.defaultMorningStatements
    }

    func resetEveningToDefaults() {
        eveningStatements = Self.defaultEveningStatements
    }

    private init() {}
}
