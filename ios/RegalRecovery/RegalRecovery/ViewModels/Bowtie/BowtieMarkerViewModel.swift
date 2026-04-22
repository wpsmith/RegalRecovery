import Foundation

@Observable
class BowtieMarkerViewModel {
    // Form state
    var selectedSide: BowtieSide = .past
    var selectedTimeInterval: Int = 6
    var selectedRoleId: UUID?
    var iActivations: [IActivation] = []
    var bigTicketEmotions: [BigTicketActivation] = []
    var customEmotions: [String] = []
    var selectedTriggerIds: Set<UUID> = []
    var briefDescription: String = ""

    static let maxDescriptionLength = 280

    var canSave: Bool {
        selectedRoleId != nil && (!iActivations.isEmpty || !bigTicketEmotions.isEmpty || !customEmotions.isEmpty)
    }

    func toggleIActivation(_ iType: ThreeIType) {
        if let index = iActivations.firstIndex(where: { $0.iType == iType }) {
            iActivations.remove(at: index)
        } else {
            iActivations.append(IActivation(iType: iType, intensity: 5))
        }
    }

    func updateIIntensity(_ iType: ThreeIType, intensity: Int) {
        guard let index = iActivations.firstIndex(where: { $0.iType == iType }) else { return }
        iActivations[index] = IActivation(iType: iType, intensity: max(1, min(10, intensity)))
    }

    func toggleBigTicket(_ emotion: BigTicketEmotion) {
        if let index = bigTicketEmotions.firstIndex(where: { $0.emotion == emotion }) {
            bigTicketEmotions.remove(at: index)
        } else {
            bigTicketEmotions.append(BigTicketActivation(emotion: emotion, intensity: 5))
        }
    }

    func updateBigTicketIntensity(_ emotion: BigTicketEmotion, intensity: Int) {
        guard let index = bigTicketEmotions.firstIndex(where: { $0.emotion == emotion }) else { return }
        bigTicketEmotions[index] = BigTicketActivation(emotion: emotion, intensity: max(1, min(10, intensity)))
    }

    func buildMarker() -> RRBowtieMarker {
        let clampedDescription = briefDescription.count > Self.maxDescriptionLength
            ? String(briefDescription.prefix(Self.maxDescriptionLength))
            : briefDescription

        return RRBowtieMarker(
            side: selectedSide,
            timeIntervalHours: selectedTimeInterval,
            roleId: selectedRoleId ?? UUID(),
            iActivations: iActivations,
            bigTicketEmotions: bigTicketEmotions.isEmpty ? nil : bigTicketEmotions,
            customEmotions: customEmotions.isEmpty ? nil : customEmotions,
            knownTriggerIds: selectedTriggerIds.isEmpty ? nil : Array(selectedTriggerIds),
            briefDescription: clampedDescription.isEmpty ? nil : clampedDescription
        )
    }

    func loadFromMarker(_ marker: RRBowtieMarker) {
        selectedSide = marker.bowtieSide
        selectedTimeInterval = marker.timeIntervalHours
        selectedRoleId = marker.roleId
        iActivations = marker.iActivations
        bigTicketEmotions = marker.bigTicketEmotions ?? []
        customEmotions = marker.customEmotions ?? []
        selectedTriggerIds = Set(marker.knownTriggerIds ?? [])
        briefDescription = marker.briefDescription ?? ""
    }

    func reset() {
        iActivations = []
        bigTicketEmotions = []
        customEmotions = []
        selectedTriggerIds = []
        briefDescription = ""
    }
}
