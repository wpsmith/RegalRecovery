import SwiftUI

struct MotivationSurfacingCard: View {
    let motivation: RRMotivation
    let framing: String?
    var onTap: (() -> Void)?

    init(motivation: RRMotivation, framing: String? = nil, onTap: (() -> Void)? = nil) {
        self.motivation = motivation
        self.framing = framing
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            RRCard {
                VStack(alignment: .leading, spacing: 12) {
                    if let framing {
                        Text(framing)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: motivation.motivationCategory.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(motivation.motivationCategory.color)

                        Text(motivation.motivationCategory.displayName)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Text(motivation.text)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.leading)

                    if let scripture = motivation.scriptureReference {
                        Text("— \(scripture)")
                            .font(RRFont.caption)
                            .italic()
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Motivation: \(motivation.text). Category: \(motivation.motivationCategory.displayName). Importance: \(motivation.importanceRating) of 5."))
        .accessibilityHint(Text("Double tap to view details"))
    }
}

#Preview {
    MotivationSurfacingCard(
        motivation: RRMotivation(
            userId: UUID(),
            text: "My daughter deserves a father who keeps his promises.",
            category: .relational,
            importanceRating: 5,
            scriptureReference: "Proverbs 22:6"
        ),
        framing: "Remember Your Why"
    )
    .padding()
}
