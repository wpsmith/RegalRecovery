import SwiftUI

// MARK: - Quarterly Review View

/// Guided review flow for periodically revisiting circle definitions.
///
/// Design:
/// - Prompt: "Recovery evolves -- do your circles still fit?"
/// - Step through each circle with reflection prompts
/// - Inline editing during review
/// - Summary of changes made
/// - Complete button
/// - Fully skippable, non-blocking
struct QuarterlyReviewView: View {

    let circleSet: CircleSet
    let apiClient: ThreeCirclesAPIClient

    @State private var currentStep: ReviewStep = .innerReview
    @State private var reviewId: String?
    @State private var changesApplied: [String] = []
    @State private var isStarting = false
    @State private var isCompleting = false
    @State private var showCompletion = false
    @State private var error: String?

    @Environment(\.dismiss) private var dismiss

    private var circleForStep: (CircleType, [CircleItem]) {
        switch currentStep {
        case .innerReview: return (.inner, circleSet.innerCircle)
        case .middleReview: return (.middle, circleSet.middleCircle)
        case .outerReview: return (.outer, circleSet.outerCircle)
        case .finalReview: return (.inner, []) // Not used for final
        }
    }

    private var stepIndex: Int {
        switch currentStep {
        case .innerReview: return 0
        case .middleReview: return 1
        case .outerReview: return 2
        case .finalReview: return 3
        }
    }

    private var totalSteps: Int { 4 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Progress Bar
                progressBar

                if showCompletion {
                    completionView
                } else if currentStep == .finalReview {
                    summaryView
                } else {
                    reflectionStep
                }
            }
            .background(Color.rrBackground)
            .navigationTitle("Quarterly Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if currentStep != .finalReview && !showCompletion {
                        Button("Next") {
                            advanceStep()
                        }
                    }
                }
            }
            .task {
                await startReview()
            }
            .alert("Error", isPresented: .constant(error != nil)) {
                Button("OK") { error = nil }
            } message: {
                Text(error ?? "")
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.rrTextSecondary.opacity(0.15))
                    .frame(height: 4)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.rrPrimary)
                    .frame(
                        width: geometry.size.width * CGFloat(stepIndex + 1) / CGFloat(totalSteps),
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.3), value: stepIndex)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    // MARK: - Reflection Step

    private var reflectionStep: some View {
        let (circleType, items) = circleForStep

        return ReviewReflectionView(
            circleType: circleType,
            items: items,
            onChangesRecorded: { changes in
                changesApplied.append(contentsOf: changes)
            }
        )
    }

    // MARK: - Summary View

    private var summaryView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.rrSuccess)

                Text("Review Summary")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                if changesApplied.isEmpty {
                    VStack(spacing: 8) {
                        Text("No changes made")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text("Your circles look good as they are. That's a healthy sign of stability in your recovery.")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Changes noted:")
                            .font(RRFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrText)

                        ForEach(changesApplied, id: \.self) { change in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrPrimary)
                                    .padding(.top, 2)
                                Text(change)
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }
                    .padding()
                    .background(Color.rrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer().frame(height: 16)

                RRButton(isCompleting ? "Completing..." : "Complete Review", icon: "checkmark") {
                    Task { await completeReview() }
                }
                .disabled(isCompleting)
                .padding(.horizontal)
            }
            .padding()
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(Color.rrPrimary)

            Text("Review Complete")
                .font(RRFont.largeTitle)
                .foregroundStyle(Color.rrText)

            Text("Your circles are up to date. Recovery is a process, and taking time to reflect is part of that process.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            RRButton("Done") {
                dismiss()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .padding()
    }

    // MARK: - Navigation

    private func advanceStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .innerReview: currentStep = .middleReview
            case .middleReview: currentStep = .outerReview
            case .outerReview: currentStep = .finalReview
            case .finalReview: break
            }
        }

        // Update review on server
        if let reviewId {
            Task {
                _ = try? await apiClient.updateReview(
                    reviewId: reviewId,
                    request: UpdateReviewRequest(
                        currentStep: currentStep,
                        changesApplied: changesApplied
                    )
                )
            }
        }
    }

    // MARK: - API Calls

    private func startReview() async {
        isStarting = true
        defer { isStarting = false }

        do {
            let response = try await apiClient.startReview(
                request: StartReviewRequest(setId: circleSet.setId)
            )
            reviewId = response.data.reviewId
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func completeReview() async {
        guard let reviewId else { return }
        isCompleting = true

        do {
            let summaryText = changesApplied.isEmpty
                ? "No changes needed."
                : "Updated \(changesApplied.count) item(s) during review."

            _ = try await apiClient.completeReview(
                reviewId: reviewId,
                request: CompleteReviewRequest(summary: summaryText)
            )

            withAnimation {
                showCompletion = true
            }
        } catch {
            self.error = error.localizedDescription
        }

        isCompleting = false
    }
}

#Preview {
    QuarterlyReviewView(
        circleSet: CircleSet(
            setId: "preview",
            userId: "user-1",
            name: "My Circles",
            recoveryArea: .sexPornography,
            frameworkPreference: nil,
            status: .active,
            innerCircle: [
                CircleItem(itemId: "i1", circle: .inner, behaviorName: "Pornography", notes: nil, specificityDetail: nil, category: nil, source: .user, flags: nil, createdAt: Date(), modifiedAt: nil),
                CircleItem(itemId: "i2", circle: .inner, behaviorName: "Masturbation", notes: nil, specificityDetail: nil, category: nil, source: .user, flags: nil, createdAt: Date(), modifiedAt: nil),
            ],
            middleCircle: [
                CircleItem(itemId: "m1", circle: .middle, behaviorName: "Isolating", notes: nil, specificityDetail: nil, category: nil, source: .user, flags: nil, createdAt: Date(), modifiedAt: nil),
            ],
            outerCircle: [
                CircleItem(itemId: "o1", circle: .outer, behaviorName: "Prayer", notes: nil, specificityDetail: nil, category: nil, source: .user, flags: nil, createdAt: Date(), modifiedAt: nil),
            ],
            versionNumber: 1,
            createdAt: Date(),
            modifiedAt: Date(),
            committedAt: Date()
        ),
        apiClient: ThreeCirclesAPIClient(apiClient: APIClient.shared)
    )
}
