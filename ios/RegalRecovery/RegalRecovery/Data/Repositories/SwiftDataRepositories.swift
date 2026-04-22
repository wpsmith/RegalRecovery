import Foundation
import SwiftData

// MARK: - User Repository

@ModelActor
actor SwiftDataUserRepository: UserRepository {
    func getUser() async throws -> RRUser? {
        let descriptor = FetchDescriptor<RRUser>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).first
    }

    func createUser(_ user: RRUser) async throws {
        modelContext.insert(user)
        try modelContext.save()
    }

    func updateUser(_ user: RRUser) async throws {
        user.modifiedAt = Date()
        try modelContext.save()
    }
}

// MARK: - Tracking Repository

@ModelActor
actor SwiftDataTrackingRepository: TrackingRepository {
    func getStreak(for addictionId: UUID) async throws -> RRStreak? {
        let descriptor = FetchDescriptor<RRStreak>(
            predicate: #Predicate { $0.addictionId == addictionId }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getStreaks(for userId: UUID) async throws -> [RRStreak] {
        let addictions = try await getAddictions(for: userId)
        let addictionIds = addictions.map(\.id)
        var result: [RRStreak] = []
        for addictionId in addictionIds {
            let descriptor = FetchDescriptor<RRStreak>(
                predicate: #Predicate { $0.addictionId == addictionId }
            )
            result.append(contentsOf: try modelContext.fetch(descriptor))
        }
        return result
    }

    func getMilestones(for addictionId: UUID) async throws -> [RRMilestone] {
        let descriptor = FetchDescriptor<RRMilestone>(
            predicate: #Predicate { $0.addictionId == addictionId },
            sortBy: [SortDescriptor(\.days)]
        )
        return try modelContext.fetch(descriptor)
    }

    func recordRelapse(_ relapse: RRRelapse) async throws {
        modelContext.insert(relapse)
        try modelContext.save()
    }

    func createMilestone(_ milestone: RRMilestone) async throws {
        modelContext.insert(milestone)
        try modelContext.save()
    }

    func getAddictions(for userId: UUID) async throws -> [RRAddiction] {
        let descriptor = FetchDescriptor<RRAddiction>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func createAddiction(_ addiction: RRAddiction) async throws {
        modelContext.insert(addiction)
        try modelContext.save()
    }

    func createStreak(_ streak: RRStreak) async throws {
        modelContext.insert(streak)
        try modelContext.save()
    }

    func getRelapses(for addictionId: UUID) async throws -> [RRRelapse] {
        let descriptor = FetchDescriptor<RRRelapse>(
            predicate: #Predicate { $0.addictionId == addictionId },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Activity Repository

@ModelActor
actor SwiftDataActivityRepository: ActivityRepository {
    func logActivity(_ activity: RRActivity) async throws {
        modelContext.insert(activity)
        try modelContext.save()
    }

    func getActivities(type: String?, from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRActivity] {
        var descriptor = FetchDescriptor<RRActivity>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let type, let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.activityType == type && $0.date >= startDate && $0.date <= endDate
            }
        } else if let type {
            descriptor.predicate = #Predicate { $0.activityType == type }
        } else if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getActivitiesForDate(_ date: Date) async throws -> [RRActivity] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let descriptor = FetchDescriptor<RRActivity>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Check-In Repository

@ModelActor
actor SwiftDataCheckInRepository: CheckInRepository {
    func logCheckIn(_ checkIn: RRCheckIn) async throws {
        modelContext.insert(checkIn)
        try modelContext.save()
    }

    func getCheckIns(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRCheckIn] {
        var descriptor = FetchDescriptor<RRCheckIn>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getLatestCheckIn() async throws -> RRCheckIn? {
        var descriptor = FetchDescriptor<RRCheckIn>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Journal Repository

@ModelActor
actor SwiftDataJournalRepository: JournalRepository {
    func saveEntry(_ entry: RRJournalEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func getEntries(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRJournalEntry] {
        var descriptor = FetchDescriptor<RRJournalEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getEntry(id: UUID) async throws -> RRJournalEntry? {
        let descriptor = FetchDescriptor<RRJournalEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func deleteEntry(id: UUID) async throws {
        if let entry = try await getEntry(id: id) {
            modelContext.delete(entry)
            try modelContext.save()
        }
    }

    func purgeExpiredEphemeral() async throws -> Int {
        let now = Date()
        let descriptor = FetchDescriptor<RRJournalEntry>(
            predicate: #Predicate {
                $0.isEphemeral == true && $0.ephemeralExpiresAt != nil && $0.ephemeralExpiresAt! <= now
            }
        )
        let expired = try modelContext.fetch(descriptor)
        let count = expired.count
        for entry in expired {
            modelContext.delete(entry)
        }
        if count > 0 {
            try modelContext.save()
        }
        return count
    }
}

// MARK: - Emotional Journal Repository

@ModelActor
actor SwiftDataEmotionalJournalRepository: EmotionalJournalRepository {
    func saveEntry(_ entry: RREmotionalJournal) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func getEntries(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RREmotionalJournal] {
        var descriptor = FetchDescriptor<RREmotionalJournal>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getEntry(id: UUID) async throws -> RREmotionalJournal? {
        let descriptor = FetchDescriptor<RREmotionalJournal>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Time Journal Repository

@ModelActor
actor SwiftDataTimeJournalRepository: TimeJournalRepository {
    func saveBlock(_ block: RRTimeBlock) async throws {
        modelContext.insert(block)
        try modelContext.save()
    }

    func getBlocks(for date: Date) async throws -> [RRTimeBlock] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let descriptor = FetchDescriptor<RRTimeBlock>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.startHour), SortDescriptor(\.startMinute)]
        )
        return try modelContext.fetch(descriptor)
    }

    func deleteBlock(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRTimeBlock>(
            predicate: #Predicate { $0.id == id }
        )
        if let block = try modelContext.fetch(descriptor).first {
            modelContext.delete(block)
            try modelContext.save()
        }
    }
}

// MARK: - Urge Log Repository

@ModelActor
actor SwiftDataUrgeLogRepository: UrgeLogRepository {
    func logUrge(_ urge: RRUrgeLog) async throws {
        modelContext.insert(urge)
        try modelContext.save()
    }

    func getUrges(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRUrgeLog] {
        var descriptor = FetchDescriptor<RRUrgeLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getLatestUrge() async throws -> RRUrgeLog? {
        var descriptor = FetchDescriptor<RRUrgeLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - FASTER Repository

@ModelActor
actor SwiftDataFASTERRepository: FASTERRepository {
    func saveEntry(_ entry: RRFASTEREntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func getEntries(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRFASTEREntry] {
        var descriptor = FetchDescriptor<RRFASTEREntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getLatestEntry() async throws -> RRFASTEREntry? {
        var descriptor = FetchDescriptor<RRFASTEREntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Mood Repository

@ModelActor
actor SwiftDataMoodRepository: MoodRepository {
    func saveEntry(_ entry: RRMoodEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func getEntries(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRMoodEntry] {
        var descriptor = FetchDescriptor<RRMoodEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getLatestEntry() async throws -> RRMoodEntry? {
        var descriptor = FetchDescriptor<RRMoodEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Gratitude Repository

@ModelActor
actor SwiftDataGratitudeRepository: GratitudeRepository {
    func saveEntry(_ entry: RRGratitudeEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func getEntries(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRGratitudeEntry] {
        var descriptor = FetchDescriptor<RRGratitudeEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Prayer Repository

@ModelActor
actor SwiftDataPrayerRepository: PrayerRepository {
    func logPrayer(_ log: RRPrayerLog) async throws {
        modelContext.insert(log)
        try modelContext.save()
    }

    func getLogs(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRPrayerLog] {
        var descriptor = FetchDescriptor<RRPrayerLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Exercise Repository

@ModelActor
actor SwiftDataExerciseRepository: ExerciseRepository {
    func logExercise(_ log: RRExerciseLog) async throws {
        modelContext.insert(log)
        try modelContext.save()
    }

    func getLogs(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRExerciseLog] {
        var descriptor = FetchDescriptor<RRExerciseLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Phone Call Repository

@ModelActor
actor SwiftDataPhoneCallRepository: PhoneCallRepository {
    func logCall(_ log: RRPhoneCallLog) async throws {
        modelContext.insert(log)
        try modelContext.save()
    }

    func getLogs(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRPhoneCallLog] {
        var descriptor = FetchDescriptor<RRPhoneCallLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Meeting Repository

@ModelActor
actor SwiftDataMeetingRepository: MeetingRepository {
    func logMeeting(_ log: RRMeetingLog) async throws {
        modelContext.insert(log)
        try modelContext.save()
    }

    func getLogs(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRMeetingLog] {
        var descriptor = FetchDescriptor<RRMeetingLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Spouse Check-In Repository

@ModelActor
actor SwiftDataSpouseCheckInRepository: SpouseCheckInRepository {
    func saveCheckIn(_ checkIn: RRSpouseCheckIn) async throws {
        modelContext.insert(checkIn)
        try modelContext.save()
    }

    func getCheckIns(from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRSpouseCheckIn] {
        var descriptor = FetchDescriptor<RRSpouseCheckIn>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        if let startDate, let endDate {
            descriptor.predicate = #Predicate {
                $0.date >= startDate && $0.date <= endDate
            }
        }

        return try modelContext.fetch(descriptor)
    }

    func getLatestCheckIn() async throws -> RRSpouseCheckIn? {
        var descriptor = FetchDescriptor<RRSpouseCheckIn>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}

// MARK: - Step Work Repository

@ModelActor
actor SwiftDataStepWorkRepository: StepWorkRepository {
    func saveStep(_ step: RRStepWork) async throws {
        modelContext.insert(step)
        try modelContext.save()
    }

    func getStep(number: Int) async throws -> RRStepWork? {
        let descriptor = FetchDescriptor<RRStepWork>(
            predicate: #Predicate { $0.stepNumber == number }
        )
        return try modelContext.fetch(descriptor).first
    }

    func getAllSteps() async throws -> [RRStepWork] {
        let descriptor = FetchDescriptor<RRStepWork>(
            sortBy: [SortDescriptor(\.stepNumber)]
        )
        return try modelContext.fetch(descriptor)
    }

    func updateStepStatus(stepNumber: Int, status: String) async throws {
        if let step = try await getStep(number: stepNumber) {
            step.status = status
            step.modifiedAt = Date()
            try modelContext.save()
        }
    }
}

// MARK: - Goal Repository

@ModelActor
actor SwiftDataGoalRepository: GoalRepository {
    func saveGoal(_ goal: RRGoal) async throws {
        modelContext.insert(goal)
        try modelContext.save()
    }

    func getGoals(for weekStartDate: Date) async throws -> [RRGoal] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: weekStartDate)
        guard let end = calendar.date(byAdding: .day, value: 7, to: start) else { return [] }

        let descriptor = FetchDescriptor<RRGoal>(
            predicate: #Predicate {
                $0.weekStartDate >= start && $0.weekStartDate < end
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getCurrentWeekGoals() async throws -> [RRGoal] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let weekStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) else { return [] }
        return try await getGoals(for: weekStart)
    }

    func updateGoalCompletion(id: UUID, isComplete: Bool) async throws {
        let descriptor = FetchDescriptor<RRGoal>(
            predicate: #Predicate { $0.id == id }
        )
        if let goal = try modelContext.fetch(descriptor).first {
            goal.isComplete = isComplete
            goal.modifiedAt = Date()
            try modelContext.save()
        }
    }
}

// MARK: - Commitment Repository

@ModelActor
actor SwiftDataCommitmentRepository: CommitmentRepository {
    func saveCommitment(_ commitment: RRCommitment) async throws {
        modelContext.insert(commitment)
        try modelContext.save()
    }

    func getCommitments(for date: Date) async throws -> [RRCommitment] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let descriptor = FetchDescriptor<RRCommitment>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getLatestCommitment(type: String) async throws -> RRCommitment? {
        var descriptor = FetchDescriptor<RRCommitment>(
            predicate: #Predicate { $0.type == type },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func markComplete(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRCommitment>(
            predicate: #Predicate { $0.id == id }
        )
        if let commitment = try modelContext.fetch(descriptor).first {
            commitment.completedAt = Date()
            commitment.modifiedAt = Date()
            try modelContext.save()
        }
    }
}

// MARK: - Support Contact Repository

@ModelActor
actor SwiftDataSupportContactRepository: SupportContactRepository {
    func saveContact(_ contact: RRSupportContact) async throws {
        modelContext.insert(contact)
        try modelContext.save()
    }

    func getContacts(for userId: UUID) async throws -> [RRSupportContact] {
        let descriptor = FetchDescriptor<RRSupportContact>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.linkedDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    func deleteContact(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRSupportContact>(
            predicate: #Predicate { $0.id == id }
        )
        if let contact = try modelContext.fetch(descriptor).first {
            modelContext.delete(contact)
            try modelContext.save()
        }
    }

}

// MARK: - Feature Flag Repository

@ModelActor
actor SwiftDataFeatureFlagRepository: FeatureFlagRepository {
    func getAllFlags() async throws -> [RRFeatureFlag] {
        let descriptor = FetchDescriptor<RRFeatureFlag>(
            sortBy: [SortDescriptor(\.key)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getFlag(key: String) async throws -> RRFeatureFlag? {
        let descriptor = FetchDescriptor<RRFeatureFlag>(
            predicate: #Predicate { $0.key == key }
        )
        return try modelContext.fetch(descriptor).first
    }

    func isEnabled(key: String) async throws -> Bool {
        let flag = try await getFlag(key: key)
        return flag?.enabled ?? false
    }

    func saveFlag(_ flag: RRFeatureFlag) async throws {
        modelContext.insert(flag)
        try modelContext.save()
    }

    func updateFlag(key: String, enabled: Bool) async throws {
        if let flag = try await getFlag(key: key) {
            flag.enabled = enabled
            flag.modifiedAt = Date()
            try modelContext.save()
        }
    }
}

// MARK: - Affirmation Repository

@ModelActor
actor SwiftDataAffirmationRepository: AffirmationRepository {
    func saveFavorite(_ favorite: RRAffirmationFavorite) async throws {
        modelContext.insert(favorite)
        try modelContext.save()
    }

    func getFavorites(for userId: UUID) async throws -> [RRAffirmationFavorite] {
        let descriptor = FetchDescriptor<RRAffirmationFavorite>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor)
    }

    func removeFavorite(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRAffirmationFavorite>(
            predicate: #Predicate { $0.id == id }
        )
        if let favorite = try modelContext.fetch(descriptor).first {
            modelContext.delete(favorite)
            try modelContext.save()
        }
    }
}

// MARK: - Devotional Repository

@ModelActor
actor SwiftDataDevotionalRepository: DevotionalRepository {
    func saveProgress(_ progress: RRDevotionalProgress) async throws {
        modelContext.insert(progress)
        try modelContext.save()
    }

    func getProgress(for userId: UUID) async throws -> [RRDevotionalProgress] {
        let descriptor = FetchDescriptor<RRDevotionalProgress>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.day)]
        )
        return try modelContext.fetch(descriptor)
    }

    func markComplete(day: Int, userId: UUID) async throws {
        let descriptor = FetchDescriptor<RRDevotionalProgress>(
            predicate: #Predicate { $0.userId == userId && $0.day == day }
        )
        if let progress = try modelContext.fetch(descriptor).first {
            progress.completedAt = Date()
            progress.modifiedAt = Date()
        } else {
            let progress = RRDevotionalProgress(userId: userId, day: day, completedAt: Date())
            modelContext.insert(progress)
        }
        try modelContext.save()
    }

    func getCompletedDayCount(for userId: UUID) async throws -> Int {
        let descriptor = FetchDescriptor<RRDevotionalProgress>(
            predicate: #Predicate { $0.userId == userId && $0.completedAt != nil }
        )
        return try modelContext.fetchCount(descriptor)
    }
}

// MARK: - Recovery Plan Repository

@ModelActor
actor SwiftDataRecoveryPlanRepository: RecoveryPlanRepository {
    func getActivePlan(userId: UUID) async throws -> RRRecoveryPlan? {
        let descriptor = FetchDescriptor<RRRecoveryPlan>(
            predicate: #Predicate { $0.userId == userId && $0.isActive == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    func createPlan(_ plan: RRRecoveryPlan) async throws {
        modelContext.insert(plan)
        try modelContext.save()
    }

    func addPlanItem(_ item: RRDailyPlanItem) async throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    func updatePlanItem(_ item: RRDailyPlanItem) async throws {
        item.modifiedAt = Date()
        try modelContext.save()
    }

    func deletePlanItem(_ item: RRDailyPlanItem) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    func getPlanItems(planId: UUID, dayOfWeek: Int?) async throws -> [RRDailyPlanItem] {
        let descriptor = FetchDescriptor<RRDailyPlanItem>(
            predicate: #Predicate { $0.planId == planId && $0.isEnabled == true },
            sortBy: [SortDescriptor(\.scheduledHour), SortDescriptor(\.scheduledMinute), SortDescriptor(\.instanceIndex)]
        )
        let allItems = try modelContext.fetch(descriptor)

        guard let dayOfWeek else { return allItems }

        return allItems.filter { item in
            item.daysOfWeek.isEmpty || item.daysOfWeek.contains(dayOfWeek)
        }
    }
}

// MARK: - Daily Score Repository

@ModelActor
actor SwiftDataDailyScoreRepository: DailyScoreRepository {
    func getScore(userId: UUID, date: Date) async throws -> RRDailyScore? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }

        let descriptor = FetchDescriptor<RRDailyScore>(
            predicate: #Predicate { $0.userId == userId && $0.date >= start && $0.date < end }
        )
        return try modelContext.fetch(descriptor).first
    }

    func saveScore(_ score: RRDailyScore) async throws {
        modelContext.insert(score)
        try modelContext.save()
    }

    func getScores(userId: UUID, from startDate: Date, to endDate: Date) async throws -> [RRDailyScore] {
        let descriptor = FetchDescriptor<RRDailyScore>(
            predicate: #Predicate { $0.userId == userId && $0.date >= startDate && $0.date <= endDate },
            sortBy: [SortDescriptor(\.date)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Sync Queue Repository

@ModelActor
actor SwiftDataSyncQueueRepository: SyncQueueRepository {
    func enqueue(_ item: RRSyncQueueItem) async throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    func dequeue(limit: Int) async throws -> [RRSyncQueueItem] {
        var descriptor = FetchDescriptor<RRSyncQueueItem>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func markCompleted(id: String) async throws {
        let descriptor = FetchDescriptor<RRSyncQueueItem>(
            predicate: #Predicate { $0.id == id }
        )
        if let item = try modelContext.fetch(descriptor).first {
            modelContext.delete(item)
            try modelContext.save()
        }
    }

    func incrementRetry(id: String) async throws {
        let descriptor = FetchDescriptor<RRSyncQueueItem>(
            predicate: #Predicate { $0.id == id }
        )
        if let item = try modelContext.fetch(descriptor).first {
            item.retryCount += 1
            item.modifiedAt = Date()
            try modelContext.save()
        }
    }

    func pendingCount() async throws -> Int {
        let descriptor = FetchDescriptor<RRSyncQueueItem>()
        return try modelContext.fetchCount(descriptor)
    }
}

// MARK: - Trigger Definition Repository

@ModelActor
actor SwiftDataTriggerDefinitionRepository: TriggerDefinitionRepository {
    func getAll(userId: UUID) async throws -> [RRTriggerDefinition] {
        let descriptor = FetchDescriptor<RRTriggerDefinition>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [
                SortDescriptor(\.useCount, order: .reverse),
                SortDescriptor(\.label)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func getByCategory(userId: UUID, category: TriggerCategory) async throws -> [RRTriggerDefinition] {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<RRTriggerDefinition>(
            predicate: #Predicate { $0.userId == userId && $0.categoryRaw == categoryRaw },
            sortBy: [
                SortDescriptor(\.useCount, order: .reverse),
                SortDescriptor(\.label)
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func getTopByUsage(userId: UUID, limit: Int) async throws -> [RRTriggerDefinition] {
        var descriptor = FetchDescriptor<RRTriggerDefinition>(
            predicate: #Predicate { $0.userId == userId && $0.useCount > 0 },
            sortBy: [SortDescriptor(\.useCount, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func save(_ definition: RRTriggerDefinition) async throws {
        modelContext.insert(definition)
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRTriggerDefinition>(
            predicate: #Predicate { $0.id == id }
        )
        if let definition = try modelContext.fetch(descriptor).first {
            modelContext.delete(definition)
            try modelContext.save()
        }
    }

    func incrementUseCount(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRTriggerDefinition>(
            predicate: #Predicate { $0.id == id }
        )
        if let definition = try modelContext.fetch(descriptor).first {
            definition.useCount += 1
            definition.lastUsed = Date()
            definition.modifiedAt = Date()
            try modelContext.save()
        }
    }

    func search(userId: UUID, query: String) async throws -> [RRTriggerDefinition] {
        let allDefinitions = try await getAll(userId: userId)
        let lowercasedQuery = query.lowercased()
        return allDefinitions.filter { $0.label.lowercased().contains(lowercasedQuery) }
    }

    func seedDefaults(userId: UUID) async throws {
        // Check if any non-custom triggers already exist for this user
        let descriptor = FetchDescriptor<RRTriggerDefinition>(
            predicate: #Predicate { $0.userId == userId && $0.isCustom == false }
        )
        let existingCount = try modelContext.fetchCount(descriptor)

        guard existingCount == 0 else { return }

        // Insert all default triggers
        for seed in TriggerSeedData.allTriggers {
            let definition = RRTriggerDefinition(
                userId: userId,
                label: seed.label,
                category: seed.category,
                isCustom: false
            )
            modelContext.insert(definition)
        }
        try modelContext.save()
    }
}

// MARK: - Trigger Log Repository

@ModelActor
actor SwiftDataTriggerLogRepository: TriggerLogRepository {
    func save(_ entry: RRTriggerLogEntry) async throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    func getEntries(userId: UUID, from startDate: Date?, to endDate: Date?, limit: Int) async throws -> [RRTriggerLogEntry] {
        var descriptor: FetchDescriptor<RRTriggerLogEntry>

        if let startDate, let endDate {
            descriptor = FetchDescriptor<RRTriggerLogEntry>(
                predicate: #Predicate { $0.userId == userId && $0.timestamp >= startDate && $0.timestamp <= endDate },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        } else {
            descriptor = FetchDescriptor<RRTriggerLogEntry>(
                predicate: #Predicate { $0.userId == userId },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
        }

        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func getEntry(id: UUID) async throws -> RRTriggerLogEntry? {
        let descriptor = FetchDescriptor<RRTriggerLogEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func update(_ entry: RRTriggerLogEntry) async throws {
        entry.modifiedAt = Date()
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRTriggerLogEntry>(
            predicate: #Predicate { $0.id == id }
        )
        if let entry = try modelContext.fetch(descriptor).first {
            modelContext.delete(entry)
            try modelContext.save()
        }
    }

    func deleteAll(userId: UUID) async throws {
        let descriptor = FetchDescriptor<RRTriggerLogEntry>(
            predicate: #Predicate { $0.userId == userId }
        )
        let entries = try modelContext.fetch(descriptor)
        for entry in entries {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }

    func getEntriesForDate(userId: UUID, date: Date) async throws -> [RRTriggerLogEntry] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }

        let descriptor = FetchDescriptor<RRTriggerLogEntry>(
            predicate: #Predicate { $0.userId == userId && $0.timestamp >= start && $0.timestamp < end },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func countForDay(userId: UUID, date: Date) async throws -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }

        let descriptor = FetchDescriptor<RRTriggerLogEntry>(
            predicate: #Predicate { $0.userId == userId && $0.timestamp >= start && $0.timestamp < end }
        )
        return try modelContext.fetchCount(descriptor)
    }
}

// MARK: - Coping Strategy Repository

@ModelActor
actor SwiftDataCopingStrategyRepository: CopingStrategyRepository {
    func getAll(userId: UUID) async throws -> [RRCopingStrategy] {
        let descriptor = FetchDescriptor<RRCopingStrategy>(
            predicate: #Predicate { $0.userId == userId },
            sortBy: [SortDescriptor(\.label)]
        )
        return try modelContext.fetch(descriptor)
    }

    func getByCategory(userId: UUID, category: TriggerCategory) async throws -> [RRCopingStrategy] {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<RRCopingStrategy>(
            predicate: #Predicate { $0.userId == userId && $0.categoryRaw == categoryRaw },
            sortBy: [SortDescriptor(\.effectivenessSum, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save(_ strategy: RRCopingStrategy) async throws {
        modelContext.insert(strategy)
        try modelContext.save()
    }

    func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<RRCopingStrategy>(
            predicate: #Predicate { $0.id == id }
        )
        if let strategy = try modelContext.fetch(descriptor).first {
            modelContext.delete(strategy)
            try modelContext.save()
        }
    }

    func recordEffectiveness(id: UUID, rating: Int) async throws {
        let descriptor = FetchDescriptor<RRCopingStrategy>(
            predicate: #Predicate { $0.id == id }
        )
        if let strategy = try modelContext.fetch(descriptor).first {
            strategy.effectivenessSum += rating
            strategy.effectivenessCount += 1
            try modelContext.save()
        }
    }

    func seedDefaults(userId: UUID) async throws {
        // Check if any system strategies already exist for this user
        let descriptor = FetchDescriptor<RRCopingStrategy>(
            predicate: #Predicate { $0.userId == userId && $0.isSystem == true }
        )
        let existingCount = try modelContext.fetchCount(descriptor)

        guard existingCount == 0 else { return }

        // Insert all system coping strategies
        for seed in TriggerSeedData.systemCopingStrategies {
            let strategy = RRCopingStrategy(
                userId: userId,
                label: seed.label,
                strategyDescription: seed.description,
                category: seed.category,
                isSystem: true
            )
            modelContext.insert(strategy)
        }
        try modelContext.save()
    }
}
