import Foundation

// MARK: - History Tab

enum HistoryTab: String, CaseIterable, Identifiable {
    case list = "List"
    case calendar = "Calendar"
    case favorites = "Favorites"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .list: return "list.bullet"
        case .calendar: return "calendar"
        case .favorites: return "heart.fill"
        }
    }
}

// MARK: - Favorite Item Wrapper

struct FavoriteItemInfo: Identifiable {
    let item: GratitudeItem
    let entryDate: Date
    let entryId: UUID

    var id: UUID { item.id }
}

// MARK: - View Model

@Observable
class GratitudeHistoryViewModel {

    // MARK: - State

    var searchText: String = ""
    var selectedCategories: Set<GratitudeCategory> = []
    var filterHasPhoto: Bool = false
    var filterMoodScore: Int? = nil
    var selectedTab: HistoryTab = .list

    // Calendar state
    var displayedMonth: Date = Date()

    // MARK: - Filtering

    func filteredEntries(from entries: [RRGratitudeEntry]) -> [RRGratitudeEntry] {
        entries.filter { entry in
            let matchesSearch: Bool = {
                guard searchText.count >= 2 else { return true }
                return entry.items.contains { item in
                    item.text.localizedCaseInsensitiveContains(searchText)
                }
            }()

            let matchesCategories: Bool = {
                guard !selectedCategories.isEmpty else { return true }
                return entry.items.contains { item in
                    guard let category = item.category else { return false }
                    return selectedCategories.contains(category)
                }
            }()

            let matchesPhoto: Bool = {
                guard filterHasPhoto else { return true }
                return entry.photoLocalPath != nil
            }()

            let matchesMood: Bool = {
                guard let target = filterMoodScore else { return true }
                return entry.moodScore == target
            }()

            return matchesSearch && matchesCategories && matchesPhoto && matchesMood
        }
    }

    // MARK: - Favorites

    func allFavoriteItems(from entries: [RRGratitudeEntry]) -> [FavoriteItemInfo] {
        entries.flatMap { entry in
            entry.items
                .filter { $0.isFavorite }
                .map { item in
                    FavoriteItemInfo(item: item, entryDate: entry.date, entryId: entry.id)
                }
        }
        .sorted { $0.entryDate > $1.entryDate }
    }

    func toggleItemFavorite(itemId: UUID, in entry: RRGratitudeEntry) {
        guard let index = entry.items.firstIndex(where: { $0.id == itemId }) else { return }
        entry.items[index].isFavorite.toggle()
        entry.modifiedAt = Date()
    }

    // MARK: - Calendar Helpers

    func entriesForDate(_ date: Date, from entries: [RRGratitudeEntry]) -> [RRGratitudeEntry] {
        let calendar = Calendar.current
        return entries.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func datesWithEntries(from entries: [RRGratitudeEntry]) -> Set<DateComponents> {
        let calendar = Calendar.current
        return Set(entries.map { calendar.dateComponents([.year, .month, .day], from: $0.date) })
    }

    // MARK: - Calendar Navigation

    func previousMonth() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    func nextMonth() {
        displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }

    // MARK: - Filter Management

    func toggleCategory(_ category: GratitudeCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }

    func clearFilters() {
        searchText = ""
        selectedCategories = []
        filterHasPhoto = false
        filterMoodScore = nil
    }

    var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || filterHasPhoto || filterMoodScore != nil
    }
}
