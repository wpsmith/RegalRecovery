import SwiftData
import SwiftUI

enum ContentSection: String, CaseIterable {
    case affirmations = "Affirmations"
    case devotions = "Devotions"
    case prayer = "Prayer"
    case resources = "Resources"
}

struct ContentTabView: View {
    @State private var selectedSection: ContentSection = .affirmations
    @Query private var favorites: [RRAffirmationFavorite]
    @Query(sort: \RRDevotionalProgress.day) private var devotionalProgress: [RRDevotionalProgress]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top menu
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(ContentSection.allCases, id: \.self) { section in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedSection = section
                                }
                            } label: {
                                Text(section.rawValue)
                                    .font(RRFont.subheadline)
                                    .fontWeight(selectedSection == section ? .semibold : .regular)
                                    .foregroundStyle(selectedSection == section ? .white : Color.rrText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedSection == section ? Color.rrPrimary : Color.rrSurface)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.rrBackground)

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        switch selectedSection {
                        case .affirmations:
                            affirmationsContent
                        case .devotions:
                            devotionalContent
                        case .prayer:
                            prayerContent
                        case .resources:
                            resourcesContent
                        }
                    }
                    .padding()
                }
                .background(Color.rrBackground)
            }
        }
    }

    // MARK: - Affirmations

    private var affirmationsContent: some View {
        VStack(spacing: 24) {
            todaysAffirmationCard
            affirmationPacksSection
            favoritesSection
        }
    }

    private var todaysAffirmationCard: some View {
        let affirmation = ContentData.todaysAffirmation
        let acceptedPack = ContentData.affirmationPacks[0]

        return NavigationLink(destination: AffirmationDeckView(packName: acceptedPack.name, affirmations: acceptedPack.affirmations)) {
            RRCard {
                VStack(spacing: 16) {
                    HStack {
                        RRBadge(text: "Today's Affirmation", color: .rrPrimary)
                        Spacer()
                        Image(systemName: affirmation.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(Color.rrDestructive)
                    }

                    Text("\"\(affirmation.text)\"")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Text(affirmation.scripture)
                        .font(RRFont.callout)
                        .foregroundStyle(Color.rrTextSecondary)

                    HStack(spacing: 0) {
                        Spacer()
                        Text("Swipe through pack")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrPrimary)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.rrPrimary.opacity(0.15), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .allowsHitTesting(false)
                        .padding(-16)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var affirmationPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Packs")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ContentData.affirmationPacks) { pack in
                        NavigationLink(destination: AffirmationDeckView(packName: pack.name, affirmations: pack.affirmations)) {
                            packCard(pack)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func packCard(_ pack: AffirmationPack) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: packIcon(for: pack.name))
                .font(.title2)
                .foregroundStyle(Color.rrPrimary)

            Text(pack.name)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text("\(pack.count) affirmations")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(width: 140, alignment: .leading)
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func packIcon(for name: String) -> String {
        switch name {
        case "I Am Accepted": return "person.crop.circle.badge.checkmark"
        case "I Am Secure": return "lock.shield.fill"
        case "I Am Significant": return "star.fill"
        case "Morning Affirmations": return "sunrise.fill"
        case "Daily Faith": return "book.fill"
        case "AA Promises": return "hands.and.sparkles.fill"
        default: return "text.quote"
        }
    }

    private var favoriteAffirmations: [Affirmation] {
        if favorites.isEmpty {
            return ContentData.defaultFavoriteAffirmations
        }
        return favorites.map { fav in
            Affirmation(text: fav.affirmationText, scripture: fav.scripture, isFavorite: true)
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "My Favorites")

            VStack(spacing: 8) {
                ForEach(favoriteAffirmations) { affirmation in
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrDestructive)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(affirmation.text)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .lineLimit(1)

                            if !affirmation.scripture.isEmpty {
                                Text(affirmation.scripture)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.rrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    // MARK: - Devotions

    private var completedDays: Set<Int> {
        Set(devotionalProgress.compactMap { $0.completedAt != nil ? $0.day : nil })
    }

    private var currentDevotionalDay: Int {
        let completed = completedDays
        for day in 1...30 {
            if !completed.contains(day) { return day }
        }
        return 30
    }

    private var devotionalContent: some View {
        let currentDay = currentDevotionalDay
        let completed = completedDays
        let todayDevotional = ContentData.devotionalDays[safe: currentDay - 1]

        return VStack(spacing: 24) {
            NavigationLink(destination: DevotionalView()) {
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("30-Day Recovery Devotional")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        Text("Day \(currentDay) of 30")
                            .font(RRFont.callout)
                            .foregroundStyle(Color.rrPrimary)

                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(12), spacing: 4), count: 15), spacing: 4) {
                            ForEach(1...30, id: \.self) { day in
                                Circle()
                                    .fill(completed.contains(day) ? Color.rrSuccess : (day == currentDay ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3)))
                                    .frame(width: 10, height: 10)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Today: \(todayDevotional?.title ?? "")")
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                                Text(todayDevotional?.scripture ?? "")
                                    .font(RRFont.caption)
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
            .buttonStyle(.plain)
        }
    }

    // MARK: - Prayer

    private var prayerContent: some View {
        VStack(spacing: 0) {
            ForEach(ContentData.prayers) { prayer in
                NavigationLink(destination: PrayersView(prayer: prayer)) {
                    RRActivityRow(
                        icon: prayer.icon,
                        iconColor: .rrPrimary,
                        title: prayer.title,
                        subtitle: ""
                    )
                }
                .buttonStyle(.plain)

                if prayer.id != ContentData.prayers.last?.id {
                    Divider()
                        .padding(.leading, 40)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    // MARK: - Resources

    private var resourcesContent: some View {
        VStack(spacing: 0) {
            NavigationLink(destination: MeetingFinderView()) {
                resourceRow(icon: "map.fill", iconColor: .rrPrimary, title: "Meeting Finder", subtitle: "5 meetings nearby")
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink(destination: CrisisHotlinesView()) {
                resourceRow(icon: "phone.fill", iconColor: .rrDestructive, title: "Crisis Hotlines", subtitle: "SA Helpline, 988 Lifeline, RAINN")
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink(destination: GlossaryView()) {
                resourceRow(icon: "book.closed.fill", iconColor: .rrPrimary, title: "Glossary", subtitle: "FASTER, FANOS, FITNAP, PCI, and more")
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            resourceRow(icon: "play.rectangle.fill", iconColor: .blue, title: "Videos", subtitle: "12 recovery talks and testimonies")
            Divider().padding(.leading, 52)
            resourceRow(icon: "doc.text.fill", iconColor: .rrPrimary, title: "Articles", subtitle: "Understanding addiction and healing")
            Divider().padding(.leading, 52)
            resourceRow(icon: "headphones", iconColor: .purple, title: "Podcasts", subtitle: "Weekly recovery conversations")
            Divider().padding(.leading, 52)
            resourceRow(icon: "quote.bubble.fill", iconColor: .rrSecondary, title: "Blogs", subtitle: "Stories and insights from recovery")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func resourceRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                Text(subtitle)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    ContentTabView()
}
