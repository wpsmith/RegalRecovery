import SwiftUI

struct TimeJournalTimelineView: View {
    let viewModel: TimeJournalViewModel
    let onSlotTapped: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(0..<viewModel.mode.slotsPerDay, id: \.self) { slotIndex in
                        TimeJournalSlotRow(
                            slotIndex: slotIndex,
                            mode: viewModel.mode,
                            entry: viewModel.entry(for: slotIndex),
                            status: viewModel.slotStatus(for: slotIndex),
                            isElapsed: viewModel.isSlotElapsed(slotIndex),
                            onTap: { onSlotTapped(slotIndex) }
                        )
                        .id(slotIndex)

                        if slotIndex < viewModel.mode.slotsPerDay - 1 {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .onAppear {
                let target = viewModel.currentSlotIndex
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(max(0, target - 1), anchor: .top)
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! RRModelConfiguration.makeContainer(inMemory: true)
    let viewModel = TimeJournalViewModel(modelContext: container.mainContext)
    TimeJournalTimelineView(viewModel: viewModel, onSlotTapped: { _ in })
}
