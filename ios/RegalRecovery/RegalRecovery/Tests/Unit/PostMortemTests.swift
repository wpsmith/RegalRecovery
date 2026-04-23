import Testing
import Foundation
@testable import RegalRecovery

// MARK: - PostMortemViewModel Tests

@Suite("PostMortemViewModel")
struct PostMortemViewModelTests {

    // MARK: - Flow Navigation

    @Test("initial step is eventType")
    func testInitialStep() {
        let vm = PostMortemViewModel()
        #expect(vm.currentStep == .eventType)
    }

    @Test("advance moves to next step")
    func testAdvanceStep() {
        let vm = PostMortemViewModel()
        vm.eventType = "relapse"
        vm.relapseId = "r_12345"

        vm.advance()

        #expect(vm.currentStep == .dayBefore)
    }

    @Test("goBack moves to previous step")
    func testGoBackStep() {
        let vm = PostMortemViewModel()
        vm.eventType = "near-miss"
        vm.advance()
        #expect(vm.currentStep == .dayBefore)

        vm.goBack()

        #expect(vm.currentStep == .eventType)
    }

    @Test("cannot go back from first step")
    func testCannotGoBackFromFirst() {
        let vm = PostMortemViewModel()
        #expect(vm.currentStep == .eventType)

        vm.goBack()

        #expect(vm.currentStep == .eventType)
    }

    @Test("progress is 0 at first step and increases")
    func testProgressCalculation() {
        let vm = PostMortemViewModel()

        let initialProgress = vm.progress
        #expect(initialProgress == 0.0)

        vm.eventType = "near-miss"
        vm.advance()
        let nextProgress = vm.progress
        #expect(nextProgress > 0.0)
        #expect(nextProgress < 1.0)
    }

    @Test("progress reaches near 1.0 at final step")
    func testProgressAtFinalStep() {
        let vm = PostMortemViewModel()
        vm.currentStep = .review

        let finalProgress = vm.progress
        #expect(finalProgress > 0.9)
    }

    // MARK: - Event Type Validation

    @Test("near-miss event type cannot have relapseId")
    func testNearMissNoRelapseId() {
        let vm = PostMortemViewModel()
        vm.eventType = "near-miss"
        vm.relapseId = "r_12345"

        #expect(!vm.canAdvance())
    }

    @Test("near-miss without relapseId can advance")
    func testNearMissWithoutRelapseCanAdvance() {
        let vm = PostMortemViewModel()
        vm.eventType = "near-miss"
        vm.relapseId = nil

        #expect(vm.canAdvance())
    }

    @Test("relapse event type with relapseId can advance")
    func testRelapseWithRelapseIdCanAdvance() {
        let vm = PostMortemViewModel()
        vm.eventType = "relapse"
        vm.relapseId = "r_12345"

        #expect(vm.canAdvance())
    }

    @Test("relapse event type with addictionId can advance")
    func testRelapseWithAddictionIdCanAdvance() {
        let vm = PostMortemViewModel()
        vm.eventType = "relapse"
        vm.addictionId = "a_67890"

        #expect(vm.canAdvance())
    }

    // MARK: - Validation

    @Test("canComplete requires all 6 sections filled")
    func testCanCompleteRequiresAllSections() {
        let vm = PostMortemViewModel()

        // Fill only 5 sections
        vm.dayBeforeText = "Day before text"
        vm.morningText = "Morning text"
        vm.timeBlocks.append(TimeBlockEntry(period: "morning"))
        vm.buildUpFirstNoticed = "Build up text"
        vm.actingOutDescription = "Acting out text"
        // Missing immediatelyAfter section

        vm.addActionItem()
        vm.actionItems[0].action = "Call sponsor"
        vm.actionItems[0].category = "relational"
        vm.actionItems[0].timelinePoint = "08:00"

        #expect(!vm.canComplete)
    }

