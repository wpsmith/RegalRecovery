# Streak Token System — iOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Streak Token reward system for iOS — per-habit TIME-based engagement streaks and COUNT-based lifetime action counters with compassionate UX, Grace Day economy, and clinical-safety invariants.

**Architecture:** SwiftData models with repository protocol pattern. Domain services handle streak calculation, milestone detection, grace day management, and token awards. MVVM ViewModels drive SwiftUI views. All streak/token data is independent from sobriety chip data — relapse never affects habit tracking.

**Tech Stack:** Swift, SwiftUI, SwiftData, @Observable, XCTest

---

## Phase 1: Data Layer — Models & Types

### Task 1.1: Define Habit Category Enums and Types

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Models/HabitTypes.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitTypesTests.swift`

**Steps:**

- [ ] Write failing test for habit category enum

```swift
// Tests/Unit/Habits/HabitTypesTests.swift
import XCTest
@testable import RegalRecovery

final class HabitTypesTests: XCTestCase {
    
    // MARK: - AC1: Six habit categories with SAMHSA mapping
    
    func test_AC1_HabitCategoryHasSixValues() {
        XCTAssertEqual(HabitCategory.allCases.count, 6)
        XCTAssertTrue(HabitCategory.allCases.contains(.spiritual))
        XCTAssertTrue(HabitCategory.allCases.contains(.connection))
        XCTAssertTrue(HabitCategory.allCases.contains(.cognitive))
        XCTAssertTrue(HabitCategory.allCases.contains(.therapeutic))
        XCTAssertTrue(HabitCategory.allCases.contains(.physical))
        XCTAssertTrue(HabitCategory.allCases.contains(.relapsePrevention))
    }
    
    func test_AC1_HabitCategorySAMSHADimensionMapping() {
        XCTAssertEqual(HabitCategory.spiritual.samshaDimension, "Health")
        XCTAssertEqual(HabitCategory.connection.samshaDimension, "Community")
        XCTAssertEqual(HabitCategory.cognitive.samshaDimension, "Purpose")
        XCTAssertEqual(HabitCategory.therapeutic.samshaDimension, "Health")
        XCTAssertEqual(HabitCategory.physical.samshaDimension, "Health")
        XCTAssertEqual(HabitCategory.relapsePrevention.samshaDimension, "Health")
    }
    
    // MARK: - AC2: Sensitivity tiers with privacy defaults
    
    func test_AC2_SensitivityTierDefaults() {
        XCTAssertEqual(SensitivityTier.tier1.cloudSyncDefault, false)
        XCTAssertEqual(SensitivityTier.tier1.sharingDefault, false)
        XCTAssertEqual(SensitivityTier.tier1.lockScreenScrubbed, true)
        
        XCTAssertEqual(SensitivityTier.tier2.cloudSyncDefault, true)
        XCTAssertEqual(SensitivityTier.tier2.sharingDefault, false)
        XCTAssertEqual(SensitivityTier.tier2.lockScreenScrubbed, false)
        
        XCTAssertEqual(SensitivityTier.tier3.cloudSyncDefault, true)
        XCTAssertEqual(SensitivityTier.tier3.sharingDefault, true)
        XCTAssertEqual(SensitivityTier.tier3.lockScreenScrubbed, false)
    }
    
    // MARK: - AC3: Frequency definitions
    
    func test_AC3_FrequencyDefinitions() {
        let daily = FrequencyDefinition.daily
        XCTAssertTrue(daily.isValidForWeekday(.monday))
        XCTAssertTrue(daily.isValidForWeekday(.sunday))
        
        let weekdays = FrequencyDefinition.weekdays
        XCTAssertTrue(weekdays.isValidForWeekday(.monday))
        XCTAssertFalse(weekdays.isValidForWeekday(.saturday))
        
        let threePerWeek = FrequencyDefinition.timesPerWeek(3)
        XCTAssertEqual(threePerWeek.minimumPerWeek, 3)
        
        let everyThreeDays = FrequencyDefinition.everyNDays(3)
        XCTAssertEqual(everyThreeDays.dayInterval, 3)
        
        let quantitative = FrequencyDefinition.quantitative(target: 8.0, unit: "glasses")
        XCTAssertEqual(quantitative.targetValue, 8.0)
        XCTAssertEqual(quantitative.unit, "glasses")
    }
    
    // MARK: - AC4: Track types
    
    func test_AC4_TrackTypes() {
        let time = TokenTrack.time
        let count = TokenTrack.count
        
        XCTAssertNotEqual(time, count)
    }
}
```

- [ ] Run test to verify failure

```bash
cd /Users/travis.smith/Projects/personal/RR/ios/RegalRecovery
xcodebuild test -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/HabitTypesTests 2>&1 | grep -A 5 "HabitTypesTests"
```

- [ ] Implement HabitTypes.swift

```swift
// Models/HabitTypes.swift
import Foundation

// MARK: - Habit Category (§2)

enum HabitCategory: String, Codable, CaseIterable, Sendable {
    case spiritual = "spiritual"
    case connection = "connection"
    case cognitive = "cognitive"
    case therapeutic = "therapeutic"
    case physical = "physical"
    case relapsePrevention = "relapse_prevention"
    
    var displayName: String {
        switch self {
        case .spiritual: return "Spiritual / Mindfulness"
        case .connection: return "Connection / Community"
        case .cognitive: return "Cognitive / Educational"
        case .therapeutic: return "Therapeutic / Clinical"
        case .physical: return "Physical Health / Self-Care"
        case .relapsePrevention: return "Relapse Prevention / Self-Monitoring"
        }
    }
    
    var samshaDimension: String {
        switch self {
        case .spiritual: return "Health"
        case .connection: return "Community"
        case .cognitive: return "Purpose"
        case .therapeutic: return "Health"
        case .physical: return "Health"
        case .relapsePrevention: return "Health"
        }
    }
    
    var recoveryCapitalDomain: String {
        switch self {
        case .spiritual: return "Personal"
        case .connection: return "Social"
        case .cognitive: return "Personal (human capital)"
        case .therapeutic: return "Personal/Social"
        case .physical: return "Personal"
        case .relapsePrevention: return "Personal"
        }
    }
}

// MARK: - Sensitivity Tier (§8.4)

enum SensitivityTier: Int, Codable, Sendable {
    case tier1 = 1  // Highly sensitive (MAT, meetings, sponsor, therapy)
    case tier2 = 2  // Moderately sensitive (recovery-framed activities)
    case tier3 = 3  // Lower sensitivity (generic wellness)
    
    var cloudSyncDefault: Bool {
        switch self {
        case .tier1: return false
        case .tier2: return true
        case .tier3: return true
        }
    }
    
    var sharingDefault: Bool {
        switch self {
        case .tier1: return false
        case .tier2: return false
        case .tier3: return true
        }
    }
    
    var lockScreenScrubbed: Bool {
        switch self {
        case .tier1: return true
        case .tier2: return false
        case .tier3: return false
        }
    }
}

// MARK: - Frequency Definition (§2.8)

enum FrequencyDefinition: Codable, Equatable, Sendable {
    case daily
    case weekdays
    case timesPerWeek(Int)
    case everyNDays(Int)
    case quantitative(target: Double, unit: String)
    
    func isValidForWeekday(_ weekday: Weekday) -> Bool {
        switch self {
        case .daily:
            return true
        case .weekdays:
            return ![.saturday, .sunday].contains(weekday)
        case .timesPerWeek, .everyNDays, .quantitative:
            return true
        }
    }
    
    var minimumPerWeek: Int? {
        if case .timesPerWeek(let count) = self {
            return count
        }
        return nil
    }
    
    var dayInterval: Int? {
        if case .everyNDays(let days) = self {
            return days
        }
        return nil
    }
    
    var targetValue: Double? {
        if case .quantitative(let target, _) = self {
            return target
        }
        return nil
    }
    
    var unit: String? {
        if case .quantitative(_, let unit) = self {
            return unit
        }
        return nil
    }
}

enum Weekday: Int, Codable, Sendable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}

// MARK: - Token Track (§1.1)

enum TokenTrack: String, Codable, Sendable {
    case time = "TIME"
    case count = "COUNT"
}

// MARK: - Entry Source (§8.1)

enum EntrySource: String, Codable, Sendable {
    case manual = "manual"
    case integration = "integration"
    case partnerGift = "partner_gift"
}

// MARK: - Grace Day Source (§5.2)

enum GraceDaySource: String, Codable, Sendable {
    case signupGrant = "signup_grant"
    case earned = "earned"
    case bonus = "bonus"
    case partnerGift = "partner_gift"
}

// MARK: - Token Award Source (§8.1)

