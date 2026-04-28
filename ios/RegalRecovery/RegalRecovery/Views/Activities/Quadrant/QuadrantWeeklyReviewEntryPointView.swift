import SwiftUI
import SwiftData

struct QuadrantWeeklyReviewEntryPointView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var vm = QuadrantWeeklyReviewDashboardViewModel()
    @State private var assessmentVM = QuadrantWeeklyReviewAssessmentViewModel()
    @State private var isAssessing = false
    @State private var showPsychoeducation = false
    @State private var didLoad = false

    var body: some View {
        Group {
            if !didLoad {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.rrBackground)
                    .onAppear { loadIfReady() }
            } else if showPsychoeducation && !isAssessing {
                NavigationStack {
                    QuadrantWeeklyReviewPsychoeducationView {
                        showPsychoeducation = false
                        isAssessing = true
                    } onSkip: {
                        showPsychoeducation = false
                    }
                }
            } else if isAssessing {
                QuadrantWeeklyReviewAssessmentFlowView(vm: assessmentVM) {
                    isAssessing = false
                    reload()
                }
            } else {
                NavigationStack {
                    QuadrantWeeklyReviewDashboardView(vm: vm) {
                        assessmentVM = QuadrantWeeklyReviewAssessmentViewModel()
                        if let userId = users.first?.id {
                            assessmentVM.load(context: modelContext, userId: userId)
                        }
                        isAssessing = true
                    }
                }
            }
        }
        .onChange(of: users.first?.id) { _, _ in
            loadIfReady()
        }
    }

    private func loadIfReady() {
        guard let userId = users.first?.id else { return }
        vm.load(context: modelContext, userId: userId)
        showPsychoeducation = !vm.hasEverAssessed
        didLoad = true
    }

    private func reload() {
        guard let userId = users.first?.id else { return }
        vm.load(context: modelContext, userId: userId)
    }
}

#Preview {
    QuadrantWeeklyReviewEntryPointView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