    @Test("canComplete requires at least 1 action item")
    func testCanCompleteRequiresActionItem() {
        let vm = PostMortemViewModel()

        // Fill all 6 sections
        vm.dayBeforeText = "Day before text"
        vm.morningText = "Morning text"
        vm.timeBlocks.append(TimeBlockEntry(period: "morning"))
        vm.buildUpFirstNoticed = "Build up text"
        vm.actingOutDescription = "Acting out text"
        vm.afterWhatDidNext = "What I did next"

        // But no action items
        #expect(!vm.canComplete)
    }

    @Test("canComplete returns false with 0 action items")
    func testCanCompleteNoActions() {
        let vm = PostMortemViewModel()

        // Fill all sections
        fillAllRequiredSections(vm: vm)

        #expect(vm.actionItems.isEmpty)
        #expect(!vm.canComplete)
    }

    @Test("canComplete returns false with 11 action items")
    func testCanCompleteTooManyActions() {
        let vm = PostMortemViewModel()

        // Fill all sections
        fillAllRequiredSections(vm: vm)

        // Add 11 action items (max is 10)
        for i in 0..<11 {
            vm.actionItems.append(ActionItemEntry(
                timelinePoint: "08:00",
                action: "Action \(i)",
                category: "spiritual"
            ))
        }

        #expect(!vm.actionItemCountValid)
    }

    @Test("canComplete returns true with valid data")
    func testCanCompleteWithValidData() {
        let vm = PostMortemViewModel()

        // Fill all sections
        fillAllRequiredSections(vm: vm)

        // Add action item
        vm.addActionItem()
        vm.actionItems[0].action = "Call sponsor"
        vm.actionItems[0].category = "relational"
        vm.actionItems[0].timelinePoint = "08:00"

        #expect(vm.canComplete)
    }

    @Test("validateForCompletion lists missing sections")
    func testValidateForCompletionMissingSections() {
        let vm = PostMortemViewModel()

        // Only fill day before
        vm.dayBeforeText = "Day before text"
        vm.addActionItem()
        vm.actionItems[0].action = "Action"
        vm.actionItems[0].category = "spiritual"
        vm.actionItems[0].timelinePoint = "08:00"

        let errors = vm.validateForCompletion()

        #expect(errors.count > 0)
        #expect(errors.contains(where: { $0.contains("Missing required sections") }))
    }

    @Test("validateForCompletion returns empty for valid data")
    func testValidateForCompletionValid() {
        let vm = PostMortemViewModel()

        fillAllRequiredSections(vm: vm)

        vm.addActionItem()
        vm.actionItems[0].action = "Action"
        vm.actionItems[0].category = "spiritual"
        vm.actionItems[0].timelinePoint = "08:00"

        let errors = vm.validateForCompletion()

        #expect(errors.isEmpty)
    }

    @Test("mood rating clamped to 1-10")
    func testMoodRatingBounds() {
        let vm = PostMortemViewModel()

        vm.dayBeforeMoodRating = -1

        fillAllRequiredSections(vm: vm)
        vm.addActionItem()
        vm.actionItems[0].action = "Action"
        vm.actionItems[0].category = "spiritual"
        vm.actionItems[0].timelinePoint = "08:00"

        let errors = vm.validateForCompletion()

        #expect(errors.contains(where: { $0.contains("mood rating must be between 1 and 10") }))
    }

    @Test("mood rating 11 is invalid")
    func testMoodRatingTooHigh() {
        let vm = PostMortemViewModel()

        vm.morningMoodRating = 11

        fillAllRequiredSections(vm: vm)
        vm.addActionItem()
        vm.actionItems[0].action = "Action"
        vm.actionItems[0].category = "spiritual"
        vm.actionItems[0].timelinePoint = "08:00"

        let errors = vm.validateForCompletion()

        #expect(errors.contains(where: { $0.contains("mood rating must be between 1 and 10") }))
    }

    // MARK: - Section Completion

