import SwiftUI
import SwiftData

struct FASTERCheckInFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var viewModel = FASTERCheckInViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .mood:
                    FASTERMoodPromptView { score in
                        viewModel.selectMood(score)
                    }
                case .indicators:
                    FASTERIndicatorSelectionView(viewModel: viewModel)
                case .results:
                    FASTERResultsView(viewModel: viewModel) {
                        saveAndDismiss()
                    }
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if viewModel.isFirstStep {
                            dismiss()
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.goBack()
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }

    private func saveAndDismiss() {
        let userId = users.first?.id ?? UUID()
        viewModel.save(context: modelContext, userId: userId)
        dismiss()
    }
}

#Preview {
    FASTERCheckInFlowView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
