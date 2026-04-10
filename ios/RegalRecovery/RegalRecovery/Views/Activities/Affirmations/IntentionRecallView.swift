import SwiftUI

struct IntentionRecallView: View {
    let morningIntention: String? // nil if morning session was skipped
    var onContinue: () -> Void

    private var hasIntention: Bool {
        guard let morningIntention else { return false }
        return !morningIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if hasIntention, let morningIntention {
                VStack(spacing: 16) {
                    Text("This morning you said:")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    Text("\"\(morningIntention)\"")
                        .font(.system(size: 18, weight: .medium))
                        .italic()
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                Text("Take a moment to reflect on your day.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .font(RRFont.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rrPrimary)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
    }
}

#Preview("With Intention") {
    IntentionRecallView(
        morningIntention: "I will be patient with myself today.",
        onContinue: {}
    )
}

#Preview("No Intention") {
    IntentionRecallView(
        morningIntention: nil,
        onContinue: {}
    )
}
