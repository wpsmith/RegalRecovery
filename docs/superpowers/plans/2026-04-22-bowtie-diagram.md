# Bowtie Diagram Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Bowtie Diagram — a structured emotional self-awareness activity that lets users plot emotional activations across a 48-hour past/future window, process them through the Backbone framework, and prepare for anticipated situations with Prayer-People-Plan entries.

**Architecture:** Vertical slices building on the existing MVVM + SwiftData + @Observable pattern. 12 tasks across 6 phases, with tasks within each phase parallelizable. Each task produces a working, testable increment. All new files live under existing directory conventions (`Views/Activities/Bowtie/`, `ViewModels/Bowtie/`, `Tests/Unit/Bowtie/`).

**Tech Stack:** SwiftUI, SwiftData, @Observable ViewModels, UserNotifications, XCTest

**Design Spec:** `docs/superpowers/specs/2026-04-22-bowtie-diagram-design.md`
**PRD:** `docs/prd/specific-features/bowtie/prd.md`

---

## File Map

### New Files

**Data & Types:**
- `ios/RegalRecovery/RegalRecovery/Models/BowtieTypes.swift` — All Bowtie enums with computed display properties
- `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift` — Append 6 new @Model classes + embedded structs

**ViewModels:**
- `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieSessionViewModel.swift`
- `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieMarkerViewModel.swift`
- `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BackboneProcessingViewModel.swift`
- `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/PPPEntryViewModel.swift`
- `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieHistoryViewModel.swift`
- `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieOnboardingViewModel.swift`
- `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/RolesManagerViewModel.swift`

**Views:**
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieSessionView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieListEntryView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieMarkerFormView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieDiagramView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BackboneFlowView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/PPPFormView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieOnboardingView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieHistoryView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieInsightsView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/RolesManagerView.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieCompletionOverlay.swift`
- `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieTalliesCard.swift`

**Tests:**
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieSessionViewModelTests.swift`
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieMarkerViewModelTests.swift`
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BackboneProcessingViewModelTests.swift`
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/PPPEntryViewModelTests.swift`
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieHistoryViewModelTests.swift`
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/RolesManagerViewModelTests.swift`
- `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieOnboardingViewModelTests.swift`

### Modified Files

- `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift` — Add models to `allModels` array (line 1494)
- `ios/RegalRecovery/RegalRecovery/Services/FeatureFlagStore.swift` — Add `activity.bowtie` flag (line 122)
- `ios/RegalRecovery/RegalRecovery/Views/Activities/ActivitiesListView.swift` — Add Bowtie row in Growth section
- `ios/RegalRecovery/RegalRecovery/RegalRecoveryApp.swift` — Add PPP follow-up check on foreground
- `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERResultsView.swift` — Add Bowtie suggestion card

---

## Phase 1 — Foundation

### Task 1: Bowtie Enums and Embedded Types

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Models/BowtieTypes.swift`

- [ ] **Step 1: Create BowtieTypes.swift with all enums**

```swift
import SwiftUI

// MARK: - Bowtie Status

enum BowtieStatus: String, Codable, CaseIterable {
    case draft
    case complete

    var displayName: String {
        switch self {
        case .draft: return String(localized: "Draft")
        case .complete: return String(localized: "Complete")
        }
    }

    var icon: String {
        switch self {
        case .draft: return "pencil.circle"
        case .complete: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Bowtie Side

enum BowtieSide: String, Codable, CaseIterable {
    case past
    case future

    var displayName: String {
        switch self {
        case .past: return String(localized: "Past 48 Hours")
        case .future: return String(localized: "Next 48 Hours")
        }
    }

    static let timeIntervals: [Int] = [1, 3, 6, 12, 24, 36, 48]

    func labelForInterval(_ hours: Int) -> String {
        switch self {
        case .past: return String(localized: "\(hours)h ago")
        case .future: return String(localized: "In \(hours)h")
        }
    }
}

// MARK: - Three I's

enum ThreeIType: String, Codable, CaseIterable, Identifiable {
    case insignificance
    case incompetence
    case impotence

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .insignificance: return String(localized: "Insignificance")
        case .incompetence: return String(localized: "Incompetence")
        case .impotence: return String(localized: "Impotence")
        }
    }

    var diagnosticQuestion: String {
        switch self {
        case .insignificance: return String(localized: "Do I matter?")
        case .incompetence: return String(localized: "Do I have what it takes?")
        case .impotence: return String(localized: "Do I have any control?")
        }
    }

    var color: Color {
        switch self {
        case .insignificance: return .blue
        case .incompetence: return .orange
        case .impotence: return .purple
        }
    }

    var icon: String {
        switch self {
        case .insignificance: return "person.slash"
        case .incompetence: return "xmark.shield"
        case .impotence: return "lock.fill"
        }
    }
}

// MARK: - Big Ticket Emotions

enum BigTicketEmotion: String, Codable, CaseIterable, Identifiable {
    case abandonment
    case loneliness
    case rejection
    case sorrow
    case neglect

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .abandonment: return String(localized: "Abandonment")
        case .loneliness: return String(localized: "Loneliness")
        case .rejection: return String(localized: "Rejection")
        case .sorrow: return String(localized: "Sorrow")
        case .neglect: return String(localized: "Neglect")
        }
    }

    var color: Color {
        switch self {
        case .abandonment: return .red
        case .loneliness: return .indigo
        case .rejection: return .blue
        case .sorrow: return .teal
        case .neglect: return .brown
        }
    }

    var icon: String {
        switch self {
        case .abandonment: return "figure.walk.departure"
        case .loneliness: return "person.slash"
        case .rejection: return "hand.raised.slash"
        case .sorrow: return "cloud.rain"
        case .neglect: return "eye.slash"
        }
    }

    var defaultIMapping: ThreeIType {
        switch self {
        case .abandonment: return .insignificance
        case .loneliness: return .insignificance
        case .rejection: return .insignificance
        case .sorrow: return .impotence
        case .neglect: return .insignificance
        }
    }
}

// MARK: - Emotion Vocabulary Mode

enum EmotionVocabulary: String, Codable, CaseIterable {
    case threeIs
    case bigTicket
    case combined

    var displayName: String {
        switch self {
        case .threeIs: return String(localized: "Three I's")
        case .bigTicket: return String(localized: "Big Ticket Emotions")
        case .combined: return String(localized: "Combined")
        }
    }
}

// MARK: - Entry Path

enum BowtieEntryPath: String, Codable {
    case activities
    case postRelapse
    case fasterScale
    case checkIn
}

// MARK: - Session Mode

enum BowtieSessionMode: String, Codable, CaseIterable {
    case guided
    case freeform

    var displayName: String {
        switch self {
        case .guided: return String(localized: "Guided")
        case .freeform: return String(localized: "Freeform")
        }
    }
}

// MARK: - Intimacy Category

enum IntimacyCategory: String, Codable, CaseIterable {
    case god
    case self_
    case others

    var displayName: String {
        switch self {
        case .god: return String(localized: "Intimacy with God")
        case .self_: return String(localized: "Intimacy with Self")
        case .others: return String(localized: "Intimacy with Others")
        }
    }

    var suggestedActions: [String] {
        switch self {
        case .god: return ["Prayer", "Scripture Reading", "Sermons", "Worship Music", "Read a Book"]
        case .self_: return ["Journal", "Exercise", "Speak Truth Over Yourself", "Make a Plan", "Quadrant Work", "Complete Bowtie"]
        case .others: return ["Connect with Wife/Partner", "Connect with Accountability Partner", "Text Your Group"]
        }
    }
}

// MARK: - PPP Outcome

enum PPPOutcome: String, Codable, CaseIterable {
    case better
    case expected
    case harder
    case reflectLater

    var displayName: String {
        switch self {
        case .better: return String(localized: "Better than expected")
        case .expected: return String(localized: "About what I anticipated")
        case .harder: return String(localized: "Harder than expected")
        case .reflectLater: return String(localized: "I'll reflect later")
        }
    }

    var icon: String {
        switch self {
        case .better: return "sun.max.fill"
        case .expected: return "equal.circle"
        case .harder: return "cloud.heavyrain"
        case .reflectLater: return "clock"
        }
    }
}

// MARK: - Embedded Codable Structs

struct IActivation: Codable, Hashable, Identifiable {
    var id: String { iType.rawValue }
    let iType: ThreeIType
    var intensity: Int
}

struct BigTicketActivation: Codable, Hashable, Identifiable {
    var id: String { emotion.rawValue }
    let emotion: BigTicketEmotion
    var intensity: Int
}

struct IntimacyAction: Codable, Hashable, Identifiable {
    var id: String { "\(category.rawValue)-\(label)" }
    let category: IntimacyCategory
    let label: String
    let isCustom: Bool
}

// MARK: - Backbone Emotions Vocabulary

enum BackboneEmotion: String, CaseIterable, Identifiable {
    case sad, frustrated, disappointed, rejected, devalued
    case anxious, overwhelmed, angry, lonely, ashamed
    case hopeless, fearful, embarrassed, helpless, invisible
    case defensive, numb

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Emotional Needs Vocabulary

enum EmotionalNeed: String, CaseIterable, Identifiable {
    case acceptance, affirmation, agency, belonging, comfort
    case compassion, connection, empathy, encouragement, forgiveness
    case grace, hope, love, peace, reassurance
    case respect, safety, security, understanding, validation

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Bowtie Completion Messages

enum BowtieCompletionMessages {
    static let messages: [String] = [
        String(localized: "You just practiced seeing yourself honestly. That's a recovery skill most people never develop."),
        String(localized: "The more you do this, the less the addiction can surprise you."),
        String(localized: "Knowing what's stirring in your heart is the beginning of freedom."),
        String(localized: "You've moved from reacting to understanding. That matters."),
        String(localized: "Self-intimacy is the antidote. You just practiced it."),
    ]

    static func random() -> String {
        messages.randomElement() ?? messages[0]
    }
}

// MARK: - Role Suggestions

enum RoleSuggestions {
    static let defaults: [String] = [
        "Christian", "Person of Faith",
        "Husband", "Wife", "Partner",
        "Father", "Mother", "Parent",
        "Son", "Daughter",
        "Brother", "Sister", "Sibling",
        "Friend",
        "Man in Recovery", "Woman in Recovery",
        "Coworker", "Employee",
        "Neighbor",
        "Coach", "Mentor",
        "Church Member",
        "Student",
    ]
}

// MARK: - Known Trigger Suggestions

enum KnownTriggerSuggestions {
    static let defaults: [String] = [
        "Rejection", "Failure", "Embarrassment",
        "Feeling Bullied", "Overwhelm", "Loneliness",
        "Being Controlled", "Feeling Stupid",
        "Being Overlooked", "Abandonment",
        "Conflict", "Criticism", "Disappointment",
    ]
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR && xcodebuild -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Models/BowtieTypes.swift
git commit -m "feat(ios): add Bowtie Diagram enums and embedded types"
```

