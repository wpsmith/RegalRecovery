import SwiftData
import SwiftUI

struct TimeJournalDailyView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TimeJournalViewModel?
    @State private var selectedSlotIndex: Int?
    @State private var showingQuickEntry = false

    var body: some View {
        Group {
            if let viewModel {
                dailyContent(viewModel: viewModel)
            } else {
                ProgressView()
                    .tint(.rrPrimary)
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Time Journal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = TimeJournalViewModel(modelContext: modelContext)
            }
        }
        .task {
            if let viewModel {
                await viewModel.loadDay(date: viewModel.currentDate)
            }
        }
    }

    @ViewBuilder
    private func dailyContent(viewModel: TimeJournalViewModel) -> some View {
        VStack(spacing: 0) {
            TimeJournalHeaderView(
                date: viewModel.currentDate,
                status: viewModel.dayStatus,
                completionPercent: viewModel.completionPercent,
                mode: viewModel.mode,
                onPreviousDay: { Task { await viewModel.navigateDay(offset: -1) } },
                onNextDay: { Task { await viewModel.navigateDay(offset: 1) } }
            )

            if viewModel.isLoading {
                Spacer()
                ProgressView()
                    .tint(.rrPrimary)
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.rrDestructive)
                    Text(error)
                        .font(RRFont.caption)
                        .foregroundStyle(.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                TimeJournalTimelineView(
                    viewModel: viewModel,
                    onSlotTapped: { index in
                        selectedSlotIndex = index
                        showingQuickEntry = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingQuickEntry) {
            // Placeholder for QuickEntrySheet (Agent 5)
            NavigationStack {
                VStack(spacing: 16) {
                    if let index = selectedSlotIndex {
                        Text("Quick Entry")
                            .font(RRFont.title)
                        Text(viewModel.mode.slotLabel(index: index))
                            .font(RRFont.body)
                            .foregroundStyle(.rrTextSecondary)
                    }
                    Text("Entry form coming soon")
                        .font(RRFont.caption)
                        .foregroundStyle(.rrTextSecondary)
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { showingQuickEntry = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    NavigationStack {
        TimeJournalDailyView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
