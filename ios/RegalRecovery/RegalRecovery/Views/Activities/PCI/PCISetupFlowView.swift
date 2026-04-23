// Views/Activities/PCI/PCISetupFlowView.swift

import SwiftUI
import SwiftData

struct PCISetupFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var viewModel = PCISetupViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .psychoeducation:
                    PCIPsychoeducationView(onGetStarted: {
                        viewModel.startSetup()
                    })
                case .dimension:
                    PCIDimensionEntryView(viewModel: viewModel)
                case .criticalSelection:
                    PCICriticalSelectionView(viewModel: viewModel)
                case .confirmation:
                    PCISetupConfirmationView(viewModel: viewModel, onComplete: {
                        saveAndDismiss()
                    })
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if case .psychoeducation = viewModel.currentStep {
                            dismiss()
                        } else if case .dimension = viewModel.currentStep {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.previousDimension()
                            }
                        } else if case .criticalSelection = viewModel.currentStep {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.currentStep = .dimension(9)
                            }
                        } else if case .confirmation = viewModel.currentStep {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.backToCriticalSelection()
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
        .task {
            let userId = users.first?.id ?? UUID()
            let shouldContinue = viewModel.loadExistingProgress(context: modelContext, userId: userId)
            if !shouldContinue {
                // Setup already complete, dismiss
                dismiss()
            }
        }
    }

    private func saveAndDismiss() {
        let userId = users.first?.id ?? UUID()
        viewModel.save(context: modelContext, userId: userId)
        dismiss()
    }
}

#Preview {
    PCISetupFlowView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