    @Test("section is complete when text is non-empty")
    func testSectionComplete() {
        let vm = PostMortemViewModel()

        #expect(!vm.isSectionComplete("dayBefore"))

        vm.dayBeforeText = "Some text"

        #expect(vm.isSectionComplete("dayBefore"))
    }

    @Test("section with whitespace only is not complete")
    func testSectionWithWhitespaceNotComplete() {
        let vm = PostMortemViewModel()

        vm.dayBeforeText = "   \n  \t  "

        #expect(!vm.isSectionComplete("dayBefore"))
    }

    @Test("completedSections tracks filled sections")
    func testCompletedSectionsTracking() {
        let vm = PostMortemViewModel()

        #expect(vm.completedSections.isEmpty)

        vm.dayBeforeText = "Day before"
        vm.morningText = "Morning"

        let completed = vm.completedSections
        #expect(completed.count == 2)
        #expect(completed.contains("dayBefore"))
        #expect(completed.contains("morning"))
    }

    @Test("throughoutTheDay section complete with time blocks")
    func testThroughoutTheDayWithTimeBlocks() {
        let vm = PostMortemViewModel()

        #expect(!vm.isSectionComplete("throughoutTheDay"))

        vm.timeBlocks.append(TimeBlockEntry(period: "morning"))

        #expect(vm.isSectionComplete("throughoutTheDay"))
    }

    @Test("throughoutTheDay section complete with free form entries")
    func testThroughoutTheDayWithFreeFormEntries() {
        let vm = PostMortemViewModel()

        #expect(!vm.isSectionComplete("throughoutTheDay"))

        vm.freeFormEntries.append(FreeFormEntry(time: "08:00", text: "Something happened"))

        #expect(vm.isSectionComplete("throughoutTheDay"))
    }

    @Test("remainingSections is inverse of completed")
    func testRemainingSections() {
        let vm = PostMortemViewModel()

        vm.dayBeforeText = "Day before"
        vm.morningText = "Morning"

        let remaining = vm.remainingSections

        #expect(remaining.count == 4)
        #expect(!remaining.contains("dayBefore"))
        #expect(!remaining.contains("morning"))
        #expect(remaining.contains("throughoutTheDay"))
        #expect(remaining.contains("buildUp"))
        #expect(remaining.contains("actingOut"))
        #expect(remaining.contains("immediatelyAfter"))
    }

    // MARK: - Trigger Management

    @Test("addTrigger adds an empty trigger entry")
    func testAddTrigger() {
        let vm = PostMortemViewModel()

        #expect(vm.triggerDetails.isEmpty)

        vm.addTrigger()

        #expect(vm.triggerDetails.count == 1)
        #expect(vm.triggerDetails[0].category.isEmpty)
        #expect(vm.triggerDetails[0].surface.isEmpty)
    }

    @Test("addTrigger respects 15 trigger limit")
    func testAddTriggerLimit() {
        let vm = PostMortemViewModel()

        for _ in 0..<16 {
            vm.addTrigger()
        }

        #expect(vm.triggerDetails.count == 15)
    }

    @Test("removeTrigger removes at index")
    func testRemoveTrigger() {
        let vm = PostMortemViewModel()

        vm.addTrigger()
        vm.addTrigger()
        vm.triggerDetails[0].category = "emotional"
        vm.triggerDetails[1].category = "physical"

        #expect(vm.triggerDetails.count == 2)

        vm.removeTrigger(at: IndexSet(integer: 0))

        #expect(vm.triggerDetails.count == 1)
        #expect(vm.triggerDetails[0].category == "physical")
    }

    @Test("toggleTriggerCategory adds category")
    func testToggleCategoryAdd() {
        let vm = PostMortemViewModel()

        #expect(vm.triggerSummary.isEmpty)

        vm.toggleTriggerCategory("emotional")

        #expect(vm.triggerSummary.count == 1)
        #expect(vm.triggerSummary.contains("emotional"))
    }

