import SwiftUI

struct LanguageSettingsView: View {
    @State private var languageManager = LanguageManager.shared
    @State private var showRestartAlert = false

    var body: some View {
        List {
            Section {
                ForEach(LanguageManager.supportedLanguages, id: \.code) { lang in
                    Button {
                        let previous = languageManager.currentLanguage
                        languageManager.currentLanguage = lang.code
                        if previous != lang.code && lang.code != "system" {
                            showRestartAlert = true
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.name)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                                if lang.code != "system" {
                                    Text(lang.code.uppercased())
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                }
                            }
                            Spacer()
                            if languageManager.currentLanguage == lang.code {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.rrPrimary)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            } footer: {
                Text("Changing the language requires restarting the app for full effect.")
                    .font(RRFont.caption)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Language")
        .alert("Restart Required", isPresented: $showRestartAlert) {
            Button("OK") { }
        } message: {
            Text("Please close and reopen the app for the language change to take full effect.")
        }
    }
}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