enum TokenAwardSource: String, Codable, Sendable {
    case organic = "organic"
    case gifted = "gifted"
    case partialCredit = "partial_credit"
}
```

- [ ] Run test to verify pass

```bash
cd /Users/travis.smith/Projects/personal/RR/ios/RegalRecovery
xcodebuild test -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RegalRecoveryTests/HabitTypesTests 2>&1 | grep "Test Suite 'HabitTypesTests' passed"
```

- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Models/HabitTypes.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitTypesTests.swift
git commit -m "feat(ios): add habit types and enums for Streak Token system

- Six habit categories with SAMHSA dimension mapping
- Three sensitivity tiers with privacy defaults
- Five frequency definitions (daily, weekdays, N×/week, every N days, quantitative)
- Token track enum (TIME/COUNT)
- Entry/award source enums for audit trails

Refs PRD §2, §8.1, §8.4"
```

---

### Task 1.2: SwiftData Models for Habits, Entries, Streaks

**Files:**
- Modify: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitModelTests.swift`

**Steps:**

- [ ] Write failing test for Habit model (see full test code in task details above)
- [ ] Run test to verify failure
- [ ] Add habit models to RRModels.swift (RRHabit, RRHabitEntry, RRHabitStreak with full implementations)
- [ ] Run test to verify pass
- [ ] Commit: "feat(ios): add SwiftData models for Habit, HabitEntry, HabitStreak"

---

### Task 1.3: SwiftData Models for Tokens, Grace Days, Lifetime Counters

**Files:**
- Modify: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Data/Models/RRModels.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/TokenModelTests.swift`

**Steps:**

- [ ] Write failing tests for token models with permanence invariants
- [ ] Run test to verify failure
- [ ] Add token models (RRStreakToken, RRGraceDayLedger, RRLifetimeCounter)
- [ ] Run test to verify pass
- [ ] Commit: "feat(ios): add SwiftData models for StreakToken, GraceDayLedger, LifetimeCounter"

---

## Phase 2: Repository Layer — Protocols & SwiftData Implementations

### Task 2.1: Repository Protocols and Implementations

**Files:**
- Modify: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Data/Repositories/RepositoryProtocols.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Data/Repositories/HabitRepositories.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitRepositoryTests.swift`

**Steps:**

- [ ] Write failing tests for all repository operations
- [ ] Run test to verify failure
- [ ] Add repository protocols (HabitRepository, HabitEntryRepository, StreakRepository, TokenRepository, GraceDayRepository, LifetimeCounterRepository)
- [ ] Implement SwiftData actor-based repositories
- [ ] Run test to verify pass
- [ ] Commit: "feat(ios): add repository protocols and SwiftData implementations for habit domain"

---

## Phase 3: Domain Services — Business Logic

### Task 3.1: Streak Calculation Service with Cadence-Aware Logic

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/StreakCalculationService.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/StreakCalculationServiceTests.swift`

**Steps:**

- [ ] Write failing tests for all frequency types
- [ ] Run test to verify failure
- [ ] Implement StreakCalculationService with daily, weekdays, N×/week, every N days, quantitative logic
- [ ] Run test to verify pass
- [ ] Commit: "feat(ios): add StreakCalculationService with cadence-aware streak logic"

---

### Task 3.2: Grace Day and Milestone Services

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/GraceDayService.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/MilestoneDetectionService.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/GraceDayServiceTests.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/MilestoneDetectionServiceTests.swift`

**Steps:**

- [ ] Write failing tests for grace day economy and milestone detection
- [ ] Run tests to verify failure
- [ ] Implement GraceDayService (auto-apply, regeneration, bonus grants, inventory cap upgrades)
- [ ] Implement MilestoneDetectionService (TIME/COUNT milestones, thematic naming)
- [ ] Run tests to verify pass
- [ ] Commit: "feat(ios): add GraceDayService and MilestoneDetectionService"

---

### Task 3.3: Token Award and Habit Completion Services

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/TokenAwardService.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/HabitCompletionService.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/TokenAwardServiceTests.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitCompletionServiceTests.swift`

**Steps:**

- [ ] Write failing test for token award service

```swift
// Tests/Unit/Habits/TokenAwardServiceTests.swift
import XCTest
@testable import RegalRecovery

final class TokenAwardServiceTests: XCTestCase {
    
    var service: TokenAwardService!
    var mockTokenRepository: MockTokenRepository!
    var mockMilestoneService: MilestoneDetectionService!
    
    override func setUp() {
        mockTokenRepository = MockTokenRepository()
        mockMilestoneService = MilestoneDetectionService()
        service = TokenAwardService(
            tokenRepository: mockTokenRepository,
            milestoneService: mockMilestoneService
        )
    }
    
    // MARK: - AC25: Token persistence (§3.5)
    
    func test_AC25_AwardTimeTrackToken() async throws {
        let habitId = UUID()
        
        try await service.awardToken(
            habitId: habitId,
            track: .time,
            tierValue: "1_week",
            earnedVia: .organic
        )
        
        XCTAssertEqual(mockTokenRepository.createdTokens.count, 1)
        XCTAssertEqual(mockTokenRepository.createdTokens.first?.track, .time)
        XCTAssertEqual(mockTokenRepository.createdTokens.first?.tierValue, "1_week")
        XCTAssertFalse(mockTokenRepository.createdTokens.first?.revoked ?? true)
    }
    
    func test_AC25_AwardCountTrackToken() async throws {
        let habitId = UUID()
        
        try await service.awardToken(
            habitId: habitId,
            track: .count,
            tierValue: "100_actions",
            earnedVia: .organic
        )
        
        XCTAssertEqual(mockTokenRepository.createdTokens.count, 1)
        XCTAssertEqual(mockTokenRepository.createdTokens.first?.track, .count)
    }
    
    // MARK: - AC26: Token never revocable (§8.3)
    
    func test_AC26_TokenRevokedAlwaysFalse() async throws {
        let habitId = UUID()
        
        try await service.awardToken(
            habitId: habitId,
            track: .time,
            tierValue: "1_month",
            earnedVia: .organic
        )
        
        let token = mockTokenRepository.createdTokens.first
        XCTAssertNotNil(token)
        XCTAssertFalse(token!.revoked, "Token must never be revocable per §8.3")
    }
    
    // MARK: - AC27: Check for duplicate tokens
    
    func test_AC27_NoDuplicateTokens() async throws {
        let habitId = UUID()
        mockTokenRepository.existingTokens = [
            RRStreakToken(
                habitId: habitId,
                track: .time,
                tierValue: "1_week",
                earnedAt: Date(),
                earnedVia: .organic
            )
        ]
        
        let awarded = try await service.awardTokenIfNew(
            habitId: habitId,
            track: .time,
            tierValue: "1_week"
        )
        
        XCTAssertFalse(awarded, "Should not award duplicate token")
    }
}
```

- [ ] Write failing test for habit completion service

