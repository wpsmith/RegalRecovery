import SwiftUI

/// Mode selection screen for the Three Circles builder.
///
/// Presents three entry modes with honest descriptions:
/// - Guided (20-30 min): Step-by-step with education and templates
/// - Starter Pack (10-15 min): Pre-built set to customize
/// - Express (5-10 min): Quick entry for experienced users
struct ModeSelectionView: View {
    let viewModel: ThreeCirclesBuilderViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Choose Your Path")
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)

                    Text("There is no wrong choice. You can always change or rebuild later.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.top, 16)

                // Mode cards
                VStack(spacing: 14) {
                    modeCard(
                        mode: .guided,
                        icon: "map.fill",
                        title: "Guided Builder",
                        duration: "20-30 minutes",
                        description: "Step-by-step with explanations, templates, and reflection prompts. Best for first time or if you want to be thorough.",
                        color: Color.rrPrimary
                    )

                    modeCard(
                        mode: .starterPack,
                        icon: "shippingbox.fill",
                        title: "Starter Pack",
                        duration: "10-15 minutes",
                        description: "Start with a pre-built set based on your recovery area and customize it. Good if you want a head start.",
                        color: .orange
                    )

                    modeCard(
                        mode: .express,
                        icon: "bolt.fill",
                        title: "Express",
                        duration: "5-10 minutes",
                        description: "Jump straight to building. Best if you already know what goes in each circle from working with a sponsor.",
                        color: Color.rrSuccess
                    )
                }
                .padding(.horizontal)

                // Import option
                Button {
                    // Future: import from paper / photo
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.viewfinder")
                            .font(.callout)
                        Text("Import from paper circles")
                            .font(RRFont.callout)
                    }
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(minHeight: 44)
                }
                .accessibilityLabel("Import circles from a paper document")
                .padding(.top, 8)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Mode Card

    private func modeCard(
        mode: OnboardingMode,
        icon: String,
        title: String,
        duration: String,
        description: String,
        color: Color
    ) -> some View {
        let isSuggested = viewModel.suggestedMode == mode

        return Button {
            viewModel.selectMode(mode)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                        .frame(width: 40, height: 40)
                        .background(color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            if isSuggested {
                                RRBadge(text: "Suggested", color: color)
                            }
                        }

                        Text(duration)
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }

                Text(description)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(isSuggested ? color.opacity(0.05) : Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSuggested ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title), \(duration). \(description)")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModeSelectionView(viewModel: ThreeCirclesBuilderViewModel())
    }
}
