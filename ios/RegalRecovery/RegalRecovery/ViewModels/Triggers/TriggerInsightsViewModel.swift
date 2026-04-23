import Foundation

@Observable
final class TriggerInsightsViewModel {

    // MARK: - Nested Types

    struct InsightEntry {
        let id: UUID
        let timestamp: Date
        let intensity: Int?
        let dayOfWeek: Int      // 1=Sunday, 7=Saturday
        let timeOfDaySlot: TimeOfDaySlot
        let triggerCategories: [String]  // raw category values
        let hasLinkedUrge: Bool
    }

    struct TriggerFrequencyItem: Identifiable {
        let label: String
        let count: Int
        var id: String { label }
    }

    enum TimeWindow: String, CaseIterable, Identifiable {
        case week7 = "7 Days"
        case month30 = "30 Days"
        case quarter90 = "90 Days"
        case allTime = "All Time"

        var id: String { rawValue }

        var days: Int? {
            switch self {
            case .week7: return 7
            case .month30: return 30
            case .quarter90: return 90
            case .allTime: return nil
            }
        }
    }

    // MARK: - State Properties

    var entries: [InsightEntry] = []
    var triggerFrequencies: [String: Int] = [:]  // label -> count
    var selectedTimeWindow: TimeWindow = .month30

    // Computed metrics (set by recompute())
    var totalCount: Int = 0
    var resiliencePercent: Int = 0
    var averageIntensity: Double?
    var categoryDistribution: [TriggerCategory: Int] = [:]
    var heatMapData: [Int: [TimeOfDaySlot: Int]] = [:]  // dayOfWeek -> slot -> count

    // MARK: - Methods

    func recompute() {
        totalCount = entries.count

        // Handle empty entries case
        guard !entries.isEmpty else {
            resiliencePercent = 0
            averageIntensity = nil
            categoryDistribution = [:]
            heatMapData = [:]
            return
        }

        // Compute resilience percent (entries without linked urge)
        let entriesWithoutUrge = entries.filter { !$0.hasLinkedUrge }.count
        resiliencePercent = Int(round((Double(entriesWithoutUrge) / Double(totalCount)) * 100))

        // Compute average intensity (only from non-nil values)
        let intensityValues = entries.compactMap { $0.intensity }
        if !intensityValues.isEmpty {
            let sum = intensityValues.reduce(0, +)
            averageIntensity = Double(sum) / Double(intensityValues.count)
        } else {
            averageIntensity = nil
        }

        // Compute category distribution
        var categoryMap: [TriggerCategory: Int] = [:]
        for entry in entries {
            for categoryString in entry.triggerCategories {
                if let category = TriggerCategory(rawValue: categoryString) {
                    categoryMap[category, default: 0] += 1
                }
            }
        }
        categoryDistribution = categoryMap

        // Compute heat map data (dayOfWeek -> TimeOfDaySlot -> count)
        var heatMap: [Int: [TimeOfDaySlot: Int]] = [:]
        for entry in entries {
            var slotMap = heatMap[entry.dayOfWeek, default: [:]]
            slotMap[entry.timeOfDaySlot, default: 0] += 1
            heatMap[entry.dayOfWeek] = slotMap
        }
        heatMapData = heatMap
    }

    func topTriggers(limit: Int = 5) -> [TriggerFrequencyItem] {
        let sorted = triggerFrequencies.sorted { $0.value > $1.value }
        return sorted.prefix(limit).map { TriggerFrequencyItem(label: $0.key, count: $0.value) }
    }
}