    @Test("toggleTriggerCategory removes category")
    func testToggleCategoryRemove() {
        let vm = PostMortemViewModel()

        vm.toggleTriggerCategory("emotional")
        #expect(vm.triggerSummary.contains("emotional"))

        vm.toggleTriggerCategory("emotional")

        #expect(!vm.triggerSummary.contains("emotional"))
    }

    @Test("toggleTriggerCategory respects 6 category limit")
    func testToggleCategoryLimit() {
        let vm = PostMortemViewModel()

        for category in PostMortemViewModel.triggerCategories {
            vm.toggleTriggerCategory(category)
        }

        #expect(vm.triggerSummary.count == 6)

        // Try to add one more
        vm.toggleTriggerCategory("extra")

        #expect(vm.triggerSummary.count == 6)
    }

    @Test("trigger categories are from allowed set")
    func testTriggerCategoriesValidation() {
        let vm = PostMortemViewModel()

        fillAllRequiredSections(vm: vm)

        vm.addActionItem()
        vm.actionItems[0].action = "Action"
        vm.actionItems[0].category = "spiritual"
        vm.actionItems[0].timelinePoint = "08:00"

        vm.triggerSummary = ["invalid_category"]

        let errors = vm.validateForCompletion()

        #expect(errors.contains(where: { $0.contains("Invalid trigger category") }))
    }

    // MARK: - Action Plan

    @Test("addActionItem adds an empty action")
    func testAddActionItem() {
        let vm = PostMortemViewModel()

        #expect(vm.actionItems.isEmpty)

        vm.addActionItem()

        #expect(vm.actionItems.count == 1)
        #expect(vm.actionItems[0].action.isEmpty)
    }

    @Test("addActionItem respects 10 item limit")
    func testAddActionItemLimit() {
        let vm = PostMortemViewModel()

        for _ in 0..<12 {
            vm.addActionItem()
        }

        #expect(vm.actionItems.count == 10)
    }

    @Test("removeActionItem removes at index")
    func testRemoveActionItem() {
        let vm = PostMortemViewModel()

        vm.addActionItem()
        vm.addActionItem()
        vm.actionItems[0].action = "First action"
        vm.actionItems[1].action = "Second action"

        vm.removeActionItem(at: IndexSet(integer: 0))

        #expect(vm.actionItems.count == 1)
        #expect(vm.actionItems[0].action == "Second action")
    }

    @Test("actionItemCountValid is true for 1-10 items")
    func testActionCountValid() {
        let vm = PostMortemViewModel()

        #expect(!vm.actionItemCountValid)

        vm.addActionItem()
        #expect(vm.actionItemCountValid)

        for _ in 0..<9 {
            vm.addActionItem()
        }
        #expect(vm.actionItemCountValid)
        #expect(vm.actionItems.count == 10)
    }

    @Test("action categories must be from allowed set")
    func testActionCategoriesValidation() {
        let vm = PostMortemViewModel()

        fillAllRequiredSections(vm: vm)

        vm.addActionItem()
        vm.actionItems[0].action = "Action"
        vm.actionItems[0].category = "invalid_category"
        vm.actionItems[0].timelinePoint = "08:00"

        let errors = vm.validateForCompletion()

        #expect(errors.contains(where: { $0.contains("Invalid action category") }))
    }

    // MARK: - FASTER Mapping

    @Test("addFasterMappingEntry adds entry")
    func testAddFasterMapping() {
        let vm = PostMortemViewModel()

        #expect(vm.fasterMapping.isEmpty)

        vm.addFasterMappingEntry()

        #expect(vm.fasterMapping.count == 1)
        #expect(vm.fasterMapping[0].stage.isEmpty)
    }

    @Test("addFasterMappingEntry respects 24 hour limit")
    func testAddFasterMappingLimit() {
        let vm = PostMortemViewModel()

        for _ in 0..<30 {
            vm.addFasterMappingEntry()
        }

        #expect(vm.fasterMapping.count == 24)
    }

