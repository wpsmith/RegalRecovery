import SwiftUI

struct AffirmationCardView: View {
    let affirmation: AffirmationItem
    let index: Int
    let total: Int
    var onFavorite: (() -> Void)?
    var onHide: (() -> Void)?
    var onNext: (() -> Void)?
    var onBack: (() -> Void)?

    @State private var isFavorited: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Text(affirmation.text)
                .font(.system(size: 22, weight: .medium))
                .lineSpacing(22 * 0.6)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.rrText)
                .padding(.horizontal, 24)
                .accessibilityLabel(affirmation.text)

            Spacer()

            // Favorite and hide actions
            HStack(spacing: 32) {
                Button {
                    isFavorited.toggle()
                    onFavorite?()
                } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundStyle(isFavorited ? Color.rrDestructive : Color.rrTextSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(isFavorited ? "Unfavorite" : "Favorite")
                .accessibilityHint("Double tap to favorite")

                Button {
                    onHide?()
                } label: {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Hide this affirmation")
            }
            .padding(.bottom, 12)

            // Card index counter
            Text("\(index + 1) of \(total)")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.bottom, 16)

            // Navigation buttons
            HStack(spacing: 16) {
                if index > 0 {
                    Button {
                        onBack?()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(height: 44)
                        .padding(.horizontal, 16)
                    }
                }

                Spacer()

                Button {
                    onNext?()
                } label: {
                    HStack(spacing: 6) {
                        Text(index < total - 1 ? "Next" : "Continue")
                        Image(systemName: "chevron.right")
                    }
                    .font(RRFont.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(Color.rrPrimary)
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .onAppear {
            isFavorited = affirmation.isFavorite ?? false
        }
    }
}

#Preview {
    ZStack {
        Color.rrBackground.ignoresSafeArea()

        AffirmationCardView(
            affirmation: AffirmationItem(
                id: "preview-1",
                text: "I am worthy of love and connection, even when I feel broken.",
                level: 1,
                coreBeliefs: [1],
                category: .selfWorth,
                track: .standard,
                recoveryStage: .early,
                isFavorite: false,
                hasAudio: false
            ),
            index: 0,
            total: 3,
            onFavorite: {},
            onHide: {},
            onNext: {},
            onBack: {}
        )
        .padding(20)
    }
}
