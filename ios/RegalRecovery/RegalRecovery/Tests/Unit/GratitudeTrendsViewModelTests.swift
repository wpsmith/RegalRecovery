import Testing
@testable import RegalRecovery

@Suite("GratitudeTrendsViewModel")
struct GratitudeTrendsViewModelTests {

    let calendar = Calendar.current
    let userId = UUID()

    // MARK: - Helpers

    func makeEntry(
        daysAgo: Int,
        items: [GratitudeItem] = [GratitudeItem(text: "Test", sortOrder: 0)]
    ) -> RRGratitudeEntry {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
        return RRGratitudeEntry(userId: userId, date: date, items: items, createdAt: date)
    }

    // MARK: - GL-TI-AC1: Current streak

    @Test("GL-TI-AC1: Current streak counts consecutive days")
    func testGratitude_GL_TI_AC1_CurrentStreak() {
        let vm = GratitudeTrendsViewModel()
        let entries = [makeEntry(daysAgo: 0), makeEntry(daysAgo: 1), makeEntry(daysAgo: 2)]
        let streak = vm.streakData(from: entries)
        #expect(streak.currentStreak == 3)
    }

    @Test("GL-TI-AC1: Gap breaks current streak")
    func testGratitude_GL_TI_AC1_CurrentStreak_Broken() {
        let vm = GratitudeTrendsViewModel()
        let entries = [makeEntry(daysAgo: 0), makeEntry(daysAgo: 2)]
        let streak = vm.streakData(from: entries)
        #expect(streak.currentStreak == 1)
    }

    @Test("GL-TI-AC1: No entries means 0 streak")
    func testGratitude_GL_TI_AC1_CurrentStreak_None() {
        let vm = GratitudeTrendsViewModel()
        let streak = vm.streakData(from: [])
        #expect(streak.currentStreak == 0)
    }

    @Test("GL-TI-AC1: Stale entries (>1 day ago) mean 0 current streak")
    func testGratitude_GL_TI_AC1_CurrentStreak_NotRecent() {
        let vm = GratitudeTrendsViewModel()
        let entries = [makeEntry(daysAgo: 3), makeEntry(daysAgo: 4)]
        let streak = vm.streakData(from: entries)
        #expect(streak.currentStreak == 0)
    }

    // MARK: - GL-TI-AC2: Longest streak

    @Test("GL-TI-AC2: Longest streak tracks all-time best")
    func testGratitude_GL_TI_AC2_LongestStreak() {
        let vm = GratitudeTrendsViewModel()
        // 6-day current streak (0-5), 3-day historical streak (8-10)
        let entries = [
            makeEntry(daysAgo: 0), makeEntry(daysAgo: 1), makeEntry(daysAgo: 2),
            makeEntry(daysAgo: 3), makeEntry(daysAgo: 4), makeEntry(daysAgo: 5),
            makeEntry(daysAgo: 8), makeEntry(daysAgo: 9), makeEntry(daysAgo: 10),
        ]
        let streak = vm.streakData(from: entries)
        #expect(streak.longestStreak == 6)
        #expect(streak.currentStreak == 6)
    }

    @Test("GL-TI-AC2: Historical streak can exceed current")
    func testGratitude_GL_TI_AC2_LongestStreak_Historical() {
        let vm = GratitudeTrendsViewModel()
        let entries = [
            makeEntry(daysAgo: 0), makeEntry(daysAgo: 1),
            makeEntry(daysAgo: 15), makeEntry(daysAgo: 16), makeEntry(daysAgo: 17),
            makeEntry(daysAgo: 18), makeEntry(daysAgo: 19), makeEntry(daysAgo: 20),
        ]
        let streak = vm.streakData(from: entries)
        #expect(streak.currentStreak == 2)
        #expect(streak.longestStreak == 6)
    }

    // MARK: - GL-TI-AC3: Total days

    @Test("GL-TI-AC3: Total days counts unique calendar days")
    func testGratitude_GL_TI_AC3_TotalDays() {
        let vm = GratitudeTrendsViewModel()
        let entries = [
            makeEntry(daysAgo: 0), makeEntry(daysAgo: 2),
            makeEntry(daysAgo: 5), makeEntry(daysAgo: 10),
        ]
        let streak = vm.streakData(from: entries)
        #expect(streak.totalDaysWithEntries == 4)
    }

    // MARK: - GL-TI-AC4: Multiple entries same day count as 1

    @Test("GL-TI-AC4: Multiple entries on same day = 1 streak day")
    func testGratitude_GL_TI_AC4_MultipleEntriesSameDay() {
        let vm = GratitudeTrendsViewModel()
        let today = calendar.startOfDay(for: Date())
        let entry1 = RRGratitudeEntry(userId: userId, date: today, items: [GratitudeItem(text: "Morning", sortOrder: 0)], createdAt: today)
        let entry2 = RRGratitudeEntry(userId: userId, date: today.addingTimeInterval(3600), items: [GratitudeItem(text: "Evening", sortOrder: 0)], createdAt: today.addingTimeInterval(3600))

        let streak = vm.streakData(from: [entry1, entry2])
        #expect(streak.totalDaysWithEntries == 1)
        #expect(streak.currentStreak == 1)
    }

