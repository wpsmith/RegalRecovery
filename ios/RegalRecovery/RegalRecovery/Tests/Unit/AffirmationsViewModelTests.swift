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

    @Test("toggleFavorite adds an affirmation to favorites")
    func testToggleFavorite_AddsToFavorites() async throws {
        let vm = AffirmationsViewModel()
        await vm.load()

        let newAffirmation = Affirmation(
            text: "Test affirmation",
            scripture: "Test 1:1",
            isFavorite: false
        )

        let countBefore = vm.favorites.count
        try await vm.toggleFavorite(newAffirmation)
        #expect(vm.favorites.count == countBefore + 1)
        #expect(vm.favorites.contains(where: { $0.id == newAffirmation.id }))
    }

    @Test("toggleFavorite removes an affirmation from favorites")
    func testToggleFavorite_RemovesFromFavorites() async throws {
        let vm = AffirmationsViewModel()
        await vm.load()

        guard let existing = vm.favorites.first else {
            Issue.record("No favorites loaded to test removal")
            return
        }

        let countBefore = vm.favorites.count
        try await vm.toggleFavorite(existing)
        #expect(vm.favorites.count == countBefore - 1)
        #expect(!vm.favorites.contains(where: { $0.id == existing.id }))
    }

    @Test("weighted rotation produces varied results over many calls")
    func testWeightedRotation_FavoritesAppearMore() async {
        let vm = AffirmationsViewModel()
        await vm.load()

        var favoriteCount = 0
        let iterations = 200

        let favoriteIDs = Set(vm.favorites.map(\.id))

        for _ in 0..<iterations {
            let affirmation = vm.getTodaysAffirmation()
            if favoriteIDs.contains(affirmation.id) {
                favoriteCount += 1
            }
        }

        // Favorites should appear at a meaningful rate (at least 5% given the 30% bucket
        // can fire and there are also random/under-served paths that might pick one).
        // This is a statistical test — we use a low threshold to avoid flakiness.
        let favoriteRate = Double(favoriteCount) / Double(iterations)
        #expect(favoriteRate > 0.05, "Favorites should appear in at least 5% of draws, got \(favoriteRate)")
    }
}
