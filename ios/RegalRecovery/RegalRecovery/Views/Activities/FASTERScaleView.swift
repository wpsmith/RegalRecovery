import SwiftUI
import SwiftData

/// Wrapper around the full FASTER check-in flow, used from ActivitiesListView and TodayView.
struct FASTERScaleView: View {
    var body: some View {
        FASTERCheckInFlowView()
    }
}

#Preview {
    NavigationStack {
        FASTERScaleView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
