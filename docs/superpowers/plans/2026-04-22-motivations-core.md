# Motivations Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Motivations feature's core engine — data models, repository, types, feature flag, library UI, CRUD operations, guided discovery exercise, quick capture, and crisis surfacing during urge/SOS flows.

**Architecture:** SwiftData models (`RRMotivation`, `RRMotivationHistory`) with a `MotivationRepository` protocol and `@ModelActor` implementation. An `@Observable` ViewModel drives the library, capture, and discovery views. The surfacing algorithm selects motivations by importance, freshness, and photo presence. All operations are offline-first via local SwiftData persistence.

**Tech Stack:** Swift 5.10+, iOS 17+, SwiftUI, SwiftData, Swift Testing, Observation framework

**PRD Reference:** `docs/prd/specific-features/Motivations/functional-requirements.md`

**Scope:** This plan covers P0 requirements (FR-M-001 through FR-M-010, FR-M-013, FR-M-027, FR-M-028, FR-M-029) plus the types, feature flag, and activity type registration needed for the feature to function. P1/P2 features (photo attachments, confidence ratings, milestone surfacing, evolution timeline, effectiveness tracking, integrations with morning/evening/journal/affirmations/three-circles/post-mortem, accountability sharing, quarterly review) are deferred to follow-up plans.

---

## File Structure

### New Files

| File | Responsibility |
|------|---------------|
| `Models/MotivationTypes.swift` | `MotivationCategory` enum, `MotivationSource` enum, `MotivationImportanceLabel`, discovery step enum, surfacing context enum |
| `Data/Models/RRMotivationModels.swift` | `RRMotivation` and `RRMotivationHistory` SwiftData `@Model` classes |
| `Data/Repositories/MotivationRepository.swift` | `MotivationRepository` protocol definition |
| `Data/Repositories/SwiftDataMotivationRepository.swift` | `@ModelActor` implementation of `MotivationRepository` |
| `ViewModels/MotivationLibraryViewModel.swift` | `@Observable` VM for library display, CRUD, sorting |
| `ViewModels/MotivationDiscoveryViewModel.swift` | `@Observable` VM for the guided discovery wizard |
| `Views/Tools/Motivations/MotivationLibraryView.swift` | Main hub: category-grouped list, empty state, summary bar |
| `Views/Tools/Motivations/MotivationDetailView.swift` | Single motivation detail: text, category, importance, scripture, edit/delete |
| `Views/Tools/Motivations/MotivationCaptureSheet.swift` | Quick-add sheet: text, category picker, importance, scripture |
| `Views/Tools/Motivations/MotivationDiscoveryView.swift` | Multi-step guided discovery wizard |
| `Views/Tools/Motivations/MotivationSurfacingCard.swift` | Reusable card for surfacing a motivation in various contexts |
| `Services/MotivationSurfacingService.swift` | Stateless algorithm: picks best motivation(s) for a given context |
| `Tests/Unit/MotivationLibraryViewModelTests.swift` | Tests for library VM CRUD and sorting |
| `Tests/Unit/MotivationDiscoveryViewModelTests.swift` | Tests for discovery wizard flow |
| `Tests/Unit/MotivationSurfacingServiceTests.swift` | Tests for the surfacing selection algorithm |

### Modified Files

| File | Change |
|------|--------|
| `Models/Types.swift` | Add `motivations` case to `ActivityType` enum and `ActivitySection` |
| `Data/Models/RRModels.swift` | Register new models in `RRModelConfiguration.allModels` |
| `Services/FeatureFlagStore.swift` | Add `"activity.motivations": true` to `flagDefaults` |
| `Views/Tools/ToolsView.swift` | Add Motivations tool card gated by feature flag |

---

## Task 1: Motivation Types

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Models/MotivationTypes.swift`

- [ ] **Step 1: Create MotivationTypes.swift with all enums**

```swift
import Foundation
import SwiftUI

// MARK: - Motivation Category

enum MotivationCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case spiritual = "Spiritual"
    case relational = "Relational"
    case health = "Health"
    case professional = "Professional"
    case personalGrowth = "Personal Growth"
    case financial = "Financial"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spiritual: return String(localized: "Spiritual")
        case .relational: return String(localized: "Relational")
        case .health: return String(localized: "Health")
        case .professional: return String(localized: "Professional")
        case .personalGrowth: return String(localized: "Personal Growth")
        case .financial: return String(localized: "Financial")
        }
    }

    var icon: String {
        switch self {
        case .spiritual: return "hands.and.sparkles"
        case .relational: return "heart.fill"
        case .health: return "figure.walk"
        case .professional: return "briefcase.fill"
        case .personalGrowth: return "leaf.fill"
        case .financial: return "banknote.fill"
        }
    }

    var color: Color {
        switch self {
        case .spiritual: return .rrPrimary
        case .relational: return .rrDestructive
        case .health: return .rrSuccess
        case .professional: return .blue
        case .personalGrowth: return .purple
        case .financial: return .green
        }
    }
}

// MARK: - Motivation Source

enum MotivationSource: String, Codable, Sendable {
    case discovery
    case manual
}

// MARK: - Importance Labels

enum MotivationImportance {
    static let labels: [Int: String] = [
        1: String(localized: "Meaningful"),
        2: String(localized: "Important"),
        3: String(localized: "Very Important"),
        4: String(localized: "Core to My Recovery"),
        5: String(localized: "Non-Negotiable"),
    ]

    static let defaultRating: Int = 3
    static let range: ClosedRange<Int> = 1...5

    static func label(for rating: Int) -> String {
        labels[rating] ?? labels[3]!
    }
}

// MARK: - Discovery Steps

enum MotivationDiscoveryStep: Int, CaseIterable {
    case intro = 0
    case miracleQuestion
    case valuesSelection
    case concretePrompts
    case summary

    var title: String {
        switch self {
        case .intro: return String(localized: "Welcome")
        case .miracleQuestion: return String(localized: "Imagine")
        case .valuesSelection: return String(localized: "Values")
        case .concretePrompts: return String(localized: "Your Why")
        case .summary: return String(localized: "Review")
        }
    }

    static let totalSteps = 5

    var progressFraction: Double {
        Double(rawValue + 1) / Double(Self.totalSteps)
    }
}

// MARK: - Surfacing Context

enum SurfacingContext: String, Codable, Sendable {
    case urgeLog
    case sosFlow
    case moodCheckIn
    case fasterScale
    case eveningReview
    case milestone
    case sobrietyReset
    case morningCommitment
    case postMortem

    var prioritizedCategories: [MotivationCategory] {
        switch self {
        case .urgeLog, .sosFlow: return [.relational, .spiritual]
        case .moodCheckIn: return [.spiritual, .health]
        case .fasterScale: return [.personalGrowth, .spiritual]
        case .milestone: return []
        case .sobrietyReset: return [.spiritual, .relational]
        case .morningCommitment, .eveningReview, .postMortem: return []
        }
    }
}

// MARK: - Motivation Change Type

enum MotivationChangeType: String, Codable, Sendable {
    case created
    case textEdited
    case importanceChanged
    case categoryChanged
    case scriptureChanged
    case archived
    case restored
    case deleted
}

// MARK: - Limits

