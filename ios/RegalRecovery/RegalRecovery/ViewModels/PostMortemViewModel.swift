import Foundation
import SwiftData
import OSLog

// MARK: - Local Entry Types

struct TimeBlockEntry: Identifiable, Equatable {
    let id = UUID()
    var period: String = "morning"  // morning, midday, afternoon, evening
    var startTime = ""
    var endTime = ""
    var activity = ""
    var location = ""
    var company = ""
    var thoughts = ""
    var feelings = ""
    var warningSigns: [String] = []
}

struct FreeFormEntry: Identifiable, Equatable {
    let id = UUID()
    var time = ""
    var text = ""
}

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

struct FasterMappingEntry: Identifiable, Equatable {
    let id = UUID()
    var timeOfDay = ""
    var stage = ""  // FASTER stage
}

struct ActionItemEntry: Identifiable, Equatable {
    let id = UUID()
    var timelinePoint = ""
    var action = ""
    var category = ""  // spiritual, relational, emotional, physical, practical
    var convertedToCommitmentId: String?
    var convertedToGoalId: String?
}

struct ShareRecipient: Identifiable, Equatable {
    let id = UUID()
    var contactId = ""
    var shareType = "full"  // "full" or "summary"
}

// MARK: - PostMortemViewModel

@Observable
class PostMortemViewModel {

    // MARK: - Flow State

    enum FlowStep: Int, CaseIterable {
        case eventType       // Step 0: Choose relapse/near-miss/combined
        case dayBefore       // Step 1
        case morning         // Step 2
        case throughoutTheDay // Step 3
        case buildUp         // Step 4
        case actingOut       // Step 5
        case immediatelyAfter // Step 6
        case triggers        // Step 7: Trigger identification
        case fasterMapping   // Step 8: FASTER timeline
        case actionPlan      // Step 9: Action items
        case review          // Step 10: Review & complete
    }

    var currentStep: FlowStep = .eventType
    var isLoading = false
    var error: String?
    var showCompletionMessage = false
    var completionMessage: String?

    // MARK: - Draft State

    var analysisId: String?
    var isDraft = true
    var existingDraftId: UUID?  // If resuming a draft

    // MARK: - Event Type (Step 0)

    var eventType: String = "relapse"  // "relapse", "near-miss", "combined"
    var relapseId: String?
    var addictionId: String?
    var timestamp = Date()

    // MARK: - Section Data (Steps 1-6)

    // Day Before
    var dayBeforeText = ""
    var dayBeforeMoodRating: Int = 5
    var dayBeforeRecoveryPracticesKept = true
    var dayBeforeUnresolvedConflicts = ""

    // Morning
    var morningText = ""
    var morningMoodRating: Int = 5
    var morningCommitmentCompleted = false
    var morningAffirmationViewed = false

    // Throughout the Day
    var timeBlocks: [TimeBlockEntry] = []
    var freeFormEntries: [FreeFormEntry] = []

    // Build-Up
    var buildUpFirstNoticed = ""
    var buildUpTriggers: [TriggerEntry] = []
    var buildUpResponseToWarnings = ""
    var buildUpMissedHelpOpportunities: [MissedHelpEntry] = []
    var buildUpDecisionPoints: [DecisionPointEntry] = []

    // Acting Out
    var actingOutDescription = ""
    var actingOutAddictionId: String?
    var actingOutDurationMinutes: Int?
    var actingOutLinkedRelapseId: String?

    // Immediately After
    var afterFeelings: [String] = []
    var afterFeelingsWheelSelections: [String] = []
    var afterWhatDidNext = ""
    var afterReachedOut = false
    var afterReachedOutTo: String?
    var afterWishDoneDifferently = ""

    // MARK: - Triggers (Step 7)

    var triggerSummary: [String] = []  // Categories: emotional, environmental, relational, physical, digital, spiritual
    var triggerDetails: [TriggerEntry] = []

    // MARK: - FASTER Mapping (Step 8)

