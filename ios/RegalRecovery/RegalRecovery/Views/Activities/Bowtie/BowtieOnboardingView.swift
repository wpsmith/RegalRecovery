import SwiftUI
import SwiftData

struct BowtieOnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = BowtieOnboardingViewModel()
    @State private var swipeDirection: SwipeDirection = .forward

    private enum SwipeDirection {
        case forward, backward
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar

                Group {
                    switch viewModel.currentStep {
                    case .explanation:
                        explanationPage
                    case .visualMetaphor:
                        visualMetaphorPage
                    case .roleSetup:
                        roleSetupPage
                    case .triggerSetup:
                        triggerSetupPage
                    }
                }
                .id(viewModel.currentStep)
                .transition(reduceMotion ? .opacity : (swipeDirection == .forward
                    ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                    : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))))
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            if horizontal < -50 && !viewModel.isLastStep {
                                swipeDirection = .forward
                                if reduceMotion {
                                    viewModel.goForward()
                                } else {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.goForward()
                                    }
                                }
                            } else if horizontal > 50 && !viewModel.isFirstStep {
                                swipeDirection = .backward
                                if reduceMotion {
                                    viewModel.goBack()
                                } else {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.goBack()
                                    }
                                }
                            }
                        }
                )
            }
            .background(Color.rrBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.isFirstStep {
                        Button {
                            swipeDirection = .backward
                            if reduceMotion {
                                viewModel.goBack()
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.goBack()
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.rrText)
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Skip")) {
                        UserDefaults.standard.set(true, forKey: "bowtie.onboardingCompleted")
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.rrTextSecondary)
                }
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.rrSurface)
                Rectangle()
                    .fill(Color.rrPrimary)
                    .frame(width: geo.size.width * viewModel.progressFraction)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progressFraction)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Page 1: Explanation

    private var explanationPage: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                Image(systemName: "bowtie.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.rrPrimary)
                    .accessibilityHidden(true)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)

                VStack(spacing: 16) {
                    Text(String(localized: "What is the Bowtie Diagram?"))
                        .font(.title2.bold())
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "A tool to help you see what's been stirring in your heart \u{2014} and what's coming \u{2014} so you can meet your real needs instead of reaching for something that hurts you."))
                        .font(.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer()

                nextButton
            }
            .padding()
        }
    }

    // MARK: - Page 2: Visual Metaphor

    private var visualMetaphorPage: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 40)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.backward")
                        .font(.title3)
                        .foregroundStyle(Color.rrPrimary.opacity(0.6))
                    Image(systemName: "bowtie.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.rrPrimary)
                    Image(systemName: "arrow.forward")
                        .font(.title3)
                        .foregroundStyle(Color.rrPrimary.opacity(0.6))
                }
                .accessibilityHidden(true)

                VStack(spacing: 16) {
                    Text(String(localized: "Looking Back, Looking Ahead"))
                        .font(.title2.bold())
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "The left side looks back at the last 48 hours. The right side looks ahead at the next 48. You examine both through the lens of your life roles \u{2014} husband, father, friend, man in recovery."))
                        .font(.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                Spacer()

                nextButton
            }
            .padding()
        }
    }

    // MARK: - Page 3: Role Setup

    private var roleSetupPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(String(localized: "Set Up Your Roles"))
                        .font(.title2.bold())
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "Select the roles that are active in your life right now."))
                        .font(.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        FlowLayout(spacing: 8) {
                            ForEach(RoleSuggestions.defaults, id: \.self) { role in
                                toggleChip(
                                    label: role,
                                    isSelected: viewModel.selectedSuggestionRoles.contains(role)
                                ) {
                                    viewModel.toggleSuggestionRole(role)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            TextField(String(localized: "Custom role"), text: $viewModel.customRoleLabel)
                                .font(.subheadline)
                                .textFieldStyle(.roundedBorder)

                            Button(String(localized: "Add")) {
                                viewModel.addCustomRole()
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.rrPrimary)
                            .disabled(viewModel.customRoleLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .padding(.horizontal)

                Text(String(localized: "\(viewModel.selectedSuggestionRoles.count) roles selected"))
                    .font(.subheadline)
                    .foregroundStyle(Color.rrTextSecondary)

                nextButton
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Page 4: Trigger Setup

    private var triggerSetupPage: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(String(localized: "Known Emotional Triggers"))
                        .font(.title2.bold())
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "What emotions tend to get stirred in you? These help the Bowtie show patterns."))
                        .font(.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        FlowLayout(spacing: 8) {
                            ForEach(KnownTriggerSuggestions.defaults, id: \.self) { trigger in
                                toggleChip(
                                    label: trigger,
                                    isSelected: viewModel.selectedSuggestionTriggers.contains(trigger)
                                ) {
                                    viewModel.toggleSuggestionTrigger(trigger)
                                }
                            }
                        }

                        HStack(spacing: 8) {
                            TextField(String(localized: "Custom trigger"), text: $viewModel.customTriggerLabel)
                                .font(.subheadline)
                                .textFieldStyle(.roundedBorder)

                            Button(String(localized: "Add")) {
                                viewModel.addCustomTrigger()
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.rrPrimary)
                            .disabled(viewModel.customTriggerLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                }
                .padding(.horizontal)

                Button {
                    viewModel.completeOnboarding(context: modelContext)
                    dismiss()
                } label: {
                    Text(String(localized: "Complete"))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.rrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Shared Components

    private var nextButton: some View {
        Button {
            swipeDirection = .forward
            if reduceMotion {
                viewModel.goForward()
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.goForward()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(String(localized: "Next"))
                    .fontWeight(.semibold)
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(Color.rrPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
    }

    private func toggleChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.rrPrimary.opacity(0.2) : Color.rrSurface)
                .foregroundStyle(isSelected ? Color.rrPrimary : Color.rrText)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.rrPrimary : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(label)
        .accessibilityHint(isSelected ? String(localized: "Double tap to deselect") : String(localized: "Double tap to select"))
    }
}

#Preview {
    BowtieOnboardingView()
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