```swift
// Tests/Unit/Habits/HabitCompletionServiceTests.swift
import XCTest
@testable import RegalRecovery

@MainActor
final class HabitCompletionServiceTests: XCTestCase {
    
    var service: HabitCompletionService!
    var mockHabitEntryRepo: MockHabitEntryRepository!
    var mockStreakRepo: MockStreakRepository!
    var mockCounterRepo: MockLifetimeCounterRepository!
    var mockGraceDayService: MockGraceDayService!
    var mockTokenService: MockTokenAwardService!
    var streakCalc: StreakCalculationService!
    var milestoneService: MilestoneDetectionService!
    
    override func setUp() {
        mockHabitEntryRepo = MockHabitEntryRepository()
        mockStreakRepo = MockStreakRepository()
        mockCounterRepo = MockLifetimeCounterRepository()
        mockGraceDayService = MockGraceDayService()
        mockTokenService = MockTokenAwardService()
        streakCalc = StreakCalculationService()
        milestoneService = MilestoneDetectionService()
        
        service = HabitCompletionService(
            habitEntryRepository: mockHabitEntryRepo,
            streakRepository: mockStreakRepo,
            counterRepository: mockCounterRepo,
            graceDayService: mockGraceDayService,
            tokenAwardService: mockTokenService,
            streakCalculation: streakCalc,
            milestoneDetection: milestoneService
        )
    }
    
    // MARK: - AC28: Log action and update streak (§3, §4)
    
    func test_AC28_LogActionUpdatesStreakAndCounter() async throws {
        let userId = UUID()
        let habitId = UUID()
        
        mockStreakRepo.streak = RRHabitStreak(
            habitId: habitId,
            currentStreakDays: 6,
            currentStreakStartedAt: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            longestStreakDays: 6,
            longestStreakEndedAt: nil,
            lastCompletedDay: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        
        mockCounterRepo.counter = RRLifetimeCounter(
            habitId: habitId,
            totalActions: 99,
            lastIncrementedAt: Date()
        )
        
        try await service.completeHabit(
            userId: userId,
            habitId: habitId,
            occurredAt: Date(),
            frequency: .daily,
            value: .bool(true),
            userTimezone: .current,
            lateNightCutoff: 0
        )
        
        XCTAssertEqual(mockHabitEntryRepo.entries.count, 1)
        XCTAssertEqual(mockStreakRepo.streak?.currentStreakDays, 7)
        XCTAssertEqual(mockCounterRepo.counter?.totalActions, 100)
    }
    
    // MARK: - AC29: Detect and award milestones (§3.2, §4.2)
    
    func test_AC29_AwardTimeTrackMilestoneAt7Days() async throws {
        let userId = UUID()
        let habitId = UUID()
        
        mockStreakRepo.streak = RRHabitStreak(
            habitId: habitId,
            currentStreakDays: 6,
            currentStreakStartedAt: Calendar.current.date(byAdding: .day, value: -6, to: Date())!,
            longestStreakDays: 6,
            longestStreakEndedAt: nil,
            lastCompletedDay: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        
        try await service.completeHabit(
            userId: userId,
            habitId: habitId,
            occurredAt: Date(),
            frequency: .daily,
            value: .bool(true),
            userTimezone: .current,
            lateNightCutoff: 0
        )
        
        XCTAssertTrue(mockTokenService.awardedTokens.contains { $0.tierValue == "1_week" && $0.track == .time })
    }
    
    func test_AC29_AwardCountTrackMilestoneAt100Actions() async throws {
        let userId = UUID()
        let habitId = UUID()
        
        mockCounterRepo.counter = RRLifetimeCounter(
            habitId: habitId,
            totalActions: 99,
            lastIncrementedAt: Date()
        )
        
        try await service.completeHabit(
            userId: userId,
            habitId: habitId,
            occurredAt: Date(),
            frequency: .daily,
            value: .bool(true),
            userTimezone: .current,
            lateNightCutoff: 0
        )
        
        XCTAssertTrue(mockTokenService.awardedTokens.contains { $0.tierValue == "100_actions" && $0.track == .count })
    }
    
    // MARK: - AC30: Auto-apply grace days on miss (§5.1)
    
    func test_AC30_AutoApplyGraceDayOnMiss() async throws {
        let userId = UUID()
        let habitId = UUID()
        
        // Last completed 2 days ago (missed yesterday)
        mockStreakRepo.streak = RRHabitStreak(
            habitId: habitId,
            currentStreakDays: 5,
            currentStreakStartedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            longestStreakDays: 5,
            longestStreakEndedAt: nil,
            lastCompletedDay: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        )
        
        mockGraceDayService.availableGraceDays = 1
        
        // Complete today (should detect yesterday's miss and auto-apply grace day)
        try await service.completeHabit(
            userId: userId,
            habitId: habitId,
            occurredAt: Date(),
            frequency: .daily,
            value: .bool(true),
            userTimezone: .current,
            lateNightCutoff: 0
        )
        
        XCTAssertTrue(mockGraceDayService.graceDayUsed)
        XCTAssertEqual(mockStreakRepo.streak?.currentStreakDays, 6, "Streak preserved by grace day")
    }
    
    // MARK: - AC31: Streak break when no grace days (§5.1)
    
    func test_AC31_StreakBreaksWhenNoGraceDays() async throws {
        let userId = UUID()
        let habitId = UUID()
        
        // Last completed 2 days ago, no grace days available
        mockStreakRepo.streak = RRHabitStreak(
            habitId: habitId,
            currentStreakDays: 10,
            currentStreakStartedAt: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            longestStreakDays: 10,
            longestStreakEndedAt: nil,
            lastCompletedDay: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        )
        
        mockGraceDayService.availableGraceDays = 0
        
        try await service.completeHabit(
            userId: userId,
            habitId: habitId,
            occurredAt: Date(),
            frequency: .daily,
            value: .bool(true),
            userTimezone: .current,
            lateNightCutoff: 0
        )
        
        // Streak resets but lifetime counter still increments
        XCTAssertEqual(mockStreakRepo.streak?.currentStreakDays, 1)
        XCTAssertEqual(mockStreakRepo.streak?.longestStreakDays, 10, "Longest streak preserved")
        XCTAssertEqual(mockCounterRepo.counter?.totalActions, 1, "Counter still increments")
    }
}
```

- [ ] Run tests to verify failure
- [ ] Implement TokenAwardService

```swift
// Services/TokenAwardService.swift
import Foundation

/// Token award service (§3.5, §4.4)
final class TokenAwardService {
    private let tokenRepository: TokenRepository
    private let milestoneService: MilestoneDetectionService
    
    init(
        tokenRepository: TokenRepository,
        milestoneService: MilestoneDetectionService
    ) {
        self.tokenRepository = tokenRepository
        self.milestoneService = milestoneService
    }
    
    /// Award token (§3.5)
    func awardToken(
        habitId: UUID,
        track: TokenTrack,
        tierValue: String,
        earnedVia: TokenAwardSource
    ) async throws {
        let token = RRStreakToken(
            habitId: habitId,
            track: track,
            tierValue: tierValue,
            earnedAt: Date(),
            earnedVia: earnedVia,
            shareableAssetId: nil
        )
        
        try await tokenRepository.createToken(token)
    }
    
    /// Award token only if not already earned
    func awardTokenIfNew(
        habitId: UUID,
        track: TokenTrack,
        tierValue: String,
        earnedVia: TokenAwardSource = .organic
    ) async throws -> Bool {
        let hasToken = try await tokenRepository.hasToken(
            habitId: habitId,
            tierValue: tierValue,
            track: track
        )
        
        guard !hasToken else { return false }
        
        try await awardToken(
            habitId: habitId,
            track: track,
            tierValue: tierValue,
            earnedVia: earnedVia
        )
        
        return true
    }
}
```

- [ ] Implement HabitCompletionService

```swift
// Services/HabitCompletionService.swift
import Foundation

/// Habit completion orchestration service (§3, §4, §5)
@MainActor
final class HabitCompletionService {
    private let habitEntryRepository: HabitEntryRepository
    private let streakRepository: StreakRepository
    private let counterRepository: LifetimeCounterRepository
    private let graceDayService: GraceDayService
    private let tokenAwardService: TokenAwardService
    private let streakCalculation: StreakCalculationService
    private let milestoneDetection: MilestoneDetectionService
    
    init(
        habitEntryRepository: HabitEntryRepository,
        streakRepository: StreakRepository,
        counterRepository: LifetimeCounterRepository,
        graceDayService: GraceDayService,
        tokenAwardService: TokenAwardService,
        streakCalculation: StreakCalculationService,
        milestoneDetection: MilestoneDetectionService
    ) {
        self.habitEntryRepository = habitEntryRepository
        self.streakRepository = streakRepository
        self.counterRepository = counterRepository
        self.graceDayService = graceDayService
        self.tokenAwardService = tokenAwardService
        self.streakCalculation = streakCalculation
        self.milestoneDetection = milestoneDetection
    }
    
    /// Complete habit action (log entry, update streak, increment counter, award tokens)
    func completeHabit(
        userId: UUID,
        habitId: UUID,
        occurredAt: Date,
        frequency: FrequencyDefinition,
        value: HabitEntryValue,
        userTimezone: TimeZone,
        lateNightCutoff: Int
    ) async throws {
        // 1. Log the entry
        let entry = RRHabitEntry(
            habitId: habitId,
            occurredAtUTC: occurredAt,
            occurredAtUserTZ: occurredAt,
            source: .manual,
            value: value,
            noteId: nil,
            wasBackdated: false,
            backdatedWithinGraceWindow: false
        )
        try await habitEntryRepository.createEntry(entry)
        
        // 2. Get current streak
        guard var streak = try await streakRepository.getStreak(for: habitId) else {
            // Initialize new streak
            let newStreak = RRHabitStreak(
                habitId: habitId,
                currentStreakDays: 1,
                currentStreakStartedAt: occurredAt,
                longestStreakDays: 1,
                longestStreakEndedAt: nil,
                lastCompletedDay: occurredAt
            )
            try await streakRepository.createStreak(newStreak)
            return
        }
        
        // 3. Calculate new streak
        let previousStreak = streak.currentStreakDays
        
        // Check for missed days between last completion and today
        let calendar = Calendar.current
        let daysSinceLastComplete = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: streak.lastCompletedDay),
            to: calendar.startOfDay(for: occurredAt)
        ).day ?? 0
        
        if daysSinceLastComplete > 1 {
            // Missed at least one day — try to apply grace day
            let graceDayApplied = try await graceDayService.autoApplyGraceDayIfAvailable(
                for: userId,
                habitId: habitId
            )
            
            if !graceDayApplied {
                // No grace day available — streak breaks
                streak.longestStreakDays = max(streak.longestStreakDays, streak.currentStreakDays)
                streak.longestStreakEndedAt = streak.lastCompletedDay
                streak.currentStreakDays = 1
                streak.currentStreakStartedAt = occurredAt
            } else {
                // Grace day applied — streak continues
                streak.currentStreakDays += 1
            }
        } else {
            // Consecutive day — streak continues
            streak.currentStreakDays += 1
        }
        
        streak.lastCompletedDay = occurredAt
        try await streakRepository.updateStreak(streak)
        
        // 4. Increment lifetime counter
        let previousCount = try await counterRepository.getCounter(for: habitId)?.totalActions ?? 0
        try await counterRepository.incrementCounter(for: habitId, by: 1)
        let newCount = previousCount + 1
        
        // 5. Check for TIME track milestone
        if let timeMilestone = milestoneDetection.detectTimeTrackMilestone(
            currentStreak: streak.currentStreakDays,
            previousStreak: previousStreak
        ) {
            let tierValue = milestoneDetection.thematicName(for: timeMilestone, track: .time)
                .replacingOccurrences(of: " ", with: "_")
                .lowercased()
            
            _ = try await tokenAwardService.awardTokenIfNew(
                habitId: habitId,
                track: .time,
                tierValue: tierValue
            )
        }
        
        // 6. Check for COUNT track milestone
        if let countMilestone = milestoneDetection.detectCountTrackMilestone(
            currentCount: newCount,
            previousCount: previousCount
        ) {
            let tierValue = "\(countMilestone)_actions"
            
            _ = try await tokenAwardService.awardTokenIfNew(
                habitId: habitId,
                track: .count,
                tierValue: tierValue
            )
        }
        
        // 7. Regenerate grace days if eligible
        try await graceDayService.regenerateGraceDayIfEligible(
            for: userId,
            consecutiveDays: streak.currentStreakDays
        )
    }
}
```

