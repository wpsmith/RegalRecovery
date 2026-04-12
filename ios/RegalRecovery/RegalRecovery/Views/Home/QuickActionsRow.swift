import SwiftUI

struct QuickActionsRow: View {
    @State private var showFASTER = false

    private let actions: [(title: String, icon: String)] = [
        ("Log Urge", "exclamationmark.triangle.fill"),
        ("Journal", "note.text"),
        ("Prayer", "hands.clap.fill"),
        ("Mood", "face.smiling"),
        ("Gratitude", "leaf.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Quick Actions")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Button { showFASTER = true } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gauge.with.dots.needle.33percent")
                                .font(.caption)
                            Text("FASTER")
                                .font(RRFont.caption)
                                .fontWeight(.medium)
                            Text("NEW")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .foregroundStyle(.white)
                                .background(Color.rrSecondary)
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .foregroundStyle(Color.rrPrimary)
                        .background(Color.rrPrimary.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    ForEach(actions, id: \.title) { action in
                        RRQuickAction(title: action.title, icon: action.icon) {}
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFASTER) {
            FASTERCheckInFlowView()
        }
    }
}

#Preview {
    QuickActionsRow()
        .padding()
        .background(Color.rrBackground)
}
