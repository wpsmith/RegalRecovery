import SwiftUI

struct WelcomeView: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // App icon placeholder
            ZStack {
                Circle()
                    .fill(Color.rrPrimary)
                    .frame(width: 120, height: 120)

                Image(systemName: "cross.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 24)

            Text("Regal Recovery")
                .font(RRFont.largeTitle)
                .foregroundStyle(Color.rrText)

            Text("Your recovery companion")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)

            Spacer()

            RRButton("Get Started", icon: "arrow.right") {
                onNext()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .padding()
        .background(Color.rrBackground.ignoresSafeArea())
    }
}

#Preview {
    WelcomeView(onNext: {})
}
