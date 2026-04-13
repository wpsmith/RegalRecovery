import SwiftUI

struct MorningSessionFlowView: View {
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
            await viewModel.startMorningSession()
        }
    }

    @ViewBuilder
    private var flowContent: some View {
        switch viewModel.currentStep {
        case .morningCard(let index):
            if let session = viewModel.morningSessionData,
               index < session.affirmations.count {
                AffirmationCardView(
                    affirmation: session.affirmations[index],
                    index: index,
                    total: session.affirmations.count,
                    onFavorite: {
                        Task { await viewModel.favoriteAffirmation(id: session.affirmations[index].id) }
                    },
                    onHide: {
                        Task { await viewModel.hideAffirmation(id: session.affirmations[index].id) }
                    },
                    onNext: { viewModel.advanceStep() },
                    onBack: { viewModel.goBack() }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
            }

        case .morningComplete:
            SessionCompleteView(
                sessionType: .morning,
                totalSessions: viewModel.completionData?.totalSessions,
                milestone: viewModel.completionData?.milestone,
                onDone: { dismiss() }
            )
            .transition(.move(edge: .trailing))

        default:
            EmptyView()
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Color.rrTextSecondary)
            Text(message)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel.startMorningSession() }
            }
            .font(RRFont.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(Color.rrPrimary)
            .clipShape(Capsule())

            Button("Close") { dismiss() }
                .font(RRFont.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .padding()
    }
}

#Preview {
    MorningSessionFlowView(
        viewModel: AffirmationSessionViewModel(
            apiClient: AffirmationsAPIClient(
                apiClient: APIClient(configuration: .local)
            )
        )
    )
}
