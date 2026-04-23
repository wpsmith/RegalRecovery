import SwiftUI

struct MotivationDiscoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = MotivationDiscoveryViewModel()
    var libraryViewModel: MotivationLibraryViewModel
    var onComplete: (([RRMotivation]) -> Void)?

    @State private var showResumeAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                }

                navigationButtons
                    .padding()
            }
            .background(Color.rrBackground)
            .navigationTitle(viewModel.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.saveDraft()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel.loadDraft() && viewModel.currentStep != .intro {
                    showResumeAlert = true
                }
            }
            .alert("Continue where you left off?", isPresented: $showResumeAlert) {
                Button("Continue") {}
                Button("Start Fresh") {
                    viewModel.clearDraft()
                    viewModel = MotivationDiscoveryViewModel()
                }
            } message: {
                Text("You have a discovery exercise in progress.")
            }
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.rrTextSecondary.opacity(0.2))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.rrPrimary)
                    .frame(width: geo.size.width * viewModel.currentStep.progressFraction, height: 4)
            }
        }
        .frame(height: 4)
        .accessibilityLabel("Step \(viewModel.currentStep.rawValue + 1) of \(MotivationDiscoveryStep.totalSteps)")
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .intro:
            introStep
        case .miracleQuestion:
            miracleStep
        case .valuesSelection:
            valuesStep
        case .concretePrompts:
            concretePromptsStep
        case .summary:
            summaryStep
        }
    }

    private var introStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.orange)

            Text("Your recovery needs a reason that is yours — not someone else's expectation, not a rule, but something you genuinely care about. Let's find it together.")
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }

    private var miracleStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("If a miracle happened overnight and your addiction was gone, what would be different when you woke up?")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            TextField("Write freely — this is for you...", text: $viewModel.miracleResponse, axis: .vertical)
                .lineLimit(4...12)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Miracle question response")
        }
    }

    private var valuesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What matters most to you in life? Choose up to \(MotivationLimits.maxValuesSelection).")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MotivationCategory.allCases) { category in
                    Button {
                        viewModel.toggleValue(category)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.title2)
                                .foregroundStyle(viewModel.selectedValues.contains(category) ? .white : category.color)
                            Text(category.displayName)
                                .font(RRFont.caption)
                                .foregroundStyle(viewModel.selectedValues.contains(category) ? .white : Color.rrText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.selectedValues.contains(category) ? category.color : Color.rrSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(category.color, lineWidth: viewModel.selectedValues.contains(category) ? 0 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                    .accessibilityLabel("\(category.displayName), \(viewModel.selectedValues.contains(category) ? "selected" : "not selected")")
                }
            }

            Text("\(viewModel.selectedValues.count)/\(MotivationLimits.maxValuesSelection) selected")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    private var concretePromptsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let category = viewModel.currentConcreteCategory {
                HStack(spacing: 8) {
                    Image(systemName: category.icon)
                        .foregroundStyle(category.color)
                    Text(category.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    Text("\(viewModel.currentConcretePromptIndex + 1)/\(viewModel.selectedValues.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Text(viewModel.concretePromptText(for: category))
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)

                let responseBinding = Binding(
                    get: { viewModel.concreteResponses[category] ?? "" },
                    set: { viewModel.concreteResponses[category] = $0 }
                )
                TextField("Your motivation...", text: responseBinding, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Motivation for \(category.displayName)")

                let scriptureBinding = Binding(
                    get: { viewModel.concreteScriptures[category] ?? "" },
                    set: { viewModel.concreteScriptures[category] = $0 }
                )

                if category == .spiritual || !scriptureBinding.wrappedValue.isEmpty {
                    Text("Is there a verse that connects to this for you?")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                    TextField("e.g. Psalm 51:10", text: scriptureBinding)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Scripture reference for \(category.displayName)")
                }
            }
        }
    }

    private var summaryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Here's what you told us matters most:")
                .font(RRFont.headline)
                .foregroundStyle(Color.rrText)

            let motivations = viewModel.buildMotivations(userId: UUID())
            ForEach(motivations, id: \.id) { motivation in
                MotivationSurfacingCard(motivation: motivation)
            }

            if motivations.isEmpty {
                Text("No motivations captured yet. Go back and write about what matters to you.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.canGoBack {
                Button("Back") {
                    viewModel.goToPreviousStep()
                }
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
            }

            Spacer()

            if viewModel.currentStep == .summary {
                Button("Add to My Motivations") {
                    saveMotivations()
                }
                .buttonStyle(.borderedProminent)
                .tint(.rrPrimary)
                .frame(minHeight: 44)
                .disabled(viewModel.buildMotivations(userId: UUID()).isEmpty)
            } else {
                Button("Continue") {
                    viewModel.goToNextStep()
                }
                .buttonStyle(.borderedProminent)
                .tint(.rrPrimary)
                .frame(minHeight: 44)
                .disabled(!viewModel.canProceed)
            }
        }
    }

    private func saveMotivations() {
        let motivations = viewModel.buildMotivations(userId: UUID())
        for motivation in motivations {
            modelContext.insert(motivation)
            libraryViewModel.motivations.insert(motivation, at: 0)

            let history = RRMotivationHistory(
                motivationId: motivation.id,
                changeType: .created,
                newValue: motivation.text
            )
            modelContext.insert(history)
        }
        try? modelContext.save()

        viewModel.clearDraft()
        onComplete?(motivations)
        dismiss()
    }
}

#Preview {
    MotivationDiscoveryView(libraryViewModel: MotivationLibraryViewModel())
        .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
