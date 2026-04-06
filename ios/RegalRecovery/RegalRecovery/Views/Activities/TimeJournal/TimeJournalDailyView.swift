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

                // Emotion timeline (TJ-019) — only shown when entries have emotions
                if viewModel.entries.contains(where: { !$0.emotions.isEmpty }) {
                    EmotionTimelineView(
                        entries: viewModel.entries,
                        mode: viewModel.mode
                    )
                }
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

// MARK: - Emotion Timeline View (TJ-019)

/// Displays a horizontal graph of emotional intensity across time slots.
/// X-axis: time slots, Y-axis: max intensity (0-10), color-coded by primary emotion category.
struct EmotionTimelineView: View {
    let entries: [RRTimeJournalEntry]
    let mode: TimeJournalMode

    /// Data point for each slot that has emotions.
    private struct EmotionPoint: Identifiable {
        let id: Int  // slotIndex
        let slotIndex: Int
        let maxIntensity: Int
        let primaryCategory: String
        let color: Color
    }

    private var dataPoints: [EmotionPoint] {
        entries.compactMap { entry -> EmotionPoint? in
            let emotions = entry.emotions
            guard !emotions.isEmpty else { return nil }
            let maxIntensity = emotions.map(\.intensity).max() ?? 0
            // Primary emotion is the one with highest intensity
            let primary = emotions.max(by: { $0.intensity < $1.intensity })
            let category = primary?.category ?? ""
            let color = EmotionCatalog.categories.first { $0.name == category }?.color ?? .gray
            return EmotionPoint(
                id: entry.slotIndex,
                slotIndex: entry.slotIndex,
                maxIntensity: maxIntensity,
                primaryCategory: category,
                color: color
            )
        }
        .sorted { $0.slotIndex < $1.slotIndex }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emotion Timeline")
                .font(RRFont.headline)
                .foregroundStyle(.rrText)
                .padding(.horizontal, 16)

            if dataPoints.isEmpty {
                Text("No emotions recorded today")
                    .font(RRFont.caption)
                    .foregroundStyle(.rrTextSecondary)
                    .padding(.horizontal, 16)
            } else {
                emotionGraph
            }
        }
        .padding(.vertical, 12)
        .background(Color.rrSurface)
    }

    private var emotionGraph: some View {
        GeometryReader { geometry in
            let width = geometry.size.width - 32  // horizontal padding
            let height: CGFloat = 120
            let totalSlots = CGFloat(mode.slotsPerDay)
            let slotWidth = width / totalSlots

            ZStack(alignment: .bottomLeading) {
                // Y-axis grid lines
                ForEach([2, 5, 8], id: \.self) { level in
                    let y = height - (CGFloat(level) / 10.0 * height)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.rrTextSecondary.opacity(0.15), lineWidth: 0.5)
                }

                // Connecting line
                if dataPoints.count > 1 {
                    Path { path in
                        for (index, point) in dataPoints.enumerated() {
                            let x = (CGFloat(point.slotIndex) + 0.5) * slotWidth
                            let y = height - (CGFloat(point.maxIntensity) / 10.0 * height)
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                }

                // Data points
                ForEach(dataPoints) { point in
                    let x = (CGFloat(point.slotIndex) + 0.5) * slotWidth
                    let y = height - (CGFloat(point.maxIntensity) / 10.0 * height)
                    Circle()
                        .fill(point.color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }
            }
            .frame(width: width, height: height)
        }
        .frame(height: 120)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        TimeJournalDailyView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
