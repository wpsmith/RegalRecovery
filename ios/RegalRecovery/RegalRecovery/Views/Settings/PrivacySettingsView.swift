import SwiftUI

struct PrivacySettingsView: View {
    @State private var showExportJSONAlert = false
    @State private var showExportPDFAlert = false

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
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
