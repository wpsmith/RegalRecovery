import Foundation
import Observation

@Observable
class FeatureFlagViewModel {
    var features: [FeatureFlag] = []
    var activities: [FeatureFlag] = []
    var assessments: [FeatureFlag] = []

    private let userDefaultsPrefix = "ff."

    func load() {
        features = Self.defaultFeatures.map { loadFlag($0) }
        activities = Self.defaultActivities.map { loadFlag($0) }
        assessments = Self.defaultAssessments.map { loadFlag($0) }
    }

    func toggle(flag: FeatureFlag) {
        let newValue = !flag.enabled

        if let i = features.firstIndex(where: { $0.key == flag.key }) {
            features[i].enabled = newValue
            persistFlag(features[i])
        } else if let i = activities.firstIndex(where: { $0.key == flag.key }) {
            activities[i].enabled = newValue
            persistFlag(activities[i])
        } else if let i = assessments.firstIndex(where: { $0.key == flag.key }) {
            assessments[i].enabled = newValue
            persistFlag(assessments[i])
        }
    }

    func enableAll() {
        setAll(true)
    }

    func disableAll() {
        setAll(false)
    }

    func resetDefaults() {
        // Clear persisted overrides
        let allFlags = features + activities + assessments
        for flag in allFlags {
            UserDefaults.standard.removeObject(forKey: userDefaultsPrefix + flag.key)
        }

        // Reload from defaults
        features = Self.defaultFeatures
        activities = Self.defaultActivities
        assessments = Self.defaultAssessments
    }

    func syncFromServer() async throws {
        // In production this would fetch flag overrides from the API.
        // For now, reload from local defaults as a no-op placeholder.
        load()
    }

    // MARK: - Private

    private func setAll(_ value: Bool) {
        for i in features.indices {
            features[i].enabled = value
            persistFlag(features[i])
        }
        for i in activities.indices {
            activities[i].enabled = value
            persistFlag(activities[i])
        }
        for i in assessments.indices {
            assessments[i].enabled = value
            persistFlag(assessments[i])
        }
    }

    private func persistFlag(_ flag: FeatureFlag) {
        UserDefaults.standard.set(flag.enabled, forKey: userDefaultsPrefix + flag.key)
    }

    private func loadFlag(_ defaultFlag: FeatureFlag) -> FeatureFlag {
        let key = userDefaultsPrefix + defaultFlag.key
        if UserDefaults.standard.object(forKey: key) != nil {
            var flag = defaultFlag
            flag.enabled = UserDefaults.standard.bool(forKey: key)
            return flag
        }
        return defaultFlag
    }

    // MARK: - Default Flags

    static let defaultFeatures: [FeatureFlag] = [
        FeatureFlag(key: "feature.onboarding", label: "Onboarding", enabled: true),
        FeatureFlag(key: "feature.profile-management", label: "Profile Management", enabled: true),
        FeatureFlag(key: "feature.tracking", label: "Tracking System", enabled: true),
        FeatureFlag(key: "feature.content-resources", label: "Content / Resources", enabled: true),
        FeatureFlag(key: "feature.commitments", label: "Commitments", enabled: true),
        FeatureFlag(key: "feature.dark-mode", label: "Light / Dark Mode", enabled: true),
        FeatureFlag(key: "feature.offline-first", label: "Offline-First", enabled: true),
        FeatureFlag(key: "feature.dsr", label: "Data Subject Rights", enabled: true),
        FeatureFlag(key: "feature.analytics-dashboard", label: "Analytics Dashboard", enabled: true),
        FeatureFlag(key: "feature.meeting-finder", label: "Meeting Finder", enabled: true),
        FeatureFlag(key: "feature.quick-actions", label: "Quick Actions", enabled: true),
        FeatureFlag(key: "feature.backup", label: "Data Backup", enabled: false),
        FeatureFlag(key: "feature.messaging-integrations", label: "Messaging Integrations", enabled: false),
        FeatureFlag(key: "feature.community", label: "Community", enabled: false),
        FeatureFlag(key: "feature.therapist-portal", label: "Therapist Portal", enabled: false),
        FeatureFlag(key: "feature.health-score", label: "Recovery Health Score", enabled: false),
        FeatureFlag(key: "feature.achievements", label: "Achievements", enabled: false),
        FeatureFlag(key: "feature.couples-mode", label: "Couples Recovery Mode", enabled: false),
        FeatureFlag(key: "feature.geofencing", label: "Geofencing", enabled: false),
        FeatureFlag(key: "feature.screen-time", label: "Screen Time", enabled: false),
        FeatureFlag(key: "feature.sleep-tracking", label: "Sleep Tracking", enabled: false),
        FeatureFlag(key: "feature.superbill", label: "Superbill / LMN", enabled: false),
        FeatureFlag(key: "feature.recovery-agent", label: "Recovery Agent (AI)", enabled: false),
        FeatureFlag(key: "feature.premium-analytics", label: "Premium Analytics", enabled: false),
        FeatureFlag(key: "feature.panic-button-biometric", label: "Panic Button (Biometric)", enabled: false),
        FeatureFlag(key: "feature.recovery-stories", label: "Recovery Stories", enabled: false),
        FeatureFlag(key: "feature.branding", label: "Branding (B2B)", enabled: false),
        FeatureFlag(key: "feature.tenancy", label: "Tenancy (B2B)", enabled: false),
        FeatureFlag(key: "feature.spotify", label: "Spotify Integration", enabled: false),
    ]