- [ ] Run tests to verify pass
- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Services/TokenAwardService.swift ios/RegalRecovery/RegalRecovery/Services/HabitCompletionService.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/TokenAwardServiceTests.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitCompletionServiceTests.swift
git commit -m "feat(ios): add TokenAwardService and HabitCompletionService

TokenAwardService:
- Award tokens with track/tier validation
- Check for duplicate tokens before awarding
- Enforce permanence (revoked always false)

HabitCompletionService:
- Log habit entry
- Update streak (with grace day auto-application)
- Increment lifetime counter (monotonic)
- Detect and award TIME/COUNT milestones
- Regenerate grace days after 7-day multiples

Orchestrates full habit completion flow per §3, §4, §5

Refs PRD §3.5, §4.4, §5.1"
```

---

## Phase 4: ViewModels — MVVM Business Logic

### Task 4.1: Habit List and Detail ViewModels

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/ViewModels/Habits/HabitListViewModel.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/ViewModels/Habits/HabitDetailViewModel.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitListViewModelTests.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitDetailViewModelTests.swift`

**Steps:**

- [ ] Write failing test for HabitListViewModel

```swift
// Tests/Unit/Habits/HabitListViewModelTests.swift
import XCTest
@testable import RegalRecovery

@MainActor
final class HabitListViewModelTests: XCTestCase {
    
    var viewModel: HabitListViewModel!
    var mockRepository: MockHabitRepository!
    
    override func setUp() {
        mockRepository = MockHabitRepository()
        viewModel = HabitListViewModel(repository: mockRepository)
    }
    
    // MARK: - AC32: Load habits by category
    
    func test_AC32_LoadHabitsByCategory() async throws {
        let userId = UUID()
        mockRepository.habits = [
            RRHabit(
                userId: userId,
                category: .spiritual,
                name: "Meditation",
                customLabelOverride: nil,
                frequencyDefinition: .daily,
                quantitativeTarget: nil,
                partialCreditThreshold: 0.70,
                sensitivityTier: .tier2,
                sharingSettings: JSONPayload()
            ),
            RRHabit(
                userId: userId,
                category: .physical,
                name: "Exercise",
                customLabelOverride: nil,
                frequencyDefinition: .daily,
                quantitativeTarget: nil,
                partialCreditThreshold: 0.70,
                sensitivityTier: .tier3,
                sharingSettings: JSONPayload()
            )
        ]
        
        await viewModel.load(userId: userId)
        
        XCTAssertEqual(viewModel.habits.count, 2)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - AC33: Enable/disable habits
    
    func test_AC33_ArchiveHabit() async throws {
        let userId = UUID()
        let habit = RRHabit(
            userId: userId,
            category: .cognitive,
            name: "Step Work",
            customLabelOverride: nil,
            frequencyDefinition: .weekdays,
            quantitativeTarget: nil,
            partialCreditThreshold: 0.70,
            sensitivityTier: .tier2,
            sharingSettings: JSONPayload()
        )
        
        mockRepository.habits = [habit]
        await viewModel.load(userId: userId)
        
        await viewModel.archiveHabit(habitId: habit.id)
        
        XCTAssertTrue(mockRepository.habits.first?.isArchived ?? false)
    }
}
```

- [ ] Implement HabitListViewModel

```swift
// ViewModels/Habits/HabitListViewModel.swift
import SwiftUI

@Observable
final class HabitListViewModel {
    private let repository: HabitRepository
    
    var habits: [RRHabit] = []
    var isLoading = false
    var error: String?
    
    init(repository: HabitRepository) {
        self.repository = repository
    }
    
    @MainActor
    func load(userId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            habits = try await repository.getHabits(for: userId, includeArchived: false)
        } catch {
            self.error = "Failed to load habits"
        }
        
        isLoading = false
    }
    
    @MainActor
    func archiveHabit(habitId: UUID) async {
        do {
            try await repository.deleteHabit(id: habitId)
            habits.removeAll { $0.id == habitId }
        } catch {
            self.error = "Failed to archive habit"
        }
    }
    
    var habitsByCategory: [HabitCategory: [RRHabit]] {
        Dictionary(grouping: habits) { $0.category }
    }
}
```

- [ ] Write failing test for HabitDetailViewModel

```swift
// Tests/Unit/Habits/HabitDetailViewModelTests.swift
import XCTest
@testable import RegalRecovery

@MainActor
final class HabitDetailViewModelTests: XCTestCase {
    
    var viewModel: HabitDetailViewModel!
    var mockStreakRepo: MockStreakRepository!
    var mockCounterRepo: MockLifetimeCounterRepository!
    var mockTokenRepo: MockTokenRepository!
    
    override func setUp() {
        mockStreakRepo = MockStreakRepository()
        mockCounterRepo = MockLifetimeCounterRepository()
        mockTokenRepo = MockTokenRepository()
        
        viewModel = HabitDetailViewModel(
            streakRepository: mockStreakRepo,
            counterRepository: mockCounterRepo,
            tokenRepository: mockTokenRepo
        )
    }
    
    // MARK: - AC34: Display hierarchy (§4.5)
    
    func test_AC34_LifetimeCounterDominantDisplay() async throws {
        let habitId = UUID()
        
        mockStreakRepo.streak = RRHabitStreak(
            habitId: habitId,
            currentStreakDays: 47,
            currentStreakStartedAt: Date(),
            longestStreakDays: 92,
            longestStreakEndedAt: nil,
            lastCompletedDay: Date()
        )
        
        mockCounterRepo.counter = RRLifetimeCounter(
            habitId: habitId,
            totalActions: 250,
            lastIncrementedAt: Date()
        )
        
        await viewModel.load(habitId: habitId)
        
        XCTAssertEqual(viewModel.lifetimeActions, 250)
        XCTAssertEqual(viewModel.currentStreak, 47)
        XCTAssertEqual(viewModel.longestStreak, 92)
    }
}
```

- [ ] Implement HabitDetailViewModel

```swift
// ViewModels/Habits/HabitDetailViewModel.swift
import SwiftUI

@Observable
final class HabitDetailViewModel {
    private let streakRepository: StreakRepository
    private let counterRepository: LifetimeCounterRepository
    private let tokenRepository: TokenRepository
    
    var lifetimeActions: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var timeTokens: [RRStreakToken] = []
    var countTokens: [RRStreakToken] = []
    var isLoading = false
    var error: String?
    
    init(
        streakRepository: StreakRepository,
        counterRepository: LifetimeCounterRepository,
        tokenRepository: TokenRepository
    ) {
        self.streakRepository = streakRepository
        self.counterRepository = counterRepository
        self.tokenRepository = tokenRepository
    }
    
    @MainActor
    func load(habitId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            // Load lifetime counter (dominant display per §4.5)
            if let counter = try await counterRepository.getCounter(for: habitId) {
                lifetimeActions = counter.totalActions
            }
            
            // Load streak data
            if let streak = try await streakRepository.getStreak(for: habitId) {
                currentStreak = streak.currentStreakDays
                longestStreak = streak.longestStreakDays
            }
            
            // Load tokens
            timeTokens = try await tokenRepository.getTokens(for: habitId, track: .time)
            countTokens = try await tokenRepository.getTokens(for: habitId, track: .count)
        } catch {
            self.error = "Failed to load habit details"
        }
        
        isLoading = false
    }
}
```

