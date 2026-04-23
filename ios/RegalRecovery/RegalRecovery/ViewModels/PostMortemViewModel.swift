import Foundation
import SwiftData
import SwiftUI
import OSLog

// MARK: - Local Entry Types

struct TriggerEntry: Identifiable, Equatable {
    let id = UUID()
    var category = ""   // emotional, environmental, etc.
    var surface = ""    // Surface-level trigger
    var underlying = "" // Underlying emotion
    var coreWound = ""  // Deepest layer
}

struct MissedHelpEntry: Identifiable, Equatable {
    let id = UUID()
    var description = ""
    var reason = ""
}

struct DecisionPointEntry: Identifiable, Equatable {
    let id = UUID()
    var timeOfDay = ""
    var description = ""
    var couldHaveDone = ""
    var insteadDid = ""
}

struct ActionItemEntry: Identifiable, Equatable {
    let id = UUID()
    var timelinePoint = ""
    var action = ""
    var category = ""  // spiritual, relational, emotional, physical, practical
    var convertedToCommitmentId: String?
    var convertedToGoalId: String?
}

struct FreeFormEntry: Identifiable, Equatable {
    let id = UUID()
    var time = ""
    var text = ""
}

struct ShareRecipient: Identifiable, Equatable {
    let id = UUID()
    var contactId = ""
    var shareType = "full"  // "full" or "summary"
}

// MARK: - New Data Loading Types

struct DayActivityRecord: Identifiable {
    let id = UUID()
    let activityType: String
    let title: String
    let icon: String
    let iconColor: Color
    let wasCompleted: Bool
}

struct UserTriggerItem: Identifiable {
    let id: UUID
    let label: String
    let category: String
    var isSelected: Bool
}

struct FASTERHistoryEntry: Identifiable {
    let id: UUID
    let date: Date
    let stage: Int  // FASTERStage rawValue
    let moodScore: Int?
    let stageName: String
    let stageColor: Color
}

struct RecommendedActivity: Identifiable {
    let id = UUID()
    let activityType: String
    let title: String
    let icon: String
    let iconColor: Color
    let reason: String  // Why this is recommended
}

// MARK: - PostMortemViewModel

@Observable
class PostMortemViewModel {

    // MARK: - Flow State

    enum FlowStep: Int, CaseIterable {
        case actingOut       // Step 1: Event type, when, which addiction
        case describeEvent   // Step 2: Describe what happened, duration
        case throughoutTheDay // Step 3: Work backwards 24hrs with Time Journal + activity data
        case dayBefore       // Step 4: Show activity history (done vs not done), ask what's missing
        case buildUp         // Step 5: Build-up, decision points, missed help
        case triggers        // Step 6: Trigger identification, leverage My Triggers
        case immediatelyAfter // Step 7: Feelings, what did next
        case fasterHistory   // Step 8: 4-week FASTER graph (if using FASTER)
        case actionPlan      // Step 9: Missed activities, recommendations, Quick Action-style tiles
    }

    var currentStep: FlowStep = .actingOut
    var isLoading = false
    var error: String?
    var showCompletionMessage = false
    var completionMessage: String?

    // MARK: - Draft State

    var analysisId: String?
    var isDraft = true
    var existingDraftId: UUID?  // If resuming a draft

    // MARK: - Step 1: Acting Out / Near Miss

    var eventType: String = "relapse"  // "relapse", "near-miss", "combined"
    var relapseId: String?
    var addictionId: String?
    var timestamp = Date()
    var actingOutDescription = ""
    var actingOutDurationMinutes: Int?

    // MARK: - Step 2: Throughout the Day (work backwards)

    var timeBlocksForDay: [RRTimeBlock] = []  // Loaded from SwiftData
    var activitiesForDay: [RRActivity] = []   // Loaded from SwiftData
    var throughoutDayText = ""  // User's "What happened before that?" reflection
    var freeFormEntries: [FreeFormEntry] = []  // User-added timeline entries

    // MARK: - Step 3: Day Before

    var dayBeforeActivities: [DayActivityRecord] = []  // What was done/not done
    var dayBeforeText = ""
    var dayBeforeMoodRating: Int = 5
    var dayBeforeUnresolvedConflicts = ""

    // MARK: - Step 4: Build-Up

