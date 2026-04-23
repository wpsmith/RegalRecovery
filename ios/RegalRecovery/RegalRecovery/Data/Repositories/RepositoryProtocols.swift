import Foundation

// MARK: - User Repository

protocol UserRepository: Sendable {
    func getUser() async throws -> RRUser?
    func createUser(_ user: RRUser) async throws
    func updateUser(_ user: RRUser) async throws
}

// MARK: - Tracking Repository

protocol TrackingRepository: Sendable {
    func getStreak(for addictionId: UUID) async throws -> RRStreak?
    func getStreaks(for userId: UUID) async throws -> [RRStreak]
    func getMilestones(for addictionId: UUID) async throws -> [RRMilestone]
    func recordRelapse(_ relapse: RRRelapse) async throws
    func createMilestone(_ milestone: RRMilestone) async throws
    func getAddictions(for userId: UUID) async throws -> [RRAddiction]
    func createAddiction(_ addiction: RRAddiction) async throws
    func createStreak(_ streak: RRStreak) async throws
    func getRelapses(for addictionId: UUID) async throws -> [RRRelapse]
}

// MARK: - Activity Repository

protocol ActivityRepository: Sendable {
    func logActivity(_ activity: RRActivity) async throws
    func getActivities(type: String?, from: Date?, to: Date?, limit: Int) async throws -> [RRActivity]
    func getActivitiesForDate(_ date: Date) async throws -> [RRActivity]
}

// MARK: - Check-In Repository

protocol CheckInRepository: Sendable {
    func logCheckIn(_ checkIn: RRCheckIn) async throws
    func getCheckIns(from: Date?, to: Date?, limit: Int) async throws -> [RRCheckIn]
    func getLatestCheckIn() async throws -> RRCheckIn?
}

// MARK: - Journal Repository

protocol JournalRepository: Sendable {
    func saveEntry(_ entry: RRJournalEntry) async throws
    func getEntries(from: Date?, to: Date?, limit: Int) async throws -> [RRJournalEntry]
    func getEntry(id: UUID) async throws -> RRJournalEntry?
    func deleteEntry(id: UUID) async throws
    func purgeExpiredEphemeral() async throws -> Int
}

// MARK: - Emotional Journal Repository

protocol EmotionalJournalRepository: Sendable {
    func saveEntry(_ entry: RREmotionalJournal) async throws
    func getEntries(from: Date?, to: Date?, limit: Int) async throws -> [RREmotionalJournal]
    func getEntry(id: UUID) async throws -> RREmotionalJournal?
}

// MARK: - Time Journal Repository

protocol TimeJournalRepository: Sendable {
    func saveBlock(_ block: RRTimeBlock) async throws
    func getBlocks(for date: Date) async throws -> [RRTimeBlock]
    func deleteBlock(id: UUID) async throws
}

// MARK: - Urge Log Repository

protocol UrgeLogRepository: Sendable {
    func logUrge(_ urge: RRUrgeLog) async throws
    func getUrges(from: Date?, to: Date?, limit: Int) async throws -> [RRUrgeLog]
    func getLatestUrge() async throws -> RRUrgeLog?
}

// MARK: - FASTER Repository

protocol FASTERRepository: Sendable {
    func saveEntry(_ entry: RRFASTEREntry) async throws
    func getEntries(from: Date?, to: Date?, limit: Int) async throws -> [RRFASTEREntry]
    func getLatestEntry() async throws -> RRFASTEREntry?
}

// MARK: - Mood Repository

protocol MoodRepository: Sendable {
    func saveEntry(_ entry: RRMoodEntry) async throws
    func getEntries(from: Date?, to: Date?, limit: Int) async throws -> [RRMoodEntry]
    func getLatestEntry() async throws -> RRMoodEntry?
}

// MARK: - Gratitude Repository

protocol GratitudeRepository: Sendable {
    func saveEntry(_ entry: RRGratitudeEntry) async throws
    func getEntries(from: Date?, to: Date?, limit: Int) async throws -> [RRGratitudeEntry]
}

// MARK: - Prayer Repository

protocol PrayerRepository: Sendable {
    func logPrayer(_ log: RRPrayerLog) async throws
    func getLogs(from: Date?, to: Date?, limit: Int) async throws -> [RRPrayerLog]
}

// MARK: - Exercise Repository

protocol ExerciseRepository: Sendable {
    func logExercise(_ log: RRExerciseLog) async throws
    func getLogs(from: Date?, to: Date?, limit: Int) async throws -> [RRExerciseLog]
}

// MARK: - Phone Call Repository

protocol PhoneCallRepository: Sendable {
    func logCall(_ log: RRPhoneCallLog) async throws
    func getLogs(from: Date?, to: Date?, limit: Int) async throws -> [RRPhoneCallLog]
}

// MARK: - Meeting Repository

protocol MeetingRepository: Sendable {
    func logMeeting(_ log: RRMeetingLog) async throws
    func getLogs(from: Date?, to: Date?, limit: Int) async throws -> [RRMeetingLog]
}

// MARK: - Spouse Check-In Repository

