import SwiftUI

struct EveningReflectionTextView: View {
    @Binding var text: String
    var onSave: () -> Void
    var onSkip: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Reflect on your day")
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Text("This is optional — write as much or as little as you'd like.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .scrollContentBackground(.hidden)
                    .padding(8)

                if text.isEmpty {
                    Text("What's on your mind...")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)

            VStack(spacing: 12) {
                Button(action: onSave) {
                    Text("Save")
                        .font(RRFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.rrPrimary)
                        .clipShape(Capsule())
                }

                Button(action: onSkip) {
                    Text("Skip")
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
    }
}

#Preview {
    @Previewable @State var text = ""
    EveningReflectionTextView(
        text: $text,
        onSave: {},
        onSkip: {}
    )
}
