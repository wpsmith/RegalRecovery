import SwiftUI

// MARK: - Insight Card View

/// Displays a single auto-generated pattern insight.
///
/// Design:
/// - Description text uses observational framing, never judgment
/// - Confidence badge (low / medium / high)
/// - Action suggestion with tappable CTA
/// - Dismiss button (X)
/// - Subtle background tint matching insight type
struct InsightCardView: View {

    let insight: PatternInsight
    let onDismiss: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header Row
            HStack(alignment: .top) {
                Image(systemName: iconForType(insight.type))
                    .font(.body)
                    .foregroundStyle(colorForType(insight.type))
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.description)
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrText)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        if let confidence = insight.confidence {
                            confidenceBadge(confidence)
                        }

                        if let dataPoints = insight.dataPoints {
                            Text("Based on \(dataPoints) data points")
                                .font(RRFont.caption2)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                    }
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(width: 24, height: 24)
                }
                .accessibilityLabel("Dismiss insight")
            }

            // MARK: - Action Suggestion
            if let suggestion = insight.actionSuggestion {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb")
                            .font(.caption)
                        Text(suggestion)
                            .font(RRFont.caption)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(Color.rrPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.rrPrimary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(backgroundForType(insight.type))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 1)
    }

    // MARK: - Confidence Badge

    private func confidenceBadge(_ confidence: InsightConfidence) -> some View {
        Text(confidence.displayLabel)
            .font(RRFont.caption2)
            .fontWeight(.medium)
            .foregroundStyle(confidenceColor(confidence))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(confidenceColor(confidence).opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Styling Helpers

    private func iconForType(_ type: InsightType) -> String {
        switch type {
        case .dayOfWeek: return "calendar"
        case .time: return "clock"
        case .trigger: return "exclamationmark.triangle"
        case .protective: return "shield.checkered"
        case .sleep: return "moon.zzz"
        case .seeds: return "leaf"
        }
    }

    private func colorForType(_ type: InsightType) -> Color {
        switch type {
        case .dayOfWeek: return .rrPrimary
        case .time: return .rrPrimary
        case .trigger: return .orange
        case .protective: return .rrSuccess
        case .sleep: return .purple
        case .seeds: return .rrSuccess
        }
    }

    private func backgroundForType(_ type: InsightType) -> Color {
        switch type {
        case .trigger: return Color.orange.opacity(0.04)
        case .protective, .seeds: return Color.rrSuccess.opacity(0.04)
        case .sleep: return Color.purple.opacity(0.04)
        default: return Color.rrSurface
        }
    }

    private func confidenceColor(_ confidence: InsightConfidence) -> Color {
        switch confidence {
        case .low: return Color.rrTextSecondary
        case .medium: return .orange
        case .high: return .rrSuccess
        }
    }
}

// MARK: - InsightConfidence Display

extension InsightConfidence {
    var displayLabel: String {
        switch self {
        case .low: return "Low confidence"
        case .medium: return "Medium confidence"
        case .high: return "High confidence"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        InsightCardView(
            insight: PatternInsight(
                insightId: "1",
                type: .dayOfWeek,
                description: "Your outer circle days tend to cluster on weekdays. Weekends seem to be more challenging.",
                confidence: .high,
                actionSuggestion: "Consider scheduling extra support activities on weekends.",
                dataPoints: 42,
                detectedAt: Date()
            ),
            onDismiss: {}
        )

        InsightCardView(
            insight: PatternInsight(
                insightId: "2",
                type: .protective,
                description: "On days you attend meetings, you consistently stay in your outer circle.",
                confidence: .medium,
                actionSuggestion: nil,
                dataPoints: 18,
                detectedAt: Date()
            ),
            onDismiss: {}
        )
    }
    .padding()
}
