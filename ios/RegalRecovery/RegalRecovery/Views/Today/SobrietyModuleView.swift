import SwiftUI

// MARK: - Addiction Color Palette

private let addictionColors: [Color] = [.blue, .purple, .orange, .pink, .teal, .mint]

private func colorForAddiction(at index: Int) -> Color {
    addictionColors[index % addictionColors.count]
}

// MARK: - SobrietyModuleView

struct SobrietyModuleView: View {
    let addictions: [SobrietyAddictionData]
    let onResetSobriety: (UUID, Date) -> Void

    @State private var viewMode: Int = 0
    @State private var selectedAddictionID: UUID?
    @State private var calendarDisplayedMonth = Date()

    // Live counter timer
    @State private var now = Date()
    @State private var timer: Timer?

    // Reset flow
    @State private var showAddictionPicker = false
    @State private var resetTargetAddiction: SobrietyAddictionData?
    @State private var showResetSheet = false
    @State private var resetSelectedDate = Date()
    @State private var showEncouragement = false
    @State private var encouragementMessage = ""

    private static let soberSinceDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    // MARK: - Computed Properties

    private var activeAddiction: SobrietyAddictionData? {
        if selectedAddictionID == nil {
            return allAddiction
        }
        return addictions.first { $0.id == selectedAddictionID }
    }

    /// "All" mode uses the MOST RECENT sobriety date (fewest sober days).
    private var allAddiction: SobrietyAddictionData? {
        guard let mostRecent = addictions.max(by: { $0.sobrietyDate < $1.sobrietyDate }) else {
            return nil
        }
        return SobrietyAddictionData(
            id: UUID(),
            name: "All",
            sobrietyDate: mostRecent.sobrietyDate
        )
    }

    private var activeSobrietyDate: Date {
        activeAddiction?.sobrietyDate ?? Date()
    }

    private var activeID: UUID {
        if let selectedAddictionID {
            return selectedAddictionID
        }
        // For "All", use the most-recent addiction's real ID
        return addictions.max(by: { $0.sobrietyDate < $1.sobrietyDate })?.id ?? UUID()
    }

    private var totalDays: Int {
        max(0, Calendar.current.dateComponents([.day], from: activeSobrietyDate, to: Date()).day ?? 0)
    }

