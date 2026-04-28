import SwiftUI
import SwiftData

struct QuadrantWeeklyReviewAssessmentFlowView: View {
    @Bindable var vm: QuadrantWeeklyReviewAssessmentViewModel
    let onDismiss: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                Group {
                    if vm.isAtSummary {
                        QuadrantWeeklyReviewSummaryView(vm: vm) {
                            saveAndDismiss()
                        } onBack: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                vm.previous()
                            }
                        }
                    } else if case .quadrant(let quadrant) = vm.currentStep {
                        QuadrantWeeklyReviewRatingView(
                            quadrant: quadrant,
                            score: Binding(
                                get: { vm.scores[quadrant] ?? 5 },
                                set: { vm.scores[quadrant] = $0 }
                            ),
                            indicators: Binding(
                                get: { vm.indicators[quadrant] ?? [] },
                                set: { vm.indicators[quadrant] = $0 }
                            ),
                            reflection: Binding(
                                get: { vm.reflections[quadrant] ?? "" },
                                set: { vm.reflections[quadrant] = $0 }
                            ),
                            onNext: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    vm.next()
                                }
                            },
                            onPrevious: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    vm.previous()
                                }
                            },
                            isFirstStep: vm.currentStep == .quadrant(.body),
                            isLastBeforeSummary: vm.currentStep == .quadrant(.spirit)
                        )
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: vm.currentStep)
            }
            .background(Color.rrBackground)
            .navigationTitle(String(localized: "Weekly Quadrant Review"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if vm.currentStep == .quadrant(.body) {
                            onDismiss()
                        } else {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                vm.previous()
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
    }

    private var progressBar: some View {
        VStack(spacing: 4) {
            ProgressView(value: vm.progress)
                .progressViewStyle(.linear)
                .tint(Color.rrPrimary)
        }
    }

    private func saveAndDismiss() {
        let userId = users.first?.id ?? UUID()
        vm.save(context: modelContext, userId: userId)
        onDismiss()
    }
}
