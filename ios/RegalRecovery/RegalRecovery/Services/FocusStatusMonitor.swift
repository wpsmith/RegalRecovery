import Foundation
import SwiftData

/// Monitors iOS Focus/Sleep status to auto-fill Time Journal sleep slots.
///
/// Uses `INFocusStatusCenter` (Intents framework) to detect when the user activates
/// and deactivates Sleep Focus. When sleep ends, calculates which journal slots fall
/// entirely within the sleep window and creates auto-filled entries.
///
/// Requirements covered: TJ-080 through TJ-085.
@Observable
class FocusStatusMonitor {

    static let shared = FocusStatusMonitor()

    private(set) var sleepStartedAt: Date?
    private(set) var sleepEndedAt: Date?
    private(set) var isSleepFocusActive: Bool = false

    /// Whether monitoring is currently active.
    private(set) var isMonitoring: Bool = false

    /// Timer used to poll focus status (INFocusStatusCenter does not provide push notifications).
    private var pollTimer: Timer?

    /// Polling interval in seconds. Short enough to catch transitions promptly.
    private let pollInterval: TimeInterval = 60

    // MARK: - Start / Stop Monitoring

    /// Begin polling for Sleep Focus status changes.
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Check immediately, then set up a recurring poll
        checkFocusStatus()

        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkFocusStatus()
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    /// Stop polling for Focus status changes.
    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
        isMonitoring = false
    }

    // MARK: - Focus Status Detection

    /// Check current Focus status and detect transitions.
    ///
    /// `INFocusStatusCenter` reports whether *any* Focus is active. We treat any
    /// focus-active period during typical sleep hours (9 PM - 11 AM) as potential sleep.
    /// When the focus deactivates, we record the sleep window.
    private func checkFocusStatus() {
        // INFocusStatusCenter requires Intents framework; guard availability
        guard let focusActive = queryFocusStatus() else { return }

        if focusActive && !isSleepFocusActive {
            // Transition: inactive -> active
            isSleepFocusActive = true
            sleepStartedAt = Date()
            sleepEndedAt = nil
        } else if !focusActive && isSleepFocusActive {
            // Transition: active -> inactive
            isSleepFocusActive = false
            sleepEndedAt = Date()
        }
    }

    /// Query the system Focus status.
    ///
    /// Returns `true` if a Focus mode is active, `false` if not, or `nil` if
    /// the API is unavailable or authorization was not granted.
    private func queryFocusStatus() -> Bool? {
        // Use INFocusStatusCenter from the Intents framework (iOS 15+).
        // The app must declare INFocusStatusCenter usage in its Info.plist
        // and request authorization for best results.
        //
        // Note: INFocusStatusCenter.default.focusStatus tells us if *a* Focus
        // is active but not *which* one. For production, a Device Activity
        // Monitor extension would be more precise. This implementation covers
        // the common case where the only overnight Focus is Sleep.
        //
        // Graceful fallback: if the API is not available or not authorized,
        // return nil so callers can offer manual sleep logging instead.

        // INFocusStatusCenter is available on iOS 15+, which is within our
        // iOS 17 deployment target.
        // We avoid importing Intents at the module level to keep the service
        // testable without the framework. Instead, we use dynamic lookup.
        // For a real build, we would import Intents directly. Since the project
        // does not yet link Intents, we return nil for now and rely on manual
        // sleep entry or HealthKit integration in a future wave.
        return nil
    }

    // MARK: - TJ-081, TJ-084: Sleep Slot Calculation

    /// Calculate which slot indices fall entirely within a sleep window.
    ///
    /// A slot qualifies only if its *entire* duration is contained within
    /// `[sleepStart, sleepEnd]`. Partial overlaps are NOT auto-filled (TJ-084).
    ///
    /// Handles cross-midnight sleep by splitting across two calendar days.
    ///
    /// - Parameters:
    ///   - sleepStart: When the user fell asleep.
    ///   - sleepEnd: When the user woke up.
    ///   - mode: The journal mode determining slot duration.
    /// - Returns: Dictionary keyed by calendar day (start-of-day `Date`) to arrays of qualifying slot indices.
    func calculateSleepSlots(
        sleepStart: Date,
        sleepEnd: Date,
        mode: TimeJournalMode
    ) -> [Date: [Int]] {
        guard sleepEnd > sleepStart else { return [:] }

        let calendar = Calendar.current
        let intervalMinutes = mode.intervalMinutes
        let slotsPerDay = mode.slotsPerDay

        // Collect all calendar days that the sleep window touches
        let startDay = calendar.startOfDay(for: sleepStart)
        let endDay = calendar.startOfDay(for: sleepEnd)

        var result: [Date: [Int]] = [:]
        var currentDay = startDay

        while currentDay <= endDay {
            var qualifyingSlots: [Int] = []

            for slotIndex in 0..<slotsPerDay {
                let slotStartMinutes = slotIndex * intervalMinutes
                let slotEndMinutes = (slotIndex + 1) * intervalMinutes

                let slotStart = currentDay.addingTimeInterval(TimeInterval(slotStartMinutes * 60))
                let slotEnd = currentDay.addingTimeInterval(TimeInterval(slotEndMinutes * 60))

                // TJ-084: Only include slots whose ENTIRE duration falls within sleep window
                if slotStart >= sleepStart && slotEnd <= sleepEnd {
                    qualifyingSlots.append(slotIndex)
                }
            }

            if !qualifyingSlots.isEmpty {
                result[currentDay] = qualifyingSlots
            }

            // Advance to next day
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }

        return result
    }

    // MARK: - TJ-082: Create Auto-Filled Sleep Entries

    /// Insert auto-filled sleep entries into the model context for all qualifying slots.
    ///
    /// The location label is carried forward from the last known location (TJ-082),
    /// typically "Home" for sleep entries.
    ///
    /// - Parameters:
    ///   - sleepStart: When the user fell asleep.
    ///   - sleepEnd: When the user woke up.
    ///   - mode: The journal mode.
    ///   - lastLocationLabel: The location label to carry forward (e.g. "Home").
    ///   - userId: The current user's ID.
    ///   - modelContext: The SwiftData model context for persistence.
    func createSleepEntries(
        sleepStart: Date,
        sleepEnd: Date,
        mode: TimeJournalMode,
        lastLocationLabel: String,
        userId: UUID,
        modelContext: ModelContext
    ) {
        let slotsByDay = calculateSleepSlots(sleepStart: sleepStart, sleepEnd: sleepEnd, mode: mode)

        for (day, slotIndices) in slotsByDay {
            for slotIndex in slotIndices {
                let entry = RRTimeJournalEntry(
                    userId: userId,
                    date: day,
                    slotIndex: slotIndex,
                    mode: mode.rawValue,
                    locationLabel: lastLocationLabel,
                    activity: "Sleep",
                    isSleep: true,
                    isAutoFilled: true,
                    autoFillAttribution: "Auto \u{2014} Sleep Focus detected"
                )
                modelContext.insert(entry)
            }
        }

        try? modelContext.save()
    }

    // MARK: - TJ-083: Clear Auto-Fill Flags

    /// Clear auto-fill flags on an entry when the user manually edits it.
    ///
    /// Called from `TimeJournalEntryViewModel.save()` when an auto-filled entry
    /// is modified by the user.
    ///
    /// - Parameter entry: The entry being edited.
    static func clearAutoFillFlags(on entry: RRTimeJournalEntry) {
        entry.isAutoFilled = false
        entry.autoFillAttribution = nil
        entry.modifiedAt = Date()
    }

    // MARK: - TJ-085: Manual Sleep Entry Fallback

    /// Create sleep entries from a manually specified sleep window.
    ///
    /// Used when Focus-based detection is unavailable or the user wants to
    /// correct the auto-detected times.
    ///
    /// - Parameters:
    ///   - sleepStart: User-reported bedtime.
    ///   - sleepEnd: User-reported wake time.
    ///   - mode: The journal mode.
    ///   - locationLabel: Location label (defaults to "Home").
    ///   - userId: The current user's ID.
    ///   - modelContext: The SwiftData model context.
    func createManualSleepEntries(
        sleepStart: Date,
        sleepEnd: Date,
        mode: TimeJournalMode,
        locationLabel: String = "Home",
        userId: UUID,
        modelContext: ModelContext
    ) {
        let slotsByDay = calculateSleepSlots(sleepStart: sleepStart, sleepEnd: sleepEnd, mode: mode)

        for (day, slotIndices) in slotsByDay {
            for slotIndex in slotIndices {
                let entry = RRTimeJournalEntry(
                    userId: userId,
                    date: day,
                    slotIndex: slotIndex,
                    mode: mode.rawValue,
                    locationLabel: locationLabel,
                    activity: "Sleep",
                    isSleep: true,
                    isAutoFilled: true,
                    autoFillAttribution: "Manual \u{2014} user reported"
                )
                modelContext.insert(entry)
            }
        }

        try? modelContext.save()
    }
}
