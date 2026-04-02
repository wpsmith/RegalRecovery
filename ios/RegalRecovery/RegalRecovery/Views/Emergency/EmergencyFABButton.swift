import SwiftUI

struct EmergencyFABButton: View {
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPulsing = false
    @State private var isPressed = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.rrDestructive)
                .frame(width: 56, height: 56)
                .shadow(color: Color.rrDestructive.opacity(0.4), radius: 8, x: 0, y: 4)

            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
        }
        .scaleEffect(isPressed ? 0.9 : (isPulsing ? 1.05 : 1.0))
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
        .onTapGesture {
            onTap()
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    onLongPress()
                }
        )
        .onAppear {
            isPulsing = true
        }
    }
}

#Preview {
    ZStack {
        Color.rrBackground.ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                EmergencyFABButton(onTap: {}, onLongPress: {})
                    .padding()
            }
        }
    }
}
