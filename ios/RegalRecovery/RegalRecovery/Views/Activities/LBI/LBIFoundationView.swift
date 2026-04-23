// Views/Activities/LBI/LBIFoundationView.swift

import SwiftUI
import SwiftData

struct LBIFoundationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @Query(sort: \RRLBIDailyEntry.date, order: .reverse) private var lbiEntries: [RRLBIDailyEntry]
    @Query(sort: \RRFASTEREntry.date, order: .reverse) private var fasterEntries: [RRFASTEREntry]

    @State private var selectedTab = 0
    @State private var hasCompletedSetup = false
    @State private var didCheck = false

    var body: some View {
        Group {
            if !didCheck {
                ProgressView()
                    .onAppear { checkSetupStatus() }
            } else if !hasCompletedSetup {
                LBISetupFlowView()
            } else {
                VStack(spacing: 0) {
                    // Segmented picker
                    Picker("", selection: $selectedTab) {
                        Text("Indicators").tag(0)
                        Text("Trends").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    TabView(selection: $selectedTab) {
                        // Tab 0: Indicators (profile edit)
                        LBIProfileEditView()
                            .tag(0)

                        // Tab 1: Trends
                        ScrollView {
                            VStack(spacing: 24) {
                                LBITrendChartView(entries: lbiEntries)
                                LBICorrelationView(pciEntries: lbiEntries, fasterEntries: fasterEntries)
                            }
                            .padding()
                            .padding(.bottom, 80)
                        }
                        .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .navigationTitle("Life Balance")
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

#Preview {
    NavigationStack {
        LBIFoundationView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
