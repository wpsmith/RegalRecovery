import SwiftUI

/// Container view for the Gratitude feature with segmented tabs for Entry, History, and Trends.
struct GratitudeTabView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case entry = "Entry"
        case history = "History"
        case trends = "Trends"

        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .entry

    var body: some View {
        VStack(spacing: 0) {
            Picker("Gratitude", selection: $selectedTab) {
                ForEach(Tab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch selectedTab {
            case .entry:
                GratitudeListView()
            case .history:
                GratitudeHistoryView()
            case .trends:
                GratitudeTrendsView()
            }
        }
        .background(Color.rrBackground)
        .navigationTitle("Gratitude")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GratitudeTabView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
