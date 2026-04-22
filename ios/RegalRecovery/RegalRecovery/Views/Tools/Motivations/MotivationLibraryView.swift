import SwiftUI
import SwiftData

struct MotivationLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRMotivation.importanceRating, order: .reverse) private var allMotivations: [RRMotivation]

    @State private var libraryViewModel = MotivationLibraryViewModel()
    @State private var showCaptureSheet = false
    @State private var showDiscovery = false

    var body: some View {
        NavigationStack {
            Group {
                if libraryViewModel.isEmpty {
                    emptyState
                } else {
                    motivationList
                }
            }
            .background(Color.rrBackground)
            .navigationTitle("Motivations")
            .toolbar {
                if !libraryViewModel.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showCaptureSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add motivation")
                    }
                }
            }
            .sheet(isPresented: $showCaptureSheet) {
                MotivationCaptureSheet(libraryViewModel: libraryViewModel)
            }
            .fullScreenCover(isPresented: $showDiscovery) {
                MotivationDiscoveryView(libraryViewModel: libraryViewModel)
            }
            .onAppear {
                libraryViewModel.motivations = allMotivations
            }
            .onChange(of: allMotivations) { _, newValue in
                libraryViewModel.motivations = newValue
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.orange)

            Text("Your recovery needs a reason that is yours. What are you fighting for?")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showDiscovery = true
            } label: {
                Label("Discover My Motivations", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.rrPrimary)
            .frame(minHeight: 44)
            .padding(.horizontal, 40)

            Button("Add one now") {
                showCaptureSheet = true
            }
            .font(RRFont.body)
            .foregroundStyle(Color.rrPrimary)
            .frame(minHeight: 44)

            Spacer()
        }
    }

    private var motivationList: some View {
        ScrollView {
            VStack(spacing: 0) {
                summaryBar
                    .padding()

                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    ForEach(libraryViewModel.groupedByCategory) { group in
                        Section {
                            ForEach(group.motivations, id: \.id) { motivation in
                                NavigationLink {
                                    MotivationDetailView(
                                        motivation: motivation,
                                        libraryViewModel: libraryViewModel
                                    )
                                } label: {
                                    motivationRow(motivation)
                                }
                                .buttonStyle(.plain)
                            }
                        } header: {
                            sectionHeader(group)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var summaryBar: some View {
        HStack {
            Text("\(libraryViewModel.totalCount) motivation\(libraryViewModel.totalCount == 1 ? "" : "s")")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
            Spacer()
            Button {
                showDiscovery = true
            } label: {
                Label("Discover More", systemImage: "sparkles")
                    .font(RRFont.caption)
            }
            .frame(minHeight: 44)
        }
    }

    private func sectionHeader(_ group: MotivationLibraryViewModel.CategoryGroup) -> some View {
        HStack(spacing: 8) {
            Image(systemName: group.category.icon)
                .foregroundStyle(group.category.color)
            Text(group.category.displayName)
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)
            Spacer()
            Text("\(group.motivations.count)")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.rrBackground)
    }

    private func motivationRow(_ motivation: RRMotivation) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(motivation.text)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { value in
                            Image(systemName: value <= motivation.importanceRating ? "flame.fill" : "flame")
                                .font(.caption2)
                                .foregroundStyle(value <= motivation.importanceRating ? Color.orange : Color.rrTextSecondary)
                        }
                    }

                    if let scripture = motivation.scriptureReference {
                        Text("— \(scripture)")
                            .font(RRFont.caption)
                            .italic()
                            .foregroundStyle(Color.rrTextSecondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Motivation: \(motivation.text). Importance: \(motivation.importanceRating) of 5. Double tap to view details.")
    }
}

#Preview {
    MotivationLibraryView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
