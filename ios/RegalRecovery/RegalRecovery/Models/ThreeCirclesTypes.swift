import Foundation

// MARK: - Circle Type

/// Which of the three circles an item belongs to.
///
/// - inner: Hard boundaries, bottom lines (behaviors to completely avoid)
/// - middle: Warning signs, slippery behaviors (not failure, but signals)
/// - outer: Healthy behaviors, self-care, recovery practices
enum CircleType: String, Codable, Sendable, CaseIterable {
    case inner
    case middle
    case outer

    var displayName: String {
        switch self {
        case .inner: return "Inner Circle"
        case .middle: return "Middle Circle"
        case .outer: return "Outer Circle"
        }
    }
}

// MARK: - Circle Set Status

/// Lifecycle status of a circle set.
///
/// - draft: Not yet committed, not used for check-ins
/// - active: Committed, used for daily check-ins and pattern tracking
/// - archived: Soft-deleted, version history preserved
enum CircleSetStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case active
    case archived

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .archived: return "Archived"
        }
    }
}

// MARK: - Recovery Area

/// Primary recovery area a circle set addresses.
enum RecoveryArea: String, Codable, Sendable, CaseIterable {
    case sexPornography = "sex-pornography"
    case alcohol
    case drugs
    case gambling
    case foodEating = "food-eating"
    case internetTechnology = "internet-technology"
    case work
    case shoppingDebt = "shopping-debt"
    case loveRelationships = "love-relationships"
    case other

    var displayName: String {
        switch self {
        case .sexPornography: return "Sex / Pornography"
        case .alcohol: return "Alcohol"
        case .drugs: return "Drugs"
        case .gambling: return "Gambling"
        case .foodEating: return "Food / Eating"
        case .internetTechnology: return "Internet / Technology"
        case .work: return "Work"
        case .shoppingDebt: return "Shopping / Debt"
        case .loveRelationships: return "Love / Relationships"
        case .other: return "Other"
        }
    }
}

// MARK: - Framework Preference

/// Recovery fellowship or framework (affects terminology).
enum FrameworkPreference: String, Codable, Sendable, CaseIterable {
    case SAA
    case SLAA
    case AA
    case NA
    case SMART
    case OA
    case GA
    case DA
    case CoDA
    case ITAA
    case WA
    case other
    case none

    var displayName: String {
        switch self {
        case .SAA: return "SAA"
        case .SLAA: return "SLAA"
        case .AA: return "AA"
        case .NA: return "NA"
        case .SMART: return "SMART Recovery"
        case .OA: return "OA"
        case .GA: return "GA"
        case .DA: return "DA"
        case .CoDA: return "CoDA"
        case .ITAA: return "ITAA"
        case .WA: return "WA"
        case .other: return "Other"
        case .none: return "None"
        }
    }
}

// MARK: - Circle Item Source

/// Origin of a circle item.
enum CircleItemSource: String, Codable, Sendable, CaseIterable {
    case user
    case template
    case starterPack
}

// MARK: - Starter Pack Variant

/// Variant of a starter pack.
enum StarterPackVariant: String, Codable, Sendable, CaseIterable {
    case secular
    case faithBased = "faith-based"
    case lgbtqAffirming = "lgbtq-affirming"

    var displayName: String {
        switch self {
        case .secular: return "Secular"
        case .faithBased: return "Faith-Based"
        case .lgbtqAffirming: return "LGBTQ+-Affirming"
        }
    }
}

// MARK: - Onboarding Mode

/// Mode for the first-time circle creation onboarding flow.
enum OnboardingMode: String, Codable, Sendable, CaseIterable {
    case guided
    case starterPack
    case express

    var displayName: String {
        switch self {
        case .guided: return "Guided"
        case .starterPack: return "Starter Pack"
        case .express: return "Express"
        }
    }
}

// MARK: - Onboarding Step

/// Steps in the onboarding flow.
enum OnboardingStep: String, Codable, Sendable, CaseIterable {
    case recoveryArea
    case framework
    case innerCircle
    case outerCircle
    case middleCircle
    case review
}

// MARK: - Change Type (Version History)

