import SwiftUI

/// Entry point for the Three Circles feature.
/// Routes to the full circle set management experience.
struct ThreeCirclesView: View {
    let apiClient: ThreeCirclesAPIClient

    init(apiClient: ThreeCirclesAPIClient = ThreeCirclesAPIClient(apiClient: APIClient(configuration: .local))) {
        self.apiClient = apiClient
    }

    var body: some View {
        CircleSetListView(apiClient: apiClient)
    }
}

#Preview {
    NavigationStack {
        ThreeCirclesView()
    }
}
