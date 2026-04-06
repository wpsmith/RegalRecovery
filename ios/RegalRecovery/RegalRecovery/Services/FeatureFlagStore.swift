import Foundation
import SwiftUI

@Observable
final class FeatureFlagStore {
    static let shared = FeatureFlagStore()

    /// Incremented on every flag change to trigger SwiftUI updates
    private(set) var version: Int = 0

    private init() {
        seedDefaultsIfNeeded()
    }

    func isEnabled(_ key: String) -> Bool {
        // Touch version to create observation dependency
        _ = version
        // Fail closed: unknown flags default to disabled
        return UserDefaults.standard.object(forKey: "ff.\(key)") as? Bool ?? false
    }

    func setFlag(_ key: String, enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "ff.\(key)")
        version += 1
    }

    /// Call after bulk flag operations (Enable All, Disable All, Reset)
    func flagsDidChange() {
        version += 1
    }

    // MARK: - Default Seeding

    /// Seeds UserDefaults with flag defaults on first launch. Only writes keys
    /// that have no existing value so user/server overrides are preserved.
    private func seedDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        for (key, value) in Self.flagDefaults {
            let udKey = "ff.\(key)"
            if defaults.object(forKey: udKey) == nil {
                defaults.set(value, forKey: udKey)
            }
        }
    }

    /// Canonical default values for all feature flags.
    /// Must stay in sync with FeatureFlagService.loadDefaults().
    static let flagDefaults: [String: Bool] = [
        // Features - P0
        "feature.onboarding": true,
        "feature.profile-management": true,
        "feature.content-resources": true,
        "feature.commitments": true,
        "feature.themes": true,
        "feature.offline-first": true,
        "feature.dsr": true,

        // Features - P1
        "feature.analytics-dashboard": true,
        "feature.meeting-finder": true,
        "feature.quick-actions": true,
        "feature.backup": false,
        "feature.messaging-integrations": false,

        // Features - P2
        "feature.community": false,
        "feature.therapist-portal": false,
        "feature.health-score": false,
        "feature.achievements": false,
        "feature.couples-mode": false,
        "feature.geofencing": false,
        "feature.screen-time": false,
        "feature.sleep-tracking": false,
        "feature.superbill": false,

        // Features - P3
        "feature.recovery-agent": false,
        "feature.premium-analytics": false,
        "feature.panic-button-biometric": false,
        "feature.recovery-stories": false,
        "feature.branding": false,
        "feature.tenancy": false,
        "feature.spotify": false,

        // Activities - P0
        "activity.sobriety-commitment": true,
        "activity.affirmations": true,
        "activity.urge-logging": true,
        "activity.journaling": true,
        "activity.faster-scale": true,
        "activity.check-ins": true,

        // Activities - P1
        "activity.emotional-journaling": true,
        "activity.time-journal": true,
        "activity.spouse-checkin-prep": true,
        "activity.person-check-ins": false,
        "activity.meetings": true,
        "activity.post-mortem": true,
        "activity.step-work": true,
        "activity.goals": true,
        "activity.devotionals": true,
        "activity.exercise": true,
        "activity.mood": true,
        "activity.gratitude": true,
        "activity.phone-calls": true,
        "activity.prayer": true,
        "activity.integrity-inventory": false,
        "activity.pci": false,
        "activity.memory-verse": false,
        "activity.nutrition": false,
        "activity.acting-in-behaviors": false,
        "activity.voice-journal": false,
        "activity.book-reading": false,

        // App Architecture
        "feature.today-view": false,
        "feature.work-tab": true,
        "feature.urge-surfing-timer": true,

        // Recovery Work & Tools
        "feature.3circles": false,
        "feature.vision": false,
        "feature.partners.redemptiveliving.backbone": false,
        "feature.relapse-prevention-plan": false,
        "feature.post-mortem": true,

        // Assessments
        "assessment.sast-r": false,
        "assessment.family-impact": false,
        "assessment.denial": false,
        "assessment.addiction-severity": false,
        "assessment.relationship-health": false,
    ]
}
