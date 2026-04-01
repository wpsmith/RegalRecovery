import Foundation
import Observation

@Observable
class PrivacyViewModel {
    var contacts: [SupportContact] = []
    var permissionMatrix: [[Bool]] = [] // rows=contacts, cols=categories
    var categories: [String] = ["Sobriety", "Check-ins", "Activities", "Journal", "Financial"]

    func load() async {
        contacts = MockData.supportNetwork

        // Build initial permission matrix from contact permission summaries
        permissionMatrix = contacts.map { contact in
            categories.map { category in
                permissionFromSummary(contact.permissionSummary, category: category)
            }
        }
    }

    func updatePermission(contactIndex: Int, categoryIndex: Int, allowed: Bool) async throws {
        guard contactIndex < permissionMatrix.count,
              categoryIndex < categories.count else { return }
        permissionMatrix[contactIndex][categoryIndex] = allowed
    }

    func exportData(format: String) async throws -> URL {
        let data = buildExportPayload()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let jsonData = try encoder.encode(data)

        let fileName = "regal_recovery_export_\(formattedDate()).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try jsonData.write(to: tempURL)

        return tempURL
    }

    func requestAccountDeletion() async throws {
        // In production this would call the API to schedule account deletion.
        // For now, mark the request timestamp locally.
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "accountDeletionRequestedAt")
    }

    // MARK: - Private

    private func permissionFromSummary(_ summary: String, category: String) -> Bool {
        let lower = summary.lowercased()
        if lower.contains("all") {
            // Check for exclusions like "All except journal & financial"
            let categoryLower = category.lowercased()
            if lower.contains("except") {
                return !lower.contains(categoryLower)
            }
            return true
        }
        return lower.contains(category.lowercased())
    }

    private func buildExportPayload() -> ExportPayload {
        let profile = MockData.profile
        let streak = MockData.streak

        let contactExports = contacts.enumerated().map { index, contact in
            ContactExport(
                name: contact.name,
                role: contact.role.rawValue,
                phone: contact.phone,
                permissions: index < permissionMatrix.count
                    ? Dictionary(uniqueKeysWithValues: zip(categories, permissionMatrix[index]))
                    : [:]
            )
        }

        return ExportPayload(
            exportDate: ISO8601DateFormatter().string(from: Date()),
            profile: ProfileExport(
                name: profile.name,
                email: profile.email,
                birthYear: profile.birthYear,
                gender: profile.gender,
                timezone: profile.timezone,
                addictions: profile.addictions,
                sobrietyDate: ISO8601DateFormatter().string(from: profile.sobrietyDate),
                bibleVersion: profile.bibleVersion,
                motivations: profile.motivations
            ),
            streak: StreakExport(
                currentDays: streak.currentDays,
                longestStreak: streak.longestStreak,
                totalRelapses: streak.totalRelapses
            ),
            supportNetwork: contactExports,
            threeCircles: ThreeCirclesExport(
                red: MockData.threeCircles.red,
                yellow: MockData.threeCircles.yellow,
                green: MockData.threeCircles.green
            )
        )
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Export Codable Types

private struct ExportPayload: Codable {
    let exportDate: String
    let profile: ProfileExport
    let streak: StreakExport
    let supportNetwork: [ContactExport]
    let threeCircles: ThreeCirclesExport
}

private struct ProfileExport: Codable {
    let name: String
    let email: String
    let birthYear: Int
    let gender: String
    let timezone: String
    let addictions: [String]
    let sobrietyDate: String
    let bibleVersion: String
    let motivations: [String]
}

private struct StreakExport: Codable {
    let currentDays: Int
    let longestStreak: Int
    let totalRelapses: Int
}

private struct ContactExport: Codable {
    let name: String
    let role: String
    let phone: String
    let permissions: [String: Bool]
}

private struct ThreeCirclesExport: Codable {
    let red: [String]
    let yellow: [String]
    let green: [String]
}