enum MotivationLimits {
    static let maxTextLength = 500
    static let maxScriptureLength = 200
    static let maxValuesSelection = 5
    static let surfacingCooldownHours = 24
    static let freeLibraryLimit = 10
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED (or at least no errors in MotivationTypes.swift)

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Models/MotivationTypes.swift
git commit -m "feat(motivations): add MotivationCategory, MotivationSource, and supporting type enums"
```

---

## Task 2: SwiftData Models

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Data/Models/RRMotivationModels.swift`
- Modify: `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift` (lines ~1494-1528, add to `allModels`)

- [ ] **Step 1: Create RRMotivationModels.swift with RRMotivation and RRMotivationHistory**

```swift
import Foundation
import SwiftData

// MARK: - Motivation

@Model
final class RRMotivation {

    @Attribute(.unique) var id: UUID
    var userId: UUID
    var text: String
    var category: String
    var importanceRating: Int
    var scriptureReference: String?
    var isArchived: Bool
    var source: String
    var lastSurfacedAt: Date?
    var surfaceCount: Int
    var reflectionCount: Int
    var createdAt: Date
    var modifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        text: String,
        category: MotivationCategory,
        importanceRating: Int = MotivationImportance.defaultRating,
        scriptureReference: String? = nil,
        isArchived: Bool = false,
        source: MotivationSource = .manual,
        lastSurfacedAt: Date? = nil,
        surfaceCount: Int = 0,
        reflectionCount: Int = 0,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.text = text
        self.category = category.rawValue
        self.importanceRating = importanceRating
        self.scriptureReference = scriptureReference
        self.isArchived = isArchived
        self.source = source.rawValue
        self.lastSurfacedAt = lastSurfacedAt
        self.surfaceCount = surfaceCount
        self.reflectionCount = reflectionCount
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    var motivationCategory: MotivationCategory {
        MotivationCategory(rawValue: category) ?? .personalGrowth
    }

    var motivationSource: MotivationSource {
        MotivationSource(rawValue: source) ?? .manual
    }

    var importanceLabel: String {
        MotivationImportance.label(for: importanceRating)
    }
}

// MARK: - Motivation History

@Model
final class RRMotivationHistory {

    @Attribute(.unique) var id: UUID
    var motivationId: UUID
    var changeType: String
    var previousValue: String?
    var newValue: String?
    var timestamp: Date

    init(
        id: UUID = UUID(),
        motivationId: UUID,
        changeType: MotivationChangeType,
        previousValue: String? = nil,
        newValue: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.motivationId = motivationId
        self.changeType = changeType.rawValue
        self.previousValue = previousValue
        self.newValue = newValue
        self.timestamp = timestamp
    }

    var motivationChangeType: MotivationChangeType {
        MotivationChangeType(rawValue: changeType) ?? .created
    }
}
```

- [ ] **Step 2: Register models in RRModelConfiguration.allModels**

In `ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift`, add `RRMotivation.self` and `RRMotivationHistory.self` to the `allModels` array, just before the closing bracket `]` (around line 1528):

```swift
        RRQuickActionItem.self,
        RRMotivation.self,
        RRMotivationHistory.self,
    ]
```

- [ ] **Step 3: Verify the file compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Data/Models/RRMotivationModels.swift ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift
git commit -m "feat(motivations): add RRMotivation and RRMotivationHistory SwiftData models"
```

---

## Task 3: Repository Protocol and Implementation

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Data/Repositories/MotivationRepository.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Data/Repositories/SwiftDataMotivationRepository.swift`

- [ ] **Step 1: Create MotivationRepository protocol**

```swift
import Foundation

// MARK: - Motivation Repository

protocol MotivationRepository: Sendable {
    func save(_ motivation: RRMotivation) async throws
    func getAll(includeArchived: Bool) async throws -> [RRMotivation]
    func getByCategory(_ category: MotivationCategory) async throws -> [RRMotivation]
    func get(id: UUID) async throws -> RRMotivation?
    func delete(id: UUID) async throws
    func count() async throws -> Int
    func getActive() async throws -> [RRMotivation]
    func saveHistory(_ history: RRMotivationHistory) async throws
    func getHistory(for motivationId: UUID) async throws -> [RRMotivationHistory]
}
```

- [ ] **Step 2: Create SwiftDataMotivationRepository implementation**

```swift
import Foundation
import SwiftData

// MARK: - SwiftData Motivation Repository

@ModelActor
actor SwiftDataMotivationRepository: MotivationRepository {

    func save(_ motivation: RRMotivation) async throws {
        modelContext.insert(motivation)
        try modelContext.save()
    }

    func getAll(includeArchived: Bool) async throws -> [RRMotivation] {
        var descriptor = FetchDescriptor<RRMotivation>(
            sortBy: [
                SortDescriptor(\.importanceRating, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        )
        if !includeArchived {
            descriptor.predicate = #Predicate { $0.isArchived == false }
        }
        return try modelContext.fetch(descriptor)
    }

    func getByCategory(_ category: MotivationCategory) async throws -> [RRMotivation] {
        let categoryRaw = category.rawValue
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.category == categoryRaw && $0.isArchived == false },
            sortBy: [
                SortDescriptor(\.importanceRating, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        )
        return try modelContext.fetch(descriptor)
    }

    func get(id: UUID) async throws -> RRMotivation? {
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func delete(id: UUID) async throws {
        if let motivation = try await get(id: id) {
            let motivationId = motivation.id
            let historyDescriptor = FetchDescriptor<RRMotivationHistory>(
                predicate: #Predicate { $0.motivationId == motivationId }
            )
            let history = try modelContext.fetch(historyDescriptor)
            for entry in history {
                modelContext.delete(entry)
            }
            modelContext.delete(motivation)
            try modelContext.save()
        }
    }

    func count() async throws -> Int {
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.isArchived == false }
        )
        return try modelContext.fetchCount(descriptor)
    }

    func getActive() async throws -> [RRMotivation] {
        try await getAll(includeArchived: false)
    }

    func saveHistory(_ history: RRMotivationHistory) async throws {
        modelContext.insert(history)
        try modelContext.save()
    }

    func getHistory(for motivationId: UUID) async throws -> [RRMotivationHistory] {
        let descriptor = FetchDescriptor<RRMotivationHistory>(
            predicate: #Predicate { $0.motivationId == motivationId },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
```

- [ ] **Step 3: Verify the files compile**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Data/Repositories/MotivationRepository.swift ios/RegalRecovery/RegalRecovery/Data/Repositories/SwiftDataMotivationRepository.swift
git commit -m "feat(motivations): add MotivationRepository protocol and SwiftData implementation"
```

---

## Task 4: Feature Flag and Activity Type Registration

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Services/FeatureFlagStore.swift` (~line 131)
- Modify: `ios/RegalRecovery/RegalRecovery/Models/Types.swift` (~lines 84-200)

- [ ] **Step 1: Add feature flag to FeatureFlagStore.flagDefaults**

In `ios/RegalRecovery/RegalRecovery/Services/FeatureFlagStore.swift`, add to the `flagDefaults` dictionary in the "Recovery Work & Tools" section (after `"feature.post-mortem": false,`):

```swift
        "activity.motivations": true,
```

- [ ] **Step 2: Add motivations case to ActivityType enum**

In `ios/RegalRecovery/RegalRecovery/Models/Types.swift`, add after the `case affirmationLog = "Affirmation Log"` line:

```swift
    case motivations = "Motivations"
```

Add to `displayName`:
```swift
        case .motivations: return String(localized: "Motivations")
```

Add to `icon`:
```swift
        case .motivations: return "flame.fill"
```

Add to `iconColor`:
```swift
        case .motivations: return .orange
```

Add to `section` (in the `.growth` case group, after `.affirmationLog`):
```swift
        case .motivations:
            return .growth
```

- [ ] **Step 3: Add DailyEligibleActivity entry for motivations**

In `ios/RegalRecovery/RegalRecovery/Models/Types.swift`, in the `DailyEligibleActivity.all` static array (after the last entry before the closing `]`), add:

```swift
        DailyEligibleActivity(
            activityType: ActivityType.motivations.rawValue,
            displayNameKey: "Motivations",
            shortNameKey: "Motivations",
            icon: "flame.fill",
            multiplePerDay: false,
            maxPerDay: 1,
            defaultEnabled: false,
            typicalHour: 7,
            typicalMinute: 0,
            typicalBlock: "Morning",
            featureFlagKey: "activity.motivations",
            section: .growth
        ),
```

- [ ] **Step 4: Verify the files compile**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Services/FeatureFlagStore.swift ios/RegalRecovery/RegalRecovery/Models/Types.swift
git commit -m "feat(motivations): register activity.motivations feature flag and ActivityType"
```

---

## Task 5: Surfacing Service

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Services/MotivationSurfacingService.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/MotivationSurfacingServiceTests.swift`

- [ ] **Step 1: Write the failing tests for surfacing**

```swift
import Testing
@testable import RegalRecovery
import Foundation

@Suite("MotivationSurfacingService Tests")
struct MotivationSurfacingServiceTests {

    private func makeMotivation(
        text: String = "Test",
        category: MotivationCategory = .spiritual,
        importance: Int = 3,
        isArchived: Bool = false,
        lastSurfacedAt: Date? = nil,
        surfaceCount: Int = 0
    ) -> RRMotivation {
        RRMotivation(
            userId: UUID(),
            text: text,
            category: category,
            importanceRating: importance,
            isArchived: isArchived,
            lastSurfacedAt: lastSurfacedAt,
            surfaceCount: surfaceCount
        )
    }

    @Test("returns empty array when library is empty")
    func testEmptyLibrary() {
        let result = MotivationSurfacingService.select(
            from: [],
            context: .urgeLog,
            count: 1
        )
        #expect(result.isEmpty)
    }

    @Test("excludes archived motivations")
    func testExcludesArchived() {
        let archived = makeMotivation(text: "Archived", isArchived: true, importance: 5)
        let active = makeMotivation(text: "Active", importance: 3)
        let result = MotivationSurfacingService.select(
            from: [archived, active],
            context: .urgeLog,
            count: 1
        )
        #expect(result.count == 1)
        #expect(result.first?.text == "Active")
    }

    @Test("prioritizes higher importance")
    func testPrioritizesImportance() {
        let low = makeMotivation(text: "Low", importance: 1)
        let high = makeMotivation(text: "High", importance: 5)
        let result = MotivationSurfacingService.select(
            from: [low, high],
            context: .urgeLog,
            count: 1
        )
        #expect(result.first?.text == "High")
    }

    @Test("prioritizes category match for context")
    func testCategoryMatchBoost() {
        let spiritual = makeMotivation(text: "Spiritual", category: .spiritual, importance: 3)
        let financial = makeMotivation(text: "Financial", category: .financial, importance: 3)
        let result = MotivationSurfacingService.select(
            from: [financial, spiritual],
            context: .urgeLog,
            count: 1
        )
        #expect(result.first?.text == "Spiritual")
    }

    @Test("respects requested count")
    func testRespectsCount() {
        let m1 = makeMotivation(text: "One", importance: 5)
        let m2 = makeMotivation(text: "Two", importance: 4)
        let m3 = makeMotivation(text: "Three", importance: 3)
        let result = MotivationSurfacingService.select(
            from: [m1, m2, m3],
            context: .urgeLog,
            count: 2
        )
        #expect(result.count == 2)
    }

    @Test("deprioritizes recently surfaced")
    func testFreshnessBonus() {
        let recent = makeMotivation(text: "Recent", importance: 5, lastSurfacedAt: Date())
        let stale = makeMotivation(text: "Stale", importance: 5, lastSurfacedAt: Date().addingTimeInterval(-86400 * 10))
        let result = MotivationSurfacingService.select(
            from: [recent, stale],
            context: .urgeLog,
            count: 1
        )
        #expect(result.first?.text == "Stale")
    }

    @Test("returns all when fewer than requested count")
    func testFewerThanRequested() {
        let m1 = makeMotivation(text: "Only one")
        let result = MotivationSurfacingService.select(
            from: [m1],
            context: .urgeLog,
            count: 3
        )
        #expect(result.count == 1)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/MotivationSurfacingServiceTests -quiet 2>&1 | tail -10`

Expected: FAIL — `MotivationSurfacingService` not defined

- [ ] **Step 3: Implement MotivationSurfacingService**

```swift
import Foundation

enum MotivationSurfacingService {

    static func select(
        from motivations: [RRMotivation],
        context: SurfacingContext,
        count: Int
    ) -> [RRMotivation] {
        let active = motivations.filter { !$0.isArchived }
        guard !active.isEmpty else { return [] }

        let prioritizedCategories = context.prioritizedCategories
        let now = Date()

        let scored = active.map { motivation -> (RRMotivation, Double) in
            var score = Double(motivation.importanceRating) * 3.0

            if prioritizedCategories.contains(motivation.motivationCategory) {
                score += 1.0
            }

            if let lastSurfaced = motivation.lastSurfacedAt {
                let daysSince = now.timeIntervalSince(lastSurfaced) / 86400.0
                score += min(daysSince * 0.1, 3.0)
            } else {
                score += 3.0
            }

            return (motivation, score)
        }

        let sorted = scored.sorted { $0.1 > $1.1 }
        let selected = sorted.prefix(count).map(\.0)
        return Array(selected)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/MotivationSurfacingServiceTests -quiet 2>&1 | tail -10`

Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Services/MotivationSurfacingService.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/MotivationSurfacingServiceTests.swift
git commit -m "feat(motivations): add surfacing algorithm with importance/context/freshness scoring"
```

---

## Task 6: MotivationLibraryViewModel

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/MotivationLibraryViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/MotivationLibraryViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import RegalRecovery
import Foundation

@Suite("MotivationLibraryViewModel Tests")
struct MotivationLibraryViewModelTests {

    @Test("initial state is empty")
    func testInitialState() {
        let vm = MotivationLibraryViewModel()
        #expect(vm.motivations.isEmpty)
        #expect(!vm.isLoading)
        #expect(vm.error == nil)
    }

    @Test("addMotivation appends to motivations")
    func testAddMotivation() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(
            text: "My daughter deserves a present father",
            category: .relational,
            importanceRating: 5,
            scriptureReference: "Prov 22:6",
            source: .manual
        )
        #expect(vm.motivations.count == 1)
        #expect(vm.motivations.first?.text == "My daughter deserves a present father")
        #expect(vm.motivations.first?.motivationCategory == .relational)
        #expect(vm.motivations.first?.importanceRating == 5)
        #expect(vm.motivations.first?.scriptureReference == "Prov 22:6")
    }

    @Test("addMotivation trims whitespace")
    func testTrimsWhitespace() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(
            text: "  Integrity before God  ",
            category: .spiritual,
            importanceRating: 4,
            scriptureReference: nil,
            source: .manual
        )
        #expect(vm.motivations.first?.text == "Integrity before God")
    }

    @Test("deleteMotivation removes from list")
    func testDeleteMotivation() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "To delete", category: .health, importanceRating: 3, scriptureReference: nil, source: .manual)
        let id = vm.motivations.first!.id
        vm.deleteMotivation(id: id)
        #expect(vm.motivations.isEmpty)
    }

    @Test("updateMotivation modifies text and updates modifiedAt")
    func testUpdateMotivation() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "Original", category: .spiritual, importanceRating: 3, scriptureReference: nil, source: .manual)
        let id = vm.motivations.first!.id
        let originalModifiedAt = vm.motivations.first!.modifiedAt

        vm.updateMotivation(id: id, text: "Updated", category: .spiritual, importanceRating: 4, scriptureReference: "Rom 8:28")

        let updated = vm.motivations.first { $0.id == id }
        #expect(updated?.text == "Updated")
        #expect(updated?.importanceRating == 4)
        #expect(updated?.scriptureReference == "Rom 8:28")
        #expect(updated!.modifiedAt >= originalModifiedAt)
    }

    @Test("groupedByCategory returns categories in order")
    func testGroupedByCategory() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "Spiritual one", category: .spiritual, importanceRating: 3, scriptureReference: nil, source: .manual)
        vm.addMotivation(text: "Family one", category: .relational, importanceRating: 5, scriptureReference: nil, source: .manual)
        vm.addMotivation(text: "Spiritual two", category: .spiritual, importanceRating: 4, scriptureReference: nil, source: .manual)

        let grouped = vm.groupedByCategory
        #expect(grouped.count == 2)

        let spiritualGroup = grouped.first { $0.category == .spiritual }
        #expect(spiritualGroup != nil)
        #expect(spiritualGroup!.motivations.count == 2)
        #expect(spiritualGroup!.motivations.first?.importanceRating == 4)
    }

    @Test("addMotivation validates text is not empty")
    func testRejectsEmptyText() {
        let vm = MotivationLibraryViewModel()
        vm.addMotivation(text: "   ", category: .spiritual, importanceRating: 3, scriptureReference: nil, source: .manual)
        #expect(vm.motivations.isEmpty)
        #expect(vm.error != nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/MotivationLibraryViewModelTests -quiet 2>&1 | tail -10`

Expected: FAIL — `MotivationLibraryViewModel` not defined

- [ ] **Step 3: Implement MotivationLibraryViewModel**

```swift
import Foundation
import Observation
import SwiftData

@Observable
final class MotivationLibraryViewModel {

    // MARK: - State

    var motivations: [RRMotivation] = []
    var isLoading: Bool = false
    var error: String?

    // MARK: - Grouped Access

    struct CategoryGroup: Identifiable {
        let category: MotivationCategory
        let motivations: [RRMotivation]
        var id: String { category.rawValue }
    }

    var groupedByCategory: [CategoryGroup] {
        let active = motivations.filter { !$0.isArchived }
        let grouped = Dictionary(grouping: active) { $0.motivationCategory }
        return MotivationCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            let sorted = items.sorted {
                if $0.importanceRating != $1.importanceRating {
                    return $0.importanceRating > $1.importanceRating
                }
                return $0.createdAt > $1.createdAt
            }
            return CategoryGroup(category: category, motivations: sorted)
        }
    }

    var totalCount: Int {
        motivations.filter { !$0.isArchived }.count
    }

    var isEmpty: Bool {
        motivations.filter { !$0.isArchived }.isEmpty
    }

    // MARK: - CRUD

    func addMotivation(
        text: String,
        category: MotivationCategory,
        importanceRating: Int,
        scriptureReference: String?,
        source: MotivationSource
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Motivation text cannot be empty"
            return
        }
        let clamped = max(1, min(5, importanceRating))
        let truncated = String(trimmed.prefix(MotivationLimits.maxTextLength))
        let scripture = scriptureReference?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanScripture = (scripture?.isEmpty ?? true) ? nil : scripture

        let motivation = RRMotivation(
            userId: UUID(),
            text: truncated,
            category: category,
            importanceRating: clamped,
            scriptureReference: cleanScripture,
            source: source
        )
        motivations.insert(motivation, at: 0)
        error = nil
    }

    func deleteMotivation(id: UUID) {
        motivations.removeAll { $0.id == id }
    }

    func updateMotivation(
        id: UUID,
        text: String,
        category: MotivationCategory,
        importanceRating: Int,
        scriptureReference: String?
    ) {
        guard let index = motivations.firstIndex(where: { $0.id == id }) else { return }
        let motivation = motivations[index]
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "Motivation text cannot be empty"
            return
        }
        motivation.text = String(trimmed.prefix(MotivationLimits.maxTextLength))
        motivation.category = category.rawValue
        motivation.importanceRating = max(1, min(5, importanceRating))
        let scripture = scriptureReference?.trimmingCharacters(in: .whitespacesAndNewlines)
        motivation.scriptureReference = (scripture?.isEmpty ?? true) ? nil : scripture
        motivation.modifiedAt = Date()
        error = nil
    }

    // MARK: - Persistence

    func loadMotivations(context: ModelContext, userId: UUID) {
        isLoading = true
        let descriptor = FetchDescriptor<RRMotivation>(
            sortBy: [
                SortDescriptor(\.importanceRating, order: .reverse),
                SortDescriptor(\.createdAt, order: .reverse),
            ]
        )
        do {
            motivations = try context.fetch(descriptor)
        } catch {
            self.error = "Failed to load motivations"
        }
        isLoading = false
    }

    func saveMotivation(_ motivation: RRMotivation, context: ModelContext) {
        context.insert(motivation)
        try? context.save()
    }

    func persistDelete(id: UUID, context: ModelContext) {
        let descriptor = FetchDescriptor<RRMotivation>(
            predicate: #Predicate { $0.id == id }
        )
        if let motivation = try? context.fetch(descriptor).first {
            let motivationId = motivation.id
            let historyDescriptor = FetchDescriptor<RRMotivationHistory>(
                predicate: #Predicate { $0.motivationId == motivationId }
            )
            if let history = try? context.fetch(historyDescriptor) {
                for entry in history {
                    context.delete(entry)
                }
            }
            context.delete(motivation)
            try? context.save()
        }
    }

    func persistUpdate(_ motivation: RRMotivation, context: ModelContext) {
        try? context.save()
    }

    func recordHistory(
        motivationId: UUID,
        changeType: MotivationChangeType,
        previousValue: String?,
        newValue: String?,
        context: ModelContext
    ) {
        let history = RRMotivationHistory(
            motivationId: motivationId,
            changeType: changeType,
            previousValue: previousValue,
            newValue: newValue
        )
        context.insert(history)
        try? context.save()
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/MotivationLibraryViewModelTests -quiet 2>&1 | tail -10`

Expected: All 7 tests PASS

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/MotivationLibraryViewModel.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/MotivationLibraryViewModelTests.swift
git commit -m "feat(motivations): add MotivationLibraryViewModel with CRUD and category grouping"
```

---

## Task 7: MotivationDiscoveryViewModel

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/ViewModels/MotivationDiscoveryViewModel.swift`
- Create: `ios/RegalRecovery/RegalRecovery/Tests/Unit/MotivationDiscoveryViewModelTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
import Testing
@testable import RegalRecovery
import Foundation

@Suite("MotivationDiscoveryViewModel Tests")
struct MotivationDiscoveryViewModelTests {

    @Test("initial step is intro")
    func testInitialStep() {
        let vm = MotivationDiscoveryViewModel()
        #expect(vm.currentStep == .intro)
    }

    @Test("goToNextStep advances from intro to miracleQuestion")
    func testAdvanceFromIntro() {
        let vm = MotivationDiscoveryViewModel()
        vm.goToNextStep()
        #expect(vm.currentStep == .miracleQuestion)
    }

    @Test("goToNextStep advances from miracleQuestion to valuesSelection")
    func testAdvanceToValues() {
        let vm = MotivationDiscoveryViewModel()
        vm.currentStep = .miracleQuestion
        vm.goToNextStep()
        #expect(vm.currentStep == .valuesSelection)
    }

    @Test("goToNextStep advances from valuesSelection to concretePrompts")
    func testAdvanceToConcretePrompts() {
        let vm = MotivationDiscoveryViewModel()
        vm.currentStep = .valuesSelection
        vm.selectedValues = [.spiritual]
        vm.goToNextStep()
        #expect(vm.currentStep == .concretePrompts)
    }

    @Test("goToPreviousStep goes back from miracleQuestion to intro")
    func testGoBack() {
        let vm = MotivationDiscoveryViewModel()
        vm.currentStep = .miracleQuestion
        vm.goToPreviousStep()
        #expect(vm.currentStep == .intro)
    }

    @Test("toggleValue adds and removes")
    func testToggleValue() {
        let vm = MotivationDiscoveryViewModel()
        vm.toggleValue(.spiritual)
        #expect(vm.selectedValues.contains(.spiritual))
        vm.toggleValue(.spiritual)
        #expect(!vm.selectedValues.contains(.spiritual))
    }

    @Test("toggleValue caps at 5")
    func testMaxValues() {
        let vm = MotivationDiscoveryViewModel()
        vm.toggleValue(.spiritual)
        vm.toggleValue(.relational)
        vm.toggleValue(.health)
        vm.toggleValue(.professional)
        vm.toggleValue(.personalGrowth)
        vm.toggleValue(.financial)
        #expect(vm.selectedValues.count == 5)
        #expect(!vm.selectedValues.contains(.financial))
    }

    @Test("canProceed is false on valuesSelection with no values selected")
    func testCanProceedValues() {
        let vm = MotivationDiscoveryViewModel()
        vm.currentStep = .valuesSelection
        #expect(!vm.canProceed)
        vm.toggleValue(.health)
        #expect(vm.canProceed)
    }

    @Test("concretePromptCategories returns selected values")
    func testConcretePromptCategories() {
        let vm = MotivationDiscoveryViewModel()
        vm.selectedValues = [.spiritual, .relational]
        #expect(vm.concretePromptCategories == [.spiritual, .relational])
    }

    @Test("buildMotivations creates one motivation per concrete response")
    func testBuildMotivations() {
        let vm = MotivationDiscoveryViewModel()
        vm.selectedValues = [.spiritual, .relational]
        vm.concreteResponses[.spiritual] = "Walk in integrity before God"
        vm.concreteResponses[.relational] = "Be present for my daughter"
        vm.concreteScriptures[.spiritual] = "Psalm 51:10"

        let motivations = vm.buildMotivations(userId: UUID())
        #expect(motivations.count == 2)

        let spiritual = motivations.first { $0.motivationCategory == .spiritual }
        #expect(spiritual?.text == "Walk in integrity before God")
        #expect(spiritual?.scriptureReference == "Psalm 51:10")
        #expect(spiritual?.motivationSource == .discovery)

        let relational = motivations.first { $0.motivationCategory == .relational }
        #expect(relational?.text == "Be present for my daughter")
        #expect(relational?.scriptureReference == nil)
    }

    @Test("buildMotivations skips empty responses")
    func testBuildMotivationsSkipsEmpty() {
        let vm = MotivationDiscoveryViewModel()
        vm.selectedValues = [.spiritual, .relational]
        vm.concreteResponses[.spiritual] = "Walk in integrity"
        vm.concreteResponses[.relational] = "   "

        let motivations = vm.buildMotivations(userId: UUID())
        #expect(motivations.count == 1)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/MotivationDiscoveryViewModelTests -quiet 2>&1 | tail -10`

Expected: FAIL — `MotivationDiscoveryViewModel` not defined

- [ ] **Step 3: Implement MotivationDiscoveryViewModel**

```swift
import Foundation
import Observation

@Observable
final class MotivationDiscoveryViewModel {

    // MARK: - Flow State

    var currentStep: MotivationDiscoveryStep = .intro

    // MARK: - Data

    var miracleResponse: String = ""
    var selectedValues: [MotivationCategory] = []
    var concreteResponses: [MotivationCategory: String] = [:]
    var concreteScriptures: [MotivationCategory: String] = [:]
    var currentConcretePromptIndex: Int = 0

    // MARK: - Draft Persistence Key

    private static let draftKey = "motivations.discovery.draft"

    // MARK: - Navigation

    var canProceed: Bool {
        switch currentStep {
        case .intro:
            return true
        case .miracleQuestion:
            return true
        case .valuesSelection:
            return !selectedValues.isEmpty
        case .concretePrompts:
            return true
        case .summary:
            return true
        }
    }

    var canGoBack: Bool {
        currentStep != .intro
    }

    func goToNextStep() {
        switch currentStep {
        case .intro:
            currentStep = .miracleQuestion
        case .miracleQuestion:
            currentStep = .valuesSelection
        case .valuesSelection:
            currentConcretePromptIndex = 0
            currentStep = .concretePrompts
        case .concretePrompts:
            if currentConcretePromptIndex < selectedValues.count - 1 {
                currentConcretePromptIndex += 1
            } else {
                currentStep = .summary
            }
        case .summary:
            break
        }
    }

    func goToPreviousStep() {
        switch currentStep {
        case .intro:
            break
        case .miracleQuestion:
            currentStep = .intro
        case .valuesSelection:
            currentStep = .miracleQuestion
        case .concretePrompts:
            if currentConcretePromptIndex > 0 {
                currentConcretePromptIndex -= 1
            } else {
                currentStep = .valuesSelection
            }
        case .summary:
            currentConcretePromptIndex = max(0, selectedValues.count - 1)
            currentStep = .concretePrompts
        }
    }

    // MARK: - Values

    func toggleValue(_ category: MotivationCategory) {
        if let index = selectedValues.firstIndex(of: category) {
            selectedValues.remove(at: index)
            concreteResponses.removeValue(forKey: category)
            concreteScriptures.removeValue(forKey: category)
        } else if selectedValues.count < MotivationLimits.maxValuesSelection {
            selectedValues.append(category)
        }
    }

    var concretePromptCategories: [MotivationCategory] {
        selectedValues
    }

    var currentConcreteCategory: MotivationCategory? {
        guard currentConcretePromptIndex < selectedValues.count else { return nil }
        return selectedValues[currentConcretePromptIndex]
    }

    func concretePromptText(for category: MotivationCategory) -> String {
        switch category {
        case .spiritual:
            return String(localized: "You chose Spiritual. What about your faith specifically motivates your recovery?")
        case .relational:
            return String(localized: "You chose Relational. What specifically about your relationships motivates your recovery?")
        case .health:
            return String(localized: "You chose Health. What about your health specifically motivates your recovery?")
        case .professional:
            return String(localized: "You chose Professional. What about your career or calling motivates your recovery?")
        case .personalGrowth:
            return String(localized: "You chose Personal Growth. What kind of person are you becoming through recovery?")
        case .financial:
            return String(localized: "You chose Financial. What about your finances motivates your recovery?")
        }
    }

    // MARK: - Build Motivations

    func buildMotivations(userId: UUID) -> [RRMotivation] {
        selectedValues.compactMap { category in
            let text = concreteResponses[category]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !text.isEmpty else { return nil }
            let scripture = concreteScriptures[category]?.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanScripture = (scripture?.isEmpty ?? true) ? nil : scripture
            return RRMotivation(
                userId: userId,
                text: String(text.prefix(MotivationLimits.maxTextLength)),
                category: category,
                importanceRating: MotivationImportance.defaultRating,
                scriptureReference: cleanScripture,
                source: .discovery
            )
        }
    }

    // MARK: - Draft Persistence

    func saveDraft() {
        let draft: [String: Any] = [
            "step": currentStep.rawValue,
            "miracleResponse": miracleResponse,
            "selectedValues": selectedValues.map(\.rawValue),
            "concreteResponses": concreteResponses.reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value },
            "concreteScriptures": concreteScriptures.reduce(into: [String: String]()) { $0[$1.key.rawValue] = $1.value },
        ]
        UserDefaults.standard.set(draft, forKey: Self.draftKey)
    }

    func loadDraft() -> Bool {
        guard let draft = UserDefaults.standard.dictionary(forKey: Self.draftKey) else { return false }
        if let stepRaw = draft["step"] as? Int,
           let step = MotivationDiscoveryStep(rawValue: stepRaw) {
            currentStep = step
        }
        miracleResponse = draft["miracleResponse"] as? String ?? ""
        if let valuesRaw = draft["selectedValues"] as? [String] {
            selectedValues = valuesRaw.compactMap { MotivationCategory(rawValue: $0) }
        }
        if let responsesRaw = draft["concreteResponses"] as? [String: String] {
            concreteResponses = responsesRaw.reduce(into: [:]) { result, pair in
                if let cat = MotivationCategory(rawValue: pair.key) {
                    result[cat] = pair.value
                }
            }
        }
        if let scripturesRaw = draft["concreteScriptures"] as? [String: String] {
            concreteScriptures = scripturesRaw.reduce(into: [:]) { result, pair in
                if let cat = MotivationCategory(rawValue: pair.key) {
                    result[cat] = pair.value
                }
            }
        }
        return true
    }

    func clearDraft() {
        UserDefaults.standard.removeObject(forKey: Self.draftKey)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/MotivationDiscoveryViewModelTests -quiet 2>&1 | tail -10`

Expected: All 11 tests PASS

- [ ] **Step 5: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/ViewModels/MotivationDiscoveryViewModel.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/MotivationDiscoveryViewModelTests.swift
git commit -m "feat(motivations): add MotivationDiscoveryViewModel with multi-step wizard flow"
```

---

## Task 8: MotivationSurfacingCard (Reusable View)

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationSurfacingCard.swift`

- [ ] **Step 1: Create the reusable surfacing card view**

```swift
import SwiftUI

struct MotivationSurfacingCard: View {
    let motivation: RRMotivation
    let framing: String?
    var onTap: (() -> Void)?

    init(motivation: RRMotivation, framing: String? = nil, onTap: (() -> Void)? = nil) {
        self.motivation = motivation
        self.framing = framing
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    if let framing {
                        Text(framing)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: motivation.motivationCategory.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(motivation.motivationCategory.color)

                        Text(motivation.motivationCategory.displayName)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Text(motivation.text)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.leading)

                    if let scripture = motivation.scriptureReference {
                        Text("— \(scripture)")
                            .font(RRFont.caption)
                            .italic()
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Motivation: \(motivation.text). Category: \(motivation.motivationCategory.displayName). Importance: \(motivation.importanceRating) of 5."))
        .accessibilityHint(Text("Double tap to view details"))
    }
}

#Preview {
    MotivationSurfacingCard(
        motivation: RRMotivation(
            userId: UUID(),
            text: "My daughter deserves a father who keeps his promises.",
            category: .relational,
            importanceRating: 5,
            scriptureReference: "Proverbs 22:6"
        ),
        framing: "Remember Your Why"
    )
    .padding()
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationSurfacingCard.swift
git commit -m "feat(motivations): add reusable MotivationSurfacingCard view"
```

---

## Task 9: MotivationCaptureSheet (Quick Add)

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationCaptureSheet.swift`

- [ ] **Step 1: Create the capture sheet view**

```swift
import SwiftUI

struct MotivationCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var libraryViewModel: MotivationLibraryViewModel
    var onSaved: ((RRMotivation) -> Void)?