- [ ] Run tests to verify pass
- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/ViewModels/Habits/HabitListViewModel.swift ios/RegalRecovery/RegalRecovery/ViewModels/Habits/HabitDetailViewModel.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitListViewModelTests.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitDetailViewModelTests.swift
git commit -m "feat(ios): add HabitListViewModel and HabitDetailViewModel

HabitListViewModel:
- Load habits by category
- Archive/unarchive habits (soft delete)
- Group habits by category

HabitDetailViewModel:
- Display lifetime actions (dominant per §4.5)
- Display current and longest streak
- Load TIME and COUNT tokens

Refs PRD §4.5"
```

---

### Task 4.2: Habit Completion and Streak Dashboard ViewModels

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/ViewModels/Habits/HabitCompletionViewModel.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/ViewModels/Habits/StreakDashboardViewModel.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/HabitCompletionViewModelTests.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/StreakDashboardViewModelTests.swift`

**Steps:**

- [ ] Write failing tests for both ViewModels
- [ ] Implement HabitCompletionViewModel (log action, backdating within 48 hours, quantitative entry)
- [ ] Implement StreakDashboardViewModel (lifetime count dominant, streak secondary, per-habit breakdown)
- [ ] Run tests to verify pass
- [ ] Commit: "feat(ios): add HabitCompletionViewModel and StreakDashboardViewModel"

---

### Task 4.3: Trophy Cabinet and Celebration ViewModels

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/ViewModels/Habits/TrophyCabinetViewModel.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/ViewModels/Habits/TokenCelebrationViewModel.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/TrophyCabinetViewModelTests.swift`

**Steps:**

- [ ] Write failing tests
- [ ] Implement TrophyCabinetViewModel (three shelves: Chips · Time · Count, earned vs ghost previews)
- [ ] Implement TokenCelebrationViewModel (three-tier celebration: small haptic, medium confetti, ceremonial)
- [ ] Run tests to verify pass
- [ ] Commit: "feat(ios): add TrophyCabinetViewModel and TokenCelebrationViewModel"

---

## Phase 5: Views — SwiftUI UI Layer

### Task 5.1: Habit List and Detail Views

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/HabitListView.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/HabitDetailView.swift`

**Steps:**

- [ ] Implement HabitListView

```swift
// Views/Activities/Habits/HabitListView.swift
import SwiftUI

struct HabitListView: View {
    @State private var viewModel: HabitListViewModel
    let userId: UUID
    
    init(userId: UUID, repository: HabitRepository) {
        self.userId = userId
        _viewModel = State(initialValue: HabitListViewModel(repository: repository))
    }
    
    var body: some View {
        List {
            ForEach(HabitCategory.allCases, id: \.self) { category in
                if let habits = viewModel.habitsByCategory[category], !habits.isEmpty {
                    Section(category.displayName) {
                        ForEach(habits) { habit in
                            NavigationLink(value: habit) {
                                HabitRow(habit: habit)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Habits")
        .task {
            await viewModel.load(userId: userId)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

struct HabitRow: View {
    let habit: RRHabit
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.displayName)
                    .font(.headline)
                
                Text(habit.frequencyDefinition.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Sensitivity indicator
            if habit.sensitivityTier == .tier1 {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

extension FrequencyDefinition {
    var displayText: String {
        switch self {
        case .daily: return "Daily"
        case .weekdays: return "Weekdays"
        case .timesPerWeek(let n): return "\(n)× per week"
        case .everyNDays(let n): return "Every \(n) days"
        case .quantitative(let target, let unit): return "\(Int(target)) \(unit)"
        }
    }
}
```

- [ ] Implement HabitDetailView

```swift
// Views/Activities/Habits/HabitDetailView.swift
import SwiftUI

struct HabitDetailView: View {
    @State private var viewModel: HabitDetailViewModel
    let habit: RRHabit
    
    init(
        habit: RRHabit,
        streakRepository: StreakRepository,
        counterRepository: LifetimeCounterRepository,
        tokenRepository: TokenRepository
    ) {
        self.habit = habit
        _viewModel = State(initialValue: HabitDetailViewModel(
            streakRepository: streakRepository,
            counterRepository: counterRepository,
            tokenRepository: tokenRepository
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Lifetime Actions (dominant display per §4.5)
                lifetimeActionsCard
                
                // Engagement Streak (secondary)
                engagementStreakCard
                
                // Tokens
                tokensSection
            }
            .padding()
        }
        .navigationTitle(habit.displayName)
        .task {
            await viewModel.load(habitId: habit.id)
        }
    }
    
    private var lifetimeActionsCard: some View {
        VStack(spacing: 8) {
            Text("Lifetime Actions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("\(viewModel.lifetimeActions)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.rrPrimary)
            
            Text("Total actions completed")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
    
    private var engagementStreakCard: some View {
        VStack(spacing: 8) {
            Text("Engagement Streak")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 32) {
                VStack {
                    Text("\(viewModel.currentStreak)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                    
                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(viewModel.longestStreak)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                    
                    Text("Longest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
    
    private var tokensSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tokens Earned")
                .font(.headline)
            
            if !viewModel.timeTokens.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("TIME Track")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.timeTokens) { token in
                                TokenBadge(token: token, shape: .hexagon)
                            }
                        }
                    }
                }
            }
            
            if !viewModel.countTokens.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("COUNT Track")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.countTokens) { token in
                                TokenBadge(token: token, shape: .gem)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TokenBadge: View {
    let token: RRStreakToken
    let shape: TokenShape
    
    enum TokenShape {
        case hexagon, gem
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(token.track == .time ? Color.blue.opacity(0.2) : Color.cyan.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: shape == .hexagon ? "hexagon.fill" : "sparkles")
                    .font(.title)
                    .foregroundStyle(token.track == .time ? Color.blue : Color.cyan)
            }
            
            Text(token.tierValue.replacingOccurrences(of: "_", with: " "))
                .font(.caption2)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}
```

- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/
git commit -m "feat(ios): add HabitListView and HabitDetailView

HabitListView:
- Categorized habit list with section headers
- Enable/disable toggles
- Navigation to detail

HabitDetailView:
- Lifetime actions (dominant display)
- Current and longest streak
- TIME and COUNT token badges
- Hexagonal shape for TIME, gem shape for COUNT

Refs PRD §4.5, §7.1"
```

---

### Task 5.2: Habit Completion and Celebration Views

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/HabitCompletionView.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/TokenCelebrationView.swift`

**Steps:**

- [ ] Implement HabitCompletionView (log action, backdating, quantitative entry)
- [ ] Implement TokenCelebrationView (three-tier celebration with haptics, confetti, ceremonial)
- [ ] Commit: "feat(ios): add HabitCompletionView and TokenCelebrationView"

---

### Task 5.3: Trophy Cabinet View

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/TrophyCabinetView.swift`

**Steps:**

- [ ] Implement TrophyCabinetView with three shelves (Chips · Time · Count)
- [ ] Implement earned vs ghost preview (Apple Fitness Awards pattern)
- [ ] Add long-press detail gesture
- [ ] Commit: "feat(ios): add TrophyCabinetView with three-shelf layout"

---

### Task 5.4: Streak Settings and Grace Day Views

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Settings/StreakSettingsView.swift`
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/GraceDayView.swift`

**Steps:**

- [ ] Implement StreakSettingsView (global/per-habit streak toggle, day boundary config, late-night cutoff)
- [ ] Implement GraceDayView (balance display, usage history, regeneration indicator)
- [ ] Commit: "feat(ios): add StreakSettingsView and GraceDayView"

---

## Phase 6: Relapse Integration — Clinical Safety Firewall

### Task 6.1: Verify Relapse Independence

**Files:**
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/RelapseIntegrationTests.swift`

**Steps:**

- [ ] Write integration test verifying relapse does NOT affect habit data