---

### Task 2: SwiftData Models

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift`

**Context:** The last model class `RRQuickActionItem` ends at line 1489. The `allModels` array is at lines 1494-1528. New models go between line 1489 and the `// MARK: - Model Container Configuration` comment at line 1491. New model types must also be added to the `allModels` array.

- [ ] **Step 1: Add RRUserRole model**

Insert after line 1489 (after `RRQuickActionItem` closing brace):

```swift

// MARK: - Bowtie: User Role

@Model
final class RRUserRole {

    @Attribute(.unique) var id: UUID
    var label: String
    var sortOrder: Int
    var isArchived: Bool
    var parentRoleId: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        parentRoleId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.parentRoleId = parentRoleId
        self.createdAt = createdAt
    }
}

// MARK: - Bowtie: Known Emotional Trigger

@Model
final class RRKnownEmotionalTrigger {

    @Attribute(.unique) var id: UUID
    var label: String
    var mappedIType: String?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String,
        mappedIType: ThreeIType? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.mappedIType = mappedIType?.rawValue
        self.createdAt = createdAt
    }

    var mappedI: ThreeIType? {
        get { mappedIType.flatMap { ThreeIType(rawValue: $0) } }
        set { mappedIType = newValue?.rawValue }
    }
}

// MARK: - Bowtie: Session

@Model
final class RRBowtieSession {

    @Attribute(.unique) var id: UUID
    var status: String
    var referenceTimestamp: Date
    var createdAt: Date
    var completedAt: Date?
    var modifiedAt: Date
    var selectedRoleIdsJSON: String
    var emotionVocabulary: String
    var entryPath: String
    var sessionMode: String
    var pastInsignificanceTotal: Int
    var pastIncompetenceTotal: Int
    var pastImpotenceTotal: Int
    var futureInsignificanceTotal: Int
    var futureIncompetenceTotal: Int
    var futureImpotenceTotal: Int

    @Relationship(deleteRule: .cascade, inverse: \RRBowtieMarker.session)
    var markers: [RRBowtieMarker] = []

    init(
        id: UUID = UUID(),
        status: BowtieStatus = .draft,
        referenceTimestamp: Date = Date(),
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        modifiedAt: Date = Date(),
        selectedRoleIds: [UUID] = [],
        emotionVocabulary: EmotionVocabulary = .threeIs,
        entryPath: BowtieEntryPath = .activities,
        sessionMode: BowtieSessionMode = .guided
    ) {
        self.id = id
        self.status = status.rawValue
        self.referenceTimestamp = referenceTimestamp
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.modifiedAt = modifiedAt
        self.selectedRoleIdsJSON = (try? JSONEncoder().encode(selectedRoleIds))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.emotionVocabulary = emotionVocabulary.rawValue
        self.entryPath = entryPath.rawValue
        self.sessionMode = sessionMode.rawValue
        self.pastInsignificanceTotal = 0
        self.pastIncompetenceTotal = 0
        self.pastImpotenceTotal = 0
        self.futureInsignificanceTotal = 0
        self.futureIncompetenceTotal = 0
        self.futureImpotenceTotal = 0
    }

    // MARK: - Computed Accessors

    var bowtieStatus: BowtieStatus {
        get { BowtieStatus(rawValue: status) ?? .draft }
        set { status = newValue.rawValue }
    }

    var vocabulary: EmotionVocabulary {
        get { EmotionVocabulary(rawValue: emotionVocabulary) ?? .threeIs }
        set { emotionVocabulary = newValue.rawValue }
    }

    var entry: BowtieEntryPath {
        get { BowtieEntryPath(rawValue: entryPath) ?? .activities }
        set { entryPath = newValue.rawValue }
    }

    var mode: BowtieSessionMode {
        get { BowtieSessionMode(rawValue: sessionMode) ?? .guided }
        set { sessionMode = newValue.rawValue }
    }

    var selectedRoleIds: [UUID] {
        get {
            guard let data = selectedRoleIdsJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([UUID].self, from: data)) ?? []
        }
        set {
            selectedRoleIdsJSON = (try? JSONEncoder().encode(newValue))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        }
    }

    var pastMarkers: [RRBowtieMarker] {
        markers.filter { $0.side == BowtieSide.past.rawValue }
    }

    var futureMarkers: [RRBowtieMarker] {
        markers.filter { $0.side == BowtieSide.future.rawValue }
    }

    var processedMarkerCount: Int {
        markers.filter(\.isProcessed).count
    }
}

// MARK: - Bowtie: Marker

@Model
final class RRBowtieMarker {

    @Attribute(.unique) var id: UUID
    var side: String
    var timeIntervalHours: Int
    var roleId: UUID
    var iActivationsJSON: String
    var bigTicketEmotionsJSON: String?
    var customEmotionsJSON: String?
    var knownTriggerIdsJSON: String?
    var briefDescription: String?
    var isProcessed: Bool
    var createdAt: Date

    var session: RRBowtieSession?

    @Relationship(deleteRule: .cascade, inverse: \RRBackboneProcessing.marker)
    var backboneProcessing: RRBackboneProcessing?

    @Relationship(deleteRule: .cascade, inverse: \RRPPPEntry.marker)
    var pppEntry: RRPPPEntry?

    init(
        id: UUID = UUID(),
        side: BowtieSide,
        timeIntervalHours: Int,
        roleId: UUID,
        iActivations: [IActivation] = [],
        bigTicketEmotions: [BigTicketActivation]? = nil,
        customEmotions: [String]? = nil,
        knownTriggerIds: [UUID]? = nil,
        briefDescription: String? = nil,
        isProcessed: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.side = side.rawValue
        self.timeIntervalHours = timeIntervalHours
        self.roleId = roleId
        self.iActivationsJSON = Self.encode(iActivations)
        self.bigTicketEmotionsJSON = bigTicketEmotions.map { Self.encode($0) }
        self.customEmotionsJSON = customEmotions.map { Self.encode($0) }
        self.knownTriggerIdsJSON = knownTriggerIds.map { Self.encode($0) }
        self.briefDescription = briefDescription
        self.isProcessed = isProcessed
        self.createdAt = createdAt
    }

    // MARK: - JSON Helpers

    private static func encode<T: Encodable>(_ value: T) -> String {
        (try? JSONEncoder().encode(value)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    private static func decode<T: Decodable>(_ json: String?, as type: T.Type) -> T? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    var iActivations: [IActivation] {
        get { Self.decode(iActivationsJSON, as: [IActivation].self) ?? [] }
        set { iActivationsJSON = Self.encode(newValue) }
    }

    var bigTicketEmotions: [BigTicketActivation]? {
        get { Self.decode(bigTicketEmotionsJSON, as: [BigTicketActivation].self) }
        set { bigTicketEmotionsJSON = newValue.map { Self.encode($0) } }
    }

    var customEmotions: [String]? {
        get { Self.decode(customEmotionsJSON, as: [String].self) }
        set { customEmotionsJSON = newValue.map { Self.encode($0) } }
    }

    var knownTriggerIds: [UUID]? {
        get { Self.decode(knownTriggerIdsJSON, as: [UUID].self) }
        set { knownTriggerIdsJSON = newValue.map { Self.encode($0) } }
    }

    var bowtieSide: BowtieSide {
        get { BowtieSide(rawValue: side) ?? .past }
        set { side = newValue.rawValue }
    }

    var totalIntensity: Int {
        iActivations.reduce(0) { $0 + $1.intensity }
    }
}

// MARK: - Bowtie: Backbone Processing

@Model
final class RRBackboneProcessing {

    @Attribute(.unique) var id: UUID
    var lifeSituation: String
    var emotionsJSON: String
    var threeIsJSON: String
    var emotionalNeedsJSON: String
    var intimacyActionsJSON: String
    var spiritualReflection: String?
    var createdAt: Date

    var marker: RRBowtieMarker?

    init(
        id: UUID = UUID(),
        lifeSituation: String,
        emotions: [String] = [],
        threeIs: [IActivation] = [],
        emotionalNeeds: [String] = [],
        intimacyActions: [IntimacyAction] = [],
        spiritualReflection: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.lifeSituation = lifeSituation
        self.emotionsJSON = (try? JSONEncoder().encode(emotions))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.threeIsJSON = (try? JSONEncoder().encode(threeIs))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.emotionalNeedsJSON = (try? JSONEncoder().encode(emotionalNeeds))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.intimacyActionsJSON = (try? JSONEncoder().encode(intimacyActions))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        self.spiritualReflection = spiritualReflection
        self.createdAt = createdAt
    }

    // MARK: - Computed Accessors

    private static func decode<T: Decodable>(_ json: String, as type: T.Type) -> T? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    var emotions: [String] {
        get { Self.decode(emotionsJSON, as: [String].self) ?? [] }
        set {
            emotionsJSON = (try? JSONEncoder().encode(newValue))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        }
    }

    var threeIs: [IActivation] {
        get { Self.decode(threeIsJSON, as: [IActivation].self) ?? [] }
        set {
            threeIsJSON = (try? JSONEncoder().encode(newValue))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        }
    }

    var emotionalNeeds: [String] {
        get { Self.decode(emotionalNeedsJSON, as: [String].self) ?? [] }
        set {
            emotionalNeedsJSON = (try? JSONEncoder().encode(newValue))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        }
    }

    var intimacyActions: [IntimacyAction] {
        get { Self.decode(intimacyActionsJSON, as: [IntimacyAction].self) ?? [] }
        set {
            intimacyActionsJSON = (try? JSONEncoder().encode(newValue))
                .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        }
    }
}

// MARK: - Bowtie: PPP Entry

@Model
final class RRPPPEntry {

    @Attribute(.unique) var id: UUID
    var prayer: String?
    var peopleContactIdsJSON: String?
    var planBefore: String?
    var planDuring: String?
    var planAfter: String?
    var reminderTime: Date?
    var followUpOutcome: String?
    var followUpReflection: String?
    var createdAt: Date

    var marker: RRBowtieMarker?

    init(
        id: UUID = UUID(),
        prayer: String? = nil,
        peopleContactIds: [UUID]? = nil,
        planBefore: String? = nil,
        planDuring: String? = nil,
        planAfter: String? = nil,
        reminderTime: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.prayer = prayer
        self.peopleContactIdsJSON = peopleContactIds.map {
            (try? JSONEncoder().encode($0)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
        }
        self.planBefore = planBefore
        self.planDuring = planDuring
        self.planAfter = planAfter
        self.reminderTime = reminderTime
        self.createdAt = createdAt
    }

    var outcome: PPPOutcome? {
        get { followUpOutcome.flatMap { PPPOutcome(rawValue: $0) } }
        set { followUpOutcome = newValue?.rawValue }
    }

    var peopleContactIds: [UUID]? {
        get {
            guard let data = peopleContactIdsJSON?.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode([UUID].self, from: data)
        }
        set {
            peopleContactIdsJSON = newValue.map {
                (try? JSONEncoder().encode($0)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
            }
        }
    }
}
```