/// Type of change that created a version snapshot.
enum ChangeType: String, Codable, Sendable, CaseIterable {
    case itemAdded = "item-added"
    case itemRemoved = "item-removed"
    case itemMoved = "item-moved"
    case itemUpdated = "item-updated"
    case fullReplace = "full-replace"
    case starterPackApplied = "starter-pack-applied"
    case versionRestored = "version-restored"
    case committed
}

// MARK: - Insight Type

/// Categories of pattern insights.
enum InsightType: String, Codable, Sendable, CaseIterable {
    case dayOfWeek
    case time
    case trigger
    case protective
    case sleep
    case seeds
}

// MARK: - Insight Confidence

/// Strength of correlation for a pattern insight.
enum InsightConfidence: String, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high
}

// MARK: - Review Status / Step

/// Steps in the quarterly review flow.
enum ReviewStep: String, Codable, Sendable, CaseIterable {
    case innerReview
    case outerReview
    case middleReview
    case finalReview
}

// MARK: - Drift Alert Status

/// Filter status for drift alerts.
enum DriftAlertStatus: String, Codable, Sendable, CaseIterable {
    case active
    case dismissed
    case all
}

// MARK: - Timeline Period

/// Time window for pattern timeline.
enum TimelinePeriod: String, Codable, Sendable, CaseIterable {
    case sevenDays = "7d"
    case thirtyDays = "30d"
    case ninetyDays = "90d"
    case oneYear = "1y"
    case all
}

// MARK: - Summary Period

/// Period for pattern summaries.
enum SummaryPeriod: String, Codable, Sendable, CaseIterable {
    case week
    case month
}

// MARK: - Mood Trend

/// Mood trend direction over a summary period.
enum MoodTrend: String, Codable, Sendable {
    case improving
    case stable
    case declining
    case insufficientData = "insufficient-data"
}

// MARK: - Share Expiry

/// Expiration options for share links.
enum ShareExpiry: String, Codable, Sendable, CaseIterable {
    case twentyFourHours = "24h"
    case sevenDays = "7d"
    case never
}

// MARK: - Share Permission

/// Permissions for share links.
enum SharePermission: String, Codable, Sendable, CaseIterable {
    case view
    case comment
}

// MARK: - Commit Option

/// Options when completing onboarding.
enum CommitOption: String, Codable, Sendable, CaseIterable {
    case commitNow
    case draft
    case draftNoShare
}

// MARK: - Merge Strategy

/// Strategy for applying a starter pack to an existing set.
enum MergeStrategy: String, Codable, Sendable, CaseIterable {
    case replace
    case merge
}

// MARK: - Core Models

/// A circle set containing inner, middle, and outer circles.
struct CircleSet: Codable, Sendable, Identifiable {
    let setId: String
    let userId: String
    let name: String
    let recoveryArea: RecoveryArea
    let frameworkPreference: FrameworkPreference?
    let status: CircleSetStatus
    let innerCircle: [CircleItem]
    let middleCircle: [CircleItem]
    let outerCircle: [CircleItem]
    let versionNumber: Int?
    let createdAt: Date
    let modifiedAt: Date
    let committedAt: Date?

    var id: String { setId }
}

/// Item flags (e.g., uncertain marker for sponsor review).
struct CircleItemFlags: Codable, Sendable, Hashable {
    let uncertain: Bool?
}

/// A single behavior, warning sign, or healthy practice within a circle.
struct CircleItem: Codable, Sendable, Identifiable, Hashable {
    let itemId: String
    let circle: CircleType
    let behaviorName: String
    let notes: String?
    let specificityDetail: String?
    let category: String?
    let source: CircleItemSource?
    let flags: CircleItemFlags?
    let createdAt: Date
    let modifiedAt: Date?

    var id: String { itemId }

    func hash(into hasher: inout Hasher) {
        hasher.combine(itemId)
    }

    static func == (lhs: CircleItem, rhs: CircleItem) -> Bool {
        lhs.itemId == rhs.itemId
    }
}

/// A version snapshot of a circle set.
struct CircleSetVersion: Codable, Sendable {
    let versionNumber: Int
    let snapshot: CircleSetSnapshot?
    let changeNote: String?
    let changedAt: Date
}