protocol SpouseCheckInRepository: Sendable {
    func saveCheckIn(_ checkIn: RRSpouseCheckIn) async throws
    func getCheckIns(from: Date?, to: Date?, limit: Int) async throws -> [RRSpouseCheckIn]
    func getLatestCheckIn() async throws -> RRSpouseCheckIn?
}

// MARK: - Step Work Repository

protocol StepWorkRepository: Sendable {
    func saveStep(_ step: RRStepWork) async throws
    func getStep(number: Int) async throws -> RRStepWork?
    func getAllSteps() async throws -> [RRStepWork]
    func updateStepStatus(stepNumber: Int, status: String) async throws
}

// MARK: - Goal Repository

protocol GoalRepository: Sendable {
    func saveGoal(_ goal: RRGoal) async throws
    func getGoals(for weekStartDate: Date) async throws -> [RRGoal]
    func getCurrentWeekGoals() async throws -> [RRGoal]
    func updateGoalCompletion(id: UUID, isComplete: Bool) async throws
}

// MARK: - Commitment Repository

protocol CommitmentRepository: Sendable {
    func saveCommitment(_ commitment: RRCommitment) async throws
    func getCommitments(for date: Date) async throws -> [RRCommitment]
    func getLatestCommitment(type: String) async throws -> RRCommitment?
    func markComplete(id: UUID) async throws
}

// MARK: - Support Contact Repository

protocol SupportContactRepository: Sendable {
    func saveContact(_ contact: RRSupportContact) async throws
    func getContacts(for userId: UUID) async throws -> [RRSupportContact]
    func deleteContact(id: UUID) async throws
}

// MARK: - Feature Flag Repository

protocol FeatureFlagRepository: Sendable {
    func getAllFlags() async throws -> [RRFeatureFlag]
    func getFlag(key: String) async throws -> RRFeatureFlag?
    func isEnabled(key: String) async throws -> Bool
    func saveFlag(_ flag: RRFeatureFlag) async throws
    func updateFlag(key: String, enabled: Bool) async throws
}

// MARK: - Affirmation Repository

protocol AffirmationRepository: Sendable {
    func saveFavorite(_ favorite: RRAffirmationFavorite) async throws
    func getFavorites(for userId: UUID) async throws -> [RRAffirmationFavorite]
    func removeFavorite(id: UUID) async throws
}

// MARK: - Devotional Repository

protocol DevotionalRepository: Sendable {
    func saveProgress(_ progress: RRDevotionalProgress) async throws
    func getProgress(for userId: UUID) async throws -> [RRDevotionalProgress]
    func markComplete(day: Int, userId: UUID) async throws
    func getCompletedDayCount(for userId: UUID) async throws -> Int
}

// MARK: - Recovery Plan Repository

protocol RecoveryPlanRepository: Sendable {
    func getActivePlan(userId: UUID) async throws -> RRRecoveryPlan?
    func createPlan(_ plan: RRRecoveryPlan) async throws
    func addPlanItem(_ item: RRDailyPlanItem) async throws
    func updatePlanItem(_ item: RRDailyPlanItem) async throws
    func deletePlanItem(_ item: RRDailyPlanItem) async throws
    func getPlanItems(planId: UUID, dayOfWeek: Int?) async throws -> [RRDailyPlanItem]
}

// MARK: - Daily Score Repository

protocol DailyScoreRepository: Sendable {
    func getScore(userId: UUID, date: Date) async throws -> RRDailyScore?
    func saveScore(_ score: RRDailyScore) async throws
    func getScores(userId: UUID, from: Date, to: Date) async throws -> [RRDailyScore]
}

// MARK: - Sync Queue Repository

protocol SyncQueueRepository: Sendable {
    func enqueue(_ item: RRSyncQueueItem) async throws
    func dequeue(limit: Int) async throws -> [RRSyncQueueItem]
    func markCompleted(id: String) async throws
    func incrementRetry(id: String) async throws
    func pendingCount() async throws -> Int
}

// MARK: - Post-Mortem Repository

protocol PostMortemRepository: Sendable {
    @MainActor func save(_ postMortem: RRPostMortem) throws
    @MainActor func getById(_ id: UUID) throws -> RRPostMortem?
    @MainActor func getByAnalysisId(_ analysisId: String, userId: UUID) throws -> RRPostMortem?
    @MainActor func getByRelapseId(_ relapseId: String, userId: UUID) throws -> RRPostMortem?
    @MainActor func list(
        userId: UUID,
        startDate: Date?,
        endDate: Date?,
        addictionId: String?,
        status: String?,
        eventType: String?,
        limit: Int,
        cursor: Date?
    ) throws -> [RRPostMortem]
    @MainActor func findDrafts(userId: UUID) throws -> [RRPostMortem]
    @MainActor func update(_ postMortem: RRPostMortem) throws
    @MainActor func delete(_ postMortem: RRPostMortem) throws
    @MainActor func getCompletedForInsights(userId: UUID, addictionId: String?) throws -> [RRPostMortem]
    @MainActor func countByStatus(userId: UUID) throws -> (drafts: Int, complete: Int)
}
