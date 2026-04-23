// Views/Activities/PCI/PCIPsychoeducationView.swift

import SwiftUI

struct PCIPsychoeducationView: View {
    let onGetStarted: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(localized: "Life Balance Index"))
                        .font(RRFont.largeTitle)
                        .foregroundStyle(Color.rrText)
                    Text(String(localized: "Inspired by Patrick Carnes' Personal Craziness Index"))
                        .font(RRFont.subheadline)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // What is the Life Balance Index?
                contentSection(
                    title: String(localized: "What is the Life Balance Index?"),
                    content: String(localized: "The Life Balance Index (LBI) is your early warning system. It tracks the daily routines and behaviors across 10 areas of your life that keep your recovery strong. When these routines start to slip — even in small ways — your LBI score rises, alerting you to take action before the erosion becomes a crisis.")
                )

                // The Boulder Metaphor
                contentSection(
                    title: String(localized: "The Boulder Metaphor"),
                    content: String(localized: "Think of relapse risk like a boulder at the top of a hill. The boulder doesn't suddenly appear — it gets nudged into motion by dozens of small slips in daily life: skipped meals, missed meetings, unpaid bills, broken promises. By the time you feel the emotional weight, the boulder is already rolling. The Life Balance Index catches those first nudges.")
                )

                // How It Works
                VStack(alignment: .leading, spacing: 12) {
                    Text(String(localized: "How It Works"))
                        .font(RRFont.title3)
                        .foregroundStyle(Color.rrText)

                    VStack(alignment: .leading, spacing: 16) {
                        numberedStep(
                            number: 1,
                            text: String(localized: "Define your personal warning signs across 10 life dimensions (about 15-20 minutes, and you can save and come back)")
                        )
                        numberedStep(
                            number: 2,
                            text: String(localized: "Choose your 7 most critical indicators for daily tracking")
                        )
                        numberedStep(
                            number: 3,
                            text: String(localized: "Each evening, spend less than 60 seconds checking which warning signs showed up today")
                        )
                        numberedStep(
                            number: 4,
                            text: String(localized: "Watch your weekly trends to catch lifestyle erosion early")
                        )
                    }
                }

                // About Missed Days
                contentSection(
                    title: String(localized: "About Missed Days"),
                    content: String(localized: "If you miss a day, it automatically counts as 7 out of 7. This isn't a punishment — it's information. When life is so unmanageable that you can't spend 60 seconds checking in, that itself tells you something important.")
                )

                // Get Started Button
                RRButton(String(localized: "Get Started"), action: onGetStarted)
                    .padding(.top, 8)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .background(Color.rrBackground)
    }

    @ViewBuilder
    private func contentSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
            Text(content)
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func numberedStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.rrPrimary)
                .frame(width: 28, height: 28)
                .overlay(
                    Text("\(number)")
                        .font(RRFont.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                )
            Text(text)
                .font(RRFont.body)
                .foregroundStyle(Color.rrTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    PCIPsychoeducationView(onGetStarted: {})
}