/// Snapshot of circle items at a specific version.
struct CircleSetSnapshot: Codable, Sendable {
    let innerCircle: [CircleItem]
    let middleCircle: [CircleItem]
    let outerCircle: [CircleItem]
}

/// A template suggestion for a circle item.
struct Template: Codable, Sendable, Identifiable {
    let templateId: String
    let recoveryArea: RecoveryArea
    let circle: CircleType
    let behaviorName: String
    let rationale: String?
    let specificityGuidance: String?
    let category: String?
    let frameworkVariant: String?
    let version: Int?

    var id: String { templateId }
}

/// A pre-built complete circle set for quick start.
struct StarterPack: Codable, Sendable, Identifiable {
    let packId: String
    let name: String
    let description: String?
    let recoveryArea: RecoveryArea
    let variant: StarterPackVariant
    let innerCircle: [StarterPackItem]?
    let middleCircle: [StarterPackItem]?
    let outerCircle: [StarterPackItem]?
    let clinicalReviewer: String?
    let communityReviewer: String?
    let version: Int?

    var id: String { packId }
}

/// An item within a starter pack.
struct StarterPackItem: Codable, Sendable {
    let behaviorName: String
    let rationale: String?
    let category: String?
}

/// Onboarding flow state for first-time circle creation.
struct OnboardingFlow: Codable, Sendable, Identifiable {
    let flowId: String
    let userId: String?
    let mode: OnboardingMode
    let currentStep: OnboardingStep?
    let recoveryArea: RecoveryArea?
    let frameworkPreference: FrameworkPreference?
    let emotionalCheckinScore: Int?
    let progress: [String: AnyCodable]?
    let createdAt: Date?
    let lastUpdatedAt: Date?

    var id: String { flowId }
}

/// A sponsor or therapist comment on a circle item.
struct SponsorComment: Codable, Sendable, Identifiable {
    let commentId: String
    let itemId: String
    let text: String
    let commenterName: String?
    let createdAt: Date

    var id: String { commentId }
}

/// A single day entry in the pattern timeline.
struct TimelineEntry: Codable, Sendable {
    let date: String
    let circle: CircleType?
    let checkinDetails: CheckinDetails?

    struct CheckinDetails: Codable, Sendable {
        let mood: Int?
        let urgeIntensity: Int?
        let notes: String?
    }
}

/// Summary of circle distribution over a period.
struct TimelineSummary: Codable, Sendable {
    let outerDays: Int
    let middleDays: Int
    let innerDays: Int
    let noCheckinDays: Int
    let currentConsecutiveOuterDays: Int?
}

/// An auto-generated insight based on check-in data.
struct PatternInsight: Codable, Sendable, Identifiable {
    let insightId: String
    let type: InsightType
    let description: String
    let confidence: InsightConfidence?
    let actionSuggestion: String?
    let dataPoints: Int?
    let detectedAt: Date?

    var id: String { insightId }
}

/// A middle circle drift alert.
struct DriftAlert: Codable, Sendable, Identifiable {
    let alertId: String
    let windowStart: String
    let windowEnd: String
    let middleCircleDays: Int
    let message: String?
    let dismissed: Bool
    let createdAt: Date?

    var id: String { alertId }
}

/// Pattern summary for a week or month.
struct PatternSummary: Codable, Sendable {
    let period: SummaryPeriod
    let startDate: String
    let endDate: String
    let outerDays: Int
    let middleDays: Int
    let innerDays: Int
    let noCheckinDays: Int
    let insights: [PatternInsight]?
    let moodTrend: MoodTrend?
    let framingMessage: String?
}

/// A quarterly review session.
struct Review: Codable, Sendable, Identifiable {
    let reviewId: String
    let setId: String
    let currentStep: ReviewStep?
    let reflections: [String: AnyCodable]?
    let changesApplied: [String]?
    let completed: Bool
    let summary: String?
    let startedAt: Date
    let completedAt: Date?
    let nextReviewDue: String?

    var id: String { reviewId }
}