    @Test("removeFasterMappingEntry removes at index")
    func testRemoveFasterMapping() {
        let vm = PostMortemViewModel()

        vm.addFasterMappingEntry()
        vm.addFasterMappingEntry()
        vm.fasterMapping[0].stage = "restoration"
        vm.fasterMapping[1].stage = "anxiety"

        vm.removeFasterMappingEntry(at: IndexSet(integer: 0))

        #expect(vm.fasterMapping.count == 1)
        #expect(vm.fasterMapping[0].stage == "anxiety")
    }

    @Test("FASTER stages are from allowed set")
    func testFasterStagesValidation() {
        let vm = PostMortemViewModel()

        fillAllRequiredSections(vm: vm)

        vm.addActionItem()
        vm.actionItems[0].action = "Action"
        vm.actionItems[0].category = "spiritual"
        vm.actionItems[0].timelinePoint = "08:00"

        vm.addFasterMappingEntry()
        vm.fasterMapping[0].stage = "invalid_stage"

        let errors = vm.validateForCompletion()

        #expect(errors.contains(where: { $0.contains("Invalid FASTER stage") }))
    }

    // MARK: - API Conversion

    @Test("toCreateRequest produces correct payload")
    func testToCreateRequest() {
        let vm = PostMortemViewModel()
        vm.eventType = "relapse"
        vm.relapseId = "r_12345"
        vm.addictionId = "a_67890"
        vm.dayBeforeText = "Day before text"
        vm.dayBeforeMoodRating = 6

        let request = vm.toCreateRequest()

        #expect(request.eventType == "relapse")
        #expect(request.relapseId == "r_12345")
        #expect(request.addictionId == "a_67890")
        #expect(request.sections?.dayBefore?.text == "Day before text")
        #expect(request.sections?.dayBefore?.moodRating == 6)
    }

    @Test("toUpdateRequest includes sections")
    func testToUpdateRequest() {
        let vm = PostMortemViewModel()
        vm.morningText = "Morning text"
        vm.morningMoodRating = 4

        let request = vm.toUpdateRequest()

        #expect(request.sections?.morning?.text == "Morning text")
        #expect(request.sections?.morning?.moodRating == 4)
    }

    @Test("toUpdateRequest includes trigger details")
    func testToUpdateRequestWithTriggers() {
        let vm = PostMortemViewModel()
        vm.addTrigger()
        vm.triggerDetails[0].category = "emotional"
        vm.triggerDetails[0].surface = "Stress"
        vm.triggerDetails[0].underlying = "Fear"

        let request = vm.toUpdateRequest()

        #expect(request.triggerDetails?.count == 1)
        #expect(request.triggerDetails?[0].category == "emotional")
        #expect(request.triggerDetails?[0].surface == "Stress")
        #expect(request.triggerDetails?[0].underlying == "Fear")
    }

    @Test("toSectionsPayload includes all filled sections")
    func testToSectionsPayload() {
        let vm = PostMortemViewModel()
        vm.dayBeforeText = "Day before"
        vm.morningText = "Morning"
        vm.buildUpFirstNoticed = "Build up"

        let sections = vm.toSectionsPayload()

        #expect(sections.dayBefore?.text == "Day before")
        #expect(sections.morning?.text == "Morning")
        #expect(sections.buildUp?.firstNoticed == "Build up")
        #expect(sections.actingOut == nil)
    }

    @Test("toSectionsPayload omits empty sections")
    func testToSectionsPayloadOmitsEmpty() {
        let vm = PostMortemViewModel()
        vm.dayBeforeText = ""
        vm.morningText = "Morning"

        let sections = vm.toSectionsPayload()

        #expect(sections.dayBefore == nil)
        #expect(sections.morning?.text == "Morning")
    }