    private var breakdownComponents: (years: Int, months: Int, days: Int) {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month, .day], from: activeSobrietyDate, to: Date())
        return (
            years: max(0, components.year ?? 0),
            months: max(0, components.month ?? 0),
            days: max(0, components.day ?? 0)
        )
    }

    private var soberSinceText: String {
        let dateString = Self.soberSinceDateFormatter.string(from: activeSobrietyDate)
        return String(localized: "Sober since \(dateString)")
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 12) {
            // Header row: pill bar + reset icon
            HStack(alignment: .center) {
                if addictions.count > 1 {
                    addictionPillBar
                } else {
                    Spacer()
                }

                Button {
                    beginResetFlow()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrTextSecondary)
                }
                .buttonStyle(.plain)
            }

            // Main content area — tappable + swipeable to cycle views
            VStack(spacing: 8) {
                Spacer(minLength: 0)
                switch viewMode {
                case 0:
                    daysView
                case 1:
                    breakdownView
                case 2:
                    liveCounterView
                case 3:
                    calendarView
                default:
                    daysView
                }
                Spacer(minLength: 0)
            }
            .frame(height: 280)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewMode = (viewMode + 1) % 4
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height
                        // Only act on primarily horizontal swipes
                        guard abs(horizontal) > abs(vertical) else { return }
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if horizontal < 0 {
                                // Swipe left -> next view
                                viewMode = (viewMode + 1) % 4
                            } else {
                                // Swipe right -> previous view
                                viewMode = (viewMode - 1 + 4) % 4
                            }
                        }
                    }
            )

            // Dot indicators
            dotIndicators
        }
        .padding()
        .background(Color.rrSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .onChange(of: viewMode) { _, newValue in
            if newValue == 2 {
                startTimer()
            } else {
                stopTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        // Addiction picker (when "All" is selected and user taps reset)
        .confirmationDialog(
            "Which addiction do you want to reset?",
            isPresented: $showAddictionPicker,
            titleVisibility: .visible
        ) {
            ForEach(addictions) { addiction in
                Button(addiction.name) {
                    resetTargetAddiction = addiction
                    resetSelectedDate = Date()
                    showResetSheet = true
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        // Reset date picker full-screen sheet
        .fullScreenCover(isPresented: $showResetSheet) {
            resetDatePickerSheet
        }
        // Encouragement full-screen sheet
        .fullScreenCover(isPresented: $showEncouragement) {
            encouragementSheet
        }
    }

    // MARK: - Reset Flow

    private func beginResetFlow() {
        if let selectedID = selectedAddictionID,
           let addiction = addictions.first(where: { $0.id == selectedID }) {
            // Specific addiction selected — go directly to reset sheet
            resetTargetAddiction = addiction
            resetSelectedDate = Date()
            showResetSheet = true
        } else {
            if addictions.count == 1 {
                // Only one addiction — go directly
                resetTargetAddiction = addictions[0]
                resetSelectedDate = Date()
                showResetSheet = true
            } else {
                // "All" mode with multiple — show picker first
                showAddictionPicker = true
            }
        }
    }

    // MARK: - Reset Date Picker Sheet

    private var resetDatePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                if let target = resetTargetAddiction {
                    Text(target.name)
                        .font(RRFont.title)
                        .foregroundStyle(Color.rrText)
                }

                DatePicker(
                    "New sobriety date",
                    selection: $resetSelectedDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding(.horizontal)

                Button(role: .destructive) {
                    guard let target = resetTargetAddiction else { return }
                    onResetSobriety(target.id, resetSelectedDate)
                    showResetSheet = false
                    encouragementMessage = ContentData.sobrietyResetMessages.randomElement()
                        ?? String(localized: "You got back up. That takes courage.")
                    // Show encouragement after a brief delay so the sheet dismiss animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        showEncouragement = true
                    }
                } label: {
                    Text("Reset Sobriety Date")
                        .font(RRFont.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.rrDestructive)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Reset Sobriety")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showResetSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Encouragement Sheet

    private var encouragementSheet: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hands.and.sparkles.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color.rrPrimary)

            Text(encouragementMessage)
                .font(RRFont.body)
                .foregroundStyle(Color.rrText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                showEncouragement = false
            } label: {
                Text("Continue")
                    .font(RRFont.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.rrPrimary)
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .background(Color.rrBackground)
    }

    // MARK: - Addiction Pill Bar

    private var addictionPillBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                pillButton(label: String(localized: "All"), color: nil, isSelected: selectedAddictionID == nil) {
                    selectedAddictionID = nil
                    calendarDisplayedMonth = Date()
                }
                ForEach(Array(addictions.enumerated()), id: \.element.id) { index, addiction in
                    pillButton(
                        label: addiction.name,
                        color: colorForAddiction(at: index),
                        isSelected: selectedAddictionID == addiction.id
                    ) {
                        selectedAddictionID = addiction.id
                        calendarDisplayedMonth = Date()
                    }
                }
            }
        }
    }

    private func pillButton(label: String, color: Color?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let color {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                }
                Text(label)
                    .font(RRFont.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? Color.white : Color.rrText)
            .background(
                Capsule()
                    .fill(isSelected ? Color.rrPrimary : Color.rrBackground)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - View Mode 0: Days

    private var daysView: some View {
        VStack(spacing: 4) {
            Text("\(totalDays)")
                .font(RRFont.heroNumber)
                .foregroundStyle(Color.rrPrimary)
                .contentTransition(.numericText())

            Text("days sober")
                .font(RRFont.title3)
                .foregroundStyle(Color.rrTextSecondary)

            Text(soberSinceText)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - View Mode 1: Breakdown

    private var breakdownView: some View {
        VStack(spacing: 4) {
            Text(breakdownString)
                .font(RRFont.title)
                .foregroundStyle(Color.rrPrimary)
                .multilineTextAlignment(.center)

            Text(soberSinceText)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var breakdownString: String {
        let b = breakdownComponents
        var parts: [String] = []
        if b.years > 0 {
            let yearLabel = b.years == 1 ? String(localized: "year") : String(localized: "years")
            parts.append("\(b.years) \(yearLabel)")
        }
        if b.months > 0 {
            let monthLabel = b.months == 1 ? String(localized: "month") : String(localized: "months")
            parts.append("\(b.months) \(monthLabel)")
        }
        // Always show days in breakdown
        let dayLabel = b.days == 1 ? String(localized: "day") : String(localized: "days")
        parts.append("\(b.days) \(dayLabel)")
        return parts.joined(separator: ", ")
    }

    // MARK: - View Mode 2: Live Counter

    private var liveCounterView: some View {
        VStack(spacing: 4) {
            Text(liveCounterString)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(Color.rrPrimary)

            Text(soberSinceText)
                .font(RRFont.caption)
                .foregroundStyle(Color.rrTextSecondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .onAppear {
            if viewMode == 2 {
                startTimer()
            }
        }
    }

    private var liveCounterString: String {
        let interval = max(0, now.timeIntervalSince(activeSobrietyDate))
        let totalSeconds = Int(interval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%dd %dh %02dm %02ds", days, hours, minutes, seconds)
    }

    private func startTimer() {
        now = Date()
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            now = Date()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - View Mode 3: Calendar

    private var calendarView: some View {
        VStack(spacing: 8) {
            // Month navigation header
            HStack {
                Button {
                    calendarDisplayedMonth = Calendar.current.date(
                        byAdding: .month, value: -1, to: calendarDisplayedMonth
                    ) ?? calendarDisplayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrPrimary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthYearString(for: calendarDisplayedMonth))
                    .font(RRFont.headline)
                    .foregroundStyle(Color.rrText)

                Spacer()

                Button {
                    calendarDisplayedMonth = Calendar.current.date(
                        byAdding: .month, value: 1, to: calendarDisplayedMonth
                    ) ?? calendarDisplayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(RRFont.body)
                        .foregroundStyle(Color.rrPrimary)
                }
                .buttonStyle(.plain)
            }

            // Weekday labels
            let weekdays = [String(localized: "S"), String(localized: "M"), String(localized: "T"), String(localized: "W"), String(localized: "T"), String(localized: "F"), String(localized: "S")]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(RRFont.caption2)
                        .foregroundStyle(Color.rrTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let calendarDays = generateCalendarDays()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(calendarDays, id: \.self) { day in
                    calendarDayCell(day: day)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    private func generateCalendarDays() -> [Date] {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: calendarDisplayedMonth),
              let firstWeek = cal.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        else {
            return []
        }

        var days: [Date] = []
        var current = firstWeek.start

        // Generate up to 6 weeks of days
        let endLimit = cal.date(byAdding: .day, value: 42, to: firstWeek.start) ?? firstWeek.start
        while current < endLimit {
            days.append(current)
            current = cal.date(byAdding: .day, value: 1, to: current) ?? current
            // Stop after we've passed the month and completed the week row
            if current >= monthInterval.end && cal.component(.weekday, from: current) == cal.firstWeekday {
                break
            }
        }

        return days
    }

    @ViewBuilder
    private func calendarDayCell(day: Date) -> some View {
        let cal = Calendar.current
        let displayedMonthValue = cal.component(.month, from: calendarDisplayedMonth)
        let dayMonthValue = cal.component(.month, from: day)
        let isCurrentMonth = displayedMonthValue == dayMonthValue
        let dayNumber = cal.component(.day, from: day)
        let today = cal.startOfDay(for: Date())
        let dayStart = cal.startOfDay(for: day)
        let isToday = cal.isDateInToday(day)

        if !isCurrentMonth {
            // Empty cell for days outside the displayed month
            Text("")
                .font(RRFont.caption2)
                .frame(maxWidth: .infinity, minHeight: 28)
        } else if selectedAddictionID == nil && addictions.count > 1 {
            // "All" mode — show multi-color indicators per addiction
            let soberAddictions = addictions.enumerated().filter { _, addiction in
                let sobrietyStart = cal.startOfDay(for: addiction.sobrietyDate)
                return dayStart >= sobrietyStart && dayStart <= today
            }
            Text("\(dayNumber)")
                .font(RRFont.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .frame(maxWidth: .infinity, minHeight: 28)
                .foregroundStyle(soberAddictions.isEmpty ? Color.rrText : Color.white)
                .background(
                    Group {
                        if !soberAddictions.isEmpty {
                            if isToday {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.rrPrimary)
                            } else if soberAddictions.count == 1 {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorForAddiction(at: soberAddictions[0].offset))
                            } else {
                                // Multiple addictions sober on this day — gradient
                                let colors = soberAddictions.map { colorForAddiction(at: $0.offset) }
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: colors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                    }
                )
        } else {
            // Single addiction mode (or single addiction total)
            let sobrietyStart = cal.startOfDay(for: activeSobrietyDate)
            let isBeforeSobriety = dayStart < sobrietyStart
            let isSoberDay = dayStart >= sobrietyStart && dayStart <= today

            Text("\(dayNumber)")
                .font(RRFont.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .frame(maxWidth: .infinity, minHeight: 28)
                .foregroundStyle(
                    isBeforeSobriety ? Color.rrTextSecondary.opacity(0.3) :
                    isSoberDay ? Color.white : Color.rrText
                )
                .background(
                    Group {
                        if isSoberDay {
                            if let selectedID = selectedAddictionID,
                               let idx = addictions.firstIndex(where: { $0.id == selectedID }) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isToday ? Color.rrPrimary : colorForAddiction(at: idx))
                            } else {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isToday ? Color.rrPrimary : Color.rrSuccess)
                            }
                        }
                    }
                )
        }
    }

    // MARK: - Dot Indicators

    private var dotIndicators: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .fill(index == viewMode ? Color.rrPrimary : Color.rrTextSecondary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}
