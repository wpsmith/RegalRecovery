// Views/Activities/PCI/PCIWeeklySummaryCard.swift
import SwiftUI

struct PCIWeeklySummaryCard: View {
    let weeklyScore: Int
    let riskLevel: PCIRiskLevel
    let delta: Int?           // Week-over-week change, nil if no previous data
    let daysCompleted: Int    // 0-7, for partial week display
    let isPartialWeek: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                // Left side: large score number colored by risk level
                Text("\(weeklyScore)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(riskLevel.color)
                    .frame(minWidth: 80, alignment: .center)

                // Center: risk level name and description
                VStack(alignment: .leading, spacing: 4) {
                    Text(riskLevel.displayName)
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text(riskLevel.description)
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                // Right side: delta indicator
                if let delta {
                    deltaView(for: delta)
                        .frame(minWidth: 44)
                }
            }

            // Bottom: partial week indicator
            if isPartialWeek {
                Text("\(daysCompleted) of 7 days so far this week")
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            // Left border accent in risk level color
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(riskLevel.color)
                .frame(width: 4),
            alignment: .leading
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private func deltaView(for delta: Int) -> some View {
        if delta == 0 {
            // No change
            Text("—")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.rrTextSecondary)
        } else {
            VStack(spacing: 2) {
                Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(deltaColor(for: delta))

                Text("\(abs(delta))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(deltaColor(for: delta))
            }
        }
    }

    private func deltaColor(for delta: Int) -> Color {
        // Positive delta (score went UP) = worse = red/orange
        // Negative delta (score went DOWN) = better = green
        if delta > 0 {
            return Color(red: 255/255, green: 107/255, blue: 53/255) // Orange-red
        } else {
            return Color(red: 52/255, green: 199/255, blue: 89/255)  // Green
        }
    }
}

// MARK: - Preview

#Preview("Optimal Health - Improving") {
    PCIWeeklySummaryCard(
        weeklyScore: 7,
        riskLevel: .optimalHealth,
        delta: -3,
        daysCompleted: 7,
        isPartialWeek: false
    )
    .padding()
}

#Preview("Stable Solidity - No Change") {
    PCIWeeklySummaryCard(
        weeklyScore: 15,
        riskLevel: .stableSolidity,
        delta: 0,
        daysCompleted: 7,
        isPartialWeek: false
    )
    .padding()
}

#Preview("Medium Risk - Worsening") {
    PCIWeeklySummaryCard(
        weeklyScore: 24,
        riskLevel: .mediumRisk,
        delta: 5,
        daysCompleted: 7,
        isPartialWeek: false
    )
    .padding()
}

#Preview("High Risk - Partial Week") {
    PCIWeeklySummaryCard(
        weeklyScore: 32,
        riskLevel: .highRisk,
        delta: nil,
        daysCompleted: 4,
        isPartialWeek: true
    )
    .padding()
}

#Preview("Very High Risk") {
    PCIWeeklySummaryCard(
        weeklyScore: 43,
        riskLevel: .veryHighRisk,
        delta: 2,
        daysCompleted: 7,
        isPartialWeek: false
    )
    .padding()
}
