import SwiftUI

struct FeatureFlag: Identifiable {
    let id = UUID()
    let key: String
    let label: String
    var enabled: Bool
}

struct DebugFlagsView: View {
    @State private var activeFeatures: [FeatureFlag] = [
        FeatureFlag(key: "feature.onboarding", label: "Onboarding", enabled: true),
        FeatureFlag(key: "feature.themes", label: "Themes", enabled: true),
        FeatureFlag(key: "feature.quick-actions", label: "Quick Actions", enabled: true),
        FeatureFlag(key: "feature.3circles", label: "3 Circles", enabled: false),
        FeatureFlag(key: "feature.vision", label: "Vision Statement", enabled: false),
    ]

    @State private var activities: [FeatureFlag] = [
        // P0 Activities
        FeatureFlag(key: "activity.sobriety-commitment", label: "Sobriety Commitment", enabled: true),
        FeatureFlag(key: "activity.affirmations", label: "Affirmations", enabled: true),
        FeatureFlag(key: "activity.urge-logging", label: "Urge Logging", enabled: true),
        FeatureFlag(key: "activity.journaling", label: "Journaling", enabled: true),
        FeatureFlag(key: "activity.faster-scale", label: "FASTER Scale", enabled: true),
        // P1 Activities
        FeatureFlag(key: "activity.time-journal", label: "Time Journal", enabled: true),
        FeatureFlag(key: "activity.fanos", label: "FANOS Check-in", enabled: false),
        FeatureFlag(key: "activity.fitnap", label: "FITNAP Check-in", enabled: false),
        FeatureFlag(key: "activity.spouse-check-ins", label: "Spouse Check-ins", enabled: false),
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

    @State private var futureFeatures: [FeatureFlag] = [
        // Recovery Work & Tools
        FeatureFlag(key: "feature.partners.redemptiveliving.backbone", label: "Backbone (Redemptive Living)", enabled: false),
        FeatureFlag(key: "feature.relapse-prevention-plan", label: "Relapse Prevention Plan", enabled: false),
        FeatureFlag(key: "feature.post-mortem", label: "Post-Mortem", enabled: true),
        // General
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

    @State private var expandedSections: Set<String> = ["Features", "Activities", "Assessments", "Future"]
    @State private var searchText = ""

    init() {
        _activeFeatures = State(initialValue: Self.loadFlags(Self.defaultActiveFeatures))
        _activities = State(initialValue: Self.loadFlags(Self.defaultActivities))
        _assessments = State(initialValue: Self.loadFlags(Self.defaultAssessments))
        _futureFeatures = State(initialValue: Self.loadFlags(Self.defaultFutureFeatures))
    }

    var body: some View {
        List {
            collapsibleSection(
                title: "Features",
                count: activeFeatures.filter(\.enabled).count,
                total: activeFeatures.count,
                flags: $activeFeatures
            )

            collapsibleSection(
                title: "Activities",
                count: activities.filter(\.enabled).count,
                total: activities.count,
                flags: $activities
            )

            collapsibleSection(
                title: "Assessments",
                count: assessments.filter(\.enabled).count,
                total: assessments.count,
                flags: $assessments
            )

            collapsibleSection(
                title: "Future",
                count: futureFeatures.filter(\.enabled).count,
                total: futureFeatures.count,
                flags: $futureFeatures
            )

            Section {
                Button("Enable All") { setAll(true) }
                Button("Disable All", role: .destructive) { setAll(false) }
                Button("Reset to Defaults") { resetDefaults() }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search flags")
    }

    private func filteredIndices(for flags: [FeatureFlag]) -> [Int] {
        guard !searchText.isEmpty else { return Array(flags.indices) }
        let query = searchText.lowercased()
        return flags.indices.filter { i in
            flags[i].label.lowercased().contains(query) || flags[i].key.lowercased().contains(query)
        }
    }

    // MARK: - Collapsible Section

    @ViewBuilder
    private func collapsibleSection(
        title: String,
        count: Int,
        total: Int,
        flags: Binding<[FeatureFlag]>
    ) -> some View {
        let hasResults = searchText.isEmpty || !filteredIndices(for: flags.wrappedValue).isEmpty
        if hasResults {
            Section {
                if expandedSections.contains(title) {
                    flagRows(flags: flags)
                }
            } header: {
            Button {
                withAnimation {
                    if expandedSections.contains(title) {
                        expandedSections.remove(title)
                    } else {
                        expandedSections.insert(title)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: expandedSections.contains(title) ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(width: 12)
                    Text(title)
                    Spacer()
                    Text("\(count)/\(total)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
        }
    }

    // MARK: - Flag Rows

    private func flagRows(flags: Binding<[FeatureFlag]>) -> some View {
        let indices = filteredIndices(for: flags.wrappedValue)
        return ForEach(indices, id: \.self) { index in
            let flag = flags[index]
            Toggle(isOn: Binding(
                get: { flag.wrappedValue.enabled },
                set: { newValue in
                    flags[index].wrappedValue.enabled = newValue
                    FeatureFlagStore.shared.setFlag(flag.wrappedValue.key, enabled: newValue)
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flag.wrappedValue.label)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                    Text(flag.wrappedValue.key)
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                        .monospaced()
                }
            }
            .tint(Color.rrPrimary)
        }
    }

    // MARK: - Bulk Actions

    private func setAll(_ value: Bool) {
        for i in activeFeatures.indices { activeFeatures[i].enabled = value }
        for i in futureFeatures.indices { futureFeatures[i].enabled = value }
        for i in activities.indices { activities[i].enabled = value }
        for i in assessments.indices { assessments[i].enabled = value }
        saveAllFlags()
    }

    private func resetDefaults() {
        activeFeatures = Self.defaultActiveFeatures
        futureFeatures = Self.defaultFutureFeatures
        activities = Self.defaultActivities
        assessments = Self.defaultAssessments
        saveAllFlags()
    }

    private func saveAllFlags() {
        let allFlags = activeFeatures + futureFeatures + activities + assessments
        for flag in allFlags {
            UserDefaults.standard.set(flag.enabled, forKey: "ff.\(flag.key)")
        }
        FeatureFlagStore.shared.flagsDidChange()
    }

    // MARK: - Defaults + Loading

    private static func loadFlags(_ defaults: [FeatureFlag]) -> [FeatureFlag] {
        defaults.map { flag in
            var f = flag
            if let saved = UserDefaults.standard.object(forKey: "ff.\(flag.key)") as? Bool {
                f.enabled = saved
            }
            return f
        }
    }

    private static let defaultActiveFeatures: [FeatureFlag] = [
        FeatureFlag(key: "feature.onboarding", label: "Onboarding", enabled: true),
        FeatureFlag(key: "feature.themes", label: "Themes", enabled: true),
        FeatureFlag(key: "feature.quick-actions", label: "Quick Actions", enabled: true),
        FeatureFlag(key: "feature.3circles", label: "3 Circles", enabled: false),
        FeatureFlag(key: "feature.vision", label: "Vision Statement", enabled: false),
    ]

    private static let defaultActivities: [FeatureFlag] = [
        FeatureFlag(key: "activity.sobriety-commitment", label: "Sobriety Commitment", enabled: true),
        FeatureFlag(key: "activity.affirmations", label: "Affirmations", enabled: true),
        FeatureFlag(key: "activity.urge-logging", label: "Urge Logging", enabled: true),
        FeatureFlag(key: "activity.journaling", label: "Journaling", enabled: true),
        FeatureFlag(key: "activity.faster-scale", label: "FASTER Scale", enabled: true),
        FeatureFlag(key: "activity.time-journal", label: "Time Journal", enabled: true),
        FeatureFlag(key: "activity.fanos", label: "FANOS Check-in", enabled: false),
        FeatureFlag(key: "activity.fitnap", label: "FITNAP Check-in", enabled: false),
        FeatureFlag(key: "activity.spouse-check-ins", label: "Spouse Check-ins", enabled: false),
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

    private static let defaultAssessments: [FeatureFlag] = [
        FeatureFlag(key: "assessment.sast-r", label: "SAST-R", enabled: false),
        FeatureFlag(key: "assessment.family-impact", label: "Family Impact", enabled: false),
        FeatureFlag(key: "assessment.denial", label: "Denial", enabled: false),
        FeatureFlag(key: "assessment.addiction-severity", label: "Addiction Severity", enabled: false),
        FeatureFlag(key: "assessment.relationship-health", label: "Relationship Health", enabled: false),
    ]

    private static let defaultFutureFeatures: [FeatureFlag] = [
        // Recovery Work & Tools
        FeatureFlag(key: "feature.partners.redemptiveliving.backbone", label: "Backbone (Redemptive Living)", enabled: false),
        FeatureFlag(key: "feature.relapse-prevention-plan", label: "Relapse Prevention Plan", enabled: false),
        FeatureFlag(key: "feature.post-mortem", label: "Post-Mortem", enabled: true),
        // General
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
}

#Preview {
    NavigationStack {
        DebugFlagsView()
    }
}
