import SwiftUI

struct PermissionsView: View {
    let onComplete: () -> Void

    @State private var notificationsEnabled = true
    @State private var biometricEnabled = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.rrSuccess)

            Text("You're Almost Ready")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)

            VStack(spacing: 16) {
                // Notifications toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $notificationsEnabled) {
                        Text("Enable Notifications")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                    }
                    .tint(Color.rrPrimary)

                    Text("Morning commitments, evening reviews, and affirmation reminders")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .padding()
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Biometric toggle
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: $biometricEnabled) {
                        Text("Enable Biometric Lock")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                    }
                    .tint(Color.rrPrimary)

                    Text("Protect your recovery data with Face ID or Touch ID")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .padding()
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 24)

            Spacer()

            RRButton("Let's Go!", icon: "arrow.right.circle.fill") {
                onComplete()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color.rrBackground.ignoresSafeArea())
    }
}

#Preview {
    PermissionsView(onComplete: {})
}
