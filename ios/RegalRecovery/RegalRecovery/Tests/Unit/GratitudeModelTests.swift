import Testing
@testable import RegalRecovery

@Suite("GratitudeModel")
struct GratitudeModelTests {

    // MARK: - GL-DM-AC1: Item text max length (300 characters)

    @Test("GL-DM-AC1: Item text respects 300 character max")
    func testGratitude_GL_DM_AC1_ItemTextMaxLength() {
        let shortText = String(repeating: "a", count: 300)
        let item = GratitudeItem(text: shortText, sortOrder: 0)
        #expect(item.text.count == 300)

        // ViewModel enforces the limit via clamp
        let vm = GratitudeEntryViewModel()
        var text = String(repeating: "b", count: 350)
        vm.clampText(&text)
        #expect(text.count == 300, "clampText should truncate to 300 characters")
    }

    // MARK: - GL-DM-AC2: Category tag options

    @Test("GL-DM-AC2: All category tags available")
    func testGratitude_GL_DM_AC2_CategoryTagOptions() {
        let expectedCategories: [GratitudeCategory] = [
            .faithGod, .family, .relationships, .health, .recovery,
            .workCareer, .natureBeauty, .smallMoments, .growthProgress, .custom
        ]

        #expect(GratitudeCategory.allCases.count == expectedCategories.count,
                "Should have exactly 10 categories")

