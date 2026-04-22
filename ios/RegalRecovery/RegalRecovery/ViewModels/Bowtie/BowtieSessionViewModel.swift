import Foundation
import SwiftData

@Observable
class BowtieSessionViewModel {
    var session: RRBowtieSession?
    var selectedRoles: [RRUserRole] = []
    var markers: [RRBowtieMarker] = []
    var showCompletion = false
    var showSetup = true

    // Setup state
    var availableRoles: [RRUserRole] = []
    var selectedRoleIds: Set<UUID> = []
    var selectedVocabulary: EmotionVocabulary = .threeIs
    var selectedMode: BowtieSessionMode = .guided

    // Tallies
    var pastInsignificance: Int = 0
    var pastIncompetence: Int = 0
    var pastImpotence: Int = 0
    var futureInsignificance: Int = 0
    var futureIncompetence: Int = 0
    var futureImpotence: Int = 0

    func loadRoles(context: ModelContext) {
        let descriptor = FetchDescriptor<RRUserRole>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        availableRoles = (try? context.fetch(descriptor)) ?? []
    }

    func checkForDraft(context: ModelContext) {
        let descriptor = FetchDescriptor<RRBowtieSession>(
            predicate: #Predicate { $0.status == "draft" },
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        if let draft = (try? context.fetch(descriptor))?.first {
            resumeSession(draft)
        }
    }

    func resumeSession(_ existingSession: RRBowtieSession) {
        session = existingSession
        markers = existingSession.markers
        selectedRoleIds = Set(existingSession.selectedRoleIds)
        selectedVocabulary = existingSession.vocabulary
        selectedMode = existingSession.mode
        showSetup = false
        recalculateTallies()
    }

    func createSession(
        entryPath: BowtieEntryPath = .activities,
        referenceTimestamp: Date = Date(),
        context: ModelContext
    ) {
        let guidedCount = UserDefaults.standard.integer(forKey: "bowtie.guidedCompletionCount")
        let effectiveMode = guidedCount >= 3 ? BowtieSessionMode.freeform : selectedMode

        let newSession = RRBowtieSession(
            selectedRoleIds: Array(selectedRoleIds),
            emotionVocabulary: selectedVocabulary,
            entryPath: entryPath,
            sessionMode: effectiveMode
        )
        newSession.referenceTimestamp = referenceTimestamp
        context.insert(newSession)
        session = newSession
        markers = []
        showSetup = false
        recalculateTallies()
    }

    func addMarker(_ marker: RRBowtieMarker, context: ModelContext) {
        marker.session = session
        context.insert(marker)
        markers.append(marker)
        session?.modifiedAt = Date()
        recalculateTallies()
        updateSessionTallies()
    }

    func removeMarker(_ marker: RRBowtieMarker, context: ModelContext) {
        markers.removeAll { $0.id == marker.id }
        context.delete(marker)
        session?.modifiedAt = Date()
        recalculateTallies()
        updateSessionTallies()
    }

    func recalculateTallies() {
        pastInsignificance = 0; pastIncompetence = 0; pastImpotence = 0
        futureInsignificance = 0; futureIncompetence = 0; futureImpotence = 0

        for marker in markers {
            let isPast = marker.side == BowtieSide.past.rawValue
            for activation in marker.iActivations {
                switch activation.iType {
                case .insignificance:
                    if isPast { pastInsignificance += activation.intensity }
                    else { futureInsignificance += activation.intensity }
                case .incompetence:
                    if isPast { pastIncompetence += activation.intensity }
                    else { futureIncompetence += activation.intensity }
                case .impotence:
                    if isPast { pastImpotence += activation.intensity }
                    else { futureImpotence += activation.intensity }
                }
            }
        }
    }

    private func updateSessionTallies() {
        session?.pastInsignificanceTotal = pastInsignificance
        session?.pastIncompetenceTotal = pastIncompetence
        session?.pastImpotenceTotal = pastImpotence
        session?.futureInsignificanceTotal = futureInsignificance
        session?.futureIncompetenceTotal = futureIncompetence
        session?.futureImpotenceTotal = futureImpotence
    }

    func completeSession(context: ModelContext, userId: UUID) {
        guard let session else { return }
        session.bowtieStatus = .complete
        session.completedAt = Date()
        session.modifiedAt = Date()

        let markerCount = markers.count
        let pastCount = markers.filter { $0.side == BowtieSide.past.rawValue }.count
        let futureCount = markers.filter { $0.side == BowtieSide.future.rawValue }.count
        let processedCount = markers.filter(\.isProcessed).count

        let activity = RRActivity(
            userId: userId,
            activityType: "BOWTIE",
            date: Date(),
            data: JSONPayload([
                "sessionId": AnyCodableValue.string(session.id.uuidString),
                "roleCount": AnyCodableValue.int(session.selectedRoleIds.count),
                "markerCount": AnyCodableValue.int(markerCount),
                "pastMarkerCount": AnyCodableValue.int(pastCount),
                "futureMarkerCount": AnyCodableValue.int(futureCount),
                "processedCount": AnyCodableValue.int(processedCount)
            ])
        )
        context.insert(activity)

        if session.mode == .guided {
            let count = UserDefaults.standard.integer(forKey: "bowtie.guidedCompletionCount")
            UserDefaults.standard.set(count + 1, forKey: "bowtie.guidedCompletionCount")
        }

        showCompletion = true
    }

    func deleteSession(context: ModelContext) {
        guard let session else { return }
        context.delete(session)
        self.session = nil
        markers = []
        showSetup = true
    }

    var pastMarkers: [RRBowtieMarker] {
        markers.filter { $0.side == BowtieSide.past.rawValue }
            .sorted { $0.timeIntervalHours > $1.timeIntervalHours }
    }

    var futureMarkers: [RRBowtieMarker] {
        markers.filter { $0.side == BowtieSide.future.rawValue }
            .sorted { $0.timeIntervalHours < $1.timeIntervalHours }
    }

    // MARK: - Guided Mode

    var guidedCurrentRoleIndex: Int = 0
    var guidedCurrentSide: BowtieSide = .past

    var guidedCurrentRole: RRUserRole? {
        let selectedRoles = availableRoles.filter { selectedRoleIds.contains($0.id) }
        guard guidedCurrentRoleIndex < selectedRoles.count else { return nil }
        return selectedRoles[guidedCurrentRoleIndex]
    }

    var guidedPromptText: String {
        guard let role = guidedCurrentRole else { return "" }
        switch guidedCurrentSide {
        case .past:
            return String(localized: "Over the last 48 hours, as a \(role.label), has anything stirred the Three I's?")
        case .future:
            return String(localized: "Looking ahead, as a \(role.label), is anything coming that might stir your emotions?")
        }
    }

    var guidedIsComplete: Bool {
        let selectedRoles = availableRoles.filter { selectedRoleIds.contains($0.id) }
        return guidedCurrentSide == .future && guidedCurrentRoleIndex >= selectedRoles.count
    }

    func guidedAdvance() {
        let selectedRoles = availableRoles.filter { selectedRoleIds.contains($0.id) }
        if guidedCurrentRoleIndex + 1 < selectedRoles.count {
            guidedCurrentRoleIndex += 1
        } else if guidedCurrentSide == .past {
            guidedCurrentSide = .future
            guidedCurrentRoleIndex = 0
        }
    }

    func guidedSkipRole() {
        guidedAdvance()
    }
}
