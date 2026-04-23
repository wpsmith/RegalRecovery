import SwiftUI
import SwiftData

struct LBIEntryPointView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var hasCompletedSetup = false
    @State private var didCheck = false
    @State private var showSetup = false

    var body: some View {
        Group {
            if !didCheck {
                ProgressView()
                    .onAppear { checkSetupStatus() }
            } else if hasCompletedSetup {
                LBICheckInView()
            } else {
                // Tell user to set up via Foundation Tools
                VStack(spacing: 20) {
                    Image(systemName: "checklist")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.rrTextSecondary)
                    Text("Set Up Life Balance First")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)
                    Text("Go to Work → Foundation Tools → Life Balance to define your personal indicators before you can do daily check-ins.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func checkSetupStatus() {
        guard let userId = users.first?.id else {
            didCheck = true
            return
        }
        let uid = userId
        let descriptor = FetchDescriptor<RRLBIProfile>(
            predicate: #Predicate { $0.userId == uid && $0.isActive == true }
        )
        guard let profile = try? modelContext.fetch(descriptor).first else {
            didCheck = true
            return
        }
        let profileId = profile.id
        let versionDescriptor = FetchDescriptor<RRLBIProfileVersion>(
            predicate: #Predicate { $0.profileId == profileId }
        )
        let versions = (try? modelContext.fetch(versionDescriptor)) ?? []
        hasCompletedSetup = versions.contains { $0.versionNumber > 0 }
        didCheck = true
    }
}
