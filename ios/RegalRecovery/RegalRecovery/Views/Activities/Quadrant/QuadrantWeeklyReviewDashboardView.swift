import SwiftUI

struct QuadrantWeeklyReviewDashboardView: View {
    @Bindable var vm: QuadrantWeeklyReviewDashboardViewModel
    let onStartAssessment: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                thisWeekCard

                QuadrantWeeklyReviewTrendChartView(trendData: vm.trendData)

                if !vm.recommendations.isEmpty {
                    recommendationsSection
                }

                if vm.hasAssessedThisWeek {
                    updateButton
                }

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(Color.rrBackground)
        .navigationTitle(String(localized: "Weekly Quadrant Review"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var thisWeekCard: some View {
        if vm.hasAssessedThisWeek, let assessment = vm.currentAssessment {
            RRCard {
                VStack(spacing: 16) {
                    HStack {
                        Text(String(localized: "This Week"))
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)
                        Spacer()
                        RRBadge(
                            text: assessment.wellnessLevelEnum.displayName,
                            color: assessment.wellnessLevelEnum.color
                        )
                    }

                    HStack {
                        Spacer()
                        QuadrantWeeklyReviewRadarChartView(
                            bodyScore: assessment.bodyScore,
                            mindScore: assessment.mindScore,
                            heartScore: assessment.heartScore,
                            spiritScore: assessment.spiritScore,
                            size: 200
                        )
                        Spacer()
                    }

                    HStack(spacing: 0) {
                        ForEach(QuadrantWeeklyReviewType.allCases) { quadrant in
                            let score: Int = {
                                switch quadrant {
                                case .body: return assessment.bodyScore
                                case .mind: return assessment.mindScore
                                case .heart: return assessment.heartScore
                                case .spirit: return assessment.spiritScore
                                }
                            }()
                            VStack(spacing: 4) {
                                Image(systemName: quadrant.icon)
                                    .font(.callout)
                                    .foregroundStyle(quadrant.color)
                                Text("\(score)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundStyle(Color.rrText)
                                Text(quadrant.displayName)
                                    .font(RRFont.caption2)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(String(localized: "Balance Score"))
                            .font(RRFont.caption)
                            .foregroundStyle(Color.rrTextSecondary)
                        Text(String(format: "%.0f", assessment.balanceScore))
                            .font(.system(.callout, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.rrText)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        } else {
            RRCard {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(.systemPurple))

                    VStack(spacing: 6) {
                        Text(String(localized: "Time for your weekly check-in"))
                            .font(RRFont.title3)
                            .foregroundStyle(Color.rrText)
                        Text(String(localized: "See the shape of your recovery this week"))
                            .font(RRFont.callout)
                            .foregroundStyle(Color.rrTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    RRButton(String(localized: "Start Assessment"), action: onStartAssessment)
                }
                .frame(maxWidth: .infinity)
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
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: rec.quadrant.icon)
                            .font(.callout)
                            .foregroundStyle(rec.quadrant.color)
                            .frame(width: 32, height: 32)
                            .background(rec.quadrant.color.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(rec.quadrant.displayName)
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)
                                if rec.isImbalanced {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(.systemOrange))
                                }
                            }

                            ForEach(rec.activities, id: \.key) { activity in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(rec.quadrant.color)
                                        .frame(width: 5, height: 5)
                                    Text(activity.label)
                                        .font(RRFont.callout)
                                        .foregroundStyle(Color.rrText)
                                }
                            }
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private var updateButton: some View {
        Button {
            onStartAssessment()
        } label: {
            Text(String(localized: "Update This Week's Assessment"))
                .font(RRFont.body)
                .fontWeight(.semibold)
                .foregroundStyle(Color.rrPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.rrPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack {
        QuadrantWeeklyReviewDashboardView(
            vm: QuadrantWeeklyReviewDashboardViewModel(),
            onStartAssessment: {}
        )
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
