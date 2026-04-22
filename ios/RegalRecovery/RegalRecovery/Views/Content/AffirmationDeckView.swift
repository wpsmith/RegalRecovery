import SwiftUI
import SwiftData

struct AffirmationDeckView: View {
    let packName: String
    let affirmations: [Affirmation]

    @Environment(\.modelContext) private var modelContext
    @Query private var users: [RRUser]

    @State private var currentIndex = 0
    @State private var sessionStartDate = Date()
    @State private var viewedIndices: Set<Int> = [0]
    @State private var hasLoggedSession = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                    affirmationCard(affirmation, index: index + 1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .onChange(of: currentIndex) { _, newIndex in
                viewedIndices.insert(newIndex)
            }
        }
        .background(Color.rrBackground)
        .onDisappear { logSession() }
    }

    private func logSession() {
        guard !hasLoggedSession else { return }
        let durationSeconds = Int(Date().timeIntervalSince(sessionStartDate))
        guard durationSeconds >= 3 else { return }
        let activity = RRActivity(
            userId: users.first?.id ?? UUID(),
            activityType: ActivityType.affirmationLog.rawValue,
            date: Date(),
            data: JSONPayload([
                "cardsViewed": AnyCodableValue.int(viewedIndices.count),
                "totalCards": AnyCodableValue.int(affirmations.count),
                "durationSeconds": AnyCodableValue.int(durationSeconds),
                "packName": AnyCodableValue.string(packName)
            ])
        )
        modelContext.insert(activity)
        hasLoggedSession = true
    }

    private func affirmationCard(_ affirmation: Affirmation, index: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text("\"\(affirmation.text)\"")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if !affirmation.scripture.isEmpty {
                Text(affirmation.scripture)
                    .font(RRFont.callout)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Button {
                // Toggle favorite — no-op in dummy app
            } label: {
                Image(systemName: affirmation.isFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(affirmation.isFavorite ? Color.rrDestructive : Color.rrTextSecondary)
            }

            Spacer()

            Text("\(index) of \(affirmations.count)")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.rrSurface)
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                .padding(.horizontal, 16)
                .padding(.vertical, 32)
        )
    }
}

#Preview {
    NavigationStack {
        AffirmationDeckView(
            packName: "I Am Accepted",
            affirmations: ContentData.affirmationPacks[0].affirmations
        )
    }
}
