import SwiftUI
import SwiftData

struct MoodRatingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]
    @State private var viewModel = MoodCheckInViewModel()
    @State private var swipeDirection: SwipeDirection = .forward

    private enum SwipeDirection {
        case forward, backward
    }

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            Group {
                switch viewModel.currentStep {
                case .primaryMood:
                    primaryMoodLayer
                case .secondaryEmotion:
                    secondaryEmotionLayer
                case .tertiaryEmotion:
                    tertiaryEmotionLayer
                case .intensityAndContext:
                    intensityContextLayer
                case .journalPrompt:
                    journalLayer
                }
            }
            .id(viewModel.currentStep)
            .transition(swipeDirection == .forward
                ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        if horizontal < -50 && viewModel.canAdvance {
                            swipeDirection = .forward
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.goForward()
                            }
                        } else if horizontal > 50 && !viewModel.isFirstStep {
                            swipeDirection = .backward
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.goBack()
                            }
                        }
                    }
            )
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
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.goBack()
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.rrText)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.canSkipToSave {
                    Button {
                        saveEntry()
                    } label: {
                        Text(viewModel.isLastStep ? "Submit" : "Skip")
                            .font(RRFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(viewModel.isLastStep ? Color.rrPrimary : Color.rrTextSecondary)
                    }
                }
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

    // MARK: - Layer 1: Primary Mood

    private var primaryMoodLayer: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("How are you feeling?")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)
                    .multilineTextAlignment(.center)

                Text("Tap the face that fits right now.")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 20) {
                ForEach(MoodPrimary.allCases) { mood in
                    Button {
                        swipeDirection = .forward
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.selectPrimary(mood)
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(mood.emoji)
                                .font(.system(size: 40))
                            Text(mood.rawValue)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.rrSurface)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(mood.rawValue), mood option")
                }
            }
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Layer 2: Secondary Emotion

    private var secondaryEmotionLayer: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let primary = viewModel.selectedPrimary {
                    VStack(spacing: 12) {
                        Text(primary.emoji)
                            .font(.system(size: 40))

                        Text("More specifically...")
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrText)
                            .multilineTextAlignment(.center)

                        Text("You said \"\(primary.rawValue).\" What kind?")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        ForEach(viewModel.availableSecondaryEmotions) { emotion in
                            Button {
                                swipeDirection = .forward
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.selectSecondary(emotion)
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Text(emotion.emoji)
                                        .font(.system(size: 24))

                                    Text(emotion.name)
                                        .font(RRFont.body)
                                        .foregroundStyle(viewModel.selectedSecondary?.id == emotion.id ? .white : Color.rrText)

                                    Spacer()

                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.showSecondaryInfo = viewModel.showSecondaryInfo?.id == emotion.id ? nil : emotion
                                        }
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 16))
                                            .foregroundStyle(viewModel.selectedSecondary?.id == emotion.id ? .white.opacity(0.7) : Color.rrTextSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.selectedSecondary?.id == emotion.id ? primary.color : Color.rrSurface)
                                )
                            }
                            .buttonStyle(.plain)

                            if viewModel.showSecondaryInfo?.id == emotion.id {
                                Text(emotion.description)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.rrSurface.opacity(0.5))
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Layer 2.5: Tertiary Emotion

    private var tertiaryEmotionLayer: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let secondary = viewModel.selectedSecondary,
                   let primary = viewModel.selectedPrimary {
                    VStack(spacing: 12) {
                        Text(secondary.emoji)
                            .font(.system(size: 40))

                        Text("Even more precisely...")
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrText)
                            .multilineTextAlignment(.center)

                        Text("You're feeling \(secondary.name.lowercased()). Which word fits best?")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 6) {
                            Text(primary.emoji)
                                .font(.system(size: 14))
                            Text(primary.rawValue)
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(primary.color.opacity(0.15)))
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)

                    VStack(spacing: 12) {
                        ForEach(viewModel.availableTertiaryEmotions, id: \.self) { emotion in
                            VStack(spacing: 0) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.selectTertiary(emotion)
                                    }
                                    swipeDirection = .forward
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            viewModel.confirmTertiaryAndAdvance()
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(viewModel.tertiaryEmoji(for: emotion))
                                            .font(.system(size: 24))

                                        Text(emotion)
                                            .font(RRFont.body)
                                            .foregroundStyle(viewModel.selectedTertiary == emotion ? .white : Color.rrText)

                                        Spacer()

                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                viewModel.showTertiaryInfo = viewModel.showTertiaryInfo == emotion ? nil : emotion
                                            }
                                        } label: {
                                            Image(systemName: "info.circle")
                                                .font(.system(size: 16))
                                                .foregroundStyle(viewModel.selectedTertiary == emotion ? .white.opacity(0.7) : Color.rrTextSecondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(viewModel.selectedTertiary == emotion ? primary.color : Color.rrSurface)
                                    )
                                }
                                .buttonStyle(.plain)

                                if viewModel.showTertiaryInfo == emotion {
                                    Text(viewModel.tertiaryDescription(for: emotion))
                                        .font(RRFont.caption)
                                        .foregroundStyle(Color.rrTextSecondary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.rrSurface.opacity(0.5))
                                        )
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Layer 3: Intensity & Context

    private var intensityContextLayer: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Tell me more")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)

                    Text("Optional — add detail to track patterns over time.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 24)

                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Emotional Intensity")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        HStack {
                            Text("Mild")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Spacer()
                            Text("\(Int(viewModel.intensity))")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)
                            Spacer()
                            Text("Intense")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        Slider(value: $viewModel.intensity, in: 0...10, step: 1)
                            .tint(viewModel.selectedPrimary?.color ?? Color.rrPrimary)
                    }
                }
                .padding(.horizontal)

                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Urge to Act Out")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        HStack {
                            Text("None")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Spacer()
                            Text("\(Int(viewModel.urgeToActOut))")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrPrimary)
                            Spacer()
                            Text("Overwhelming")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                        }

                        Slider(value: $viewModel.urgeToActOut, in: 0...10, step: 1)
                            .tint(Color.rrDestructive)
                    }
                }
                .padding(.horizontal)

                if viewModel.urgeToActOut > 0 {
                    tagSection("Triggers", tags: MoodCheckInViewModel.triggerTags)
                }

                tagSection("What are you doing?", tags: MoodCheckInViewModel.activityTags)

                if viewModel.shouldShowActivityDetails {
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("More details")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            TextField("What specifically?", text: $viewModel.activityDetails)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                tagSection("Who are you with?", tags: MoodCheckInViewModel.peopleTags)

                if viewModel.shouldShowWhoField {
                    RRCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Who?")
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            TextField("Names or descriptions", text: $viewModel.whoDetails)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                RRButton("Continue", icon: "arrow.right") {
                    swipeDirection = .forward
                    withAnimation(.easeInOut(duration: 0.3)) {
                        viewModel.goForward()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.urgeToActOut > 0)
            .animation(.easeInOut(duration: 0.3), value: viewModel.shouldShowActivityDetails)
            .animation(.easeInOut(duration: 0.3), value: viewModel.shouldShowWhoField)
        }
    }

    // MARK: - Layer 4: Journal

    private var journalLayer: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Reflect")
                    .font(RRFont.title)
                    .foregroundStyle(Color.rrText)

                Text(viewModel.journalPrompt)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
                    .italic()
            }
            .padding(.top, 24)
            .padding(.horizontal)

            RRCard {
                TextEditor(text: $viewModel.journalResponse)
                    .frame(minHeight: 150)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .scrollContentBackground(.hidden)
            }
            .padding(.horizontal)

            Text("\(viewModel.journalResponse.count)/500")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)

            Spacer()

            RRButton("Save Check-In", icon: "checkmark.circle") {
                saveEntry()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        VStack(spacing: 24) {
            Spacer()

            if let primary = viewModel.selectedPrimary {
                Text(primary.emoji)
                    .font(.system(size: 72))
            }

            Text("Check-in saved")
                .font(RRFont.title)
                .foregroundStyle(Color.rrText)

            if let tertiary = viewModel.selectedTertiary {
                Text("Feeling \(tertiary.lowercased())")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
            } else if let secondary = viewModel.selectedSecondary {
                Text("Feeling \(secondary.name.lowercased())")
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Spacer()

            RRButton("Done", icon: "checkmark") {
                dismiss()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.rrBackground)
        .transition(.opacity)
    }

    // MARK: - Helpers

    private func tagSection(_ title: String, tags: [String]) -> some View {
        RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Button {
                            viewModel.toggleTag(tag)
                        } label: {
                            Text(tag)
                                .font(RRFont.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(viewModel.selectedTags.contains(tag) ? Color.rrPrimary : Color.rrSurface)
                                )
                                .foregroundStyle(viewModel.selectedTags.contains(tag) ? .white : Color.rrText)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func saveEntry() {
        let userId = users.first?.id ?? UUID()
        viewModel.save(context: modelContext, userId: userId)
    }
}

#Preview {
    NavigationStack {
        MoodRatingView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
