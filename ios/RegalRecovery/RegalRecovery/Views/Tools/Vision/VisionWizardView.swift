import SwiftUI
import SwiftData

struct VisionWizardView: View {
    @State var viewModel: VisionWizardViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var showResumeAlert = false

    init(editing vision: RRVisionStatement? = nil) {
        if let vision {
            _viewModel = State(initialValue: VisionWizardViewModel(editing: vision))
        } else {
            _viewModel = State(initialValue: VisionWizardViewModel())
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rrBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    progressBar
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)

                    stepContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if !isReviewStep {
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
                        viewModel.saveDraft()
                        dismiss()
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                }
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
                if viewModel.editingVisionId == nil && viewModel.hasSavedDraft {
                    showResumeAlert = true
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Step \(viewModel.currentStep.progressIndex) of \(VisionWizardStep.totalSteps)")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                Spacer()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrSurface)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrPrimary)
                        .frame(width: geometry.size.width * viewModel.currentStep.progressFraction, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep.progressFraction)
                }
            }
            .frame(height: 6)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .prompts(let index):
            VisionPromptsStepView(viewModel: viewModel, promptIndex: index)
        case .identity:
            VisionIdentityStepView(viewModel: viewModel)
        case .values:
            VisionValuesStepView(viewModel: viewModel)
        case .scripture:
            VisionScriptureStepView(viewModel: viewModel)
        case .review:
            VisionReviewStepView(viewModel: viewModel) {
                let userId = users.first?.id ?? UUID()
                viewModel.save(context: modelContext, userId: userId)
                dismiss()
            }
        }
    }

    private var isReviewStep: Bool {
        if case .review = viewModel.currentStep { return true }
        return false
    }

    private var navigationBar: some View {
        HStack(spacing: 12) {
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
            }

            Spacer()

            if viewModel.canSkip {
                Button {
                    viewModel.skipCurrentStep()
                } label: {
                    Text("Skip")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }

            Button {
                viewModel.goToNextStep()
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
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VisionWizardView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
