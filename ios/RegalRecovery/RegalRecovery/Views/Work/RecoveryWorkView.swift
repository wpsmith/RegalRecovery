import SwiftUI

struct RecoveryWorkView: View {
    @State private var viewModel = RecoveryWorkViewModel()
    @State private var showCompleted = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Due Now
                if !viewModel.dueNow.isEmpty {
                    Section {
                        ForEach(viewModel.dueNow) { item in
                            RecoveryWorkItemRow(item: item) {
                                viewModel.startItem(item)
                            }
                        }
                    } header: {
                        Label("Due Now", systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }

                // MARK: - This Week
                if !viewModel.thisWeek.isEmpty {
                    Section {
                        ForEach(viewModel.thisWeek) { item in
                            RecoveryWorkItemRow(item: item) {
                                viewModel.startItem(item)
                            }
                        }
                    } header: {
                        Text("This Week")
                    }
                }

                // MARK: - This Month
                if !viewModel.thisMonth.isEmpty {
                    Section {
                        ForEach(viewModel.thisMonth) { item in
                            RecoveryWorkItemRow(item: item) {
                                viewModel.startItem(item)
                            }
                        }
                    } header: {
                        Text("This Month")
                    }
                }

                // MARK: - Completed
                if !viewModel.completed.isEmpty {
                    Section(isExpanded: $showCompleted) {
                        ForEach(viewModel.completed) { item in
                            RecoveryWorkItemRow(item: item)
                        }
                    } header: {
                        Button {
                            withAnimation {
                                showCompleted.toggle()
                            }
                        } label: {
                            HStack {
                                Text("Completed (\(viewModel.completed.count))")
                                Spacer()
                                Image(systemName: showCompleted ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - Empty State
                if viewModel.dueNow.isEmpty && viewModel.thisWeek.isEmpty && viewModel.thisMonth.isEmpty {
                    Section {
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.rrSuccess)
                            Text("All caught up!")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Text("No recovery work items are pending right now.")
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80)
            }
            .navigationTitle("Recovery Work")
            .onAppear {
                viewModel.load()
            }
        }
    }
}

#Preview {
    RecoveryWorkView()
}
