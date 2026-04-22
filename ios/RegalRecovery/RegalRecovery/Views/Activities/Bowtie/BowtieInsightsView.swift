import SwiftUI

struct BowtieInsightsView: View {
    let viewModel: BowtieHistoryViewModel
    let roles: [RRUserRole]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                iDistributionSection
                roleActivationSection
                anticipatoryRatioSection
                backboneCompletionSection
            }
            .padding()
        }
        .background(Color.rrBackground)
        .navigationTitle(String(localized: "Insights"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - I-Distribution

    private var iDistributionSection: some View {
        let dist = viewModel.totalIDistribution
        let maxVal = max(dist.insignificance, dist.incompetence, dist.impotence, 1)

        return RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "I-Distribution"))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                iDistributionBar(
                    label: ThreeIType.insignificance.displayName,
                    value: dist.insignificance,
                    maxValue: maxVal,
                    color: ThreeIType.insignificance.color
                )

                iDistributionBar(
                    label: ThreeIType.incompetence.displayName,
                    value: dist.incompetence,
                    maxValue: maxVal,
                    color: ThreeIType.incompetence.color
                )

                iDistributionBar(
                    label: ThreeIType.impotence.displayName,
                    value: dist.impotence,
                    maxValue: maxVal,
                    color: ThreeIType.impotence.color
                )

                if let dominant = dist.dominant {
                    Text(String(localized: "Your primary emotional vulnerability is \(dominant.displayName)."))
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func iDistributionBar(label: String, value: Int, maxValue: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(RRFont.caption)
                    .foregroundStyle(Color.rrText)
                Spacer()
                Text("\(value)")
                    .font(RRFont.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rrText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.rrSurface)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(value) / CGFloat(maxValue), height: 8)
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "\(label): \(value)"))
    }

    // MARK: - Role Activation

    private var roleActivationSection: some View {
        let activations = viewModel.roleActivations(roles: roles)
        let maxIntensity = activations.map(\.totalIntensity).max() ?? 1

        return RRCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(String(localized: "Role Activation"))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Text(String(localized: "The roles carrying the most emotional weight."))
                    .font(RRFont.subheadline)
                    .foregroundStyle(Color.rrTextSecondary)

                if activations.isEmpty {
                    Text(String(localized: "No role activations recorded yet."))
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                } else {
                    ForEach(activations.filter({ $0.totalIntensity > 0 })) { activation in
                        HStack(spacing: 12) {
                            Text(activation.label)
                                .font(RRFont.subheadline)
                                .foregroundStyle(Color.rrText)
                                .frame(width: 100, alignment: .leading)

                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.rrSurface)
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.rrPrimary)
                                        .frame(
                                            width: geometry.size.width * CGFloat(activation.totalIntensity) / CGFloat(max(maxIntensity, 1)),
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)

                            Text("\(activation.totalIntensity)")
                                .font(RRFont.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.rrText)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Anticipatory Ratio

    private var anticipatoryRatioSection: some View {
        let ratio = viewModel.anticipatoryRatio
        let percentage = Int(ratio * 100)

        return RRCard {
            VStack(spacing: 16) {
                Text(String(localized: "Anticipatory Awareness"))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(Color.rrSurface, lineWidth: 10)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(ratio))
                        .stroke(Color.rrPrimary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    Text("\(percentage)%")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.rrText)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "Anticipatory awareness: \(percentage) percent"))

                if ratio > 0.5 {
                    Text(String(localized: "Your anticipatory awareness is strong \u{2014} you're spending more time preparing than reacting."))
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(String(localized: "Your anticipatory awareness is growing. Keep building the habit of looking ahead."))
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    // MARK: - Backbone Completion

    private var backboneCompletionSection: some View {
        let rate = viewModel.backboneCompletionRate
        let percentage = Int(rate * 100)

        return RRCard {
            VStack(spacing: 16) {
                Text(String(localized: "Backbone Completion"))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    Circle()
                        .stroke(Color.rrSurface, lineWidth: 10)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: CGFloat(rate))
                        .stroke(Color.rrSecondary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    Text("\(percentage)%")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.rrText)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(String(localized: "Backbone completion: \(percentage) percent"))

                Text(String(localized: "\(percentage)% of your activation points have been fully processed."))
                    .font(RRFont.subheadline)
                    .foregroundStyle(Color.rrTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
