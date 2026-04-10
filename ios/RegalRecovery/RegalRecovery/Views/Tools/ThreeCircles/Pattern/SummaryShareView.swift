import SwiftUI

// MARK: - Summary Share View

/// Shareable summary card with granular controls over what to include.
///
/// Features:
/// - Weekly or monthly summary card
/// - Circle distribution, mood trend, top insights
/// - Granular sharing controls (toggles for each section)
/// - Share sheet (image export)
/// - Expiry selector
struct SummaryShareView: View {

    let summary: PatternSummary?

    @State private var includeDistribution = true
    @State private var includeMoodTrend = true
    @State private var includeInsights = true
    @State private var selectedExpiry: ShareExpiry = .sevenDays
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Preview Card
                    summaryCard
                        .padding(.horizontal)

                    // MARK: - Sharing Controls
                    sharingControls

                    // MARK: - Expiry Selector
                    expirySelector

                    // MARK: - Share Button
                    RRButton("Share Summary", icon: "square.and.arrow.up") {
                        showShareSheet = true
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.rrBackground)
            .navigationTitle("Share Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let renderedImage = renderSummaryCard() {
                    ShareSheetView(items: [renderedImage])
                }
            }
        }
    }

    // MARK: - Summary Card

    @ViewBuilder
    private var summaryCard: some View {
        if let summary {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Three Circles Summary")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)
                        Text("\(summary.startDate) -- \(summary.endDate)")
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                    }
                    Spacer()
                    Image(systemName: "circle.grid.3x3.fill")
                        .foregroundStyle(Color.rrPrimary)
                }

                Divider()

                // Distribution
                if includeDistribution {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Circle Distribution")
                            .font(RRFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrText)

                        distributionBar(summary: summary)

                        HStack(spacing: 16) {
                            distributionLabel("Outer", count: summary.outerDays, color: .rrSuccess)
                            distributionLabel("Middle", count: summary.middleDays, color: .orange)
                            distributionLabel("Inner", count: summary.innerDays, color: .rrDestructive)
                            distributionLabel("No log", count: summary.noCheckinDays, color: Color.rrTextSecondary.opacity(0.3))
                        }
                    }
                }

                // Mood Trend
                if includeMoodTrend, let trend = summary.moodTrend {
                    HStack(spacing: 8) {
                        Image(systemName: moodTrendIcon(trend))
                            .foregroundStyle(moodTrendColor(trend))
                        Text("Mood trend: \(moodTrendLabel(trend))")
                            .font(RRFont.subheadline)
                            .foregroundStyle(Color.rrText)
                    }
                }

                // Insights
                if includeInsights, let insights = summary.insights, !insights.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Top Insights")
                            .font(RRFont.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.rrText)

                        ForEach(insights.prefix(3)) { insight in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "lightbulb")
                                    .font(.caption)
                                    .foregroundStyle(Color.rrPrimary)
                                Text(insight.description)
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrText)
                            }
                        }
                    }
                }

                // Framing message
                if let message = summary.framingMessage {
                    Text(message)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .italic()
                }
            }
            .padding()
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        } else {
            emptyState
        }
    }

    // MARK: - Distribution Bar

    private func distributionBar(summary: PatternSummary) -> some View {
        let total = max(1, summary.outerDays + summary.middleDays + summary.innerDays + summary.noCheckinDays)

        return GeometryReader { geometry in
            HStack(spacing: 2) {
                if summary.outerDays > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrSuccess)
                        .frame(width: geometry.size.width * CGFloat(summary.outerDays) / CGFloat(total))
                }
                if summary.middleDays > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * CGFloat(summary.middleDays) / CGFloat(total))
                }
                if summary.innerDays > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrDestructive)
                        .frame(width: geometry.size.width * CGFloat(summary.innerDays) / CGFloat(total))
                }
                if summary.noCheckinDays > 0 {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.rrTextSecondary.opacity(0.3))
                        .frame(width: geometry.size.width * CGFloat(summary.noCheckinDays) / CGFloat(total))
                }
            }
        }
        .frame(height: 12)
    }

    private func distributionLabel(_ label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            RRColorDot(color, size: 8)
            Text("\(count)")
                .font(RRFont.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrText)
            Text(label)
                .font(RRFont.caption2)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    // MARK: - Sharing Controls

    private var sharingControls: some View {
        VStack(alignment: .leading, spacing: 4) {
            RRSectionHeader(title: "Include in Share")
                .padding(.horizontal)

            VStack(spacing: 0) {
                shareToggle("Circle distribution", isOn: $includeDistribution)
                Divider().padding(.leading, 16)
                shareToggle("Mood trend", isOn: $includeMoodTrend)
                Divider().padding(.leading, 16)
                shareToggle("Top insights", isOn: $includeInsights)
            }
            .background(Color.rrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal)
        }
    }

    private func shareToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
        }
        .tint(.rrPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Expiry Selector

    private var expirySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Link expires after")
                .font(RRFont.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.horizontal)

            Picker("Expiry", selection: $selectedExpiry) {
                Text("24 hours").tag(ShareExpiry.twentyFourHours)
                Text("7 days").tag(ShareExpiry.sevenDays)
                Text("Never").tag(ShareExpiry.never)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
        }
    }

    // MARK: - Mood Trend Helpers

    private func moodTrendIcon(_ trend: MoodTrend) -> String {
        switch trend {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        case .insufficientData: return "questionmark"
        }
    }

    private func moodTrendColor(_ trend: MoodTrend) -> Color {
        switch trend {
        case .improving: return .rrSuccess
        case .stable: return .rrPrimary
        case .declining: return .orange
        case .insufficientData: return Color.rrTextSecondary
        }
    }

    private func moodTrendLabel(_ trend: MoodTrend) -> String {
        switch trend {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        case .insufficientData: return "Not enough data yet"
        }
    }

    // MARK: - Render Card as Image

    @MainActor
    private func renderSummaryCard() -> UIImage? {
        let renderer = ImageRenderer(content: summaryCard.frame(width: 350))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 36))
                .foregroundStyle(Color.rrTextSecondary.opacity(0.4))
            Text("No summary available yet")
                .font(RRFont.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
            Text("Check in for at least a week to generate a shareable summary.")
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Share Sheet (UIKit bridge)

private struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SummaryShareView(
        summary: PatternSummary(
            period: .week,
            startDate: "2026-03-31",
            endDate: "2026-04-06",
            outerDays: 4,
            middleDays: 2,
            innerDays: 0,
            noCheckinDays: 1,
            insights: [
                PatternInsight(
                    insightId: "1",
                    type: .dayOfWeek,
                    description: "Weekends are more challenging. Consider scheduling extra support.",
                    confidence: .high,
                    actionSuggestion: nil,
                    dataPoints: 28,
                    detectedAt: Date()
                )
            ],
            moodTrend: .improving,
            framingMessage: "You logged 4 outer circle days, 2 middle circle days, and 1 day without a check-in."
        )
    )
}