    var firstNoticed = ""
    var triggers: [TriggerEntry] = []
    var responseToWarnings = ""
    var missedHelpOpportunities: [MissedHelpEntry] = []
    var decisionPoints: [DecisionPointEntry] = []

    // MARK: - Step 5: Triggers

    var userTriggers: [UserTriggerItem] = []  // Loaded from My Triggers
    var triggerSummary: [String] = []  // Categories: emotional, environmental, relational, physical, cognitive, spiritual, situational
    var triggerDetails: [TriggerEntry] = []

    // MARK: - Step 6: Immediately After

    var feelings: [String] = []
    var feelingsWheelSelections: [String] = []
    var whatDidNext = ""
    var reachedOut = false
    var reachedOutTo: String?
    var wishDoneDifferently = ""

    // MARK: - Step 7: FASTER History

    var fasterHistory: [FASTERHistoryEntry] = []
    var hasFasterData: Bool { !fasterHistory.isEmpty }
    var selectedFasterEntry: FASTERHistoryEntry?  // For chart tap detail

    // MARK: - Step 8: Action Plan

    var missedActivities: [DayActivityRecord] = []      // Activities that weren't done on event day
    var recommendedActivities: [RecommendedActivity] = [] // Activities not in plan
    var selectedRecommendations: Set<String> = []         // Activity types user selected to add
    var actionItems: [ActionItemEntry] = []

    // MARK: - Sharing

    var sharingEnabled = false
    var shareEntries: [ShareRecipient] = []

    // MARK: - Insights (computed from completed post-mortems)

    var insights: PostMortemInsightsData?
    var insightsLoading = false

    // MARK: - Constants

