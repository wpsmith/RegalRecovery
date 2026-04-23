import Foundation
import SwiftData

@Observable
class BowtieHistoryViewModel {
    var completedSessions: [RRBowtieSession] = []

    func loadSessions(context: ModelContext) {
        let descriptor = FetchDescriptor<RRBowtieSession>(
            predicate: #Predicate { $0.status == "complete" },
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        completedSessions = (try? context.fetch(descriptor)) ?? []
    }

    func deleteSession(_ session: RRBowtieSession, context: ModelContext) {
        context.delete(session)
        loadSessions(context: context)
    }

    // MARK: - Analytics

    struct IDistribution {
        var insignificance: Int = 0
        var incompetence: Int = 0
        var impotence: Int = 0

        var dominant: ThreeIType? {
            let max = Swift.max(insignificance, incompetence, impotence)
            guard max > 0 else { return nil }
            if insignificance == max { return .insignificance }
            if incompetence == max { return .incompetence }
            return .impotence
        }
    }

    var totalIDistribution: IDistribution {
        var dist = IDistribution()
        for session in completedSessions {
            dist.insignificance += session.pastInsignificanceTotal + session.futureInsignificanceTotal
            dist.incompetence += session.pastIncompetenceTotal + session.futureIncompetenceTotal
            dist.impotence += session.pastImpotenceTotal + session.futureImpotenceTotal
        }
        return dist
    }

    struct RoleActivation: Identifiable {
        let id: UUID
        let label: String
        var totalIntensity: Int
        var frequency: Int
    }

    func roleActivations(roles: [RRUserRole]) -> [RoleActivation] {
        var activations: [UUID: RoleActivation] = [:]
        for role in roles {
            activations[role.id] = RoleActivation(id: role.id, label: role.label, totalIntensity: 0, frequency: 0)
        }
        for session in completedSessions {
            for marker in session.markers {
                if var a = activations[marker.roleId] {
                    a.totalIntensity += marker.totalIntensity
                    a.frequency += 1
                    activations[marker.roleId] = a
                }
            }
        }
        return activations.values.sorted { $0.totalIntensity > $1.totalIntensity }
    }

    var anticipatoryRatio: Double {
        let totalPast = completedSessions.reduce(0) { $0 + $1.pastMarkers.count }
        let totalFuture = completedSessions.reduce(0) { $0 + $1.futureMarkers.count }
        let total = totalPast + totalFuture
        guard total > 0 else { return 0 }
        return Double(totalFuture) / Double(total)
    }

    var backboneCompletionRate: Double {
        let total = completedSessions.reduce(0) { $0 + $1.markers.count }
        let processed = completedSessions.reduce(0) { $0 + $1.processedMarkerCount }
        guard total > 0 else { return 0 }
        return Double(processed) / Double(total)
    }
}
