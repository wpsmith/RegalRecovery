import SwiftUI

/// Final review and commit screen for the Three Circles builder.
///
/// Shows a concentric circles visualization with real items, expandable
/// sections per circle, inline editing, three commit options, and
/// guardrail/isolation nudges.
struct ReviewCommitView: View {
    let viewModel: ThreeCirclesBuilderViewModel
    let onDismiss: () -> Void

    @State private var expandedCircle: CircleType? = .inner
    @State private var showCommitOptions: Bool = false
    @State private var showCommitConfirmation: Bool = false
    @State private var selectedCommitOption: CommitOption?
    @State private var showShareNudge: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Concentric circles visualization
                circlesVisualization
                    .padding(.top, 8)

                // Circle sections
                circleSectionView(.inner, color: Color.rrDestructive)
                circleSectionView(.middle, color: .orange)
                circleSectionView(.outer, color: Color.rrSuccess)

                // Guardrail summary
                guardrailSummary

                // Commit section
                commitSection
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showCommitConfirmation) {
            commitConfirmationSheet
        }
    }

    // MARK: - Circles Visualization

    private var circlesVisualization: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.rrSuccess, lineWidth: 3)
                .frame(width: 260, height: 260)
            Text("\(viewModel.outerCircleItems.count)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(Color.rrSuccess)
                .offset(y: -140)
            Text("Outer")
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrSuccess)
                .offset(y: -126)

            // Middle circle
            Circle()
                .stroke(Color.orange, lineWidth: 3)
                .frame(width: 170, height: 170)
            Text("\(viewModel.middleCircleItems.count)")
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(.orange)
                .offset(y: -95)
            Text("Middle")
                .font(RRFont.caption2)
                .foregroundStyle(.orange)
                .offset(y: -81)

            // Inner circle
            Circle()
                .stroke(Color.rrDestructive, lineWidth: 3)
                .frame(width: 80, height: 80)
            VStack(spacing: 0) {
                Text("\(viewModel.innerCircleItems.count)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.rrDestructive)
                Text("Inner")
                    .font(RRFont.caption2)
                    .foregroundStyle(Color.rrDestructive)
            }
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Three circles: \(viewModel.innerCircleItems.count) inner, \(viewModel.middleCircleItems.count) middle, \(viewModel.outerCircleItems.count) outer items")
    }

    // MARK: - Circle Section

    private func circleSectionView(_ circleType: CircleType, color: Color) -> some View {
        let items = viewModel.items(for: circleType)
        let isExpanded = expandedCircle == circleType

        return VStack(spacing: 0) {
            // Section header
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedCircle = isExpanded ? nil : circleType
                }
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)

                    Text(circleType.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Spacer()

                    Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(circleType.displayName), \(items.count) items, \(isExpanded ? "expanded" : "collapsed")")

            // Expanded items
            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.horizontal)

                    if items.isEmpty {
                        emptyCircleMessage(circleType)
                            .padding()
                    } else {
                        VStack(spacing: 2) {
                            ForEach(items) { item in
                                reviewItemRow(item, circleType: circleType, color: color)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // Edit button
                    Button {
                        navigateToCircleEdit(circleType)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)
                            Text("Edit \(circleType.displayName)")
                                .font(RRFont.callout)
                        }
                        .foregroundStyle(color)
                        .frame(minHeight: 44)
                    }
                    .padding(.bottom, 8)
                }
                .transition(.opacity)
            }
        }
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }

    private func reviewItemRow(_ item: BuilderItem, circleType: CircleType, color: Color) -> some View {
        HStack(spacing: 10) {
            RRColorDot(color, size: 6)

            Text(item.behaviorName)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)

            Spacer()

            if item.isUncertain {
                Image(systemName: "questionmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Marked for sponsor review")
            }

            // Delete inline
            Button {
                viewModel.removeItem(from: circleType, item: item)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(Color.rrTextSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Remove \(item.behaviorName)")
        }
        .padding(.vertical, 4)
    }

    private func emptyCircleMessage(_ circleType: CircleType) -> some View {
        let message: String = {
            switch circleType {
            case .inner:
                return "No items yet. At least one inner circle item is needed to commit."
            case .middle:
                return "No items yet. Middle circle items often become clearer over time."
            case .outer:
                return "No items yet. Consider adding healthy practices to work toward."
            }
        }()

        return Text(message)
            .font(RRFont.caption)
            .foregroundStyle(Color.rrTextSecondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Guardrail Summary

    @ViewBuilder
    private var guardrailSummary: some View {
        let nudges = viewModel.guardrailNudges
        if !nudges.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.body)
                        .foregroundStyle(Color.rrPrimary)
                    Text("Review Notes")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }

                ForEach(nudges) { nudge in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: nudgeIcon(nudge.severity))
                            .font(.caption)
                            .foregroundStyle(nudgeColor(nudge.severity))

                        Text(nudge.message)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            .padding(.horizontal)
        }
    }

    // MARK: - Commit Section

    private var commitSection: some View {
        VStack(spacing: 14) {
            // Primary commit
            RRButton("Commit My Circles", icon: "checkmark.seal.fill") {
                selectedCommitOption = .commitNow
                showCommitConfirmation = true
            }
            .opacity(viewModel.innerCircleItems.isEmpty ? 0.5 : 1.0)
            .disabled(viewModel.innerCircleItems.isEmpty)
            .padding(.horizontal)

            // Save as draft + share
            Button {
                selectedCommitOption = .draft
                showShareNudge = true
                showCommitConfirmation = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Save Draft & Share with Sponsor")
                }
                .font(RRFont.body)
                .foregroundStyle(Color.rrPrimary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
            }
            .padding(.horizontal)

            // Save as draft only
            Button {
                selectedCommitOption = .draftNoShare
                showCommitConfirmation = true
            } label: {
                Text("Save as Draft")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(minHeight: 44)
            }

            // Isolation nudge
            if selectedCommitOption == .draftNoShare || showShareNudge == false {
                isolationNudge
            }

            // Error display
            if let error = viewModel.commitError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.rrDestructive)
                    Text(error)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrDestructive)
                }
                .padding(.horizontal)
            }
        }
    }

    private var isolationNudge: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.2.fill")
                .font(.caption)
                .foregroundStyle(Color.rrPrimary)

            Text("Recovery works best in community. Consider sharing your circles with your sponsor or accountability partner for feedback.")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(Color.rrPrimary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.horizontal)
    }

    // MARK: - Commit Confirmation Sheet

    private var commitConfirmationSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if viewModel.isCommitting {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Saving your circles...")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                } else {
                    Image(systemName: commitIcon)
                        .font(.system(size: 48))
                        .foregroundStyle(Color.rrPrimary)

                    Text(commitTitle)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text(commitMessage)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        RRButton("Confirm", icon: "checkmark") {
                            if let option = selectedCommitOption {
                                viewModel.commit(option: option)
                                // In production, the API call happens here.
                                // Simulate success for now.
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.commitCompleted(success: true)
                                    viewModel.clearDraft()
                                    showCommitConfirmation = false
                                    onDismiss()
                                }
                            }
                        }

                        Button("Go Back") {
                            showCommitConfirmation = false
                        }
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(minHeight: 44)
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
                Spacer()
            }
            .background(Color.rrBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { showCommitConfirmation = false }
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(viewModel.isCommitting)
    }

    // MARK: - Helpers

    private var commitIcon: String {
        switch selectedCommitOption {
        case .commitNow: return "checkmark.seal.fill"
        case .draft: return "square.and.arrow.up.fill"
        case .draftNoShare: return "doc.fill"
        case .none: return "doc.fill"
        }
    }

    private var commitTitle: String {
        switch selectedCommitOption {
        case .commitNow: return String(localized: "Commit Your Circles")
        case .draft: return String(localized: "Save & Share")
        case .draftNoShare: return String(localized: "Save as Draft")
        case .none: return String(localized: "Save")
        }
    }

    private var commitMessage: String {
        switch selectedCommitOption {
        case .commitNow:
            return String(localized: "Your circles will become active and used for daily check-ins. You can always edit them later.")
        case .draft:
            return String(localized: "Your circles will be saved as a draft. A share link will be generated for your sponsor to review and comment.")
        case .draftNoShare:
            return String(localized: "Your circles will be saved as a draft. You can commit or share them when you are ready.")
        case .none:
            return ""
        }
    }

    private func navigateToCircleEdit(_ circleType: CircleType) {
        switch circleType {
        case .inner: viewModel.goToStep(.innerCircle)
        case .middle: viewModel.goToStep(.middleCircle)
        case .outer: viewModel.goToStep(.outerCircle)
        }
    }

    private func nudgeIcon(_ severity: GuardrailNudge.Severity) -> String {
        switch severity {
        case .info: return "info.circle.fill"
        case .suggestion: return "lightbulb.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    private func nudgeColor(_ severity: GuardrailNudge.Severity) -> Color {
        switch severity {
        case .info: return Color.rrPrimary
        case .suggestion: return .orange
        case .warning: return Color.rrDestructive
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReviewCommitView(
            viewModel: {
                let vm = ThreeCirclesBuilderViewModel()
                vm.innerCircleItems = [
                    BuilderItem(behaviorName: "Viewing pornography"),
                    BuilderItem(behaviorName: "Masturbation"),
                    BuilderItem(behaviorName: "Acting out sexually"),
                ]
                vm.middleCircleItems = [
                    BuilderItem(behaviorName: "Isolating from others"),
                    BuilderItem(behaviorName: "Staying up late alone"),
                    BuilderItem(behaviorName: "Skipping meetings", isUncertain: true),
                ]
                vm.outerCircleItems = [
                    BuilderItem(behaviorName: "Daily prayer"),
                    BuilderItem(behaviorName: "Calling sponsor"),
                    BuilderItem(behaviorName: "Exercise"),
                    BuilderItem(behaviorName: "Attending meetings"),
                    BuilderItem(behaviorName: "Journaling"),
                ]
                return vm
            }(),
            onDismiss: {}
        )
    }
}
