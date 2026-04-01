import SwiftUI
import SwiftData

@Observable
class StreakViewModel {
    var currentDays: Int = 0
    var sobrietyDate: Date = Date()
    var longestStreak: Int = 0
    var totalRelapses: Int = 0
    var nextMilestoneDays: Int = 0
    var milestones: [Milestone] = []
    var isLoading = false
    var error: String?

    // MARK: - Standard milestones

    static let milestoneThresholds = [1, 3, 7, 14, 30, 60, 90, 120, 180, 270, 365, 500, 730, 1000, 1825, 3650]

    // MARK: - Loading

    func load(context: ModelContext) async {
        isLoading = true
        error = nil

        do {
            try await loadFromSwiftData(context: context)
        } catch {
            self.error = "Unable to load streak data. Please try again."
        }

        isLoading = false
    }

    // MARK: - Actions

    func recordRelapse(notes: String, triggers: [String]) async throws {
        // TODO: Persist to repository
        // Reset streak by updating sobriety date to now
        sobrietyDate = Date()
        totalRelapses += 1
        currentDays = 0
        nextMilestoneDays = nextMilestone(for: 0)
    }

    // MARK: - Calculations

    /// Calculate streak days in real-time from the sobriety date
    func calculateStreakDays() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: calendar.startOfDay(for: sobrietyDate), to: calendar.startOfDay(for: Date()))
        return max(0, components.day ?? 0)
    }

    /// Find the next milestone threshold for a given day count
    func nextMilestone(for days: Int) -> Int {
        for threshold in Self.milestoneThresholds {
            if threshold > days {
                return threshold
            }
        }
        // Beyond all defined milestones: next yearly milestone
        let years = (days / 365) + 1
        return years * 365
    }

    /// Return a scripture reference for a milestone day count
    func milestoneScripture(for days: Int) -> String {
        switch days {
        case 1:    return "Lamentations 3:22-23 — His mercies are new every morning."
        case 3:    return "Psalm 30:5 — Weeping may stay for the night, but rejoicing comes in the morning."
        case 7:    return "Isaiah 40:31 — Those who hope in the Lord will renew their strength."
        case 14:   return "Philippians 1:6 — He who began a good work in you will carry it on to completion."
        case 30:   return "2 Corinthians 5:17 — If anyone is in Christ, the new creation has come."
        case 60:   return "Romans 8:37 — We are more than conquerors through Him who loved us."
        case 90:   return "Psalm 51:10 — Create in me a pure heart, O God."
        case 120:  return "Hebrews 12:1 — Let us run with perseverance the race marked out for us."
        case 180:  return "James 1:12 — Blessed is the one who perseveres under trial."
        case 270:  return "Galatians 5:1 — It is for freedom that Christ has set us free."
        case 365:  return "Philippians 4:13 — I can do all things through Christ who strengthens me."
        case 500:  return "2 Timothy 4:7 — I have fought the good fight, I have finished the race."
        case 730:  return "Psalm 40:2 — He set my feet on a rock and gave me a firm place to stand."
        case 1000: return "Romans 8:28 — All things work together for good for those who love God."
        case 1825: return "Psalm 126:3 — The Lord has done great things for us, and we are filled with joy."
        case 3650: return "Revelation 21:5 — Behold, I am making all things new."
        default:   return "Psalm 37:5 — Commit your way to the Lord; trust in Him and He will act."
        }
    }

    // MARK: - Private

    private func loadFromSwiftData(context: ModelContext) async throws {
        let streakDescriptor = FetchDescriptor<RRStreak>()
        guard let rrStreak = try context.fetch(streakDescriptor).first else { return }

        currentDays = rrStreak.currentDays
        sobrietyDate = rrStreak.addiction?.sobrietyDate ?? Date()
        longestStreak = rrStreak.longestStreak
        totalRelapses = rrStreak.totalRelapses
        nextMilestoneDays = nextMilestone(for: currentDays)

        let milestoneDescriptor = FetchDescriptor<RRMilestone>(sortBy: [SortDescriptor(\.days)])
        let rrMilestones = try context.fetch(milestoneDescriptor)
        milestones = rrMilestones.map { Milestone(days: $0.days, dateEarned: $0.dateEarned, scripture: $0.scripture) }
    }
}
