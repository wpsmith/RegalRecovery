// Views/Triggers/TriggerInsightsDashboardView.swift

import SwiftUI

/// The trigger analytics dashboard showing metrics, heat map, category distribution, and top triggers.
struct TriggerInsightsDashboardView: View {
    @State private var viewModel = TriggerInsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: - Time Window Picker
                Picker("Time Window", selection: $viewModel.selectedTimeWindow) {
                    ForEach(TriggerInsightsViewModel.TimeWindow.allCases) { window in
                        Text(window.rawValue).tag(window)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // MARK: - Metrics Row
                HStack(spacing: 12) {
                    MetricCard(
                        title: "Total",
                        value: "\(viewModel.totalCount)",
                        icon: "number",
                        valueColor: .primary
                    )

                    MetricCard(
                        title: "Navigated",
                        value: "\(viewModel.resiliencePercent)%",
                        icon: "shield.checkered",
                        valueColor: .rrSuccess
                    )

                    MetricCard(
                        title: "Avg Intensity",
                        value: averageIntensityText,
                        icon: "gauge.with.needle",
                        valueColor: .primary
                    )
                }
                .padding(.horizontal)

                // MARK: - Heat Map Section
                CardSection(title: "When do triggers happen?") {
                    if viewModel.heatMapData.isEmpty {
                        Text("No trigger data available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        TriggerHeatMapView(data: viewModel.heatMapData)
                    }
                }
                .padding(.horizontal)

                // MARK: - Category Distribution
                CardSection(title: "Categories") {
                    if viewModel.categoryDistribution.isEmpty {
                        Text("No category data available")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(categoriesWithCounts, id: \.category) { item in
                                VStack(spacing: 4) {
                                    HStack(spacing: 8) {
                                        Image(systemName: item.category.icon)
                                            .font(.caption)
                                            .foregroundStyle(item.category.color)

                                        Text(item.category.displayName)
                                            .font(.subheadline)

                                        Spacer()

                                        Text("\(item.count)")
                                            .font(.subheadline.monospacedDigit())
                                            .foregroundStyle(.secondary)
                                    }

                                    // Proportional bar
                                    GeometryReader { geometry in
                                        let proportion = Double(item.count) / Double(viewModel.totalCount)
                                        let width = geometry.size.width * proportion

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(item.category.color)
                                            .frame(width: width, height: 8)
                                    }
                                    .frame(height: 8)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // MARK: - Top Triggers
                CardSection(title: "Top Triggers") {
                    let topTriggers = viewModel.topTriggers(limit: 5)

                    if topTriggers.isEmpty {
                        Text("No triggers logged yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(topTriggers.enumerated()), id: \.element.id) { index, item in
                                HStack(spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                        .frame(width: 24, alignment: .leading)

                                    Text(item.label)
                                        .font(.subheadline)

                                    Spacer()

                                    Text("\(item.count)x")
                                        .font(.subheadline.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Trigger Insights")
    }

    // MARK: - Helpers

    private var averageIntensityText: String {
        if let avg = viewModel.averageIntensity {
            return String(format: "%.1f", avg)
        } else {
            return "—"
        }
    }

    private var categoriesWithCounts: [(category: TriggerCategory, count: Int)] {
        TriggerCategory.allCases
            .compactMap { category in
                if let count = viewModel.categoryDistribution[category], count > 0 {
                    return (category, count)
                }
                return nil
            }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - MetricCard

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let valueColor: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .monospacedDigit()
                .foregroundStyle(valueColor)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - CardSection

private struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TriggerInsightsDashboardView()
    }
}
