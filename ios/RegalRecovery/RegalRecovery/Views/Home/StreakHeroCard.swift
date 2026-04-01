import SwiftUI

enum StreakDisplayMode: Int, CaseIterable {
    case totalDays = 0
    case liveCounter
    case yearsMonthsDays
    case sobrietyDate
}

struct StreakHeroCard: View {
    let streak: StreakData
    @State private var displayMode: StreakDisplayMode = .totalDays
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var sobrietyDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: streak.sobrietyDate)
    }

    private var daysToNext: Int {
        streak.nextMilestoneDays - streak.currentDays
    }

    var body: some View {
        RRCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    streakDisplay
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: displayMode)
                        .onTapGesture {
                            withAnimation {
                                let next = (displayMode.rawValue + 1) % StreakDisplayMode.allCases.count
                                displayMode = StreakDisplayMode(rawValue: next)!
                            }
                        }

                    Text("Since \(sobrietyDateFormatted)")
                        .font(RRFont.caption)
                        .foregroundStyle(Color.rrTextSecondary)
                        .padding(.bottom, 8)

                    RRBadge(
                        text: "\(daysToNext) days to \(streak.nextMilestoneDays)!",
                        color: .rrSecondary
                    )
                }

                Spacer()

                RRMilestoneCoin(days: streak.currentDays, size: 40)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.rrSuccess.opacity(0.4), Color.rrSuccess.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .onReceive(timer) { time in
            if displayMode == .liveCounter {
                now = time
            }
        }
    }

    // MARK: - Display Modes

    @ViewBuilder
    private var streakDisplay: some View {
        switch displayMode {
        case .totalDays:
            totalDaysView
        case .liveCounter:
            liveCounterView
        case .yearsMonthsDays:
            yearsMonthsDaysView
        case .sobrietyDate:
            sobrietyDateView
        }
    }

    // Mode 1: "270" + "Days Sober"
    private var totalDaysView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(streak.currentDays)")
                .font(RRFont.heroNumber)
                .foregroundStyle(Color.rrSuccess)
            Text("Days Sober")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
        }
    }

    // Mode 2: Live counter "0yr 9mo 0d 14h 32m 08s"
    private var liveCounterView: some View {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: streak.sobrietyDate,
            to: now
        )
        let yr = components.year ?? 0
        let mo = components.month ?? 0
        let d = components.day ?? 0
        let h = components.hour ?? 0
        let m = components.minute ?? 0
        let s = components.second ?? 0

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                if yr > 0 { counterUnit(yr, "yr") }
                if mo > 0 || yr > 0 { counterUnit(mo, "mo") }
                counterUnit(d, "d")
            }
            HStack(spacing: 2) {
                counterUnit(h, "h")
                counterUnit(m, "m")
                counterUnit(s, "s")
            }
            Text("Sober")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
        }
    }

    // Mode 3: "9 months, 0 days" (only showing what's needed)
    private var yearsMonthsDaysView: some View {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: streak.sobrietyDate,
            to: now
        )
        let yr = components.year ?? 0
        let mo = components.month ?? 0
        let d = components.day ?? 0

        var parts: [String] = []
        if yr > 0 { parts.append("\(yr)yr") }
        if mo > 0 { parts.append("\(mo)mo") }
        if d > 0 || parts.isEmpty { parts.append("\(d)d") }

        return VStack(alignment: .leading, spacing: 4) {
            Text(parts.joined(separator: ", "))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(Color.rrSuccess)
            Text("Sober")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
        }
    }

    // Mode 4: Sobriety date displayed large
    private var sobrietyDateView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sobrietyDateFormatted)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.rrSuccess)
            Text("Sobriety Date")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrText)
        }
    }

    // MARK: - Counter Unit

    private func counterUnit(_ value: Int, _ unit: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value)")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.rrSuccess)
            Text(unit)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.rrTextSecondary)
        }
    }
}

#Preview {
    StreakHeroCard(streak: StreakData(
        currentDays: 270,
        sobrietyDate: Calendar.current.date(byAdding: .day, value: -270, to: Date())!,
        longestStreak: 270,
        totalRelapses: 2,
        nextMilestoneDays: 300,
        milestones: []
    ))
    .padding()
    .background(Color.rrBackground)
}