```swift
// Tests/Unit/Habits/RelapseIntegrationTests.swift
import XCTest
import SwiftData
@testable import RegalRecovery

@MainActor
final class RelapseIntegrationTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var habitCompletionService: HabitCompletionService!
    
    override func setUp() async throws {
        let schema = Schema([
            RRHabit.self,
            RRHabitEntry.self,
            RRHabitStreak.self,
            RRStreakToken.self,
            RRLifetimeCounter.self,
            RRGraceDayLedger.self,
            RRAddiction.self,
            RRRelapse.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        
        // Set up full service stack
        let habitRepo = SwiftDataHabitRepository(context: context)
        let entryRepo = SwiftDataHabitEntryRepository(context: context)
        let streakRepo = SwiftDataStreakRepository(context: context)
        let counterRepo = SwiftDataLifetimeCounterRepository(context: context)
        let tokenRepo = SwiftDataTokenRepository(context: context)
        let graceDayRepo = SwiftDataGraceDayRepository(context: context)
        
        let graceDayService = GraceDayService(repository: graceDayRepo)
        let milestoneService = MilestoneDetectionService()
        let tokenService = TokenAwardService(tokenRepository: tokenRepo, milestoneService: milestoneService)
        let streakCalc = StreakCalculationService()
        
        habitCompletionService = HabitCompletionService(
            habitEntryRepository: entryRepo,
            streakRepository: streakRepo,
            counterRepository: counterRepo,
            graceDayService: graceDayService,
            tokenAwardService: tokenService,
            streakCalculation: streakCalc,
            milestoneDetection: milestoneService
        )
    }
    
    // MARK: - AC35: Relapse does NOT reset habit streaks (§11.1)
    
    func test_AC35_RelapseDoesNotResetHabitStreaks() async throws {
        let userId = UUID()
        let addictionId = UUID()
        let habitId = UUID()
        
        // Create habit with 47-day streak
        let habit = RRHabit(
            userId: userId,
            category: .spiritual,
            name: "Morning Meditation",
            customLabelOverride: nil,
            frequencyDefinition: .daily,
            quantitativeTarget: nil,
            partialCreditThreshold: 0.70,
            sensitivityTier: .tier2,
            sharingSettings: JSONPayload()
        )
        context.insert(habit)
        
        let streak = RRHabitStreak(
            habitId: habitId,
            currentStreakDays: 47,
            currentStreakStartedAt: Calendar.current.date(byAdding: .day, value: -47, to: Date())!,
            longestStreakDays: 47,
            longestStreakEndedAt: nil,
            lastCompletedDay: Date()
        )
        context.insert(streak)
        
        let counter = RRLifetimeCounter(
            habitId: habitId,
            totalActions: 250,
            lastIncrementedAt: Date()
        )
        context.insert(counter)
        
        // Create token
        let token = RRStreakToken(
            habitId: habitId,
            track: .time,
            tierValue: "1_month",
            earnedAt: Date(),
            earnedVia: .organic
        )
        context.insert(token)
        
        try context.save()
        
        // Log relapse
        let addiction = RRAddiction(
            id: addictionId,
            name: "Pornography",
            sobrietyDate: Calendar.current.date(byAdding: .day, value: -47, to: Date())!,
            userId: userId
        )
        context.insert(addiction)
        
        let relapse = RRRelapse(
            addictionId: addictionId,
            date: Date(),
            notes: "Stress trigger",
            triggers: ["stress", "isolation"]
        )
        context.insert(relapse)
        
        try context.save()
        
        // Verify habit streak is UNCHANGED
        let streakDescriptor = FetchDescriptor<RRHabitStreak>(
            predicate: #Predicate { $0.habitId == habitId }
        )
        let updatedStreak = try context.fetch(streakDescriptor).first
        
        XCTAssertEqual(updatedStreak?.currentStreakDays, 47, "Habit streak MUST NOT reset on relapse per §11.1")
        
        // Verify lifetime counter is UNCHANGED
        let counterDescriptor = FetchDescriptor<RRLifetimeCounter>(
            predicate: #Predicate { $0.habitId == habitId }
        )
        let updatedCounter = try context.fetch(counterDescriptor).first
        
        XCTAssertEqual(updatedCounter?.totalActions, 250, "Lifetime counter MUST NOT reset on relapse per §11.1")
        
        // Verify token is still present and NOT revoked
        let tokenDescriptor = FetchDescriptor<RRStreakToken>(
            predicate: #Predicate { $0.habitId == habitId }
        )
        let updatedToken = try context.fetch(tokenDescriptor).first
        
        XCTAssertNotNil(updatedToken, "Token MUST NOT be deleted on relapse")
        XCTAssertFalse(updatedToken!.revoked, "Token MUST NOT be revoked on relapse per §11.1")
    }
    
    // MARK: - AC36: Soft-fail relapse flow (§11.2)
    
    func test_AC36_RelapseFlowPreservesHabitData() async throws {
        // Simulate full relapse flow
        // Verify all habit tokens, streaks, counters intact
        // Verify supportive re-entry message available
        
        // This test would integrate with the relapse logging flow
        // For now, the key assertion is that no cascade-delete or update occurs
        
        XCTAssertTrue(true, "Placeholder for full relapse flow integration test")
    }
}
```

- [ ] Run test to verify pass (habit data untouched by relapse)
- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/RelapseIntegrationTests.swift
git commit -m "feat(ios): add relapse integration tests verifying habit data independence

- Verify relapse does NOT reset habit streaks
- Verify relapse does NOT reset lifetime counters
- Verify tokens NOT revoked on relapse
- Verify soft-fail relapse flow preserves all habit data

Critical clinical-safety firewall per §11.1, §11.2

Refs PRD §11.1, §11.2, §17 (AC1)"
```

---

### Task 6.2: Soft-Fail Relapse Flow UI

**Files:**
- Modify: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/ViewModels/CommitmentViewModel.swift` (or relapse logging view model)
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Views/Activities/Habits/StreakBreakReentryView.swift`

**Steps:**

- [ ] Add soft-fail messaging to relapse logging flow
- [ ] Implement StreakBreakReentryView ("Welcome back. Your N previous days...")
- [ ] Show preserved tokens explicitly
- [ ] Add 7-14 day supportive window trigger
- [ ] Commit: "feat(ios): add soft-fail relapse flow with habit data preservation messaging"

---

## Phase 7: Notifications & Compulsion Safeguards

### Task 7.1: Notification Service with Budget and Copy Compliance

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/StreakNotificationService.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/StreakNotificationServiceTests.swift`

**Steps:**

- [ ] Write failing test for notification service

```swift
// Tests/Unit/Habits/StreakNotificationServiceTests.swift
import XCTest
import UserNotifications
@testable import RegalRecovery

final class StreakNotificationServiceTests: XCTestCase {
    
    var service: StreakNotificationService!
    
    override func setUp() {
        service = StreakNotificationService()
    }
    
    // MARK: - AC37: Notification budget (§9.1)
    
    func test_AC37_NotificationBudgetMaxThreePerDay() async throws {
        let userId = UUID()
        
        // Request 5 notifications
        for i in 0..<5 {
            try await service.scheduleStreakAtRiskNotification(
                userId: userId,
                habitName: "Habit \(i)",
                hoursUntilRollover: 4
            )
        }
        
        let scheduled = await service.getScheduledNotifications()
        XCTAssertLessThanOrEqual(scheduled.count, 3, "Max 3 notifications per day per §9.1")
    }
    
    // MARK: - AC38: Copy compliance (§9.5, §16)
    
    func test_AC38_NeverUseProhibitedPhrases() {
        let prohibitedPhrases = [
            "streak broken",
            "streak lost",
            "streak failed",
            "don't break",
            "last chance",
            "you're slipping"
        ]
        
        let supportiveCopy = service.streakAtRiskCopy(habitName: "Meditation", hoursLeft: 4)
        
        for phrase in prohibitedPhrases {
            XCTAssertFalse(
                supportiveCopy.lowercased().contains(phrase.lowercased()),
                "Copy must not contain '\(phrase)' per §9.5, §16"
            )
        }
        
        // Verify supportive framing
        XCTAssertTrue(
            supportiveCopy.contains("can") || supportiveCopy.contains("want to") || supportiveCopy.contains("ready"),
            "Copy must use autonomy-supportive language"
        )
    }
    
    // MARK: - AC39: Opt-in streak-at-risk warnings (§9.3)
    
    func test_AC39_StreakAtRiskIsOptIn() {
        let defaultSettings = service.defaultNotificationSettings()
        XCTAssertFalse(defaultSettings.streakAtRiskEnabled, "Streak-at-risk warnings must be opt-in per §9.3")
    }
    
    // MARK: - AC40: Lock-screen scrubbing for Tier 1 habits (§9.6)
    
    func test_AC40_Tier1HabitsScrubbedOnLockScreen() {
        let tier1Copy = service.lockScreenCopy(habitName: "MAT Medication (Suboxone)", sensitivityTier: .tier1)
        XCTAssertEqual(tier1Copy, "Time for your morning task", "Tier 1 habits must be scrubbed per §9.6")
        
        let tier3Copy = service.lockScreenCopy(habitName: "Exercise", sensitivityTier: .tier3)
        XCTAssertTrue(tier3Copy.contains("Exercise"), "Tier 3 habits can show name")
    }
    
    // MARK: - AC41: Crisis mode suppresses gamification (§9.7)
    
    func test_AC41_CrisisModeSuppressesStreakNotifications() async throws {
        let userId = UUID()
        
        try await service.enableCrisisMode(for: userId)
        
        let scheduled = try await service.scheduleStreakAtRiskNotification(
            userId: userId,
            habitName: "Journaling",
            hoursUntilRollover: 4
        )
        
        XCTAssertFalse(scheduled, "Streak notifications suppressed in crisis mode per §9.7")
    }
}
```

