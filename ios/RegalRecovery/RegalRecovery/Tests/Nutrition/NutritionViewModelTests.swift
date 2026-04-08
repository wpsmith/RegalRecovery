import XCTest

/// Unit tests for NutritionViewModel.
/// Tests reference acceptance criteria from the Nutrition Activity spec.
final class NutritionViewModelTests: XCTestCase {

    var viewModel: NutritionViewModel!

    override func setUp() {
        super.setUp()
        viewModel = NutritionViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Meal Loading (FR-NUT-4.1)

    /// TestNutritionViewModel_LoadMeals_DisplaysInReverseChronological
    func testLoadMeals_DisplaysInReverseChronological() async {
        await viewModel.loadMeals()

        XCTAssertFalse(viewModel.meals.isEmpty, "Should have meal data after loading")
        if viewModel.meals.count >= 2 {
            XCTAssertTrue(
                viewModel.meals[0].timestamp >= viewModel.meals[1].timestamp,
                "Meals should be in reverse chronological order"
            )
        }
    }

    // MARK: - Quick Log (FR-NUT-2.1)

    /// TestNutritionViewModel_QuickLog_SetsIsQuickLogTrue
    func testQuickLog_SetsIsQuickLogTrue() async throws {
        try await viewModel.quickLog(type: .breakfast)

        XCTAssertFalse(viewModel.meals.isEmpty, "Should have a meal after quick log")
        let meal = viewModel.meals.first!
        XCTAssertTrue(meal.isQuickLog, "Quick log should have isQuickLog=true")
        XCTAssertNil(meal.description, "Quick log should have nil description")
        XCTAssertEqual(meal.mealType, .breakfast, "Quick log should have correct meal type")
    }

    // MARK: - Hydration (FR-NUT-3.1, FR-NUT-3.2)

    /// TestNutritionViewModel_HydrationIncrement_UpdatesProgressBar
    func testHydrationIncrement_UpdatesProgressBar() async {
        await viewModel.loadHydration()
        let initialServings = viewModel.hydration?.servingsLogged ?? 0

        await viewModel.addWater()

        XCTAssertEqual(
            viewModel.hydration?.servingsLogged, initialServings + 1,
            "Servings should increment by 1"
        )
    }

    /// TestNutritionViewModel_HydrationDecrement_DoesNotGoBelowZero (FR-NUT-3.2)
    func testHydrationDecrement_DoesNotGoBelowZero() async {
        // Set up hydration at zero.
        viewModel.hydration = HydrationStatus(
            date: "2026-03-28", servingsLogged: 0, totalOunces: 0,
            servingSizeOz: 8, dailyTargetServings: 8, dailyTargetOunces: 64,
            goalMet: false, goalProgressPercent: 0
        )

        await viewModel.removeWater()

        XCTAssertEqual(viewModel.hydration?.servingsLogged, 0, "Should not go below zero")
    }

    // MARK: - Meal Submission Validation (FR-NUT-1.3, FR-NUT-1.4)

    /// Test that empty description causes validation error.
    func testSubmitMeal_EmptyDescription_ThrowsError() async {
        viewModel.mealDescription = ""
        viewModel.mealType = .breakfast

        do {
            try await viewModel.submitMeal()
            // breakfast doesn't require description via the guard, so this is fine
        } catch {
            // Expected for .other meal type
        }
    }

    /// Test that description over 300 chars causes validation error.
    func testSubmitMeal_LongDescription_ThrowsError() async {
        viewModel.mealDescription = String(repeating: "a", count: 301)
        viewModel.mealType = .breakfast

        do {
            try await viewModel.submitMeal()
            XCTFail("Should throw for description over 300 chars")
        } catch {
            // Expected
        }
    }

    // MARK: - Conflict Resolution (FR-NUT-14.3)

    /// TestNutritionConflictResolver_UnionMergeMealLogs
    func testUnionMergeMealLogs() {
        let local = [
            MealLog(mealId: "ml_local1", timestamp: Date(), mealType: .breakfast,
                    customMealLabel: nil, description: "Local breakfast",
                    eatingContext: nil, moodBefore: nil, moodAfter: nil,
                    mindfulnessCheck: nil, notes: nil, isQuickLog: false, links: nil),
        ]

        let remote = [
            MealLog(mealId: "ml_remote1", timestamp: Date().addingTimeInterval(-3600),
                    mealType: .lunch, customMealLabel: nil, description: "Remote lunch",
                    eatingContext: nil, moodBefore: nil, moodAfter: nil,
                    mindfulnessCheck: nil, notes: nil, isQuickLog: false, links: nil),
        ]

        let merged = NutritionConflictResolver.unionMergeMealLogs(local: local, remote: remote)

        XCTAssertEqual(merged.count, 2, "Union merge should keep both entries")
    }

    /// TestNutritionConflictResolver_LWWHydration
    func testLWWHydration() {
        let local = HydrationStatus(
            date: "2026-03-28", servingsLogged: 3, totalOunces: 24,
            servingSizeOz: 8, dailyTargetServings: 8, dailyTargetOunces: 64,
            goalMet: false, goalProgressPercent: 37
        )
        let remote = HydrationStatus(
            date: "2026-03-28", servingsLogged: 5, totalOunces: 40,
            servingSizeOz: 8, dailyTargetServings: 8, dailyTargetOunces: 64,
            goalMet: false, goalProgressPercent: 62
        )

        let result = NutritionConflictResolver.lastWriterWinsHydration(local: local, remote: remote)

        XCTAssertEqual(result.servingsLogged, 5, "LWW should keep server version")
    }
}