- [ ] **Step 2: Register new models in allModels array**

Add to the `allModels` array at line ~1527 (before the closing bracket):

```swift
        RRUserRole.self,
        RRKnownEmotionalTrigger.self,
        RRBowtieSession.self,
        RRBowtieMarker.self,
        RRBackboneProcessing.self,
        RRPPPEntry.self,
```

- [ ] **Step 3: Build to verify schema compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR && xcodebuild -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift
git commit -m "feat(ios): add Bowtie SwiftData models and schema registration"
```

---

### Task 3: Roles Manager ViewModel and View

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/RolesManagerViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/RolesManagerView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/RolesManagerViewModelTests.swift`

- [ ] **Step 1: Write failing tests for RolesManagerViewModel**

```swift
import XCTest
import SwiftData
@testable import RegalRecovery

final class RolesManagerViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        super.setUp()
        container = try! RRModelConfiguration.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testAddRole_InsertsRoleWithCorrectLabel() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Husband", context: context)

        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())
        XCTAssertEqual(roles.count, 1)
        XCTAssertEqual(roles[0].label, "Husband")
        XCTAssertFalse(roles[0].isArchived)
    }

    func testAddSubRole_SetsParentRoleId() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Father", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())
        let parentId = roles[0].id

        vm.addSubRole(label: "Father — Oldest", parentId: parentId, context: context)

        let allRoles = try! context.fetch(FetchDescriptor<RRUserRole>(sortBy: [SortDescriptor(\.sortOrder)]))
        XCTAssertEqual(allRoles.count, 2)
        XCTAssertEqual(allRoles[1].parentRoleId, parentId)
    }

    func testArchiveRole_SetsIsArchived() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Coworker", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())

        vm.archiveRole(roles[0], context: context)

        let updated = try! context.fetch(FetchDescriptor<RRUserRole>())
        XCTAssertTrue(updated[0].isArchived)
    }

    func testActiveRoles_ExcludesArchived() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Active", context: context)
        vm.addRole(label: "Archived", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>(sortBy: [SortDescriptor(\.sortOrder)]))
        vm.archiveRole(roles[1], context: context)

        vm.loadRoles(context: context)

        XCTAssertEqual(vm.activeRoles.count, 1)
        XCTAssertEqual(vm.activeRoles[0].label, "Active")
    }

    func testDeleteRole_RemovesFromStore() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "Temp", context: context)
        let roles = try! context.fetch(FetchDescriptor<RRUserRole>())

        vm.deleteRole(roles[0], context: context)

        let remaining = try! context.fetch(FetchDescriptor<RRUserRole>())
        XCTAssertTrue(remaining.isEmpty)
    }

    func testReorderRoles_UpdatesSortOrder() {
        let vm = RolesManagerViewModel()
        vm.addRole(label: "A", context: context)
        vm.addRole(label: "B", context: context)
        vm.addRole(label: "C", context: context)
        vm.loadRoles(context: context)

        let reordered = [vm.activeRoles[2], vm.activeRoles[0], vm.activeRoles[1]]
        vm.reorderRoles(reordered, context: context)

        XCTAssertEqual(vm.activeRoles[0].label, "C")
        XCTAssertEqual(vm.activeRoles[1].label, "A")
        XCTAssertEqual(vm.activeRoles[2].label, "B")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/travis.smith/Projects/personal/RR && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/RolesManagerViewModelTests 2>&1 | tail -10`
Expected: FAIL — `RolesManagerViewModel` not found

- [ ] **Step 3: Implement RolesManagerViewModel**

