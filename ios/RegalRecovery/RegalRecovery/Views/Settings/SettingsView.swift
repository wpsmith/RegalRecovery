import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var users: [RRUser]
    @Query private var streaks: [RRStreak]
    @Query private var supportContacts: [RRSupportContact]
    @Query(filter: #Predicate<RRDailyPlanItem> { $0.isEnabled == true })
    private var enabledPlanItems: [RRDailyPlanItem]
    @State private var showExportAlert = false
    @State private var showDeleteAlert = false
    @State private var ephemeralMode = false
    @State private var expandedSections: Set<String> = ["Profile", "Support Network", "My Recovery Foundation", "Preferences", "Privacy & Data", "Debug"]

    private var user: RRUser? { users.first }

    /// Compute current days from the first streak's addiction sobriety date.
    private var currentDays: Int {
        streaks.first?.currentDays ?? 0
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Profile Section
                Section {
                    if expandedSections.contains("Profile") {
                        // Profile header
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color.rrPrimary)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(user?.avatarInitial ?? "?")
                                        .font(.title2.weight(.bold))
                                        .foregroundStyle(.white)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user?.name ?? String(localized: "Set up profile"))
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                                RRBadge(text: "\(currentDays) days", color: .rrSuccess)
                                Text(user?.email ?? "")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                        .padding(.vertical, 4)

                        NavigationLink("Edit Profile") {
                            ProfileEditView()
                        }

                        NavigationLink("Addictions") {
                            AddictionManagementView()
                        }
                    }
                } header: {
                    sectionHeader("Profile")
                }

                // MARK: - Support Network Section
                Section {
                    if expandedSections.contains("Support Network") {
                        if supportContacts.isEmpty {
                            Text("No support contacts yet")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                        } else {
                            ForEach(supportContacts) { contact in
                                NavigationLink {
                                    SupportNetworkView()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(contact.name)
                                                .font(RRFont.body)
                                                .foregroundStyle(Color.rrText)
                                        }
                                        Spacer()
                                        RRBadge(text: contact.role.capitalized, color: contactRoleColor(contact.role))
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    sectionHeader("Support Network")
                }

                // MARK: - My Recovery Foundation
                Section {
                    if expandedSections.contains("My Recovery Foundation") {
                        NavigationLink {
                            RecoveryFoundationView()
                        } label: {
                            HStack {
                                Image(systemName: "shield.checkered")
                                    .foregroundStyle(Color.rrPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("My Recovery Foundation")
                                        .font(RRFont.body)
                                    Text("3 Circles, RPP, Vision, Support Network")
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }
                        }

                        NavigationLink {
                            RecoveryPlanSetupView()
                        } label: {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(Color.rrPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("My Recovery Plan")
                                        .font(RRFont.body)
                                    Text("\(enabledPlanItems.count) daily activities configured")
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }
                        }
                    }
                } header: {
                    sectionHeader("My Recovery Foundation")
                }

                // MARK: - Preferences Section
                Section {
                    if expandedSections.contains("Preferences") {
                        NavigationLink("Notifications") {
                            NotificationSettingsView()
                        }
                        if FeatureFlagStore.shared.isEnabled("feature.themes") {
                            NavigationLink("Appearance") {
                                AppearanceSettingsView()
                            }
                        }
                        NavigationLink {
                            LanguageSettingsView()
                        } label: {
                            HStack {
                                Text("Language")
                                    .foregroundStyle(Color.rrText)
                                Spacer()
                                Text(LanguageManager.shared.displayName)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                    }
                } header: {
                    sectionHeader("Preferences")
                }

                // MARK: - Privacy & Data Section
                Section {
                    if expandedSections.contains("Privacy & Data") {
                        NavigationLink("Privacy & Data Sharing") {
                            PrivacySettingsView()
                        }

                        Button("Export My Data") {
                            showExportAlert = true
                        }

                        Button("Delete My Account", role: .destructive) {
                            showDeleteAlert = true
                        }

                        Toggle(isOn: $ephemeralMode) {
                            Text("Ephemeral Mode")
                        }
                    }
                } header: {
                    sectionHeader("Privacy & Data")
                } footer: {
                    Text("Auto-delete journal entries after 30 days. Ephemeral entries are never included in backups.")
                }

                // MARK: - Debug
                Section {
                    if expandedSections.contains("Debug") {
                        NavigationLink {
                            DebugFlagsView()
                        } label: {
                            HStack {
                                Image(systemName: "flag.fill")
                                    .foregroundStyle(.orange)
                                Text("Feature Flags")
                                    .foregroundStyle(Color.rrText)
                            }
                        }

                        NavigationLink {
                            TestingModeView()
                        } label: {
                            HStack {
                                Image(systemName: "testtube.2")
                                    .foregroundStyle(.orange)
                                Text("Testing Mode")
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }
                } header: {
                    sectionHeader("Debug")
                } footer: {
                    Text("Toggle feature flags and testing tools for development.")
                }
            }
            .listStyle(.insetGrouped)
            .alert("Export My Data", isPresented: $showExportAlert) {
                Button("Export as JSON") { }
                Button("Export as PDF") { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your data export is ready.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) { }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete your account after 30 days.")
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
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
                Text(LocalizedStringKey(title))
                Spacer()
            }
        }
    }

    private func contactRoleColor(_ role: String) -> Color {
        switch role {
        case "sponsor": return .rrPrimary
        case "counselor": return .purple
        case "spouse": return .rrDestructive
        case "accountabilityPartner": return .rrSecondary
        default: return .rrTextSecondary
        }
    }
}

#Preview {
    SettingsView()
}
