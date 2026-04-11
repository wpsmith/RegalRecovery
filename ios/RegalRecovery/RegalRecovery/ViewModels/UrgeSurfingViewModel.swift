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

    // Wave animation
    var wavePhaseOffset: Double = 0

    /// Normalized progress 0...1
    var progress: Double {
        Double(secondsElapsed) / 1200.0
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

    var milestonesPassed: Set<Int> {
        var passed: Set<Int> = []
        if secondsElapsed >= 300 { passed.insert(5) }
        if secondsElapsed >= 600 { passed.insert(10) }
        if secondsElapsed >= 900 { passed.insert(15) }
        return passed
    }

    // MARK: - Actions

    func start(modelContext: ModelContext, userId: UUID) {
        phase = .running
        isRunning = true
        secondsRemaining = 1200
        secondsElapsed = 0
        currentMilestone = nil
        milestoneMessage = nil

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
        secondsRemaining = 1200
        secondsElapsed = 0
        currentMilestone = nil
        milestoneMessage = nil
        wavePhaseOffset = 0
    }

    /// Mark the auto-logged urge as successfully surfed.
    func markSurfed(modelContext: ModelContext) {
        guard let urgeId = autoLoggedUrgeId else { return }
        let descriptor = FetchDescriptor<RRUrgeLog>(
            predicate: #Predicate { $0.id == urgeId }
        )
        if let urgeLog = try? modelContext.fetch(descriptor).first {
            urgeLog.resolution = "Urge surfed (\(secondsElapsed / 60)m)"
        }
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
            milestoneMessage = "You made it. The wave has passed."
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
        let minutesElapsed = secondsElapsed / 60

        switch secondsElapsed {
        case 300: // 5 minutes
            currentMilestone = 5
            milestoneMessage = "5 minutes — you're riding the wave"
            phase = .milestone
            clearMilestoneAfterDelay()
        case 600: // 10 minutes
            currentMilestone = 10
            milestoneMessage = "10 minutes — halfway there, the urge is fading"
            phase = .milestone
            clearMilestoneAfterDelay()
        case 900: // 15 minutes
            currentMilestone = 15
            milestoneMessage = "15 minutes — almost through it"
            phase = .milestone
            clearMilestoneAfterDelay()
        default:
            break
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
