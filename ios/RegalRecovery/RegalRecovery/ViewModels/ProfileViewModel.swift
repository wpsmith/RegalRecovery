import Foundation
import Observation

@Observable
class ProfileViewModel {
    var user: UserProfile?
    var addictions: [String] = []
    var supportNetwork: [SupportContact] = []
    var streakDays: Int = 0

    // Edit state
    var editName: String = ""
    var editEmail: String = ""
    var editBirthYear: Int = 1988
    var editGender: String = ""
    var editTimezone: String = ""
    var editBibleVersion: String = ""

    func load() async {
        let profile = MockData.profile
        user = profile
        addictions = profile.addictions
        supportNetwork = MockData.supportNetwork
        streakDays = MockData.streak.currentDays

        // Populate edit state from profile
        editName = profile.name
        editEmail = profile.email
        editBirthYear = profile.birthYear
        editGender = profile.gender
        editTimezone = profile.timezone
        editBibleVersion = profile.bibleVersion
    }

    func save() async throws {
        let current = user
        user = UserProfile(
            name: editName,
            email: editEmail,
            birthYear: editBirthYear,
            gender: editGender,
            timezone: editTimezone,
            addictions: addictions,
            sobrietyDate: current?.sobrietyDate ?? Date(),
            bibleVersion: editBibleVersion,
            motivations: current?.motivations ?? [],
            avatarInitial: String(editName.prefix(1)).uppercased()
        )
    }

    func addAddiction(_ name: String, sobrietyDate: Date) async throws {
        guard !name.isEmpty, !addictions.contains(name) else { return }
        addictions.append(name)
    }

    func removeAddiction(_ name: String) async throws {
        addictions.removeAll(where: { $0 == name })
    }

    func addContact(name: String, role: String, phone: String) async throws {
        guard !name.isEmpty else { return }

        let contactRole: ContactRole
        switch role.lowercased() {
        case "sponsor": contactRole = .sponsor
        case "counselor", "counselor (csat)": contactRole = .counselor
        case "spouse": contactRole = .spouse
        default: contactRole = .accountabilityPartner
        }

        let contact = SupportContact(
            name: name,
            role: contactRole,
            permissionSummary: "No permissions set",
            linkedDaysAgo: 0,
            phone: phone
        )
        supportNetwork.append(contact)
    }

    func removeContact(_ contact: SupportContact) async throws {
        supportNetwork.removeAll(where: { $0.id == contact.id })
    }

    func updatePermissions(for contact: SupportContact, permissions: [String]) async throws {
        guard let index = supportNetwork.firstIndex(where: { $0.id == contact.id }) else { return }

        let existing = supportNetwork[index]
        let summary = permissions.isEmpty ? "No permissions set" : "Sees: \(permissions.joined(separator: ", "))"

        supportNetwork[index] = SupportContact(
            name: existing.name,
            role: existing.role,
            permissionSummary: summary,
            linkedDaysAgo: existing.linkedDaysAgo,
            phone: existing.phone
        )
    }
}