        for expected in expectedCategories {
            #expect(GratitudeCategory.allCases.contains(expected),
                    "Missing category: \(expected.rawValue)")
        }

        // Optional category
        let itemWithCategory = GratitudeItem(text: "test", category: .faithGod, sortOrder: 0)
        #expect(itemWithCategory.category == .faithGod)

        let itemWithout = GratitudeItem(text: "test", sortOrder: 0)
        #expect(itemWithout.category == nil)
    }

    // MARK: - GL-DM-AC3: Mood score range 1-5

    @Test("GL-DM-AC3: Mood score supports 1-5 and nil")
    func testGratitude_GL_DM_AC3_MoodScoreRange() {
        for score in 1...5 {
            let entry = RRGratitudeEntry(
                userId: UUID(),
                date: Date(),
                items: [GratitudeItem(text: "test", sortOrder: 0)],
                moodScore: score
            )
            #expect(entry.moodScore == score, "Mood score \(score) should be accepted")
        }

        let noMood = RRGratitudeEntry(
            userId: UUID(),
            date: Date(),
            items: [GratitudeItem(text: "test", sortOrder: 0)]
        )
        #expect(noMood.moodScore == nil, "nil mood should be accepted")
    }

    // MARK: - GL-DM-AC5: Item ordering

    @Test("GL-DM-AC5: Items ordered by sortOrder")
    func testGratitude_GL_DM_AC5_ItemOrdering() {
        let items = [
            GratitudeItem(text: "Third", sortOrder: 2),
            GratitudeItem(text: "First", sortOrder: 0),
            GratitudeItem(text: "Second", sortOrder: 1),
        ]

        let sorted = items.sorted { $0.sortOrder < $1.sortOrder }
        #expect(sorted[0].text == "First")
        #expect(sorted[1].text == "Second")
        #expect(sorted[2].text == "Third")
    }

    // MARK: - GL-DM-AC6: Individual item favoriting

    @Test("GL-DM-AC6: Items favorited independently")
    func testGratitude_GL_DM_AC6_ItemFavoriting() {
        var item = GratitudeItem(text: "test item", sortOrder: 0)
        #expect(item.isFavorite == false, "Default isFavorite should be false")

        item.isFavorite = true
        #expect(item.isFavorite == true)

        let entry = RRGratitudeEntry(
            userId: UUID(),
            date: Date(),
            items: [
                GratitudeItem(text: "fav item", isFavorite: true, sortOrder: 0),
                GratitudeItem(text: "non-fav item", isFavorite: false, sortOrder: 1),
            ],
            isFavorite: false
        )
        #expect(entry.isFavorite == false, "Entry-level favorite independent of item favorites")
        #expect(entry.items[0].isFavorite == true)
        #expect(entry.items[1].isFavorite == false)
    }

    // MARK: - GL-DM-AC7: Editable within 24 hours

    @Test("GL-DM-AC7: Entry editable within 24h")
    func testGratitude_GL_DM_AC7_EditWindow() {
        let recentEntry = RRGratitudeEntry(
            userId: UUID(),
            date: Date(),
            items: [GratitudeItem(text: "test", sortOrder: 0)],
            createdAt: Date()
        )
        #expect(recentEntry.isEditable == true, "Entry created now should be editable")

        let almostExpired = RRGratitudeEntry(
            userId: UUID(),
            date: Date(),
            items: [GratitudeItem(text: "test", sortOrder: 0)],
            createdAt: Date().addingTimeInterval(-23 * 3600)
        )
        #expect(almostExpired.isEditable == true, "Entry created 23h ago should still be editable")
    }

    // MARK: - GL-DM-AC8: Read-only after 24h

    @Test("GL-DM-AC8: Entry read-only after 24h")
    func testGratitude_GL_DM_AC8_ReadOnlyAfter24h() {
        let oldEntry = RRGratitudeEntry(
            userId: UUID(),
            date: Date().addingTimeInterval(-25 * 3600),
            items: [GratitudeItem(text: "old", sortOrder: 0)],
            createdAt: Date().addingTimeInterval(-25 * 3600)
        )
        #expect(oldEntry.isEditable == false, "Entry created 25h ago should NOT be editable")
    }

    // MARK: - GL-DM-AC9: Multiple entries per day

    @Test("GL-DM-AC9: Multiple entries per day saved independently")
    func testGratitude_GL_DM_AC9_MultiplePerDay() {
        let userId = UUID()
        let today = Date()

        let entry1 = RRGratitudeEntry(
            userId: userId,
            date: today,
            items: [GratitudeItem(text: "Morning", sortOrder: 0)]
        )
        let entry2 = RRGratitudeEntry(
            userId: userId,
            date: today.addingTimeInterval(3600),
            items: [GratitudeItem(text: "Evening", sortOrder: 0)]
        )

        #expect(entry1.id != entry2.id, "Multiple entries should have different IDs")
        #expect(Calendar.current.isDate(entry1.date, inSameDayAs: entry2.date),
                "Both entries should be on the same calendar day")
    }

    // MARK: - GL-DM-AC10: Legacy migration

    @Test("GL-DM-AC10: Legacy [String] items migrate to [GratitudeItem]")
    func testGratitude_GL_DM_AC10_LegacyMigration() {
        let legacyItems = ["Morning prayer", "Family breakfast", "Sponsor call"]
        let migratedItems: [GratitudeItem] = legacyItems.enumerated().map { index, text in
            GratitudeItem(text: text, sortOrder: index)
        }

        #expect(migratedItems.count == 3, "Migration should preserve item count")
        for (index, item) in migratedItems.enumerated() {
            #expect(item.text == legacyItems[index], "Text should be preserved")
            #expect(item.sortOrder == index, "Sort order should match index")
            #expect(item.category == nil, "Category should be nil for migrated items")
            #expect(item.isFavorite == false, "Favorite should default to false")
        }
    }

    // MARK: - GratitudeItem Codable

    @Test("GratitudeItem encodes and decodes correctly")
    func testGratitude_GL_DM_ItemCodable() throws {
        let item = GratitudeItem(
            text: "Test item",
            category: .recovery,
            isFavorite: true,
            sortOrder: 3
        )

        let data = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(GratitudeItem.self, from: data)

        #expect(decoded.text == item.text)
        #expect(decoded.category == item.category)
        #expect(decoded.isFavorite == item.isFavorite)
        #expect(decoded.sortOrder == item.sortOrder)
    }
}
