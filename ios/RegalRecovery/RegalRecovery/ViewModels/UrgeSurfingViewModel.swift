import Foundation
import SwiftData

enum TimerPhase: String {
    case ready = "Ready"
    case running = "Running"
    case milestone = "Milestone"
    case completed = "Completed"
}

@Observable
class UrgeSurfingViewModel {

    // MARK: - State

    var isRunning = false
    var secondsRemaining = 1200 // 20 minutes
    var secondsElapsed = 0
    var phase: TimerPhase = .ready
    var currentMilestone: Int? // 5, 10, 15, or nil
    var milestoneMessage: String?
    var autoLoggedUrgeId: UUID?
    var showDismissOption = false
    var showCompanionBreathing = false
    var showCompanionPrayer = false
    var showCompanionAffirmations = false
    var activitiesUsed: Set<String> = []
    private var startTime: Date?

    // Wave animation
    var wavePhaseOffset: Double = 0

    /// Configured timer duration in seconds, read from UserDefaults.
    var configuredDurationSeconds: Int {
        let minutes = UserDefaults.standard.integer(forKey: "urgeSurfing.timerMinutes")
        let resolved = minutes > 0 ? minutes : 20
        return resolved * 60
    }

    /// Normalized progress 0...1
    var progress: Double {
        Double(secondsElapsed) / Double(configuredDurationSeconds)
    }

    /// Wave height decreases as timer progresses (urge subsides)
    var waveHeight: Double {
        max(0.1, 1.0 - progress * 0.7)
    }

    var timerDisplay: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Milestone minutes at 25%, 50%, 75% of configured duration.
    var milestoneMinutes: [Int] {
        let total = configuredDurationSeconds / 60
        return [total / 4, total / 2, (total * 3) / 4]
    }

    var milestonesPassed: Set<Int> {
        var passed: Set<Int> = []
        for m in milestoneMinutes {
            if secondsElapsed >= m * 60 { passed.insert(m) }
        }
        return passed
    }

    // MARK: - Actions

    func start(modelContext: ModelContext, userId: UUID) {
        phase = .running
        isRunning = true
        secondsRemaining = configuredDurationSeconds
        secondsElapsed = 0
        currentMilestone = nil
        milestoneMessage = nil
        activitiesUsed = []
        startTime = Date()

        // Auto-log urge
        let urgeId = UUID()
        let urgeLog = RRUrgeLog(
            id: urgeId,
            userId: userId,
            date: Date(),
            intensity: 0,
            triggers: [],
            notes: "Emergency tool activated",
            resolution: ""
        )
        modelContext.insert(urgeLog)
        try? modelContext.save()
        autoLoggedUrgeId = urgeId

        // Show dismiss banner for 5 seconds
        showDismissOption = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.showDismissOption = false
        }
    }

    func stop() {
        isRunning = false
        phase = .ready
        secondsRemaining = configuredDurationSeconds
        secondsElapsed = 0
        currentMilestone = nil
        milestoneMessage = nil
        wavePhaseOffset = 0
        activitiesUsed = []
        startTime = nil
    }

    /// Mark the auto-logged urge as successfully surfed and log the session.
    func markSurfed(modelContext: ModelContext) {
        let durationMinutes = secondsElapsed / 60
        let activitiesList = activitiesUsed.sorted()

        guard let urgeId = autoLoggedUrgeId else { return }
        let descriptor = FetchDescriptor<RRUrgeLog>(
            predicate: #Predicate { $0.id == urgeId }
        )
        if let urgeLog = try? modelContext.fetch(descriptor).first {
            var resolution = "Urge surfed (\(durationMinutes)m)"
            if !activitiesList.isEmpty {
                resolution += " — \(activitiesList.joined(separator: ", "))"
            }
            urgeLog.resolution = resolution
        }

        let activity = RRActivity(
            userId: UUID(),
            activityType: "Urge Surfing",
            date: startTime ?? Date(),
            data: JSONPayload([
                "durationSeconds": .int(secondsElapsed),
                "durationMinutes": .int(durationMinutes),
                "activitiesUsed": .array(activitiesList.map { .string($0) }),
                "completed": .bool(phase == .completed),
            ])
        )
        modelContext.insert(activity)
        try? modelContext.save()
    }

    func tick() {
        guard isRunning, secondsRemaining > 0 else { return }

        secondsRemaining -= 1
        secondsElapsed += 1
        wavePhaseOffset += 0.15

        // Check milestones
        checkMilestone()

        // Check completion
        if secondsRemaining <= 0 {
            phase = .completed
            isRunning = false
            milestoneMessage = String(localized: "You made it. The wave has passed.")
        }
    }

    func dismissAutoLog(modelContext: ModelContext) {
        guard let urgeId = autoLoggedUrgeId else { return }

        let descriptor = FetchDescriptor<RRUrgeLog>(
            predicate: #Predicate { $0.id == urgeId }
        )
        if let urgeLog = try? modelContext.fetch(descriptor).first {
            modelContext.delete(urgeLog)
            try? modelContext.save()
        }
        autoLoggedUrgeId = nil
        showDismissOption = false
    }

    // MARK: - Private

    private func checkMilestone() {
        let milestones = milestoneMinutes
        guard milestones.count == 3 else { return }

        let messages: [(Int, String)] = [
            (milestones[0], String(localized: "\(milestones[0]) minutes — you're riding the wave")),
            (milestones[1], String(localized: "\(milestones[1]) minutes — halfway there, the urge is fading")),
            (milestones[2], String(localized: "\(milestones[2]) minutes — almost through it")),
        ]

        for (minute, message) in messages {
            if secondsElapsed == minute * 60 {
                currentMilestone = minute
                milestoneMessage = message
                phase = .milestone
                clearMilestoneAfterDelay()
                return
            }
        }
    }

    private func clearMilestoneAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            guard let self, self.isRunning else { return }
            self.phase = .running
            self.milestoneMessage = nil
            self.currentMilestone = nil
        }
    }
}
