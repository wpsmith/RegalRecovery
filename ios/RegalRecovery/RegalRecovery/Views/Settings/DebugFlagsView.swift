import SwiftUI

struct FeatureFlag: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    var enabled: Bool
}

struct DebugFlagsView: View {
    @State private var features: [FeatureFlag] = [
        // P0 Features
        FeatureFlag(key: "feature.onboarding", label: "Onboarding", enabled: true),
        FeatureFlag(key: "feature.profile-management", label: "Profile Management", enabled: true),
        FeatureFlag(key: "feature.tracking", label: "Tracking System", enabled: true),
        FeatureFlag(key: "feature.content-resources", label: "Content / Resources", enabled: true),
        FeatureFlag(key: "feature.commitments", label: "Commitments", enabled: true),
        FeatureFlag(key: "feature.dark-mode", label: "Light / Dark Mode", enabled: true),
        FeatureFlag(key: "feature.offline-first", label: "Offline-First", enabled: true),
        FeatureFlag(key: "feature.dsr", label: "Data Subject Rights", enabled: true),
        // P1 Features
        FeatureFlag(key: "feature.analytics-dashboard", label: "Analytics Dashboard", enabled: true),
        FeatureFlag(key: "feature.meeting-finder", label: "Meeting Finder", enabled: true),
        FeatureFlag(key: "feature.quick-actions", label: "Quick Actions", enabled: true),
        FeatureFlag(key: "feature.backup", label: "Data Backup", enabled: false),
        FeatureFlag(key: "feature.messaging-integrations", label: "Messaging Integrations", enabled: false),
        // P2 Features
        FeatureFlag(key: "feature.community", label: "Community", enabled: false),
        FeatureFlag(key: "feature.therapist-portal", label: "Therapist Portal", enabled: false),
        FeatureFlag(key: "feature.health-score", label: "Recovery Health Score", enabled: false),
        FeatureFlag(key: "feature.achievements", label: "Achievements", enabled: false),
        FeatureFlag(key: "feature.couples-mode", label: "Couples Recovery Mode", enabled: false),
        FeatureFlag(key: "feature.geofencing", label: "Geofencing", enabled: false),
        FeatureFlag(key: "feature.screen-time", label: "Screen Time", enabled: false),
        FeatureFlag(key: "feature.sleep-tracking", label: "Sleep Tracking", enabled: false),
        FeatureFlag(key: "feature.superbill", label: "Superbill / LMN", enabled: false),
        // P3 Features
        FeatureFlag(key: "feature.recovery-agent", label: "Recovery Agent (AI)", enabled: false),
        FeatureFlag(key: "feature.premium-analytics", label: "Premium Analytics", enabled: false),
        FeatureFlag(key: "feature.panic-button-biometric", label: "Panic Button (Biometric)", enabled: false),
        FeatureFlag(key: "feature.recovery-stories", label: "Recovery Stories", enabled: false),
        FeatureFlag(key: "feature.branding", label: "Branding (B2B)", enabled: false),
        FeatureFlag(key: "feature.tenancy", label: "Tenancy (B2B)", enabled: false),
        FeatureFlag(key: "feature.spotify", label: "Spotify Integration", enabled: false),
    ]

    @State private var activities: [FeatureFlag] = [
        // P0 Activities
        FeatureFlag(key: "activity.sobriety-commitment", label: "Sobriety Commitment", enabled: true),
        FeatureFlag(key: "activity.affirmations", label: "Affirmations", enabled: true),
        FeatureFlag(key: "activity.urge-logging", label: "Urge Logging", enabled: true),
        FeatureFlag(key: "activity.journaling", label: "Journaling", enabled: true),
        FeatureFlag(key: "activity.faster-scale", label: "FASTER Scale", enabled: true),
        FeatureFlag(key: "activity.check-ins", label: "Recovery Check-ins", enabled: true),
        // P1 Activities
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

    @State private var assessments: [FeatureFlag] = [
        FeatureFlag(key: "assessment.sast-r", label: "SAST-R", enabled: false),
        FeatureFlag(key: "assessment.family-impact", label: "Family Impact", enabled: false),
        FeatureFlag(key: "assessment.denial", label: "Denial", enabled: false),
        FeatureFlag(key: "assessment.addiction-severity", label: "Addiction Severity", enabled: false),
        FeatureFlag(key: "assessment.relationship-health", label: "Relationship Health", enabled: false),
    ]

    var body: some View {
        List {
            Section {
                flagSection(flags: $features)
            } header: {
                HStack {
                    Text("Features")
                    Spacer()
                    Text("\(features.filter(\.enabled).count)/\(features.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }

            Section {
                flagSection(flags: $activities)
            } header: {
                HStack {
                    Text("Activities")
                    Spacer()
                    Text("\(activities.filter(\.enabled).count)/\(activities.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }

            Section {
                flagSection(flags: $assessments)
            } header: {
                HStack {
                    Text("Assessments")
                    Spacer()
                    Text("\(assessments.filter(\.enabled).count)/\(assessments.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }

            Section {
                Button("Enable All") {
                    setAll(true)
                }
                Button("Disable All", role: .destructive) {
                    setAll(false)
                }
                Button("Reset to Defaults") {
                    resetDefaults()
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func flagSection(flags: Binding<[FeatureFlag]>) -> some View {
        ForEach(flags) { $flag in
            HStack {
                Toggle(isOn: $flag.enabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(flag.label)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                        Text(flag.key)
                            .font(RRFont.caption2)
                            .foregroundStyle(Color.rrTextSecondary)
                            .monospaced()
                    }
                }
                .tint(Color.rrPrimary)
            }
        }
    }

    private func setAll(_ value: Bool) {
        for i in features.indices { features[i].enabled = value }
        for i in activities.indices { activities[i].enabled = value }
        for i in assessments.indices { assessments[i].enabled = value }
    }

    private func resetDefaults() {
        // Re-initialize to match the original values
        for i in features.indices {
            features[i].enabled = i < 11 // P0+P1 enabled
        }
        for i in activities.indices {
            activities[i].enabled = i < 19 // most enabled except last 2
        }
        for i in assessments.indices {
            assessments[i].enabled = false
        }
    }
}

#Preview {
    NavigationStack {
        DebugFlagsView()
    }
}