// MARK: - Version List Item (summary, not full snapshot)

/// Summary entry in the version list (no full snapshot).
struct VersionListItem: Codable, Sendable {
    let versionNumber: Int
    let changedAt: Date
    let changeNote: String?
    let innerCount: Int?
    let middleCount: Int?
    let outerCount: Int?
}

/// Summary entry in the version history embedded in circle set detail.
struct VersionHistoryEntry: Codable, Sendable {
    let versionNumber: Int
    let changedAt: Date
    let changeNote: String?
}

// MARK: - Circle Set Detail (extended with version history and comments)

/// Extended circle set data returned by GET /sets/{setId}.
struct CircleSetDetail: Codable, Sendable, Identifiable {
    let setId: String
    let userId: String
    let name: String
    let recoveryArea: RecoveryArea
    let frameworkPreference: FrameworkPreference?
    let status: CircleSetStatus
    let innerCircle: [CircleItem]
    let middleCircle: [CircleItem]
    let outerCircle: [CircleItem]
    let versionNumber: Int?
    let createdAt: Date
    let modifiedAt: Date
    let committedAt: Date?
    let versionHistory: [VersionHistoryEntry]?
    let sponsorCommentCount: Int?

    var id: String { setId }
}

// MARK: - Starter Pack List Item (summary)

/// Summary entry in the starter pack list.
struct StarterPackListItem: Codable, Sendable, Identifiable {
    let packId: String
    let name: String
    let description: String?
    let variant: StarterPackVariant?
    let itemCounts: ItemCounts?

    struct ItemCounts: Codable, Sendable {
        let inner: Int?
        let middle: Int?
        let outer: Int?
    }

    var id: String { packId }
}

// MARK: - Review List Item (summary)

/// Summary entry in the review list.
struct ReviewListItem: Codable, Sendable, Identifiable {
    let reviewId: String
    let startedAt: Date
    let completedAt: Date?
    let completed: Bool

    var id: String { reviewId }
}

// MARK: - Shared Circle Set View

/// Read-only view of a shared circle set (public, no auth).
struct SharedCircleSetView: Codable, Sendable {
    let name: String
    let recoveryArea: RecoveryArea
    let innerCircle: [CircleItem]
    let middleCircle: [CircleItem]
    let outerCircle: [CircleItem]
    let sharedAt: Date
    let expiresAt: Date?
    let canComment: Bool?
}

// MARK: - Share Link Data

/// Data returned when generating a share link.
struct ShareLinkData: Codable, Sendable {
    let shareCode: String
    let shareLink: String
    let expiresAt: Date?
    let permissions: [String]?
}

// MARK: - Onboarding Completion Data

/// Data returned when completing onboarding.
struct OnboardingCompletionData: Codable, Sendable {
    let circleSet: CircleSet
    let sponsorShareLink: String?
    let sponsorShareCode: String?
}

// MARK: - Request Models

/// Request body for creating a new circle set.
struct CreateCircleSetRequest: Codable, Sendable {
    let name: String
    let recoveryArea: RecoveryArea
    let frameworkPreference: FrameworkPreference?
    let status: CircleSetStatus?
    let innerCircle: [CreateCircleItemInline]?
    let middleCircle: [CreateCircleItemInline]?
    let outerCircle: [CreateCircleItemInline]?

    /// Inline item for circle set creation (minimal fields).
    struct CreateCircleItemInline: Codable, Sendable {
        let behaviorName: String
        let notes: String?
        let specificityDetail: String?
        let category: String?
    }
}

/// Request body for full replace of a circle set (PUT).
struct ReplaceCircleSetRequest: Codable, Sendable {
    let name: String?
    let frameworkPreference: FrameworkPreference?
    let innerCircle: [[String: AnyCodable]]
    let middleCircle: [[String: AnyCodable]]
    let outerCircle: [[String: AnyCodable]]
    let changeNote: String?
}

/// Request body for partial update of a circle set (PATCH).
struct UpdateCircleSetRequest: Codable, Sendable {
    let name: String?
    let frameworkPreference: FrameworkPreference?
    let status: CircleSetStatus?

