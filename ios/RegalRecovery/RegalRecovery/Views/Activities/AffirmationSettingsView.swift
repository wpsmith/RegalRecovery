import SwiftUI
import SwiftData

/// Settings sheet for affirmation pack order, favorite order, and daily pack assignments.
struct AffirmationSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \RRAffirmationFavorite.createdAt)
    private var favorites: [RRAffirmationFavorite]

    @State private var packOrder: [String] = []
    @State private var favoriteOrder: [FavoriteItem] = []
    @State private var dailyAssignment: [Int: String] = [:]

    private var settings: AffirmationSettingsManager { .shared }

    // Day labels keyed by Calendar weekday (1=Sun, 7=Sat)
    private static let dayLabels: [(day: Int, label: String)] = [
        (1, "Sunday"), (2, "Monday"), (3, "Tuesday"), (4, "Wednesday"),
        (5, "Thursday"), (6, "Friday"), (7, "Saturday"),
    ]

    /// All available pack names for pickers (includes "None")
    private var packOptions: [String] {
        ["None"] + packOrder
    }

    // MARK: - Body

    var body: some View {
        List {
            packOrderSection
            if !favorites.isEmpty {
                favoriteOrderSection
            }
            dailyAssignmentSection
            resetSection
        }
        .navigationTitle("Affirmation Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    saveAndDismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            loadState()
        }
    }

    // MARK: - Pack Order Section

    private var packOrderSection: some View {
        Section {
            ForEach(packOrder, id: \.self) { name in
                HStack {
                    Text(name)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    let count = ContentData.affirmationPacks
                        .first { $0.name == name }?.count ?? 0
                    RRBadge(text: "\(count)", color: .rrSecondary)
                }
                .frame(minHeight: 44)
            }
            .onMove { source, destination in
                packOrder.move(fromOffsets: source, toOffset: destination)
            }
        } header: {
            Text("Pack Order")
        }
    }

    // MARK: - Favorite Order Section

    private var favoriteOrderSection: some View {
        Section {
            ForEach(favoriteOrder) { item in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\"\(item.text)\"")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .lineLimit(2)
                        .italic()
                    if !item.scripture.isEmpty {
                        Text(item.scripture)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
                .frame(minHeight: 44)
            }
            .onMove { source, destination in
                favoriteOrder.move(fromOffsets: source, toOffset: destination)
            }
        } header: {
            Text("Favorite Order")
        }
    }

    // MARK: - Daily Assignment Section

    private var dailyAssignmentSection: some View {
        Section {
            ForEach(Self.dayLabels, id: \.day) { entry in
                HStack {
                    Text(entry.label)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .frame(minHeight: 44)
                    Spacer()
                    Picker("", selection: dailyBinding(for: entry.day)) {
                        ForEach(packOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .labelsHidden()
                }
            }
        } header: {
            Text("Daily Pack Assignment")
        } footer: {
            Text("Assign a pack to each day to go directly to that pack from the Today screen.")
                .font(RRFont.caption)
        }
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                settings.resetToDefaults()
                loadState()
            } label: {
                HStack {
                    Spacer()
                    Text("Reset to Defaults")
                        .font(RRFont.body)
                        .fontWeight(.medium)
                    Spacer()
                }
                .frame(minHeight: 44)
            }
        }
    }

    // MARK: - Helpers

    private func dailyBinding(for day: Int) -> Binding<String> {
        Binding(
            get: { dailyAssignment[day] ?? "None" },
            set: { newValue in
                if newValue == "None" {
                    dailyAssignment.removeValue(forKey: day)
                } else {
                    dailyAssignment[day] = newValue
                }
            }
        )
    }

    private func loadState() {
        packOrder = settings.packOrder
        dailyAssignment = settings.dailyPackAssignment

        // Build favorite items from the saved order + query results
        let savedOrder = settings.favoriteOrder
        if savedOrder.isEmpty {
            favoriteOrder = favorites.map {
                FavoriteItem(id: $0.id, text: $0.affirmationText, scripture: $0.scripture)
            }
        } else {
            var items: [FavoriteItem] = []
            var remaining = favorites
            for id in savedOrder {
                if let idx = remaining.firstIndex(where: { $0.id == id }) {
                    let fav = remaining.remove(at: idx)
                    items.append(FavoriteItem(id: fav.id, text: fav.affirmationText, scripture: fav.scripture))
                }
            }
            for fav in remaining {
                items.append(FavoriteItem(id: fav.id, text: fav.affirmationText, scripture: fav.scripture))
            }
            favoriteOrder = items
        }
    }

    private func saveAndDismiss() {
        settings.packOrder = packOrder
        settings.favoriteOrder = favoriteOrder.map(\.id)
        settings.dailyPackAssignment = dailyAssignment
        settings.save()
        dismiss()
    }
}

// MARK: - Favorite Item (local view model)

private struct FavoriteItem: Identifiable {
    let id: UUID
    let text: String
    let scripture: String
}

#Preview {
    NavigationStack {
        AffirmationSettingsView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
