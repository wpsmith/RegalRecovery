import SwiftUI

struct BowtieCompletionOverlay: View {
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var message: String = BowtieCompletionMessages.random()
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
                .accessibilityHidden(true)

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)

                Text(String(localized: "Session Complete"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.rrText)

                Text(message)
                    .font(.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button {
                    onDismiss()
                } label: {
                    Text(String(localized: "Done"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.rrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 32)
                .accessibilityLabel(String(localized: "Done"))
                .accessibilityHint(String(localized: "Double tap to dismiss"))
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.rrSurface)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
            .scaleEffect(appeared ? 1.0 : 0.8)
            .opacity(appeared ? 1.0 : 0.0)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(String(localized: "Session Complete. \(message)"))
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    appeared = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDismiss()
            }
        }
    }
}