```swift
import Foundation
import SwiftData

@Observable
class RolesManagerViewModel {

    var activeRoles: [RRUserRole] = []
    var archivedRoles: [RRUserRole] = []

    func loadRoles(context: ModelContext) {
        let descriptor = FetchDescriptor<RRUserRole>(sortBy: [SortDescriptor(\.sortOrder)])
        let all = (try? context.fetch(descriptor)) ?? []
        activeRoles = all.filter { !$0.isArchived }
        archivedRoles = all.filter { $0.isArchived }
    }

    func addRole(label: String, context: ModelContext) {
        let nextOrder = (activeRoles.last?.sortOrder ?? -1) + 1
        let role = RRUserRole(label: label, sortOrder: nextOrder)
        context.insert(role)
        loadRoles(context: context)
    }

    func addSubRole(label: String, parentId: UUID, context: ModelContext) {
        let nextOrder = (activeRoles.last?.sortOrder ?? -1) + 1
        let role = RRUserRole(label: label, sortOrder: nextOrder, parentRoleId: parentId)
        context.insert(role)
        loadRoles(context: context)
    }

    func archiveRole(_ role: RRUserRole, context: ModelContext) {
        role.isArchived = true
        loadRoles(context: context)
    }

    func unarchiveRole(_ role: RRUserRole, context: ModelContext) {
        role.isArchived = false
        role.sortOrder = (activeRoles.last?.sortOrder ?? -1) + 1
        loadRoles(context: context)
    }

    func deleteRole(_ role: RRUserRole, context: ModelContext) {
        context.delete(role)
        loadRoles(context: context)
    }

    func updateLabel(_ role: RRUserRole, newLabel: String, context: ModelContext) {
        role.label = newLabel
        loadRoles(context: context)
    }

    func reorderRoles(_ roles: [RRUserRole], context: ModelContext) {
        for (index, role) in roles.enumerated() {
            role.sortOrder = index
        }
        loadRoles(context: context)
    }

    func subRoles(of parentId: UUID) -> [RRUserRole] {
        activeRoles.filter { $0.parentRoleId == parentId }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/travis.smith/Projects/personal/RR && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/RolesManagerViewModelTests 2>&1 | tail -10`
Expected: All tests PASS

- [ ] **Step 5: Create RolesManagerView**

```swift
import SwiftUI
import SwiftData

struct RolesManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = RolesManagerViewModel()
    @State private var newRoleLabel = ""
    @State private var editingRole: RRUserRole?
    @State private var editLabel = ""
    @State private var showAddSubRole = false
    @State private var subRoleParentId: UUID?
    @State private var newSubRoleLabel = ""

    var body: some View {
        List {
            Section {
                HStack {
                    TextField(String(localized: "New role name"), text: $newRoleLabel)
                        .textInputAutocapitalization(.words)
                    Button {
                        guard !newRoleLabel.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        viewModel.addRole(label: newRoleLabel.trimmingCharacters(in: .whitespaces), context: modelContext)
                        newRoleLabel = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.rrPrimary)
                    }
                    .disabled(newRoleLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Add Role")
            }

            if !viewModel.activeRoles.isEmpty {
                Section {
                    ForEach(viewModel.activeRoles, id: \.id) { role in
                        HStack {
                            if role.parentRoleId != nil {
                                Image(systemName: "arrow.turn.down.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(role.label)
                            Spacer()
                            Button {
                                subRoleParentId = role.id
                                showAddSubRole = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.archiveRole(role, context: modelContext)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingRole = role
                                editLabel = role.label
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.rrPrimary)
                        }
                    }
                    .onMove { from, to in
                        var roles = viewModel.activeRoles
                        roles.move(fromOffsets: from, toOffset: to)
                        viewModel.reorderRoles(roles, context: modelContext)
                    }
                } header: {
                    Text("Your Roles")
                }
            }

            if !viewModel.archivedRoles.isEmpty {
                Section {
                    ForEach(viewModel.archivedRoles, id: \.id) { role in
                        HStack {
                            Text(role.label)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                viewModel.unarchiveRole(role, context: modelContext)
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.rrPrimary)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                viewModel.deleteRole(role, context: modelContext)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("Archived")
                }
            }

            if viewModel.activeRoles.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Text("Suggested Roles")
                            .font(.headline)
                        Text("Tap to add roles that fit your life right now.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 8) {
                            ForEach(RoleSuggestions.defaults, id: \.self) { suggestion in
                                let alreadyAdded = viewModel.activeRoles.contains { $0.label == suggestion }
                                Button {
                                    if !alreadyAdded {
                                        viewModel.addRole(label: suggestion, context: modelContext)
                                    }
                                } label: {
                                    Text(suggestion)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(alreadyAdded ? Color.rrPrimary.opacity(0.2) : Color.rrSurface)
                                        .foregroundStyle(alreadyAdded ? .rrPrimary : .primary)
                                        .clipShape(Capsule())
                                }
                                .disabled(alreadyAdded)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(String(localized: "Life Roles"))
        .onAppear { viewModel.loadRoles(context: modelContext) }
        .alert("Edit Role", isPresented: .init(
            get: { editingRole != nil },
            set: { if !$0 { editingRole = nil } }
        )) {
            TextField("Role name", text: $editLabel)
            Button("Save") {
                if let role = editingRole {
                    viewModel.updateLabel(role, newLabel: editLabel, context: modelContext)
                }
                editingRole = nil
            }
            Button("Cancel", role: .cancel) { editingRole = nil }
        }
        .alert("Add Sub-Role", isPresented: $showAddSubRole) {
            TextField("Sub-role name", text: $newSubRoleLabel)
            Button("Add") {
                if let parentId = subRoleParentId,
                   !newSubRoleLabel.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.addSubRole(
                        label: newSubRoleLabel.trimmingCharacters(in: .whitespaces),
                        parentId: parentId,
                        context: modelContext
                    )
                }
                newSubRoleLabel = ""
                subRoleParentId = nil
            }
            Button("Cancel", role: .cancel) {
                newSubRoleLabel = ""
                subRoleParentId = nil
            }
        }
    }
}

// MARK: - Flow Layout (for suggestion chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
```

- [ ] **Step 6: Build to verify**

Run: `cd /Users/travis.smith/Projects/personal/RR && xcodebuild -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 7: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/RolesManagerViewModel.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/RolesManagerView.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/RolesManagerViewModelTests.swift
git commit -m "feat(ios): add roles manager with sub-role support for Bowtie"
```

---

## Phase 2 — Core Session

### Task 4: Feature Flag + Activities Integration

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Services/FeatureFlagStore.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/ActivitiesListView.swift`

- [ ] **Step 1: Register activity.bowtie feature flag**

In `FeatureFlagStore.swift`, add to the `flagDefaults` dictionary after the `"activity.acting-in-behaviors": false,` line (around line 122):

```swift
        "activity.bowtie": false,
```

- [ ] **Step 2: Add Bowtie row to ActivitiesListView**

In `ActivitiesListView.swift`, add a `@Query` for draft Bowtie sessions at the top of the struct (after line 19):

```swift
    @Query(filter: #Predicate<RRBowtieSession> { $0.status == "draft" },
           sort: \RRBowtieSession.modifiedAt, order: .reverse)
    private var bowtieDrafts: [RRBowtieSession]
    @Query(filter: #Predicate<RRBowtieSession> { $0.status == "complete" },
           sort: \RRBowtieSession.completedAt, order: .reverse)
    private var completedBowties: [RRBowtieSession]
```

Add a subtitle helper (after `motivationsSubtitle`):

```swift
    private var bowtieSubtitle: String {
        if let draft = bowtieDrafts.first {
            let dayLabel = Calendar.current.isDateInToday(draft.modifiedAt) ? String(localized: "Today") : relativeDay(draft.modifiedAt)
            return String(localized: "\(dayLabel) — Draft")
        }
        if let latest = completedBowties.first {
            return relativeDay(latest.completedAt ?? latest.modifiedAt)
        }
        return String(localized: "Emotional awareness tool")
    }
