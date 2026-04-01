import SwiftUI

struct OnboardingFlow: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var userName = ""
    @State private var userEmail = ""

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView(selection: $currentPage) {
                WelcomeView {
                    withAnimation { currentPage = 1 }
                }
                .tag(0)

                AccountSetupView(name: $userName, email: $userEmail) {
                    withAnimation { currentPage = 2 }
                }
                .tag(1)

                RecoverySetupView(name: $userName, email: $userEmail) {
                    withAnimation { currentPage = 3 }
                }
                .tag(2)

                PermissionsView(onComplete: onComplete)
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                onComplete()
            } label: {
                Text("Skip to Demo")
                    .font(RRFont.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.rrSurface)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
            .padding(.trailing, 16)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }
}

#Preview {
    OnboardingFlow(onComplete: {})
}
