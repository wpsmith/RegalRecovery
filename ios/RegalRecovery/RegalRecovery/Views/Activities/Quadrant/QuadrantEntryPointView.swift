import SwiftUI
import SwiftData

struct QuadrantEntryPointView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var vm = QuadrantDashboardViewModel()
    @State private var assessmentVM = QuadrantAssessmentViewModel()
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
                    QuadrantPsychoeducationView {
                        showPsychoeducation = false
                        isAssessing = true
                    } onSkip: {
                        showPsychoeducation = false
                    }
                }
            } else if isAssessing {
                QuadrantAssessmentFlowView(vm: assessmentVM) {
                    isAssessing = false
                    reload()
                }
            } else {
                NavigationStack {
                    QuadrantDashboardView(vm: vm) {
                        assessmentVM = QuadrantAssessmentViewModel()
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
    QuadrantEntryPointView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
