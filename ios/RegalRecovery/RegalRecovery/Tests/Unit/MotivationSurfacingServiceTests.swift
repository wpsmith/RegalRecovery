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
