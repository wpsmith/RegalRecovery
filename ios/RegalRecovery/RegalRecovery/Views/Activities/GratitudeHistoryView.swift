import SwiftUI
import SwiftData

struct GratitudeHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRGratitudeEntry.date, order: .reverse) private var entries: [RRGratitudeEntry]

    @State private var viewModel = GratitudeHistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("View", selection: $viewModel.selectedTab) {
                ForEach(HistoryTab.allCases) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch viewModel.selectedTab {
            case .list:
                listTab
            case .calendar:
                calendarTab
            case .favorites:
                favoritesTab
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Gratitude History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - List Tab

    private var listTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Search bar
                searchBar

                // Filter chips
                filterChips

                // Entry cards
                let filtered = viewModel.filteredEntries(from: entries)
                if filtered.isEmpty {
                    emptyState(
                        icon: "leaf.fill",
                        title: "No Entries Found",
                        message: viewModel.hasActiveFilters
                            ? "Try adjusting your filters."
                            : "Start logging what you are grateful for."
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filtered) { entry in
                            NavigationLink(destination: GratitudeDetailView(entry: entry)) {
                                entryCard(entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.rrTextSecondary)
            TextField("Search gratitude items...", text: $viewModel.searchText)
                .font(RRFont.body)
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
        .padding(10)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category chips
                ForEach(GratitudeCategory.allCases) { category in
                    filterPill(
                        label: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategories.contains(category)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.toggleCategory(category)
                        }
                    }
                }

                // Photo filter
                filterPill(
                    label: "Photo",
                    icon: "camera.fill",
                    isSelected: viewModel.filterHasPhoto
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.filterHasPhoto.toggle()
                    }
                }

                // Clear filters
                if viewModel.hasActiveFilters {
                    Button {
                        withAnimation { viewModel.clearFilters() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func filterPill(label: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(RRFont.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(isSelected ? .white : Color.rrPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.rrPrimary : Color.rrPrimary.opacity(0.08))
            .clipShape(Capsule())
        }
    }

    // MARK: - Entry Card

    @ViewBuilder
    private func entryCard(_ entry: RRGratitudeEntry) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                // Header: date + item count
                HStack {
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                        .font(RRFont.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)

                    Text("\(entry.items.count) item\(entry.items.count == 1 ? "" : "s")")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    Spacer()

                    if let mood = entry.moodScore {
                        Image(systemName: MoodIcon.symbolName(for: mood))
                            .font(.title3)
                            .foregroundStyle(MoodIcon.color(for: mood))
                    }
                }

                // Preview: first 2 items
                let previewItems = Array(entry.items.prefix(2))
                ForEach(previewItems) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.rrSuccess)
                            .padding(.top, 3)
                        Text(item.text)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                            .lineLimit(1)
                    }
                }

                // Category pills + photo indicator
                HStack(spacing: 6) {
                    let categoryNames = uniqueCategoryDisplayNames(in: entry)
                    ForEach(categoryNames, id: \.name) { item in
                        RRBadge(text: item.name, color: item.color)
                    }

                    if entry.photoLocalPath != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
    }

    // MARK: - Calendar Tab

    private var calendarTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                calendarGrid
                    .padding(.horizontal)

                // Entries for selected date handled via tap below
            }
            .padding(.vertical)
        }
    }

    private var calendarGrid: some View {
        let calendar = Calendar.current
        let month = viewModel.displayedMonth
        let datesWithDots = viewModel.datesWithEntries(from: entries)

        return VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button { viewModel.previousMonth() } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.rrPrimary)
                }

                Spacer()

                Text(month.formatted(.dateTime.month(.wide).year()))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Spacer()

                Button { viewModel.nextMonth() } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.rrPrimary)
                }
            }

            // Weekday headers
            let weekdaySymbols = calendar.veryShortWeekdaySymbols
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(RRFont.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let days = calendarDays(for: month)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    if let day = day {
                        let components = calendar.dateComponents([.year, .month, .day], from: day)
                        let hasEntry = datesWithDots.contains(components)
                        let isToday = calendar.isDateInToday(day)

                        NavigationLink(destination: calendarDayDetail(day)) {
                            VStack(spacing: 2) {
                                Text("\(calendar.component(.day, from: day))")
                                    .font(RRFont.body)
                                    .fontWeight(isToday ? .bold : .regular)
                                    .foregroundStyle(isToday ? Color.rrPrimary : Color.rrText)

                                Circle()
                                    .fill(hasEntry ? Color.rrSuccess : Color.clear)
                                    .frame(width: 6, height: 6)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func calendarDayDetail(_ date: Date) -> some View {
        let dayEntries = viewModel.entriesForDate(date, from: entries)
        ScrollView {
            VStack(spacing: 12) {
                Text(date.formatted(date: .complete, time: .omitted))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                if dayEntries.isEmpty {
                    emptyState(
                        icon: "leaf",
                        title: "No Entries",
                        message: "No gratitude entries for this day."
                    )
                } else {
                    ForEach(dayEntries) { entry in
                        NavigationLink(destination: GratitudeDetailView(entry: entry)) {
                            entryCard(entry)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .navigationTitle("Day Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Favorites Tab

    private var favoritesTab: some View {
        let favorites = viewModel.allFavoriteItems(from: entries)

        return ScrollView {
            if favorites.isEmpty {
                emptyState(
                    icon: "heart",
                    title: "No Favorites Yet",
                    message: "Tap the heart on items you want to remember."
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(favorites) { fav in
                        NavigationLink(destination: entryDetailById(fav.entryId)) {
                            RRCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .font(.caption)
                                            .foregroundStyle(Color.rrDestructive)

                                        Text(fav.item.text)
                                            .font(RRFont.body)
                                            .foregroundStyle(Color.rrText)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        Spacer()
                                    }

                                    HStack(spacing: 8) {
                                        Text(fav.entryDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)

                                        if let category = fav.item.category {
                                            RRBadge(text: fav.item.displayCategoryName ?? category.rawValue, color: category.color)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }

    @ViewBuilder
    private func entryDetailById(_ entryId: UUID) -> some View {
        if let entry = entries.first(where: { $0.id == entryId }) {
            GratitudeDetailView(entry: entry)
        } else {
            Text("Entry not found")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.5))

            Text(title)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            Text(message)
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Helpers

    private func uniqueCategories(in entry: RRGratitudeEntry) -> [GratitudeCategory] {
        var seen = Set<GratitudeCategory>()
        var result: [GratitudeCategory] = []
        for item in entry.items {
            if let cat = item.category, !seen.contains(cat) {
                seen.insert(cat)
                result.append(cat)
            }
        }
        return result
    }

    private struct CategoryDisplayItem {
        let name: String
        let color: Color
    }

    private func uniqueCategoryDisplayNames(in entry: RRGratitudeEntry) -> [CategoryDisplayItem] {
        var seen = Set<String>()
        var result: [CategoryDisplayItem] = []
        for item in entry.items {
            if let category = item.category {
                let displayName = item.displayCategoryName ?? category.rawValue
                if !seen.contains(displayName) {
                    seen.insert(displayName)
                    result.append(CategoryDisplayItem(name: displayName, color: category.color))
                }
            }
        }
        return result
    }

    private func calendarDays(for month: Date) -> [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: month))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad trailing to fill last week row
        let remainder = days.count % 7
        if remainder > 0 {
            days.append(contentsOf: Array(repeating: nil as Date?, count: 7 - remainder))
        }

        return days
    }
}

// MARK: - Preview

#Preview {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)

    let userId = UUID()
    let entries = [
        RRGratitudeEntry(
            userId: userId,
            date: Date(),
            items: [
                GratitudeItem(text: "Morning quiet time with God", category: .faithGod, isFavorite: true, sortOrder: 0),
                GratitudeItem(text: "Rachel's patience and love", category: .relationships, sortOrder: 1),
                GratitudeItem(text: "Progress in Step 8 work", category: .recovery, sortOrder: 2),
            ],
            moodScore: 4
        ),
        RRGratitudeEntry(
            userId: userId,
            date: Date().addingTimeInterval(-86400),
            items: [
                GratitudeItem(text: "A good night's sleep", category: .health, sortOrder: 0),
                GratitudeItem(text: "Coffee with Mike", category: .smallMoments, isFavorite: true, sortOrder: 1),
            ],
            moodScore: 3,
            photoLocalPath: "/fake/photo.jpg"
        ),
        RRGratitudeEntry(
            userId: userId,
            date: Date().addingTimeInterval(-172800),
            items: [
                GratitudeItem(text: "Beautiful weather for a walk", category: .natureBeauty, sortOrder: 0),
            ],
            moodScore: 5
        ),
    ]

    for entry in entries {
        container.mainContext.insert(entry)
    }

    return NavigationStack {
        GratitudeHistoryView()
    }
    .modelContainer(container)
}
