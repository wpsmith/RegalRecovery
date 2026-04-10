import Foundation
import Observation
import OSLog

// MARK: - Pattern View Model

/// Drives the pattern dashboard: timeline, insights, drift alerts, and summary.
///
/// Uses the Three Circles API client for all data fetching.
/// Period selection, overlay toggles, and dismissal actions are local state.
@Observable
class PatternViewModel {

    // MARK: - Published State

    var selectedPeriod: TimelinePeriod = .thirtyDays
    var timelineData: TimelineData?
    var summary: TimelineSummary?
    var insights: [PatternInsight] = []
    var driftAlerts: [DriftAlert] = []
    var patternSummary: PatternSummary?

    var showMoodOverlay: Bool = false
    var showUrgeOverlay: Bool = false

    var isLoadingTimeline: Bool = false
    var isLoadingInsights: Bool = false
    var isLoadingDriftAlerts: Bool = false
    var isLoadingSummary: Bool = false

    var error: String?

    // MARK: - Dependencies

    private let apiClient: ThreeCirclesAPIClient
    private let setId: String
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "PatternViewModel")

    // MARK: - Init

    init(apiClient: ThreeCirclesAPIClient, setId: String) {
        self.apiClient = apiClient
        self.setId = setId
    }

    // MARK: - Computed

    var totalDays: Int {
        guard let s = summary else { return 0 }
        return s.outerDays + s.middleDays + s.innerDays + s.noCheckinDays
    }

    /// Descriptive framing message. Never percentages, never grades.
    var framingMessage: String {
        guard let s = summary else { return "" }

        var parts: [String] = []
        if s.outerDays > 0 {
            parts.append("\(s.outerDays) outer circle \(s.outerDays == 1 ? "day" : "days")")
        }
        if s.middleDays > 0 {
            parts.append("\(s.middleDays) middle circle \(s.middleDays == 1 ? "day" : "days")")
        }
        if s.innerDays > 0 {
            parts.append("\(s.innerDays) inner circle \(s.innerDays == 1 ? "day" : "days")")
        }
        if s.noCheckinDays > 0 {
            parts.append("\(s.noCheckinDays) \(s.noCheckinDays == 1 ? "day" : "days") without a check-in")
        }

        guard !parts.isEmpty else { return "No data for this period yet." }

        let joined = parts.joined(separator: ", ")
        return "You logged \(joined) in this period."
    }

    /// Recovery total: all outer days since tracking began.
    var recoveryTotal: Int {
        summary?.outerDays ?? 0
    }

    /// Consecutive outer days, shown subtly -- not primary metric.
    var consecutiveOuterDays: Int {
        summary?.currentConsecutiveOuterDays ?? 0
    }

    var hasActiveDriftAlert: Bool {
        driftAlerts.contains { !$0.dismissed }
    }

    var activeDriftAlerts: [DriftAlert] {
        driftAlerts.filter { !$0.dismissed }
    }

    // MARK: - Data Loading

    /// Load all pattern data for the current period.
    func loadAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadTimeline() }
            group.addTask { await self.loadInsights() }
            group.addTask { await self.loadDriftAlerts() }
            group.addTask { await self.loadSummary() }
        }
    }

    /// Load timeline entries for the selected period.
    func loadTimeline() async {
        isLoadingTimeline = true
        defer { isLoadingTimeline = false }

        do {
            let response = try await apiClient.getTimeline(
                setId: setId,
                period: selectedPeriod
            )
            timelineData = response.data
            summary = response.data.summary
            error = nil
        } catch {
            logger.error("Failed to load timeline: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    /// Load pattern insights.
    func loadInsights() async {
        isLoadingInsights = true
        defer { isLoadingInsights = false }

        do {
            let response = try await apiClient.getInsights(setId: setId)
            insights = response.data
            error = nil
        } catch {
            logger.error("Failed to load insights: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    /// Load drift alerts (active only).
    func loadDriftAlerts() async {
        isLoadingDriftAlerts = true
        defer { isLoadingDriftAlerts = false }

        do {
            let response = try await apiClient.getDriftAlerts(
                setId: setId,
                status: .active
            )
            driftAlerts = response.data
            error = nil
        } catch {
            logger.error("Failed to load drift alerts: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    /// Load weekly/monthly summary for sharing.
    func loadSummary() async {
        isLoadingSummary = true
        defer { isLoadingSummary = false }

        do {
            let response = try await apiClient.getSummary(
                setId: setId,
                period: .week
            )
            patternSummary = response.data
            error = nil
        } catch {
            logger.error("Failed to load summary: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }

    // MARK: - Period Selection

    func selectPeriod(_ period: TimelinePeriod) async {
        selectedPeriod = period
        await loadTimeline()
    }

    // MARK: - Overlay Toggles

    func toggleMoodOverlay() {
        showMoodOverlay.toggle()
    }

    func toggleUrgeOverlay() {
        showUrgeOverlay.toggle()
    }

    // MARK: - Dismiss Actions

    /// Dismiss a single insight card.
    func dismissInsight(_ insight: PatternInsight) {
        insights.removeAll { $0.insightId == insight.insightId }
    }

    /// Dismiss a drift alert via API, then remove locally.
    func dismissDriftAlert(_ alert: DriftAlert) async {
        do {
            try await apiClient.dismissDriftAlert(alertId: alert.alertId)
            driftAlerts.removeAll { $0.alertId == alert.alertId }
        } catch {
            logger.error("Failed to dismiss drift alert: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
}
