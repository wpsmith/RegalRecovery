import SwiftUI
import SwiftData

/// Compact card for the Today screen showing affirmation session status
/// and cumulative session count. Per AFF-FR-004 this card NEVER displays
/// streaks or consecutive-day counters -- only cumulative totals.
struct AffirmationTodayCard: View {
    @Query(
        filter: #Predicate<RRActivity> { $0.activityType == "Affirmation Log" },
        sort: \RRActivity.date,
        order: .reverse
    )
    private var sessions: [RRActivity]

    @Query(sort: \RRAffirmationFavorite.createdAt, order: .reverse)
    private var favorites: [RRAffirmationFavorite]

    private let calendar = Calendar.current

    // MARK: - Computed Properties

    private var hasTodaySession: Bool {
        sessions.contains { calendar.isDateInToday($0.date) }
    }

    /// Cumulative session count -- NEVER streaks (clinical safety: AFF-FR-004).
    private var totalSessions: Int {
        sessions.count
    }

    /// Most recent affirmation text from favorites.
    private var recentAffirmationText: String? {
        favorites.first?.affirmationText
    }

    // MARK: - Body

    var body: some View {
        NavigationLink {
            if let packName = AffirmationSettingsManager.shared.packForToday(),
               let pack = ContentData.affirmationPacks.first(where: { $0.name == packName }) {
                AffirmationDeckView(packName: pack.name, affirmations: pack.affirmations)
            } else {
                AffirmationPackPickerView()
            }
        } label: {
            HStack(spacing: 12) {
                // Left icon
                ZStack {
                    Circle()
                        .fill(Color.rrPrimary.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "text.quote")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.rrPrimary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    // Title row with status badge
                    HStack {
                        Text("Affirmations")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        Spacer()

                        // Status badge
                        if hasTodaySession {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text("Done")
                                    .font(RRFont.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(Color.rrSuccess)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.rrSuccess.opacity(0.12))
                            .clipShape(Capsule())
                        } else {
                            Text("Not yet")
                                .font(RRFont.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.rrTextSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.rrTextSecondary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 8) {
                        if totalSessions > 0 {
                            Text(String(localized: "\(totalSessions) session\(totalSessions == 1 ? "" : "s") total"))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        if !favorites.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Color.rrDestructive)
                                Text("\(favorites.count)")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                    }

                    if let text = recentAffirmationText {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.rrDestructive)
                            Text("\"\(text)\"")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrText)
                                .lineLimit(1)
                                .italic()
                        }
                    }
                }

                // Disclosure indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
            .padding(14)
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        VStack(spacing: 16) {
            AffirmationTodayCard()
        }
        .padding()
        .background(Color.rrBackground)
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
