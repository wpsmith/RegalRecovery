import SwiftData
import SwiftUI

struct SettingsView: View {
    @Query private var users: [RRUser]
    @Query private var streaks: [RRStreak]
    @Query private var supportContacts: [RRSupportContact]
    @State private var showExportAlert = false
    @State private var showDeleteAlert = false
    @State private var ephemeralMode = false

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
                            Text(user?.name ?? "Set up profile")
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

                    NavigationLink("Addiction Management") {
                        AddictionManagementView()
                    }
                }

                // MARK: - Support Network Section
                Section {
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
                                        Text(contact.permissions.joined(separator: ", "))
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                    Spacer()
                                    RRBadge(text: contact.role.capitalized, color: contactRoleColor(contact.role))
                                }
                            }
                        }
                    }
                } header: {
                    Text("Support Network")
                }

                // MARK: - Preferences Section
                Section {
                    NavigationLink("Notifications") {
                        NotificationSettingsView()
                    }
                    NavigationLink("Appearance") {
                        AppearanceSettingsView()
                    }
                } header: {
                    Text("Preferences")
                }

                // MARK: - Privacy & Data Section
                Section {
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
                } header: {
                    Text("Privacy & Data")
                } footer: {
                    Text("Auto-delete journal entries after 30 days. Ephemeral entries are never included in backups.")
                }

                // MARK: - About Section
                Section {
                    NavigationLink("About") {
                        AboutView()
                    }
                }

                // MARK: - Debug
                Section {
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
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Toggle feature flags for development and testing.")
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