    var fasterMapping: [FasterMappingEntry] = []

    // MARK: - Action Plan (Step 9)

    var actionItems: [ActionItemEntry] = []

    // MARK: - Sharing

    var sharingEnabled = false
    var shareEntries: [ShareRecipient] = []

    // MARK: - Insights (computed from completed post-mortems)

    var insights: PostMortemInsightsData?
    var insightsLoading = false

    // MARK: - Constants

    static let allSectionNames = ["dayBefore", "morning", "throughoutTheDay", "buildUp", "actingOut", "immediatelyAfter"]
    static let triggerCategories = ["emotional", "environmental", "relational", "physical", "digital", "spiritual"]
    static let fasterStages = ["restoration", "forgetting-priorities", "anxiety", "speeding-up", "ticked-off", "exhausted", "relapse"]
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
        case .eventType:
            // Validate event type selection
            guard !eventType.isEmpty else { return false }
            if eventType == "relapse" {
                return relapseId != nil || addictionId != nil
            }
            if eventType == "near-miss" {
                return relapseId == nil  // Near-miss cannot have relapseId
            }
            return true

        case .dayBefore:
            return !dayBeforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .morning:
            return !morningText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .throughoutTheDay:
            return !timeBlocks.isEmpty || !freeFormEntries.isEmpty

        case .buildUp:
            return !buildUpFirstNoticed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .actingOut:
            return !actingOutDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .immediatelyAfter:
            return !afterWhatDidNext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        case .triggers:
            return true  // Optional step

        case .fasterMapping:
            return true  // Optional step

        case .actionPlan:
            return actionItemCountValid

