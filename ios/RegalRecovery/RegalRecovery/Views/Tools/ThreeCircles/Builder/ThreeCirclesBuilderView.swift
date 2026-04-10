import SwiftUI

/// Main container for the Three Circles onboarding builder.
///
/// Manages step navigation, progress display, and the "I need support" escape hatch.
/// Switches between step-specific views based on the current builder step.
struct ThreeCirclesBuilderView: View {
    @State private var viewModel = ThreeCirclesBuilderViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showResumeAlert: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rrBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress indicator (shown after mode selection)
                    if shouldShowProgress {
                        progressBar
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                    }

                    // Step content
                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Navigation buttons
                    if shouldShowNavigation {
                        navigationBar
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                    }
                }
            }
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        if hasProgress {
                            viewModel.saveDraft()
                        }
                        dismiss()
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showSupportSheet = true
                    } label: {
                        Label("I need support", systemImage: "heart.circle")
                            .font(.body)
                            .foregroundStyle(Color.rrPrimary)
                    }
                    .accessibilityLabel("I need support")
                }
            }
            .sheet(isPresented: $viewModel.showSupportSheet) {
                SupportSheet()
            }
            .sheet(isPresented: $viewModel.showPauseSheet) {
                PausePointSheet(viewModel: viewModel)
            }
            .alert("Resume Previous Work?", isPresented: $showResumeAlert) {
                Button("Resume") {
                    _ = viewModel.resumeDraft()
                }
                Button("Start Fresh", role: .destructive) {
                    viewModel.clearDraft()
                }
            } message: {
                Text("You have a saved draft from a previous session. Would you like to continue where you left off?")
            }
            .onAppear {
                if viewModel.hasSavedDraft {
                    showResumeAlert = true
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
    }

    // MARK: - Progress Bar

    private var shouldShowProgress: Bool {
        BuilderStep.progressSteps.contains(viewModel.currentStep)
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            // Step counter
            HStack {
                Text("Step \(viewModel.currentProgressIndex) of \(viewModel.totalProgressSteps)")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrSurface)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrPrimary)
                        .frame(width: geometry.size.width * viewModel.progressFraction, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progressFraction)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .emotionalCheckin:
            EmotionalCheckinView(viewModel: viewModel)

        case .modeSelection:
            ModeSelectionView(viewModel: viewModel)

        case .recoveryArea:
            RecoveryAreaSelectionView(viewModel: viewModel)

        case .framework:
            FrameworkSelectionView(viewModel: viewModel)

        case .innerCircle:
            CircleBuildingView(viewModel: viewModel, circleType: .inner)

        case .outerCircle:
            CircleBuildingView(viewModel: viewModel, circleType: .outer)

        case .middleCircle:
            CircleBuildingView(viewModel: viewModel, circleType: .middle)

        case .review:
            ReviewCommitView(viewModel: viewModel) {
                dismiss()
            }
        }
    }

    // MARK: - Navigation Bar

    private var shouldShowNavigation: Bool {
        switch viewModel.currentStep {
        case .emotionalCheckin, .modeSelection, .review:
            return false
        default:
            return true
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
            // Back button
            if viewModel.canGoBack {
                Button {
                    viewModel.goToPreviousStep()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Back")
                            .font(RRFont.body)
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Go back")
            }

            Spacer()

            // Skip button
            if viewModel.canSkip {
                Button {
                    viewModel.skipCurrentStep()
                } label: {
                    Text("Skip")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityLabel("Skip this step")
            }

            // Next button
            Button {
                // Show pause point between circle building steps
                if shouldShowPausePoint {
                    viewModel.showPauseSheet = true
                } else {
                    viewModel.goToNextStep()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Next")
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(minHeight: 44)
                .background(viewModel.canProceed ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canProceed)
            .accessibilityLabel("Continue to next step")
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var hasProgress: Bool {
        !viewModel.innerCircleItems.isEmpty ||
        !viewModel.middleCircleItems.isEmpty ||
        !viewModel.outerCircleItems.isEmpty ||
        !viewModel.selectedRecoveryAreas.isEmpty
    }

    private var shouldShowPausePoint: Bool {
        switch viewModel.currentStep {
        case .innerCircle, .outerCircle:
            return true
        default:
            return false
        }
    }
}

// MARK: - Support Sheet

/// Shown when user taps "I need support" at any point during building.
private struct SupportSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.rrPrimary)
                        .padding(.top, 24)

                    Text("You Are Not Alone")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)

                    Text("Building your three circles can bring up difficult feelings. That is completely normal and shows courage.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    VStack(spacing: 12) {
                        supportOption(
                            icon: "phone.fill",
                            title: "Call Your Sponsor",
                            subtitle: "Reach out to your accountability partner"
                        )
                        supportOption(
                            icon: "person.2.fill",
                            title: "Find a Meeting",
                            subtitle: "Connect with your recovery community"
                        )
                        supportOption(
                            icon: "text.bubble.fill",
                            title: "Crisis Text Line",
                            subtitle: "Text HOME to 741741"
                        )
                        supportOption(
                            icon: "bookmark.fill",
                            title: "Save and Return Later",
                            subtitle: "Your progress will be saved"
                        )
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.rrBackground)
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func supportOption(icon: String, title: String, subtitle: String) -> some View {
        RRCard {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(Color.rrPrimary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Text(subtitle)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }
}

// MARK: - Pause Point Sheet

/// Shown between circle building steps to offer a break.
private struct PausePointSheet: View {
    let viewModel: ThreeCirclesBuilderViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.rrPrimary)

                Text("Nice Work So Far")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text("You have been doing meaningful work. Take a moment if you need one. Your progress is saved.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    RRButton("Continue Building", icon: "arrow.right") {
                        dismiss()
                        viewModel.goToNextStep()
                    }

                    Button {
                        viewModel.saveDraft()
                        dismiss()
                    } label: {
                        Text("Save and take a break")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                Spacer()
            }
            .background(Color.rrBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    ThreeCirclesBuilderView()
}