    static let defaultActivities: [FeatureFlag] = [
        FeatureFlag(key: "activity.sobriety-commitment", label: "Sobriety Commitment", enabled: true),
        FeatureFlag(key: "activity.affirmations", label: "Affirmations", enabled: true),
        FeatureFlag(key: "activity.urge-logging", label: "Urge Logging", enabled: true),
        FeatureFlag(key: "activity.journaling", label: "Journaling", enabled: true),
        FeatureFlag(key: "activity.faster-scale", label: "FASTER Scale", enabled: true),
        FeatureFlag(key: "activity.check-ins", label: "Recovery Check-ins", enabled: true),
        FeatureFlag(key: "activity.emotional-journaling", label: "Emotional Journaling", enabled: true),
        FeatureFlag(key: "activity.time-journal", label: "Time Journal", enabled: true),
        FeatureFlag(key: "activity.spouse-checkin-prep", label: "Spouse Check-in Prep", enabled: true),
        FeatureFlag(key: "activity.person-check-ins", label: "Person Check-ins", enabled: false),
        FeatureFlag(key: "activity.meetings", label: "Meetings Attended", enabled: true),
        FeatureFlag(key: "activity.post-mortem", label: "Post-Mortem Analysis", enabled: true),
        FeatureFlag(key: "activity.step-work", label: "12-Step Work", enabled: true),
        FeatureFlag(key: "activity.goals", label: "Weekly Goals", enabled: true),
        FeatureFlag(key: "activity.devotionals", label: "Devotionals", enabled: true),
        FeatureFlag(key: "activity.exercise", label: "Exercise", enabled: true),
        FeatureFlag(key: "activity.mood", label: "Mood Ratings", enabled: true),
        FeatureFlag(key: "activity.gratitude", label: "Gratitude List", enabled: true),
        FeatureFlag(key: "activity.phone-calls", label: "Phone Calls", enabled: true),
        FeatureFlag(key: "activity.prayer", label: "Prayer", enabled: true),
        FeatureFlag(key: "activity.integrity-inventory", label: "Integrity Inventory", enabled: false),
        FeatureFlag(key: "activity.pci", label: "PCI", enabled: false),
    ]

    static let defaultAssessments: [FeatureFlag] = [
        FeatureFlag(key: "assessment.sast-r", label: "SAST-R", enabled: false),
        FeatureFlag(key: "assessment.family-impact", label: "Family Impact", enabled: false),
        FeatureFlag(key: "assessment.denial", label: "Denial", enabled: false),
        FeatureFlag(key: "assessment.addiction-severity", label: "Addiction Severity", enabled: false),
        FeatureFlag(key: "assessment.relationship-health", label: "Relationship Health", enabled: false),
    ]
}
