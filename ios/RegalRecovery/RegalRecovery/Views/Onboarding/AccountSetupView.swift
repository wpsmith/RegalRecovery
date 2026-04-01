import SwiftUI

struct AccountSetupView: View {
    @Binding var name: String
    @Binding var email: String
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Create Your Account")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 48)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Name")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Your name", text: $name)
                        .font(RRFont.body)
                        .padding(12)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("Your email", text: $email)
                        .font(RRFont.body)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(12)
                        .background(Color.rrSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            VStack(spacing: 12) {
                Text("Sign in with")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)

                HStack(spacing: 12) {
                    socialButton(icon: "apple.logo", label: "Apple")
                    socialButton(icon: "g.circle", label: "Google")
                    socialButton(icon: "envelope.fill", label: "Email")
                }
            }

            Spacer()

            RRButton("Continue", icon: "arrow.right") {
                onNext()
            }
            .padding(.bottom, 48)
        }
        .padding(.horizontal, 24)
        .background(Color.rrBackground.ignoresSafeArea())
    }

    private func socialButton(icon: String, label: String) -> some View {
        Button {} label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.body)
                Text(label)
                    .font(RRFont.caption)
                    .fontWeight(.medium)
            }
            .foregroundStyle(Color.rrText)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .overlay(
                Capsule()
                    .stroke(Color.rrTextSecondary.opacity(0.4), lineWidth: 1)
            )
        }
    }
}

#Preview {
    AccountSetupView(name: .constant("Alex"), email: .constant("alex@example.com"), onNext: {})
}
