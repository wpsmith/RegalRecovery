import Foundation
import SwiftData
import SwiftUI

// MARK: - View Model Data Types

struct TodayPlanItem: Identifiable {
    let id: UUID
    let activityType: String
    let displayName: String
    let icon: String
    let iconColor: Color
    let scheduledHour: Int
    let scheduledMinute: Int
    let instanceIndex: Int
    var state: DailyPlanActivityState
    let weight: Double
    var completedAt: Date?

    var scheduledTimeString: String {
        let hour12 = scheduledHour == 0 ? 12 : (scheduledHour > 12 ? scheduledHour - 12 : scheduledHour)
        let ampm = scheduledHour < 12 ? "AM" : "PM"
        if scheduledMinute == 0 {
            return "\(hour12):00 \(ampm)"
        }
        return String(format: "%d:%02d %@", hour12, scheduledMinute, ampm)
    }
}

struct RecoveryWorkCard: Identifiable {
    let id: UUID
    let activityName: String
    let triggerReason: String
    let activityType: String
}

struct SobrietyAddictionData: Identifiable {
    let id: UUID
    let name: String
    let sobrietyDate: Date
}

// MARK: - Today View Model

@Observable
class TodayViewModel {

    var greeting: String = ""
    var streakDays: Int = 0
    var planItems: [TodayPlanItem] = []
    var score: Int = 0
    var scoreLevel: DailyScoreLevel = .minimal
    var totalPlanned: Int = 0
    var totalCompleted: Int = 0
    var morningCommitmentDone: Bool = false
    var recoveryWorkCards: [RecoveryWorkCard] = []
    var hasPlan: Bool = false
    var userName: String = ""

    // Sobriety
    var sobrietyAddictions: [SobrietyAddictionData] = []

    // MARK: - Load

    func load(context: ModelContext) {
        loadUser(context: context)
        loadStreak(context: context)
        loadSobriety(context: context)
        loadPlanItems(context: context)
        computeScore()
        loadRecoveryWorkCards(context: context)
    }

    // MARK: - Actions

    func completeActivity(_ item: TodayPlanItem, context: ModelContext) {
        guard let idx = planItems.firstIndex(where: { $0.id == item.id }) else { return }
        planItems[idx].state = .completed
        computeScore()
    }

    func skipActivity(_ item: TodayPlanItem, reason: String) {
        guard let idx = planItems.firstIndex(where: { $0.id == item.id }) else { return }
        planItems[idx].state = .skipped
        computeScore()
    }

    // MARK: - Private Loading

    private func loadUser(context: ModelContext) {
        let descriptor = FetchDescriptor<RRUser>()
        guard let user = try? context.fetch(descriptor).first else {
            greeting = timeOfDayGreeting(name: "friend")
            return
        }
        let firstName = user.name.components(separatedBy: " ").first ?? user.name
        userName = firstName
        greeting = timeOfDayGreeting(name: firstName)
    }

    private func loadStreak(context: ModelContext) {
        let descriptor = FetchDescriptor<RRStreak>()
        guard let streak = try? context.fetch(descriptor).first else {
            streakDays = 0
            return
        }
        streakDays = streak.currentDays
    }

    private func loadSobriety(context: ModelContext) {
        let descriptor = FetchDescriptor<RRAddiction>()
        guard let addictions = try? context.fetch(descriptor), !addictions.isEmpty else {
            sobrietyAddictions = []
            return
        }
        sobrietyAddictions = addictions.map { addiction in
            SobrietyAddictionData(
                id: addiction.id,
                name: addiction.name,
                sobrietyDate: addiction.sobrietyDate
            )
        }
    }

    func resetSobrietyDate(addictionId: UUID, newDate: Date, context: ModelContext) {
        let descriptor = FetchDescriptor<RRAddiction>(
            predicate: #Predicate { $0.id == addictionId }
        )
        guard let addiction = try? context.fetch(descriptor).first else { return }
        addiction.sobrietyDate = newDate
        addiction.modifiedAt = Date()
        try? context.save()
        loadSobriety(context: context)
    }

