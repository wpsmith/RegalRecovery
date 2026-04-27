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
    @State private var hasUnsavedChanges = false
    @State private var showCannotLeaveAlert = false
    @State private var newIndicatorTexts: [LBIDimensionType: String] = [:]

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

                    if !viewModel.isSelectionComplete {
                        selectionBanner
                    }

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
                    if selectedTab == 0 && hasUnsavedChanges {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { saveChanges() }
                                .fontWeight(.semibold)
                                .disabled(!viewModel.isSelectionComplete)
                        }
                    }
                }
                .interactiveDismissDisabled(!viewModel.isSelectionComplete)
                .navigationBarBackButtonHidden(!viewModel.isSelectionComplete && hasUnsavedChanges)
                .onAppear { reloadProfile() }
            }
        }
        .alert("Select 7 Check-In Items", isPresented: $showCannotLeaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You need exactly 7 starred indicators for your daily check-in. You currently have \(viewModel.selectedCount). Swipe right on an indicator to star it.")
        }
    }

    // MARK: - Selection Banner

    private var selectionBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            Text("\(viewModel.selectedCount) of 7 check-in items selected")
                .font(RRFont.callout)
                .fontWeight(.medium)
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(viewModel.selectedCount < 7 ? Color.orange : Color.rrSuccess)
    }

    // MARK: - Indicators Tab (editable with swipe)

    private var indicatorsTab: some View {
        List {
            ForEach(sortedDimensions, id: \.dimensionType) { dimension in
                Section {
                    ForEach(dimension.indicators) { indicator in
                        indicatorRow(dimension: dimension, indicator: indicator)
                    }

                    if dimension.indicators.count < 5 {
                        addIndicatorRow(dimensionType: dimension.dimensionType)
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: dimension.dimensionType.icon)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrPrimary)
                        Text(dimension.dimensionType.displayName)
                    }
                } footer: {
                    let starredInDimension = dimension.indicators.filter { viewModel.selectedCriticalIds.contains($0.id) }.count
                    if starredInDimension > 0 {
                        Text("\(starredInDimension) starred for check-in")
                            .font(RRFont.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            dimensionsWithNoIndicators
        }
        .listStyle(.insetGrouped)
        .contentMargins(.bottom, 80)
    }

    // MARK: - Indicator Row

    private func indicatorRow(dimension: LBIDimension, indicator: LBIIndicator) -> some View {
        let isStarred = viewModel.selectedCriticalIds.contains(indicator.id)

        return HStack(spacing: 12) {
            Image(systemName: isStarred ? "star.fill" : "circle.fill")
                .font(isStarred ? .callout : .system(size: 6))
                .foregroundStyle(isStarred ? .orange : Color.rrTextSecondary)
                .frame(width: 20)

            TextField("Indicator", text: Binding(
                get: { indicator.text },
                set: { newValue in
                    if newValue.count <= 200 {
                        viewModel.updateIndicator(
                            id: indicator.id,
                            in: dimension.dimensionType,
                            newText: newValue
                        )
                        hasUnsavedChanges = true
                    }
                }
            ))
            .font(RRFont.body)
            .foregroundStyle(Color.rrText)
        }
        .swipeActions(edge: .leading) {
            if !isStarred {
                Button {
                    withAnimation {
                        if viewModel.selectForCheckIn(indicatorId: indicator.id) {
                            hasUnsavedChanges = true
                        } else {
                            showCannotLeaveAlert = true
                        }
                    }
                } label: {
                    Label("Star", systemImage: "star.fill")
                }
                .tint(.orange)
            }
        }
        .swipeActions(edge: .trailing) {
            if isStarred {
                Button {
                    withAnimation {
                        viewModel.deselectFromCheckIn(indicatorId: indicator.id)
                        hasUnsavedChanges = true
                    }
                } label: {
                    Label("Unstar", systemImage: "star.slash")
                }
                .tint(.gray)
            } else {
                Button(role: .destructive) {
                    withAnimation {
                        viewModel.removeIndicator(id: indicator.id, from: dimension.dimensionType)
                        hasUnsavedChanges = true
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Add Indicator Row

    private func addIndicatorRow(dimensionType: LBIDimensionType) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.callout)
                .foregroundStyle(Color.rrPrimary)
                .frame(width: 20)

            TextField("Add indicator", text: Binding(
                get: { newIndicatorTexts[dimensionType] ?? "" },
                set: { newIndicatorTexts[dimensionType] = $0 }
            ))
            .font(RRFont.body)
            .foregroundStyle(Color.rrText)
            .onSubmit { addNewIndicator(to: dimensionType) }

            if let text = newIndicatorTexts[dimensionType], !text.isEmpty {
                Button {
                    addNewIndicator(to: dimensionType)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.rrPrimary)
                }
            }
        }
    }

    // MARK: - Empty Dimensions

    @ViewBuilder
    private var dimensionsWithNoIndicators: some View {
        let allTypes = LBIDimensionType.allCases.sorted { $0.sortOrder < $1.sortOrder }
        let existingTypes = Set(viewModel.dimensions.filter { !$0.indicators.isEmpty }.map { $0.dimensionType })
        let missingTypes = allTypes.filter { !existingTypes.contains($0) }

        if !missingTypes.isEmpty {
            ForEach(missingTypes, id: \.self) { dimensionType in
                Section {
                    addIndicatorRow(dimensionType: dimensionType)
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: dimensionType.icon)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(dimensionType.displayName)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                }
            }
        }
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

    private func addNewIndicator(to dimensionType: LBIDimensionType) {
        guard let text = newIndicatorTexts[dimensionType]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        viewModel.addIndicator(to: dimensionType, text: text)
        newIndicatorTexts[dimensionType] = ""
        hasUnsavedChanges = true
    }

    private func saveChanges() {
        guard let userId = users.first?.id else { return }
        viewModel.saveAll(context: modelContext, userId: userId)
        hasUnsavedChanges = false
    }

    private func reloadProfile() {
        guard let userId = users.first?.id else { return }
        viewModel.load(context: modelContext, userId: userId)
        hasUnsavedChanges = false
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
