import SwiftUI

@Observable
class ActivityViewModel {
    let activityType: String
    var history: [ActivityEntry] = []
    var isLoading = false
    var error: String?

    init(activityType: String) {
        self.activityType = activityType
    }

    // MARK: - Loading

    func loadHistory(limit: Int = 20) async {
        isLoading = true
        error = nil

        do {
            // TODO: Replace MockData fallback with real repository calls
            try await loadFromMockData(limit: limit)
        } catch {
            self.error = "Unable to load \(activityType) history. Please try again."
        }

        isLoading = false
    }

    // MARK: - Actions

    func logEntry(data: [String: Any]) async throws {
        // TODO: Persist to repository
        let entry = ActivityEntry(
            type: activityTypeEnum ?? .mood,
            date: Date(),
            summary: activityType,
            detail: data["detail"] as? String ?? "",
            value: data["value"] as? Double,
            icon: activityTypeEnum?.icon ?? "circle.fill",
            iconColor: activityTypeEnum?.iconColor ?? .gray
        )
        history.insert(entry, at: 0)
    }

    // MARK: - Private

    private var activityTypeEnum: ActivityType? {
        ActivityType.allCases.first { $0.rawValue == activityType }
    }

    private func loadFromMockData(limit: Int) async throws {
        // Generate sample history entries from MockData patterns
        guard let type = activityTypeEnum else { return }

        var entries: [ActivityEntry] = []
        for i in 0..<min(limit, 7) {
            entries.append(ActivityEntry(
                type: type,
                date: MockData.daysAgo(i),
                summary: type.rawValue,
                detail: sampleDetail(for: type, dayOffset: i),
                value: sampleValue(for: type),
                icon: type.icon,
                iconColor: type.iconColor
            ))
        }
        history = entries
    }

    private func sampleDetail(for type: ActivityType, dayOffset: Int) -> String {
        switch type {
        case .mood:       return "Rating: \(7 + (dayOffset % 3))/10"
        case .gratitude:  return "3 items listed"
        case .prayer:     return "\(10 + dayOffset * 2) minutes"
        case .exercise:   return "30 min run"
        case .phoneCalls: return "Called sponsor"
        default:          return "Completed"
        }
    }

    private func sampleValue(for type: ActivityType) -> Double {
        switch type {
        case .mood:     return Double.random(in: 5...9)
        case .prayer:   return Double.random(in: 10...30)
        case .exercise: return Double.random(in: 20...60)
        default:        return 1.0
        }
    }
}
