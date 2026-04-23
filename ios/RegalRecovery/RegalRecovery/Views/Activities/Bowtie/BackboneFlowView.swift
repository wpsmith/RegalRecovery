import SwiftUI
import SwiftData

struct BackboneFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = BackboneProcessingViewModel()
    @State private var swipeDirection: SwipeDirection = .forward
    let marker: RRBowtieMarker
    var onJournalRequested: ((String) -> Void)?
    var onAffirmationRequested: (() -> Void)?

    private enum SwipeDirection { case forward, backward }

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            Group {
                switch viewModel.currentStep {
                case .lifeSituation:
                    lifeSituationStep
                case .emotions:
                    emotionsStep
                case .threeIs:
                    threeIsStep
                case .spiritualReflection:
                    spiritualReflectionStep
                case .emotionalNeeds:
                    emotionalNeedsStep
                case .intimacyActions:
                    intimacyActionsStep
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
                        if horizontal < -50 && viewModel.canAdvance {
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

            navigationButtons
        }
        .background(Color.rrBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if viewModel.isFirstStep {
                        dismiss()
                    } else {
                        swipeDirection = .backward
                        if reduceMotion {
                            viewModel.goBack()
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.goBack()
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.rrText)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(viewModel.currentStep.title)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
            }
        }
        .overlay {
            if viewModel.showCompletion {
                completionOverlay
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

    // MARK: - Step 1: Life Situation

    private var lifeSituationStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "text.bubble")
                        .font(.largeTitle)
                        .foregroundStyle(Color.rrPrimary)

                    Text("What is happening in this moment?")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("Describe the situation or what you are anticipating.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal)

                RRCard {
                    VStack(alignment: .trailing, spacing: 8) {
                        TextEditor(text: $viewModel.lifeSituation)
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrText)
                            .frame(minHeight: 120)
                            .scrollContentBackground(.hidden)
                            .overlay(alignment: .topLeading) {
                                if viewModel.lifeSituation.isEmpty {
                                    Text("What are you experiencing or anticipating?")
                                        .font(RRFont.body)
                                        .foregroundStyle(Color.rrTextSecondary.opacity(0.6))
                                        .allowsHitTesting(false)
                                        .padding(.top, 8)
                                }
                            }

                        Text("\(viewModel.lifeSituation.count)/500")
                            .font(RRFont.caption)
                            .foregroundStyle(viewModel.lifeSituation.count > 500 ? .red : Color.rrTextSecondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onChange(of: viewModel.lifeSituation) { _, newValue in
            if newValue.count > 500 {
                viewModel.lifeSituation = String(newValue.prefix(500))
            }
        }
    }

    // MARK: - Step 2: Emotions

    private var emotionsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square")
                        .font(.largeTitle)
                        .foregroundStyle(Color.rrPrimary)

                    Text("What are you feeling?")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("Select all emotions that apply.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal)

                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        FlowLayout(spacing: 8) {
                            ForEach(BackboneEmotion.allCases) { emotion in
                                chipButton(
                                    label: emotion.displayName,
                                    isSelected: viewModel.selectedEmotions.contains(emotion.rawValue)
                                ) {
                                    viewModel.toggleEmotion(emotion.rawValue)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add your own")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        HStack {
                            TextField("Custom emotion", text: $viewModel.customEmotionText)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .onSubmit { viewModel.addCustomEmotion() }
                            Button {
                                viewModel.addCustomEmotion()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            .disabled(viewModel.customEmotionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding(.horizontal)

                if !customEmotions.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            FlowLayout(spacing: 8) {
                                ForEach(customEmotions, id: \.self) { emotion in
                                    chipButton(
                                        label: emotion.capitalized,
                                        isSelected: true
                                    ) {
                                        viewModel.toggleEmotion(emotion)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var customEmotions: [String] {
        let builtIn = Set(BackboneEmotion.allCases.map(\.rawValue))
        return viewModel.selectedEmotions.filter { !builtIn.contains($0) }.sorted()
    }

    // MARK: - Step 3: Three I's

    private var threeIsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(Color.rrPrimary)

                    Text("Which I's are activated?")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("Tap any that apply, then adjust intensity.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal)

                ForEach(ThreeIType.allCases) { iType in
                    threeICard(iType)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func threeICard(_ iType: ThreeIType) -> some View {
        let isActive = viewModel.iActivations.contains(where: { $0.iType == iType })
        let intensity = viewModel.iActivations.first(where: { $0.iType == iType })?.intensity ?? 5

        return RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleIActivation(iType)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: iType.icon)
                            .font(.title2)
                            .foregroundStyle(isActive ? iType.color : Color.rrTextSecondary)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(iType.displayName)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                            Text(iType.diagnosticQuestion)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        Spacer()

                        Image(systemName: isActive ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(isActive ? iType.color : Color.rrTextSecondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isActive ? .isSelected : [])
                .accessibilityLabel(iType.displayName)
                .accessibilityHint(isActive ? String(localized: "Double tap to deselect") : String(localized: "Double tap to select"))

                if isActive {
                    Divider()
                    VStack(spacing: 8) {
                        HStack {
                            Text("Intensity")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Spacer()
                            Text("\(intensity)")
                                .font(RRFont.headline)
                                .foregroundStyle(iType.color)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(intensity) },
                                set: { viewModel.updateIntensity(for: iType, to: Int($0)) }
                            ),
                            in: 1...10,
                            step: 1
                        )
                        .tint(iType.color)
                        .accessibilityLabel(String(localized: "\(iType.displayName) intensity"))
                        .accessibilityValue(String(localized: "\(intensity) of 10"))

                        HStack {
                            Text("Low")
                                .font(RRFont.caption2)
                                .foregroundStyle(Color.rrTextSecondary)
                            Spacer()
                            Text("High")
                                .font(RRFont.caption2)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    // MARK: - Step 4: Spiritual Reflection

    private var spiritualReflectionStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "hands.and.sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(Color.rrPrimary)

                    Text("Spiritual Reflection")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("How did you experience yourself and God in this situation?")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal)

                RRCard {
                    TextEditor(text: $viewModel.spiritualReflectionText)
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrText)
                        .frame(minHeight: 150)
                        .scrollContentBackground(.hidden)
                        .overlay(alignment: .topLeading) {
                            if viewModel.spiritualReflectionText.isEmpty {
                                Text("This step is optional. Share what comes to mind...")
                                    .font(RRFont.body)
                                    .foregroundStyle(Color.rrTextSecondary.opacity(0.6))
                                    .allowsHitTesting(false)
                                    .padding(.top, 8)
                            }
                        }
                }
                .padding(.horizontal)

                Text("You can skip this step if you prefer.")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
            }
        }
    }

    // MARK: - Step 5: Emotional Needs

    private var emotionalNeedsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "heart.circle")
                        .font(.largeTitle)
                        .foregroundStyle(Color.rrPrimary)

                    Text("What do you need?")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("Select the emotional needs behind these feelings.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal)

                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        FlowLayout(spacing: 8) {
                            ForEach(EmotionalNeed.allCases) { need in
                                chipButton(
                                    label: need.displayName,
                                    isSelected: viewModel.selectedNeeds.contains(need.rawValue)
                                ) {
                                    viewModel.toggleNeed(need.rawValue)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                RRCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add your own")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        HStack {
                            TextField("Custom need", text: $viewModel.customNeedText)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                                .onSubmit { viewModel.addCustomNeed() }
                            Button {
                                viewModel.addCustomNeed()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.rrPrimary)
                            }
                            .disabled(viewModel.customNeedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding(.horizontal)

                if !customNeeds.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            FlowLayout(spacing: 8) {
                                ForEach(customNeeds, id: \.self) { need in
                                    chipButton(
                                        label: need.capitalized,
                                        isSelected: true
                                    ) {
                                        viewModel.toggleNeed(need)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var customNeeds: [String] {
        let builtIn = Set(EmotionalNeed.allCases.map(\.rawValue))
        return viewModel.selectedNeeds.filter { !builtIn.contains($0) }.sorted()
    }

    // MARK: - Step 6: Intimacy Actions

    private var intimacyActionsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Image(systemName: "figure.2.arms.open")
                        .font(.largeTitle)
                        .foregroundStyle(Color.rrPrimary)

                    Text("Choose actions for intimacy")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("What will you do to meet those needs in a healthy way?")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)
                .padding(.horizontal)

                ForEach(IntimacyCategory.allCases, id: \.rawValue) { category in
                    intimacyCategoryCard(category)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func intimacyCategoryCard(_ category: IntimacyCategory) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: iconForCategory(category))
                        .foregroundStyle(Color.rrPrimary)
                    Text(category.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }

                FlowLayout(spacing: 8) {
                    ForEach(category.suggestedActions, id: \.self) { actionLabel in
                        let action = IntimacyAction(category: category, label: actionLabel, isCustom: false)
                        chipButton(
                            label: actionLabel,
                            isSelected: viewModel.selectedActions.contains(action)
                        ) {
                            viewModel.toggleAction(action)
                        }
                    }

                    // Show custom actions for this category
                    ForEach(customActionsFor(category), id: \.id) { action in
                        chipButton(
                            label: action.label,
                            isSelected: true
                        ) {
                            viewModel.toggleAction(action)
                        }
                    }
                }

                HStack {
                    TextField("Add custom action", text: customActionBinding(for: category))
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrText)
                        .onSubmit { submitCustomAction(for: category) }
                    Button {
                        submitCustomAction(for: category)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.rrPrimary)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func customActionsFor(_ category: IntimacyCategory) -> [IntimacyAction] {
        viewModel.selectedActions.filter { $0.category == category && $0.isCustom }
    }

    // Per-category custom action text tracked via a single field plus category tag
    @State private var customActionTexts: [IntimacyCategory: String] = [:]

    private func customActionBinding(for category: IntimacyCategory) -> Binding<String> {
        Binding(
            get: { customActionTexts[category] ?? "" },
            set: { customActionTexts[category] = $0 }
        )
    }

    private func submitCustomAction(for category: IntimacyCategory) {
        let text = (customActionTexts[category] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.addCustomAction(category: category, label: text)
        customActionTexts[category] = ""
    }

    private func iconForCategory(_ category: IntimacyCategory) -> String {
        switch category {
        case .god: return "hands.and.sparkles"
        case .self_: return "person.fill"
        case .others: return "person.2.fill"
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
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
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(RRFont.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            Button {
                if viewModel.isLastStep {
                    viewModel.save(marker: marker, context: modelContext)
                } else {
                    swipeDirection = .forward
                    if reduceMotion {
                        viewModel.goForward()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.goForward()
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.isLastStep ? "Save" : "Next")
                    Image(systemName: viewModel.isLastStep ? "checkmark" : "chevron.right")
                }
                .font(RRFont.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(viewModel.canAdvance ? Color.rrPrimary : Color.rrPrimary.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canAdvance)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.rrBackground)
    }

    // MARK: - Chip Button

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(RRFont.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.rrPrimary : Color.rrSurface)
                )
                .foregroundStyle(isSelected ? .white : Color.rrText)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color.rrTextSecondary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityLabel(label)
        .accessibilityHint(isSelected ? String(localized: "Double tap to deselect") : String(localized: "Double tap to select"))
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)

                Text(String(localized: "Processing Complete"))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.rrText)

                Text(BowtieCompletionMessages.random())
                    .font(.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    if let onJournalRequested {
                        Button {
                            let emotions = viewModel.selectedEmotions.sorted().joined(separator: ", ")
                            let needs = viewModel.selectedNeeds.sorted().joined(separator: ", ")
                            let journalContext = "Bowtie Processing: \(viewModel.lifeSituation)\nEmotions: \(emotions)\nNeeds: \(needs)"
                            onJournalRequested(journalContext)
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.pencil")
                                Text("Journal about this")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.rrPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if let onAffirmationRequested {
                        Button {
                            onAffirmationRequested()
                            dismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text("Read affirmations")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.rrPrimary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text(String(localized: "Done"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.rrPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 32)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.rrSurface)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

#Preview {
    NavigationStack {
        BackboneFlowView(
            marker: RRBowtieMarker(
                side: .past,
                timeIntervalHours: 6,
                roleId: UUID(),
                iActivations: [IActivation(iType: .incompetence, intensity: 5)]
            )
        )
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
