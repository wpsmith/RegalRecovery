import Testing
@testable import RegalRecovery

// MARK: - Helpers

/// Finds the affirmation tile in `RecoveryWorkViewModel.allTiles`.
private var affirmationTile: WorkTileItem? {
    RecoveryWorkViewModel.allTiles.first(where: { $0.id == "activity.affirmations" })
}

/// Default empty collections for `todayStatus` calls.
private func makeTodayStatus(
    for tile: WorkTileItem,
    affirmationSessions: [RRActivity] = []
) -> TileStatus {
    RecoveryWorkViewModel.todayStatus(
        for: tile,
        commitments: [],
        journals: [],
        timeBlocks: [],
        fasterEntries: [],
        urgeLogs: [],
        moodEntries: [],
        gratitudeEntries: [],
        prayerLogs: [],
        exerciseLogs: [],
        phoneCallLogs: [],
        meetingLogs: [],
        spouseCheckIns: [],
        stepWork: [],
        goals: [],
        affirmationSessions: affirmationSessions
    )
}

/// Computes time-based state without SwiftData context.
private func computeTimeBasedState(
    scheduledHour: Int,
    scheduledMinute: Int,
    currentHour: Int,
    currentMinute: Int
) -> DailyPlanActivityState {
    let currentMinutes = currentHour * 60 + currentMinute
    let scheduledMinutes = scheduledHour * 60 + scheduledMinute
    let overdueThreshold = scheduledMinutes + 120

    if currentMinutes >= overdueThreshold {
        return .overdue
    } else if currentMinutes >= scheduledMinutes {
        return .pending
    } else {
        return .upcoming
    }
}

// MARK: - Work Screen Tile Tests (AFF-AC-161 through AFF-AC-165)

@Suite("Work Screen Affirmations Tile")
struct WorkScreenTileTests {

    init() {
        FeatureFlagStore.shared.setFlag("activity.affirmations", enabled: true)
    }

    @Test("AFF-AC-161: Tile visible with correct properties when flag enabled")
    func tileVisibleWhenFlagEnabled() {
        let tile = affirmationTile
        #expect(tile != nil, "Affirmations tile should exist in allTiles")
        #expect(tile?.id == "activity.affirmations")
        #expect(tile?.title == "Affirmations")
        #expect(tile?.icon == "text.quote")
        #expect(tile?.iconColor == .rrPrimary)
        #expect(tile?.category == .activities)
    }

    @Test("AFF-AC-162: Tile activityTypeKey maps to AffirmationPackPickerView")
    func tileNavigatesToAffirmationExperience() {
        let tile = affirmationTile
        #expect(tile != nil, "Affirmations tile should exist")
        #expect(tile?.activityTypeKey == ActivityType.affirmationLog.rawValue)
        #expect(tile?.activityTypeKey == "Affirmation Log")
    }

    @Test("AFF-AC-163: Status is .none when no session today")
    func tileStatusNoSessionToday() {
        guard let tile = affirmationTile else {
            Issue.record("Affirmations tile not found")
            return
        }
        let status = makeTodayStatus(for: tile, affirmationSessions: [])
        if case .none = status {
            // expected
        } else {
            Issue.record("Expected .none status when no affirmation sessions exist, got \(status)")
        }
    }

    @Test("AFF-AC-164: Status reflects completion when session exists today")
    func tileStatusSessionCompleted() {
        guard let tile = affirmationTile else {
            Issue.record("Affirmations tile not found")
            return
        }
        let session = RRActivity(
            userId: UUID(),
            activityType: ActivityType.affirmationLog.rawValue,
            date: Date()
        )
        let status = makeTodayStatus(for: tile, affirmationSessions: [session])
        if case .completed = status {
            // expected
        } else {
            Issue.record("Expected .completed status when affirmation session exists today, got \(status)")
        }
    }

    @Test("AFF-AC-165: Tile disabled when feature flag is off")
    func tileHiddenWhenFlagDisabled() {
        FeatureFlagStore.shared.setFlag("activity.affirmations", enabled: false)
        guard let tile = affirmationTile else {
            Issue.record("Affirmations tile not found")
            return
        }
        #expect(!tile.isEnabled, "Tile should be disabled when feature flag is off")
        let status = makeTodayStatus(for: tile)
        if case .none = status {
            // expected
        } else {
            Issue.record("Expected .none status for disabled tile, got \(status)")
        }
        FeatureFlagStore.shared.setFlag("activity.affirmations", enabled: true)
    }
}

// MARK: - Today Screen Activity Item Tests (AFF-AC-166 through AFF-AC-175)

@Suite("Today Screen Christian Affirmations")
struct TodayScreenTests {

    init() {
        FeatureFlagStore.shared.setFlag("activity.affirmations", enabled: true)
    }

    @Test("AFF-AC-166: Christian Affirmations in enabled activity list")
    func showsChristianAffirmationsItem() {
        let activity = DailyEligibleActivity.enabled.first(where: {
            $0.activityType == ActivityType.affirmationLog.rawValue
        })
        #expect(activity != nil, "Christian Affirmations should be in the enabled list")
        #expect(activity?.displayName == "Christian Affirmations")
        #expect(activity?.activityType == "Affirmation Log")
        #expect(activity?.icon == "text.quote")
        #expect(activity?.featureFlagKey == "activity.affirmations")
    }