    static let allSectionNames = ["actingOut", "throughoutTheDay", "dayBefore", "buildUp", "triggers", "immediatelyAfter"]
    static let triggerCategories = ["emotional", "physical", "environmental", "relational", "cognitive", "spiritual", "situational"]
    static let actionCategories = ["spiritual", "relational", "emotional", "physical", "practical"]

    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "PostMortemViewModel")

    // MARK: - Navigation

    var progress: Double {
        let totalSteps = Double(FlowStep.allCases.count)
        let currentStepIndex = Double(currentStep.rawValue)
        return currentStepIndex / totalSteps
    }

    func canAdvance() -> Bool {
        switch currentStep {
        case .actingOut:
            return !eventType.isEmpty

        case .describeEvent:
            return !actingOutDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .throughoutTheDay:
            return true  // Optional step, can advance even if empty

        case .dayBefore:
            return !dayBeforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .buildUp:
            return !firstNoticed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .triggers:
            return true  // Optional step

        case .immediatelyAfter:
            return !whatDidNext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .fasterHistory:
            return true  // Optional step, auto-advance if no data

        case .actionPlan:
            return canComplete
        }
    }

    func advance() {
        guard canAdvance() else { return }

        // Auto-skip FASTER history if no data
        if currentStep == .immediatelyAfter && !hasFasterData {
            if let nextStep = FlowStep(rawValue: FlowStep.actionPlan.rawValue) {
                currentStep = nextStep
            }
        } else if let nextStep = FlowStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }

    func goBack() {
        // Auto-skip FASTER history going backwards if no data
        if currentStep == .actionPlan && !hasFasterData {
            if let prevStep = FlowStep(rawValue: FlowStep.immediatelyAfter.rawValue) {
                currentStep = prevStep
            }
        } else if let prevStep = FlowStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prevStep
        }
    }

    // MARK: - Section Completion

    var completedSections: [String] {
        var sections: [String] = []

        if !actingOutDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("actingOut")
        }
        if !throughoutDayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !timeBlocksForDay.isEmpty || !activitiesForDay.isEmpty {
            sections.append("throughoutTheDay")
        }
        if !dayBeforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("dayBefore")
        }
        if !firstNoticed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("buildUp")
        }
        if !triggerSummary.isEmpty || !triggerDetails.isEmpty {
            sections.append("triggers")
        }
        if !whatDidNext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("immediatelyAfter")
        }

        return sections
    }

    var remainingSections: [String] {
        Self.allSectionNames.filter { !completedSections.contains($0) }
    }

    func isSectionComplete(_ name: String) -> Bool {
        completedSections.contains(name)
    }

    // MARK: - Validation

    func validateForCompletion() -> [String] {
        var errors: [String] = []

        // Acting out description required
        if actingOutDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Acting out description is required")
        }

        // At least 1 action item required (custom or selected recommendation)
        if actionItems.isEmpty && selectedRecommendations.isEmpty {
            errors.append("At least one action plan item is required")
        }

        // Mood ratings must be 1-10
        if dayBeforeMoodRating < 1 || dayBeforeMoodRating > 10 {
            errors.append("Day before mood rating must be between 1 and 10")
        }

        // Trigger categories must be valid
        for category in triggerSummary {
            if !Self.triggerCategories.contains(category) {
                errors.append("Invalid trigger category: \(category)")
            }
        }

        // Action categories must be valid
        for item in actionItems {
            if !Self.actionCategories.contains(item.category) {
                errors.append("Invalid action category: \(item.category)")
            }
        }

        return errors
    }

    var canComplete: Bool {
        validateForCompletion().isEmpty
    }

    // MARK: - Data Loading Methods

    @MainActor
    func loadDayContext(context: ModelContext, userId: UUID, date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        // Load time blocks for the day
        let timeBlockDescriptor = FetchDescriptor<RRTimeBlock>(
            predicate: #Predicate { block in
                block.userId == userId && block.date >= startOfDay && block.date < endOfDay
            },
            sortBy: [SortDescriptor(\.startHour), SortDescriptor(\.startMinute)]
        )
        timeBlocksForDay = (try? context.fetch(timeBlockDescriptor)) ?? []

        // Load activities for the day
        let activityDescriptor = FetchDescriptor<RRActivity>(
            predicate: #Predicate { activity in
                activity.userId == userId && activity.date >= startOfDay && activity.date < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        activitiesForDay = (try? context.fetch(activityDescriptor)) ?? []
    }

    @MainActor
    func loadDayBeforeContext(context: ModelContext, userId: UUID, date: Date) {
        let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        let startOfDayBefore = Calendar.current.startOfDay(for: dayBefore)
        let endOfDayBefore = Calendar.current.date(byAdding: .day, value: 1, to: startOfDayBefore)!

        // Load user's recovery plan
        let planDescriptor = FetchDescriptor<RRRecoveryPlan>(
            predicate: #Predicate { plan in
                plan.userId == userId && plan.isActive
            }
        )
        guard let plan = try? context.fetch(planDescriptor).first,
              let planItems = plan.items else {
            dayBeforeActivities = []
            return
        }

        // For each planned activity, check if it was completed
        var records: [DayActivityRecord] = []

        for item in planItems where item.isEnabled {
            // Find matching DailyEligibleActivity for display info
            guard let eligibleActivity = DailyEligibleActivity.all.first(where: { $0.activityType == item.activityType }) else {
                continue
            }

            // Check if activity was completed day before
            let itemType = item.activityType
            let activityDescriptor = FetchDescriptor<RRActivity>(
                predicate: #Predicate { activity in
                    activity.userId == userId &&
                    activity.activityType == itemType &&
                    activity.date >= startOfDayBefore &&
                    activity.date < endOfDayBefore
                }
            )
            let wasCompleted = (try? context.fetch(activityDescriptor).first) != nil

            records.append(DayActivityRecord(
                activityType: item.activityType,
                title: eligibleActivity.displayName,
                icon: eligibleActivity.icon,
                iconColor: eligibleActivity.section.iconColor,
                wasCompleted: wasCompleted
            ))
        }

        dayBeforeActivities = records.sorted { !$0.wasCompleted && $1.wasCompleted }
    }

    @MainActor
    func loadUserTriggers(context: ModelContext, userId: UUID) {
        let descriptor = FetchDescriptor<RRTriggerDefinition>(
            predicate: #Predicate { trigger in
                trigger.userId == userId
            },
            sortBy: [SortDescriptor(\.useCount, order: .reverse), SortDescriptor(\.label)]
        )

        let definitions = (try? context.fetch(descriptor)) ?? []
        userTriggers = definitions.map { def in
            UserTriggerItem(
                id: def.id,
                label: def.label,
                category: def.category.displayName,
                isSelected: false
            )
        }
    }

    @MainActor
    func loadFasterHistory(context: ModelContext, userId: UUID) {
        let fourWeeksAgo = Calendar.current.date(byAdding: .day, value: -28, to: Date())!

        let descriptor = FetchDescriptor<RRFASTEREntry>(
            predicate: #Predicate { entry in
                entry.userId == userId && entry.date >= fourWeeksAgo
            },
            sortBy: [SortDescriptor(\.date)]
        )

        let entries = (try? context.fetch(descriptor)) ?? []
        fasterHistory = entries.map { entry in
            let stage = FASTERStage(rawValue: entry.stage) ?? .restoration
            return FASTERHistoryEntry(
                id: entry.id,
                date: entry.date,
                stage: entry.stage,
                moodScore: entry.moodScore,
                stageName: stage.name,
                stageColor: stage.color
            )
        }
    }

    @MainActor
    func loadActionPlanContext(context: ModelContext, userId: UUID, date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        // Load user's recovery plan
        let planDescriptor = FetchDescriptor<RRRecoveryPlan>(
            predicate: #Predicate { plan in
                plan.userId == userId && plan.isActive
            }
        )
        guard let plan = try? context.fetch(planDescriptor).first,
              let planItems = plan.items else {
            missedActivities = []
            recommendedActivities = []
            return
        }

        // Identify missed activities on event day
        var missed: [DayActivityRecord] = []
        var activitiesInPlan = Set<String>()

        for item in planItems where item.isEnabled {
            activitiesInPlan.insert(item.activityType)

            guard let eligibleActivity = DailyEligibleActivity.all.first(where: { $0.activityType == item.activityType }) else {
                continue
            }

            let itemType = item.activityType
            let activityDescriptor = FetchDescriptor<RRActivity>(
                predicate: #Predicate { activity in
                    activity.userId == userId &&
                    activity.activityType == itemType &&
                    activity.date >= startOfDay &&
                    activity.date < endOfDay
                }
            )
            let wasCompleted = (try? context.fetch(activityDescriptor).first) != nil

            if !wasCompleted {
                missed.append(DayActivityRecord(
                    activityType: item.activityType,
                    title: eligibleActivity.displayName,
                    icon: eligibleActivity.icon,
                    iconColor: eligibleActivity.section.iconColor,
                    wasCompleted: false
                ))
            }
        }

        missedActivities = missed

        // Recommend activities not in plan (basic recommendations for common recovery activities)
        var recommendations: [RecommendedActivity] = []

        let recommendableActivities: [(String, String, String, Color, String)] = [
            (ActivityType.urgeLog.rawValue, "Urge Logging", "exclamationmark.triangle.fill", .orange, "Track triggers early"),
            (ActivityType.fasterScale.rawValue, "FASTER Scale", "gauge.with.needle", .rrSuccess, "Daily emotional check-in"),
            (ActivityType.journal.rawValue, "Journaling", "note.text", .purple, "Process thoughts and feelings"),
            (ActivityType.prayer.rawValue, "Prayer", "hands.and.sparkles.fill", .rrSecondary, "Connect with God"),
            (ActivityType.gratitude.rawValue, "Gratitude", "leaf.fill", .rrSuccess, "Shift focus to blessings"),
            (ActivityType.exercise.rawValue, "Exercise", "figure.run", .rrSuccess, "Physical stress release"),
            (ActivityType.phoneCalls.rawValue, "Phone Calls", "phone.fill", .rrPrimary, "Stay connected"),
        ]

        for (activityType, title, icon, color, reason) in recommendableActivities {
            if !activitiesInPlan.contains(activityType) {
                recommendations.append(RecommendedActivity(
                    activityType: activityType,
                    title: title,
                    icon: icon,
                    iconColor: color,
                    reason: reason
                ))
            }
        }

        recommendedActivities = recommendations
    }

    // MARK: - Trigger Management

    func addTrigger() {
        if triggerDetails.count < 15 {
            triggerDetails.append(TriggerEntry())
        }
    }

    func removeTrigger(at offsets: IndexSet) {
        triggerDetails.remove(atOffsets: offsets)
    }

    func addBuildUpTrigger() {
        if triggers.count < 15 {
            triggers.append(TriggerEntry())
        }
    }

    func removeBuildUpTrigger(at index: Int) {
        guard triggers.indices.contains(index) else { return }
        triggers.remove(at: index)
    }

    func addCustomTrigger() {
        if triggerDetails.count < 15 {
            triggerDetails.append(TriggerEntry())
        }
    }

    func removeCustomTrigger(at index: Int) {
        guard triggerDetails.indices.contains(index) else { return }
        triggerDetails.remove(at: index)
    }

    func toggleTriggerCategory(_ category: String) {
        if triggerSummary.contains(category) {
            triggerSummary.removeAll { $0 == category }
        } else {
            if triggerSummary.count < 7 {
                triggerSummary.append(category)
            }
        }
    }

    func toggleUserTrigger(_ triggerId: UUID) {
        if let index = userTriggers.firstIndex(where: { $0.id == triggerId }) {
            userTriggers[index].isSelected.toggle()
        }
    }

    // MARK: - Build-Up Helpers

    func addMissedHelpOpportunity() {
        missedHelpOpportunities.append(MissedHelpEntry())
    }

    func removeMissedHelpOpportunity(at index: Int) {
        guard missedHelpOpportunities.indices.contains(index) else { return }
        missedHelpOpportunities.remove(at: index)
    }

    func addDecisionPoint() {
        decisionPoints.append(DecisionPointEntry())
    }

    func removeDecisionPoint(at index: Int) {
        guard decisionPoints.indices.contains(index) else { return }
        decisionPoints.remove(at: index)
    }

    // MARK: - Feelings Management

    func addFeeling(_ feeling: String) {
        guard !feeling.isEmpty, !feelings.contains(feeling) else { return }
        feelings.append(feeling)
    }

    func removeFeeling(_ feeling: String) {
        feelings.removeAll { $0 == feeling }
    }

    // MARK: - Timeline Management

    func addFreeFormEntry(time: Date, description: String) {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        freeFormEntries.append(FreeFormEntry(time: timeFormatter.string(from: time), text: description))
    }

    // MARK: - Action Plan

    func addActionItem() {
        if actionItems.count < 10 {
            actionItems.append(ActionItemEntry())
        }
    }

    func removeActionItem(at offsets: IndexSet) {
        actionItems.remove(atOffsets: offsets)
    }

    func removeActionItemAt(at index: Int) {
        guard actionItems.indices.contains(index) else { return }
        actionItems.remove(at: index)
    }

    func toggleRecommendation(_ activityType: String) {
        if selectedRecommendations.contains(activityType) {
            selectedRecommendations.remove(activityType)
        } else {
            selectedRecommendations.insert(activityType)
        }
    }

    // MARK: - Draft Persistence (SwiftData)

    @MainActor
    func saveDraft(context: ModelContext) throws {
        let userId = UUID()  // TODO: Get from current user session

        let postMortem: RRPostMortem

        if let existingId = existingDraftId,
           let existing = try? context.fetch(FetchDescriptor<RRPostMortem>(
               predicate: #Predicate { $0.id == existingId }
           )).first {
            postMortem = existing
        } else {
            postMortem = RRPostMortem(
                userId: userId,
                analysisId: analysisId ?? "",
                timestamp: timestamp,
                eventType: eventType,
                relapseId: relapseId,
                addictionId: addictionId
            )
            context.insert(postMortem)
        }

        // Update fields
        postMortem.status = "draft"
        postMortem.timestamp = timestamp
        postMortem.eventType = eventType
        postMortem.relapseId = relapseId
        postMortem.addictionId = addictionId
        postMortem.sectionsCompleted = completedSections
        postMortem.sectionsRemaining = remainingSections
        postMortem.triggerSummary = triggerSummary
        postMortem.actionItemCount = actionItems.count + selectedRecommendations.count
        postMortem.synced = false
        postMortem.modifiedAt = Date()

        // Serialize sections to JSON
        postMortem.sections = toSectionsPayload()

        // Serialize trigger details
        let triggerPayloads = triggerDetails.map { entry in
            TriggerDetailPayload(
                category: entry.category.isEmpty ? nil : entry.category,
                surface: entry.surface.isEmpty ? nil : entry.surface,
                underlying: entry.underlying.isEmpty ? nil : entry.underlying,
                coreWound: entry.coreWound.isEmpty ? nil : entry.coreWound
            )
        }
        postMortem.triggerDetails = triggerPayloads

        // Serialize action plan (include custom items + selected recommendations)
        let actionPayloads = actionItems.map { item in
            ActionPlanItemPayload(
                actionId: nil,
                timelinePoint: item.timelinePoint.isEmpty ? nil : item.timelinePoint,
                action: item.action.isEmpty ? nil : item.action,
                category: item.category.isEmpty ? nil : item.category,
                convertedToCommitmentId: item.convertedToCommitmentId,
                convertedToGoalId: item.convertedToGoalId
            )
        }
        postMortem.actionPlan = actionPayloads

        try context.save()
        existingDraftId = postMortem.id

        logger.info("Saved post-mortem draft: \(postMortem.id)")
    }

    @MainActor
    func complete(context: ModelContext) throws {
        guard canComplete else {
            throw PostMortemError.incompleteData(errors: validateForCompletion())
        }

        // Mark as complete locally
        isDraft = false
        showCompletionMessage = true
        completionMessage = "Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom."

        // Save final state to SwiftData
        try saveDraft(context: context)

        logger.info("Post-mortem completed locally")
    }

    @MainActor
    func loadDraft(from postMortem: RRPostMortem) {
        existingDraftId = postMortem.id
        analysisId = postMortem.analysisId
        timestamp = postMortem.timestamp
        eventType = postMortem.eventType
        relapseId = postMortem.relapseId
        addictionId = postMortem.addictionId
        isDraft = postMortem.status == "draft"

        // Load sections
        if let sections = postMortem.sections {
            if let dayBefore = sections.dayBefore {
                dayBeforeText = dayBefore.text ?? ""
                dayBeforeMoodRating = dayBefore.moodRating ?? 5
                dayBeforeUnresolvedConflicts = dayBefore.unresolvedConflicts ?? ""
            }

            if let throughoutDay = sections.throughoutTheDay {
                throughoutDayText = throughoutDay.freeFormEntries?.first?.text ?? ""
            }

            if let buildUp = sections.buildUp {
                firstNoticed = buildUp.firstNoticed ?? ""
                responseToWarnings = buildUp.responseToWarnings ?? ""

                triggers = buildUp.triggers?.map { trigger in
                    TriggerEntry(
                        category: trigger.category ?? "",
                        surface: trigger.surface ?? "",
                        underlying: trigger.underlying ?? "",
                        coreWound: trigger.coreWound ?? ""
                    )
                } ?? []

                missedHelpOpportunities = buildUp.missedHelpOpportunities?.map { opportunity in
                    MissedHelpEntry(
                        description: opportunity.description ?? "",
                        reason: opportunity.reason ?? ""
                    )
                } ?? []

                decisionPoints = buildUp.decisionPoints?.map { point in
                    DecisionPointEntry(
                        timeOfDay: point.timeOfDay ?? "",
                        description: point.description ?? "",
                        couldHaveDone: point.couldHaveDone ?? "",
                        insteadDid: point.insteadDid ?? ""
                    )
                } ?? []
            }

            if let actingOut = sections.actingOut {
                actingOutDescription = actingOut.description ?? ""
                actingOutDurationMinutes = actingOut.durationMinutes
            }

            if let after = sections.immediatelyAfter {
                feelings = after.feelings ?? []
                feelingsWheelSelections = after.feelingsWheelSelections ?? []
                whatDidNext = after.whatDidNext ?? ""
                reachedOut = after.reachedOut ?? false
                reachedOutTo = after.reachedOutTo
                wishDoneDifferently = after.wishDoneDifferently ?? ""
            }
        }

        // Load triggers
        triggerSummary = postMortem.triggerSummary
        triggerDetails = postMortem.triggerDetails.map { payload in
            TriggerEntry(
                category: payload.category ?? "",
                surface: payload.surface ?? "",
                underlying: payload.underlying ?? "",
                coreWound: payload.coreWound ?? ""
            )
        }

        // Load action plan
        actionItems = postMortem.actionPlan.map { payload in
            ActionItemEntry(
                timelinePoint: payload.timelinePoint ?? "",
                action: payload.action ?? "",
                category: payload.category ?? "",
                convertedToCommitmentId: payload.convertedToCommitmentId,
                convertedToGoalId: payload.convertedToGoalId
            )
        }

        logger.info("Loaded post-mortem draft: \(postMortem.id)")
    }

    @MainActor
    func resumeLatestDraft(context: ModelContext, userId: UUID) -> Bool {
        let descriptor = FetchDescriptor<RRPostMortem>(
            predicate: #Predicate { pm in
                pm.userId == userId && pm.status == "draft"
            },
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )

        guard let draft = try? context.fetch(descriptor).first else {
            return false
        }

        loadDraft(from: draft)
        return true
    }

    // MARK: - API Integration

    func createOnServer(apiClient: APIClient) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let request = toCreateRequest()
            let response: SiemensResponse<PostMortemSummaryData> = try await apiClient.post(.createPostMortem(request))

            analysisId = response.data.analysisId
            isDraft = response.data.status == "draft"

            logger.info("Created post-mortem on server: \(response.data.analysisId)")
        } catch {
            self.error = "Failed to create post-mortem: \(error.localizedDescription)"
            logger.error("Failed to create post-mortem: \(error.localizedDescription)")
            throw error
        }
    }

    func updateOnServer(apiClient: APIClient) async throws {
        guard let analysisId else {
            throw PostMortemError.missingAnalysisId
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let request = toUpdateRequest()
            let response: SiemensResponse<PostMortemSummaryData> = try await apiClient.patch(.updatePostMortem(analysisId: analysisId, request))

            isDraft = response.data.status == "draft"

            logger.info("Updated post-mortem on server: \(analysisId)")
        } catch {
            self.error = "Failed to update post-mortem: \(error.localizedDescription)"
            logger.error("Failed to update post-mortem: \(error.localizedDescription)")
            throw error
        }
    }

    func completeOnServer(apiClient: APIClient) async throws -> String? {
        guard let analysisId else {
            throw PostMortemError.missingAnalysisId
        }

        guard canComplete else {
            throw PostMortemError.incompleteData(errors: validateForCompletion())
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let response: SiemensResponse<PostMortemAnalysisData> = try await apiClient.post(.completePostMortem(analysisId: analysisId))

            isDraft = false
            showCompletionMessage = true
            completionMessage = response.data.message ?? "Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom."

            logger.info("Completed post-mortem on server: \(analysisId)")

            return response.data.message
        } catch {
            self.error = "Failed to complete post-mortem: \(error.localizedDescription)"
            logger.error("Failed to complete post-mortem: \(error.localizedDescription)")
            throw error
        }
    }

    func loadInsights(apiClient: APIClient, addictionId: String?) async throws {
        insightsLoading = true
        defer { insightsLoading = false }

        do {
            let response: SiemensResponse<PostMortemInsightsData> = try await apiClient.get(.getPostMortemInsights(addictionId: addictionId))
            insights = response.data

            logger.info("Loaded post-mortem insights: \(response.data.totalAnalyses) analyses")
        } catch {
            logger.error("Failed to load insights: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Conversion to API Types

    func toCreateRequest() -> CreatePostMortemRequest {
        CreatePostMortemRequest(
            timestamp: ISO8601DateFormatter().string(from: timestamp),
            eventType: eventType,
            relapseId: relapseId,
            addictionId: addictionId,
            sections: toSectionsPayload()
        )
    }

    func toUpdateRequest() -> UpdatePostMortemRequest {
        UpdatePostMortemRequest(
            sections: toSectionsPayload(),
            triggerSummary: triggerSummary.isEmpty ? nil : triggerSummary,
            triggerDetails: triggerDetails.isEmpty ? nil : triggerDetails.map { entry in
                TriggerDetailPayload(
                    category: entry.category.isEmpty ? nil : entry.category,
                    surface: entry.surface.isEmpty ? nil : entry.surface,
                    underlying: entry.underlying.isEmpty ? nil : entry.underlying,
                    coreWound: entry.coreWound.isEmpty ? nil : entry.coreWound
                )
            },
            fasterMapping: nil,  // Removed: now using real FASTER history instead
            actionPlan: actionItems.isEmpty ? nil : actionItems.map { item in
                ActionPlanItemPayload(
                    actionId: nil,
                    timelinePoint: item.timelinePoint.isEmpty ? nil : item.timelinePoint,
                    action: item.action.isEmpty ? nil : item.action,
                    category: item.category.isEmpty ? nil : item.category,
                    convertedToCommitmentId: item.convertedToCommitmentId,
                    convertedToGoalId: item.convertedToGoalId
                )
            }
        )
    }

    func toSectionsPayload() -> PostMortemSectionsPayload {
        PostMortemSectionsPayload(
            dayBefore: dayBeforeText.isEmpty ? nil : DayBeforeSectionPayload(
                text: dayBeforeText,
                moodRating: dayBeforeMoodRating,
                recoveryPracticesKept: nil,  // Removed: replaced by activity history
                unresolvedConflicts: dayBeforeUnresolvedConflicts.isEmpty ? nil : dayBeforeUnresolvedConflicts
            ),
            morning: nil,  // Removed: morning section no longer exists
            throughoutTheDay: throughoutDayText.isEmpty ? nil : ThroughoutTheDaySectionPayload(
                timeBlocks: nil,  // Time blocks are loaded from RRTimeBlock, not user-entered
                freeFormEntries: throughoutDayText.isEmpty ? nil : [
                    FreeFormEntryPayload(time: nil, text: throughoutDayText)
                ]
            ),
            buildUp: firstNoticed.isEmpty ? nil : BuildUpSectionPayload(
                firstNoticed: firstNoticed,
                triggers: triggers.isEmpty ? nil : triggers.map { trigger in
                    TriggerDetailPayload(
                        category: trigger.category.isEmpty ? nil : trigger.category,
                        surface: trigger.surface.isEmpty ? nil : trigger.surface,
                        underlying: trigger.underlying.isEmpty ? nil : trigger.underlying,
                        coreWound: trigger.coreWound.isEmpty ? nil : trigger.coreWound
                    )
                },
                responseToWarnings: responseToWarnings.isEmpty ? nil : responseToWarnings,
                missedHelpOpportunities: missedHelpOpportunities.isEmpty ? nil : missedHelpOpportunities.map { opportunity in
                    MissedHelpOpportunityPayload(
                        description: opportunity.description.isEmpty ? nil : opportunity.description,
                        reason: opportunity.reason.isEmpty ? nil : opportunity.reason
                    )
                },
                decisionPoints: decisionPoints.isEmpty ? nil : decisionPoints.map { point in
                    DecisionPointPayload(
                        timeOfDay: point.timeOfDay.isEmpty ? nil : point.timeOfDay,
                        description: point.description.isEmpty ? nil : point.description,
                        couldHaveDone: point.couldHaveDone.isEmpty ? nil : point.couldHaveDone,
                        insteadDid: point.insteadDid.isEmpty ? nil : point.insteadDid
                    )
                }
            ),
            actingOut: actingOutDescription.isEmpty ? nil : ActingOutSectionPayload(
                description: actingOutDescription,
                addictionId: addictionId,
                durationMinutes: actingOutDurationMinutes,
                linkedRelapseId: relapseId
            ),
            immediatelyAfter: whatDidNext.isEmpty ? nil : ImmediatelyAfterSectionPayload(
                feelings: feelings.isEmpty ? nil : feelings,
                feelingsWheelSelections: feelingsWheelSelections.isEmpty ? nil : feelingsWheelSelections,
                whatDidNext: whatDidNext,
                reachedOut: reachedOut,
                reachedOutTo: reachedOutTo,
                wishDoneDifferently: wishDoneDifferently.isEmpty ? nil : wishDoneDifferently
            )
        )
    }
}

// MARK: - Activity Section Icon Color Extension

extension ActivitySection {
    var iconColor: Color {
        switch self {
        case .sobrietyCommitment: return .rrSecondary
        case .journalingReflection: return .purple
        case .selfCare: return .rrSuccess
        case .connection: return .rrPrimary
        case .growth: return .orange
        }
    }
}

// MARK: - Errors

enum PostMortemError: LocalizedError {
    case missingAnalysisId
    case incompleteData(errors: [String])
    case invalidEventType
    case relapseIdRequiredForRelapse
    case nearMissCannotHaveRelapseId

    var errorDescription: String? {
        switch self {
        case .missingAnalysisId:
            return "Post-mortem analysis ID is missing. Please create the analysis first."
        case .incompleteData(let errors):
            return "Post-mortem data is incomplete: \(errors.joined(separator: ", "))"
        case .invalidEventType:
            return "Invalid event type. Must be 'relapse', 'near-miss', or 'combined'."
        case .relapseIdRequiredForRelapse:
            return "Relapse ID is required for relapse event type."
        case .nearMissCannotHaveRelapseId:
            return "Near-miss events cannot have a relapse ID."
        }
    }
}
