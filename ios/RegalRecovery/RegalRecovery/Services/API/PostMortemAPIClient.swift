import Foundation

// MARK: - Post-Mortem API Models (camelCase per OpenAPI spec)

/// Event types for post-mortem analysis.
enum PostMortemEventType: String, Codable, Sendable {
    case relapse = "relapse"
    case nearMiss = "near-miss"
    case combined = "combined"
}

/// Status of a post-mortem analysis.
enum PostMortemStatus: String, Codable, Sendable {
    case draft = "draft"
    case complete = "complete"
}

/// Trigger categories matching Urge Logging.
enum TriggerCategory: String, Codable, Sendable {
    case emotional, environmental, relational, physical, digital, spiritual
}

/// FASTER Scale stages.
enum FASTERStage: String, Codable, Sendable {
    case restoration = "restoration"
    case forgettingPriorities = "forgetting-priorities"
    case anxiety = "anxiety"
    case speedingUp = "speeding-up"
    case tickedOff = "ticked-off"
    case exhausted = "exhausted"
    case relapse = "relapse"
}

/// Action plan categories.
enum ActionCategory: String, Codable, Sendable {
    case spiritual, relational, emotional, physical, practical
}

/// Share types for sharing post-mortems.
enum ShareType: String, Codable, Sendable {
    case full = "full"
    case summary = "summary"
}

/// Time block periods.
enum TimePeriod: String, Codable, Sendable {
    case morning, midday, afternoon, evening
}

// MARK: - Request Models

/// Request to create a post-mortem analysis.
struct CreatePostMortemRequest: Codable, Sendable {
    let timestamp: String
    let eventType: String
    let relapseId: String?
    let addictionId: String?
    let sections: PostMortemSectionsData?
}

/// Request to update a post-mortem analysis (merge patch).
struct UpdatePostMortemRequest: Codable, Sendable {
    let sections: PostMortemSectionsData?
    let triggerSummary: [String]?
    let triggerDetails: [TriggerDetailData]?
    let fasterMapping: [FasterMappingEntryData]?
    let actionPlan: [ActionPlanItemData]?
}

/// Request to share a post-mortem.
struct SharePostMortemRequestBody: Codable, Sendable {
    let shares: [ShareEntryData]
}

/// A single share entry.
struct ShareEntryData: Codable, Sendable {
    let contactId: String
    let shareType: String
}

/// Request to convert an action item.
struct ConvertActionItemRequestBody: Codable, Sendable {
    let targetType: String
    let title: String
    let frequency: String?
    let targetDate: String?
}

// MARK: - Response Models

/// Summary view of a post-mortem (used in list responses).
struct PostMortemSummaryData: Codable, Sendable {
    let analysisId: String
    let timestamp: String?
    let status: String
    let eventType: String
    let relapseId: String?
    let addictionId: String?
    let sectionsCompleted: [String]?
    let sectionsRemaining: [String]?
    let triggerSummary: [String]?
    let actionItemCount: Int?
    let completedAt: String?
}

/// Full post-mortem analysis detail.
struct PostMortemAnalysisData: Codable, Sendable {
    let analysisId: String
    let timestamp: String?
    let status: String
    let eventType: String
    let relapseId: String?
    let addictionId: String?
    let sections: PostMortemSectionsData?
    let triggerSummary: [String]?
    let triggerDetails: [TriggerDetailData]?
    let fasterMapping: [FasterMappingEntryData]?
    let actionPlan: [ActionPlanItemData]?
    let sharing: SharingStatusData?
    let linkedEntities: LinkedEntitiesData?
    let completedAt: String?
    let message: String?
}

/// The six walkthrough sections.
struct PostMortemSectionsData: Codable, Sendable {
    let dayBefore: DayBeforeSectionData?
    let morning: MorningSectionData?
    let throughoutTheDay: ThroughoutTheDaySectionData?
    let buildUp: BuildUpSectionData?
    let actingOut: ActingOutSectionData?
    let immediatelyAfter: ImmediatelyAfterSectionData?
}

struct DayBeforeSectionData: Codable, Sendable {
    let text: String?
    let moodRating: Int?
    let recoveryPracticesKept: Bool?
    let unresolvedConflicts: String?
}

