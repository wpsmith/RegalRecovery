import SwiftUI

struct TriggerLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = TriggerLogViewModel()
    @State private var showConfirmation = false
    @State private var showStandardFields = false
    @State private var showDeepFields = false
    @State private var submittedRiskLevel: RiskLevel?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Trigger Selection Section
                    triggerSelectionSection

                    // 2. Intensity Section
                    IntensitySliderView(
                        intensity: $viewModel.intensity,
                        isIncluded: $viewModel.includeIntensity
                    )
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.rrSurface)
                    )

                    // 3. Submit Button
                    submitButton

                    // 4. Add more detail button
                    if !showStandardFields {
                        addMoreDetailButton
                    }

                    // 5. Standard Fields Section
                    if showStandardFields {
                        standardFieldsSection
                    }

                    // 6. Deep Fields Section
                    if showDeepFields {
                        deepFieldsSection
                    }
                }
                .padding(16)
            }
            .navigationTitle("Log a Trigger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showConfirmation) {
                confirmationSheet
            }
        }
    }

    // MARK: - Trigger Selection Section

    private var triggerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with count
            HStack {
                Text("What are you experiencing?")
                    .font(.headline)
                    .foregroundStyle(.rrText)

                if !viewModel.selectedTriggerIds.isEmpty {
                    Text("\(viewModel.selectedTriggerIds.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.rrPrimary)
                        )
                }

                Spacer()
            }

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.rrTextSecondary)
                    .font(.subheadline)

                TextField("Search triggers", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemBackground))
            )

            // Trigger chips in FlowLayout
            FlowLayout(spacing: 8) {
                ForEach(filteredTriggers) { trigger in
                    TriggerChipView(
                        label: trigger.label,
                        category: trigger.category,
                        isSelected: viewModel.selectedTriggerIds.contains(trigger.id),
                        onTap: {
                            viewModel.toggleTrigger(id: trigger.id)
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.rrSurface)
        )
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.submit()
                    submittedRiskLevel = viewModel.includeIntensity
                        ? RiskLevel.from(intensity: viewModel.intensity)
                        : nil
                    showConfirmation = true
                } catch {
                    // Handle error (could add error presentation here)
                    print("Submit error: \(error)")
                }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Log it")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSubmit ? Color.rrPrimary : Color.gray.opacity(0.3))
            )
        }
        .disabled(!canSubmit)
        .buttonStyle(.plain)
    }

    // MARK: - Add More Detail Button

    private var addMoreDetailButton: some View {
        Button {
            withAnimation {
                showStandardFields = true
                viewModel.logDepth = .standard
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle")
                Text("Add more detail")
                    .fontWeight(.medium)
            }
            .foregroundStyle(.rrPrimary)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Standard Fields Section

    private var standardFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            Text("Context")
                .font(.headline)
                .foregroundStyle(.rrText)

            // Mood
            TextField("Mood or emotion", text: Binding(
                get: { viewModel.mood ?? "" },
                set: { viewModel.mood = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)

            // Situation
            TextField("What was happening?", text: Binding(
                get: { viewModel.situation ?? "" },
                set: { viewModel.situation = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)

            // Social context
            VStack(alignment: .leading, spacing: 8) {
                Text("Who was around?")
                    .font(.subheadline)
                    .foregroundStyle(.rrTextSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SocialContext.allCases) { context in
                            Button {
                                viewModel.socialContext = context
                            } label: {
                                Text(context.displayName)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.socialContext == context
                                                  ? Color.rrPrimary
                                                  : Color(.tertiarySystemBackground))
                                    )
                                    .foregroundStyle(viewModel.socialContext == context
                                                     ? .white
                                                     : .rrText)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Where were you?")
                    .font(.subheadline)
                    .foregroundStyle(.rrTextSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(LocationCategory.allCases) { location in
                            Button {
                                viewModel.locationCategory = location
                            } label: {
                                Text(location.displayName)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.locationCategory == location
                                                  ? Color.rrPrimary
                                                  : Color(.tertiarySystemBackground))
                                    )
                                    .foregroundStyle(viewModel.locationCategory == location
                                                     ? .white
                                                     : .rrText)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Response
            TextField("What did you do?", text: Binding(
                get: { viewModel.responseTaken ?? "" },
                set: { viewModel.responseTaken = $0.isEmpty ? nil : $0 }
            ))
            .textFieldStyle(.roundedBorder)

            // Go deeper button
            if !showDeepFields {
                Button {
                    withAnimation {
                        showDeepFields = true
                        viewModel.logDepth = .deep
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                        Text("Go deeper")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.rrPrimary)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Deep Fields Section

    private var deepFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider()

            Text("Reflection")
                .font(.headline)
                .foregroundStyle(.rrText)

            // Unmet need
            VStack(alignment: .leading, spacing: 8) {
                Text("What unmet need might be underneath?")
                    .font(.subheadline)
                    .foregroundStyle(.rrTextSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(UnmetNeed.allCases) { need in
                            Button {
                                viewModel.unmetNeed = need
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: need.icon)
                                        .font(.title2)
                                        .foregroundStyle(viewModel.unmetNeed == need
                                                         ? .white
                                                         : .rrPrimary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(viewModel.unmetNeed == need
                                                      ? Color.rrPrimary
                                                      : Color(.tertiarySystemBackground))
                                        )

                                    Text(need.displayName)
                                        .font(.caption2)
                                        .foregroundStyle(.rrText)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 70)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Teacher reflection
            VStack(alignment: .leading, spacing: 8) {
                Text("What did this trigger teach you?")
                    .font(.subheadline)
                    .foregroundStyle(.rrTextSecondary)

                TextEditor(text: Binding(
                    get: { viewModel.teacherReflection ?? "" },
                    set: { viewModel.teacherReflection = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separator), lineWidth: 1)
                )
            }

            // FASTER position
            VStack(alignment: .leading, spacing: 8) {
                Text("Where are you on the FASTER Scale?")
                    .font(.subheadline)
                    .foregroundStyle(.rrTextSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FASTERStage.allCases) { stage in
                            Button {
                                viewModel.fasterPosition = stage
                            } label: {
                                Text(stage.letter)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(viewModel.fasterPosition == stage
                                                     ? .white
                                                     : stage.color)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(viewModel.fasterPosition == stage
                                                  ? stage.color
                                                  : stage.color.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Confirmation Sheet

    private var confirmationSheet: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.rrSuccess)

            // Affirming message
            Text(TriggerLogViewModel.randomAffirmingMessage())
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            // Next actions
            VStack(spacing: 12) {
                ForEach(TriggerLogViewModel.nextActions(for: submittedRiskLevel)) { action in
                    Button {
                        handleNextAction(action)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: action.icon)
                            Text(action.label)
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(action.style == .secondary ? .rrText : .white)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(backgroundColorForActionStyle(action.style))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Helpers

    private var filteredTriggers: [TriggerLogViewModel.TriggerOption] {
        if searchText.isEmpty {
            return viewModel.availableTriggers
        }
        return viewModel.availableTriggers.filter {
            $0.label.localizedCaseInsensitiveContains(searchText) ||
            $0.category.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var canSubmit: Bool {
        !viewModel.selectedTriggerIds.isEmpty && !viewModel.isSubmitting
    }

    private func backgroundColorForActionStyle(_ style: TriggerLogViewModel.NextAction.ActionStyle) -> Color {
        switch style {
        case .primary:
            return .rrPrimary
        case .secondary:
            return Color(.secondarySystemBackground)
        case .destructive:
            return .rrDestructive
        }
    }

    private func handleNextAction(_ action: TriggerLogViewModel.NextAction) {
        switch action.id {
        case "dismiss":
            showConfirmation = false
            dismiss()
        case "logAnother":
            showConfirmation = false
            // Form already reset by viewModel.submit()
            showStandardFields = false
            showDeepFields = false
        default:
            // Other actions would navigate or trigger specific flows
            showConfirmation = false
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview("Trigger Log View") {
    TriggerLogView()
        .onAppear {
            // Populate sample triggers for preview
            let sampleTriggers: [TriggerLogViewModel.TriggerOption] = [
                .init(id: UUID(), label: "Stress", category: .emotional),
                .init(id: UUID(), label: "Anxiety", category: .emotional),
                .init(id: UUID(), label: "Loneliness", category: .emotional),
                .init(id: UUID(), label: "Boredom", category: .emotional),
                .init(id: UUID(), label: "Fatigue", category: .physical),
                .init(id: UUID(), label: "Hunger", category: .physical),
                .init(id: UUID(), label: "Pain", category: .physical),
                .init(id: UUID(), label: "Home alone", category: .environmental),
                .init(id: UUID(), label: "Late at night", category: .environmental),
                .init(id: UUID(), label: "Conflict", category: .relational),
                .init(id: UUID(), label: "Rejection", category: .relational),
                .init(id: UUID(), label: "Fantasy", category: .cognitive),
                .init(id: UUID(), label: "Comparison", category: .cognitive),
            ]

            // This won't actually work in preview, but shows the structure
            // In real usage, the viewModel would be populated by the parent
        }
}
