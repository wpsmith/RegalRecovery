// Views/Activities/LBI/LBISetupConfirmationView.swift

import SwiftUI

struct LBISetupConfirmationView: View {
    @Bindable var viewModel: LBISetupViewModel
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("You're All Set!")
                        .font(RRFont.largeTitle)
                        .foregroundStyle(Color.rrText)

                    Text("Here are your 7 critical indicators. You'll check these each day to track your Life Balance Index.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Critical items list
                RRCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Daily Check-in Items")
                            .font(RRFont.headline)
                            .foregroundStyle(Color.rrText)

                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(criticalItems.enumerated()), id: \.element.id) { index, item in
                                HStack(spacing: 12) {
                                    Text("\(index + 1).")
                                        .font(RRFont.body)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.rrPrimary)
                                        .frame(width: 24, alignment: .trailing)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.displayText)
                                            .font(RRFont.body)
                                            .foregroundStyle(Color.rrText)
                                        Text(item.dimensionType.shortName)
                                            .font(RRFont.caption)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(.vertical, 10)

                                if index < criticalItems.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                // Daily check-in info
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title2)
                                .foregroundStyle(Color.rrPrimary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Daily Check-in")
                                    .font(RRFont.headline)
                                    .foregroundStyle(Color.rrText)

                                Text("Takes less than 60 seconds")
                                    .font(RRFont.caption)
                                    .foregroundStyle(Color.rrTextSecondary)
                            }
                        }

                        Text("Each evening, simply mark which of these 7 items showed up in your day. Your weekly score will reveal patterns and help you catch lifestyle erosion early.")
                            .font(RRFont.body)
                            .foregroundStyle(Color.rrTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // About missed days
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.orange)

                            Text("About Missed Days")
                                .font(RRFont.headline)
                                .foregroundStyle(Color.rrText)
                        }

                        Text("If you miss a day, it automatically counts as 7 out of 7. This isn't a punishment — it's information. When life is so unmanageable that you can't spend 60 seconds checking in, that itself tells you something important.")
                            .font(RRFont.callout)
                            .foregroundStyle(Color.rrTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // Encouragement message
                VStack(alignment: .leading, spacing: 12) {
                    Text("You're Building a Foundation")
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    Text("By tracking these daily patterns, you're creating an early warning system for your recovery. Small slips become visible before they become crises. You've got this.")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Start tracking button
                Button(action: onComplete) {
                    Text("Start Tracking")
                        .font(RRFont.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.rrPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom, 80)
        }
        .background(Color.rrBackground)
    }

    // Get final critical items sorted by dimension sortOrder
    private var criticalItems: [LBICriticalItem] {
        viewModel.buildCriticalItems().sorted { $0.dimensionType.sortOrder < $1.dimensionType.sortOrder }
    }
}

#Preview {
    @Previewable @State var viewModel = LBISetupViewModel()

    // Mock data for preview
    viewModel.dimensionIndicators = [
        .physicalHealth: ["Skipping meals", "Not exercising"],
        .interests: ["Reading"],
        .work: ["Unreturned emails", "Late to meetings"],
        .recoveryPractice: ["Missed meeting", "Skipped journaling"]
    ]
    viewModel.allBuiltIndicators = [
        (.physicalHealth, LBIIndicator(text: "Skipping meals", isPositive: false)),
        (.physicalHealth, LBIIndicator(text: "Not exercising", isPositive: false)),
        (.interests, LBIIndicator(text: "Reading", isPositive: true)),
        (.work, LBIIndicator(text: "Unreturned emails", isPositive: false)),
        (.work, LBIIndicator(text: "Late to meetings", isPositive: false)),
        (.recoveryPractice, LBIIndicator(text: "Missed meeting", isPositive: false)),
        (.recoveryPractice, LBIIndicator(text: "Skipped journaling", isPositive: false))
    ]
    viewModel.selectedCriticalIds = Set(viewModel.allBuiltIndicators.map { $0.indicator.id })
    viewModel.currentStep = .confirmation

    return LBISetupConfirmationView(viewModel: viewModel, onComplete: {})
}
