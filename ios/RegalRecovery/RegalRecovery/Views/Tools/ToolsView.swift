import SwiftUI

struct ToolsView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    toolCard(
                        destination: FASTERScaleToolView(),
                        icon: "gauge.with.needle",
                        iconColor: .rrSuccess,
                        title: "FASTER Scale",
                        subtitle: "Current: Green"
                    )
                    toolCard(
                        destination: ThreeCirclesView(),
                        icon: "circles.hexagongrid",
                        iconColor: .rrPrimary,
                        title: "3 Circles",
                        subtitle: "Boundary Tool"
                    )
                    toolCard(
                        destination: PanicButtonView(),
                        icon: "exclamationmark.shield.fill",
                        iconColor: .rrDestructive,
                        title: "Panic Button",
                        subtitle: "Emergency Tools"
                    )
                    if FeatureFlagStore.shared.isEnabled("feature.vision") {
                        toolCard(
                            destination: VisionHubView(),
                            icon: "eye.fill",
                            iconColor: .rrPrimary,
                            title: "Vision",
                            subtitle: "Your Recovery Why"
                        )
                    }
                    if FeatureFlagStore.shared.isEnabled("feature.motivations") {
                        toolCard(
                            destination: MotivationLibraryView(),
                            icon: "flame.fill",
                            iconColor: .orange,
                            title: "Motivations",
                            subtitle: "Your Recovery Why"
                        )
                    }
                }
                .padding()
            }
            .background(Color.rrBackground)
        }
    }

    private func toolCard<Destination: View>(
        destination: Destination,
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String
    ) -> some View {
        NavigationLink(destination: destination) {
            RRCard {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundStyle(iconColor)
                    Text(title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Text(subtitle)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ToolsView()
}
