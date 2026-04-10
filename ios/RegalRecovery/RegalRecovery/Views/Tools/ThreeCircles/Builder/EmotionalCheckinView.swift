import SwiftUI

/// Pre-builder emotional check-in screen.
///
/// Asks "How are you feeling right now?" with a 5-point scale.
/// If the user is struggling (score 1-2), offers compassionate paths forward.
struct EmotionalCheckinView: View {
    let viewModel: ThreeCirclesBuilderViewModel

    private let feelings: [(score: Int, icon: String, label: String, color: Color)] = [
        (1, "cloud.heavyrain.fill", "Struggling", Color(red: 0.651, green: 0.239, blue: 0.251)),
        (2, "cloud.fill", "Low", Color(red: 0.831, green: 0.502, blue: 0.165)),
        (3, "sun.haze.fill", "Okay", Color(red: 0.788, green: 0.635, blue: 0.153)),
        (4, "sun.max.fill", "Good", Color(red: 0.482, green: 0.620, blue: 0.239)),
        (5, "sparkles", "Strong", Color(red: 0.176, green: 0.416, blue: 0.310)),
    ]

    var body: some View {
        ZStack {
            // Main check-in content
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    // Title
                    VStack(spacing: 12) {
                        Text("How are you feeling right now?")
                            .font(RRFont.title)
                            .foregroundStyle(Color.rrText)
                            .multilineTextAlignment(.center)

                        Text("There are no wrong answers. This helps us tailor the experience to where you are today.")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    // Feeling options
                    VStack(spacing: 16) {
                        ForEach(feelings, id: \.score) { feeling in
                            feelingButton(feeling)
                        }
                    }
                    .padding(.horizontal)

                    // Skip option
                    Button {
                        viewModel.setEmotionalCheckin(3) // Default to "okay" when skipping
                    } label: {
                        Text("Skip this step")
                            .font(RRFont.callout)
                            .foregroundStyle(Color.rrTextSecondary)
                            .frame(minHeight: 44)
                    }
                    .accessibilityLabel("Skip the emotional check-in")

                    Spacer(minLength: 40)
                }
            }

            // Struggling options overlay
            if viewModel.showStrugglingOptions {
                strugglingOverlay
            }
        }
    }

    // MARK: - Feeling Button

    private func feelingButton(_ feeling: (score: Int, icon: String, label: String, color: Color)) -> some View {
        let isSelected = viewModel.emotionalCheckinScore == feeling.score

        return Button {
            viewModel.setEmotionalCheckin(feeling.score)
        } label: {
            HStack(spacing: 16) {
                Image(systemName: feeling.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(feeling.color)
                    .frame(width: 44, height: 44)

                Text(feeling.label)
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(feeling.color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? feeling.color.opacity(0.1) : Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(feeling.label), feeling level \(feeling.score) of 5")
    }

    // MARK: - Struggling Overlay

    private var strugglingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showStrugglingOptions = false
                }

            RRCard {
                VStack(spacing: 20) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.rrPrimary)

                    Text("It takes courage to show up when things are hard.")
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                        .multilineTextAlignment(.center)

                    Text("You do not have to do this right now. Here are some options:")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        RRButton("Start anyway, I can do this", icon: "arrow.right") {
                            viewModel.handleStrugglingPath(.startAnyway)
                        }

                        Button {
                            viewModel.handleStrugglingPath(.saveForLater)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bookmark.fill")
                                Text("Save for later")
                            }
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                        }

                        Button {
                            viewModel.handleStrugglingPath(.getSupport)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "hand.raised.fill")
                                Text("I need support first")
                            }
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrDestructive)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showStrugglingOptions)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EmotionalCheckinView(viewModel: ThreeCirclesBuilderViewModel())
    }
}
