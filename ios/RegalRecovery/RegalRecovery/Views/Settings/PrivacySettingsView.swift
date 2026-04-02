import SwiftData
import SwiftUI

struct PrivacySettingsView: View {
    @Query private var supportContacts: [RRSupportContact]
    @State private var showExportJSONAlert = false
    @State private var showExportPDFAlert = false
    @State private var showDeleteAlert = false

    private let columns = ["Sobriety", "Check-ins", "Activities", "Journal", "Financial"]

    var body: some View {
        List {
            // MARK: - Data Sharing Grid
            Section {
                if supportContacts.isEmpty {
                    Text("No support contacts configured. Add contacts in Support Network settings to manage data sharing.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                } else {
                    // Column headers
                    ScrollView(.horizontal, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header row
                            HStack(spacing: 0) {
                                Text("")
                                    .frame(width: 90, alignment: .leading)
                                ForEach(columns, id: \.self) { col in
                                    Text(col)
                                        .font(RRFont.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .frame(width: 64)
                                }
                            }
                            .padding(.bottom, 8)

                            Divider()

                            // Data rows
                            ForEach(supportContacts) { contact in
                                HStack(spacing: 0) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(contact.name)
                                            .font(RRFont.footnote)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color.rrText)
                                        Text(shortRole(contact.role))
                                            .font(RRFont.caption2)
                                            .foregroundStyle(roleColor(contact.role))
                                    }
                                    .frame(width: 90, alignment: .leading)

                                    ForEach(columns, id: \.self) { col in
                                        let granted = contact.permissions.contains(col)
                                        Text(granted ? "\u{2713}" : "\u{2014}")
                                            .font(.body)
                                            .foregroundStyle(granted ? Color.rrSuccess : Color.rrTextSecondary.opacity(0.4))
                                            .frame(width: 64)
                                    }
                                }
                                .padding(.vertical, 8)

                                if contact.id != supportContacts.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                Text("Data Sharing")
            }

            // MARK: - Export Section
            Section {
                Button {
                    showExportJSONAlert = true
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }

                Button {
                    showExportPDFAlert = true
                } label: {
                    Label("Export as PDF", systemImage: "doc.richtext")
                }
            } header: {
                Text("Export")
            }

            // MARK: - Delete Section
            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete My Account", systemImage: "trash")
                        .foregroundStyle(Color.rrDestructive)
                }
            } footer: {
                Text("Account deletion is permanent and takes effect after 30 days.")
            }
        }
        .listStyle(.insetGrouped)
        .alert("Export Successful", isPresented: $showExportJSONAlert) {
            Button("OK") { }
        } message: {
            Text("Your data has been exported as JSON.")
        }
        .alert("Export Successful", isPresented: $showExportPDFAlert) {
            Button("OK") { }
        } message: {
            Text("Your data has been exported as PDF.")
        }
        .alert("Delete Account?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account after 30 days.")
        }
    }

    private func shortRole(_ role: String) -> String {
        switch role {
        case "sponsor": return "Sponsor"
        case "counselor": return "Counselor"
        case "spouse": return "Spouse"
        case "accountabilityPartner": return "AP"
        default: return role.capitalized
        }
    }

    private func roleColor(_ role: String) -> Color {
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
    NavigationStack {
        PrivacySettingsView()
    }
}
