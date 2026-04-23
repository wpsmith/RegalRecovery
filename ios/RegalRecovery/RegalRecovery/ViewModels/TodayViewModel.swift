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
    var hasAddictions: Bool = false
    /// Activity types present in today's plan (for gating standalone cards).
    var planActivityTypes: Set<String> = []
    var userName: String = ""

    // Sobriety
    var sobrietyAddictions: [SobrietyAddictionData] = []

    // Activity log
    var todayActivityLog: [RecentActivity] = []

    // MARK: - Load

    func load(context: ModelContext) {
        loadAddictions(context: context)
        loadUser(context: context)
        loadStreak(context: context)
        loadSobriety(context: context)
        loadPlanItems(context: context)
        computeScore()
        loadRecoveryWorkCards(context: context)
        loadTodayActivityLog(context: context)

        // Backfill PCI missed days
        if let userId = (try? context.fetch(FetchDescriptor<RRUser>()))?.first?.id {
            PCIMissedDayService.backfillMissedDays(context: context, userId: userId)
        }
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

    private func loadAddictions(context: ModelContext) {
        let descriptor = FetchDescriptor<RRAddiction>()
        let addictions = (try? context.fetch(descriptor)) ?? []
        hasAddictions = !addictions.isEmpty
    }

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
            planActivityTypes = []
            return
        }

        hasPlan = true
        planActivityTypes = Set(items.filter(\.isEnabled).map(\.activityType))
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

    // MARK: - Today Activity Log

    private func loadTodayActivityLog(context: ModelContext) {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: todayStart)!

        let fmt = RelativeDateTimeFormatter()
        fmt.unitsStyle = .short
        let now = Date()

        var all: [(date: Date, item: RecentActivity)] = []

        // Commitments
        let commitmentDesc = FetchDescriptor<RRCommitment>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(commitmentDesc) {
            for c in results {
                let label = c.type == "morning" ? "Morning Commitment" : "Evening Review"
                let icon = c.type == "morning" ? "sunrise.fill" : "moon.stars.fill"
                let color: Color = c.type == "morning" ? .rrSecondary : .rrPrimary
                all.append((c.date, RecentActivity(title: label, detail: "Completed", time: fmt.localizedString(for: c.date, relativeTo: now), icon: icon, iconColor: color)))
            }
        }

        // Mood
        let moodDesc = FetchDescriptor<RRMoodEntry>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(moodDesc) {
            for m in results {
                let detail: String = {
                    var parts = [m.primaryMood]
                    if let secondary = m.secondaryEmotion { parts.append(secondary) }
                    return parts.joined(separator: " · ")
                }()
                all.append((m.date, RecentActivity(title: "Mood Check-In", detail: detail, time: fmt.localizedString(for: m.date, relativeTo: now), icon: "face.smiling", iconColor: .yellow)))
            }
        }

        // Prayer
        let prayerDesc = FetchDescriptor<RRPrayerLog>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(prayerDesc) {
            for p in results {
                all.append((p.date, RecentActivity(title: "Prayer", detail: "\(p.durationMinutes) min", time: fmt.localizedString(for: p.date, relativeTo: now), icon: "hands.and.sparkles.fill", iconColor: .purple)))
            }
        }

        // Exercise
        let exerciseDesc = FetchDescriptor<RRExerciseLog>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(exerciseDesc) {
            for e in results {
                all.append((e.date, RecentActivity(title: "Exercise", detail: "\(e.durationMinutes) min \(e.exerciseType)", time: fmt.localizedString(for: e.date, relativeTo: now), icon: "figure.run", iconColor: .blue)))
            }
        }

        // FASTER Scale
        let fasterDesc = FetchDescriptor<RRFASTEREntry>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(fasterDesc) {
            for f in results {
                let stage = FASTERStage(rawValue: f.stage) ?? .forgettingPriorities
                all.append((f.date, RecentActivity(title: "FASTER Scale", detail: stage.name, time: fmt.localizedString(for: f.date, relativeTo: now), icon: "gauge.with.needle", iconColor: stage.color)))
            }
        }

        // PCI / Life Balance
        let pciDesc = FetchDescriptor<RRPCIDailyEntry>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }
        )
        if let results = try? context.fetch(pciDesc) {
            for p in results {
                let scoreText = "\(p.totalScore)/7"
                let detail = p.isMissedDay ? "Missed - Auto-scored 7" : scoreText
                all.append((p.createdAt, RecentActivity(
                    title: "Life Balance",
                    detail: detail,
                    time: fmt.localizedString(for: p.createdAt, relativeTo: now),
                    icon: "checklist",
                    iconColor: .orange
                )))
            }
        }

        // Journal
        let journalDesc = FetchDescriptor<RRJournalEntry>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(journalDesc) {
            for j in results {
                let snippet = String(j.content.prefix(40))
                all.append((j.date, RecentActivity(title: "Journal", detail: snippet, time: fmt.localizedString(for: j.date, relativeTo: now), icon: "note.text", iconColor: .purple)))
            }
        }

        // Gratitude
        let gratitudeDesc = FetchDescriptor<RRGratitudeEntry>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(gratitudeDesc) {
            for g in results {
                all.append((g.date, RecentActivity(title: "Gratitude", detail: "\(g.items.count) items", time: fmt.localizedString(for: g.date, relativeTo: now), icon: "leaf.fill", iconColor: .rrSuccess)))
            }
        }

        // Urge Log
        let urgeDesc = FetchDescriptor<RRUrgeLog>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(urgeDesc) {
            for u in results {
                all.append((u.date, RecentActivity(title: "Urge Log", detail: "\(u.intensity)/10", time: fmt.localizedString(for: u.date, relativeTo: now), icon: "exclamationmark.triangle.fill", iconColor: .orange)))
            }
        }

        // Phone Calls
        let phoneDesc = FetchDescriptor<RRPhoneCallLog>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(phoneDesc) {
            for pc in results {
                all.append((pc.date, RecentActivity(title: "Phone Call", detail: "\(pc.contactName), \(pc.durationMinutes) min", time: fmt.localizedString(for: pc.date, relativeTo: now), icon: "phone.fill", iconColor: .green)))
            }
        }

        // Meetings
        let meetingDesc = FetchDescriptor<RRMeetingLog>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(meetingDesc) {
            for ml in results {
                all.append((ml.date, RecentActivity(title: "Meeting", detail: ml.meetingName, time: fmt.localizedString(for: ml.date, relativeTo: now), icon: "person.3.fill", iconColor: .rrPrimary)))
            }
        }

        // Spouse Check-ins
        let spouseDesc = FetchDescriptor<RRSpouseCheckIn>(
            predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(spouseDesc) {
            for sc in results {
                all.append((sc.date, RecentActivity(title: "Spouse Check-in", detail: sc.framework, time: fmt.localizedString(for: sc.date, relativeTo: now), icon: "heart.fill", iconColor: .pink)))
            }
        }

        // Affirmation Sessions
        let affirmationDesc = FetchDescriptor<RRActivity>(
            predicate: #Predicate { $0.activityType == "Affirmation Log" && $0.date >= todayStart && $0.date < tomorrow },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let results = try? context.fetch(affirmationDesc) {
            for a in results {
                let cardsViewed: Int = {
                    if case .int(let v) = a.data.data["cardsViewed"] { return v }
                    return 0
                }()
                let totalCards: Int = {
                    if case .int(let v) = a.data.data["totalCards"] { return v }
                    return 0
                }()
                let durationSeconds: Int = {
                    if case .int(let v) = a.data.data["durationSeconds"] { return v }
                    return 0
                }()
                let detail = "\(cardsViewed)/\(totalCards) cards, \(formatDuration(durationSeconds))"
                all.append((a.date, RecentActivity(title: "Affirmations", detail: detail, time: fmt.localizedString(for: a.date, relativeTo: now), icon: ActivityType.affirmationLog.icon, iconColor: ActivityType.affirmationLog.iconColor)))
            }
        }

        todayActivityLog = all.sorted { $0.date > $1.date }.map(\.item)
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

        if activityType == ActivityType.prayer.rawValue {
            return fetchDates(RRPrayerLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.exercise.rawValue {
            return fetchDates(RRExerciseLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.journal.rawValue {
            return fetchDates(RRJournalEntry.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
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
        if activityType == "lbi" {
            return fetchDates(RRPCIDailyEntry.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.createdAt, context: context)
        }
        if activityType == ActivityType.urgeLog.rawValue {
            return fetchDates(RRUrgeLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.phoneCalls.rawValue {
            return fetchDates(RRPhoneCallLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.meetingsAttended.rawValue {
            return fetchDates(RRMeetingLog.self, predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow }, dateKeyPath: \.date, context: context)
        }
        if activityType == ActivityType.fanos.rawValue || activityType == ActivityType.fitnap.rawValue {
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

        if activityType == "lbi" {
            return hasRecord(
                RRPCIDailyEntry.self,
                predicate: #Predicate { $0.date >= todayStart && $0.date < tomorrow && $0.isMissedDay == false },
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

        if activityType == ActivityType.fanos.rawValue || activityType == ActivityType.fitnap.rawValue {
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
        case 0..<12: period = String(localized: "Good morning")
        case 12..<17: period = String(localized: "Good afternoon")
        default: period = String(localized: "Good evening")
        }
        return "\(period), \(name)"
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }
        return "\(remainingSeconds)s"
    }

    private func activityColor(for activityType: String) -> Color {
        if let at = ActivityType(rawValue: activityType) {
            return at.iconColor
        }
        // Fallback colors for activity types not in the enum
        switch activityType {
        case "devotional": return .rrPrimary
        case "memoryVerseReview": return .rrPrimary
        case "lbi": return .orange
        case "nutrition": return .green
        case "actingInBehaviors": return .blue
        case "voiceJournal": return .purple
        case "bookReading": return .rrPrimary
        case "personCheckInSpouse": return .pink
        default: return .rrSecondary
        }
    }
}
