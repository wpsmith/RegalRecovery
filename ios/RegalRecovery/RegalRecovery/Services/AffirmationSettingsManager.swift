import Foundation

/// Singleton managing UserDefaults-backed settings for the affirmation experience:
/// pack display order, favorite display order, and per-day pack assignments.
final class AffirmationSettingsManager {
    static let shared = AffirmationSettingsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let packOrder = "affirmations.packOrder"
        static let favoriteOrder = "affirmations.favoriteOrder"
        static let dailyPacks = "affirmations.dailyPacks"
    }

    // MARK: - Pack Order

    /// Ordered pack names determining display order everywhere.
    /// Defaults to ContentData order.
    var packOrder: [String] {
        get {
            defaults.stringArray(forKey: Keys.packOrder)
                ?? ContentData.affirmationPacks.map(\.name)
        }
        set { defaults.set(newValue, forKey: Keys.packOrder) }
    }

    // MARK: - Favorite Order

    /// Ordered favorite IDs determining display order in the Favorites pack.
    /// Defaults to empty (which means fall back to createdAt order).
    var favoriteOrder: [UUID] {
        get {
            guard let strings = defaults.stringArray(forKey: Keys.favoriteOrder) else {
                return []
            }
            return strings.compactMap { UUID(uuidString: $0) }
        }
        set {
            defaults.set(newValue.map(\.uuidString), forKey: Keys.favoriteOrder)
        }
    }

    // MARK: - Daily Pack Assignment

    /// Day-of-week (1=Sunday ... 7=Saturday) mapped to a pack name.
    /// Drives which pack the Today screen opens directly.
    var dailyPackAssignment: [Int: String] {
        get {
            guard let dict = defaults.dictionary(forKey: Keys.dailyPacks) as? [String: String] else {
                return [:]
            }
            var result: [Int: String] = [:]
            for (key, value) in dict {
                if let day = Int(key) {
                    result[day] = value
                }
            }
            return result
        }
        set {
            let dict = Dictionary(uniqueKeysWithValues: newValue.map { (String($0.key), $0.value) })
            defaults.set(dict, forKey: Keys.dailyPacks)
        }
    }

    // MARK: - Convenience

    /// Returns the assigned pack name for today's day-of-week, if any.
    func packForToday() -> String? {
        let weekday = Calendar.current.component(.weekday, from: Date()) // 1=Sun, 7=Sat
        return dailyPackAssignment[weekday]
    }

    // MARK: - Persistence

    func save() {
        // UserDefaults writes are already immediate; this is a semantic hook
        // for callers that want an explicit save point.
        defaults.synchronize()
    }

    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.packOrder)
        defaults.removeObject(forKey: Keys.favoriteOrder)
        defaults.removeObject(forKey: Keys.dailyPacks)
    }

    private init() {}
}
