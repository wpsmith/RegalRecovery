import SwiftUI
import SwiftData

struct JournalHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRJournalEntry.date, order: .reverse) private var allEntries: [RRJournalEntry]

    @State private var searchText = ""
    @State private var modeFilter: String? = nil  // nil = All
    @State private var dateFilter: DateFilter = .allTime
    @State private var entryToDelete: RRJournalEntry?
    @State private var showDeleteConfirmation = false

    enum DateFilter: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case allTime = "All Time"
    }

    var body: some View {
        List {
            // Entry count
            Section {
                Text("\(filteredEntries.count) entries")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .listRowBackground(Color.rrBackground)
                    .listRowSeparator(.hidden)
            }

            // Filter chips
            Section {
                filterChips
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.rrBackground)
                    .listRowSeparator(.hidden)
            }

            // Grouped entries
            ForEach(groupedSections, id: \.title) { section in
                Section {
                    ForEach(section.entries) { entry in
                        NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                            entryRow(entry)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                entryToDelete = entry
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Color.rrSurface)
                    }
                } header: {
                    Text(section.title)
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.rrBackground)
        .navigationTitle("Journal History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search entries...")
        .confirmationDialog("Delete this entry?", isPresented: $showDeleteConfirmation, presenting: entryToDelete) { entry in
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
            }
        }
    }

    // MARK: - Filter Chips

    @ViewBuilder
    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    modePill(label: "All", mode: nil)
                    modePill(label: "Jotting", mode: "jotting")
                    modePill(label: "Prompted", mode: "prompted")
                    modePill(label: "Freeform", mode: "freeform")
                }
                .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(DateFilter.allCases, id: \.self) { filter in
                        datePill(filter)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func modePill(label: String, mode: String?) -> some View {
        let isSelected = modeFilter == mode
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                modeFilter = mode
            }
        } label: {
            Text(label)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color.rrPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.rrPrimary : Color.rrPrimary.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func datePill(_ filter: DateFilter) -> some View {
        let isSelected = dateFilter == filter
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                dateFilter = filter
            }
        } label: {
            Text(filter.rawValue)
                .font(RRFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color.rrPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.rrPrimary : Color.rrPrimary.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    // MARK: - Entry Row

    @ViewBuilder
    private func entryRow(_ entry: RRJournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entry.date.formatted(date: .omitted, time: .shortened))
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                Text(entry.mode.capitalized)
                    .font(RRFont.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.rrPrimary.opacity(0.08))
                    .clipShape(Capsule())

                if entry.prompt != nil {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow.opacity(0.7))
                }

                Spacer()
            }

            Text(entry.content)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Filtering

    private var filteredEntries: [RRJournalEntry] {
        allEntries.filter { entry in
            let matchesSearch = searchText.isEmpty ||
                entry.content.localizedCaseInsensitiveContains(searchText) ||
                (entry.prompt?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesMode = modeFilter == nil || entry.mode == modeFilter
            let matchesDate: Bool = {
                switch dateFilter {
                case .thisWeek:
                    return Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .weekOfYear)
                case .thisMonth:
                    return Calendar.current.isDate(entry.date, equalTo: Date(), toGranularity: .month)
                case .allTime:
                    return true
                }
            }()
            return matchesSearch && matchesMode && matchesDate
        }
    }

    // MARK: - Grouping

    private struct EntrySection {
        let title: String
        let entries: [RRJournalEntry]
    }

    private var groupedSections: [EntrySection] {
        let cal = Calendar.current
        let now = Date()

        var today: [RRJournalEntry] = []
        var yesterday: [RRJournalEntry] = []
        var thisWeek: [RRJournalEntry] = []
        var earlierThisMonth: [RRJournalEntry] = []
        var byMonth: [String: [RRJournalEntry]] = [:]
        var monthOrder: [String] = []

        for entry in filteredEntries {
            if cal.isDateInToday(entry.date) {
                today.append(entry)
            } else if cal.isDateInYesterday(entry.date) {
                yesterday.append(entry)
            } else if cal.isDate(entry.date, equalTo: now, toGranularity: .weekOfYear) {
                thisWeek.append(entry)
            } else if cal.isDate(entry.date, equalTo: now, toGranularity: .month) {
                earlierThisMonth.append(entry)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                let key = formatter.string(from: entry.date)
                if byMonth[key] == nil {
                    monthOrder.append(key)
                }
                byMonth[key, default: []].append(entry)
            }
        }

        var sections: [EntrySection] = []
        if !today.isEmpty { sections.append(EntrySection(title: "Today", entries: today)) }
        if !yesterday.isEmpty { sections.append(EntrySection(title: "Yesterday", entries: yesterday)) }
        if !thisWeek.isEmpty { sections.append(EntrySection(title: "This Week", entries: thisWeek)) }
        if !earlierThisMonth.isEmpty { sections.append(EntrySection(title: "Earlier This Month", entries: earlierThisMonth)) }
        for month in monthOrder {
            if let entries = byMonth[month] {
                sections.append(EntrySection(title: month, entries: entries))
            }
        }

        return sections
    }
}

#Preview {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)

    let entries = [
        RRJournalEntry(userId: UUID(), date: Date(), mode: "journal", content: "Today I reflected on my progress and felt grateful.", prompt: "What are you grateful for?"),
        RRJournalEntry(userId: UUID(), date: Date().addingTimeInterval(-86400), mode: "freeform", content: "Yesterday was tough but I stayed focused on my recovery goals."),
        RRJournalEntry(userId: UUID(), date: Date().addingTimeInterval(-172800), mode: "prompted", content: "Working through step four has been revealing.", prompt: "How is your step work going?"),
        RRJournalEntry(userId: UUID(), date: Date().addingTimeInterval(-604800), mode: "jotting", content: "Quick thought: I need to call my sponsor more often."),
    ]

    for entry in entries {
        container.mainContext.insert(entry)
    }

    return NavigationStack {
        JournalHistoryView()
    }
    .modelContainer(container)
}
