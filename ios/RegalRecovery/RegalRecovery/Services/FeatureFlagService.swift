import Foundation

@Observable
final class FeatureFlagService {

    private var flags: [String: Bool] = [:]

    init() {
        loadDefaults()
        loadFromUserDefaults()
    }

    func isEnabled(_ key: String) -> Bool {
        flags[key] ?? false
    }

    func setFlag(_ key: String, enabled: Bool) {
        flags[key] = enabled
        saveToUserDefaults()
    }

    func allFlags() -> [String: Bool] {
        flags
    }

    /// Restore saved overrides from UserDefaults.
    func loadFromUserDefaults() {
        guard let saved = UserDefaults.standard.dictionary(forKey: "rr_feature_flags") as? [String: Bool] else {
            return
        }
        for (key, value) in saved {
            flags[key] = value
        }
    }

    /// Fetch latest flags from the server. Falls back to local values on failure.
    func syncFromServer(baseURL: URL, accessToken: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("/config/feature-flags"))
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return
        }

        struct FlagResponse: Codable {
            let data: [String: Bool]
        }

        if let decoded = try? JSONDecoder().decode(FlagResponse.self, from: data) {
            for (key, value) in decoded.data {
                flags[key] = value
            }
            saveToUserDefaults()
        }
    }

    // MARK: - Private

    private func saveToUserDefaults() {
        UserDefaults.standard.set(flags, forKey: "rr_feature_flags")
    }

    private func loadDefaults() {
        // Features - P0
        flags["feature.onboarding"] = true
        flags["feature.profile-management"] = true
        flags["feature.content-resources"] = true
        flags["feature.commitments"] = true
        flags["feature.themes"] = true
        flags["feature.offline-first"] = true
        flags["feature.dsr"] = true

        // Features - P1
        flags["feature.analytics-dashboard"] = true
        flags["feature.meeting-finder"] = true
        flags["feature.quick-actions"] = true
        flags["feature.backup"] = false
        flags["feature.messaging-integrations"] = false

        // Features - P2
        flags["feature.community"] = false
        flags["feature.therapist-portal"] = false
        flags["feature.health-score"] = false
        flags["feature.achievements"] = false
        flags["feature.couples-mode"] = false
        flags["feature.geofencing"] = false
        flags["feature.screen-time"] = false
        flags["feature.sleep-tracking"] = false
        flags["feature.superbill"] = false

        // Features - P3
        flags["feature.recovery-agent"] = false
        flags["feature.premium-analytics"] = false
        flags["feature.panic-button-biometric"] = false
        flags["feature.recovery-stories"] = false
        flags["feature.branding"] = false
        flags["feature.tenancy"] = false
        flags["feature.spotify"] = false

        // Activities - P0
        flags["activity.sobriety-commitment"] = true
        flags["activity.affirmations"] = true
        flags["activity.urge-logging"] = true
        flags["activity.journaling"] = true
        flags["activity.faster-scale"] = true
        flags["activity.check-ins"] = true

        // Activities - P1
        flags["activity.emotional-journaling"] = true
        flags["activity.time-journal"] = true
        flags["activity.spouse-checkin-prep"] = true
        flags["activity.person-check-ins"] = false
        flags["activity.meetings"] = true
        flags["activity.post-mortem"] = true
        flags["activity.step-work"] = true
        flags["activity.goals"] = true
        flags["activity.devotionals"] = true
        flags["activity.exercise"] = true
        flags["activity.mood"] = true
        flags["activity.gratitude"] = true
        flags["activity.phone-calls"] = true
        flags["activity.prayer"] = true
        flags["activity.integrity-inventory"] = false
        flags["activity.pci"] = false

        // App Architecture
        flags["feature.today-view"] = false
        flags["feature.work-tab"] = true
        flags["feature.urge-surfing-timer"] = true
        flags["feature.activities"] = true

        // Recovery Work & Tools
        flags["feature.3circles"] = false
        flags["feature.vision"] = false
        flags["feature.partners.redemptiveliving.backbone"] = false
        flags["feature.relapse-prevention-plan"] = false
        flags["feature.post-mortem"] = true

        // Assessments
        flags["assessment.sast-r"] = false
        flags["assessment.family-impact"] = false
        flags["assessment.denial"] = false
        flags["assessment.addiction-severity"] = false
        flags["assessment.relationship-health"] = false
    }
}
