import Testing
@testable import RegalRecovery

@Suite("AffirmationsViewModel")
struct AffirmationsViewModelTests {

    @Test("getTodaysAffirmation returns a non-nil affirmation")
    func testGetTodaysAffirmation_ReturnsNonNil() async {
        let vm = AffirmationsViewModel()
        await vm.load()

        let affirmation = vm.getTodaysAffirmation()
        #expect(!affirmation.text.isEmpty)
    }

    @Test("weighted rotation produces varied results over many calls")
    func testWeightedRotation_ProducesVariedResults() async {
        let vm = AffirmationsViewModel()
        await vm.load()

        var uniqueTexts = Set<String>()
        let iterations = 200

        for _ in 0..<iterations {
            let affirmation = vm.getTodaysAffirmation()
            uniqueTexts.insert(affirmation.text)
        }

        // Over 200 draws we should see more than a handful of unique affirmations
        #expect(uniqueTexts.count > 5, "Should produce varied results, got only \(uniqueTexts.count) unique affirmations")
    }
}