    init(
        name: String? = nil,
        frameworkPreference: FrameworkPreference? = nil,
        status: CircleSetStatus? = nil
    ) {
        self.name = name
        self.frameworkPreference = frameworkPreference
        self.status = status
    }
}

/// Request body for adding an item to a circle.
struct CreateCircleItemRequest: Codable, Sendable {
    let circle: CircleType
    let behaviorName: String
    let notes: String?
    let specificityDetail: String?
    let category: String?
    let flags: CircleItemFlags?

    init(
        circle: CircleType,
        behaviorName: String,
        notes: String? = nil,
        specificityDetail: String? = nil,
        category: String? = nil,
        flags: CircleItemFlags? = nil
    ) {
        self.circle = circle
        self.behaviorName = behaviorName
        self.notes = notes
        self.specificityDetail = specificityDetail
        self.category = category
        self.flags = flags
    }
}

/// Request body for updating a circle item (PUT).
struct UpdateCircleItemRequest: Codable, Sendable {
    let behaviorName: String?
    let notes: String?
    let specificityDetail: String?
    let category: String?
    let flags: CircleItemFlags?

    init(
        behaviorName: String? = nil,
        notes: String? = nil,
        specificityDetail: String? = nil,
        category: String? = nil,
        flags: CircleItemFlags? = nil
    ) {
        self.behaviorName = behaviorName
        self.notes = notes
        self.specificityDetail = specificityDetail
        self.category = category
        self.flags = flags
    }
}

/// Request body for moving an item between circles.
struct MoveItemRequest: Codable, Sendable {
    let targetCircle: CircleType
    let changeNote: String?

    init(targetCircle: CircleType, changeNote: String? = nil) {
        self.targetCircle = targetCircle
        self.changeNote = changeNote
    }
}

/// Request body for committing a draft circle set.
struct CommitCircleSetRequest: Codable, Sendable {
    let changeNote: String?

    init(changeNote: String? = nil) {
        self.changeNote = changeNote
    }
}

/// Request body for applying a starter pack to a circle set.
struct ApplyStarterPackRequest: Codable, Sendable {
    let packId: String
    let mergeStrategy: MergeStrategy?

    init(packId: String, mergeStrategy: MergeStrategy? = nil) {
        self.packId = packId
        self.mergeStrategy = mergeStrategy
    }
}

/// Request body for starting onboarding.
struct StartOnboardingRequest: Codable, Sendable {
    let mode: OnboardingMode?
    let emotionalCheckinScore: Int?

    init(mode: OnboardingMode? = nil, emotionalCheckinScore: Int? = nil) {
        self.mode = mode
        self.emotionalCheckinScore = emotionalCheckinScore
    }
}

/// Request body for updating onboarding progress (PATCH).
struct UpdateOnboardingRequest: Codable, Sendable {
    let currentStep: OnboardingStep?
    let recoveryArea: RecoveryArea?
    let frameworkPreference: FrameworkPreference?
    let progress: [String: AnyCodable]?
    let mode: OnboardingMode?

    init(
        currentStep: OnboardingStep? = nil,
        recoveryArea: RecoveryArea? = nil,
        frameworkPreference: FrameworkPreference? = nil,
        progress: [String: AnyCodable]? = nil,
        mode: OnboardingMode? = nil
    ) {
        self.currentStep = currentStep
        self.recoveryArea = recoveryArea
        self.frameworkPreference = frameworkPreference
        self.progress = progress
        self.mode = mode
    }
}

/// Request body for completing onboarding.
struct CompleteOnboardingRequest: Codable, Sendable {
    let commitOption: CommitOption
    let changeNote: String?
    let generateSponsorShare: Bool?

    init(commitOption: CommitOption, changeNote: String? = nil, generateSponsorShare: Bool? = nil) {
        self.commitOption = commitOption
        self.changeNote = changeNote
        self.generateSponsorShare = generateSponsorShare
    }
}

/// Request body for generating a share link.
struct CreateShareLinkRequest: Codable, Sendable {
    let expiresIn: ShareExpiry?
    let permissions: [SharePermission]?

