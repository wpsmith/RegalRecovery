import Foundation

// MARK: - Motivation Repository

protocol MotivationRepository: Sendable {
    func save(_ motivation: RRMotivation) async throws
    func getAll(includeArchived: Bool) async throws -> [RRMotivation]
    func getByCategory(_ category: MotivationCategory) async throws -> [RRMotivation]
    func get(id: UUID) async throws -> RRMotivation?
    func delete(id: UUID) async throws
    func count() async throws -> Int
    func getActive() async throws -> [RRMotivation]
    func saveHistory(_ history: RRMotivationHistory) async throws
    func getHistory(for motivationId: UUID) async throws -> [RRMotivationHistory]
}