struct MorningSectionData: Codable, Sendable {
    let text: String?
    let moodRating: Int?
    let morningCommitmentCompleted: Bool?
    let affirmationViewed: Bool?
    let autoPopulated: AutoPopulatedSectionData?
}

struct AutoPopulatedSectionData: Codable, Sendable {
    let morningCommitmentCompleted: Bool?
    let moodRating: Int?
    let affirmationViewed: Bool?
}

struct ThroughoutTheDaySectionData: Codable, Sendable {
    let timeBlocks: [TimeBlockData]?
    let freeFormEntries: [FreeFormEntryData]?
}

struct TimeBlockData: Codable, Sendable {
    let period: String
    let startTime: String
    let endTime: String
    let activity: String?
    let location: String?
    let company: String?
    let thoughts: String?
    let feelings: String?
    let warningSigns: [String]?
}

struct FreeFormEntryData: Codable, Sendable {
    let time: String
    let text: String
}

struct BuildUpSectionData: Codable, Sendable {
    let firstNoticed: String?
    let triggers: [TriggerDetailData]?
    let responseToWarnings: String?
    let missedHelpOpportunities: [MissedHelpOpportunityData]?
    let decisionPoints: [DecisionPointData]?
}

struct MissedHelpOpportunityData: Codable, Sendable {
    let description: String
    let reason: String
}

struct DecisionPointData: Codable, Sendable {
    let timeOfDay: String
    let description: String?
    let couldHaveDone: String
    let insteadDid: String
}

struct ActingOutSectionData: Codable, Sendable {
    let description: String?
    let addictionId: String?
    let durationMinutes: Int?
    let linkedRelapseId: String?
}

struct ImmediatelyAfterSectionData: Codable, Sendable {
    let feelings: [String]?
    let feelingsWheelSelections: [String]?
    let whatDidNext: String?
    let reachedOut: Bool?
    let reachedOutTo: String?
    let wishDoneDifferently: String?
}

struct TriggerDetailData: Codable, Sendable {
    let category: String
    let surface: String
    let underlying: String?
    let coreWound: String?
}

struct FasterMappingEntryData: Codable, Sendable {
    let timeOfDay: String
    let stage: String
}

struct ActionPlanItemData: Codable, Sendable {
    let actionId: String?
    let timelinePoint: String?
    let action: String
    let category: String
    let convertedToCommitmentId: String?
    let convertedToGoalId: String?
}

struct SharingStatusData: Codable, Sendable {
    let isShared: Bool
    let sharedWith: [SharedWithEntryData]?
}

struct SharedWithEntryData: Codable, Sendable {
    let contactId: String
    let shareType: String
    let sharedAt: String?
}

struct LinkedEntitiesData: Codable, Sendable {
    let relapseId: String?
    let urgeLogIds: [String]?
    let fasterEntryIds: [String]?
    let checkInIds: [String]?
}

/// Cross-analysis insights.
struct PostMortemInsightsData: Codable, Sendable {
    let totalAnalyses: Int
    let commonTriggers: [TriggerFrequencyData]?
    let commonFasterStageAtBreak: StageFrequencyData?
    let commonTimeOfDay: TimeOfDayFrequencyData?
    let recurringDecisionPoints: [DecisionPointThemeData]?
    let deepTriggerPatterns: [TriggerDetailData]?
}

struct TriggerFrequencyData: Codable, Sendable {
    let category: String
    let frequency: Int
    let percentage: Double
}

struct StageFrequencyData: Codable, Sendable {
    let stage: String
    let frequency: Int
    let percentage: Double
}

struct TimeOfDayFrequencyData: Codable, Sendable {
    let period: String
    let frequency: Int
    let percentage: Double
}

struct DecisionPointThemeData: Codable, Sendable {
    let theme: String
    let frequency: Int
}

/// Conversion result data.
struct ConvertActionItemResultData: Codable, Sendable {
    let actionId: String
    let targetType: String
    let createdEntityId: String
}

// MARK: - Compassionate Messages

enum PostMortemMessages {
    static let opening = "A relapse is painful, but it is also an opportunity to learn. This process will help you understand what happened so you can build a stronger foundation going forward."
    static let closing = "Thank you for your honesty and courage. Every insight you have gained here is a step toward lasting freedom."
    static let reminder = "Taking a few minutes to reflect on what happened can strengthen your recovery. Would you like to complete a post-mortem?"
}