    @Test("toSectionsPayload includes time blocks")
    func testToSectionsPayloadWithTimeBlocks() {
        let vm = PostMortemViewModel()
        vm.timeBlocks.append(TimeBlockEntry(
            period: "morning",
            startTime: "08:00",
            endTime: "10:00",
            activity: "Working",
            location: "Office"
        ))

        let sections = vm.toSectionsPayload()

        #expect(sections.throughoutTheDay?.timeBlocks?.count == 1)
        #expect(sections.throughoutTheDay?.timeBlocks?[0].period == "morning")
        #expect(sections.throughoutTheDay?.timeBlocks?[0].startTime == "08:00")
        #expect(sections.throughoutTheDay?.timeBlocks?[0].activity == "Working")
    }
}

// MARK: - API Model Contract Tests

@Suite("PostMortem API Models")
struct PostMortemAPIModelTests {

    @Test("CreatePostMortemRequest encodes to correct JSON")
    func testEncodeCreateRequest() throws {
        let request = CreatePostMortemRequest(
            timestamp: "2026-03-28T23:00:00Z",
            eventType: "relapse",
            relapseId: "r_98765",
            addictionId: "a_67890",
            sections: PostMortemSectionsPayload(
                dayBefore: DayBeforeSectionPayload(
                    text: "Day before text",
                    moodRating: 4,
                    recoveryPracticesKept: false,
                    unresolvedConflicts: "Argument with spouse"
                ),
                morning: nil,
                throughoutTheDay: nil,
                buildUp: nil,
                actingOut: nil,
                immediatelyAfter: nil
            )
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["timestamp"] as? String == "2026-03-28T23:00:00Z")
        #expect(json?["eventType"] as? String == "relapse")
        #expect(json?["relapseId"] as? String == "r_98765")
        #expect(json?["addictionId"] as? String == "a_67890")
    }

    @Test("PostMortemSummaryData decodes from API response")
    func testDecodeSummaryData() throws {
        let json = """
        {
            "analysisId": "pm_99999",
            "timestamp": "2026-03-28T23:00:00Z",
            "status": "draft",
            "eventType": "relapse",
            "relapseId": "r_98765",
            "addictionId": "a_67890",
            "sectionsCompleted": ["dayBefore"],
            "sectionsRemaining": ["morning", "throughoutTheDay", "buildUp", "actingOut", "immediatelyAfter"],
            "actionItemCount": 0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostMortemSummaryData.self, from: json)

        #expect(decoded.analysisId == "pm_99999")
        #expect(decoded.status == "draft")
        #expect(decoded.eventType == "relapse")
        #expect(decoded.relapseId == "r_98765")
        #expect(decoded.sectionsCompleted?.count == 1)
        #expect(decoded.sectionsRemaining?.count == 5)
        #expect(decoded.actionItemCount == 0)
    }

    @Test("PostMortemAnalysisData decodes full analysis")
    func testDecodeFullAnalysis() throws {
        let json = """
        {
            "analysisId": "pm_99999",
            "timestamp": "2026-03-28T23:00:00Z",
            "status": "complete",
            "eventType": "relapse",
            "relapseId": "r_98765",
            "addictionId": "a_67890",
            "completedAt": "2026-03-29T10:00:00Z",
            "message": "Thank you for your honesty and courage."
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostMortemAnalysisData.self, from: json)

        #expect(decoded.analysisId == "pm_99999")
        #expect(decoded.status == "complete")
        #expect(decoded.completedAt == "2026-03-29T10:00:00Z")
        #expect(decoded.message == "Thank you for your honesty and courage.")
    }