    @State private var text: String = ""
    @State private var selectedCategory: MotivationCategory = .personalGrowth
    @State private var importanceRating: Int = MotivationImportance.defaultRating
    @State private var scriptureReference: String = ""

    private var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What motivates your recovery?", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .accessibilityLabel("Motivation text")
                    Text("\(text.count)/\(MotivationLimits.maxTextLength)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } header: {
                    Text("Your Motivation")
                }

                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(MotivationCategory.allCases) { category in
                            Label(category.displayName, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("Category")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ForEach(MotivationImportance.range, id: \.self) { value in
                                Button {
                                    importanceRating = value
                                } label: {
                                    Image(systemName: value <= importanceRating ? "flame.fill" : "flame")
                                        .font(.title2)
                                        .foregroundStyle(value <= importanceRating ? Color.orange : Color.rrTextSecondary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(MotivationImportance.label(for: value))")
                                .frame(minWidth: 44, minHeight: 44)
                            }
                        }
                        Text(MotivationImportance.label(for: importanceRating))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                } header: {
                    Text("Importance")
                }

                Section {
                    TextField("e.g. Romans 8:28", text: $scriptureReference)
                        .accessibilityLabel("Scripture reference")
                } header: {
                    Text("Scripture (Optional)")
                }
            }
            .navigationTitle("Add Motivation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        let scripture = scriptureReference.trimmingCharacters(in: .whitespacesAndNewlines)

        let motivation = RRMotivation(
            userId: UUID(),
            text: String(trimmedText.prefix(MotivationLimits.maxTextLength)),
            category: selectedCategory,
            importanceRating: importanceRating,
            scriptureReference: scripture.isEmpty ? nil : scripture,
            source: .manual
        )

        modelContext.insert(motivation)
        try? modelContext.save()

        libraryViewModel.motivations.insert(motivation, at: 0)

        let history = RRMotivationHistory(
            motivationId: motivation.id,
            changeType: .created,
            newValue: motivation.text
        )
        modelContext.insert(history)
        try? modelContext.save()

        onSaved?(motivation)
        dismiss()
    }
}

#Preview {
    MotivationCaptureSheet(libraryViewModel: MotivationLibraryViewModel())
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationCaptureSheet.swift
git commit -m "feat(motivations): add quick capture sheet with category, importance, and scripture"
```

---

## Task 10: MotivationDetailView

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationDetailView.swift`

- [ ] **Step 1: Create the detail view**

```swift
import SwiftUI

struct MotivationDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let motivation: RRMotivation
    var libraryViewModel: MotivationLibraryViewModel

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    @State private var editText: String = ""
    @State private var editCategory: MotivationCategory = .personalGrowth
    @State private var editImportance: Int = 3
    @State private var editScripture: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                categoryHeader
                motivationTextSection
                if let scripture = motivation.scriptureReference, !scripture.isEmpty {
                    scriptureSection(scripture)
                }
                importanceSection
                metadataSection
                actionButtons
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle("Motivation")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isEditing) {
            editSheet
        }
        .confirmationDialog(
            "Are you sure?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteMotivation() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This motivation and its history will be permanently removed. If you are reconsidering this motivation rather than removing it, consider lowering its importance instead.")
        }
    }

    // MARK: - Sections

    private var categoryHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: motivation.motivationCategory.icon)
                .font(.title2)
                .foregroundStyle(motivation.motivationCategory.color)
            Text(motivation.motivationCategory.displayName)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
        }
    }

    private var motivationTextSection: some View {
        RRCard {
            Text(motivation.text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func scriptureSection(_ scripture: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "book.fill")
                .foregroundStyle(Color.rrPrimary)
            Text(scripture)
                .font(RRFont.body)
                .italic()
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    private var importanceSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Importance")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { value in
                    Image(systemName: value <= motivation.importanceRating ? "flame.fill" : "flame")
                        .foregroundStyle(value <= motivation.importanceRating ? Color.orange : Color.rrTextSecondary)
                }
                Text(motivation.importanceLabel)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.leading, 4)
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Added \(motivation.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            if motivation.modifiedAt > motivation.createdAt {
                Text("Last updated \(motivation.modifiedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                editText = motivation.text
                editCategory = motivation.motivationCategory
                editImportance = motivation.importanceRating
                editScripture = motivation.scriptureReference ?? ""
                isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.rrPrimary)
            .frame(minHeight: 44)

            Button {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.rrDestructive)
            .frame(minHeight: 44)
        }
    }

    // MARK: - Edit Sheet

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("Motivation") {
                    TextField("Motivation text", text: $editText, axis: .vertical)
                        .lineLimit(3...8)
                }
                Section("Category") {
                    Picker("Category", selection: $editCategory) {
                        ForEach(MotivationCategory.allCases) { cat in
                            Label(cat.displayName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                Section("Importance") {
                    HStack {
                        ForEach(1...5, id: \.self) { value in
                            Button { editImportance = value } label: {
                                Image(systemName: value <= editImportance ? "flame.fill" : "flame")
                                    .font(.title2)
                                    .foregroundStyle(value <= editImportance ? .orange : .rrTextSecondary)
                            }
                            .buttonStyle(.plain)
                            .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                }
                Section("Scripture (Optional)") {
                    TextField("e.g. Romans 8:28", text: $editScripture)
                }
            }
            .navigationTitle("Edit Motivation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isEditing = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEdit() }
                        .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - Actions

    private func saveEdit() {
        let previousText = motivation.text
        let previousCategory = motivation.category
        let previousImportance = motivation.importanceRating
        let previousScripture = motivation.scriptureReference

        let trimmedText = String(editText.trimmingCharacters(in: .whitespacesAndNewlines).prefix(MotivationLimits.maxTextLength))
        let trimmedScripture = editScripture.trimmingCharacters(in: .whitespacesAndNewlines)

        motivation.text = trimmedText
        motivation.category = editCategory.rawValue
        motivation.importanceRating = editImportance
        motivation.scriptureReference = trimmedScripture.isEmpty ? nil : trimmedScripture
        motivation.modifiedAt = Date()
        try? modelContext.save()

        if previousText != trimmedText {
            recordChange(.textEdited, previousValue: previousText, newValue: trimmedText)
        }
        if previousCategory != editCategory.rawValue {
            recordChange(.categoryChanged, previousValue: previousCategory, newValue: editCategory.rawValue)
        }
        if previousImportance != editImportance {
            recordChange(.importanceChanged, previousValue: "\(previousImportance)", newValue: "\(editImportance)")
        }
        if previousScripture != (trimmedScripture.isEmpty ? nil : trimmedScripture) {
            recordChange(.scriptureChanged, previousValue: previousScripture, newValue: trimmedScripture.isEmpty ? nil : trimmedScripture)
        }

        isEditing = false
    }

    private func recordChange(_ type: MotivationChangeType, previousValue: String?, newValue: String?) {
        let history = RRMotivationHistory(
            motivationId: motivation.id,
            changeType: type,
            previousValue: previousValue,
            newValue: newValue
        )
        modelContext.insert(history)
        try? modelContext.save()
    }

    private func deleteMotivation() {
        libraryViewModel.deleteMotivation(id: motivation.id)
        libraryViewModel.persistDelete(id: motivation.id, context: modelContext)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        MotivationDetailView(
            motivation: RRMotivation(
                userId: UUID(),
                text: "My daughter deserves a father who keeps his promises.",
                category: .relational,
                importanceRating: 5,
                scriptureReference: "Proverbs 22:6"
            ),
            libraryViewModel: MotivationLibraryViewModel()
        )
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationDetailView.swift
git commit -m "feat(motivations): add motivation detail view with edit, delete, and history tracking"
```

---

## Task 11: MotivationDiscoveryView (Guided Wizard)

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationDiscoveryView.swift`

- [ ] **Step 1: Create the discovery wizard view**

```swift
import SwiftUI

struct MotivationDiscoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = MotivationDiscoveryViewModel()
    var libraryViewModel: MotivationLibraryViewModel
    var onComplete: (([RRMotivation]) -> Void)?

