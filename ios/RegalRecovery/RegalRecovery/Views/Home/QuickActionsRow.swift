import SwiftUI

struct QuickActionsRow: View {
    private let actions: [(title: String, icon: String)] = [
        ("Log Urge", "exclamationmark.triangle.fill"),
        ("Journal", "note.text"),
        ("Check-In", "checkmark.circle"),
        ("Prayer", "hands.clap.fill"),
        ("Mood", "face.smiling"),
        ("Gratitude", "leaf.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RRSectionHeader(title: "Quick Actions")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(actions, id: \.title) { action in
                        RRQuickAction(title: action.title, icon: action.icon) {}
                    }
                }
            }
        }
    }
}

#Preview {
    QuickActionsRow()
        .padding()
        .background(Color.rrBackground)
}