    // MARK: - GL-TI-AC5: Category breakdown

    @Test("GL-TI-AC5: Category breakdown shows distribution percentages")
    func testGratitude_GL_TI_AC5_CategoryBreakdown() {
        let vm = GratitudeTrendsViewModel()
        let entries = [
            makeEntry(daysAgo: 0, items: [
                GratitudeItem(text: "A", category: .faithGod, sortOrder: 0),
                GratitudeItem(text: "B", category: .faithGod, sortOrder: 1),
                GratitudeItem(text: "C", category: .recovery, sortOrder: 2),
            ]),
            makeEntry(daysAgo: 1, items: [
                GratitudeItem(text: "D", category: .family, sortOrder: 0),
                GratitudeItem(text: "E", sortOrder: 1), // no category
            ]),
        ]

        let breakdown = vm.categoryBreakdown(from: entries, period: .allTime)
        #expect(!breakdown.isEmpty)

        let faithItem = breakdown.first { $0.category == .faithGod }
        #expect(faithItem?.count == 2)

        let total = breakdown.reduce(0) { $0 + $1.count }
        #expect(total == 4, "Excludes nil-category items")

        let totalPercent = breakdown.reduce(0.0) { $0 + $1.percentage }
        #expect(abs(totalPercent - 100.0) < 0.1)
    }

    // MARK: - GL-TI-AC7: Average items per entry

    @Test("GL-TI-AC7: Average items per entry computed correctly")
    func testGratitude_GL_TI_AC7_AvgItemsPerEntry() {
        let vm = GratitudeTrendsViewModel()
        let entries = [
            makeEntry(daysAgo: 0, items: [
                GratitudeItem(text: "A", sortOrder: 0),
                GratitudeItem(text: "B", sortOrder: 1),
                GratitudeItem(text: "C", sortOrder: 2),
            ]),
            makeEntry(daysAgo: 1, items: [
                GratitudeItem(text: "D", sortOrder: 0),
            ]),
        ]

        let avg = vm.averageItemsPerEntry(from: entries)
        #expect(abs(avg - 2.0) < 0.01)
    }

    @Test("GL-TI-AC7: Empty entries returns 0 average")
    func testGratitude_GL_TI_AC7_AvgItemsPerEntry_Empty() {
        let vm = GratitudeTrendsViewModel()
        #expect(vm.averageItemsPerEntry(from: []) == 0.0)
    }

    // MARK: - GL-TI-AC10: Evening review excluded

    @Test("GL-TI-AC10: Only RRGratitudeEntry objects count toward streak")
    func testGratitude_GL_TI_AC10_EveningReviewExcluded() {
        let vm = GratitudeTrendsViewModel()
        let entries = [makeEntry(daysAgo: 0), makeEntry(daysAgo: 1)]
        let streak = vm.streakData(from: entries)
        #expect(streak.currentStreak == 2)
        // Evening review data lives in RRCommitment, not RRGratitudeEntry,
        // so it never appears in the entries array.
    }

    // MARK: - Weekly entry data

    @Test("Weekly entry data returns 8 weeks")
    func testGratitude_GL_TI_WeeklyEntryData() {
        let vm = GratitudeTrendsViewModel()
        let entries = [makeEntry(daysAgo: 0), makeEntry(daysAgo: 1), makeEntry(daysAgo: 2)]
        let weeklyData = vm.weeklyEntryData(from: entries)
        #expect(weeklyData.count == 8)
    }

    // MARK: - Period filtering

    @Test("TrendPeriod days correct")
    func testGratitude_GL_TI_PeriodFiltering() {
        #expect(TrendPeriod.thirtyDay.days == 30)
        #expect(TrendPeriod.ninetyDay.days == 90)
        #expect(TrendPeriod.allTime.days == nil)
    }

    // MARK: - Correlation insufficient data

    @Test("GL-TI-AC8: Check-in correlation requires 14+ days")
    func testGratitude_GL_TI_AC8_CheckInCorrelation_InsufficientData() {
        let vm = GratitudeTrendsViewModel()
        let insight = vm.checkInCorrelation(entries: [makeEntry(daysAgo: 0)], checkIns: [])
        #expect(insight == nil)
    }

    @Test("Urge correlation requires sufficient data")
    func testGratitude_GL_TI_UrgeCorrelation_InsufficientData() {
        let vm = GratitudeTrendsViewModel()
        let insight = vm.urgeCorrelation(entries: [makeEntry(daysAgo: 0)], urgeLogs: [])
        #expect(insight == nil)
    }
}
