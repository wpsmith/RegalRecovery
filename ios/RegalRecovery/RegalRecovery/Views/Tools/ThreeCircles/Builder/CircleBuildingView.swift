import SwiftUI

/// The main circle building screen, used for inner, outer, and middle circles.
///
/// Displays circle-specific definitions, template suggestions, free-text entry,
/// the current item list with edit/delete actions, and inline guardrail nudges.
struct CircleBuildingView: View {
    let viewModel: ThreeCirclesBuilderViewModel
    let circleType: CircleType

    @State private var newItemText: String = ""
    @State private var showTemplates: Bool = false
    @State private var showReflection: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    // MARK: - Circle Metadata

    private var circleColor: Color {
        switch circleType {
        case .inner: return Color.rrDestructive
        case .middle: return .orange
        case .outer: return Color.rrSuccess
        }
    }

    private var circleDefinition: String {
        switch circleType {
        case .inner:
            return "Your inner circle contains your bottom lines: behaviors you have committed to completely avoiding. These are the actions that, if you engage in them, represent a break in your sobriety."
        case .middle:
            return "Your middle circle contains warning signs and slippery behaviors. These are not failures, but signals that you may be moving toward your inner circle. Recognizing them early is a sign of growing awareness."
        case .outer:
            return "Your outer circle contains healthy behaviors, self-care practices, and recovery activities. These are the things that strengthen your recovery and the life you are building."
        }
    }

    private var circlePrompt: String {
        switch circleType {
        case .inner:
            return "What behaviors are you committed to avoiding completely?"
        case .middle:
            return "What warning signs tell you that you might be heading toward your inner circle?"
        case .outer:
            return "What healthy practices support your recovery and well-being?"
        }
    }

    private var reflectionPrompt: String {
        switch circleType {
        case .inner:
            return "As you review your inner circle, consider: Are these specific enough that you would know clearly if you crossed a line? Could you explain each one to your sponsor or accountability partner?"
        case .middle:
            return "Think about the last time you acted out. What happened in the hours or days before? Those patterns often belong in your middle circle."
        case .outer:
            return "Recovery is not just about avoiding harm. What does a good day look like for you? What activities bring you genuine peace or joy?"
        }
    }

