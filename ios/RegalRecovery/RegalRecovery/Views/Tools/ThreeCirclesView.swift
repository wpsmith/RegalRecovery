import SwiftUI

/// Entry point for the Three Circles feature.
/// Routes to the full circle set management experience.
struct ThreeCirclesView: View {
    var body: some View {
        CircleSetListView()
    }
}

#Preview {
    NavigationStack {
        ThreeCirclesView()
    }
}
