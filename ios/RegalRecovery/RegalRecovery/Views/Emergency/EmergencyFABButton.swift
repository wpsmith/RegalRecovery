import SwiftUI

struct EmergencyFABButton: View {
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.rrDestructive)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.rrDestructive.opacity(0.4), radius: 8, x: 0, y: 4)

                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }
        }
        .scaleEffect(isPulsing ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isPulsing)
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
                EmergencyFABButton(action: {})
                    .padding()
            }
        }
    }
}