    init(expiresIn: ShareExpiry? = nil, permissions: [SharePermission]? = nil) {
        self.expiresIn = expiresIn
        self.permissions = permissions
    }
}

/// Request body for adding a sponsor comment.
struct AddSponsorCommentRequest: Codable, Sendable {
    let itemId: String
    let text: String
    let commenterName: String?

    init(itemId: String, text: String, commenterName: String? = nil) {
        self.itemId = itemId
        self.text = text
        self.commenterName = commenterName
    }
}

/// Request body for restoring a version.
struct RestoreVersionRequest: Codable, Sendable {
    let changeNote: String?

    init(changeNote: String? = nil) {
        self.changeNote = changeNote
    }
}

/// Request body for starting a quarterly review.
struct StartReviewRequest: Codable, Sendable {
    let setId: String
}

/// Request body for updating review progress (PATCH).
struct UpdateReviewRequest: Codable, Sendable {
    let currentStep: ReviewStep?
    let reflections: [String: AnyCodable]?
    let changesApplied: [String]?

    init(
        currentStep: ReviewStep? = nil,
        reflections: [String: AnyCodable]? = nil,
        changesApplied: [String]? = nil
    ) {
        self.currentStep = currentStep
        self.reflections = reflections
        self.changesApplied = changesApplied
    }
}

/// Request body for completing a quarterly review.
struct CompleteReviewRequest: Codable, Sendable {
    let summary: String?

    init(summary: String? = nil) {
        self.summary = summary
    }
}

// MARK: - Response Envelopes

/// Generic data response envelope matching Siemens pattern.
struct ThreeCirclesDataResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: T
    let links: ThreeCirclesResourceLinks?
    let meta: ThreeCirclesResponseMeta?
}

/// Paginated list response with cursor-based pagination.
struct ThreeCirclesListResponse<T: Codable & Sendable>: Codable, Sendable {
    let data: [T]
    let links: ThreeCirclesPaginationLinks?
    let meta: ThreeCirclesListMeta?
}

/// Resource links for data responses.
struct ThreeCirclesResourceLinks: Codable, Sendable {
    let `self`: String?
    let versions: String?
    let share: String?
    let timeline: String?
    let comments: String?
    let complete: String?
    let restore: String?
    let apply: String?
    let circleSet: String?
    let set: String?
    let item: String?
    let insights: String?
    let summary: String?
    let shareView: String?

    enum CodingKeys: String, CodingKey {
        case `self`
        case versions, share, timeline, comments, complete
        case restore, apply, circleSet, set, item
        case insights, summary, shareView
    }
}

/// Pagination links for list responses.
struct ThreeCirclesPaginationLinks: Codable, Sendable {
    let `self`: String?
    let next: String?

    enum CodingKeys: String, CodingKey {
        case `self`
        case next
    }
}

/// Metadata for list responses.
struct ThreeCirclesListMeta: Codable, Sendable {
    let totalCount: Int?
    let cursor: String?
    let recoveryArea: RecoveryArea?
    let circle: CircleType?
    let nextReviewDue: String?
    let minimumDataDays: Int?
    let period: String?
    let startDate: String?
    let endDate: String?
    let readOnly: Bool?
}

/// Generic response metadata.
struct ThreeCirclesResponseMeta: Codable, Sendable {
    let readOnly: Bool?
}

/// Error response envelope with rr:0x000B domain codes.
struct ThreeCirclesErrorResponse: Codable, Sendable {
    let errors: [ThreeCirclesErrorObject]
}

/// Individual error object conforming to rr:0x000Bxxxx codes.
struct ThreeCirclesErrorObject: Codable, Sendable {
    let id: String?
    let code: String?
    let status: Int
    let title: String
    let detail: String?
    let correlationId: String?
    let source: ThreeCirclesErrorSource?

    struct ThreeCirclesErrorSource: Codable, Sendable {
        let pointer: String?
        let parameter: String?
        let header: String?
    }
}

// MARK: - Timeline Response Data

/// Full timeline response data (entries + summary).
struct TimelineData: Codable, Sendable {
    let entries: [TimelineEntry]
    let summary: TimelineSummary?
}