    @Test("PostMortemInsightsData decodes insights response")
    func testDecodeInsightsData() throws {
        let json = """
        {
            "totalAnalyses": 5,
            "commonTriggers": [
                {
                    "category": "digital",
                    "frequency": 4,
                    "percentage": 80.0
                }
            ],
            "commonFasterStageAtBreak": {
                "stage": "exhausted",
                "frequency": 3,
                "percentage": 60.0
            },
            "commonTimeOfDay": {
                "period": "evening",
                "frequency": 4,
                "percentage": 80.0
            }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostMortemInsightsData.self, from: json)

        #expect(decoded.totalAnalyses == 5)
        #expect(decoded.commonTriggers?.count == 1)
        #expect(decoded.commonTriggers?[0].category == "digital")
        #expect(decoded.commonTriggers?[0].frequency == 4)
        #expect(decoded.commonFasterStageAtBreak?.stage == "exhausted")
        #expect(decoded.commonTimeOfDay?.period == "evening")
    }

    @Test("PostMortemSectionsPayload round-trips encode/decode")
    func testSectionsRoundTrip() throws {
        let original = PostMortemSectionsPayload(
            dayBefore: DayBeforeSectionPayload(
                text: "Day before",
                moodRating: 5,
                recoveryPracticesKept: true,
                unresolvedConflicts: nil
            ),
            morning: MorningSectionPayload(
                text: "Morning",
                moodRating: 6,
                morningCommitmentCompleted: false,
                affirmationViewed: true,
                autoPopulated: nil
            ),
            throughoutTheDay: nil,
            buildUp: nil,
            actingOut: nil,
            immediatelyAfter: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PostMortemSectionsPayload.self, from: data)

        #expect(decoded.dayBefore?.text == "Day before")
        #expect(decoded.dayBefore?.moodRating == 5)
        #expect(decoded.morning?.text == "Morning")
        #expect(decoded.morning?.moodRating == 6)
    }

    @Test("TriggerDetailPayload encodes optional fields correctly")
    func testTriggerDetailOptionals() throws {
        let trigger = TriggerDetailPayload(
            category: "emotional",
            surface: "Stress",
            underlying: nil,
            coreWound: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(trigger)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["category"] as? String == "emotional")
        #expect(json?["surface"] as? String == "Stress")
        #expect(json?["underlying"] == nil)
        #expect(json?["coreWound"] == nil)
    }

    @Test("TriggerDetailPayload decodes with all fields")
    func testTriggerDetailFull() throws {
        let json = """
        {
            "category": "emotional",
            "surface": "Boredom",
            "underlying": "Loneliness",
            "coreWound": "Fear of being unlovable"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TriggerDetailPayload.self, from: json)

        #expect(decoded.category == "emotional")
        #expect(decoded.surface == "Boredom")
        #expect(decoded.underlying == "Loneliness")
        #expect(decoded.coreWound == "Fear of being unlovable")
    }

    @Test("ActionPlanItemPayload encodes all fields")
    func testActionPlanEncoding() throws {
        let action = ActionPlanItemPayload(
            actionId: "ap_12345",
            timelinePoint: "08:00",
            action: "Call sponsor",
            category: "relational",
            convertedToCommitmentId: nil,
            convertedToGoalId: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(action)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["actionId"] as? String == "ap_12345")
        #expect(json?["timelinePoint"] as? String == "08:00")
        #expect(json?["action"] as? String == "Call sponsor")
        #expect(json?["category"] as? String == "relational")
    }

