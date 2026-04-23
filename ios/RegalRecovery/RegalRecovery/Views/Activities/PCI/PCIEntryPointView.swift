import SwiftUI
import SwiftData

struct PCIEntryPointView: View {
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
                PCICheckInView()
            } else {
                PCISetupFlowView()
            }
        }
    }

    private func checkSetupStatus() {
        guard let userId = users.first?.id else {
            didCheck = true
            return
        }
        let uid = userId
        let descriptor = FetchDescriptor<RRPCIProfile>(
            predicate: #Predicate { $0.userId == uid && $0.isActive == true }
        )
        guard let profile = try? modelContext.fetch(descriptor).first else {
            didCheck = true
            return
        }
        let profileId = profile.id
        let versionDescriptor = FetchDescriptor<RRPCIProfileVersion>(
            predicate: #Predicate { $0.profileId == profileId }
        )
        let versions = (try? modelContext.fetch(versionDescriptor)) ?? []
        hasCompletedSetup = versions.contains { $0.versionNumber > 0 }
        didCheck = true
    }
}
