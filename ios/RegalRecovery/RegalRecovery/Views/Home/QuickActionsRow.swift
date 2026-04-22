import SwiftUI
import SwiftData

struct QuickActionsRow: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = QuickActionsViewModel()
    @State private var showFASTER = false
    @State private var showTriggerLog = false
    @State private var showCustomize = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: String(localized: "Quick Actions"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.items) { item in
                        if item.definition.presentationStyle == .fullScreenCover {
                            Button {
                                if item.definition.id == ActivityType.fasterScale.rawValue {
                                    showFASTER = true
                                } else if item.definition.id == ActivityType.triggerLog.rawValue {
                                    showTriggerLog = true
                                }
                            } label: {
                                quickActionLabel(item.definition.shortTitle, icon: item.definition.icon)
                            }
                        } else {
                            NavigationLink {
                                ActivityDestinationView(activityType: item.definition.id)
                            } label: {
                                quickActionLabel(item.definition.shortTitle, icon: item.definition.icon)
                            }
                        }
                    }

                    Button {
                        showCustomize = true
                    } label: {
                        Image(systemName: "pencil.circle")
                            .font(.body)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .foregroundStyle(Color.rrTextSecondary)
                            .background(Color.rrPrimary.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFASTER) {
            FASTERCheckInFlowView()
        }
        .fullScreenCover(isPresented: $showTriggerLog) {
            TriggerLogView()
        }
        .sheet(isPresented: $showCustomize, onDismiss: {
            viewModel.load(context: modelContext)
        }) {
            QuickActionsCustomizeView(viewModel: viewModel)
        }
        .task {
            viewModel.load(context: modelContext)
        }
    }

    private func quickActionLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(RRFont.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .foregroundStyle(Color.rrPrimary)
        .background(Color.rrPrimary.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        QuickActionsRow()
            .padding()
            .background(Color.rrBackground)
            .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
    }
}