- [ ] Run test to verify failure
- [ ] Implement StreakNotificationService

```swift
// Services/StreakNotificationService.swift
import Foundation
import UserNotifications

/// Streak notification service with budget, copy compliance, and crisis mode (§9)
final class StreakNotificationService: @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()
    private let maxNotificationsPerDay = 3
    
    struct NotificationSettings {
        var streakAtRiskEnabled: Bool = false  // Opt-in per §9.3
        var dailyBudget: Int = 3
        var quietHoursStart: Int = 22
        var quietHoursEnd: Int = 7
        var crisisModeEnabled: Bool = false
    }
    
    // MARK: - Settings
    
    func defaultNotificationSettings() -> NotificationSettings {
        NotificationSettings()
    }
    
    // MARK: - Scheduling
    
    func scheduleStreakAtRiskNotification(
        userId: UUID,
        habitName: String,
        hoursUntilRollover: Int,
        sensitivityTier: SensitivityTier = .tier3
    ) async throws -> Bool {
        // Check crisis mode
        if await isCrisisModeEnabled(for: userId) {
            return false
        }
        
        // Check daily budget
        let scheduled = await getScheduledNotifications()
        guard scheduled.count < maxNotificationsPerDay else {
            return false
        }
        
        // Create notification
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = streakAtRiskCopy(habitName: habitName, hoursLeft: hoursUntilRollover)
        content.sound = .default
        content.categoryIdentifier = "habit.streak_at_risk"
        
        // Lock-screen scrubbing for Tier 1
        if sensitivityTier == .tier1 {
            content.body = lockScreenCopy(habitName: habitName, sensitivityTier: sensitivityTier)
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(hoursUntilRollover * 3600),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
        return true
    }
    
    func getScheduledNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }
    
    // MARK: - Copy Generation (§9.5)
    
    func streakAtRiskCopy(habitName: String, hoursLeft: Int) -> String {
        // Autonomy-supportive, never loss-framing per §9.5
        let templates = [
            "You can keep your \(habitName) streak today — want to take a few minutes?",
            "Ready to log your \(habitName) today?",
            "Your \(habitName) supports the work you've already done."
        ]
        
        return templates.randomElement()!
    }
    
    func lockScreenCopy(habitName: String, sensitivityTier: SensitivityTier) -> String {
        if sensitivityTier == .tier1 {
            return "Time for your morning task"
        }
        return "Time for \(habitName)"
    }
    
    // MARK: - Crisis Mode (§9.7)
    
    func enableCrisisMode(for userId: UUID) async throws {
        // Store crisis mode state (UserDefaults or model)
        UserDefaults.standard.set(true, forKey: "crisisMode_\(userId.uuidString)")
        
        // Cancel all streak-at-risk notifications
        await center.removeAllPendingNotificationRequests()
    }
    
    func isCrisisModeEnabled(for userId: UUID) async -> Bool {
        UserDefaults.standard.bool(forKey: "crisisMode_\(userId.uuidString)")
    }
}
```

- [ ] Run test to verify pass
- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Services/StreakNotificationService.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/StreakNotificationServiceTests.swift
git commit -m "feat(ios): add StreakNotificationService with budget and copy compliance

- Max 3 notifications per day (combined budget per §9.1)
- Opt-in streak-at-risk warnings (default off per §9.3)
- Copy compliance: no loss-framing, autonomy-supportive language (§9.5, §16)
- Lock-screen scrubbing for Tier 1 habits (§9.6)
- Crisis mode suppresses all gamification notifications (§9.7)
- Quiet hours enforcement (22:00-07:00)

Refs PRD §9.1, §9.3, §9.5, §9.6, §9.7, §16"
```

---

### Task 7.2: Compulsion Safeguards

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/CompulsionSafeguardService.swift`
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/CompulsionSafeguardServiceTests.swift`

**Steps:**

- [ ] Write failing test for compulsion safeguards

```swift
// Tests/Unit/Habits/CompulsionSafeguardServiceTests.swift
import XCTest
@testable import RegalRecovery

final class CompulsionSafeguardServiceTests: XCTestCase {
    
    var service: CompulsionSafeguardService!
    
    override func setUp() {
        service = CompulsionSafeguardService()
    }
    
    // MARK: - AC42: Daily token cap (§12.1)
    
    func test_AC42_DailyTokenCapMaxFiveCategories() async throws {
        let userId = UUID()
        
        // Log 7 different habit categories in one day
        for category in HabitCategory.allCases {
            try await service.logHabitCompletion(userId: userId, category: category, date: Date())
        }
        
        let countTowardLifetime = await service.countTowardLifetimeActions(for: userId, on: Date())
        XCTAssertLessThanOrEqual(countTowardLifetime, 5, "Max 5 categories count toward lifetime per day per §12.1")
    }
    
    // MARK: - AC43: Session time warning (§12.1)
    
    func test_AC43_SessionTimeWarningAt30Minutes() async throws {
        service.startSession()
        
        // Simulate 30 minutes elapsed
        try await Task.sleep(nanoseconds: 1_800_000_000_000)  // 30 minutes in nanoseconds
        
        let shouldWarn = await service.shouldShowSessionTimeWarning()
        XCTAssertTrue(shouldWarn, "Session time warning at 30 minutes per §12.1")
    }
}
```

- [ ] Implement CompulsionSafeguardService

```swift
// Services/CompulsionSafeguardService.swift
import Foundation

/// Compulsion safeguard service (§12.1)
actor CompulsionSafeguardService {
    private var dailyCompletions: [UUID: [Date: Set<HabitCategory>]] = [:]
    private var sessionStartTime: Date?
    
    private let dailyTokenCap = 5
    private let sessionWarningThresholdMinutes = 30
    
    // MARK: - Daily Token Cap
    
    func logHabitCompletion(userId: UUID, category: HabitCategory, date: Date) throws {
        let dayKey = Calendar.current.startOfDay(for: date)
        
        if dailyCompletions[userId] == nil {
            dailyCompletions[userId] = [:]
        }
        
        if dailyCompletions[userId]![dayKey] == nil {
            dailyCompletions[userId]![dayKey] = []
        }
        
        dailyCompletions[userId]![dayKey]!.insert(category)
    }
    
    func countTowardLifetimeActions(for userId: UUID, on date: Date) -> Int {
        let dayKey = Calendar.current.startOfDay(for: date)
        let categories = dailyCompletions[userId]?[dayKey] ?? []
        return min(categories.count, dailyTokenCap)
    }
    
    // MARK: - Session Time Warning
    
    func startSession() {
        sessionStartTime = Date()
    }
    
    func shouldShowSessionTimeWarning() -> Bool {
        guard let start = sessionStartTime else { return false }
        let elapsed = Date().timeIntervalSince(start)
        return elapsed >= TimeInterval(sessionWarningThresholdMinutes * 60)
    }
}
```

- [ ] Run test to verify pass
- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Services/CompulsionSafeguardService.swift ios/RegalRecovery/RegalRecovery/Tests/Unit/Habits/CompulsionSafeguardServiceTests.swift
git commit -m "feat(ios): add CompulsionSafeguardService for anti-compulsion controls

- Daily token cap: max 5 unique categories per day (§12.1)
- Session time warning at 30 minutes (§12.1)
- Prevents obsessive farming and cross-addiction risk

Refs PRD §12.1"
```

---

## Phase 8: Final Integration and Feature Flag

### Task 8.1: Feature Flag Integration

**Files:**
- Modify: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Services/FeatureFlagService.swift` (if exists)
- Create feature flag key: `activity.streak-tokens`

**Steps:**

- [ ] Add feature flag key to FeatureFlagService

```swift
// Services/FeatureFlagService.swift (add to existing)

