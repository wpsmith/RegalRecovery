import SwiftUI

struct QuadrantSummaryView: View {
    @Bindable var vm: QuadrantAssessmentViewModel
    let onSave: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                radarSection

                balanceScoreSection

                if vm.computedImbalances.isEmpty {
                    positiveMessageCard
                } else {
                    imbalanceSection
                }

                if !vm.recommendations.isEmpty {
                    recommendationsSection
                }

                actionButtons
                    .padding(.bottom, 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.rrBackground)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Your Recovery Quadrant"))
                .font(RRFont.largeTitle)
                .foregroundStyle(Color.rrText)
            Text(String(localized: "Review your scores before saving"))
                .font(RRFont.subheadline)
                .foregroundStyle(Color.rrTextSecondary)
        }
    }

    private var radarSection: some View {
        HStack {
            Spacer()
            QuadrantRadarChartView(
                bodyScore: vm.scores[.body] ?? 5,
                mindScore: vm.scores[.mind] ?? 5,
                heartScore: vm.scores[.heart] ?? 5,
                spiritScore: vm.scores[.spirit] ?? 5,
                size: 220
            )
            Spacer()
        }
    }

    private var balanceScoreSection: some View {
        RRCard {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "Balance Score"))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(String(format: "%.0f", vm.computedBalanceScore))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.rrText)
                    }
                    Spacer()
                    RRBadge(text: vm.computedWellnessLevel.displayName, color: vm.computedWellnessLevel.color)
                }

                Text(vm.computedWellnessLevel.description)
                    .font(RRFont.callout)
                    .foregroundStyle(Color.rrTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                HStack(spacing: 0) {
                    ForEach(QuadrantType.allCases) { quadrant in
                        VStack(spacing: 4) {
                            Image(systemName: quadrant.icon)
                                .font(.callout)
                                .foregroundStyle(quadrant.color)
                            Text("\(vm.scores[quadrant] ?? 5)")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.rrText)
                            Text(quadrant.displayName)
                                .font(RRFont.caption2)
                                .foregroundStyle(Color.rrTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var positiveMessageCard: some View {
        RRCard {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color(.systemGreen))
                Text(String(localized: "Your recovery is well-balanced this week. Keep it up!"))
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var imbalanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Areas Needing Attention"))
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            ForEach(vm.computedImbalances) { quadrant in
                RRCard {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: quadrant.icon)
                            .font(.title3)
                            .foregroundStyle(quadrant.color)
                            .frame(width: 32, height: 32)
                            .background(quadrant.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(quadrant.displayName)
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color(.systemOrange))
                            }
                            Text(String(localized: "This area needs your attention"))
                                .font(RRFont.caption)
                                .foregroundStyle(Color.rrTextSecondary)
                            Text(String(localized: "Your \(quadrant.displayName) score is significantly lower than your other areas. Consider prioritizing \(quadrant.displayName) this week."))
                                .font(RRFont.callout)
                                .foregroundStyle(Color.rrText)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 2)
                        }
                    }
                }
            }
        }
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "Recommended This Week"))
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)

            ForEach(vm.recommendations, id: \.quadrant) { rec in
                RRCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: rec.quadrant.icon)
                                .font(.callout)
                                .foregroundStyle(rec.quadrant.color)
                                .frame(width: 28, height: 28)
                                .background(rec.quadrant.color.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                            Text(rec.quadrant.displayName)
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)

                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(rec.activities, id: \.key) { activity in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(rec.quadrant.color)
                                        .frame(width: 6, height: 6)
                                    Text(activity.label)
                                        .font(RRFont.callout)
                                        .foregroundStyle(Color.rrText)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            RRButton(String(localized: "Save Assessment"), action: onSave)

            Button(action: onBack) {
                Text(String(localized: "← Edit"))
                    .font(RRFont.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rrTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.rrSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}
