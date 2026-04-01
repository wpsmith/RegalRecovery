import SwiftUI

struct AffirmationDeckView: View {
    let packName: String
    let affirmations: [Affirmation]

    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(Array(affirmations.enumerated()), id: \.element.id) { index, affirmation in
                    affirmationCard(affirmation, index: index + 1)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
        .background(Color.rrBackground)
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
