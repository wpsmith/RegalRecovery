import Testing
@testable import RegalRecovery

@Suite("GratitudeSharingService")
struct GratitudeSharingTests {

    let userId = UUID()

    func makeEntry(
        items: [GratitudeItem],
        moodScore: Int? = 4,
        photoPath: String? = "/photo.jpg"
    ) -> RRGratitudeEntry {
        RRGratitudeEntry(
            userId: userId,
            date: Date(),
            items: items,
            moodScore: moodScore,
            photoLocalPath: photoPath
        )
    }

    // MARK: - GL-SH-AC1: Individual item shareable

    @Test("GL-SH-AC1: Individual item shares text only")
    func testGratitude_GL_SH_AC1_ShareItem() {
        let item = GratitudeItem(text: "Grateful for sobriety", category: .recovery, sortOrder: 0)
        let shared = GratitudeSharingService.shareText(for: item)
        #expect(shared == "Grateful for sobriety")
    }

    // MARK: - GL-SH-AC2: Full entry shareable

    @Test("GL-SH-AC2: Full entry shared as numbered list")
    func testGratitude_GL_SH_AC2_ShareEntry() {
        let items = [
            GratitudeItem(text: "Morning prayer", category: .faithGod, sortOrder: 0),
            GratitudeItem(text: "Family dinner", category: .family, sortOrder: 1),
            GratitudeItem(text: "Beautiful sunset", category: .natureBeauty, sortOrder: 2),
        ]
        let entry = makeEntry(items: items)
        let shared = GratitudeSharingService.shareText(for: entry)

        #expect(shared.contains("1. Morning prayer"))
        #expect(shared.contains("2. Family dinner"))
        #expect(shared.contains("3. Beautiful sunset"))
        #expect(shared.contains("Gratitude"))
    }

    // MARK: - GL-SH-AC3: Privacy filter

    @Test("GL-SH-AC3: Shared content excludes mood, category, photo")
    func testGratitude_GL_SH_AC3_PrivacyFilter() {
        let items = [
            GratitudeItem(text: "Test item", category: .recovery, isFavorite: true, sortOrder: 0),
        ]
        let entry = makeEntry(items: items, moodScore: 5, photoPath: "/secret/photo.jpg")
        let sharedText = GratitudeSharingService.shareText(for: entry)

        // Must NOT contain mood, category, or photo info
        #expect(!sharedText.contains("5"), "Should not contain mood score")
        #expect(!sharedText.lowercased().contains("recovery"), "Should not contain category")
        #expect(!sharedText.contains("photo"), "Should not contain photo path")
        #expect(!sharedText.contains("favorite"), "Should not contain favorite status")

        // Individual item share also excludes metadata
        let itemShare = GratitudeSharingService.shareText(for: items[0])
        #expect(itemShare == "Test item")
    }

    // MARK: - GL-SH-AC4: Clipboard text format

    @Test("GL-SH-AC4: Clipboard text has numbered items")
    func testGratitude_GL_SH_AC4_Clipboard() {
        let items = [
            GratitudeItem(text: "Item one", sortOrder: 0),
            GratitudeItem(text: "Item two", sortOrder: 1),
        ]
        let entry = makeEntry(items: items)
        let text = GratitudeSharingService.shareText(for: entry)

        let lines = text.components(separatedBy: "\n").filter { !$0.isEmpty }
        #expect(lines.contains("1. Item one"))
        #expect(lines.contains("2. Item two"))
    }

    // MARK: - GL-SH-AC5: Styled graphic

    @Test("GL-SH-AC5: Styled graphic renders with correct dimensions")
    func testGratitude_GL_SH_AC5_StyledGraphic() {
        let image = GratitudeSharingService.styledImage(
            text: "Grateful for sobriety",
            date: Date(),
            scripture: "Psalm 100:4"
        )
        #expect(image.size.width > 0)
        #expect(image.size.height > 0)
        #expect(image.size.width == 600, "Card width should be 600")
    }

    @Test("GL-SH-AC5: Styled graphic renders without scripture")
    func testGratitude_GL_SH_AC5_StyledGraphic_NoScripture() {
        let image = GratitudeSharingService.styledImage(
            text: "Grateful for today",
            date: Date(),
            scripture: nil
        )
        #expect(image.size.width > 0)
    }

    // MARK: - Item ordering in shared text

    @Test("Shared text orders items by sortOrder")
    func testGratitude_GL_SH_ItemOrdering() {
        let items = [
            GratitudeItem(text: "Third", sortOrder: 2),
            GratitudeItem(text: "First", sortOrder: 0),
            GratitudeItem(text: "Second", sortOrder: 1),
        ]
        let entry = makeEntry(items: items)
        let shared = GratitudeSharingService.shareText(for: entry)

        let itemLines = shared.components(separatedBy: "\n").filter { $0.first?.isNumber == true }
        #expect(itemLines.count == 3)
        #expect(itemLines[0].contains("First"))
        #expect(itemLines[1].contains("Second"))
        #expect(itemLines[2].contains("Third"))
    }
}
