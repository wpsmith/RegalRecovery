import SwiftUI

/// A card shown on the Today screen when the user has addictions but
/// no recovery plan yet.  Navigates to `RecoveryPlanSetupView`.
struct SetupMyPlanCard: View {
    var body: some View {
        NavigationLink {
            RecoveryPlanSetupView()
        } label: {
            RRCard {
                HStack(spacing: 14) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                        .foregroundStyle(Color.rrPrimary)
                        .frame(width: 44, height: 44)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Setup My Plan")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text("Create your daily recovery plan")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        SetupMyPlanCard()
            .padding()
    }
}