        case .review:
            return canComplete
        }
    }

    func advance() {
        guard canAdvance() else { return }
        if let nextStep = FlowStep(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        }
    }

    func goBack() {
        if let prevStep = FlowStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prevStep
        }
    }

    // MARK: - Section Completion

    var completedSections: [String] {
        var sections: [String] = []

        if !dayBeforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("dayBefore")
        }
        if !morningText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("morning")
        }
        if !timeBlocks.isEmpty || !freeFormEntries.isEmpty {
            sections.append("throughoutTheDay")
        }
        if !buildUpFirstNoticed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("buildUp")
        }
        if !actingOutDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("actingOut")
        }
        if !afterWhatDidNext.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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

        // All 6 sections required
        let missing = remainingSections
        if !missing.isEmpty {
            errors.append("Missing required sections: \(missing.joined(separator: ", "))")
        }

        // At least 1 action item required
        if actionItems.isEmpty {
            errors.append("At least one action plan item is required")
        }

        // Mood ratings must be 1-10
        if dayBeforeMoodRating < 1 || dayBeforeMoodRating > 10 {
            errors.append("Day before mood rating must be between 1 and 10")
        }
        if morningMoodRating < 1 || morningMoodRating > 10 {
            errors.append("Morning mood rating must be between 1 and 10")
        }

        // Trigger categories must be valid
        for category in triggerSummary {
            if !Self.triggerCategories.contains(category) {
                errors.append("Invalid trigger category: \(category)")
            }
        }

        // FASTER stages must be valid
        for entry in fasterMapping {
            if !Self.fasterStages.contains(entry.stage) {
                errors.append("Invalid FASTER stage: \(entry.stage)")
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

    // MARK: - Trigger Management

    func addTrigger() {
        if triggerDetails.count < 15 {
            triggerDetails.append(TriggerEntry())
        }
    }

    func removeTrigger(at offsets: IndexSet) {
        triggerDetails.remove(atOffsets: offsets)
    }

    func toggleTriggerCategory(_ category: String) {
        if triggerSummary.contains(category) {
            triggerSummary.removeAll { $0 == category }
        } else {
            if triggerSummary.count < 6 {
                triggerSummary.append(category)
            }
        }
    }

    // MARK: - FASTER Mapping

    func addFasterMappingEntry() {
        if fasterMapping.count < 24 {
            fasterMapping.append(FasterMappingEntry())
        }
    }

    func removeFasterMappingEntry(at offsets: IndexSet) {
        fasterMapping.remove(atOffsets: offsets)
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

    var actionItemCountValid: Bool {
        actionItems.count >= 1 && actionItems.count <= 10
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
        postMortem.actionItemCount = actionItems.count
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

        // Serialize FASTER mapping
        let fasterPayloads = fasterMapping.map { entry in
            FasterMappingEntryPayload(
                timeOfDay: entry.timeOfDay.isEmpty ? nil : entry.timeOfDay,
                stage: entry.stage.isEmpty ? nil : entry.stage
            )
        }
        postMortem.fasterMapping = fasterPayloads

        // Serialize action plan
        let actionPayloads = actionItems.map { item in
            ActionPlanItemPayload(
                actionId: nil,  // Server-assigned
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
                dayBeforeRecoveryPracticesKept = dayBefore.recoveryPracticesKept ?? true
                dayBeforeUnresolvedConflicts = dayBefore.unresolvedConflicts ?? ""
            }

            if let morning = sections.morning {
                morningText = morning.text ?? ""
                morningMoodRating = morning.moodRating ?? 5
                morningCommitmentCompleted = morning.morningCommitmentCompleted ?? false
                morningAffirmationViewed = morning.affirmationViewed ?? false
            }

            if let throughoutDay = sections.throughoutTheDay {
                timeBlocks = throughoutDay.timeBlocks?.map { block in
                    TimeBlockEntry(
                        period: block.period ?? "morning",
                        startTime: block.startTime ?? "",
                        endTime: block.endTime ?? "",
                        activity: block.activity ?? "",
                        location: block.location ?? "",
                        company: block.company ?? "",
                        thoughts: block.thoughts ?? "",
                        feelings: block.feelings ?? "",
                        warningSigns: block.warningSigns ?? []
                    )
                } ?? []

                freeFormEntries = throughoutDay.freeFormEntries?.map { entry in
                    FreeFormEntry(
                        time: entry.time ?? "",
                        text: entry.text ?? ""
                    )
                } ?? []
            }

            if let buildUp = sections.buildUp {
                buildUpFirstNoticed = buildUp.firstNoticed ?? ""
                buildUpResponseToWarnings = buildUp.responseToWarnings ?? ""

                buildUpTriggers = buildUp.triggers?.map { trigger in
                    TriggerEntry(
                        category: trigger.category ?? "",
                        surface: trigger.surface ?? "",
                        underlying: trigger.underlying ?? "",
                        coreWound: trigger.coreWound ?? ""
                    )
                } ?? []

                buildUpMissedHelpOpportunities = buildUp.missedHelpOpportunities?.map { opportunity in
                    MissedHelpEntry(
                        description: opportunity.description ?? "",
                        reason: opportunity.reason ?? ""
                    )
                } ?? []

                buildUpDecisionPoints = buildUp.decisionPoints?.map { point in
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
                actingOutAddictionId = actingOut.addictionId
                actingOutDurationMinutes = actingOut.durationMinutes
                actingOutLinkedRelapseId = actingOut.linkedRelapseId
            }

            if let after = sections.immediatelyAfter {
                afterFeelings = after.feelings ?? []
                afterFeelingsWheelSelections = after.feelingsWheelSelections ?? []
                afterWhatDidNext = after.whatDidNext ?? ""
                afterReachedOut = after.reachedOut ?? false
                afterReachedOutTo = after.reachedOutTo
                afterWishDoneDifferently = after.wishDoneDifferently ?? ""
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

        // Load FASTER mapping
        fasterMapping = postMortem.fasterMapping.map { payload in
            FasterMappingEntry(
                timeOfDay: payload.timeOfDay ?? "",
                stage: payload.stage ?? ""
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
            fasterMapping: fasterMapping.isEmpty ? nil : fasterMapping.map { entry in
                FasterMappingEntryPayload(
                    timeOfDay: entry.timeOfDay.isEmpty ? nil : entry.timeOfDay,
                    stage: entry.stage.isEmpty ? nil : entry.stage
                )
            },
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
                recoveryPracticesKept: dayBeforeRecoveryPracticesKept,
                unresolvedConflicts: dayBeforeUnresolvedConflicts.isEmpty ? nil : dayBeforeUnresolvedConflicts
            ),
            morning: morningText.isEmpty ? nil : MorningSectionPayload(
                text: morningText,
                moodRating: morningMoodRating,
                morningCommitmentCompleted: morningCommitmentCompleted,
                affirmationViewed: morningAffirmationViewed,
                autoPopulated: nil
            ),
            throughoutTheDay: (timeBlocks.isEmpty && freeFormEntries.isEmpty) ? nil : ThroughoutTheDaySectionPayload(
                timeBlocks: timeBlocks.isEmpty ? nil : timeBlocks.map { block in
                    TimeBlockPayload(
                        period: block.period.isEmpty ? nil : block.period,
                        startTime: block.startTime.isEmpty ? nil : block.startTime,
                        endTime: block.endTime.isEmpty ? nil : block.endTime,
                        activity: block.activity.isEmpty ? nil : block.activity,
                        location: block.location.isEmpty ? nil : block.location,
                        company: block.company.isEmpty ? nil : block.company,
                        thoughts: block.thoughts.isEmpty ? nil : block.thoughts,
                        feelings: block.feelings.isEmpty ? nil : block.feelings,
                        warningSigns: block.warningSigns.isEmpty ? nil : block.warningSigns
                    )
                },
                freeFormEntries: freeFormEntries.isEmpty ? nil : freeFormEntries.map { entry in
                    FreeFormEntryPayload(
                        time: entry.time.isEmpty ? nil : entry.time,
                        text: entry.text.isEmpty ? nil : entry.text
                    )
                }
            ),
            buildUp: buildUpFirstNoticed.isEmpty ? nil : BuildUpSectionPayload(
                firstNoticed: buildUpFirstNoticed,
                triggers: buildUpTriggers.isEmpty ? nil : buildUpTriggers.map { trigger in
                    TriggerDetailPayload(
                        category: trigger.category.isEmpty ? nil : trigger.category,
                        surface: trigger.surface.isEmpty ? nil : trigger.surface,
                        underlying: trigger.underlying.isEmpty ? nil : trigger.underlying,
                        coreWound: trigger.coreWound.isEmpty ? nil : trigger.coreWound
                    )
                },
                responseToWarnings: buildUpResponseToWarnings.isEmpty ? nil : buildUpResponseToWarnings,
                missedHelpOpportunities: buildUpMissedHelpOpportunities.isEmpty ? nil : buildUpMissedHelpOpportunities.map { opportunity in
                    MissedHelpOpportunityPayload(
                        description: opportunity.description.isEmpty ? nil : opportunity.description,
                        reason: opportunity.reason.isEmpty ? nil : opportunity.reason
                    )
                },
                decisionPoints: buildUpDecisionPoints.isEmpty ? nil : buildUpDecisionPoints.map { point in
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
                addictionId: actingOutAddictionId,
                durationMinutes: actingOutDurationMinutes,
                linkedRelapseId: actingOutLinkedRelapseId
            ),
            immediatelyAfter: afterWhatDidNext.isEmpty ? nil : ImmediatelyAfterSectionPayload(
                feelings: afterFeelings.isEmpty ? nil : afterFeelings,
                feelingsWheelSelections: afterFeelingsWheelSelections.isEmpty ? nil : afterFeelingsWheelSelections,
                whatDidNext: afterWhatDidNext,
                reachedOut: afterReachedOut,
                reachedOutTo: afterReachedOutTo,
                wishDoneDifferently: afterWishDoneDifferently.isEmpty ? nil : afterWishDoneDifferently
            )
        )
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
