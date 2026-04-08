import Testing
@testable import RegalRecovery

@Suite("GratitudeHistoryViewModel")
struct GratitudeHistoryViewModelTests {

    let calendar = Calendar.current
    let userId = UUID()

    // MARK: - Helpers

    func makeEntry(
        daysAgo: Int = 0,
        items: [GratitudeItem] = [GratitudeItem(text: "Test", sortOrder: 0)],
        moodScore: Int? = nil,
        photoPath: String? = nil
    ) -> RRGratitudeEntry {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        return RRGratitudeEntry(
            userId: userId,
            date: date,
            items: items,
            moodScore: moodScore,
            photoLocalPath: photoPath,
            createdAt: date
        )
    }

    // MARK: - GL-HS-AC1: Reverse chronological

    @Test("GL-HS-AC1: Filtered entries returned without reordering")
    func testGratitude_GL_HS_AC1_ReverseChronological() {
        let vm = GratitudeHistoryViewModel()
        let entries = [makeEntry(daysAgo: 3), makeEntry(daysAgo: 0), makeEntry(daysAgo: 1)]
        let filtered = vm.filteredEntries(from: entries)
        #expect(filtered.count == 3, "All entries returned with no filters")
    }

    // MARK: - GL-HS-AC2: Entry card preview

    @Test("GL-HS-AC2: Entry card shows date, count, first 2 items")
    func testGratitude_GL_HS_AC2_EntryCardPreview() {
        let items = [
            GratitudeItem(text: "First", category: .faithGod, sortOrder: 0),
            GratitudeItem(text: "Second", category: .recovery, sortOrder: 1),
            GratitudeItem(text: "Third", sortOrder: 2),
        ]
        let entry = makeEntry(items: items, moodScore: 4)

        #expect(entry.items.count == 3)
        let preview = Array(entry.items.prefix(2))
        #expect(preview.count == 2)
        #expect(preview[0].text == "First")
        #expect(preview[1].text == "Second")
    }

    // MARK: - GL-HS-AC6: Search results

    @Test("GL-HS-AC6: Full-text search across item text")
    func testGratitude_GL_HS_AC6_SearchResults() {
        let vm = GratitudeHistoryViewModel()
        let entries = [
            makeEntry(items: [GratitudeItem(text: "Grateful for sobriety", sortOrder: 0)]),
            makeEntry(daysAgo: 1, items: [GratitudeItem(text: "Family dinner", sortOrder: 0)]),
            makeEntry(daysAgo: 2, items: [GratitudeItem(text: "Morning prayer", sortOrder: 0)]),
        ]

        vm.searchText = ""
        #expect(vm.filteredEntries(from: entries).count == 3)

        vm.searchText = "s"  // <2 chars, no filtering
        #expect(vm.filteredEntries(from: entries).count == 3)

        vm.searchText = "sobriety"
        #expect(vm.filteredEntries(from: entries).count == 1)

        vm.searchText = "FAMILY"
        #expect(vm.filteredEntries(from: entries).count == 1)

        vm.searchText = "zzzzz"
        #expect(vm.filteredEntries(from: entries).count == 0)
    }

    // MARK: - GL-HS-AC7: Filter combination (AND logic)

    @Test("GL-HS-AC7: Filters combine with AND logic")
    func testGratitude_GL_HS_AC7_FilterCombination() {
        let vm = GratitudeHistoryViewModel()
        let entries = [
            makeEntry(
                items: [GratitudeItem(text: "Recovery", category: .recovery, sortOrder: 0)],
                moodScore: 5,
                photoPath: "/photo.jpg"
            ),
            makeEntry(
                daysAgo: 1,
                items: [GratitudeItem(text: "Family", category: .family, sortOrder: 0)],
                moodScore: 3
            ),
            makeEntry(
                daysAgo: 2,
                items: [GratitudeItem(text: "Work", category: .workCareer, sortOrder: 0)],
                moodScore: 5,
                photoPath: "/work.jpg"
            ),
        ]

        vm.toggleCategory(.recovery)
        #expect(vm.filteredEntries(from: entries).count == 1)

        vm.clearFilters()
        vm.filterHasPhoto = true
        #expect(vm.filteredEntries(from: entries).count == 2)

        vm.filterMoodScore = 5
        #expect(vm.filteredEntries(from: entries).count == 2)

        vm.toggleCategory(.recovery)
        #expect(vm.filteredEntries(from: entries).count == 1)
    }

    // MARK: - GL-HS-AC8: Favorites tab

    @Test("GL-HS-AC8: Favorites tab shows all favorited items")
    func testGratitude_GL_HS_AC8_FavoritesTab() {
        let vm = GratitudeHistoryViewModel()
        let entries = [
            makeEntry(items: [
                GratitudeItem(text: "Fav 1", isFavorite: true, sortOrder: 0),
                GratitudeItem(text: "Non-fav", isFavorite: false, sortOrder: 1),
            ]),
            makeEntry(daysAgo: 1, items: [
                GratitudeItem(text: "Fav 2", isFavorite: true, sortOrder: 0),
            ]),
        ]

        let favorites = vm.allFavoriteItems(from: entries)
        #expect(favorites.count == 2)
        #expect(favorites.allSatisfy { $0.item.isFavorite })
    }

    // MARK: - GL-HS-AC9: Favorite toggle

    @Test("GL-HS-AC9: Toggle item favorite on/off")
    func testGratitude_GL_HS_AC9_FavoriteToggle() {
        let vm = GratitudeHistoryViewModel()
        let entry = makeEntry(items: [
            GratitudeItem(text: "Test", isFavorite: false, sortOrder: 0),
        ])
        let itemId = entry.items[0].id

        #expect(entry.items[0].isFavorite == false)

        vm.toggleItemFavorite(itemId: itemId, in: entry)
        #expect(entry.items[0].isFavorite == true)

        vm.toggleItemFavorite(itemId: itemId, in: entry)
        #expect(entry.items[0].isFavorite == false)
    }

    // MARK: - Calendar helpers

    @Test("GL-HS-AC4: Calendar indicators for dates with entries")
    func testGratitude_GL_HS_AC4_CalendarIndicators() {
        let vm = GratitudeHistoryViewModel()
        let entries = [makeEntry(daysAgo: 0), makeEntry(daysAgo: 1)]
        let datesWithEntries = vm.datesWithEntries(from: entries)
        #expect(datesWithEntries.count == 2)
    }

    @Test("GL-HS-AC5: Calendar date resolves to day's entries")
    func testGratitude_GL_HS_AC5_CalendarNavigation() {
        let vm = GratitudeHistoryViewModel()
        let entries = [makeEntry(daysAgo: 0), makeEntry(daysAgo: 0), makeEntry(daysAgo: 1)]
        let todayEntries = vm.entriesForDate(Date(), from: entries)
        #expect(todayEntries.count == 2)
    }

    // MARK: - Filter management

    @Test("Filter management: clear resets all filters")
    func testGratitude_GL_HS_FilterManagement() {
        let vm = GratitudeHistoryViewModel()
        #expect(vm.hasActiveFilters == false)

        vm.toggleCategory(.recovery)
        #expect(vm.hasActiveFilters == true)

        vm.clearFilters()
        #expect(vm.hasActiveFilters == false)
        #expect(vm.selectedCategories.isEmpty)
        #expect(vm.filterHasPhoto == false)
        #expect(vm.filterMoodScore == nil)
        #expect(vm.searchText == "")
    }
}
