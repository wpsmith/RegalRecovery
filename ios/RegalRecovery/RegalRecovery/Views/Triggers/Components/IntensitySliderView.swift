import SwiftUI

struct IntensitySliderView: View {
    @Binding var intensity: Int
    @Binding var isIncluded: Bool

    private var riskLevel: RiskLevel {
        RiskLevel.from(intensity: intensity)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header row
            HStack {
                Text("Intensity")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.rrText)

                Spacer()

                Text("\(intensity)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .monospacedDigit()
                    .foregroundStyle(riskLevel.color)

                Toggle("", isOn: $isIncluded)
                    .labelsHidden()
            }

            if isIncluded {
                // Slider
                Slider(
                    value: Binding(
                        get: { Double(intensity) },
                        set: { intensity = Int($0) }
                    ),
                    in: 1...10,
                    step: 1
                )
                .tint(riskLevel.color)
                .accessibilityLabel("Intensity: \(intensity) of 10, \(riskLevel.displayName)")

                // Anchor labels
                HStack {
                    Text("Barely noticeable")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("Moderate")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("Overwhelming")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Intensity Slider") {
    struct PreviewWrapper: View {
        @State private var intensity = 5
        @State private var isIncluded = true

        var body: some View {
            VStack(spacing: 24) {
                IntensitySliderView(
                    intensity: $intensity,
                    isIncluded: $isIncluded
                )
                .padding()
                .background(Color.rrSurface)
                .cornerRadius(12)

                Text("Current: \(intensity), Risk: \(RiskLevel.from(intensity: intensity).displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    return PreviewWrapper()
}

#Preview("Multiple States") {
    struct PreviewWrapper: View {
        @State private var intensity1 = 2
        @State private var isIncluded1 = true

        @State private var intensity2 = 5
        @State private var isIncluded2 = true

        @State private var intensity3 = 8
        @State private var isIncluded3 = true

        @State private var intensity4 = 5
        @State private var isIncluded4 = false

        var body: some View {
            VStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Low (2)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    IntensitySliderView(
                        intensity: $intensity1,
                        isIncluded: $isIncluded1
                    )
                }

                VStack(alignment: .leading) {
                    Text("Moderate (5)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    IntensitySliderView(
                        intensity: $intensity2,
                        isIncluded: $isIncluded2
                    )
                }

                VStack(alignment: .leading) {
                    Text("High (8)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    IntensitySliderView(
                        intensity: $intensity3,
                        isIncluded: $isIncluded3
                    )
                }

                VStack(alignment: .leading) {
                    Text("Disabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    IntensitySliderView(
                        intensity: $intensity4,
                        isIncluded: $isIncluded4
                    )
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
