import SwiftUI
import SwiftData

struct FASTERScaleToolView: View {
    @Query(sort: \RRFASTEREntry.date, order: .reverse)
    private var fasterEntries: [RRFASTEREntry]

    @State private var selectedStage: FASTERStage = .forgettingPriorities

    /// Last 30 entries for the history dot strip
    private var recentHistory: [RRFASTEREntry] {
        Array(fasterEntries.prefix(30))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: - Stage Cards
                ForEach(FASTERStage.allCases) { stage in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedStage = stage
                        }
                    } label: {
                        stageCard(stage)
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - 30-Day History
                RRSectionHeader(title: "30-Day History")

                RRCard {
                    if recentHistory.isEmpty {
                        Text("No entries yet")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 4) {
                                ForEach(recentHistory) { entry in
                                    RRColorDot(FASTERStage(rawValue: entry.stage)?.color ?? .gray, size: 10)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.rrBackground)
    }

    private func stageCard(_ stage: FASTERStage) -> some View {
        let isSelected = selectedStage == stage

        return RRCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(stage.color.opacity(isSelected ? 1.0 : 0.2))
                        .frame(width: 44, height: 44)
                    Text(stage.letter)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? .white : stage.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stage.name)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Text(stage.description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(stage.color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? stage.color.opacity(0.15) : Color.clear
            )
        }
    }
}

#Preview {
    NavigationStack {
        FASTERScaleToolView()
    }
}
