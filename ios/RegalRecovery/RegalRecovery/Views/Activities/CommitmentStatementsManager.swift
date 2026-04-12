import Foundation
import SwiftData

/// Manages persistence of user-customizable commitment statements for the Sobriety Commitment
/// and Morning Commitment views. Statements are stored in UserDefaults and seeded with defaults
/// on first access. Supports dynamic addiction-specific and schedule-aware statements.
final class CommitmentStatementsManager {

    static let shared = CommitmentStatementsManager()

    // MARK: - UserDefaults Keys

    private static let morningStatementsKey = "sobriety.commitment.morningStatements"
    private static let eveningStatementsKey = "sobriety.commitment.eveningStatements"
    private static let customizedKey = "sobriety.commitment.hasCustomized"

    // MARK: - Addiction-Specific Templates

    /// Maps addiction name keywords to sobriety commitment wording.
    private static let addictionStatementTemplates: [(keywords: [String], statement: String)] = [
        (["sex addiction", "sa"], "I commit to sexual sobriety today \u{2014} no sex with self, no sex outside of marriage."),
        (["pornography", "porn"], "I commit to pornography sobriety today \u{2014} no viewing, seeking, or consuming pornographic material."),
        (["alcohol"], "I commit to alcohol sobriety today \u{2014} no drinking in any form."),
        (["substance", "drugs"], "I commit to substance sobriety today \u{2014} no use of mood-altering chemicals."),
        (["gambling"], "I commit to gambling sobriety today \u{2014} no betting, wagering, or gambling activity."),
    ]

    // MARK: - Static Default Statements (non-addiction-specific)

    static let communityStatement = "I will reach out to my sponsor or accountability partner if I am struggling."
    static let meetingsStatement = "I will attend my scheduled recovery meeting."
    static let prayerStatement = "I will spend time in prayer and scripture today."
    static let honestyStatement = "I will be honest with myself and others today."
    static let surrenderStatement = "I surrender this day to God and trust His plan for my recovery."

    static let defaultEveningStatements: [String] = [
        "Did I maintain my sobriety commitment today?",
        "Was I honest in all my interactions today?",
        "Did I reach out for support when I needed it?",
        "What am I grateful for today?",
    ]

    /// The old static defaults (used as fallback and for "Reset to Defaults").
    static let defaultMorningStatements: [String] = [
        "I commit to sexual sobriety today \u{2014} no sex with self, no sex outside of marriage.",
        communityStatement,
        meetingsStatement,
        prayerStatement,
        honestyStatement,
        surrenderStatement,
    ]

    // MARK: - Dynamic Defaults

    /// Builds default morning statements tailored to the user's addictions and today's schedule.
    /// - Parameters:
    ///   - addictions: The user's configured addictions.
    ///   - hasMeetingToday: Whether a meeting activity is scheduled for today.
    /// - Returns: An array of commitment statement strings.
    static func dynamicMorningDefaults(addictions: [String], hasMeetingToday: Bool) -> [String] {
        var statements: [String] = []

        // Addiction-specific statements
        for addiction in addictions {
            let lower = addiction.lowercased()
            for template in addictionStatementTemplates {
                if template.keywords.contains(where: { lower.contains($0) }) {
                    if !statements.contains(template.statement) {
                        statements.append(template.statement)
                    }
                    break
                }
            }
        }

        // If no addiction matched a template, add a generic one
        if statements.isEmpty {
            statements.append("I commit to sobriety today \u{2014} I will honor my recovery boundaries.")
        }

        // Community
        statements.append(communityStatement)

        // Meetings (only if scheduled today)
        if hasMeetingToday {
            statements.append(meetingsStatement)
        }

        // Prayer, Honesty, Surrender
        statements.append(prayerStatement)
        statements.append(honestyStatement)
        statements.append(surrenderStatement)

        return statements
    }

    // MARK: - Public API

    /// Whether the user has ever customized their statements.
    var hasCustomized: Bool {
        UserDefaults.standard.bool(forKey: Self.customizedKey)
    }

    var morningStatements: [String] {
        get {
            if let saved = UserDefaults.standard.stringArray(forKey: Self.morningStatementsKey) {
                return saved
            }
            return Self.defaultMorningStatements
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.morningStatementsKey)
            UserDefaults.standard.set(true, forKey: Self.customizedKey)
        }
    }

    /// Returns morning statements, seeding with dynamic defaults if the user hasn't customized yet.
    func morningStatements(addictions: [String], hasMeetingToday: Bool) -> [String] {
        if hasCustomized, let saved = UserDefaults.standard.stringArray(forKey: Self.morningStatementsKey) {
            return saved
        }
        let dynamic = Self.dynamicMorningDefaults(addictions: addictions, hasMeetingToday: hasMeetingToday)
        return dynamic
    }

    var eveningStatements: [String] {
        get {
            if let saved = UserDefaults.standard.stringArray(forKey: Self.eveningStatementsKey) {
                return saved
            }
            return Self.defaultEveningStatements
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.eveningStatementsKey)
        }
    }

    func resetMorningToDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.morningStatementsKey)
        UserDefaults.standard.set(false, forKey: Self.customizedKey)
    }

    func resetEveningToDefaults() {
        eveningStatements = Self.defaultEveningStatements
    }

    private init() {}
}
