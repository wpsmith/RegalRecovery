import Testing
@testable import RegalRecovery

// MARK: - Prayer ViewModel Tests

/// TestPrayerScreen_StreakDisplay_ShowsCurrentStreak verifies streak display.
@Test func prayerScreen_StreakDisplay() async throws {
    let vm = PrayerViewModel()
    await vm.load()

    // Mock data provides a 4-day streak.
    #expect(vm.stats.currentStreakDays == 4)
}

/// TestPrayerScreen_QuickLogButton_CreatesSession verifies quick log.
/// PR-AC1.11: Quick log creates session with type=personal.
@Test func prayerScreen_QuickLogButton_CreatesSession() async throws {
    let vm = PrayerViewModel()
    let initialCount = vm.history.count

    try await vm.quickLog()

    #expect(vm.history.count == initialCount + 1)
    #expect(vm.history.first?.prayerType == .personal)
    #expect(vm.history.first?.durationMinutes == nil)
}

/// TestPrayerTypeMapping verifies all 6 prayer types are represented.
@Test func prayerTypeMapping_AllTypesPresent() {
    let allTypes = PrayerType.allCases
    #expect(allTypes.count == 6)
    #expect(allTypes.contains(.personal))
    #expect(allTypes.contains(.guided))
    #expect(allTypes.contains(.group))
    #expect(allTypes.contains(.scriptureBased))
    #expect(allTypes.contains(.intercessory))
    #expect(allTypes.contains(.listening))
}

/// TestPrayerCompassionMessage verifies streak break compassion (PR-AC5.4).
@Test func prayerCompassionMessage_ShowsOnStreakBreak() async {
    let vm = PrayerViewModel()

    // Simulate broken streak.
    vm.stats = PrayerStatsLocal(
        currentStreakDays: 0,
        longestStreakDays: 14,
        totalPrayerDays: 50,
        sessionsThisWeek: 0
    )

    #expect(vm.hasStreakBreak == true)
}

/// TestPrayerEntry_MoodRange verifies mood values are within 1-5 range.
@Test func prayerEntry_MoodRange() {
    let entry = PrayerEntry(moodBefore: 1, moodAfter: 5)
    #expect(entry.moodBefore == 1)
    #expect(entry.moodAfter == 5)
}

/// TestPrayerType_DisplayNames verifies display names are user-friendly.
@Test func prayerType_DisplayNames() {
    #expect(PrayerType.personal.displayName == "Personal")
    #expect(PrayerType.guided.displayName == "Guided")
    #expect(PrayerType.group.displayName == "Group")
    #expect(PrayerType.scriptureBased.displayName == "Scripture-Based")
    #expect(PrayerType.intercessory.displayName == "Intercessory")
    #expect(PrayerType.listening.displayName == "Listening")
}

/// TestPrayerType_Icons verifies each type has an SF Symbol icon.
@Test func prayerType_Icons() {
    for type in PrayerType.allCases {
        #expect(!type.icon.isEmpty, "Prayer type \(type.rawValue) should have an icon")
    }
}
