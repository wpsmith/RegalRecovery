import SwiftUI

struct PrivacySettingsView: View {
    @State private var showExportJSONAlert = false
    @State private var showExportPDFAlert = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
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
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
