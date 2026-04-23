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
    @State private var viewModel = LBIProfileEditViewModel()
    @State private var showEditIndicators = false
    @State private var showEditCritical = false

    var body: some View {
        Group {
            if !didCheck {
                ProgressView()
                    .onAppear { checkSetupStatus() }
            } else if !hasCompletedSetup {
                LBISetupFlowView()
            } else {
                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("Indicators").tag(0)
                        Text("Trends").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.top, 8)

                    TabView(selection: $selectedTab) {
                        indicatorsTab
                            .tag(0)

                        trendsTab
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                .navigationTitle("Life Balance")
                .toolbar {
                    if selectedTab == 0 {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                Button {
                                    showEditIndicators = true
                                } label: {
                                    Label("Edit Indicators", systemImage: "pencil")
                                }
                                Button {
                                    showEditCritical = true
                                } label: {
                                    Label("Edit Check-In Items", systemImage: "star")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                        }
                    }
                }
                .sheet(isPresented: $showEditIndicators) {
                    LBIProfileEditView()
                        .onDisappear { reloadProfile() }
                }
                .sheet(isPresented: $showEditCritical) {
                    LBICriticalItemEditView()
                        .onDisappear { reloadProfile() }
                }
                .onAppear { reloadProfile() }
            }
        }
    }

    // MARK: - Indicators Tab (read-only with stars)

    private var indicatorsTab: some View {
        List {
            ForEach(sortedDimensions, id: \.dimensionType) { dimension in
                Section {
                    ForEach(dimension.indicators) { indicator in
                        HStack(spacing: 12) {
                            if viewModel.selectedCriticalIds.contains(indicator.id) {
                                Image(systemName: "star.fill")
                                    .font(.callout)
                                    .foregroundStyle(.orange)
                            } else {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .frame(width: 20)
                            }

                            Text(indicator.text)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: dimension.dimensionType.icon)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrPrimary)
                        Text(dimension.dimensionType.displayName)
                    }
                }
            }

            if !viewModel.criticalItems.isEmpty {
                Section {
                    ForEach(viewModel.criticalItems.sorted(by: { $0.sortOrder < $1.sortOrder })) { item in
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.callout)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.displayText)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                                Text(item.dimensionType.shortName)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(RRFont.caption)
                            .foregroundStyle(.orange)
                        Text("Daily Check-In Items (7)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 80)
    }

    // MARK: - Trends Tab

    private var trendsTab: some View {
        ScrollView {
            VStack(spacing: 24) {
                LBITrendChartView(entries: Array(lbiEntries), setupDate: profileSetupDate)
                LBICorrelationView(pciEntries: Array(lbiEntries), fasterEntries: Array(fasterEntries))
            }
            .padding()
            .padding(.bottom, 80)
        }
    }

    private var entriesSinceSetup: [RRLBIDailyEntry] {
        guard let setupDate = profileSetupDate else { return [] }
        return lbiEntries.filter { $0.date >= setupDate }
    }

    private var profileSetupDate: Date? {
        guard let userId = users.first?.id else { return nil }
        let uid = userId
        let desc = FetchDescriptor<RRLBIProfile>(
            predicate: #Predicate { $0.userId == uid && $0.isActive == true }
        )
        guard let profile = try? modelContext.fetch(desc).first else { return nil }
        let pid = profile.id
        let vDesc = FetchDescriptor<RRLBIProfileVersion>(
            predicate: #Predicate { $0.profileId == pid && $0.versionNumber > 0 },
            sortBy: [SortDescriptor(\.versionNumber)]
        )
        guard let firstVersion = try? modelContext.fetch(vDesc).first else { return nil }
        return Calendar.current.startOfDay(for: firstVersion.effectiveFrom)
    }

    // MARK: - Helpers

    private var sortedDimensions: [LBIDimension] {
        viewModel.dimensions
            .filter { !$0.indicators.isEmpty }
            .sorted { $0.dimensionType.sortOrder < $1.dimensionType.sortOrder }
    }

    private func reloadProfile() {
        guard let userId = users.first?.id else { return }
        viewModel.load(context: modelContext, userId: userId)
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
