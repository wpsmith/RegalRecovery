import Foundation

/// ViewModel for the Nutrition activity screen.
/// Handles meal logging, hydration tracking, and trends display.
/// Feature flag: `activity.nutrition`
@Observable
class NutritionViewModel {

    // MARK: - State

    var meals: [MealLog] = []
    var hydration: HydrationStatus?
    var calendarDays: [NutritionCalendarDay] = []
    var trends: NutritionTrendsData?
    var weeklySummary: WeeklySummaryData?
    var settings: NutritionSettings = .defaults
    var isLoading = false
    var error: String?

    // Meal entry form state.
    var mealType: MealType = .breakfast
    var mealDescription: String = ""
    var customMealLabel: String = ""
    var eatingContext: EatingContext?
    var moodBefore: Int?
    var moodAfter: Int?
    var mindfulnessCheck: MindfulnessCheck?
    var mealNotes: String = ""

    // MARK: - Computed

    var todayMeals: [MealLog] {
        let today = Calendar.current.startOfDay(for: Date())
        return meals.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
    }

    var todayMealCount: Int { todayMeals.count }

    var hydrationProgress: Double {
        guard let h = hydration, h.dailyTargetServings > 0 else { return 0 }
        return min(Double(h.servingsLogged) / Double(h.dailyTargetServings), 1.0)
    }

    // MARK: - Load

    func loadMeals() async {
        isLoading = true
        defer { isLoading = false }

        // Fallback to mock data since API may not be available yet.
        meals = [
            MealLog(mealId: "ml_mock1", timestamp: Date().addingTimeInterval(-3600 * 4),
                    mealType: .breakfast, customMealLabel: nil,
                    description: "Scrambled eggs, toast, and coffee",
                    eatingContext: .homemade, moodBefore: 3, moodAfter: 4,
                    mindfulnessCheck: .yes, notes: nil, isQuickLog: false, links: nil),
            MealLog(mealId: "ml_mock2", timestamp: Date().addingTimeInterval(-3600 * 1),
                    mealType: .lunch, customMealLabel: nil,
                    description: "Grilled chicken salad",
                    eatingContext: .homemade, moodBefore: 2, moodAfter: 4,
                    mindfulnessCheck: .somewhat, notes: "Felt better after eating", isQuickLog: false, links: nil),
        ]
    }

    func loadHydration() async {
        hydration = HydrationStatus(
            date: ISO8601DateFormatter().string(from: Date()).prefix(10).description,
            servingsLogged: 5,
            totalOunces: 40,
            servingSizeOz: 8,
            dailyTargetServings: 8,
            dailyTargetOunces: 64,
            goalMet: false,
            goalProgressPercent: 62
        )
    }

    func loadAll() async {
        await loadMeals()
        await loadHydration()
    }

    // MARK: - Meal Actions

    func submitMeal() async throws {
        guard !mealDescription.isEmpty || mealType != .other else {
            throw ActivityError.validationFailed("Description is required.")
        }
        guard mealDescription.count <= 300 else {
            throw ActivityError.validationFailed("Description must be 300 characters or fewer.")
        }

        let newMeal = MealLog(
            mealId: "ml_\(UUID().uuidString.prefix(8))",
            timestamp: Date(),
            mealType: mealType,
            customMealLabel: mealType == .other ? customMealLabel : nil,
            description: mealDescription,
            eatingContext: eatingContext,
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            mindfulnessCheck: mindfulnessCheck,
            notes: mealNotes.isEmpty ? nil : mealNotes,
            isQuickLog: false,
            links: nil
        )

        meals.insert(newMeal, at: 0)
        resetMealForm()
    }

    func quickLog(type: MealType) async throws {
        let newMeal = MealLog(
            mealId: "ml_\(UUID().uuidString.prefix(8))",
            timestamp: Date(),
            mealType: type,
            customMealLabel: nil,
            description: nil,
            eatingContext: nil,
            moodBefore: nil,
            moodAfter: nil,
            mindfulnessCheck: nil,
            notes: nil,
            isQuickLog: true,
            links: nil
        )

        meals.insert(newMeal, at: 0)
    }

    // MARK: - Hydration Actions

    func addWater(servings: Int = 1) async {
        guard var h = hydration else { return }
        let newServings = h.servingsLogged + servings
        let servingSizeOz = h.servingSizeOz
        let target = h.dailyTargetServings
        hydration = HydrationStatus(
            date: h.date,
            servingsLogged: newServings,
            totalOunces: Double(newServings) * servingSizeOz,
            servingSizeOz: servingSizeOz,
            dailyTargetServings: target,
            dailyTargetOunces: Double(target) * servingSizeOz,
            goalMet: newServings >= target,
            goalProgressPercent: min(newServings * 100 / max(target, 1), 100)
        )
    }

    func removeWater(servings: Int = 1) async {
        guard var h = hydration else { return }
        let newServings = max(h.servingsLogged - servings, 0)
        let servingSizeOz = h.servingSizeOz
        let target = h.dailyTargetServings
        hydration = HydrationStatus(
            date: h.date,
            servingsLogged: newServings,
            totalOunces: Double(newServings) * servingSizeOz,
            servingSizeOz: servingSizeOz,
            dailyTargetServings: target,
            dailyTargetOunces: Double(target) * servingSizeOz,
            goalMet: newServings >= target,
            goalProgressPercent: min(newServings * 100 / max(target, 1), 100)
        )
    }

    // MARK: - Private

    private func resetMealForm() {
        mealType = .breakfast
        mealDescription = ""
        customMealLabel = ""
        eatingContext = nil
        moodBefore = nil
        moodAfter = nil
        mindfulnessCheck = nil
        mealNotes = ""
    }
}