```

Add the NavigationLink in the Growth section (after the 3 Circles block, around line 413):

```swift
                    if isFlagEnabled("activity.bowtie") {
                        NavigationLink {
                            BowtieSessionView()
                        } label: {
                            HStack {
                                RRActivityRow(
                                    icon: "bowtie",
                                    iconColor: .rrPrimary,
                                    title: String(localized: "Bowtie Diagram"),
                                    subtitle: bowtieSubtitle
                                )
                                if !bowtieDrafts.isEmpty {
                                    Text("Continue")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.rrPrimary.opacity(0.15))
                                        .foregroundStyle(.rrPrimary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
```

Note: The icon `"bowtie"` references a custom SF Symbol or asset. If it doesn't exist yet, use `"bow.tie"` (available in SF Symbols 5) or fall back to `"diamond.fill"` as a placeholder.

- [ ] **Step 3: Build to verify**

Run: `cd /Users/travis.smith/Projects/personal/RR && xcodebuild -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED (BowtieSessionView doesn't exist yet — this will fail until Task 5 creates it. Create a stub if needed.)

- [ ] **Step 4: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Services/FeatureFlagStore.swift ios/RegalRecovery/RegalRecovery/Views/Activities/ActivitiesListView.swift
git commit -m "feat(ios): add Bowtie feature flag and Activities list integration"
```

---

### Task 5: Session ViewModel + Past Side Plotting

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieSessionViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieMarkerViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieSessionViewModelTests.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieMarkerViewModelTests.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieSessionView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieListEntryView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieMarkerFormView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieTalliesCard.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieCompletionOverlay.swift`

**This is the largest task. It produces:** a working Bowtie session — create session, select roles, add past-side markers with Three I's/Big Ticket/Combined, see tallies, auto-save as draft, mark complete.

- [ ] **Step 1: Write BowtieSessionViewModel tests**

Tests for: creating a session, resuming a draft, adding a marker updates tallies, completing a session, deleting a session.

- [ ] **Step 2: Write BowtieMarkerViewModel tests**

Tests for: validation (needs at least one activation), intensity clamping (1-10), description max length (280), Three I's mode vs Big Ticket mode.

- [ ] **Step 3: Run tests to verify they fail**

- [ ] **Step 4: Implement BowtieSessionViewModel**

Key behaviors:
- `createSession(roles:vocabulary:mode:entryPath:referenceTimestamp:context:)` — inserts RRBowtieSession
- `resumeDraft(session:context:)` — loads existing draft
- `addMarker(_:context:)` — inserts RRBowtieMarker, calls `recalculateTallies()`
- `removeMarker(_:context:)` — deletes marker, recalculates tallies
- `recalculateTallies()` — sums intensities per I-type per side, writes to session
- `completeSession(context:userId:)` — sets status to complete, sets completedAt, writes RRActivity for calendar
- `deleteSession(context:)` — deletes session from context
- Auto-save: every mutation calls `session.modifiedAt = Date()`

- [ ] **Step 5: Implement BowtieMarkerViewModel**

Key behaviors:
- Form state: `selectedSide`, `selectedTimeInterval`, `selectedRoleId`, `iActivations`, `bigTicketEmotions`, `customEmotions`, `selectedTriggerIds`, `briefDescription`
- `canSave` — at least one activation with intensity > 0
- `buildMarker()` → `RRBowtieMarker`
- `loadFromMarker(_:)` — populate form from existing marker for editing

- [ ] **Step 6: Run tests to verify they pass**

- [ ] **Step 7: Implement BowtieSessionView**

The main session screen. Structure:
- If no session loaded and draft exists → resume draft. If no draft → show session setup (role picker + vocabulary picker + mode toggle → create session)
- Once session active: show `BowtieListEntryView` with tallies card
- Toolbar: complete button (disabled if no markers), help icon
- On complete: show `BowtieCompletionOverlay`

- [ ] **Step 8: Implement BowtieListEntryView**

Sectioned list:
- "Past 48 Hours" section header
- For each time interval (48, 36, 24, 12, 6, 3, 1): show markers at that interval as cards, plus an "Add" button
- Each marker card shows: role label, I-type chips with intensity, description preview, processed checkmark if applicable
- Tap marker → sheet with `BowtieMarkerFormView` in edit mode
- Tap add → sheet with `BowtieMarkerFormView` in create mode for that interval

- [ ] **Step 9: Implement BowtieMarkerFormView**

Sheet for adding/editing a marker:
- Role picker (segmented or menu from session's selected roles)
- Time interval picker (segmented control: 1, 3, 6, 12, 24, 36, 48)
- Emotion vocabulary section based on session's mode:
  - Three I's: three toggle chips, each with intensity slider (1-10) when selected
  - Big Ticket: five toggle chips, each with intensity slider
  - Combined: both sets
- Known triggers multi-select (if user has configured triggers)
- Description text field with character counter (280 max)
- Save / Cancel buttons

- [ ] **Step 10: Implement BowtieTalliesCard**

Compact card showing running tallies:
- If Three I's mode: Insignificance: X, Incompetence: Y, Impotence: Z
- If Big Ticket mode: per-emotion tallies
- Color-coded by I-type/emotion
- Shows separate past and future totals

- [ ] **Step 11: Implement BowtieCompletionOverlay**

Overlay shown after completing a session:
- Random completion message from `BowtieCompletionMessages.random()`
- Dismiss button
- Auto-dismiss after 5 seconds

- [ ] **Step 12: Build and test**

Run: Build + run tests
Expected: All tests pass, build succeeds

- [ ] **Step 13: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieSessionViewModel.swift ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieMarkerViewModel.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieSessionView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieListEntryView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieMarkerFormView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieTalliesCard.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieCompletionOverlay.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieSessionViewModelTests.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieMarkerViewModelTests.swift
git commit -m "feat(ios): add Bowtie session creation and past-side marker plotting"
```

---

## Phase 3 — Complete Plotting

### Task 6: Future Side + Complete Button

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieListEntryView.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieSessionView.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieTalliesCard.swift`

- [ ] **Step 1: Add Future section to BowtieListEntryView**

Add a "Next 48 Hours" section below the Past section. Same structure: time intervals (1, 3, 6, 12, 24, 36, 48h), marker cards, add buttons. Future markers use `.future` side and have outlined styling (`.stroke()` instead of `.fill()` on marker chips).

- [ ] **Step 2: Add tab selector to BowtieSessionView for freeform mode**

In freeform mode, add a `Picker` with `.segmented` style at top: "Past 48h" / "Future 48h" / "All". Controls which sections are visible in `BowtieListEntryView`. In guided mode, the view already walks through both sides sequentially.

- [ ] **Step 3: Update BowtieTalliesCard to show both sides**

Two-column layout: Past tallies on left, Future tallies on right, separated by a "Now" divider. Each column shows per-I totals.

- [ ] **Step 4: Build and test**

Run: Build + run all Bowtie tests
Expected: All pass

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieListEntryView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieSessionView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieTalliesCard.swift
git commit -m "feat(ios): add future-side plotting and dual tallies display"
```

---

### Task 7: Visual Bowtie Diagram

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieDiagramView.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieSessionView.swift`

- [ ] **Step 1: Implement BowtieDiagramView using Canvas or Shape**

The bowtie shape: two triangles meeting at center "Now" point.
- Left triangle (past): wide at left edge (48h), narrows to center
- Right triangle (future): narrows from center, widens to right edge (48h)
- Vertical dashed lines at each time interval
- Markers rendered as circles at the intersection of their time interval column and a vertical position based on role
- Color-coded by I-type: `.insignificance` = blue, `.incompetence` = orange, `.impotence` = purple
- Past markers: filled circles. Future markers: outlined circles (stroke only)
- Tap a column area → add marker sheet. Tap existing marker → edit/process options
- "Now" label at center with timestamp

Accessibility:
- `.accessibilityElement(children: .ignore)` on the diagram Canvas
- `.accessibilityLabel()` announcing structured summary: "Bowtie diagram. Past side: 3 markers. Future side: 2 markers. Past tallies: Insignificance 8, Incompetence 4, Impotence 2."
- `.accessibilityHint("Use list view for detailed interaction")`

- [ ] **Step 2: Add adaptive layout switching in BowtieSessionView**

```swift
@Environment(\.horizontalSizeClass) private var sizeClass

// In body:
if sizeClass == .regular {
    BowtieDiagramView(session: viewModel.session, onTapInterval: { side, interval in ... }, onTapMarker: { marker in ... })
} else {
    BowtieListEntryView(...)
}
```

- [ ] **Step 3: Honor Reduce Motion**

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
// Disable marker placement animations when reduceMotion is true
```

- [ ] **Step 4: Build and test visually**

Run the app in simulator at different size classes (iPhone SE, iPhone 16 Pro Max, iPad). Verify diagram appears on larger screens, list on smaller.

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieDiagramView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieSessionView.swift
git commit -m "feat(ios): add visual Bowtie diagram with adaptive layout"
```

---

## Phase 4 — Processing Workflows

### Task 8: Backbone Processing Flow

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BackboneProcessingViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BackboneFlowView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BackboneProcessingViewModelTests.swift`

- [ ] **Step 1: Write BackboneProcessingViewModel tests**

Tests for: step navigation (forward/back), canAdvance per step, saving creates RRBackboneProcessing linked to marker, saving sets marker.isProcessed to true, progress fraction computation.

```swift
import XCTest
import SwiftData
@testable import RegalRecovery

final class BackboneProcessingViewModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() {
        super.setUp()
        container = try! RRModelConfiguration.makeContainer(inMemory: true)
        context = ModelContext(container)
    }

    override func tearDown() {
        container = nil
        context = nil
        super.tearDown()
    }

    func testInitialStep_IsLifeSituation() {
        let vm = BackboneProcessingViewModel()
        XCTAssertEqual(vm.currentStep, .lifeSituation)
    }

    func testCanAdvance_LifeSituation_RequiresNonEmptyText() {
        let vm = BackboneProcessingViewModel()
        XCTAssertFalse(vm.canAdvance)

        vm.lifeSituation = "Boss criticized my report"
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_Emotions_RequiresAtLeastOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .emotions
        XCTAssertFalse(vm.canAdvance)

        vm.selectedEmotions.insert("frustrated")
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_ThreeIs_RequiresAtLeastOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .threeIs
        XCTAssertFalse(vm.canAdvance)

        vm.iActivations.append(IActivation(iType: .incompetence, intensity: 5))
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_SpiritualReflection_AlwaysTrue() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .spiritualReflection
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_EmotionalNeeds_RequiresAtLeastOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .emotionalNeeds
        XCTAssertFalse(vm.canAdvance)

        vm.selectedNeeds.insert("affirmation")
        XCTAssertTrue(vm.canAdvance)
    }

    func testCanAdvance_IntimacyActions_RequiresAtLeastOne() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .intimacyActions
        XCTAssertFalse(vm.canAdvance)

        vm.selectedActions.append(IntimacyAction(category: .self_, label: "Journal", isCustom: false))
        XCTAssertTrue(vm.canAdvance)
    }

    func testProgressFraction_IncreasesPerStep() {
        let vm = BackboneProcessingViewModel()
        let initial = vm.progressFraction
        vm.currentStep = .emotions
        XCTAssertGreaterThan(vm.progressFraction, initial)
    }

    func testGoForward_AdvancesStep() {
        let vm = BackboneProcessingViewModel()
        vm.lifeSituation = "Something happened"
        vm.goForward()
        XCTAssertEqual(vm.currentStep, .emotions)
    }

    func testGoBack_ReturnsToMreviousStep() {
        let vm = BackboneProcessingViewModel()
        vm.currentStep = .emotions
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .lifeSituation)
    }

    func testGoBack_AtFirstStep_DoesNothing() {
        let vm = BackboneProcessingViewModel()
        vm.goBack()
        XCTAssertEqual(vm.currentStep, .lifeSituation)
    }

    func testSave_CreatesBackboneProcessingAndMarksProcessed() {
        let session = RRBowtieSession(selectedRoleIds: [UUID()])
        context.insert(session)
        let marker = RRBowtieMarker(side: .past, timeIntervalHours: 6, roleId: UUID(), iActivations: [IActivation(iType: .incompetence, intensity: 5)])
        marker.session = session
        context.insert(marker)

        let vm = BackboneProcessingViewModel()
        vm.lifeSituation = "Boss said my report was sloppy"
        vm.selectedEmotions = Set(["frustrated", "embarrassed"])
        vm.iActivations = [IActivation(iType: .incompetence, intensity: 7)]
        vm.spiritualReflectionText = "I felt distant from God"
        vm.selectedNeeds = Set(["affirmation", "respect"])
        vm.selectedActions = [IntimacyAction(category: .self_, label: "Journal", isCustom: false)]

        vm.save(marker: marker, context: context)

        XCTAssertTrue(marker.isProcessed)
        XCTAssertNotNil(marker.backboneProcessing)
        XCTAssertEqual(marker.backboneProcessing?.lifeSituation, "Boss said my report was sloppy")
        XCTAssertEqual(marker.backboneProcessing?.emotions.count, 2)
        XCTAssertEqual(marker.backboneProcessing?.intimacyActions.count, 1)
        XCTAssertEqual(marker.backboneProcessing?.spiritualReflection, "I felt distant from God")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement BackboneProcessingViewModel**

```swift
import Foundation
import SwiftData

enum BackboneStep: Int, CaseIterable {
    case lifeSituation
    case emotions
    case threeIs
    case spiritualReflection
    case emotionalNeeds
    case intimacyActions
}

@Observable
class BackboneProcessingViewModel {

    var currentStep: BackboneStep = .lifeSituation
    var showCompletion = false

    // Step 1
    var lifeSituation: String = ""

    // Step 2
    var selectedEmotions: Set<String> = []

    // Step 3
    var iActivations: [IActivation] = []

    // Step 4
    var spiritualReflectionText: String = ""

    // Step 5
    var selectedNeeds: Set<String> = []

    // Step 6
    var selectedActions: [IntimacyAction] = []

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(BackboneStep.allCases.count)
    }

    var isFirstStep: Bool { currentStep == .lifeSituation }
    var isLastStep: Bool { currentStep == .intimacyActions }

    var canAdvance: Bool {
        switch currentStep {
        case .lifeSituation:
            return !lifeSituation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .emotions:
            return !selectedEmotions.isEmpty
        case .threeIs:
            return !iActivations.isEmpty
        case .spiritualReflection:
            return true
        case .emotionalNeeds:
            return !selectedNeeds.isEmpty
        case .intimacyActions:
            return !selectedActions.isEmpty
        }
    }

    func goForward() {
        guard canAdvance,
              let next = BackboneStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func goBack() {
        guard currentStep.rawValue > 0,
              let prev = BackboneStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func toggleEmotion(_ emotion: String) {
        if selectedEmotions.contains(emotion) {
            selectedEmotions.remove(emotion)
        } else {
            selectedEmotions.insert(emotion)
        }
    }

    func toggleNeed(_ need: String) {
        if selectedNeeds.contains(need) {
            selectedNeeds.remove(need)
        } else {
            selectedNeeds.insert(need)
        }
    }

    func toggleIActivation(_ iType: ThreeIType, intensity: Int) {
        if let index = iActivations.firstIndex(where: { $0.iType == iType }) {
            iActivations.remove(at: index)
        } else {
            iActivations.append(IActivation(iType: iType, intensity: intensity))
        }
    }

    func updateIntensity(for iType: ThreeIType, to intensity: Int) {
        guard let index = iActivations.firstIndex(where: { $0.iType == iType }) else { return }
        iActivations[index] = IActivation(iType: iType, intensity: max(1, min(10, intensity)))
    }

    func toggleAction(_ action: IntimacyAction) {
        if let index = selectedActions.firstIndex(of: action) {
            selectedActions.remove(at: index)
        } else {
            selectedActions.append(action)
        }
    }

    func addCustomAction(category: IntimacyCategory, label: String) {
        let action = IntimacyAction(category: category, label: label, isCustom: true)
        selectedActions.append(action)
    }

    func save(marker: RRBowtieMarker, context: ModelContext) {
        let processing = RRBackboneProcessing(
            lifeSituation: lifeSituation.trimmingCharacters(in: .whitespacesAndNewlines),
            emotions: Array(selectedEmotions).sorted(),
            threeIs: iActivations,
            emotionalNeeds: Array(selectedNeeds).sorted(),
            intimacyActions: selectedActions,
            spiritualReflection: spiritualReflectionText.isEmpty ? nil : spiritualReflectionText
        )
        processing.marker = marker
        context.insert(processing)
        marker.isProcessed = true
        showCompletion = true
    }

    func loadFromExisting(_ processing: RRBackboneProcessing) {
        lifeSituation = processing.lifeSituation
        selectedEmotions = Set(processing.emotions)
        iActivations = processing.threeIs
        spiritualReflectionText = processing.spiritualReflection ?? ""
        selectedNeeds = Set(processing.emotionalNeeds)
        selectedActions = processing.intimacyActions
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Implement BackboneFlowView**

6-step wizard using the MoodRatingView swipe pattern:
- Progress bar at top
- Step content switches on `currentStep`
- Each step has a title, prompt text (per PRD Section 6.5), and input controls
- Life Situation: text editor, max 500 chars, placeholder from PRD
- Emotions: `FlowLayout` of `BackboneEmotion` chips, toggleable, free text option
- Three I's: three cards with diagnostic question, toggle + intensity slider
- Spiritual Reflection: text editor, prompt: "How did you experience yourself and God in this situation?"
- Emotional Needs: `FlowLayout` of `EmotionalNeed` chips, toggleable, free text option
- Intimacy Actions: three-column layout (God / Self / Others), each with suggested actions as toggle chips + custom add
- Swipe gesture navigation (DragGesture, 50pt minimum)
- Completion overlay on save

- [ ] **Step 6: Wire Backbone launch from marker cards**

In `BowtieListEntryView`, add a context menu or button on each marker card: "Process this" → present `BackboneFlowView` as sheet. Show checkmark on marker card when `isProcessed` is true.

- [ ] **Step 7: Build and test**

- [ ] **Step 8: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BackboneProcessingViewModel.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BackboneFlowView.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BackboneProcessingViewModelTests.swift
git commit -m "feat(ios): add Backbone processing 6-step wizard for Bowtie markers"
```

---

### Task 9: Prayer-People-Plan + Notifications

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/PPPEntryViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/PPPFormView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/PPPEntryViewModelTests.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/RegalRecoveryApp.swift` — PPP follow-up on foreground

- [ ] **Step 1: Write PPPEntryViewModel tests**

Tests for: saving creates RRPPPEntry linked to marker, reminder scheduling, follow-up outcome recording, loading from existing.

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement PPPEntryViewModel**

Key behaviors:
- Form state: `prayer`, `selectedContactIds`, `planBefore`, `planDuring`, `planAfter`, `reminderEnabled`, `reminderInterval` (30min/1h/3h/custom)
- `save(marker:context:)` — creates RRPPPEntry, optionally schedules notification
- `scheduleReminder(for pppEntry:marker:)` — computes reminder time from `session.referenceTimestamp + marker.timeIntervalHours - reminderInterval`, schedules UNNotificationRequest with content "Your plan is ready."
- `cancelReminder(for pppEntry:)` — removes scheduled notification by ID
- `recordFollowUp(outcome:reflection:context:)` — updates existing PPPEntry
- `loadFromExisting(_:)` — populate form from existing entry

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Implement PPPFormView**

Sheet with three sections:
- **Prayer:** text editor with optional guided prompt based on marker's I-type (e.g., for insignificance: "Lord, remind me that I am seen and valued by You")
- **People:** list of support contacts from `RRSupportContact` query, toggleable selection
- **Plan:** three text fields with labels "Before this situation, I will ___", "During this situation, I will ___", "After this situation, I will ___"
- **Reminder:** toggle + interval picker (Picker with .menu style: 30 min, 1 hour, 3 hours)
- Save / Cancel buttons

- [ ] **Step 6: Wire PPP launch from future markers**

In `BowtieListEntryView`, add "Prepare for this" button on future-side marker cards → present `PPPFormView`. Show PPP indicator on marker cards that have an entry.

- [ ] **Step 7: Add PPP follow-up check on app foreground**

In `RegalRecoveryApp.swift`, in the `handleForeground()` method, add a check:
- Query `RRPPPEntry` where `reminderTime != nil && reminderTime < Date() && followUpOutcome == nil`
- If any found, set a `@State` flag to present a follow-up sheet
- Follow-up sheet: "How did it go?" with 4 outcome buttons + optional reflection text field

- [ ] **Step 8: Build and test**

- [ ] **Step 9: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/PPPEntryViewModel.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/PPPFormView.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/PPPEntryViewModelTests.swift ios/RegalRecovery/RegalRecovery/RegalRecoveryApp.swift
git commit -m "feat(ios): add Prayer-People-Plan with reminders and follow-up"
```

---

### Task 10: Guided Mode + Onboarding

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieOnboardingViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieOnboardingView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieOnboardingViewModelTests.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieSessionViewModel.swift`

- [ ] **Step 1: Write BowtieOnboardingViewModel tests**

Tests for: step progression, role addition from suggestions, trigger addition from suggestions, onboarding completion marks flag.

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement BowtieOnboardingViewModel**

```swift
import Foundation
import SwiftData

enum BowtieOnboardingStep: Int, CaseIterable {
    case explanation
    case visualMetaphor
    case roleSetup
    case triggerSetup
}

@Observable
class BowtieOnboardingViewModel {

    var currentStep: BowtieOnboardingStep = .explanation
    var selectedSuggestionRoles: Set<String> = []
    var customRoleLabel: String = ""
    var selectedSuggestionTriggers: Set<String> = []
    var customTriggerLabel: String = ""

    private static let completedKey = "bowtie.onboardingCompleted"

    static var isOnboardingCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    var isLastStep: Bool { currentStep == .triggerSetup }
    var isFirstStep: Bool { currentStep == .explanation }

    var progressFraction: Double {
        Double(currentStep.rawValue + 1) / Double(BowtieOnboardingStep.allCases.count)
    }

    func goForward() {
        guard let next = BowtieOnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
    }

    func goBack() {
        guard currentStep.rawValue > 0,
              let prev = BowtieOnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    func toggleSuggestionRole(_ role: String) {
        if selectedSuggestionRoles.contains(role) {
            selectedSuggestionRoles.remove(role)
        } else {
            selectedSuggestionRoles.insert(role)
        }
    }

    func addCustomRole() {
        let trimmed = customRoleLabel.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        selectedSuggestionRoles.insert(trimmed)
        customRoleLabel = ""
    }

    func toggleSuggestionTrigger(_ trigger: String) {
        if selectedSuggestionTriggers.contains(trigger) {
            selectedSuggestionTriggers.remove(trigger)
        } else {
            selectedSuggestionTriggers.insert(trigger)
        }
    }

    func addCustomTrigger() {
        let trimmed = customTriggerLabel.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        selectedSuggestionTriggers.insert(trimmed)
        customTriggerLabel = ""
    }

    func completeOnboarding(context: ModelContext) {
        for (index, label) in selectedSuggestionRoles.sorted().enumerated() {
            let role = RRUserRole(label: label, sortOrder: index)
            context.insert(role)
        }

        for label in selectedSuggestionTriggers.sorted() {
            let defaultMapping = KnownTriggerSuggestions.defaults.contains(label)
                ? suggestedMapping(for: label) : nil
            let trigger = RRKnownEmotionalTrigger(label: label, mappedIType: defaultMapping)
            context.insert(trigger)
        }

        UserDefaults.standard.set(true, forKey: Self.completedKey)
    }

    private func suggestedMapping(for trigger: String) -> ThreeIType? {
        switch trigger.lowercased() {
        case "rejection", "being overlooked", "abandonment", "loneliness":
            return .insignificance
        case "failure", "feeling stupid", "criticism":
            return .incompetence
        case "being controlled", "overwhelm":
            return .impotence
        default:
            return nil
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Implement BowtieOnboardingView**

4-page flow (using the MoodRatingView swipe pattern):
- **Page 1 — Explanation:** "What is the Bowtie Diagram?" Brief explanation with bowtie visual. Text per PRD Section 5.1.
- **Page 2 — Visual Metaphor:** Looking back (past 48h) and looking ahead (next 48h) through your life roles. Simple illustration.
- **Page 3 — Role Setup:** `FlowLayout` of `RoleSuggestions.defaults` as toggle chips. Custom role text field + add button.
- **Page 4 — Trigger Setup:** `FlowLayout` of `KnownTriggerSuggestions.defaults` as toggle chips. Custom trigger text field + add button. "Complete" button saves and dismisses.
- Skip button in toolbar on every page.
- Progress bar at top.

- [ ] **Step 6: Add guided mode to BowtieSessionViewModel**

Add guided mode state tracking:
- `guidedCurrentRoleIndex: Int` — which role we're prompting for
- `guidedCurrentSide: BowtieSide` — past first, then future
- `guidedPromptText: String` — computed: "Over the last 48 hours, as a [Role], has anything stirred the Three I's?"
- `guidedAdvance()` — move to next role, or switch to future side, or show completion
- `guidedSkipRole()` — "Nothing for this role" → advance
- Track guided completion count in UserDefaults key `bowtie.guidedCompletionCount`
- After 3 guided completions, default new sessions to `.freeform`

- [ ] **Step 7: Wire onboarding into BowtieSessionView**

In `BowtieSessionView`, check `BowtieOnboardingViewModel.isOnboardingCompleted`. If false, present `BowtieOnboardingView` as full-screen cover before showing the session.

- [ ] **Step 8: Build and test**

- [ ] **Step 9: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieOnboardingViewModel.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieOnboardingView.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieOnboardingViewModelTests.swift ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieSessionViewModel.swift
git commit -m "feat(ios): add Bowtie onboarding flow and guided session mode"
```

---

## Phase 5 — History & Integration

### Task 11: History + Analytics Views

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieHistoryViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieHistoryView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieInsightsView.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieHistoryViewModelTests.swift`

- [ ] **Step 1: Write BowtieHistoryViewModel tests**

Tests for: loading completed sessions sorted by date, I-distribution aggregation, role activation ranking, anticipatory ratio computation.

- [ ] **Step 2: Run tests to verify they fail**

- [ ] **Step 3: Implement BowtieHistoryViewModel**

```swift
import Foundation
import SwiftData

@Observable
class BowtieHistoryViewModel {

    var completedSessions: [RRBowtieSession] = []

    func loadSessions(context: ModelContext) {
        let descriptor = FetchDescriptor<RRBowtieSession>(
            predicate: #Predicate { $0.status == "complete" },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        completedSessions = (try? context.fetch(descriptor)) ?? []
    }

    func deleteSession(_ session: RRBowtieSession, context: ModelContext) {
        context.delete(session)
        loadSessions(context: context)
    }

    // MARK: - Analytics

    struct IDistribution {
        var insignificance: Int = 0
        var incompetence: Int = 0
        var impotence: Int = 0
    }

    var pastIDistribution: IDistribution {
        var dist = IDistribution()
        for session in completedSessions {
            dist.insignificance += session.pastInsignificanceTotal
            dist.incompetence += session.pastIncompetenceTotal
            dist.impotence += session.pastImpotenceTotal
        }
        return dist
    }

    var futureIDistribution: IDistribution {
        var dist = IDistribution()
        for session in completedSessions {
            dist.insignificance += session.futureInsignificanceTotal
            dist.incompetence += session.futureIncompetenceTotal
            dist.impotence += session.futureImpotenceTotal
        }
        return dist
    }

    struct RoleActivation: Identifiable {
        let id: UUID
        let label: String
        var totalIntensity: Int
        var frequency: Int
    }

    func roleActivations(roles: [RRUserRole]) -> [RoleActivation] {
        var activations: [UUID: RoleActivation] = [:]
        for role in roles {
            activations[role.id] = RoleActivation(id: role.id, label: role.label, totalIntensity: 0, frequency: 0)
        }
        for session in completedSessions {
            for marker in session.markers {
                if var activation = activations[marker.roleId] {
                    activation.totalIntensity += marker.totalIntensity
                    activation.frequency += 1
                    activations[marker.roleId] = activation
                }
            }
        }
        return activations.values.sorted { $0.totalIntensity > $1.totalIntensity }
    }

    var anticipatoryRatio: Double {
        let totalPast = completedSessions.reduce(0) { $0 + $1.pastMarkers.count }
        let totalFuture = completedSessions.reduce(0) { $0 + $1.futureMarkers.count }
        let total = totalPast + totalFuture
        guard total > 0 else { return 0 }
        return Double(totalFuture) / Double(total)
    }

    var backboneCompletionRate: Double {
        let totalMarkers = completedSessions.reduce(0) { $0 + $1.markers.count }
        let processedMarkers = completedSessions.reduce(0) { $0 + $1.processedMarkerCount }
        guard totalMarkers > 0 else { return 0 }
        return Double(processedMarkers) / Double(totalMarkers)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

- [ ] **Step 5: Implement BowtieHistoryView**

NavigationStack list:
- Each row: date, roles examined (comma-separated labels), past/future tally summary, processing status (e.g., "3 of 5 processed")
- Tap → navigate to `BowtieSessionView` in read-only mode (pass the session, disable editing)
- Swipe to delete with confirmation dialog
- Empty state: PRD Section 12.3 text
- "Insights" button in toolbar → navigate to `BowtieInsightsView`

- [ ] **Step 6: Implement BowtieInsightsView**

Three sections:
- **I-Distribution:** bar chart (use SwiftUI Charts if available, or simple HStack-based bars) showing total intensity per I-type. Growth framing: "Your primary emotional vulnerability is [most activated I]."
- **Role Activation:** ranked list of roles by total activation. "The roles carrying the most emotional weight right now."
- **Anticipatory Ratio:** percentage display + trend description. "Your anticipatory awareness is [X]% — [growth message]."

- [ ] **Step 7: Wire history access**

Add a "History" NavigationLink in `BowtieSessionView` toolbar or as a section at the bottom of the session setup screen.

- [ ] **Step 8: Build and test**

- [ ] **Step 9: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/Bowtie/BowtieHistoryViewModel.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieHistoryView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BowtieInsightsView.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Bowtie/BowtieHistoryViewModelTests.swift
git commit -m "feat(ios): add Bowtie history list and analytics insights"
```

---

### Task 12: Entry Points + Cross-Feature Bridges

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERResultsView.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BackboneFlowView.swift`

- [ ] **Step 1: Add post-relapse Bowtie suggestion**

In `BowtieSessionView`, accept an optional `relapseTimestamp: Date?` init parameter. When provided, pre-set `entryPath` to `.postRelapse` and `referenceTimestamp` to the relapse time. The suggestion card itself will be wired from wherever the sobriety reset flow presents its completion — add a conditional NavigationLink or button that appears when `activity.bowtie` is enabled:

```swift
if FeatureFlagStore.shared.isEnabled("activity.bowtie") {
    VStack(alignment: .leading, spacing: 8) {
        Text("Understanding what happened starts with knowing what was going on inside you. A Bowtie Diagram can help.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        NavigationLink("Start Bowtie") {
            BowtieSessionView(relapseTimestamp: relapseDate)
        }
        .buttonStyle(.borderedProminent)
        .tint(.rrPrimary)
    }
}
```

- [ ] **Step 2: Add FASTER Scale follow-up suggestion**

In `FASTERResultsView.swift`, after the results display, add a conditional suggestion when assessed stage is `.speedingUp` or higher:

```swift
if FeatureFlagStore.shared.isEnabled("activity.bowtie"),
   viewModel.assessedStage.rawValue >= FASTERStage.speedingUp.rawValue {
    VStack(alignment: .leading, spacing: 8) {
        Text("Your FASTER Scale shows acceleration. A Bowtie Diagram can help you see what emotional activations are driving it.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        NavigationLink("Start Bowtie") {
            BowtieSessionView()
        }
        .buttonStyle(.bordered)
        .tint(.rrPrimary)
    }
    .padding()
}
```

- [ ] **Step 3: Wire Journal bridge from Backbone**

In `BackboneFlowView`, when user selects "Journal" as an intimacy action on the final step, add a callback that the parent can use to navigate to the journal. Pass pre-fill context:

```swift
// In BackboneFlowView's completion handler:
if selectedActions.contains(where: { $0.label == "Journal" }) {
    onJournalRequested?("""
    Bowtie Processing: \(viewModel.lifeSituation)
    Emotions: \(viewModel.selectedEmotions.sorted().joined(separator: ", "))
    Needs: \(viewModel.selectedNeeds.sorted().joined(separator: ", "))
    """)
}
```

- [ ] **Step 4: Wire Affirmation bridge from Backbone**

When user selects "Speak Truth Over Yourself", add a callback that navigates to `AffirmationPackPickerView`:

```swift
if selectedActions.contains(where: { $0.label == "Speak Truth Over Yourself" }) {
    onAffirmationRequested?()
}
```

- [ ] **Step 5: Build and test**

- [ ] **Step 6: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Activities/FASTER/FASTERResultsView.swift ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/BackboneFlowView.swift
git commit -m "feat(ios): wire Bowtie entry points and cross-feature bridges"
```

---

## Phase 6 — Accessibility

### Task 13: Accessibility Audit + Polish

**Files:**
- Modify: All Bowtie view files

- [ ] **Step 1: VoiceOver audit**

Review every Bowtie view for:
- All interactive elements have `.accessibilityLabel()` and `.accessibilityHint()`
- `BowtieDiagramView` announces structured summary, not visual description
- `BowtieListEntryView` marker cards announce: role, I-type, intensity, processed status
- Emotion/need chips announce selection state
- Slider values announced

- [ ] **Step 2: Dynamic Type**

- All text uses semantic font styles (`.title`, `.headline`, `.body`, `.subheadline`, `.caption`)
- No hardcoded font sizes
- Test at maximum accessibility text size — verify no truncation of critical content
- `BowtieDiagramView` gracefully degrades: labels abbreviate, markers stack

- [ ] **Step 3: Touch targets**

Verify all interactive elements meet 44x44pt minimum:
- Marker dots on diagram
- Emotion chips
- Role chips
- Slider thumbs
- Navigation buttons

- [ ] **Step 4: Color independence**

Verify every color-coded element has an accompanying icon or label:
- I-type markers: color + icon (person.slash / xmark.shield / lock.fill)
- Past vs future markers: color + shape (filled vs outlined)
- Tallies: color + text label

- [ ] **Step 5: Reduced Motion + High Contrast**

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
@Environment(\.colorSchemeContrast) private var contrast
```

- Disable swipe transition animations when reduceMotion is true
- Disable diagram marker placement animations when reduceMotion is true
- Ensure all colors pass 4.5:1 contrast ratio in increased contrast mode

- [ ] **Step 6: Tone and language review**

Review all user-facing strings against PRD Section 12:
- No clinical/triggering language
- Counselor tone throughout
- Empty states match PRD 12.3
- Completion messages match PRD 12.4
- All text at 8th-grade reading level

- [ ] **Step 7: Build and test**

- [ ] **Step 8: Commit**

```bash
git add -A ios/RegalRecovery/RegalRecovery/Views/Activities/Bowtie/
git commit -m "feat(ios): accessibility audit and polish for Bowtie Diagram"
```

---

## Summary

| Phase | Tasks | Parallelizable | Deliverable |
|-------|-------|---------------|-------------|
| 1 | 1, 2, 3 | Yes (1+2 parallel, 3 after both) | Data layer + roles manager |
| 2 | 4, 5 | Yes | Feature flag + working session with past plotting |
| 3 | 6, 7 | Yes | Full past+future plotting with visual diagram |
| 4 | 8, 9, 10 | Yes | Backbone, PPP, guided mode + onboarding |
| 5 | 11, 12 | Yes | History, analytics, entry points, bridges |
| 6 | 13 | No | Accessibility + polish |

**Total: 13 tasks, 6 phases.** After Phase 2, the feature is a usable MVP (create session, plot markers, see tallies). Each subsequent phase adds depth.