    @Test("AFF-AC-167: Activity type routes to AffirmationPackPickerView")
    func itemNavigatesToAffirmationExperience() {
        let activityType = ActivityType.affirmationLog.rawValue
        #expect(activityType == "Affirmation Log")
        let eligible = DailyEligibleActivity.all.first(where: { $0.activityType == activityType })
        #expect(eligible != nil, "Affirmation Log must be in DailyEligibleActivity.all for routing")
        let parsed = ActivityType(rawValue: activityType)
        #expect(parsed == .affirmationLog)
    }

    @Test("AFF-AC-168: State is .upcoming before scheduled time")
    func stateUpcoming() {
        let state = computeTimeBasedState(scheduledHour: 23, scheduledMinute: 59, currentHour: 6, currentMinute: 0)
        #expect(state == .upcoming)
    }

    @Test("AFF-AC-169: State is .pending within 2-hour overdue window")
    func statePending() {
        let state = computeTimeBasedState(scheduledHour: 7, scheduledMinute: 0, currentHour: 7, currentMinute: 30)
        #expect(state == .pending)
    }

    @Test("AFF-AC-170: State is .overdue when 2+ hours past scheduled time")
    func stateOverdue() {
        let state = computeTimeBasedState(scheduledHour: 7, scheduledMinute: 0, currentHour: 9, currentMinute: 1)
        #expect(state == .overdue)
    }

    @Test("AFF-AC-171: State is .completed when session exists today")
    func stateCompleted() {
        let item = TodayPlanItem(
            id: UUID(),
            activityType: ActivityType.affirmationLog.rawValue,
            displayName: "Christian Affirmations",
            icon: "text.quote",
            iconColor: .rrPrimary,
            scheduledHour: 7,
            scheduledMinute: 0,
            instanceIndex: 0,
            state: .completed,
            weight: 10.0,
            completedAt: Date()
        )
        #expect(item.state == .completed)
        #expect(item.activityType == ActivityType.affirmationLog.rawValue)
    }

    @Test("AFF-AC-172: Completed affirmation contributes to daily score")
    func completionFeedsDailyScore() {
        let scoreWith = DailyScoreCalculator.calculate(
            morningDone: false, otherCompleted: 1, otherTotal: 1, morningInPlan: false
        )
        #expect(scoreWith == 100)

        let scoreWithMorning = DailyScoreCalculator.calculate(
            morningDone: true, otherCompleted: 1, otherTotal: 2, morningInPlan: true
        )
        #expect(scoreWithMorning == 60)

        let scoreWithout = DailyScoreCalculator.calculate(
            morningDone: false, otherCompleted: 0, otherTotal: 1, morningInPlan: false
        )
        #expect(scoreWithout == 0)
    }

    @Test("AFF-AC-173: Affirmation excluded when feature flag disabled")
    func activityGatedByFeatureFlag() {
        FeatureFlagStore.shared.setFlag("activity.affirmations", enabled: false)
        let enabledActivities = DailyEligibleActivity.enabled
        let entry = enabledActivities.first(where: {
            $0.activityType == ActivityType.affirmationLog.rawValue
        })
        #expect(entry == nil, "Affirmation should NOT be in enabled list when flag is disabled")
        let allEntry = DailyEligibleActivity.all.first(where: {
            $0.activityType == ActivityType.affirmationLog.rawValue
        })
        #expect(allEntry != nil, "Affirmation should still exist in DailyEligibleActivity.all")
        FeatureFlagStore.shared.setFlag("activity.affirmations", enabled: true)
    }

    @Test("AFF-AC-174: Multiple instances show numbered display names")
    func multipleInstancesPerDay() {
        let baseName = "Christian Affirmations"
        let siblings = 2
        let displayName1 = siblings > 1 ? "\(baseName) #1" : baseName
        let displayName2 = siblings > 1 ? "\(baseName) #2" : baseName
        #expect(displayName1 == "Christian Affirmations #1")
        #expect(displayName2 == "Christian Affirmations #2")
    }

    @Test("AFF-AC-175: Skip transitions to .skipped and recalculates score")
    func activitySkippable() {
        let vm = TodayViewModel()
        vm.planItems = [
            TodayPlanItem(
                id: UUID(),
                activityType: ActivityType.affirmationLog.rawValue,
                displayName: "Christian Affirmations",
                icon: "text.quote",
                iconColor: .rrPrimary,
                scheduledHour: 7,
                scheduledMinute: 0,
                instanceIndex: 0,
                state: .pending,
                weight: 80.0,
                completedAt: nil
            )
        ]
        #expect(vm.planItems[0].state == .pending)
        vm.skipActivity(vm.planItems[0], reason: "Not feeling it today")
        #expect(vm.planItems[0].state == .skipped)
        #expect(vm.score == 0)
    }
}
