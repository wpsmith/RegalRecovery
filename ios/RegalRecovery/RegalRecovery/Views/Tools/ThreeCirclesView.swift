import SwiftUI

struct ThreeCirclesView: View {
    @State private var redExpanded = false
    @State private var yellowExpanded = false
    @State private var greenExpanded = true

    private static let defaultRedCircle = [
        "Pornography", "Masturbation", "Objectifying others", "Visiting triggering websites"
    ]
    private static let defaultYellowCircle = [
        "Isolating from others", "Staying up late alone", "Skipping meetings",
        "Excessive screen time", "Fantasy", "Dishonesty", "Skipping prayer",
        "Avoiding sponsor calls"
    ]
    private static let defaultGreenCircle = [
        "Prayer", "Exercise", "Calling sponsor", "Attending meetings", "Journaling",
        "Scripture reading", "Date night with spouse", "Fellowship", "Acts of service",
        "Meditation", "Gratitude practice", "Consistent sleep routine"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Concentric Circles Diagram
                ZStack {
                    // Outer — Green
                    Circle()
                        .stroke(Color.rrSuccess, lineWidth: 3)
                        .frame(width: 260, height: 260)
                    Text("Green")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrSuccess)
                        .offset(y: -140)

                    // Middle — Yellow
                    Circle()
                        .stroke(Color.orange, lineWidth: 3)
                        .frame(width: 170, height: 170)
                    Text("Yellow")
                        .font(RRFont.caption)
                        .foregroundStyle(.orange)
                        .offset(y: -95)

                    // Inner — Red
                    Circle()
                        .stroke(Color.rrDestructive, lineWidth: 3)
                        .frame(width: 80, height: 80)
                    Text("Red")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrDestructive)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)

                // MARK: - Circle Sections
                circleSection(
                    title: "Red Circle (Acting Out)",
                    items: Self.defaultRedCircle,
                    color: .rrDestructive,
                    isExpanded: $redExpanded
                )

                circleSection(
                    title: "Yellow Circle (Warning)",
                    items: Self.defaultYellowCircle,
                    color: .orange,
                    isExpanded: $yellowExpanded
                )

                circleSection(
                    title: "Green Circle (Healthy)",
                    items: Self.defaultGreenCircle,
                    color: .rrSuccess,
                    isExpanded: $greenExpanded
                )
            }
            .padding()
        }
        .background(Color.rrBackground)
    }

    private func circleSection(
        title: String,
        items: [String],
        color: Color,
        isExpanded: Binding<Bool>
    ) -> some View {
        RRCard {
            DisclosureGroup(isExpanded: isExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(spacing: 10) {
                            RRColorDot(color, size: 8)
                            Text(item)
                                .font(RRFont.body)
                                .foregroundStyle(Color.rrText)
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                HStack(spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    Text(title)
                        .font(RRFont.headline)
                        .foregroundStyle(Color.rrText)
                    Spacer()
                    Text("\(items.count)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                }
            }
            .tint(color)
        }
    }
}

#Preview {
    NavigationStack {
        ThreeCirclesView()
    }
}
