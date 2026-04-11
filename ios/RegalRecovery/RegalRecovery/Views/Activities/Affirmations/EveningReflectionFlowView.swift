import SwiftUI

struct EveningReflectionFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: AffirmationSessionViewModel

    var body: some View {
        ZStack {
            Color.rrBackground.ignoresSafeArea()

            if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                errorView(error)
            } else {
                flowContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        .task {
            await viewModel.startEveningSession()
        }
    }

    // MARK: - Flow Content

    @ViewBuilder
    private var flowContent: some View {
        switch viewModel.currentStep {
        case .eveningAffirmation:
            eveningAffirmationStep

        case .eveningRating:
            DayRatingView(
                rating: $viewModel.dayRating,
                onContinue: { viewModel.advanceStep() }
            )

        case .eveningReflection:
            EveningReflectionTextView(
                text: $viewModel.reflectionText,
                onSave: { viewModel.advanceStep() },
                onSkip: { viewModel.advanceStep() }
            )

        case .eveningComplete:
            SessionCompleteView(
                sessionType: .evening,
                totalSessions: viewModel.completionData?.totalSessions,
                milestone: viewModel.completionData?.milestone,
                onDone: { dismiss() }
            )

        default:
            EmptyView()
        }
    }

    // MARK: - Evening Affirmation + Intention Recall

    @ViewBuilder
    private var eveningAffirmationStep: some View {
        if let session = viewModel.eveningSessionData {
            ScrollView {
                VStack(spacing: 24) {
                    AffirmationCardView(
                        affirmation: session.affirmation,
                        index: 0,
                        total: 1,
                        onFavorite: {
                            Task { await viewModel.favoriteAffirmation(id: session.affirmation.id) }
                        },
                        onHide: {
                            Task { await viewModel.hideAffirmation(id: session.affirmation.id) }
                        },
                        onNext: { viewModel.advanceStep() }
                    )
                    .frame(minHeight: 300)

                    IntentionRecallView(
                        morningIntention: session.morningIntention,
                        onContinue: { viewModel.advanceStep() }
                    )
                    .frame(minHeight: 200)
                }
                .padding(.vertical, 16)
            }
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrTextSecondary)

            Text(message)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.error = nil
                Task { await viewModel.startEveningSession() }
            } label: {
                Text("Try Again")
                    .font(RRFont.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .frame(height: 44)
                    .background(Color.rrPrimary)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    EveningReflectionFlowView(
        viewModel: {
            let vm = AffirmationSessionViewModel(
                apiClient: AffirmationsAPIClient(apiClient: APIClient(configuration: .local))
            )
            vm.eveningSessionData = EveningSessionData(
                sessionId: "preview-session",
                sessionType: .evening,
                affirmation: AffirmationItem(
                    id: "preview-1",
                    text: "Today I honored my recovery, and that is enough.",
                    level: 1,
                    coreBeliefs: [1],
                    category: .selfWorth,
                    track: .standard,
                    recoveryStage: .early,
                    isFavorite: false,
                    hasAudio: false
                ),
                morningIntention: "I will be patient with myself today.",
                ratingPrompt: nil,
                createdAt: nil
            )
            vm.currentStep = .eveningAffirmation
            return vm
        }()
    )
}
