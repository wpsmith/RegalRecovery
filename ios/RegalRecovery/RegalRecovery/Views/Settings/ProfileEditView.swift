import SwiftData
import SwiftUI

struct ProfileEditView: View {
    @Query private var users: [RRUser]
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var birthYear: Int = 1990
    @State private var gender: String = "Male"
    @State private var timezone: String = "America/Chicago"
    @State private var bibleVersion: String = "ESV"
    @State private var hasLoaded = false

    private let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]
    private let timezoneOptions = [
        "America/New_York",
        "America/Chicago",
        "America/Denver",
        "America/Los_Angeles",
        "America/Anchorage",
        "Pacific/Honolulu",
    ]
    private let bibleVersionOptions = ["ESV", "NIV", "NKJV", "KJV", "NLT", "NASB", "CSB", "MSG"]

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
            } header: {
                Text("Name")
            }

            Section {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
            } header: {
                Text("Email")
            }

            Section {
                Picker("Birth Year", selection: $birthYear) {
                    ForEach(1940...2010, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            } header: {
                Text("Birth Year")
            }

            Section {
                Picker("Gender", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            } header: {
                Text("Gender")
            }

            Section {
                Picker("Timezone", selection: $timezone) {
                    ForEach(timezoneOptions, id: \.self) { tz in
                        Text(tz.replacingOccurrences(of: "America/", with: "").replacingOccurrences(of: "Pacific/", with: "").replacingOccurrences(of: "_", with: " "))
                            .tag(tz)
                    }
                }
            } header: {
                Text("Timezone")
            }

            Section {
                Picker("Bible Version", selection: $bibleVersion) {
                    ForEach(bibleVersionOptions, id: \.self) { version in
                        Text(version).tag(version)
                    }
                }
            } header: {
                Text("Bible Version")
            }
        }
        .onAppear {
            guard !hasLoaded, let user = users.first else { return }
            name = user.name
            email = user.email
            birthYear = user.birthYear
            gender = user.gender
            timezone = user.timezone
            bibleVersion = user.bibleVersion
            hasLoaded = true
        }
        .onChange(of: name) { saveProfile() }
        .onChange(of: email) { saveProfile() }
        .onChange(of: birthYear) { saveProfile() }
        .onChange(of: gender) { saveProfile() }
        .onChange(of: timezone) { saveProfile() }
        .onChange(of: bibleVersion) { saveProfile() }
    }

    private func saveProfile() {
        guard hasLoaded, let user = users.first else { return }
        user.name = name
        user.email = email
        user.birthYear = birthYear
        user.gender = gender
        user.timezone = timezone
        user.bibleVersion = bibleVersion
        user.modifiedAt = Date()
    }
}

#Preview {
    NavigationStack {
        ProfileEditView()
    }
}
