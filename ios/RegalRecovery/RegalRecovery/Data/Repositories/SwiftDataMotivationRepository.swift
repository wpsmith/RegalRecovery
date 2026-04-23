import Foundation
import SwiftData

// MARK: - SwiftData Motivation Repository

@ModelActor
actor SwiftDataMotivationRepository: MotivationRepository {

    func save(_ motivation: RRMotivation) async throws {
        modelContext.insert(motivation)
        try modelContext.save()
    }

    func getAll(includeArchived: Bool) async throws -> [RRMotivation] {
        var descriptor = FetchDescriptor<RRMotivation>(
            sortBy: [
                SortDescriptor(\.importanceRating, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        )
        if !includeArchived {
            descriptor.predicate = #Predicate { $0.isArchived == false }
        }
        return try modelContext.fetch(descriptor)
    }

    func getByCategory(_ category: MotivationCategory) async throws -> [RRMotivation] {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.category == categoryRaw && $0.isArchived == false },
            sortBy: [
                SortDescriptor(\.importanceRating, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func get(id: UUID) async throws -> RRMotivation? {
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func delete(id: UUID) async throws {
        if let motivation = try await get(id: id) {
            let motivationId = motivation.id
            let historyDescriptor = FetchDescriptor<RRMotivationHistory>(
                predicate: #Predicate { $0.motivationId == motivationId }
            )
            let history = try modelContext.fetch(historyDescriptor)
            for entry in history {
                modelContext.delete(entry)
            }
            modelContext.delete(motivation)
            try modelContext.save()
        }
    }

    func count() async throws -> Int {
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.isArchived == false }
        )
        return try modelContext.fetchCount(descriptor)
    }

    func getActive() async throws -> [RRMotivation] {
        try await getAll(includeArchived: false)
    }

    func saveHistory(_ history: RRMotivationHistory) async throws {
        modelContext.insert(history)
        try modelContext.save()
    }

    func getHistory(for motivationId: UUID) async throws -> [RRMotivationHistory] {
        let descriptor = FetchDescriptor<RRMotivationHistory>(
            predicate: #Predicate { $0.motivationId == motivationId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
