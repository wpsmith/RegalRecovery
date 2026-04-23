// Views/Activities/PCI/PCICheckInView.swift

import SwiftUI
import SwiftData
import UIKit

struct PCICheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var viewModel = PCICheckInViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if !viewModel.hasActiveProfile {
                    needsSetupView
                } else if !viewModel.setupComplete {
                    incompleteSetupView
                } else {
                    mainCheckInView
                }
            }
            .navigationTitle(String(localized: "Life Balance Check-In"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color.rrText)
                    }
                }
            }
            .task {
                let userId = users.first?.id ?? UUID()
                viewModel.load(context: modelContext, userId: userId)
            }
        }
    }

    // MARK: - Main Check-In View

    private var mainCheckInView: some View {
        VStack(spacing: 0) {
            // Header with date and score
            VStack(spacing: 16) {
                if viewModel.isEditingExisting {
                    editingBanner
                }

                // Date display
                Text(todayFormatted)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Large score display
                HStack(spacing: 12) {
                    Text(viewModel.scoreLabel)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)

                    Spacer()
                }

                Text(scoreDescription)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color.rrBackground)

            // Toggle list
            List {
                ForEach(viewModel.criticalItems) { item in
                    toggleRow(for: item)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.rrBackground)
            .contentMargins(.bottom, 80)

            // Save button
            VStack {
                RRButton(
                    String(localized: "Save"),
                    action: saveAndDismiss
                )
                .padding()
            }
            .background(Color.rrBackground)
        }
        .background(Color.rrBackground)
    }

    // MARK: - Toggle Row

    @ViewBuilder
    private func toggleRow(for item: PCICriticalItem) -> some View {
        let isToggled = viewModel.isItemToggled(item.id)

        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            viewModel.toggleItem(item.id)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayText)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.leading)

                    Text(item.dimensionType.shortName)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Spacer()

                Image(systemName: isToggled ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isToggled ? Color.rrDestructive : Color.rrTextSecondary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isToggled
                ? Color.rrDestructive.opacity(0.08)
                : Color.rrSurface
        )
    }

    // MARK: - State Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(String(localized: "Loading check-in..."))
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
    }

    private var needsSetupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 60))
                .foregroundStyle(Color.rrPrimary)

            VStack(spacing: 8) {
                Text(String(localized: "Setup Required"))
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text(String(localized: "You need to complete the Life Balance Inventory setup before you can do daily check-ins."))
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink(destination: PCISetupFlowView()) {
                Text(String(localized: "Start Setup"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.rrPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
    }

    private var incompleteSetupView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(Color.orange)

            VStack(spacing: 8) {
                Text(String(localized: "Setup Incomplete"))
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text(String(localized: "Your Life Balance Inventory setup is incomplete. Please complete the setup to start tracking."))
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            NavigationLink(destination: PCISetupFlowView()) {
                Text(String(localized: "Complete Setup"))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color.rrPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
    }

    private var editingBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "pencil.circle.fill")
                .foregroundStyle(Color.rrPrimary)
            Text(String(localized: "Editing today's check-in"))
                .font(RRFont.caption)
                .foregroundStyle(Color.rrText)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.rrPrimary.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: - Computed Properties

    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    private var scoreColor: Color {
        switch viewModel.dailyScore {
        case 0...2:
            return .rrSuccess
        case 3...4:
            return Color.orange
        default:
            return .rrDestructive
        }
    }

    private var scoreDescription: String {
        switch viewModel.dailyScore {
        case 0:
            return String(localized: "No warning signs today — excellent!")
        case 1...2:
            return String(localized: "Minimal risk — you're doing well")
        case 3...4:
            return String(localized: "Moderate concern — stay aware")
        case 5...6:
            return String(localized: "Higher risk — reach out for support")
        default:
            return String(localized: "Very high risk — connect with your recovery network")
        }
    }

    // MARK: - Actions

    private func saveAndDismiss() {
        let userId = users.first?.id ?? UUID()
        viewModel.save(context: modelContext, userId: userId)
        dismiss()
    }
}

#Preview {
    PCICheckInView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
