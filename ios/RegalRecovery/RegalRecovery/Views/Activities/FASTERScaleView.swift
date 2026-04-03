import SwiftUI
import SwiftData

struct FASTERScaleView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var viewModel = FASTERScaleViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch viewModel.currentPhase {
                case .mood:
                    FASTERMoodPromptView { score in
                        viewModel.selectMood(score)
                    }

                case .scale:
                    scalePhase

                case .results:
                    if let assessed = viewModel.assessedStage {
                        FASTERResultsView(
                            assessedStage: assessed,
                            selectedIndicators: viewModel.selectedIndicators,
                            journalInsight: $viewModel.journalInsight,
                            journalWarning: $viewModel.journalWarning,
                            journalFreeText: $viewModel.journalFreeText,
                            onSave: { saveCheckIn() }
                        )
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
    }

    // MARK: - Scale Phase

    private var scalePhase: some View {
        VStack(spacing: 20) {
            // Info header
            VStack(spacing: 4) {
                Text("What are you experiencing?")
                    .font(RRFont.title3)
                    .foregroundStyle(Color.rrText)
                Text("Tap a stage to expand it, then select any indicators that apply.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            // Accordion cards
            VStack(spacing: 10) {
                ForEach(FASTERStage.allCases) { stage in
                    FASTERStageCardView(
                        stage: stage,
                        isExpanded: viewModel.isExpanded(stage: stage),
                        selectedCount: viewModel.selectedCount(for: stage),
                        isIndicatorSelected: { viewModel.isIndicatorSelected(stage: stage, indicator: $0) },
                        onToggleExpand: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.toggleExpanded(stage: stage)
                            }
                        },
                        onToggleIndicator: { indicator in
                            viewModel.toggleIndicator(stage: stage, indicator: indicator)
                        }
                    )
                }
            }
            .padding(.horizontal)

            // Submit button
            RRButton("Complete Check-In", icon: "checkmark.circle") {
                viewModel.submit()
            }
            .opacity(viewModel.canSubmit ? 1 : 0.4)
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal)
        }
    }

    // MARK: - Persistence

    private func saveCheckIn() {
        guard let assessed = viewModel.assessedStage else { return }
        let userId = users.first?.id ?? UUID()

        let entry = RRFASTEREntry(
            userId: userId,
            date: Date(),
            assessedStage: assessed.rawValue,
            moodScore: viewModel.moodScore ?? 3,
            selectedIndicators: viewModel.allSelectedIndicatorStrings,
            journalInsight: viewModel.journalInsight,
            journalWarning: viewModel.journalWarning,
            journalFreeText: viewModel.journalFreeText
        )
        modelContext.insert(entry)
        viewModel.reset()
    }
}

#Preview {
    NavigationStack {
        FASTERScaleView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
