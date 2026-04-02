import SwiftUI
import SwiftData

struct PrayerLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RRPrayerLog.date, order: .reverse) private var entries: [RRPrayerLog]
    @Query(sort: \RRUser.createdAt) private var users: [RRUser]

    @State private var now = Date()
    @State private var cooldownTimer: Timer?

    private let onceDailyPrayers: Set<String> = ["Morning Prayer", "Evening Prayer"]

    private var todayEntries: [RRPrayerLog] {
        entries.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var pastEntries: [RRPrayerLog] {
        entries.filter { !Calendar.current.isDateInToday($0.date) }
    }

    private var completedTodayTitles: Set<String> {
        Set(todayEntries.map(\.prayerType))
    }

    /// Any prayer done today gets a checkmark
    private func isDoneToday(_ prayer: PrayerItem) -> Bool {
        completedTodayTitles.contains(prayer.title)
    }

    /// Once-daily prayers (Morning/Evening) are fully locked after done
    private func isOnceDailyLocked(_ prayer: PrayerItem) -> Bool {
        onceDailyPrayers.contains(prayer.title) && completedTodayTitles.contains(prayer.title)
    }

    private func isOnCooldown(_ prayer: PrayerItem) -> Bool {
        let cutoff = now.addingTimeInterval(-120)
        return entries.contains { $0.prayerType == prayer.title && $0.date > cutoff }
    }

    /// 0.0 = just logged, 1.0 = cooldown expired
    private func cooldownProgress(for prayer: PrayerItem) -> Double {
        guard let lastLog = entries.first(where: { $0.prayerType == prayer.title }),
              lastLog.date > now.addingTimeInterval(-120) else { return 1.0 }
        return min(1.0, now.timeIntervalSince(lastLog.date) / 120.0)
    }

    private var anyCooldownActive: Bool {
        entries.contains { $0.date > now.addingTimeInterval(-120) }
    }

    private func relativeDay(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return "Today, \(date.formatted(date: .omitted, time: .shortened))"
        }
        if cal.isDateInYesterday(date) {
            return "Yesterday, \(date.formatted(date: .omitted, time: .shortened))"
        }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days) days ago"
    }

    private func startCooldownTimerIfNeeded() {
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        guard anyCooldownActive else { return }
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            now = Date()
            if !anyCooldownActive {
                cooldownTimer?.invalidate()
                cooldownTimer = nil
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Recovery prayers
                RRCard {
                    VStack(alignment: .leading, spacing: 12) {
                        RRSectionHeader(title: "Recovery Prayers")

                        ForEach(ContentData.prayers) { prayer in
                            let locked = isOnceDailyLocked(prayer)
                            let cooldown = !locked && isOnCooldown(prayer)
                            let done = isDoneToday(prayer)
                            let disabled = locked || cooldown

                            NavigationLink {
                                PrayersView(
                                    prayer: prayer,
                                    isCompletedToday: locked,
                                    isOnCooldown: cooldown
                                )
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: prayer.icon)
                                        .font(.title3)
                                        .foregroundStyle(disabled ? Color.rrTextSecondary : Color.rrPrimary)
                                        .frame(width: 28)

                                    Text(prayer.title)
                                        .font(RRFont.body)
                                        .foregroundStyle(disabled ? Color.rrTextSecondary : Color.rrText)

                                    Spacer()

                                    // Checkmark if done today (always, regardless of type)
                                    if done {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.rrSuccess)
                                            .font(.body)
                                    }

                                    if locked {
                                        Text("Done today")
                                            .font(RRFont.caption2)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(Color.rrTextSecondary)
                                    }
                                }
                                .padding(.vertical, 4)
                                .clipShape(Rectangle())
                                .overlay(alignment: .trailing) {
                                    // Cooldown: gray overlay that shrinks from right to left
                                    if cooldown {
                                        GeometryReader { geo in
                                            Rectangle()
                                                .fill(Color.gray.opacity(0.15))
                                                .frame(width: geo.size.width * (1.0 - cooldownProgress(for: prayer)))
                                                .animation(.linear(duration: 1), value: now)
                                        }
                                        .allowsHitTesting(false)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .disabled(disabled)

                            if prayer.id != ContentData.prayers.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Today
                if !todayEntries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            RRSectionHeader(title: "Today")

                            ForEach(todayEntries) { entry in
                                historyRow(entry)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(entry)
                                            startCooldownTimerIfNeeded()
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                if entry.id != todayEntries.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // History
                if !pastEntries.isEmpty {
                    RRCard {
                        VStack(alignment: .leading, spacing: 16) {
                            RRSectionHeader(title: "History")

                            ForEach(pastEntries) { entry in
                                historyRow(entry)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(entry)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                if entry.id != pastEntries.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.rrBackground)
        .navigationTitle("Prayer")
        .onAppear { startCooldownTimerIfNeeded() }
        .onDisappear {
            cooldownTimer?.invalidate()
            cooldownTimer = nil
        }
        .onChange(of: entries.count) { _, _ in
            startCooldownTimerIfNeeded()
        }
    }

    private func historyRow(_ entry: RRPrayerLog) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.rrSuccess)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.prayerType)
                    .font(RRFont.body)
                    .foregroundStyle(Color.rrText)

                Text(relativeDay(entry.date))
                    .font(RRFont.subheadline)
                    .foregroundStyle(Color.rrTextSecondary)
            }

            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        PrayerLogView()
    }
    .modelContainer(try! RRModelConfiguration.makeContainer(inMemory: true))
}