    private var items: [BuilderItem] {
        viewModel.items(for: circleType)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Circle definition card
                definitionCard

                // Template suggestions (collapsible)
                templateSection

                // Add new item
                addItemSection

                // Current items list
                if !items.isEmpty {
                    itemListSection
                }

                // Guardrail nudges
                guardrailSection

                // Reflection prompt
                reflectionButton
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showReflection) {
            reflectionSheet
        }
    }

    // MARK: - Definition Card

    private var definitionCard: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 14, height: 14)

                    Text(circleType.displayName)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                }

                Text(circleDefinition)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Template Section

    private var templateSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showTemplates.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .font(.body)
                        .foregroundStyle(.orange)

                    Text("Suggestions to get started")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .rotationEffect(.degrees(showTemplates ? 180 : 0))
                }
                .padding()
                .background(Color.rrSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Suggestions to get started, \(showTemplates ? "expanded" : "collapsed")")

            if showTemplates {
                VStack(spacing: 0) {
                    ForEach(templateSuggestions, id: \.self) { suggestion in
                        templateRow(suggestion)
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal)
    }

    private func templateRow(_ suggestion: String) -> some View {
        let isAdded = items.contains { $0.behaviorName.lowercased() == suggestion.lowercased() }

        return Button {
            if !isAdded {
                viewModel.addItem(to: circleType, behaviorName: suggestion, source: .template)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                    .font(.body)
                    .foregroundStyle(isAdded ? circleColor : Color.rrTextSecondary)

                Text(suggestion)
                    .font(RRFont.body)
                    .foregroundStyle(isAdded ? Color.rrTextSecondary : Color.rrText)
                    .strikethrough(isAdded)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isAdded)
        .accessibilityLabel("\(suggestion)\(isAdded ? ", already added" : ", tap to add")")
    }

    // MARK: - Add Item Section

    private var addItemSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(circlePrompt)
                    .font(RRFont.callout)
                    .foregroundStyle(Color.rrTextSecondary)

                HStack(spacing: 10) {
                    TextField("Add a behavior...", text: $newItemText)
                        .font(RRFont.body)
                        .textFieldStyle(.roundedBorder)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            addNewItem()
                        }
                        .accessibilityLabel("Enter a behavior to add to your \(circleType.displayName.lowercased())")

                    Button {
                        addNewItem()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(newItemText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.rrTextSecondary.opacity(0.3) : circleColor)
                    }
                    .disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Add item")
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Item List Section

    private var itemListSection: some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Your Items")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    Text("\(items.count)")
                        .font(RRFont.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(circleColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(circleColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                ForEach(items) { item in
                    itemRow(item)
                }
            }
        }
        .padding(.horizontal)
    }

    private func itemRow(_ item: BuilderItem) -> some View {
        HStack(spacing: 10) {
            RRColorDot(circleColor, size: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.behaviorName)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)

                HStack(spacing: 6) {
                    if item.source == .template {
                        RRBadge(text: "Template", color: .orange.opacity(0.8))
                    }
                    if item.source == .starterPack {
                        RRBadge(text: "Starter Pack", color: Color.rrPrimary.opacity(0.8))
                    }
                    if item.isUncertain {
                        RRBadge(text: "Uncertain", color: Color.rrTextSecondary)
                    }
                }
            }

            Spacer()

            // Uncertain toggle
            Button {
                viewModel.toggleUncertain(item, in: circleType)
            } label: {
                Image(systemName: item.isUncertain ? "questionmark.circle.fill" : "questionmark.circle")
                    .font(.body)
                    .foregroundStyle(item.isUncertain ? .orange : Color.rrTextSecondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(item.isUncertain ? "Mark as certain" : "Mark as uncertain for sponsor review")

            // Delete
            Button {
                viewModel.removeItem(from: circleType, item: item)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.body)
                    .foregroundStyle(Color.rrTextSecondary.opacity(0.4))
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Remove \(item.behaviorName)")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Guardrail Section

    @ViewBuilder
    private var guardrailSection: some View {
        let nudges = currentNudges
        if !nudges.isEmpty {
            VStack(spacing: 8) {
                ForEach(nudges) { nudge in
                    nudgeRow(nudge)
                }
            }
            .padding(.horizontal)
        }
    }

    private var currentNudges: [GuardrailNudge] {
        var nudges: [GuardrailNudge] = []
        let count = items.count

        switch circleType {
        case .inner:
            if count > 15 {
                nudges.append(GuardrailNudge(
                    message: "You have many inner circle items. Focus on the most critical boundaries first.",
                    severity: .suggestion
                ))
            }
            if count >= 3 && count <= 5 {
                nudges.append(GuardrailNudge(
                    message: "3-5 inner circle items is a solid starting point.",
                    severity: .info
                ))
            }
        case .middle:
            if count == 0 {
                nudges.append(GuardrailNudge(
                    message: "It is okay to come back to this later. Middle circle items often become clearer with time.",
                    severity: .info
                ))
            }
        case .outer:
            if count > 20 {
                nudges.append(GuardrailNudge(
                    message: "A large outer circle can feel overwhelming. Focus on what you can realistically maintain.",
                    severity: .suggestion
                ))
            }
        }

        return nudges
    }

    private func nudgeRow(_ nudge: GuardrailNudge) -> some View {
        let nudgeColor: Color = {
            switch nudge.severity {
            case .info: return Color.rrPrimary
            case .suggestion: return .orange
            case .warning: return Color.rrDestructive
            }
        }()

        let nudgeIcon: String = {
            switch nudge.severity {
            case .info: return "info.circle.fill"
            case .suggestion: return "lightbulb.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }()

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: nudgeIcon)
                .font(.body)
                .foregroundStyle(nudgeColor)

            Text(nudge.message)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .background(nudgeColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Reflection Button

    private var reflectionButton: some View {
        Button {
            showReflection = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.callout)
                Text("Reflection prompt")
                    .font(RRFont.callout)
            }
            .foregroundStyle(Color.rrPrimary)
            .frame(minHeight: 44)
        }
        .accessibilityLabel("Open reflection prompt")
    }

    // MARK: - Reflection Sheet

    private var reflectionSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(circleColor)

                Text("Take a Moment to Reflect")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text(reflectionPrompt)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
                Spacer()
            }
            .padding()
            .background(Color.rrBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showReflection = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Template Suggestions

    /// Hardcoded suggestions per circle type. In production these would come from the templates API.
    private var templateSuggestions: [String] {
        switch circleType {
        case .inner:
            return [
                "Viewing pornography",
                "Masturbation",
                "Acting out sexually outside marriage",
                "Visiting triggering websites or apps",
                "Engaging in fantasy",
                "Objectifying others",
                "Anonymous sexual encounters",
                "Using substances to cope",
            ]
        case .middle:
            return [
                "Isolating from others",
                "Staying up late alone with devices",
                "Skipping meetings or check-ins",
                "Browsing social media excessively",
                "Keeping secrets from spouse or sponsor",
                "Allowing resentment to build",
                "Neglecting spiritual practices",
                "Overworking to avoid feelings",
                "Romanticizing past behaviors",
                "Being dishonest about small things",
            ]
        case .outer:
            return [
                "Daily prayer or meditation",
                "Calling sponsor or accountability partner",
                "Attending recovery meetings",
                "Regular exercise",
                "Journaling",
                "Scripture or recovery reading",
                "Date night with spouse",
                "Fellowship with safe people",
                "Acts of service",
                "Consistent sleep routine",
                "Gratitude practice",
                "Therapy or counseling",
            ]
        }
    }

    // MARK: - Helpers

    private func addNewItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        viewModel.addItem(to: circleType, behaviorName: trimmed)
        newItemText = ""
        isTextFieldFocused = true
    }
}

// MARK: - Preview

#Preview("Inner Circle") {
    NavigationStack {
        CircleBuildingView(
            viewModel: ThreeCirclesBuilderViewModel(),
            circleType: .inner
        )
    }
}

#Preview("Outer Circle") {
    NavigationStack {
        CircleBuildingView(
            viewModel: ThreeCirclesBuilderViewModel(),
            circleType: .outer
        )
    }
}
