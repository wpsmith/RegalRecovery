import SwiftData
import SwiftUI

enum ContentSection: String, CaseIterable {
    case affirmations = "Affirmations"
    case devotions = "Devotions"
    case resources = "Resources"
}

struct ContentTabView: View {
    @State private var selectedSection: ContentSection = .affirmations
    @Query private var favorites: [RRAffirmationFavorite]

    private func isFlagEnabled(_ key: String) -> Bool {
        FeatureFlagStore.shared.isEnabled(key)
    }

    private var enabledSections: [ContentSection] {
        ContentSection.allCases.filter { section in
            switch section {
            case .affirmations: return isFlagEnabled("activity.affirmations")
            case .devotions: return isFlagEnabled("activity.devotionals")
            case .resources: return isFlagEnabled("feature.content-resources")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if enabledSections.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.rrTextSecondary.opacity(0.4))
                        Text("No Content Available")
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)
                        Text("All content sections are currently disabled.")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    Spacer()
                } else {
                    // Top menu
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(enabledSections, id: \.self) { section in
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
                            case .resources:
                                resourcesContent
                            }
                        }
                        .padding()
                    }
                    .background(Color.rrBackground)
                }
            }
            .onAppear {
                if !enabledSections.contains(selectedSection), let first = enabledSections.first {
                    selectedSection = first
                }
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

    private var devotionalContent: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrPrimary.opacity(0.4))
            Text("Devotions Coming Soon")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
            Text("New devotional content is being prepared. Check back soon.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Resources

    private var resourcesContent: some View {
        VStack(spacing: 0) {
            if isFlagEnabled("feature.meeting-finder") {
                NavigationLink(destination: MeetingFinderView()) {
                    resourceRow(icon: "map.fill", iconColor: .rrPrimary, title: "Meeting Finder", subtitle: "5 meetings nearby")
                }
                .buttonStyle(.plain)
                Divider().padding(.leading, 52)
            }
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
            NavigationLink(destination: resourceComingSoonView(icon: "film", title: "Videos Coming Soon", description: "Video content is being prepared. Check back soon.")) {
                resourceRow(icon: "play.rectangle.fill", iconColor: .blue, title: "Videos", subtitle: "12 recovery talks and testimonies")
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink(destination: resourceComingSoonView(icon: "doc.text", title: "Articles Coming Soon", description: "Article content is being prepared. Check back soon.")) {
                resourceRow(icon: "doc.text.fill", iconColor: .rrPrimary, title: "Articles", subtitle: "Understanding addiction and healing")
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink(destination: resourceComingSoonView(icon: "headphones", title: "Podcasts Coming Soon", description: "Podcast content is being prepared. Check back soon.")) {
                resourceRow(icon: "headphones", iconColor: .purple, title: "Podcasts", subtitle: "Weekly recovery conversations")
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 52)
            NavigationLink(destination: resourceComingSoonView(icon: "text.book.closed", title: "Blogs Coming Soon", description: "Blog content is being prepared. Check back soon.")) {
                resourceRow(icon: "quote.bubble.fill", iconColor: .rrSecondary, title: "Blogs", subtitle: "Stories and insights from recovery")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }

    private func resourceComingSoonView(icon: String, title: String, description: String) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.rrPrimary.opacity(0.4))
            Text(title)
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
            Text(description)
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