    private func loadPlanItems(context: ModelContext) {
        let planDescriptor = FetchDescriptor<RRRecoveryPlan>(
            predicate: #Predicate { $0.isActive == true }
        )
        guard let plan = try? context.fetch(planDescriptor).first,
              let items = plan.items else {
            hasPlan = false
            planItems = []
            return
        }

        hasPlan = true
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)

        let enabledActivityTypes = Set(DailyEligibleActivity.enabled.map(\.activityType))

        let enabledItems = items
            .filter { $0.isEnabled }
            .filter { enabledActivityTypes.contains($0.activityType) }
            .filter { $0.daysOfWeek.isEmpty || $0.daysOfWeek.contains(todayWeekday) }
            .sorted { $0.sortOrder < $1.sortOrder }

        let otherCount = enabledItems.filter { !isMorningCommitment($0.activityType) }.count
        let otherWeight = otherCount > 0 ? 80.0 / Double(otherCount) : 0.0

        // Build a count of how many instances exist per activityType (for display names)
        let siblingCounts = Dictionary(grouping: enabledItems, by: \.activityType)
            .mapValues(\.count)

        // Get completion timestamps per activityType for count-based matching
        let completionTimestamps = activityCompletionTimestamps(for: enabledItems, context: context)

        // Track how many instances of each type we've emitted so far
        // to determine which instances are "completed" by count
        var emittedCounts: [String: Int] = [:]

