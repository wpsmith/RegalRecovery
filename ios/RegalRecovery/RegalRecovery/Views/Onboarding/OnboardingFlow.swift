import SwiftUI

struct OnboardingFlow: View {
    let onComplete: () -> Void

    @State private var currentPage = 0
    @State private var userName = ""
    @State private var userEmail = ""
    @State private var selectedAddictions: [(name: String, date: Date)] = [
        (name: "Sex Addiction (SA)", date: Date()),
        (name: "Pornography", date: Date())
    ]

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

                AddictionSetupView(selectedAddictions: $selectedAddictions) {
                    withAnimation { currentPage = 3 }
                }
                .tag(2)

                MotivationSetupView(
                    name: userName,
                    email: userEmail,
                    selectedAddictions: selectedAddictions
                ) {
                    withAnimation { currentPage = 4 }
                }
                .tag(3)

                PermissionsView(onComplete: onComplete)
                    .tag(4)
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