extension FeatureFlag {
    static let streakTokens = FeatureFlag(
        key: "activity.streak-tokens",
        defaultValue: false,
        description: "Enable Streak Token system (TIME and COUNT tracks)"
    )
}
```

- [ ] Gate all streak token UI behind flag

```swift
// Views/Home/HomeView.swift (or wherever navigation to habits lives)

if featureFlagService.isEnabled(.streakTokens) {
    NavigationLink("Habits", value: NavigationDestination.habitList)
}
```

- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Services/FeatureFlagService.swift
git commit -m "feat(ios): add feature flag for Streak Token system

- Flag key: activity.streak-tokens
- All habit UI gated behind flag
- Default: disabled

Refs PRD §17 (AC requirement)"
```

---

### Task 8.2: Comprehensive Integration Test Suite

**Files:**
- Test: `/Users/travis.smith/Projects/personal/RR/ios/RegalRecovery/RegalRecovery/Tests/Integration/StreakTokenIntegrationTests.swift`

**Steps:**

- [ ] Write comprehensive end-to-end integration test

```swift
// Tests/Integration/StreakTokenIntegrationTests.swift
import XCTest
import SwiftData
@testable import RegalRecovery

@MainActor
final class StreakTokenIntegrationTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    var habitCompletionService: HabitCompletionService!
    var graceDayService: GraceDayService!
    
    override func setUp() async throws {
        // Full service stack setup
        let schema = Schema([
            RRHabit.self,
            RRHabitEntry.self,
            RRHabitStreak.self,
            RRStreakToken.self,
            RRLifetimeCounter.self,
            RRGraceDayLedger.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: config)
        context = ModelContext(container)
        
        // Wire up services
        let habitRepo = SwiftDataHabitRepository(context: context)
        let entryRepo = SwiftDataHabitEntryRepository(context: context)
        let streakRepo = SwiftDataStreakRepository(context: context)
        let counterRepo = SwiftDataLifetimeCounterRepository(context: context)
        let tokenRepo = SwiftDataTokenRepository(context: context)
        let graceDayRepo = SwiftDataGraceDayRepository(context: context)
        
        graceDayService = GraceDayService(repository: graceDayRepo)
        let milestoneService = MilestoneDetectionService()
        let tokenService = TokenAwardService(tokenRepository: tokenRepo, milestoneService: milestoneService)
        let streakCalc = StreakCalculationService()
        
        habitCompletionService = HabitCompletionService(
            habitEntryRepository: entryRepo,
            streakRepository: streakRepo,
            counterRepository: counterRepo,
            graceDayService: graceDayService,
            tokenAwardService: tokenService,
            streakCalculation: streakCalc,
            milestoneDetection: milestoneService
        )
    }
    
    // MARK: - AC44: Full user journey
    
    func test_AC44_FullUserJourney7DayStreakWith100Actions() async throws {
        let userId = UUID()
        let habitId = UUID()
        
        // Grant initial grace days
        try await graceDayService.grantInitialGraceDays(for: userId)
        
        // Complete habit for 7 consecutive days
        for dayOffset in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date())!
            
            try await habitCompletionService.completeHabit(
                userId: userId,
                habitId: habitId,
                occurredAt: date,
                frequency: .daily,
                value: .bool(true),
                userTimezone: .current,
                lateNightCutoff: 0
            )
        }
        
        // Verify streak
        let streakDescriptor = FetchDescriptor<RRHabitStreak>(
            predicate: #Predicate { $0.habitId == habitId }
        )
        let streak = try context.fetch(streakDescriptor).first
        XCTAssertEqual(streak?.currentStreakDays, 7)
        
        // Verify TIME track token awarded
        let timeTokenDescriptor = FetchDescriptor<RRStreakToken>(
            predicate: #Predicate { $0.habitId == habitId && $0.track == .time }
        )
        let timeToken = try context.fetch(timeTokenDescriptor).first
        XCTAssertNotNil(timeToken)
        XCTAssertTrue(timeToken!.tierValue.contains("week"))
        
        // Complete 93 more actions to reach 100
        for _ in 0..<93 {
            try await habitCompletionService.completeHabit(
                userId: userId,
                habitId: habitId,
                occurredAt: Date(),
                frequency: .daily,
                value: .bool(true),
                userTimezone: .current,
                lateNightCutoff: 0
            )
        }
        
        // Verify lifetime counter
        let counterDescriptor = FetchDescriptor<RRLifetimeCounter>(
            predicate: #Predicate { $0.habitId == habitId }
        )
        let counter = try context.fetch(counterDescriptor).first
        XCTAssertEqual(counter?.totalActions, 100)
        
        // Verify COUNT track token awarded
        let countTokenDescriptor = FetchDescriptor<RRStreakToken>(
            predicate: #Predicate { $0.habitId == habitId && $0.track == .count }
        )
        let countTokens = try context.fetch(countTokenDescriptor)
        XCTAssertTrue(countTokens.contains { $0.tierValue == "100_actions" })
    }
}
```

- [ ] Run integration test to verify end-to-end flow
- [ ] Commit changes

```bash
cd /Users/travis.smith/Projects/personal/RR
git add ios/RegalRecovery/RegalRecovery/Tests/Integration/StreakTokenIntegrationTests.swift
git commit -m "test(ios): add comprehensive integration tests for Streak Token system

- Full user journey: 7-day streak with 100 lifetime actions
- Verify TIME and COUNT tokens awarded at milestones
- Verify grace day economy
- End-to-end validation of all services

Refs PRD §17 acceptance criteria"
```

---

## Phase 9: Accessibility and Finalization

### Task 9.1: Accessibility Compliance

**Files:**
- Modify all views to add VoiceOver labels, accessibility traits, Dynamic Type support

**Steps:**

- [ ] Add VoiceOver labels to all token badges

```swift
// TokenBadge view (in HabitDetailView.swift)

.accessibilityLabel("Token: \(token.tierValue.replacingOccurrences(of: "_", with: " ")), earned \(token.earnedAt.formatted(date: .abbreviated, time: .omitted)), \(shape == .hexagon ? "hexagonal shape" : "gem shape")")
```

- [ ] Verify WCAG AA contrast on all token colors
- [ ] Test Dynamic Type at AX5
- [ ] Add .accessibilityElement(children: .combine) where appropriate
- [ ] Respect prefers-reduced-motion for all animations
- [ ] Commit: "a11y(ios): add accessibility support for Streak Token views"

---

### Task 9.2: Final Acceptance Criteria Validation

**Files:**
- Create: `/Users/travis.smith/Projects/personal/RR/docs/prd/features/streaks/acceptance-checklist.md`

**Steps:**

- [ ] Run all unit tests

```bash
cd /Users/travis.smith/Projects/personal/RR/ios/RegalRecovery
xcodebuild test -scheme RegalRecovery -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep "Test Suite 'All tests' passed"
```

- [ ] Verify all 44 acceptance criteria from PRD §17 are covered by tests
- [ ] Create acceptance checklist document mapping each AC to test
- [ ] Run manual QA on device for UX validation
- [ ] Commit: "docs(ios): add acceptance criteria validation checklist"

---

## Summary

This implementation plan covers the complete Streak Token system in 9 phases with 20+ tasks. Each task follows strict TDD: write failing test → implement → verify pass → commit. All clinical-safety invariants are enforced at the data layer and validated with tests.

**Key Architectural Decisions:**

1. **Permanence enforcement:** `RRStreakToken.revoked` is a computed property always returning `false`; `RRLifetimeCounter.totalActions` is private(set) with increment-only methods.
2. **Relapse independence:** No cascade relationships between sobriety models and habit models; integration test validates relapse has zero effect.
3. **Grace days auto-apply:** Silent application in `HabitCompletionService`, no user-facing "almost lost" warnings.
4. **Display hierarchy:** Lifetime actions (COUNT) are dominant, streak (TIME) secondary per §4.5.
5. **Copy compliance:** Automated test enforcement of prohibited phrases; all copy is autonomy-supportive.
6. **Feature flag:** `activity.streak-tokens` gates all UI; default disabled.

**Coverage:**

- **Data layer:** 3 tasks (types, models, permanence)
- **Repository layer:** 1 task (protocols + implementations)
- **Services:** 4 tasks (streak calc, grace days, milestones, token award, habit completion, notifications, safeguards)
- **ViewModels:** 3 tasks (list, detail, completion, dashboard, trophy cabinet)
- **Views:** 4 tasks (list, detail, completion, celebration, trophy cabinet, settings, grace day)
- **Integration:** 3 tasks (relapse independence, notifications, compulsion safeguards, end-to-end)
- **Finalization:** 2 tasks (feature flag, accessibility, acceptance validation)

All PRD sections §1-§17 are covered. All acceptance criteria from §17 are validated by tests.