    @Test("SharePostMortemRequest encodes shares array")
    func testShareRequestEncoding() throws {
        let request = SharePostMortemRequest(
            shares: [
                SharePostMortemRequest.ShareEntry(
                    contactId: "c_99999",
                    shareType: "full"
                ),
                SharePostMortemRequest.ShareEntry(
                    contactId: "c_88888",
                    shareType: "summary"
                )
            ]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let shares = json?["shares"] as? [[String: Any]]

        #expect(shares?.count == 2)
        #expect(shares?[0]["contactId"] as? String == "c_99999")
        #expect(shares?[0]["shareType"] as? String == "full")
        #expect(shares?[1]["shareType"] as? String == "summary")
    }

    @Test("UpdatePostMortemRequest encodes only non-nil fields")
    func testUpdateRequestPartialEncoding() throws {
        let request = UpdatePostMortemRequest(
            sections: nil,
            triggerSummary: ["emotional", "digital"],
            triggerDetails: nil,
            fasterMapping: nil,
            actionPlan: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["sections"] == nil)
        #expect((json?["triggerSummary"] as? [String])?.count == 2)
        #expect(json?["triggerDetails"] == nil)
    }

    @Test("TimeBlockPayload decodes with all fields")
    func testTimeBlockDecoding() throws {
        let json = """
        {
            "period": "morning",
            "startTime": "08:00",
            "endTime": "10:00",
            "activity": "Working",
            "location": "Office",
            "company": "Alone",
            "thoughts": "Feeling stressed",
            "feelings": "Anxious",
            "warningSigns": ["speeding-up", "ticked-off"]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimeBlockPayload.self, from: json)

        #expect(decoded.period == "morning")
        #expect(decoded.startTime == "08:00")
        #expect(decoded.activity == "Working")
        #expect(decoded.warningSigns?.count == 2)
    }

    @Test("FreeFormEntryPayload round-trips")
    func testFreeFormEntryRoundTrip() throws {
        let original = FreeFormEntryPayload(
            time: "14:30",
            text: "Noticed craving"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FreeFormEntryPayload.self, from: data)

        #expect(decoded.time == "14:30")
        #expect(decoded.text == "Noticed craving")
    }

    @Test("FasterMappingEntryPayload encodes correctly")
    func testFasterMappingEncoding() throws {
        let entry = FasterMappingEntryPayload(
            timeOfDay: "19:00",
            stage: "exhausted"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        #expect(json?["timeOfDay"] as? String == "19:00")
        #expect(json?["stage"] as? String == "exhausted")
    }

    @Test("BuildUpSectionPayload with nested structures")
    func testBuildUpSectionNested() throws {
        let section = BuildUpSectionPayload(
            firstNoticed: "Around 6pm",
            triggers: [
                TriggerDetailPayload(category: "emotional", surface: "Stress", underlying: nil, coreWound: nil)
            ],
            responseToWarnings: "Ignored them",
            missedHelpOpportunities: [
                MissedHelpOpportunityPayload(description: "Could have called sponsor", reason: "Felt ashamed")
            ],
            decisionPoints: [
                DecisionPointPayload(
                    timeOfDay: "18:30",
                    description: "Decided to go home alone",
                    couldHaveDone: "Call a friend",
                    insteadDid: "Isolated"
                )
            ]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(section)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BuildUpSectionPayload.self, from: data)

        #expect(decoded.firstNoticed == "Around 6pm")
        #expect(decoded.triggers?.count == 1)
        #expect(decoded.missedHelpOpportunities?.count == 1)
        #expect(decoded.decisionPoints?.count == 1)
    }

    @Test("ImmediatelyAfterSectionPayload with feelings wheel")
    func testImmediatelyAfterWithFeelingsWheel() throws {
        let section = ImmediatelyAfterSectionPayload(
            feelings: ["shame", "guilt"],
            feelingsWheelSelections: ["sad/guilty", "fearful/anxious"],
            whatDidNext: "Went to bed",
            reachedOut: true,
            reachedOutTo: "c_12345",
            wishDoneDifferently: "Would have called sponsor immediately"
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(section)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ImmediatelyAfterSectionPayload.self, from: data)

        #expect(decoded.feelings?.count == 2)
        #expect(decoded.feelingsWheelSelections?.count == 2)
        #expect(decoded.reachedOut == true)
        #expect(decoded.reachedOutTo == "c_12345")
    }
}

// MARK: - Helper Functions

private func fillAllRequiredSections(vm: PostMortemViewModel) {
    vm.dayBeforeText = "Day before text"
    vm.morningText = "Morning text"
    vm.timeBlocks.append(TimeBlockEntry(period: "morning"))
    vm.buildUpFirstNoticed = "Build up text"
    vm.actingOutDescription = "Acting out text"
    vm.afterWhatDidNext = "What I did next"
}