        planItems = enabledItems.map { item in
            let eligible = DailyEligibleActivity.enabled.first(where: { $0.activityType == item.activityType })
            let isMorning = isMorningCommitment(item.activityType)
            let weight = isMorning ? 20.0 : otherWeight

            let emittedSoFar = emittedCounts[item.activityType] ?? 0
            emittedCounts[item.activityType] = emittedSoFar + 1

            let timestamps = completionTimestamps[item.activityType] ?? []
            let isThisInstanceCompleted = emittedSoFar < timestamps.count
            let completedAt = isThisInstanceCompleted ? timestamps[emittedSoFar] : nil

            let state: DailyPlanActivityState
            if isThisInstanceCompleted {
                state = .completed
            } else {
                state = computeTimeBasedState(
                    scheduledHour: item.scheduledHour,
                    scheduledMinute: item.scheduledMinute,
                    currentHour: currentHour,
                    currentMinute: currentMinute
                )
            }

            let siblings = siblingCounts[item.activityType] ?? 1
            let baseName = eligible?.displayName ?? item.activityType
            let displayName = siblings > 1 ? "\(baseName) #\(item.instanceIndex + 1)" : baseName

            return TodayPlanItem(
                id: item.id,
                activityType: item.activityType,
                displayName: displayName,
                icon: eligible?.icon ?? "circle",
                iconColor: activityColor(for: item.activityType),
                scheduledHour: item.scheduledHour,
                scheduledMinute: item.scheduledMinute,
                instanceIndex: item.instanceIndex,
                state: state,
                weight: weight,
                completedAt: completedAt
            )
        }
    }

    private func computeTimeBasedState(
        scheduledHour: Int,
        scheduledMinute: Int,
        currentHour: Int,
        currentMinute: Int
    ) -> DailyPlanActivityState {
        let currentMinutes = currentHour * 60 + currentMinute
        let scheduledMinutes = scheduledHour * 60 + scheduledMinute
        let overdueThreshold = scheduledMinutes + 120

        if currentMinutes >= overdueThreshold {
            return .overdue
        } else if currentMinutes >= scheduledMinutes {
            return .pending
        } else {
            return .upcoming
        }
    }

    func computeActivityState(
        for item: RRDailyPlanItem,
        context: ModelContext,
        currentHour: Int,
        currentMinute: Int
    ) -> DailyPlanActivityState {
        let completed = isActivityCompleted(activityType: item.activityType, context: context)
        if completed { return .completed }

        return computeTimeBasedState(
            scheduledHour: item.scheduledHour,
            scheduledMinute: item.scheduledMinute,
            currentHour: currentHour,
            currentMinute: currentMinute
        )
    }

    // MARK: - Score

    private func computeScore() {
        let morningItem = planItems.first(where: { isMorningCommitment($0.activityType) })
        let morningInPlan = morningItem != nil
        let morningDone = morningItem?.state == .completed
        morningCommitmentDone = morningDone

        let others = planItems.filter { !isMorningCommitment($0.activityType) }
        let othersCompleted = others.filter { $0.state == .completed }.count

        totalPlanned = planItems.count
        totalCompleted = planItems.filter { $0.state == .completed }.count

        score = DailyScoreCalculator.calculate(
            morningDone: morningDone,
            otherCompleted: othersCompleted,
            otherTotal: others.count,
            morningInPlan: morningInPlan
        )
        scoreLevel = DailyScoreCalculator.level(for: score)
    }

    // MARK: - Recovery Work Cards

    private func loadRecoveryWorkCards(context: ModelContext) {
        var cards: [RecoveryWorkCard] = []

        // Check for recent relapses that need post-mortem
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        let relapseDescriptor = FetchDescriptor<RRRelapse>(
            predicate: #Predicate { $0.date >= twoDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let relapses = try? context.fetch(relapseDescriptor), !relapses.isEmpty {
            cards.append(RecoveryWorkCard(
                id: UUID(),
                activityName: "Post-Mortem Analysis",
                triggerReason: "From recent relapse",
                activityType: ActivityType.postMortem.rawValue
            ))
        }

        recoveryWorkCards = cards
    }

    // MARK: - Completion Timestamps (for multi-instance)

    /// Returns a dictionary mapping activityType -> sorted completion timestamps today.
    /// Used for count-based matching: if plan has 2 Prayer items and user logged 1 prayer,
    /// the first instance (by time) is completed and the second is pending.
    private func activityCompletionTimestamps(for items: [RRDailyPlanItem], context: ModelContext) -> [String: [Date]] {
        let uniqueTypes = Set(items.map(\.activityType))
        var result: [String: [Date]] = [:]
        for activityType in uniqueTypes {
            result[activityType] = completionTimestamps(activityType: activityType, context: context)
        }
        return result
    }

    private func completionTimestamps(activityType: String, context: ModelContext) -> [Date] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        if isMorningCommitment(activityType) {
            return fetchDates(
                RRCommitment.self,
                predicate: #Predicate { $0.type == "morning" && $0.date >= todayStart && $0.date < tomorrow },
                dateKeyPath: \.date,
                context: context
            )
        }

        if activityType == ActivityType.recoveryCheckIn.rawValue {
            return fetchDates(RRCheckIn.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.prayer.rawValue {
            return fetchDates(RRPrayerLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.exercise.rawValue {
            return fetchDates(RRExerciseLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.journal.rawValue {
            return fetchDates(RRJournalEntry.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.emotionalJournal.rawValue {
            return fetchDates(RREmotionalJournal.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.mood.rawValue {
            return fetchDates(RRMoodEntry.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.gratitude.rawValue {
            return fetchDates(RRGratitudeEntry.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.fasterScale.rawValue {
            return fetchDates(RRFASTEREntry.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.phoneCalls.rawValue {
            return fetchDates(RRPhoneCallLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.meetingsAttended.rawValue {
            return fetchDates(RRMeetingLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.spouseCheckIn.rawValue {
            return fetchDates(RRSpouseCheckIn.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.affirmationLog.rawValue {
            return fetchDates(
                RRActivity.self,
                predicate: #Predicate { $0.activityType == "Affirmation Log" && $0.date >= todayStart && $0.date < tomorrow },
                dateKeyPath: \.date,
                context: context
            )
        }
        if activityType == "devotional" {
            let descriptor = FetchDescriptor<RRDevotionalProgress>(
                predicate: #Predicate { $0.completedAt != nil }
            )
            let results = (try? context.fetch(descriptor)) ?? []
            return results.compactMap { item in
                guard let completedAt = item.completedAt, calendar.isDateInToday(completedAt) else { return nil }
                return completedAt
            }.sorted()
        }

        // Generic fallback
        return fetchDates(
            RRActivity.self,
            predicate: #Predicate { $0.activityType == activityType && $0.date >= todayStart && $0.date < tomorrow },
            dateKeyPath: \.date,
            context: context
        )
    }

    private func fetchDates<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>,
        dateKeyPath: KeyPath<T, Date>,
        context: ModelContext
    ) -> [Date] {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        guard let results = try? context.fetch(descriptor) else { return [] }
        return results.map { $0[keyPath: dateKeyPath] }.sorted()
    }

    // MARK: - Completion Checks (single bool, kept for compatibility)

    private func isActivityCompleted(activityType: String, context: ModelContext) -> Bool {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        if isMorningCommitment(activityType) {
            return hasRecord(
                RRCommitment.self,
                predicate: #Predicate { $0.type == "morning" && $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.recoveryCheckIn.rawValue {
            return hasRecord(
                RRCheckIn.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.prayer.rawValue {
            return hasRecord(
                RRPrayerLog.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.exercise.rawValue {
            return hasRecord(
                RRExerciseLog.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.journal.rawValue {
            return hasRecord(
                RRJournalEntry.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.emotionalJournal.rawValue {
            return hasRecord(
                RREmotionalJournal.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.mood.rawValue {
            return hasRecord(
                RRMoodEntry.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.gratitude.rawValue {
            return hasRecord(
                RRGratitudeEntry.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.fasterScale.rawValue {
            return hasRecord(
                RRFASTEREntry.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.phoneCalls.rawValue {
            return hasRecord(
                RRPhoneCallLog.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.meetingsAttended.rawValue {
            return hasRecord(
                RRMeetingLog.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.spouseCheckIn.rawValue {
            return hasRecord(
                RRSpouseCheckIn.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        if activityType == ActivityType.affirmationLog.rawValue {
            return hasRecord(
                RRActivity.self,
                predicate: #Predicate { $0.activityType == "Affirmation Log" && $0.date >= todayStart && $0.date < tomorrow },
                context: context
            )
        }

        // For devotional, check DevotionalProgress with today's date
        if activityType == "devotional" {
            return hasRecord(
                RRDevotionalProgress.self,
                predicate: #Predicate { $0.completedAt != nil },
                context: context,
                additionalCheck: { items in
                    let calendar = Calendar.current
                    return items.contains { item in
                        guard let completedAt = item.completedAt else { return false }
                        return calendar.isDateInToday(completedAt)
                    }
                }
            )
        }

        // Generic fallback: check RRActivity table
        return hasRecord(
            RRActivity.self,
            predicate: #Predicate { $0.activityType == activityType && $0.date >= todayStart && $0.date < tomorrow },
            context: context
        )
    }

    private func hasRecord<T: PersistentModel>(
        _ type: T.Type,
        predicate: Predicate<T>,
        context: ModelContext,
        additionalCheck: (([T]) -> Bool)? = nil
    ) -> Bool {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 5
        guard let results = try? context.fetch(descriptor) else { return false }
        if let check = additionalCheck {
            return check(results)
        }
        return !results.isEmpty
    }

    // MARK: - Helpers

    private func isMorningCommitment(_ activityType: String) -> Bool {
        activityType == ActivityType.sobrietyCommitment.rawValue
    }

    private func timeOfDayGreeting(name: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let period: String
        switch hour {
        case 0..<12: period = "Good morning"
        case 12..<17: period = "Good afternoon"
        default: period = "Good evening"
        }
        return "\(period), \(name)"
    }

    private func activityColor(for activityType: String) -> Color {
        if let at = ActivityType(rawValue: activityType) {
            return at.iconColor
        }
        // Fallback colors for activity types not in the enum
        switch activityType {
        case "devotional": return .rrPrimary
        case "memoryVerseReview": return .rrPrimary
        case "pci": return .orange
        case "nutrition": return .green
        case "actingInBehaviors": return .blue
        case "voiceJournal": return .purple
        case "bookReading": return .rrPrimary
        case "personCheckInSpouse": return .pink
        case "personCheckInSponsor": return .rrPrimary
        case "personCheckInCounselor": return .purple
        default: return .rrSecondary
        }
    }
}
