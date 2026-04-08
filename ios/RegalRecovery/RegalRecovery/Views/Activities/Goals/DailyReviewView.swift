import SwiftUI

/// End-of-day review view (AC-ED-2 through AC-ED-5).
/// Shows uncompleted goals with disposition options and an optional reflection prompt.
struct DailyReviewView: View {
    @Bindable var viewModel: WeeklyDailyGoalsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary header
                    reviewSummary

                    // AC-ED-2: Uncompleted goal dispositions
                    if !viewModel.uncompletedGoals.isEmpty {
                        uncomletedGoalsSection
                    } else {
                        allCompletedView
                    }

                    // AC-ED-4: Reflection prompt
                    reflectionSection
                }
                .padding()
            }
            .navigationTitle("End-of-Day Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        Task {
                            isSubmitting = true
                            try? await viewModel.submitDailyReview()
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .disabled(isSubmitting || hasUnresolvedGoals)
                }
            }
        }
    }

    private var hasUnresolvedGoals: Bool {
        let unresolvedCount = viewModel.uncompletedGoals.filter { goal in
            viewModel.dispositions[goal.id] == nil
        }.count
        return unresolvedCount > 0
    }

    // MARK: - Summary

    private var reviewSummary: some View {
        VStack(spacing: 8) {
            Text("\(viewModel.dailyCompletedCount) of \(viewModel.dailyTotalCount) completed")
                .font(.title2.bold())

            ProgressView(value: viewModel.dailyCompletionPercentage)
                .tint(viewModel.dailyCompletionPercentage >= 0.8 ? Color.rrSuccess : Color.rrPrimary)
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Uncompleted Goals

    private var uncomletedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uncompleted Goals")
                .font(.headline)

            ForEach(viewModel.uncompletedGoals) { goal in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ForEach(goal.dynamics) { dynamic in
                            Image(systemName: dynamic.icon)
                                .font(.caption)
                                .foregroundStyle(Color.rrPrimary)
                        }
                        Text(goal.text)
                            .font(.subheadline)
                        Spacer()
                    }

                    // AC-ED-2: Disposition options
                    HStack(spacing: 8) {
                        dispositionButton(for: goal, action: .carryToTomorrow, label: "Tomorrow", icon: "arrow.uturn.forward")
                        dispositionButton(for: goal, action: .skipped, label: "Skipped", icon: "forward.end")
                        dispositionButton(for: goal, action: .noLongerRelevant, label: "Remove", icon: "xmark")
                    }
                }
                .padding()
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func dispositionButton(for goal: GoalInstance, action: DispositionAction, label: String, icon: String) -> some View {
        let isSelected = viewModel.dispositions[goal.id] == action
        return Button {
            viewModel.dispositions[goal.id] = action
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.rrPrimary : Color.rrSurface)
            .foregroundStyle(isSelected ? .white : Color.rrText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.rrPrimary.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - All Completed

    private var allCompletedView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.rrSuccess)
            Text("All goals completed!")
                .font(.headline)
                .foregroundStyle(Color.rrText)
            Text("Great work on your recovery today.")
                .font(.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Reflection (AC-ED-4, AC-ED-5)

    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reflection")
                .font(.headline)

            Text("What made today's goals easy or hard to complete?")
                .font(.subheadline)
                .foregroundStyle(Color.rrTextSecondary)

            TextField("Optional reflection...", text: $viewModel.reviewReflection, axis: .vertical)
                .lineLimit(3...8)
                .textFieldStyle(.roundedBorder)
        }
    }
}
