import Foundation

/// API client for nutrition endpoints. Hand-written to match the OpenAPI spec.
/// Feature flag: `activity.nutrition`
final class NutritionAPIClient: Sendable {

    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Meals

    /// POST /activities/nutrition/meals
    func createMealLog(_ request: CreateMealLogRequest) async throws -> SiemensResponse<MealLog> {
        try await apiClient.post(.nutritionCreateMeal(request))
    }

    /// POST /activities/nutrition/meals/quick
    func createQuickMealLog(_ request: CreateQuickMealLogRequest) async throws -> SiemensResponse<MealLog> {
        try await apiClient.post(.nutritionQuickLog(request))
    }

    /// GET /activities/nutrition/meals/{mealId}
    func getMealLog(mealId: String) async throws -> SiemensResponse<MealLog> {
        try await apiClient.get(.nutritionGetMeal(mealId: mealId))
    }

    /// GET /activities/nutrition/meals
    func listMealLogs(
        mealType: String? = nil,
        eatingContext: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        search: String? = nil,
        cursor: String? = nil,
        limit: Int? = nil
    ) async throws -> PaginatedResponse<MealLog> {
        try await apiClient.getList(.nutritionListMeals(
            mealType: mealType,
            eatingContext: eatingContext,
            startDate: startDate,
            endDate: endDate,
            search: search,
            cursor: cursor,
            limit: limit
        ))
    }

    /// PATCH /activities/nutrition/meals/{mealId}
    func updateMealLog(mealId: String, _ request: UpdateMealLogRequest) async throws -> SiemensResponse<MealLog> {
        try await apiClient.patch(.nutritionUpdateMeal(mealId: mealId, request))
    }

    /// DELETE /activities/nutrition/meals/{mealId}
    func deleteMealLog(mealId: String) async throws {
        try await apiClient.delete(.nutritionDeleteMeal(mealId: mealId))
    }

    // MARK: - Hydration

    /// GET /activities/nutrition/hydration
    func getHydrationToday() async throws -> SiemensResponse<HydrationStatus> {
        try await apiClient.get(.nutritionGetHydration)
    }

    /// POST /activities/nutrition/hydration/log
    func logHydration(_ request: LogHydrationRequest) async throws -> SiemensResponse<HydrationStatus> {
        try await apiClient.post(.nutritionLogHydration(request))
    }

    /// GET /activities/nutrition/hydration/history
    func getHydrationHistory(startDate: String, endDate: String) async throws -> PaginatedResponse<HydrationDay> {
        try await apiClient.getList(.nutritionHydrationHistory(startDate: startDate, endDate: endDate))
    }

    // MARK: - Calendar

    /// GET /activities/nutrition/calendar
    func getCalendar(year: Int, month: Int) async throws -> SiemensResponse<NutritionCalendarData> {
        try await apiClient.get(.nutritionCalendar(year: year, month: month))
    }

    // MARK: - Trends

    /// GET /activities/nutrition/trends
    func getTrends(period: String) async throws -> SiemensResponse<NutritionTrendsData> {
        try await apiClient.get(.nutritionTrends(period: period))
    }

    /// GET /activities/nutrition/trends/weekly-summary
    func getWeeklySummary() async throws -> SiemensResponse<WeeklySummaryData> {
        try await apiClient.get(.nutritionWeeklySummary)
    }

    // MARK: - Settings

    /// GET /activities/nutrition/settings
    func getSettings() async throws -> SiemensResponse<NutritionSettings> {
        try await apiClient.get(.nutritionGetSettings)
    }

    /// PATCH /activities/nutrition/settings
    func updateSettings(_ body: [String: Any]) async throws -> SiemensResponse<NutritionSettings> {
        try await apiClient.patch(.nutritionUpdateSettings(body))
    }
}
