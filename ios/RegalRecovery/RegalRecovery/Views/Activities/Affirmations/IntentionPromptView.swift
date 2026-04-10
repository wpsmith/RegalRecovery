import SwiftUI

struct IntentionPromptView: View {
    let prompt: String // "Today I choose to..."
    @Binding var text: String
    var onComplete: () -> Void
    var onSkip: () -> Void

    private let maxCharacters = 500

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Title
            Text("Daily Intention")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            // Prompt text
            Text(prompt)
                .font(.system(size: 20, weight: .medium))
                .italic()
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Text editor with placeholder
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Write your intention here...")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                }

                TextEditor(text: $text)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(minHeight: 120, maxHeight: 200)
            }
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.rrTextSecondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .onChange(of: text) { _, newValue in
                if newValue.count > maxCharacters {
                    text = String(newValue.prefix(maxCharacters))
                }
            }

            // Character counter
            Text("\(text.count)/\(maxCharacters)")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: onComplete) {
                    Text("Continue")
                        .font(RRFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.rrPrimary)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)

                Button(action: onSkip) {
                    Text("Skip")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(height: 44)
                }
            }
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
    }
}

#Preview {
    IntentionPromptView(
        prompt: "Today I choose to...",
        text: .constant(""),
        onComplete: {},
        onSkip: {}
    )
}