    @State private var showResumeAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }

                navigationButtons
                    .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.saveDraft()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel.loadDraft() && viewModel.currentStep != .intro {
                    showResumeAlert = true
                }
            }
            .alert("Continue where you left off?", isPresented: $showResumeAlert) {
                Button("Continue") {}
                Button("Start Fresh") {
                    viewModel.clearDraft()
                    viewModel = MotivationDiscoveryViewModel()
                }
            } message: {
                Text("You have a discovery exercise in progress.")
            }
        }
    }

    // MARK: - Progress

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.rrTextSecondary.opacity(0.2))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.rrPrimary)
                    .frame(width: geo.size.width * viewModel.currentStep.progressFraction, height: 4)
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Step \(viewModel.currentStep.rawValue + 1) of \(MotivationDiscoveryStep.totalSteps)")
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .intro:
            introStep
        case .miracleQuestion:
            miracleStep
        case .valuesSelection:
            valuesStep
        case .concretePrompts:
            concretePromptsStep
        case .summary:
            summaryStep
        }
    }

    private var introStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.orange)

            Text("Your recovery needs a reason that is yours — not someone else's expectation, not a rule, but something you genuinely care about. Let's find it together.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var miracleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("If a miracle happened overnight and your addiction was gone, what would be different when you woke up?")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            TextField("Write freely — this is for you...", text: $viewModel.miracleResponse, axis: .vertical)
                .lineLimit(4...12)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Miracle question response")
        }
    }

    private var valuesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What matters most to you in life? Choose up to \(MotivationLimits.maxValuesSelection).")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MotivationCategory.allCases) { category in
                    Button {
                        viewModel.toggleValue(category)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.title2)
                                .foregroundStyle(viewModel.selectedValues.contains(category) ? .white : category.color)
                            Text(category.displayName)
                                .font(RRFont.caption)
                                .foregroundStyle(viewModel.selectedValues.contains(category) ? .white : Color.rrText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedValues.contains(category) ? category.color : Color.rrCardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(category.color, lineWidth: viewModel.selectedValues.contains(category) ? 0 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityLabel("\(category.displayName), \(viewModel.selectedValues.contains(category) ? "selected" : "not selected")")
                }
            }

            Text("\(viewModel.selectedValues.count)/\(MotivationLimits.maxValuesSelection) selected")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    private var concretePromptsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let category = viewModel.currentConcreteCategory {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.color)
                    Text(category.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    Text("\(viewModel.currentConcretePromptIndex + 1)/\(viewModel.selectedValues.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Text(viewModel.concretePromptText(for: category))
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)

                let responseBinding = Binding(
                    get: { viewModel.concreteResponses[category] ?? "" },
                    set: { viewModel.concreteResponses[category] = $0 }
                )
                TextField("Your motivation...", text: responseBinding, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Motivation for \(category.displayName)")

                let scriptureBinding = Binding(
                    get: { viewModel.concreteScriptures[category] ?? "" },
                    set: { viewModel.concreteScriptures[category] = $0 }
                )

                if category == .spiritual || !scriptureBinding.wrappedValue.isEmpty {
                    Text("Is there a verse that connects to this for you?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("e.g. Psalm 51:10", text: scriptureBinding)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Scripture reference for \(category.displayName)")
                }
            }
        }
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Here's what you told us matters most:")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            let motivations = viewModel.buildMotivations(userId: UUID())
            ForEach(motivations, id: \.id) { motivation in
                MotivationSurfacingCard(motivation: motivation)
            }

            if motivations.isEmpty {
                Text("No motivations captured yet. Go back and write about what matters to you.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.canGoBack {
                Button("Back") {
                    viewModel.goToPreviousStep()
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
            }

            Spacer()

            if viewModel.currentStep == .summary {
                Button("Add to My Motivations") {
                    saveMotivations()
                }
                .buttonStyle(.borderedProminent)
                .tint(.rrPrimary)
                .frame(minHeight: 44)
                .disabled(viewModel.buildMotivations(userId: UUID()).isEmpty)
            } else {
                Button("Continue") {
                    viewModel.goToNextStep()
                }
                .buttonStyle(.borderedProminent)
                .tint(.rrPrimary)
                .frame(minHeight: 44)
                .disabled(!viewModel.canProceed)
            }
        }
    }

    // MARK: - Save

    private func saveMotivations() {
        let motivations = viewModel.buildMotivations(userId: UUID())
        for motivation in motivations {
            modelContext.insert(motivation)
            libraryViewModel.motivations.insert(motivation, at: 0)

            let history = RRMotivationHistory(
                motivationId: motivation.id,
                changeType: .created,
                newValue: motivation.text
            )
            modelContext.insert(history)
        }
        try? modelContext.save()

        viewModel.clearDraft()
        onComplete?(motivations)
        dismiss()
    }
}

