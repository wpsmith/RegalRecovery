import SwiftUI
import SwiftData

/// Work Screen entry point -- lets the user choose an affirmation pack
/// (including a dynamically-built "Favorites" pack) then navigates
/// into the existing AffirmationDeckView for card-swiping.
struct AffirmationPackPickerView: View {
    @Query(sort: \RRAffirmationFavorite.createdAt)
    private var favorites: [RRAffirmationFavorite]

    @State private var showSettings = false

    private var settings: AffirmationSettingsManager { .shared }

    // MARK: - Ordered Packs

    private var orderedPacks: [AffirmationPack] {
        let order = settings.packOrder
        return order.compactMap { name in
            ContentData.affirmationPacks.first { $0.name == name }
        }
    }

    // MARK: - Favorites Pack

    private var favoritesAffirmations: [Affirmation] {
        let order = settings.favoriteOrder
        if order.isEmpty {
            // Fall back to createdAt order (already sorted by @Query)
            return favorites.map {
                Affirmation(text: $0.affirmationText, scripture: $0.scripture, isFavorite: true)
            }
        }
        // Build ordered list: known order first, then any not in order list
        var ordered: [Affirmation] = []
        var remaining = favorites
        for id in order {
            if let idx = remaining.firstIndex(where: { $0.id == id }) {
                let fav = remaining.remove(at: idx)
                ordered.append(
                    Affirmation(text: fav.affirmationText, scripture: fav.scripture, isFavorite: true)
                )
            }
        }
        // Append any favorites not in the saved order
        for fav in remaining {
            ordered.append(
                Affirmation(text: fav.affirmationText, scripture: fav.scripture, isFavorite: true)
            )
        }
        return ordered
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Favorites card (always visible)
                if favorites.isEmpty {
                    packCard(
                        name: "Favorites",
                        count: 0,
                        preview: "Tap the heart on any affirmation to add it here",
                        isFavorites: true
                    )
                } else {
                    NavigationLink {
                        AffirmationDeckView(
                            packName: "Favorites",
                            affirmations: favoritesAffirmations
                        )
                    } label: {
                        packCard(
                            name: "Favorites",
                            count: favorites.count,
                            preview: favorites.first?.affirmationText,
                            isFavorites: true
                        )
                    }
                    .buttonStyle(.plain)
                }

                // All content packs
                ForEach(orderedPacks) { pack in
                    NavigationLink {
                        AffirmationDeckView(
                            packName: pack.name,
                            affirmations: pack.affirmations
                        )
                    } label: {
                        packCard(
                            name: pack.name,
                            count: pack.count,
                            preview: pack.affirmations.first?.text,
                            isFavorites: false
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.rrBackground)
        .navigationTitle("Affirmations")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                AffirmationSettingsView()
            }
        }
    }

    // MARK: - Pack Card

    private func packCard(
        name: String,
        count: Int,
        preview: String?,
        isFavorites: Bool
    ) -> some View {
        RRCard {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isFavorites
                              ? Color.rrDestructive.opacity(0.15)
                              : Color.rrPrimary.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: isFavorites ? "heart.fill" : "text.quote")
                        .font(.title3)
                        .foregroundStyle(isFavorites ? Color.rrDestructive : Color.rrPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(name)
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                        RRBadge(
                            text: "\(count)",
                            color: isFavorites ? .rrDestructive : .rrSecondary
                        )
                    }

                    if let preview {
                        Text("\"\(preview)\"")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(2)
                            .italic()
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AffirmationPackPickerView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