#Preview {
    MotivationDiscoveryView(libraryViewModel: MotivationLibraryViewModel())
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationDiscoveryView.swift
git commit -m "feat(motivations): add guided discovery wizard with miracle question, values sort, and concrete prompts"
```

---

## Task 12: MotivationLibraryView (Main Hub)

**Files:**
- Create: `ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationLibraryView.swift`

- [ ] **Step 1: Create the library hub view**

```swift
import SwiftUI
import SwiftData

struct MotivationLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRMotivation.importanceRating, order: .reverse) private var allMotivations: [RRMotivation]

    @State private var libraryViewModel = MotivationLibraryViewModel()
    @State private var showCaptureSheet = false
    @State private var showDiscovery = false

    var body: some View {
        NavigationStack {
            Group {
                if libraryViewModel.isEmpty {
                    emptyState
                } else {
                    motivationList
                }
            }
            .background(Color.rrBackground)
            .navigationTitle("Motivations")
            .toolbar {
                if !libraryViewModel.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCaptureSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add motivation")
                    }
                }
            }
            .sheet(isPresented: $showCaptureSheet) {
                MotivationCaptureSheet(libraryViewModel: libraryViewModel)
            }
            .fullScreenCover(isPresented: $showDiscovery) {
                MotivationDiscoveryView(libraryViewModel: libraryViewModel)
            }
            .onAppear {
                libraryViewModel.motivations = allMotivations
            }
            .onChange(of: allMotivations) { _, newValue in
                libraryViewModel.motivations = newValue
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.orange)

            Text("Your recovery needs a reason that is yours. What are you fighting for?")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showDiscovery = true
            } label: {
                Label("Discover My Motivations", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.rrPrimary)
            .frame(minHeight: 44)
            .padding(.horizontal, 40)

            Button("Add one now") {
                showCaptureSheet = true
            }
            .font(RRFont.body)
            .foregroundStyle(Color.rrPrimary)
            .frame(minHeight: 44)

            Spacer()
        }
    }

    // MARK: - Motivation List

    private var motivationList: some View {
        ScrollView {
            VStack(spacing: 0) {
                summaryBar
                    .padding()

                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    ForEach(libraryViewModel.groupedByCategory) { group in
                        Section {
                            ForEach(group.motivations, id: \.id) { motivation in
                                NavigationLink {
                                    MotivationDetailView(
                                        motivation: motivation,
                                        libraryViewModel: libraryViewModel
                                    )
                                } label: {
                                    motivationRow(motivation)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            sectionHeader(group)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var summaryBar: some View {
        HStack {
            Text("\(libraryViewModel.totalCount) motivation\(libraryViewModel.totalCount == 1 ? "" : "s")")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            Spacer()
            Button {
                showDiscovery = true
            } label: {
                Label("Discover More", systemImage: "sparkles")
                    .font(RRFont.caption)
            }
            .frame(minHeight: 44)
        }
    }

    private func sectionHeader(_ group: MotivationLibraryViewModel.CategoryGroup) -> some View {
        HStack(spacing: 8) {
            Image(systemName: group.category.icon)
                .foregroundStyle(group.category.color)
            Text(group.category.displayName)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
            Spacer()
            Text("\(group.motivations.count)")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.rrBackground)
    }

    private func motivationRow(_ motivation: RRMotivation) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(motivation.text)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { value in
                            Image(systemName: value <= motivation.importanceRating ? "flame.fill" : "flame")
                                .font(.caption2)
                                .foregroundStyle(value <= motivation.importanceRating ? Color.orange : Color.rrTextSecondary)
                        }
                    }

                    if let scripture = motivation.scriptureReference {
                        Text("— \(scripture)")
                            .font(RRFont.caption)
                            .italic()
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Motivation: \(motivation.text). Importance: \(motivation.importanceRating) of 5. Double tap to view details.")
    }
}

#Preview {
    MotivationLibraryView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Tools/Motivations/MotivationLibraryView.swift
git commit -m "feat(motivations): add library hub with category groups, empty state, and navigation"
```

---

## Task 13: Wire into ToolsView

**Files:**
- Modify: `ios/RegalRecovery/RegalRecovery/Views/Tools/ToolsView.swift` (~line 42)

- [ ] **Step 1: Add Motivations card to ToolsView**

In `ios/RegalRecovery/RegalRecovery/Views/Tools/ToolsView.swift`, add after the Vision tool card `if` block (after the closing brace of the Vision feature flag check around line 42):

```swift
                    if FeatureFlagStore.shared.isEnabled("activity.motivations") {
                        toolCard(
                            destination: MotivationLibraryView(),
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Motivations",
                            subtitle: "Your Recovery Why"
                        )
                    }
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild build -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ios/RegalRecovery/RegalRecovery/Views/Tools/ToolsView.swift
git commit -m "feat(motivations): wire Motivations tool card into ToolsView with feature flag"
```

---

## Task 14: Run Full Test Suite and Visual Verification

- [ ] **Step 1: Run all tests**

Run: `cd /Users/travis.smith/Projects/personal/RR/.claude/worktrees/motivations && xcodebuild test -project ios/RegalRecovery/RegalRecovery.xcodeproj -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -20`

Expected: All tests pass, including MotivationSurfacingServiceTests, MotivationLibraryViewModelTests, MotivationDiscoveryViewModelTests

- [ ] **Step 2: Launch the app in simulator and verify**

Run the app in the iOS Simulator. Navigate to the Tools tab. Verify:
1. "Motivations" card appears with flame icon
2. Tapping it shows the empty state with "What are you fighting for?"
3. "Discover My Motivations" launches the guided wizard
4. Walking through the wizard creates motivations in the library
5. "Add one now" / "+" button opens the capture sheet
6. Tapping a motivation opens the detail view
7. Edit and delete work correctly
8. VoiceOver reads motivations with category and importance

- [ ] **Step 3: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix(motivations): address issues found during visual verification"
```

---

## Deferred to Follow-Up Plans

The following PRD requirements are **not covered** by this plan and should be implemented in subsequent plans:

### Plan 2: Photo Attachments and Confidence Ratings
- FR-M-004: Photo attachment for motivations
- FR-M-007: Motivation confidence rating

### Plan 3: Contextual Surfacing Integrations
- FR-M-011: Low mood / check-in surfacing
- FR-M-012: Milestone surfacing
- FR-M-018: Morning commitment integration
- FR-M-019: Evening review integration
- FR-M-022: FASTER Scale integration
- FR-M-024: Post-mortem integration
- FR-M-010 (remaining): SOS flow photo display, reach-out pre-fill

### Plan 4: Reflection, Journaling, and Evolution
- FR-M-014: Motivation reflection prompts
- FR-M-015: Motivation evolution timeline
- FR-M-020: Journal integration
- FR-M-021: Affirmations integration
- FR-M-023: Three Circles integration
- FR-M-031: Calendar activity dual-write

### Plan 5: Engagement, Sharing, and Review
- FR-M-016: Post-surfacing effectiveness tracking
- FR-M-017: Personal engagement metrics dashboard
- FR-M-025: Accountability partner sharing
- FR-M-026: Quarterly motivation review
- FR-M-030: Surfacing event model

---

## Dependency Notes

- This plan has **no external blocking dependencies** — all models, repos, and views are self-contained.
- The surfacing card component (Task 8) is designed to be reused by Plan 3's integrations.
- The `MotivationSurfacingService` (Task 5) is designed as a stateless utility that Plan 3 will call from various flow views.
- The `RRMotivationHistory` model (Task 2) supports Plan 4's evolution timeline.
- The feature flag `activity.motivations` gates the entire feature (Task 4 + Task 13).
